import speech from '@google-cloud/speech';
import { TranslationServiceClient } from '@google-cloud/translate';
import tts from '@google-cloud/text-to-speech';

const speechClient = new speech.SpeechClient();
const translateClient = new TranslationServiceClient();
const ttsClient = new tts.TextToSpeechClient();

const GCP_PROJECT = process.env.GOOGLE_CLOUD_PROJECT;

// Per-language TTS voice candidates tried in order (Chirp3-HD → Neural2 → Standard).
// Failures are cached so we don't retry a broken voice on every utterance.
const ttsFailureCache = new Set();

function voiceCandidates(lang) {
  return [
    { languageCode: lang, name: `${lang}-Chirp3-HD-Aoede`, ssmlGender: 'FEMALE' },
    { languageCode: lang, name: `${lang}-Neural2-A`, ssmlGender: 'FEMALE' },
    { languageCode: lang, name: `${lang}-Standard-A`, ssmlGender: 'FEMALE' },
    { languageCode: lang, name: `${lang}-Standard-B`, ssmlGender: 'MALE' },
  ];
}

// Google STT streaming sessions expire after 290 s. Restart before that.
const STT_RESTART_MS = 270_000;

// 100 ms of silence at 16 kHz, 16-bit mono = 3 200 bytes of zeros.
// Sent periodically when the user is quiet to prevent Google's ~10 s
// "no audio received" timeout from killing the stream mid-conversation.
const SILENCE_CHUNK = Buffer.alloc(3200);
const KEEPALIVE_INTERVAL_MS = 4_000; // send silence every 4 s of quiet

/**
 * One-directional translation pipeline:
 *   Caller audio (PCM16, 16 kHz mono) → STT → Translate → TTS → MP3 bytes
 *
 * @param {object} opts
 * @param {string} opts.sourceLang   BCP-47 of the speaker  (e.g. 'mr-IN')
 * @param {string} opts.targetLang   BCP-47 of the listener (e.g. 'en-IN')
 * @param {(buf: Buffer) => void} opts.onAudio       MP3 buffer ready to send to listener
 * @param {(evt: TranscriptEvent) => void} opts.onTranscript  transcript / translation events
 */
export class TranslationPipeline {
  constructor({ sourceLang, targetLang, onAudio, onTranscript }) {
    this.sourceLang = sourceLang;
    this.targetLang = targetLang;
    this.onAudio = onAudio;
    this.onTranscript = onTranscript;
    this._destroyed = false;
    this._sttStream = null;
    this._streamStartedAt = 0;
    this._lastAudioAt = 0;
    this._keepaliveInterval = null;
    // STT stream is opened lazily on the first audio chunk to avoid the
    // "Audio Timeout" error that occurs when the stream sits idle while the
    // client is still setting up its microphone.
  }

  /** Feed a raw PCM16 audio chunk from the speaker into the pipeline. */
  sendAudio(chunk) {
    if (this._destroyed) return;

    // Lazy init: open the STT stream only when audio actually arrives.
    if (!this._sttStream) {
      this._initSTT();
    }

    if (Date.now() - this._streamStartedAt > STT_RESTART_MS) {
      this._restartSTT();
    }

    if (this._sttStream && !this._sttStream.destroyed) {
      this._lastAudioAt = Date.now();
      this._sttStream.write(chunk);
    }
  }

  destroy() {
    this._destroyed = true;
    clearInterval(this._keepaliveInterval);
    this._keepaliveInterval = null;
    this._sttStream?.destroy();
    this._sttStream = null;
  }

  _initSTT() {
    this._streamStartedAt = Date.now();
    this._sttStream = speechClient.streamingRecognize({
      config: {
        encoding: 'LINEAR16',
        sampleRateHertz: 16000,
        languageCode: this.sourceLang,
        model: 'latest_long',
        enableAutomaticPunctuation: true,
      },
      interimResults: true,
    });

    // Send silence periodically to prevent Google's ~10s no-audio timeout.
    clearInterval(this._keepaliveInterval);
    this._keepaliveInterval = setInterval(() => {
      if (
        !this._destroyed &&
        this._sttStream &&
        !this._sttStream.destroyed &&
        Date.now() - this._lastAudioAt > KEEPALIVE_INTERVAL_MS
      ) {
        this._sttStream.write(SILENCE_CHUNK);
      }
    }, KEEPALIVE_INTERVAL_MS);

    this._sttStream.on('data', (data) => {
      const result = data.results?.[0];
      if (!result) return;
      const transcript = result.alternatives?.[0]?.transcript?.trim();
      if (!transcript) return;

      // Emit interim + final source transcript to the speaker's UI
      this.onTranscript?.({
        text: transcript,
        isFinal: result.isFinal,
        lang: this.sourceLang,
        isTranslation: false,
      });

      if (result.isFinal) {
        this._translateAndSpeak(transcript).catch((err) =>
          console.error('[pipeline] translateAndSpeak error:', err.message),
        );
      }
    });

    this._sttStream.on('error', (err) => {
      if (this._destroyed) return;
      console.error(`[stt:${this.sourceLang}→${this.targetLang}] Error: ${err.message}`);
      // Brief delay before restarting to avoid tight error loops
      setTimeout(() => {
        if (!this._destroyed) this._initSTT();
      }, 1000);
    });
  }

  _restartSTT() {
    console.log(`[stt] Restarting stream for ${this.sourceLang}→${this.targetLang}`);
    this._sttStream?.destroy();
    this._initSTT();
  }

  async _translateAndSpeak(text) {
    const translated = await this._translate(text);

    // Emit translated text to the listener's UI
    this.onTranscript?.({
      text: translated,
      isFinal: true,
      lang: this.targetLang,
      isTranslation: true,
    });

    const audio = await this._tts(translated);
    if (audio) this.onAudio?.(audio);
  }

  async _translate(text) {
    const [response] = await translateClient.translateText({
      parent: `projects/${GCP_PROJECT}/locations/global`,
      contents: [text],
      mimeType: 'text/plain',
      // Use the base language code (e.g. 'mr' from 'mr-IN')
      sourceLanguageCode: this.sourceLang.split('-')[0],
      targetLanguageCode: this.targetLang.split('-')[0],
    });
    return response.translations?.[0]?.translatedText ?? text;
  }

  async _tts(text) {
    for (const voice of voiceCandidates(this.targetLang)) {
      if (ttsFailureCache.has(voice.name)) continue;
      try {
        const [response] = await ttsClient.synthesizeSpeech({
          input: { text },
          voice,
          audioConfig: { audioEncoding: 'MP3' },
        });
        return Buffer.from(response.audioContent);
      } catch (err) {
        console.warn(`[tts] Voice "${voice.name}" unavailable: ${err.message}`);
        ttsFailureCache.add(voice.name);
      }
    }
    console.error(`[tts] No working voice found for lang: ${this.targetLang}`);
    return null;
  }
}

/**
 * translationSession.js
 *
 * Manages a single user's real-time pipeline:
 *   Microphone audio  →  Google STT (streaming)
 *                     →  Google Translate
 *                     →  Google TTS
 *                     →  PCM audio bytes  →  partner's speaker
 */

import speech from '@google-cloud/speech';
import { TranslationServiceClient } from '@google-cloud/translate';
import tts from '@google-cloud/text-to-speech';

const speechClient = new speech.SpeechClient();
const translateClient = new TranslationServiceClient();
const ttsClient = new tts.TextToSpeechClient();

const PROJECT_ID = process.env.GOOGLE_CLOUD_PROJECT;

// ─── STT stream config ────────────────────────────────────────────────────────
// LINEAR16 @ 16 kHz mono — matches what Flutter's `record` package sends
function buildSttConfig(languageCode) {
  return {
    config: {
      encoding: 'LINEAR16',
      sampleRateHertz: 16000,
      languageCode,
      enableAutomaticPunctuation: true,
      model: 'phone_call',          // Optimised for telephony audio quality
      useEnhanced: true,            // Enhanced model (billed at higher rate but worth it)
    },
    interimResults: true,           // Stream partial transcripts to UI in real-time
  };
}

// ─── Translate ────────────────────────────────────────────────────────────────
async function translateText(text, sourceLang, targetLang) {
  // BCP-47 codes like "en-US" → base codes "en" required by Translate API
  const src = sourceLang.split('-')[0];
  const tgt = targetLang.split('-')[0];

  const [response] = await translateClient.translateText({
    parent: `projects/${PROJECT_ID}/locations/global`,
    contents: [text],
    mimeType: 'text/plain',
    sourceLanguageCode: src,
    targetLanguageCode: tgt,
  });

  return response.translations[0].translatedText;
}

// ─── TTS ──────────────────────────────────────────────────────────────────────
async function synthesizeSpeech(text, voiceLang) {
  // Prefer Neural2 → fallback gracefully if not available for that locale
  const [response] = await ttsClient.synthesizeSpeech({
    input: { text },
    voice: {
      languageCode: voiceLang,
      ssmlGender: 'NEUTRAL',
      name: `${voiceLang}-Neural2-A`,   // e.g. "es-ES-Neural2-A"
    },
    audioConfig: {
      audioEncoding: 'LINEAR16',        // Raw PCM — easiest to play on Flutter side
      sampleRateHertz: 16000,
      effectsProfileId: ['handset-class-device'],  // Optimised for phone speakers
    },
  });

  return response.audioContent; // Buffer<PCM bytes>
}

// ─── Session factory ──────────────────────────────────────────────────────────
/**
 * @param {object} opts
 * @param {string}   opts.sourceLang       BCP-47 e.g. "en-US"
 * @param {string}   opts.targetLang       BCP-47 e.g. "es"   (for Translate)
 * @param {string}   opts.voiceLang        BCP-47 e.g. "es-ES" (for TTS voice)
 * @param {Function} opts.onTranslatedAudio  (Buffer) → void  — send audio to partner
 * @param {Function} opts.onTranscript       (text, isFinal) → void  — update sender UI
 * @param {Function} opts.onError            (Error) → void
 */
export function createTranslationSession({
  sourceLang,
  targetLang,
  voiceLang,
  onTranslatedAudio,
  onTranscript,
  onError,
}) {
  let recognizeStream = null;
  let restartTimer = null;
  let isActive = true;
  let pendingAudioChunks = []; // Buffer audio that arrives during stream restart

  // ── Start / restart the STT stream ─────────────────────────────────────────
  const startStream = () => {
    if (!isActive) return;

    recognizeStream = speechClient
      .streamingRecognize(buildSttConfig(sourceLang))
      .on('error', (err) => {
        if (!isActive) return;

        // Code 11 = stream deadline exceeded (~305 s) — normal, restart silently
        if (err.code === 11) {
          console.log(`[STT] Stream timeout — restarting for lang=${sourceLang}`);
          cleanupStream();
          startStream();
        } else {
          console.error('[STT] Fatal error:', err.message);
          onError?.(err);
        }
      })
      .on('data', async (data) => {
        const result = data.results?.[0];
        if (!result) return;

        const transcript = result.alternatives?.[0]?.transcript ?? '';
        const isFinal = result.isFinal;

        // Send interim transcripts back to sender for live caption display
        onTranscript?.(transcript, isFinal);

        // Only translate + synthesise on final results to avoid wasted API calls
        if (isFinal && transcript.trim().length > 0) {
          try {
            const translated = await translateText(transcript, sourceLang, targetLang);
            const audioBuffer = await synthesizeSpeech(translated, voiceLang);
            onTranslatedAudio?.(audioBuffer);
          } catch (err) {
            console.error('[Pipeline] Translate/TTS error:', err.message);
            onError?.(err);
          }
        }
      });

    // Flush any audio that arrived during the restart window
    if (pendingAudioChunks.length > 0) {
      for (const chunk of pendingAudioChunks) {
        recognizeStream.write(chunk);
      }
      pendingAudioChunks = [];
    }

    // Proactively restart 15 seconds before Google's hard 305-second cutoff
    restartTimer = setTimeout(() => {
      console.log(`[STT] Proactive restart for lang=${sourceLang}`);
      cleanupStream();
      startStream();
    }, 290_000);
  };

  const cleanupStream = () => {
    clearTimeout(restartTimer);
    if (recognizeStream && !recognizeStream.destroyed) {
      recognizeStream.end();
    }
    recognizeStream = null;
  };

  // Kick off first stream
  startStream();

  // ── Public API ──────────────────────────────────────────────────────────────
  return {
    /**
     * Feed raw PCM audio from Flutter microphone into the STT stream.
     * Safe to call even during a stream restart.
     */
    sendAudio(buffer) {
      if (!isActive) return;

      if (recognizeStream && !recognizeStream.destroyed) {
        recognizeStream.write(buffer);
      } else {
        // Stream is restarting — queue chunks so we don't drop audio
        pendingAudioChunks.push(buffer);
      }
    },

    /** Gracefully shut down everything for this user. */
    stop() {
      isActive = false;
      cleanupStream();
      pendingAudioChunks = [];
    },
  };
}
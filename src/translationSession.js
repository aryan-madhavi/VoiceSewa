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

const speechClient    = new speech.SpeechClient();
const translateClient = new TranslationServiceClient();
const ttsClient       = new tts.TextToSpeechClient();

const PROJECT_ID = process.env.GOOGLE_CLOUD_PROJECT;

// ── STT config ────────────────────────────────────────────────────────────────

function buildSttConfig(languageCode) {
  return {
    config: {
      encoding:                   'LINEAR16',
      sampleRateHertz:            16000,
      languageCode,
      enableAutomaticPunctuation: true,
      model:                      'latest_long',
      useEnhanced:                true,
    },
    interimResults: true,
  };
}

// ── Translate ─────────────────────────────────────────────────────────────────

async function translateText(text, sourceLang, targetLang) {
  const src = sourceLang.split('-')[0];
  const tgt = targetLang.split('-')[0];

  const [response] = await translateClient.translateText({
    parent:             `projects/${PROJECT_ID}/locations/global`,
    contents:           [text],
    mimeType:           'text/plain',
    sourceLanguageCode: src,
    targetLanguageCode: tgt,
  });

  return response.translations[0].translatedText;
}

// ── TTS ───────────────────────────────────────────────────────────────────────
// Neural2 voices give the best quality but aren't available for every locale.
// Languages with Neural2 support (as of 2025): en, hi, fr, de, es, it, ja, ko,
// pt, cmn (Mandarin), ar, nl, pl, sv, tr, vi.
// Languages WITHOUT Neural2 (common for VoiceSewa): ml-IN, pa-IN, gu-IN, bn-IN.
// Strategy: try Neural2 first, fall back to Standard on any error.

const NEURAL2_UNAVAILABLE = new Set(); // Cache failures to avoid repeated retries

async function synthesizeSpeech(text, voiceLang) {
  const useNeural2 = !NEURAL2_UNAVAILABLE.has(voiceLang);

  const voiceName = useNeural2
    ? `${voiceLang}-Neural2-A`
    : `${voiceLang}-Standard-A`;

  const request = {
    input:       { text },
    voice: {
      languageCode: voiceLang,
      ssmlGender:   'NEUTRAL',
      name:         voiceName,
    },
    audioConfig: {
      audioEncoding:    'LINEAR16',
      sampleRateHertz:  16000,
      effectsProfileId: ['handset-class-device'],
    },
  };

  try {
    const [response] = await ttsClient.synthesizeSpeech(request);
    return response.audioContent;
  } catch (err) {
    if (useNeural2) {
      // Neural2 not available for this locale — cache and retry with Standard
      console.warn(`[TTS] Neural2 unavailable for ${voiceLang}, falling back to Standard`);
      NEURAL2_UNAVAILABLE.add(voiceLang);

      const fallbackRequest = {
        ...request,
        voice: { ...request.voice, name: `${voiceLang}-Standard-A` },
      };
      const [response] = await ttsClient.synthesizeSpeech(fallbackRequest);
      return response.audioContent;
    }
    // Standard also failed — rethrow
    throw err;
  }
}

// ── Session factory ───────────────────────────────────────────────────────────

/**
 * @param {object}   opts
 * @param {string}   opts.sourceLang        BCP-47 e.g. "hi-IN"
 * @param {string}   opts.targetLang        BCP-47 base e.g. "en" (for Translate API)
 * @param {string}   opts.voiceLang         BCP-47 e.g. "en-IN" (for TTS voice)
 * @param {Function} opts.onTranslatedAudio (Buffer) → void
 * @param {Function} opts.onTranscript      (text, isFinal) → void
 * @param {Function} opts.onError           (Error) → void
 */
export function createTranslationSession({
  sourceLang,
  targetLang,
  voiceLang,
  onTranslatedAudio,
  onTranscript,
  onError,
}) {
  let recognizeStream    = null;
  let restartTimer       = null;
  let isActive           = true;
  let pendingAudioChunks = [];

  const startStream = () => {
    if (!isActive) return;

    recognizeStream = speechClient
      .streamingRecognize(buildSttConfig(sourceLang))
      .on('error', (err) => {
        if (!isActive) return;
        if (err.code === 11) {
          // Stream deadline exceeded (~305s) — normal, restart silently
          console.log(`[STT] Stream timeout, restarting lang=${sourceLang}`);
          cleanupStream();
          startStream();
        } else {
          console.error('[STT] Fatal error:', err.message);
          onError?.(err);
        }
      })
      .on('data', async (data) => {
        const result     = data.results?.[0];
        if (!result) return;

        const transcript = result.alternatives?.[0]?.transcript ?? '';
        const isFinal    = result.isFinal;

        onTranscript?.(transcript, isFinal);

        if (isFinal && transcript.trim().length > 0) {
          try {
            const translated  = await translateText(transcript, sourceLang, targetLang);
            const audioBuffer = await synthesizeSpeech(translated, voiceLang);
            onTranslatedAudio?.(audioBuffer);
          } catch (err) {
            console.error('[Pipeline] Translate/TTS error:', err.message);
            onError?.(err);
          }
        }
      });

    // Flush queued audio from restart window
    if (pendingAudioChunks.length > 0) {
      for (const chunk of pendingAudioChunks) {
        recognizeStream.write(chunk);
      }
      pendingAudioChunks = [];
    }

    // Proactively restart 15s before Google's hard 305s cutoff
    restartTimer = setTimeout(() => {
      console.log(`[STT] Proactive restart lang=${sourceLang}`);
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

  startStream();

  return {
    sendAudio(buffer) {
      if (!isActive) return;
      if (recognizeStream && !recognizeStream.destroyed) {
        recognizeStream.write(buffer);
      } else {
        pendingAudioChunks.push(buffer);
      }
    },

    stop() {
      isActive = false;
      cleanupStream();
      pendingAudioChunks = [];
    },
  };
}
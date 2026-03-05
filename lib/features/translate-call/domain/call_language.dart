// lib/features/translate_call/domain/call_language.dart
//
// Enum of all supported Indian languages.
// Each value carries the three BCP-47 codes the backend needs:
//   sourceLang → Google STT  (e.g. "hi-IN")
//   targetLang → Google Translate (e.g. "hi")
//   voiceLang  → Google TTS voice (e.g. "hi-IN")
//
// No imports needed — pure Dart.

enum CallLanguage {
  english(
    label: 'English',
    nativeLabel: 'English',
    sourceLang: 'en-IN',
    targetLang: 'en',
    voiceLang: 'en-IN',
    flag: '🇮🇳',
  ),
  hindi(
    label: 'Hindi',
    nativeLabel: 'हिन्दी',
    sourceLang: 'hi-IN',
    targetLang: 'hi',
    voiceLang: 'hi-IN',
    flag: '🇮🇳',
  ),
  marathi(
    label: 'Marathi',
    nativeLabel: 'मराठी',
    sourceLang: 'mr-IN',
    targetLang: 'mr',
    voiceLang: 'mr-IN',
    flag: '🇮🇳',
  ),
  tamil(
    label: 'Tamil',
    nativeLabel: 'தமிழ்',
    sourceLang: 'ta-IN',
    targetLang: 'ta',
    voiceLang: 'ta-IN',
    flag: '🇮🇳',
  ),
  telugu(
    label: 'Telugu',
    nativeLabel: 'తెలుగు',
    sourceLang: 'te-IN',
    targetLang: 'te',
    voiceLang: 'te-IN',
    flag: '🇮🇳',
  ),
  kannada(
    label: 'Kannada',
    nativeLabel: 'ಕನ್ನಡ',
    sourceLang: 'kn-IN',
    targetLang: 'kn',
    voiceLang: 'kn-IN',
    flag: '🇮🇳',
  ),
  gujarati(
    label: 'Gujarati',
    nativeLabel: 'ગુજરાતી',
    sourceLang: 'gu-IN',
    targetLang: 'gu',
    voiceLang: 'gu-IN',
    flag: '🇮🇳',
  ),
  bengali(
    label: 'Bengali',
    nativeLabel: 'বাংলা',
    sourceLang: 'bn-IN',
    targetLang: 'bn',
    voiceLang: 'bn-IN',
    flag: '🇮🇳',
  ),
  punjabi(
    label: 'Punjabi',
    nativeLabel: 'ਪੰਜਾਬੀ',
    sourceLang: 'pa-IN',
    targetLang: 'pa',
    voiceLang: 'pa-IN',
    flag: '🇮🇳',
  ),
  malayalam(
    label: 'Malayalam',
    nativeLabel: 'മലയാളം',
    sourceLang: 'ml-IN',
    targetLang: 'ml',
    voiceLang: 'ml-IN',
    flag: '🇮🇳',
  );

  const CallLanguage({
    required this.label,
    required this.nativeLabel,
    required this.sourceLang,
    required this.targetLang,
    required this.voiceLang,
    required this.flag,
  });

  /// English name — for accessibility / search
  final String label;

  /// Name in the language's own script — shown in the picker UI
  final String nativeLabel;

  /// BCP-47 locale for Google Speech-to-Text streaming
  final String sourceLang;

  /// Base language code for Google Cloud Translation API
  final String targetLang;

  /// BCP-47 locale for Google Text-to-Speech Neural2 voice
  final String voiceLang;

  /// Flag emoji — decorative, not used for logic
  final String flag;

  // ── Lookups ──────────────────────────────────────────────────────────────

  /// Find by sourceLang code. Falls back to [hindi] if not found.
  /// Used when deserialising a call doc from Firestore.
  static CallLanguage fromSourceLang(String code) {
    return CallLanguage.values.firstWhere(
      (l) => l.sourceLang == code,
      orElse: () => CallLanguage.hindi,
    );
  }

  /// Find by enum name string (e.g. "hindi"). Falls back to [hindi].
  /// Used when restoring persisted language preference.
  static CallLanguage fromName(String name) {
    return CallLanguage.values.firstWhere(
      (l) => l.name == name,
      orElse: () => CallLanguage.hindi,
    );
  }
}
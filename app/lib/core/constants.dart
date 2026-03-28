class AppConstants {
  AppConstants._();

  // ── BACKEND URL ─────────────────────────────────────────────────────────────
  // To point at a local dev server temporarily change this to:
  //   'http://10.0.2.2:8080'  Android emulator
  //   'http://localhost:8080' iOS simulator
  //   'http://<LAN-IP>:8080'  physical device on the same network
  static const String backendUrl =
      'https://vaani-production.up.railway.app';

  // Converts https → wss automatically for WebSocket connections.
  static String get backendWsUrl =>
      backendUrl.replaceFirst(RegExp(r'^http'), 'ws');
}

/// A language option shown in the settings picker.
class LanguageOption {
  const LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
  });
  final String code;       // BCP-47, e.g. 'mr-IN'
  final String name;       // English name
  final String nativeName; // Name in that language
}

const List<LanguageOption> kSupportedLanguages = [
  LanguageOption(code: 'mr-IN', name: 'Marathi',           nativeName: 'मराठी'),
  LanguageOption(code: 'hi-IN', name: 'Hindi',             nativeName: 'हिंदी'),
  LanguageOption(code: 'en-IN', name: 'English (India)',   nativeName: 'English'),
  LanguageOption(code: 'en-US', name: 'English (US)',      nativeName: 'English'),
  LanguageOption(code: 'ta-IN', name: 'Tamil',             nativeName: 'தமிழ்'),
  LanguageOption(code: 'te-IN', name: 'Telugu',            nativeName: 'తెలుగు'),
  LanguageOption(code: 'kn-IN', name: 'Kannada',           nativeName: 'ಕನ್ನಡ'),
  LanguageOption(code: 'ml-IN', name: 'Malayalam',         nativeName: 'മലയാളം'),
  LanguageOption(code: 'gu-IN', name: 'Gujarati',          nativeName: 'ગુજરાતી'),
  LanguageOption(code: 'bn-IN', name: 'Bengali',           nativeName: 'বাংলা'),
  LanguageOption(code: 'pa-IN', name: 'Punjabi',           nativeName: 'ਪੰਜਾਬੀ'),
  LanguageOption(code: 'or-IN', name: 'Odia',              nativeName: 'ଓଡ଼ିଆ'),
];

/// Firestore collection names
class FirestoreCollections {
  FirestoreCollections._();
  static const String calls = 'calls';
  static const String users = 'users';
  // Each document ID is an E.164 phone number; value: { uid: String }
  // Direct document reads — no collection query or composite index needed.
  static const String phoneIndex = 'phone_index';
}

/// Normalise any Indian phone number string to E.164 (+91XXXXXXXXXX).
///
/// Handles all common formats saved in device contacts:
///   9876543210      → +919876543210  (bare 10-digit)
///   09876543210     → +919876543210  (STD leading-0, 11-digit)
///   919876543210    → +919876543210  (country code without +)
///   +91 98765 43210 → +919876543210  (already E.164 with spaces)
String toE164(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
  // Already E.164 — strip spaces/dashes and reattach the +
  if (raw.trim().startsWith('+')) return '+$digits';
  // STD format: leading 0 + 10-digit number = 11 digits
  if (digits.length == 11 && digits.startsWith('0')) {
    return '+91${digits.substring(1)}';
  }
  // Bare 10-digit Indian mobile number
  if (digits.length == 10) return '+91$digits';
  // Country code present without +: 91XXXXXXXXXX
  if (digits.length == 12 && digits.startsWith('91')) return '+$digits';
  // Best effort for anything else
  return '+$digits';
}

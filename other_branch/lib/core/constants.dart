class AppConstants {
  AppConstants._();

  // ── BACKEND URL ─────────────────────────────────────────────────────────────
  // The value is injected at build time via --dart-define so the APK/IPA never
  // needs to be rebuilt just because the server URL changes.
  //
  // ── Local dev ───────────────────────────────────────────────────────────────
  //   Android emulator  → http://10.0.2.2:8080   (default below)
  //   iOS simulator     → http://localhost:8080
  //   Physical device   → http://<your-LAN-IP>:8080
  //
  //   flutter run --dart-define=BACKEND_URL=http://192.168.1.10:8080
  //
  // ── Railway deployment ──────────────────────────────────────────────────────
  //   1. Go to your Railway project → Settings → Domains → Generate Domain
  //      (or add a custom domain). Railway gives you a URL like:
  //        https://voicesewa-backend-production.up.railway.app
  //
  //   2. Build the app with that URL:
  //        flutter build apk \
  //          --dart-define=BACKEND_URL=https://voicesewa-backend-production.up.railway.app
  //
  //      Note: Railway terminates TLS, so use https:// — NOT http://.
  //      The backendWsUrl getter below automatically converts it to wss://.
  //
  // ── Cloud Run deployment ────────────────────────────────────────────────────
  //   Same pattern — just substitute the Cloud Run service URL:
  //        flutter build apk \
  //          --dart-define=BACKEND_URL=https://voicesewa-backend-xxxx-as.a.run.app
  //
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://10.0.2.2:8080', // Android emulator → localhost
  );

  // Converts http → ws and https → wss automatically.
  // No change needed here when switching between Railway / Cloud Run / local.
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
}

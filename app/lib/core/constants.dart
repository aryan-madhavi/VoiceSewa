class AppConstants {
  AppConstants._();

  /// Override at build time:
  ///   flutter run --dart-define=BACKEND_URL=https://your-cloud-run-url
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://10.0.2.2:8080', // Android emulator → localhost
  );

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

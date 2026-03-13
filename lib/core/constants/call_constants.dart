class CallConstants {
  CallConstants._();

  static const String backendUrl = 'https://voicesewa-production.up.railway.app';

  static String get backendWsUrl =>
      backendUrl.replaceFirst(RegExp(r'^http'), 'ws');
}

class CallFirestoreCollections {
  CallFirestoreCollections._();
  static const String calls = 'calls';
}

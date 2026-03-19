// TODO: Replace this file by running:
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=voicesewa
//
// The generated file will contain DefaultFirebaseOptions for each platform.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not configured');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Platform not configured');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDAnttyFc6SpKhvBPDfDD1fNo7_vPlAM6A',
    appId: '1:221047757778:android:ddfa650b10b38a5607460b',
    messagingSenderId: '221047757778',
    projectId: 'autocalltranslate',
    storageBucket: 'autocalltranslate.firebasestorage.app',
  );

  // Replace values below with output from `flutterfire configure`

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAXvsDJFVXUk5CKb9ZNYuBcV3M7l7VMlNs',
    appId: '1:221047757778:ios:e58cdf9b80d8af1907460b',
    messagingSenderId: '221047757778',
    projectId: 'autocalltranslate',
    storageBucket: 'autocalltranslate.firebasestorage.app',
    iosBundleId: 'com.voicesewa.callTranslate',
  );

}
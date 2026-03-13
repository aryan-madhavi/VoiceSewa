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
    apiKey: 'AIzaSyAa2I-7TTJ96aHU-Ab7wvdKy79hJbnkD9s',
    appId: '1:431243640261:android:bdf5256eeadf779193dfac',
    messagingSenderId: '431243640261',
    projectId: 'voicesewa',
    storageBucket: 'voicesewa.firebasestorage.app',
  );

  // Replace values below with output from `flutterfire configure`

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAjWIObUNj7w_j28aTwUE5Q4HokKXt-igE',
    appId: '1:431243640261:ios:f35dc80b21de6bd993dfac',
    messagingSenderId: '431243640261',
    projectId: 'voicesewa',
    storageBucket: 'voicesewa.firebasestorage.app',
    iosBundleId: 'com.voicesewa.callTranslate',
  );

}
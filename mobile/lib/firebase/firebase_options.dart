// File generated to mirror the firebase_options.dart FlutterFire CLI would
// produce. Project: heal-prd, app ids from google-services.json (Android)
// and GoogleService-Info.plist (iOS). All bundle IDs / package names are
// com.pclub.heal.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCNxGz9LuqSNrNIE70o11Ltu_AFqUpUZik',
    appId: '1:355529098583:android:a1156a55525a6236e62a12',
    messagingSenderId: '355529098583',
    projectId: 'heal-prd',
    storageBucket: 'heal-prd.appspot.com',
    databaseURL: 'https://heal-prd-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD2-uzzcwBWjx0c26jTE2W7JcJ_m78LhoU',
    appId: '1:355529098583:ios:92b69d78847cd4ece62a12',
    messagingSenderId: '355529098583',
    projectId: 'heal-prd',
    storageBucket: 'heal-prd.appspot.com',
    databaseURL: 'https://heal-prd-default-rtdb.firebaseio.com',
    iosBundleId: 'com.pclub.heal',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCNxGz9LuqSNrNIE70o11Ltu_AFqUpUZik',
    appId: '1:355529098583:web:placeholder',
    messagingSenderId: '355529098583',
    projectId: 'heal-prd',
    storageBucket: 'heal-prd.appspot.com',
    databaseURL: 'https://heal-prd-default-rtdb.firebaseio.com',
  );
}

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError('DefaultFirebaseOptions are not configured for linux.');
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not configured for this platform.');
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_WEB_API_KEY'] ?? 'AIzaSyB9CayWyFJSQ7qHczNaTr7yzVS0LTnfmbc',
    appId: dotenv.env['FIREBASE_WEB_APP_ID'] ?? '1:384928842494:web:fe40cc61f152b172235baf',
    messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '384928842494',
    projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? 'church-usher-app',
    authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? 'church-usher-app.firebaseapp.com',
    storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'church-usher-app.firebasestorage.app',
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? 'AIzaSyAXXuz_KW77Y0KWxhSNQe8Wz2GtfKLWnns',
    appId: dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? '1:384928842494:android:0c62680350696b92235baf',
    messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '384928842494',
    projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? 'church-usher-app',
    storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'church-usher-app.firebasestorage.app',
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_IOS_API_KEY'] ?? 'AIzaSyAr8LRZ8NH1YVj8Vg-38edNr64FsJFXfGE',
    appId: dotenv.env['FIREBASE_IOS_APP_ID'] ?? '1:384928842494:ios:4d47a8737a5bf44d235baf',
    messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '384928842494',
    projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? 'church-usher-app',
    storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'church-usher-app.firebasestorage.app',
    iosBundleId: 'com.usherapp.usherApp',
  );

  static FirebaseOptions get macos => ios;

  static FirebaseOptions get windows => web;
}


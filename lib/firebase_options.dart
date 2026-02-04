import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBKR--06xqs0EjUQ-pm65DM2sn5vCk8Z40',
    appId: '1:363665765741:web:725c956a4570c916381664',
    messagingSenderId: '363665765741',
    projectId: 'ridebook-3a6b3',
    authDomain: 'ridebook-3a6b3.firebaseapp.com',
    storageBucket: 'ridebook-3a6b3.firebasestorage.app',
    measurementId: 'G-HNXWJ3WNPJ',
    databaseURL: 'https://ridebook-3a6b3-default-rtdb.firebaseio.com'
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBKR--06xqs0EjUQ-pm65DM2sn5vCk8Z40',
    appId: '1:363665765741:android:725c956a4570c916381664',
    messagingSenderId: '363665765741',
    projectId: 'ridebook-3a6b3',
    storageBucket: 'ridebook-3a6b3.firebasestorage.app',
    databaseURL: 'https://ridebook-3a6b3-default-rtdb.firebaseio.com'
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'YOUR_IOS_BUNDLE_ID',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'YOUR_IOS_BUNDLE_ID',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBKR--06xqs0EjUQ-pm65DM2sn5vCk8Z40',
    appId: '1:363665765741:web:725c956a4570c916381664',
    messagingSenderId: '363665765741',
    projectId: 'ridebook-3a6b3',
    authDomain: 'ridebook-3a6b3.firebaseapp.com',
    storageBucket: 'ridebook-3a6b3.firebasestorage.app',
    databaseURL: 'https://ridebook-3a6b3-default-rtdb.firebaseio.com'
  );
}
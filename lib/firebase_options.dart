import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
        return linux;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'demo-web-api-key',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-petcore-project',
    authDomain: 'demo-petcore-project.firebaseapp.com',
    storageBucket: 'demo-petcore-project.appspot.com',
    measurementId: 'G-0000000000',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'demo-android-api-key',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-petcore-project',
    storageBucket: 'demo-petcore-project.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'demo-ios-api-key',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-petcore-project',
    storageBucket: 'demo-petcore-project.appspot.com',
    iosBundleId: 'com.example.petcore',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'demo-macos-api-key',
    appId: '1:000000000000:macos:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-petcore-project',
    storageBucket: 'demo-petcore-project.appspot.com',
    iosBundleId: 'com.example.petcore',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'demo-windows-api-key',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-petcore-project',
    authDomain: 'demo-petcore-project.firebaseapp.com',
    storageBucket: 'demo-petcore-project.appspot.com',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'demo-linux-api-key',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-petcore-project',
    authDomain: 'demo-petcore-project.firebaseapp.com',
    storageBucket: 'demo-petcore-project.appspot.com',
  );
}

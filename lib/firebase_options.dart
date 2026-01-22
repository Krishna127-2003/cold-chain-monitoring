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

      default:
        return web;
    }
  }

  // ✅ WEB (You will paste your values here)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyCQc4ySUxtzN75gURXJJRB-4WdbottJ2ns",
    authDomain: "cold-chain-monitor-v1.firebaseapp.com",
    projectId: "cold-chain-monitor-v1",
    storageBucket: "cold-chain-monitor-v1.firebasestorage.app",
    messagingSenderId: "653168096175",
    appId: "1:653168096175:web:f0c268040154b0f4c1f55a"
  );

  // ✅ ANDROID (Safe default, will work because google-services.json is added)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "dummy",
    appId: "dummy",
    messagingSenderId: "dummy",
    projectId: "dummy",
  );

  // Optional (not needed now)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "dummy",
    appId: "dummy",
    messagingSenderId: "dummy",
    projectId: "dummy",
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: "dummy",
    appId: "dummy",
    messagingSenderId: "dummy",
    projectId: "dummy",
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: "dummy",
    appId: "dummy",
    messagingSenderId: "dummy",
    projectId: "dummy",
  );
}

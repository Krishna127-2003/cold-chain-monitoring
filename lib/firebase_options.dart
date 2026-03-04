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
    apiKey: "AIzaSyCFFfYKcZ4mKTiEjiTQFI2TBDv7jYFgxlw",                    // API_KEY from plist
    appId: "1:653168096175:ios:068c68f9b480898ec1f55a",              // GOOGLE_APP_ID from plist
    messagingSenderId: "653168096175",  // GCM_SENDER_ID from plist
    projectId: "cold-chain-monitor-v1",             // PROJECT_ID from plist
    storageBucket: "cold-chain-monitor-v1.firebasestorage.app",     // STORAGE_BUCKET from plist
    iosClientId: "653168096175-0ebb60n39if5jb7vmhmch980ec6hsfms.apps.googleusercontent.com",            // CLIENT_ID from plist
    iosBundleId: "com.marken.coldchain",      // BUNDLE_ID from plist
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: "AIzaSyCFFfYKcZ4mKTiEjiTQFI2TBDv7jYFgxlw",
    appId: "1:653168096175:ios:068c68f9b480898ec1f55a",
    messagingSenderId: "653168096175",
    projectId: "cold-chain-monitor-v1",
    storageBucket: "cold-chain-monitor-v1.firebasestorage.app",
    iosClientId: "653168096175-0ebb60n39if5jb7vmhmch980ec6hsfms.apps.googleusercontent.com",
    iosBundleId: "com.marken.coldchain",
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: "dummy",
    appId: "dummy",
    messagingSenderId: "dummy",
    projectId: "dummy",
  );
}

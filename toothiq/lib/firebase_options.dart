// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// إعدادات Firebase — مشروع toothiq-notification
/// (متزامنة مع google-services.json و GoogleService-Info.plist)
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web is not configured for toothiq. Run flutterfire configure if needed.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAOtrQFvJWwJOE9TKhP1nsWcyu7g8wdkYQ',
    appId: '1:860789524798:android:b67a192a2cb0cb33a7046f',
    messagingSenderId: '860789524798',
    projectId: 'toothiq-notification',
    storageBucket: 'toothiq-notification.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBTXWXNsLt-fhJgP8tewDN7NK9YnXKdQfY',
    appId: '1:860789524798:ios:92f7dc68242facc8a7046f',
    messagingSenderId: '860789524798',
    projectId: 'toothiq-notification',
    storageBucket: 'toothiq-notification.firebasestorage.app',
    iosBundleId: 'com.example.dentalAppBaqer',
  );

  static const FirebaseOptions macos = ios;
}

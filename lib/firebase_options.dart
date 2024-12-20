// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
    apiKey: 'AIzaSyAxYnr0XEaaFkK91EK8GVS1rOV3fsFyGwA',
    appId: '1:850006190065:web:41afa5b6d9e0dba3dcc650',
    messagingSenderId: '850006190065',
    projectId: 'bootstrap-rfid',
    authDomain: 'bootstrap-rfid.firebaseapp.com',
    storageBucket: 'bootstrap-rfid.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAUA76FUe6A9J5q1ObUNaqGb83NkCw3C1U',
    appId: '1:850006190065:android:57bec094944e15a5dcc650',
    messagingSenderId: '850006190065',
    projectId: 'bootstrap-rfid',
    storageBucket: 'bootstrap-rfid.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDp8I7hVdDK2JMRbQ472V_DbaSvw5h4DCQ',
    appId: '1:850006190065:ios:cf8ccd0c036509bfdcc650',
    messagingSenderId: '850006190065',
    projectId: 'bootstrap-rfid',
    storageBucket: 'bootstrap-rfid.appspot.com',
    iosBundleId: 'com.example.blocTestApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDp8I7hVdDK2JMRbQ472V_DbaSvw5h4DCQ',
    appId: '1:850006190065:ios:cf8ccd0c036509bfdcc650',
    messagingSenderId: '850006190065',
    projectId: 'bootstrap-rfid',
    storageBucket: 'bootstrap-rfid.appspot.com',
    iosBundleId: 'com.example.blocTestApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAxYnr0XEaaFkK91EK8GVS1rOV3fsFyGwA',
    appId: '1:850006190065:web:f3c35e3fb32b1919dcc650',
    messagingSenderId: '850006190065',
    projectId: 'bootstrap-rfid',
    authDomain: 'bootstrap-rfid.firebaseapp.com',
    storageBucket: 'bootstrap-rfid.appspot.com',
  );

}
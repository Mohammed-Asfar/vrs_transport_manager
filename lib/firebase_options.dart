import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return windows;
    }
    // Fallback to web config for other platforms
    return web;
  }

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBmWdpe1qPS7eWtAos0O-ZUJmMjwEjyIyM',
    appId: '1:160330625412:web:e93c2ed221a01d1686add1',
    messagingSenderId: '160330625412',
    projectId: 'vrs-invoice-db',
    authDomain: 'vrs-invoice-db.firebaseapp.com',
    databaseURL: 'https://vrs-invoice-db-default-rtdb.firebaseio.com',
    storageBucket: 'vrs-invoice-db.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBmWdpe1qPS7eWtAos0O-ZUJmMjwEjyIyM',
    appId: '1:160330625412:web:49df1413e562327a86add1',
    messagingSenderId: '160330625412',
    projectId: 'vrs-invoice-db',
    authDomain: 'vrs-invoice-db.firebaseapp.com',
    databaseURL: 'https://vrs-invoice-db-default-rtdb.firebaseio.com',
    storageBucket: 'vrs-invoice-db.firebasestorage.app',
    measurementId: 'G-2RY5YE4HKH',
  );
}

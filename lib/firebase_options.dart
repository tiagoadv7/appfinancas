// Gerado manualmente com os valores do Firebase Console.
// Para regenerar automaticamente: dart pub global run flutterfire_cli:flutterfire configure

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'Plataforma não suportada: $defaultTargetPlatform',
        );
    }
  }

  // ─── Web ──────────────────────────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCVA3fWvpd4MoD_qlNFKXvsuFZFvB3qKxw',
    appId: '1:620656474886:web:5b5c6f1b1dd15c57887c87',
    messagingSenderId: '620656474886',
    projectId: 'appfinancas-9d7a3',
    authDomain: 'appfinancas-9d7a3.firebaseapp.com',
    storageBucket: 'appfinancas-9d7a3.firebasestorage.app',
    measurementId: 'G-E77G46XTFV',
  );

  // ─── Android ──────────────────────────────────────────────────────────────
  // Fonte: android/app/google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAhA0xxmYvMtdOxFFgU0Vxt63vLiXMv8wY',
    appId: '1:620656474886:android:e2c3d41f8d6b508c887c87',
    messagingSenderId: '620656474886',
    projectId: 'appfinancas-9d7a3',
    storageBucket: 'appfinancas-9d7a3.firebasestorage.app',
  );

  // ─── iOS ──────────────────────────────────────────────────────────────────
  // Adicione o app iOS no Firebase Console, baixe o GoogleService-Info.plist
  // e coloque em ios/Runner/. Preencha os valores abaixo.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'SUA_API_KEY_IOS',
    appId: '1:620656474886:ios:HASH_IOS',
    messagingSenderId: '620656474886',
    projectId: 'appfinancas-9d7a3',
    storageBucket: 'appfinancas-9d7a3.firebasestorage.app',
    iosClientId: 'SEU_IOS_CLIENT_ID.apps.googleusercontent.com',
    iosBundleId: 'com.example.appfinancas',
  );

  // ─── macOS ────────────────────────────────────────────────────────────────
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'SUA_API_KEY_MACOS',
    appId: '1:620656474886:ios:HASH_MACOS',
    messagingSenderId: '620656474886',
    projectId: 'appfinancas-9d7a3',
    storageBucket: 'appfinancas-9d7a3.firebasestorage.app',
    iosClientId: 'SEU_IOS_CLIENT_ID.apps.googleusercontent.com',
    iosBundleId: 'com.example.appfinancas',
  );
}

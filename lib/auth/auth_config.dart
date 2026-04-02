import 'package:flutter/foundation.dart' show kDebugMode;

// Em debug (dev), usa MockAuthService com login local.
// Em release (produção), usa FirebaseAuthService.
bool get useMockAuth => kDebugMode;

// Credenciais de teste — apenas ambiente de desenvolvimento.
const String devTestEmail = 'dev@appfinancas.com';
const String devTestPassword = 'dev123';

// Client ID OAuth 2.0 para Web (Google Sign-In no Chrome/Web).
// Obtenha em: Google Cloud Console → Credenciais → OAuth 2.0 → Web
// Ex: 'xxxx-yyyy.apps.googleusercontent.com'
const String? googleSignInWebAppClientId = null;

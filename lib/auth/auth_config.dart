import 'package:flutter/foundation.dart' show kDebugMode;

// Em debug (dev), usa o MockAuthService com login por email/senha local.
// Em release (produção), usa o GoogleAuthService.
bool get useMockAuth => kDebugMode;

// Credenciais de teste disponíveis apenas no ambiente de desenvolvimento.
const String devTestEmail = 'dev@appfinancas.com';
const String devTestPassword = 'dev123';

// IMPORTANTE: Adicione aqui o Client ID do OAuth 2.0 para "Aplicativo da Web"
// obtido no Google Cloud Console. Necessário para o login no Chrome.
// Ex: 'xxxx-yyyy.apps.googleusercontent.com'
const String? googleSignInWebAppClientId = null;

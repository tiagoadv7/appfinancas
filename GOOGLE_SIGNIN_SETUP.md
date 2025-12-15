# 🔐 Guia de Configuração - Google Sign-In

## 📱 Configuração para Android

### Passo 1: Obter SHA-1 do Projeto

```bash
cd android
./gradlew signingReport
```

Procure por `SHA1` na saída. Você verá algo como:
```
Variant: release
Config: release
Store: /Users/usuario/.android/debug.keystore
Alias: AndroidDebugKey
MD5: ...
SHA1: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB
SHA256: ...
```

### Passo 2: Configurar Google Cloud Console

1. Acesse [Google Cloud Console](https://console.cloud.google.com)
2. Crie um novo projeto (ou selecione existente)
3. Ative a API de **Google+**:
   - Vá em "APIs & Services" > "Library"
   - Procure por "Google+ API"
   - Clique em "Enable"

4. Configure OAuth 2.0:
   - Vá em "APIs & Services" > "Credentials"
   - Clique em "Create Credentials" > "OAuth 2.0 Client ID"
   - Escolha "Android"
   - Preencha:
     - **Package name**: `com.example.appfinancas` (ou seu package name)
     - **SHA-1**: Cole o SHA-1 obtido no Passo 1
   - Clique em "Create"

### Passo 3: Baixar arquivo de configuração

1. Na mesma tela, você verá "Google Services Configuration"
2. Clique em "Download google-services.json"
3. Salve o arquivo em `android/app/`

### Passo 4: Atualizar build.gradle

**android/build.gradle**:
```gradle
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

**android/app/build.gradle**:
```gradle
apply plugin: 'com.android.application'
apply plugin: 'com.google.gms.google-services'  // Adicione essa linha

android {
    // ... resto da configuração
}

dependencies {
    // ... outras dependências
}
```

## 🍎 Configuração para iOS

### Passo 1: Configurar URL Schemes

1. Abra `ios/Runner.xcworkspace` no Xcode
2. Selecione o projeto "Runner"
3. Vá em "Info" tab
4. Procure por "URL Types"
5. Clique no "+" para adicionar novo URL Type
6. Em "URL Schemes", adicione o ID do Cliente Reverso do Google

### Passo 2: Obter ID do Cliente Reverso

1. No Google Cloud Console, vá em "APIs & Services" > "Credentials"
2. Crie um novo OAuth 2.0 Client ID para iOS:
   - Escolha "iOS"
   - Preencha:
     - **Bundle ID**: `com.example.appfinancas` (veja em Xcode)
     - **Team ID**: Seu Apple Team ID
   - Copie o "iOS URL Scheme"

### Passo 3: Adicionar GoogleService-Info.plist

1. No Google Cloud Console, faça download do `GoogleService-Info.plist`
2. Arraste para Xcode > Runner > Runner
3. Certifique-se de que está marcado "Copy if needed"

### Passo 4: Atualizar Info.plist

**ios/Runner/Info.plist**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- ... outras configurações -->
    
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
            </array>
        </dict>
    </array>
    
    <!-- ... resto do arquivo -->
</dict>
</plist>
```

## 🌐 Configuração para Web

### Passo 1: Obter Web Client ID

1. No Google Cloud Console, crie um novo OAuth 2.0 Client ID para Web
2. Em "Authorized JavaScript origins", adicione:
   - `http://localhost:5000`
   - `http://localhost:7357` (padrão do Flutter)
   - Seu domínio em produção

3. Em "Authorized redirect URIs", adicione:
   - `http://localhost:5000/callback`
   - `http://localhost:7357/callback`
   - Seu domínio com callback em produção

### Passo 2: Configurar no pubspec.yaml

```yaml
dependencies:
  google_sign_in: ^6.1.4
  google_sign_in_web: ^0.12.0  # Adicione explicitamente para web
```

### Passo 3: Adicionar Meta Tag no HTML

**web/index.html**:
```html
<head>
    <meta charset="UTF-8">
    <meta content="IE=Edge" http-equiv="X-UA-Compatible">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    
    <!-- Google Sign-In -->
    <script src="https://accounts.google.com/gsi/client" async defer></script>
    
    <!-- Resto do arquivo -->
</head>
```

## 🧪 Teste Local

### Para Android
```bash
flutter run -d android
```

### Para iOS
```bash
flutter run -d ios
```

### Para Web
```bash
flutter run -d chrome -w
```

## ⚠️ Troubleshooting

### Erro: "PlatformException(sign_in_failed)"

**Causa**: SHA-1 não registrado ou incorreto

**Solução**:
1. Verifique o SHA-1 correto com `./gradlew signingReport`
2. Atualize no Google Cloud Console
3. Limpe o cache: `flutter clean && flutter pub get`

### Erro: "MissingPluginException"

**Causa**: Plugin não compilado corretamente

**Solução**:
```bash
flutter clean
flutter pub get
flutter pub upgrade
flutter run
```

### Erro: "CONFIGURATION_ERROR (Error reading services: googleServiceFile)"

**Causa**: `google-services.json` não encontrado

**Solução**:
1. Certifique-se de que está em `android/app/`
2. Limpe o projeto: `flutter clean`
3. Reconstrua: `flutter run`

### Erro: "The identity provider configuration is not available"

**Causa**: URL schemes não configurado corretamente no iOS

**Solução**:
1. Abra `ios/Runner.xcworkspace` no Xcode
2. Verifique "Info" > "URL Types"
3. Adicione o URL scheme correto
4. Limpe build: `flutter clean && flutter run -d ios`

## 📚 Recursos Úteis

- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Google Cloud Console](https://console.cloud.google.com)
- [Firebase for Flutter](https://firebase.flutter.dev/)
- [Flutter Documentation](https://flutter.dev/docs)

## 🔒 Boas Práticas de Segurança

1. **Nunca commits credenciais**: Adicione a `.gitignore`:
   ```
   google-services.json
   GoogleService-Info.plist
   ```

2. **Use variáveis de ambiente**: Para dados sensíveis, use variáveis de ambiente

3. **Valide tokens no backend**: Sempre valide tokens Google no servidor

4. **Implemente rate limiting**: Limitar tentativas de login

5. **Use HTTPS em produção**: Sempre use conexão segura

---

**Última atualização**: Novembro 2025

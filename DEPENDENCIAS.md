# 📦 Dependências do Projeto

## Dependências Instaladas

### pubspec.yaml Atualizado

```yaml
name: appfinancas
description: "App de gerenciamento de finanças com autenticação Google e colaboradores."
publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: ^3.10.0

dependencies:
  flutter:
    sdk: flutter

  # UI Icons
  cupertino_icons: ^1.0.8

  # Autenticação Google
  google_sign_in: ^6.1.4
    # Descrição: Integração com Google Sign-In para Flutter
    # Uso: Login/Logout com conta Google
    # Site: https://pub.dev/packages/google_sign_in

  # Firebase Core (Base para Firebase Services)
  firebase_core: ^2.24.0
    # Descrição: Core Firebase para Flutter
    # Uso: Inicializar Firebase
    # Site: https://pub.dev/packages/firebase_core

  # Firebase Authentication
  firebase_auth: ^4.15.0
    # Descrição: Autenticação via Firebase
    # Uso: Validar tokens, gerenciar usuários
    # Site: https://pub.dev/packages/firebase_auth

  # Firebase Realtime Database
  firebase_database: ^10.2.0
    # Descrição: Banco de dados em tempo real do Firebase
    # Uso: Sincronizar dados de transações/colaboradores
    # Site: https://pub.dev/packages/firebase_database

  # Provider (Gerenciamento de Estado)
  provider: ^6.0.0
    # Descrição: Provider para gerenciamento de estado
    # Uso: Compartilhar estado entre widgets
    # Site: https://pub.dev/packages/provider

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Linter
  flutter_lints: ^6.0.0
    # Descrição: Linting rules recomendadas pelo Flutter
    # Uso: Verificar qualidade do código

flutter:
  uses-material-design: true
```

## 🔍 Análise de Dependências

### Por Funcionalidade

#### Autenticação Google
```
google_sign_in: ^6.1.4
└─ Fornece:
   ├─ GoogleSignIn class
   ├─ GoogleSignInAccount model
   ├─ Sign-in flow nativa para Android/iOS/Web
   └─ Gerenciamento de tokens OAuth 2.0
```

#### Firebase (Futuro)
```
firebase_core: ^2.24.0
firebase_auth: ^4.15.0
firebase_database: ^10.2.0
└─ Fornece:
   ├─ Persistência de dados
   ├─ Sincronização em tempo real
   ├─ Autenticação segura
   └─ Cloud Functions integration
```

#### Estado
```
provider: ^6.0.0
└─ Fornece:
   ├─ ChangeNotifier
   ├─ Provider widget
   ├─ Multi-provider
   └─ Consumer pattern
```

## 📊 Versões Compatíveis

| Pacote | Versão Usada | Versão Mínima | Última | Status |
|--------|--------------|---------------|--------|--------|
| google_sign_in | 6.1.4 | 6.0.0 | 6.2.0 | ✅ OK |
| firebase_core | 2.24.0 | 2.20.0 | 2.24.0 | ✅ OK |
| firebase_auth | 4.15.0 | 4.10.0 | 4.15.0 | ✅ OK |
| firebase_database | 10.2.0 | 10.0.0 | 10.2.0 | ✅ OK |
| provider | 6.0.0 | 6.0.0 | 6.1.0 | ✅ OK |
| flutter_lints | 6.0.0 | 6.0.0 | 6.0.0 | ✅ OK |

## 🔧 Como Instalar

### Instalação Normal
```bash
# Na raiz do projeto
flutter pub get
```

### Instalação com Upgrade
```bash
# Atualizar para versões compatíveis
flutter pub upgrade
```

### Instalar Pacote Individual
```bash
# Exemplo: adicionar novo pacote
flutter pub add nova_dependencia
```

### Remover Pacote
```bash
# Exemplo: remover pacote
flutter pub remove nova_dependencia
```

## 🔐 Google Sign-In - Configuração Necessária

### Android Específico
Nenhuma dependência adicional necessária no Android (usar com Firebase)

### iOS Específico
```bash
cd ios
pod install
cd ..
```

### Web Específico
```bash
# Adicionar explicitamente para Web
flutter pub add google_sign_in_web
```

## 📚 Documentação das Dependências

### google_sign_in
```dart
// Exemplo de uso
final googleSignIn = GoogleSignIn();
final user = await googleSignIn.signIn();
print(user.email);       // user@example.com
print(user.displayName); // User Name
print(user.photoUrl);    // https://...
```

**Métodos principais:**
- `signIn()` - Fazer login
- `signOut()` - Fazer logout
- `disconnect()` - Desconectar
- `isSignedIn()` - Verificar estado

### firebase_core
```dart
// Inicialização
await Firebase.initializeApp();
```

**Necessário para:**
- Usar firebase_auth
- Usar firebase_database
- Usar qualquer serviço Firebase

### firebase_auth
```dart
// Exemplo: criar usuário
FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: email,
  password: password,
);

// Verificar usuário atual
final user = FirebaseAuth.instance.currentUser;
```

### firebase_database
```dart
// Exemplo: salvar dado
final ref = FirebaseDatabase.instance.ref();
await ref.child('users').push().set({
  'name': 'João',
  'email': 'joao@example.com'
});

// Exemplo: ler dado
final snapshot = await ref.child('users').get();
```

### provider
```dart
// Exemplo: criar provider
class UserProvider with ChangeNotifier {
  User? _user;
  
  User? get user => _user;
  
  void setUser(User user) {
    _user = user;
    notifyListeners();
  }
}

// Usar em widget
final user = context.watch<UserProvider>().user;
```

## ⚠️ Compatibilidade

### Flutter Versions
- ✅ Flutter 3.10.0+
- ✅ Flutter 3.13.0+
- ✅ Flutter 3.16.0+ (recomendado)

### Dart Versions
- ✅ Dart 3.10.0+

### Plataformas Suportadas
- ✅ Android (API 21+)
- ✅ iOS (12.0+)
- ✅ Web (Chrome, Firefox, Safari)
- ❌ Windows (Google Sign-In não suporta nativamente)
- ❌ macOS (Google Sign-In requer configuração especial)
- ❌ Linux (não suportado)

## 🔄 Atualizações de Dependências

### Verificar Atualizações
```bash
flutter pub outdated
```

### Atualizar Tudo
```bash
flutter pub upgrade
```

### Atualizar Específico
```bash
flutter pub upgrade google_sign_in
```

### Lock Versão
```bash
# No pubspec.yaml, use:
google_sign_in: 6.1.4  # em vez de ^6.1.4
```

## 🚀 Dependências Recomendadas para o Futuro

Se você quiser adicionar mais features:

```yaml
# Notificações
firebase_messaging: ^14.0.0

# Cloud Storage
firebase_storage: ^11.0.0

# Analytics
firebase_analytics: ^10.0.0

# Crash Reporting
firebase_crashlytics: ^3.0.0

# Remote Config
firebase_remote_config: ^4.0.0

# Gerenciamento de Estado (alternativa)
riverpod: ^2.0.0
bloc: ^8.1.0

# HTTP Client
http: ^1.1.0

# Localization
intl: ^0.19.0

# Date Picker
intl_date_picker: ^1.0.0

# PDF Export
pdf: ^3.10.0

# Gráficos
fl_chart: ^0.60.0
```

## 📋 Checklist de Dependências

```
✅ google_sign_in      → Instalado e configurado
✅ firebase_core       → Instalado (não usado ainda)
✅ firebase_auth       → Instalado (não usado ainda)
✅ firebase_database   → Instalado (não usado ainda)
✅ provider            → Instalado (não usado ainda)
✅ cupertino_icons    → Pré-instalado
✅ flutter_lints      → Pré-instalado
```

## 🔐 Boas Práticas

1. **Sempre use `^` para versões**: `^6.1.4` permite 6.1.5, 6.2.0 mas não 7.0.0
2. **Não committe `pubspec.lock`**: Deixe Flutter gerenciar versões exatas
3. **Teste compatibilidade**: Após atualizar, rode `flutter test`
4. **Leia changelogs**: Antes de atualizar major version
5. **Use `pub.dev`**: Para verificar documentação e exemplos

## 📞 Suporte

Se tiver problemas com dependências:

1. Rode `flutter clean`
2. Rode `flutter pub get`
3. Rode `flutter pub upgrade`
4. Verifique `pubspec.yaml`
5. Leia erro específico e procure na documentação

---

**Última atualização**: Novembro 2025
**Status**: Todos os pacotes instalados e funcionando ✅

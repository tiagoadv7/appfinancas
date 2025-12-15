# 📱 FinançasApp - Build & Teste

## Builds Disponíveis

### 1. **Web Release** (Pronto para Usar) ✅
- **Local**: `build/web/`
- **Status**: ✅ Compilado e pronto para testes
- **Como executar localmente**:
  ```powershell
  cd "C:\Users\Tiago Neves\Documents\GitHub\appfinancas"
  flutter run -d chrome  # Abre em navegador Chrome
  ```
- **Para publicar**: Copiar conteúdo de `build/web/` para servidor web

### 2. **APK (Android)** ⚠️ Requer Configuração
- **Status**: ❌ Android SDK não configurado
- **Para habilitar**:
  1. Instalar Android Studio: https://developer.android.com/studio
  2. Durante instalação, selecionar SDK components
  3. Ou configurar manualmente:
     ```powershell
     flutter config --android-sdk "C:\path\to\android\sdk"
     ```
  4. Então compilar:
     ```powershell
     flutter build apk --release
     ```

---

## 🧪 Testando a Aplicação

### Login e Acesso
- **Mock Login**: Clique em "Ou Entrar como Teste (Mock)" para acessar como usuário Owner
- **Google Sign-In**: Configurar em `web/index.html` (meta tag `google-signin-client_id`)

### Funcionalidades Implementadas
✅ Dashboard com resumo financeiro
✅ Gestão de transações (Entradas/Saídas)
✅ Categorias personalizadas (botão "Adicionar Categoria")
✅ Tema claro/escuro com toggle automático
✅ Avatar circular com iniciais do usuário
✅ BottomNavigationBar com design arredondado (topo)
✅ FloatingActionButton com ícone + para nova transação
✅ Colaboradores e sistema de convites (Owner only)

### Dados de Teste
- **Usuário padrão**: Tiago Neves (tiago@appfinancas.com)
- **Papel**: Owner
- **Transações mock**: 12 transações carregadas automaticamente
- **Categorias**: 5 categorias padrão + personalizadas

---

## 📦 Estrutura de Build

```
build/
├── web/              # Web release build (pronto para produção)
│   ├── index.html
│   ├── main.dart.js
│   └── assets/
└── apk/              # (Após configurar Android SDK)
    └── app-release.apk
```

---

## 🚀 Próximas Etapas

1. **Para testar no navegador agora**:
   ```powershell
   flutter run -d chrome
   ```

2. **Para gerar APK**:
   - Instalar Android SDK (veja seção acima)
   - Executar: `flutter build apk --release`
   - APK estará em: `build/app/outputs/flutter-apk/app-release.apk`

3. **Para publicar Web**:
   - Fazer upload de `build/web/` para servidor web
   - Ou usar Firebase Hosting, Netlify, Vercel, etc.

---

## ⚙️ Configurações Importantes

### Google Sign-In (Opcional para Produção)
Para ativar Google Sign-In em produção:
1. Criar projeto em Google Cloud Console
2. Obter `client_id`
3. Adicionar ao `web/index.html`:
   ```html
   <meta name="google-signin-client_id" content="YOUR_CLIENT_ID">
   ```

### Theme & Dark Mode
- Tema detecta automaticamente do sistema
- Toggle manual no AppBar (ícone sol/lua)
- Cores tema-aware em todo o app

---

**Data de Build**: 14/11/2025  
**Versão Flutter**: 3.38.1  
**Versão Dart**: 3.x+

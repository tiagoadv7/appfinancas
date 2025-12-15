# Changelog - Integração Google Sign-In e Sistema de Convites

## 📦 Dependências Adicionadas

```yaml
google_sign_in: ^6.1.4
firebase_core: ^2.24.0
firebase_auth: ^4.15.0
firebase_database: ^10.2.0
provider: ^6.0.0
```

## ✨ Novos Modelos de Dados

### 1. **User** - Representa um usuário autenticado
```dart
class User {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String role; // 'owner', 'collaborator', 'viewer'
}
```

### 2. **Invitation** - Representa um convite para colaborador
```dart
class Invitation {
  final String id;
  final String email;
  final String role;
  final DateTime createdAt;
  final String createdBy;
  final bool accepted;
}
```

## 🔐 Sistema de Autenticação

### Novos Métodos em `_MainAppState`

- **`_signInWithGoogle()`**: Faz login com conta Google
- **`_signOut()`**: Faz logout do usuário
- **`_showInviteCollaboratorDialog()`**: Modal para convidar colaboradores
- **`_sendInvitation(String email, String role)`**: Envia convite para email
- **`_removeCollaborator(String userId)`**: Remove colaborador da lista
- **`_showCollaboratorsDialog()`**: Exibe lista de colaboradores e convites

### Getters para Controle de Acesso

```dart
String get _userRole      // Retorna o papel do usuário
bool get _isAdmin         // Verifica se é owner
bool get _isCollaborator  // Verifica se é collaborator
bool get _isViewer        // Verifica se é viewer
bool get _isGuest         // Verifica se não está autenticado
```

## 🎨 Mudanças na UI

### AppBar Atualizado
- Botão **"Convidar"** (apenas para Owner)
- Menu de usuário com:
  - Informações do perfil (nome, email, papel)
  - Link para gerenciar colaboradores
  - Botão de logout
  - Avatar com foto do Google

### Tela de Login
- Exibe quando o usuário não está autenticado
- Botão "Entrar com Google" bem destacado
- Mensagem clara sobre os benefícios de fazer login

### Tela de Colaboradores
- Lista colaboradores ativos
- Exibe convites pendentes
- Possibilidade de remover colaboradores (apenas Owner)

## 🔄 Mudanças de Lógica

### Permissões por Tipo de Usuário

| Funcionalidade | Owner | Collaborator | Viewer | Guest |
|---|---|---|---|---|
| Visualizar Dashboard | ✅ | ✅ | ✅ | ❌ |
| Ver Transações | ✅ | ✅ | ✅ | ❌ |
| Adicionar Transação | ✅ | ✅ | ❌ | ❌ |
| Deletar Transação | ✅ | ✅ | ❌ | ❌ |
| Gerenciar Colaboradores | ✅ | ❌ | ❌ | ❌ |
| Convidar Colaboradores | ✅ | ❌ | ❌ | ❌ |

### Mudanças no Fluxo de Adição de Transações

**Antes:**
```dart
if (_userRole == 'guest') { // Usava variável string
  _showAuthModal();
}
```

**Depois:**
```dart
if (_isGuest) { // Usa getter booleano
  _showAuthModal();
}
if (!_isCollaborator && !_isAdmin) { // Valida permissões
  _showErrorSnackBar('Você não tem permissão...');
}
```

## 🎯 Fluxo de Uso

### 1. Primeiro Acesso
1. Usuário vê tela de login
2. Clica em "Entrar com Google"
3. Google redireciona para autenticação
4. Usuário é marcado como **Owner**
5. Acesso ao Dashboard

### 2. Convidar Colaborador
1. Owner clica em "Convidar"
2. Digita email e seleciona permissão
3. Convite é armazenado localmente (ou no Firebase quando integrado)
4. Convite aparece na lista de "Convites Pendentes"

### 3. Controle de Acesso
- **Viewer**: Pode apenas visualizar transações (FAB escondido)
- **Collaborator**: Pode adicionar, editar e deletar
- **Owner**: Acesso total + gerenciamento de colaboradores

## 📝 Mudanças Importantes

### Estado Simplificado
```dart
// Removido: String _userRole = 'collaborator';
// Adicionado: User? _currentUser;

// Removido: List<User> já não usamos user list estruturada
// Adicionado: 
late GoogleSignIn _googleSignIn;
User? _currentUser;
List<User> _collaborators = [];
List<Invitation> _invitations = [];
```

### Métodos Adicionados
- `_showErrorSnackBar()` - Exibe erro
- `_showSuccessSnackBar()` - Exibe sucesso
- Propriedades de acesso para diferentes tipos de usuário

## 🔄 Próximas Integrações Recomendadas

1. **Firebase Realtime Database** - Sincronizar dados entre dispositivos
2. **Cloud Functions** - Validar e processar convites
3. **Email Service** - Enviar emails reais para convites
4. **Notifications** - Notificar usuários sobre convites
5. **Analytics** - Rastrear uso do aplicativo

## ⚠️ Notas Importantes

- Atualmente, convites e colaboradores são armazenados em memória (não persistem)
- Para produção, implemente Firebase ou outro backend
- Google Sign-In precisa ser configurado no Google Cloud Console
- SHA-1 do projeto Android deve ser registrado no Google Cloud Console

## 🧪 Teste as Funcionalidades

```bash
# 1. Instalar dependências
flutter pub get

# 2. Executar a aplicação
flutter run

# 3. Fazer login com Google
# - Clique em "Entrar com Google"
# - Selecione sua conta

# 4. Testar funcionalidades
# - Adicionar transação (apenas se Collaborator ou Owner)
# - Convidar colaborador (apenas se Owner)
# - Ver colaboradores (apenas se Owner)
# - Visualizar Dashboard
```

---

**Data de Implementação**: Novembro 2025
**Status**: Código completo e testado ✅

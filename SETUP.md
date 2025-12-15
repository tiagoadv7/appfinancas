# FinançasApp - Guia de Setup e Funcionalidades

## 📋 Funcionalidades Implementadas

### 1. **Autenticação com Google**
- Login via Google Sign-In
- Logout e gerenciamento de perfil do usuário
- Foto de perfil sincronizada do Google
- Diferentes tipos de usuários: Owner (criador), Collaborator (editor), Viewer (visualizador)

### 2. **Sistema de Convites de Colaboradores**
- **Owner (Proprietário)**: Pode convidar novos colaboradores
- **Collaborator (Colaborador)**: Pode editar e visualizar transações
- **Viewer (Visualizador)**: Apenas visualiza transações (leitura)
- Convites pendentes são exibidos no painel de colaboradores

### 3. **Gerenciamento de Transações**
- **Visualização**: Todas as transações são visíveis para todos os usuários autenticados
- **Edição**: Apenas Owner e Collaborator podem adicionar/editar transações
- **Deleção**: Apenas Owner e Collaborator podem deletar transações
- **Filtros**: Dashboard, Entradas, Saídas, Todas as Transações

### 4. **Dashboard**
- Sumário de Saldo, Entradas e Saídas
- Gráfico de barras anual
- Resumo por categoria (Top 5)

## 🔧 Instalação e Setup

### Pré-requisitos
- Flutter SDK (3.10.0 ou superior)
- Dart SDK
- Android Studio / Xcode (para emulador)

### Passo 1: Instalar Dependências
```bash
flutter pub get
```

### Passo 2: Configurar Google Sign-In

#### Para Android:
1. Acesse [Google Cloud Console](https://console.cloud.google.com)
2. Crie um novo projeto
3. Ative a API de Google+ para Android
4. Configure as credenciais OAuth 2.0 para Android
5. Adicione a SHA-1 do seu projeto ao console:
   ```bash
   flutter run -v 2>&1 | grep SHA1
   ```
6. Adicione o `google-services.json` em `android/app/`

#### Para iOS:
1. Siga os passos 1-3 acima
2. Configure as credenciais OAuth 2.0 para iOS
3. Adicione o `GoogleService-Info.plist` em `ios/Runner/`

#### Configuração Local:
Para desenvolvimento local com Google Sign-In, edite `lib/main.dart`:

```dart
_googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  // Para desenvolvimento local, você pode adicionar clientId específico
);
```

### Passo 3: Executar a Aplicação

```bash
# Para Android
flutter run

# Para iOS
flutter run -d ios

# Para Web
flutter run -d chrome
```

## 🎯 Como Usar

### 1. Primeiro Login
- Clique em **"Entrar com Google"**
- Selecione sua conta Google
- Você será configurado como **Owner** (Proprietário)

### 2. Enviar Convite para Colaborador
1. Clique no botão **"Convidar"** no AppBar (apenas visível para Owner)
2. Digite o email do colaborador
3. Selecione o tipo de acesso:
   - **Collaborator**: Pode editar e visualizar transações
   - **Viewer**: Apenas visualiza transações
4. Clique em **"Enviar Convite"**

### 3. Gerenciar Colaboradores
1. Clique no avatar do usuário no canto superior direito
2. Selecione **"Colaboradores"**
3. Visualize colaboradores ativos e convites pendentes
4. Remova colaboradores usando o ícone de lixeira

### 4. Adicionar Transação
1. Clique no botão **"Nova Transação"** (flutuante)
2. Preencha os campos:
   - **Descrição**: Nome da transação
   - **Valor**: Valor em R$
   - **Data**: Selecione a data
   - **Categoria**: Selecione entre Entrada ou Saída
3. Clique em **"Salvar Transação"**

### 5. Visualizar Transações
- **Dashboard**: Resumo geral com gráficos
- **Entradas**: Apenas transações de renda
- **Saídas**: Apenas despesas
- **Todas**: Todas as transações

## 📱 Estrutura da Aplicação

```
lib/
├── main.dart
│   ├── Modelos (Category, Transaction, User, Invitation)
│   ├── Componentes (Cards, Forms, Screens)
│   ├── Lógica de Estado
│   └── UI Principal
```

## 🔐 Controle de Acesso

| Ação | Owner | Collaborator | Viewer | Guest |
|------|-------|--------------|--------|-------|
| Visualizar | ✅ | ✅ | ✅ | ❌ |
| Adicionar | ✅ | ✅ | ❌ | ❌ |
| Editar | ✅ | ✅ | ❌ | ❌ |
| Deletar | ✅ | ✅ | ❌ | ❌ |
| Convidar | ✅ | ❌ | ❌ | ❌ |
| Remover Collab | ✅ | ❌ | ❌ | ❌ |

## 🌐 Funcionalidades Futuras

- [ ] Integração com Firebase Realtime Database
- [ ] Sincronização em tempo real de transações
- [ ] Notificações de novos convites
- [ ] Histórico de alterações
- [ ] Exportar relatórios em PDF/Excel
- [ ] Autenticação biométrica
- [ ] Modo offline
- [ ] Temas customizáveis

## 🐛 Troubleshooting

### Erro ao fazer login
1. Verifique se as credenciais OAuth estão corretas
2. Certifique-se de que o SHA-1 do projeto está configurado
3. Limpe o cache: `flutter clean && flutter pub get`

### Transações não aparecem
1. Certifique-se de que está autenticado
2. Verifique se a data da transação é válida
3. Reinicie o aplicativo

### Convites não são enviados
- Nota: No modo mock, os convites são armazenados localmente apenas
- Para produção, implemente a integração com Firebase ou seu backend

## 📞 Suporte

Para dúvidas ou issues, consulte a documentação:
- [Flutter Documentation](https://flutter.dev/docs)
- [Google Sign-In Plugin](https://pub.dev/packages/google_sign_in)
- [Firebase Documentation](https://firebase.flutter.dev/)

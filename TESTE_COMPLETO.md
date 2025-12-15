# 🧪 Guia de Testes - Modo Mock

Este guia explica como testar a aplicação **sem necessidade de configurar Google Sign-In**.

## ⚡ Teste Rápido (Sem Configuração Google)

Para testar rapidamente sem configurar credenciais do Google, você pode criar um usuário mock:

### Modificação Temporária para Testes

Edite `lib/main.dart` e adicione este método à classe `_MainAppState`:

```dart
// Adicione este método para testes rápidos
void _mockSignIn() {
  setState(() {
    _currentUser = User(
      id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
      email: 'teste@example.com',
      name: 'Usuário Teste',
      photoUrl: null,
      role: 'owner',
    );
    _selectedIndex = 0;
  });
  _showSuccessSnackBar('Login Mock realizado');
}
```

Em `_buildGuestScreen()`, substitua:
```dart
// De:
onPressed: _signInWithGoogle,

// Para:
onPressed: _mockSignIn,  // Teste rápido
```

---

## 📋 Checklist de Testes

### 1️⃣ Testes de Autenticação

**Objetivo**: Verificar login/logout

```
□ Inicial: Deve exibir tela de login
□ Clica em "Entrar com Google"
□ Resultado: Deve ir para Dashboard
□ Logout: Menu > Sair
□ Resultado: Volta para tela de login
```

### 2️⃣ Testes de Adição de Transação

**Objetivo**: Verificar criação de transações

```
□ Login como Owner
□ Clica em "Nova Transação"
□ Preenche: 
  - Descrição: "Teste"
  - Valor: "100,50"
  - Data: Hoje
  - Categoria: Salário (Entrada)
□ Clica "Salvar"
□ Resultado: Transação aparece em "Todas"
```

### 3️⃣ Testes de Convite de Colaborador

**Objetivo**: Verificar sistema de convites

```
□ Login como Owner
□ Clica em "Convidar"
□ Modal: 
  - Email: "collab@example.com"
  - Role: "Collaborator"
□ Clica "Enviar Convite"
□ Resultado: Aparece toast "Convite enviado"
□ Menu > Colaboradores
□ Resultado: Email aparece em "Convites Pendentes"
```

### 4️⃣ Testes de Permissões (Collaborator)

**Objetivo**: Verificar permissões de colaborador

```
□ Modificar usuário para role "collaborator"
□ FAB "Nova Transação" deve estar visível
□ Deve conseguir adicionar transação
□ Botão "Convidar" NÃO deve aparecer
□ Menu não deve ter "Colaboradores"
□ Ao tentar deletar: Deve mostrar erro
```

### 5️⃣ Testes de Permissões (Viewer)

**Objetivo**: Verificar permissões de visualizador

```
□ Modificar usuário para role "viewer"
□ FAB "Nova Transação" deve estar ESCONDIDO
□ Ao clicar em + transação: Erro "sem permissão"
□ Deve conseguir visualizar Dashboard
□ Deve conseguir visualizar transações
□ Não pode deletar transações
```

### 6️⃣ Testes de Dashboard

**Objetivo**: Verificar visualização de dados

```
□ Verificar cards de resumo:
  - Saldo Atual
  - Total de Entradas
  - Total de Saídas
□ Verificar gráfico anual
□ Verificar categorias Top 5
□ Números devem estar corretos
```

### 7️⃣ Testes de Filtros

**Objetivo**: Verificar filtros de transações

```
□ Aba "Entradas":
  - Deve mostrar apenas entradas
  - Devem ter cor verde
□ Aba "Saídas":
  - Deve mostrar apenas saídas
  - Devem ter cor vermelha
□ Aba "Todas":
  - Deve mostrar todas
  - Deve permitir scroll
```

### 8️⃣ Testes de Formulário

**Objetivo**: Verificar validação de forma

```
□ Tentar salvar sem descrição:
  - Deve mostrar erro
□ Tentar salvar com valor inválido:
  - Deve mostrar erro
□ Descrição com caracteres especiais:
  - Deve aceitar
□ Datas futuras:
  - Deve aceitar
```

---

## 🧩 Testes de UI Responsividade

### Tamanhos de Tela

```dart
// Testar em diferentes resoluções:
□ Mobile (360x640)        - App deve adaptar
□ Tablet (768x1024)       - Grid deve ter 2 colunas
□ Desktop (1920x1080)     - UI deve expandir bem
```

### Orientação

```
□ Portrait (vertical):     OK
□ Landscape (horizontal):  OK
```

---

## 🎨 Testes de Tema

```
□ Cards com cores corretas
□ Ícones visíveis e alinhados
□ Texto legível em todas as telas
□ Contraste adequado
□ Material Design 3 aplicado
```

---

## 🔄 Testes de Navegação

```
□ BottomNavBar:
  - Dashboard → Entradas → OK
  - Entradas → Saídas → OK
  - Saídas → Todas → OK
  - Todas → Dashboard → OK

□ Menu do usuário:
  - Clica no avatar
  - Menu abre
  - Menu fecha ao clicar fora
  - Opções funcionam

□ Botão voltar:
  - Modal fecha
  - Mantém estado da tela anterior
```

---

## 📊 Testes com Dados

### Dados Iniciais

A app vem com 12 transações mock:

```
✓ Salário Mensal (4500) - Entrada
✓ Aluguel (1500) - Saída
✓ Supermercado (350) - Saída
... mais 9 transações
```

### Adicionar Dados

```
□ Adicionar 5 transações de teste
□ Verificar se aparecem em:
  - Dashboard (números atualizam)
  - Filtro correto (Entradas/Saídas)
  - Data correta

□ Deletar 2 transações
□ Verificar se desaparecem
□ Verificar se números atualizam
```

---

## 🐛 Testes de Edge Cases

### Valores Extremos

```
□ Valor muito grande (999999.99)
□ Valor muito pequeno (0.01)
□ Valor negativo (-100) - Deve rejeitar?
□ Valor com muitas casas decimais (100.123456)
```

### Datas Extremas

```
□ Data muito antiga (01/01/1900)
□ Data futura (31/12/2099)
□ Hoje
□ Ontem
```

### Descrições Longas

```
□ Descrição com 50 caracteres
□ Descrição com 200 caracteres
□ Descrição com emoji 🎉
□ Descrição com caracteres especiais !@#$%
```

---

## 🔐 Testes de Segurança

```
□ Logout remove dados do usuário
□ Guest não pode acessar funções protegidas
□ Permissões são validadas antes da ação
□ Dados sensíveis não aparecem em logs
□ URLs de imagem carregam com sucesso
```

---

## ⚡ Testes de Performance

```
□ App inicia em menos de 3 segundos
□ Dashboard carrega rápido
□ Scroll lista é suave
□ Adição de transação é instantânea
□ Não há travamentos notáveis
```

---

## 🧪 Exemplo de Teste Completo

### Cenário: "User Completo"

1. **Setup**
   - App em clean state
   - Nenhum usuário logado

2. **Testes**
   ```
   ✓ Tela de login exibida
   ✓ Clica "Entrar"
   ✓ User faz login
   ✓ Dashboard exibido
   ✓ Cards mostram valores corretos
   ✓ Gráfico renderiza
   ✓ Clica "Nova Transação"
   ✓ Form abre
   ✓ Preenche campos
   ✓ Salva transação
   ✓ Tela "Todas" exibida
   ✓ Transação nova aparece
   ✓ Clica novamente
   ✓ Adiciona mais
   ✓ Números atualizam
   ✓ Menu > Colaboradores
   ✓ Enviou convite
   ✓ Convite aparece na lista
   ✓ Menu > Sair
   ✓ Volta para login
   ```

---

## 📱 Teste em Device Real

```bash
# Conecte seu device Android/iOS
flutter devices

# Execute:
flutter run -d <device-id>

# Ou para iOS:
flutter run -d ios
```

---

## 📸 Screenshots para Validação

Capture imagens de:

```
□ Tela de Login
□ Dashboard (com dados)
□ Adição de Transação
□ Lista de Transações
□ Menu de Usuário
□ Dialog de Colaboradores
□ Modal de Convite
□ Filtro de Saídas
```

---

## 📝 Relatório de Testes

Use esta template:

```markdown
# Relatório de Testes - [Data]

## Ambiente
- Device: [Android/iOS/Web]
- Resolução: [Tamanho]
- Flutter Version: [Versão]

## Testes Executados
- [x] Autenticação
- [x] Convites
- [x] Transações
- [x] Permissões

## Bugs Encontrados
1. ...

## Observações
- ...

## Status Final
✓ APROVADO / ✗ FALHOU
```

---

## 🚀 Próximas Etapas Após Testes

1. Corrigir bugs encontrados
2. Otimizar performance
3. Integrar Firebase
4. Deploy em produção
5. Coletar feedback dos usuários

---

**Bom teste! 🎉**

Se encontrar bugs, documente e crie um issue.
Se tudo passar, parabéns! Seu app está pronto! 🎊

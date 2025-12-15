# 🧪 Teste Rápido - Login Mock

## ✨ Nova Funcionalidade: Login Mock

Para facilitar testes **sem configurar Google Sign-In**, foi adicionado um botão de login mock na tela de login.

### 🎯 Como Testar

#### 1. **Executar a Aplicação**
```bash
flutter run
```

#### 2. **Tela de Login**
Você verá dois botões:
- **"Entrar com Google"** - Login real (requer configuração Google)
- **"Ou Entrar como Teste (Mock)"** - Login de teste instantâneo ⭐

#### 3. **Clicar em "Ou Entrar como Teste (Mock)"**
```
Usuário: Tiago Neves
Email:   tiago@appfinancas.com
Papel:   Owner (acesso total)
```

---

## 🧪 Testes que você pode fazer

### ✅ Teste 1: Dashboard
1. Clique em "Ou Entrar como Teste (Mock)"
2. Veja o Dashboard com dados
3. Verifique cards de Saldo, Entradas, Saídas
4. Veja o gráfico anual e categorias

### ✅ Teste 2: Visualizar Transações
1. Clique na aba "Entradas"
2. Clique na aba "Saídas"
3. Clique na aba "Todas"
4. Verifique filtros funcionando

### ✅ Teste 3: Adicionar Transação
1. Clique no botão **"+ Nova Transação"** (FAB)
2. Preencha:
   - **Descrição**: "Teste de Transação"
   - **Valor**: "123,45"
   - **Data**: Escolha uma data
   - **Categoria**: Selecione qualquer uma
3. Clique **"Salvar Transação"**
4. Veja a transação aparecer em "Todas"
5. Dashboard atualiza automaticamente

### ✅ Teste 4: Deletar Transação
1. Vá para aba "Todas"
2. Clique no **ícone de lixeira** em qualquer transação
3. Confirme a deleção
4. Transação desaparece
5. Dashboard atualiza

### ✅ Teste 5: Convidar Colaborador
1. Clique no botão **"Convidar"** no AppBar
2. Preencha:
   - **Email**: qualquer email
   - **Tipo**: Colaborator ou Viewer
3. Clique **"Enviar Convite"**
4. Veja mensagem de sucesso

### ✅ Teste 6: Ver Colaboradores
1. Clique no avatar (inicial **"T"**) no canto superior direito
2. Clique em **"Colaboradores"**
3. Veja convites pendentes
4. Remova colaboradores se houver

### ✅ Teste 7: Menu do Usuário
1. Clique no avatar **"T"** (com fundo azul)
2. Veja:
   - Seu nome: **Tiago Neves**
   - Email: **tiago@appfinancas.com**
   - Papel: **Owner**
3. Opção de **"Colaboradores"**
4. Botão **"Sair"**

### ✅ Teste 8: Logout
1. Clique no avatar **"T"**
2. Clique em **"Sair"**
3. Volta para tela de login
4. Clique em "Ou Entrar como Teste" novamente para re-entrar

---

## 🎨 Avatar do Usuário

O avatar foi melhorado e agora mostra:
- ✅ **Fundo azul (primaryColor)**
- ✅ **Inicial do nome em branco** (T para Tiago)
- ✅ **Maior e mais visível**
- ✅ **Clicável para abrir menu**

```
┌─ AppBar ──────────────────────────────────┐
│ 🐷 FinançasApp    [Convidar]    [🟦 T]    │
│                                            │
│ Clique no "T" para abrir menu             │
└────────────────────────────────────────────┘
```

---

## 🎯 Dados de Teste

### Usuário Mock
```
Nome:   Tiago Neves
Email:  tiago@appfinancas.com
ID:     mock-user-001
Papel:  Owner
```

### Transações Iniciais (já vêm precarregadas)
- Salário Mensal: R$ 4.500,00 (Entrada)
- Aluguel: R$ 1.500,00 (Saída)
- Supermercado: R$ 350,50 (Saída)
- ... mais 9 transações

---

## 📋 Checklist de Testes

```
□ Login Mock funciona
□ Dashboard carrega com dados
□ Avatar mostra "T" com fundo azul
□ Abrir menu do usuário
□ Ver dados do perfil
□ Adicionar transação
□ Transação aparece na lista
□ Dashboard atualiza
□ Deletar transação
□ Convidar colaborador
□ Ver colaboradores
□ Logout funciona
□ Volta para tela de login
□ Login novamente funciona
```

---

## 🚀 Fluxo Completo de Teste

```
1. Executar app
   └─ flutter run

2. Clicar em "Ou Entrar como Teste"
   └─ Login instantâneo

3. Ver Dashboard
   └─ Dados precarregados

4. Adicionar transação
   └─ Clique [+ Nova Transação]

5. Preencher e salvar
   └─ Transação aparece em "Todas"

6. Deletar transação
   └─ Clique no ícone de lixeira

7. Convidar colaborador
   └─ Clique em [Convidar]

8. Ver colaboradores
   └─ Clique em avatar > [Colaboradores]

9. Logout
   └─ Clique em avatar > [Sair]

10. Login novamente
    └─ Volta para tela de login
```

---

## ⚡ Dicas de Teste

1. **Teste diferentes valores**
   - Valores pequenos: 0.01
   - Valores grandes: 9999.99
   - Com vírgula: 123,45
   - Com ponto: 123.45

2. **Teste diferentes categorias**
   - Entradas (Salário, Investimentos)
   - Saídas (Alimentação, Moradia)

3. **Teste datas**
   - Hoje
   - Passado
   - Futuro (se permitido)

4. **Teste descrições**
   - Texto curto
   - Texto longo
   - Com caracteres especiais

---

## 🔄 Resetar para Testar de Novo

Se quiser resetar os dados:

1. Clique em "Sair"
2. Feche a app
3. Execute `flutter run` novamente
4. Os dados voltam ao estado inicial

---

## 📱 Layout Responsivo

O app foi testado em:
- ✅ Mobile (360px)
- ✅ Tablet (768px)
- ✅ Desktop (1920px)

Redimensione a janela para testar responsividade!

---

## 🎊 Tudo Pronto!

Você agora pode testar **TODAS as funcionalidades** sem configurar Google Sign-In:
- ✅ Login
- ✅ Adicionar transações
- ✅ Deletar transações
- ✅ Convidar colaboradores
- ✅ Gerenciar colaboradores
- ✅ Visualizar dashboard
- ✅ Filtrar transações
- ✅ Logout

**Clique em "Ou Entrar como Teste (Mock)" e comece a testar!** 🚀

---

**Quando estiver pronto para usar Google real:**
- Siga: **GOOGLE_SIGNIN_SETUP.md**
- Configure credenciais no Google Cloud Console
- O botão "Entrar com Google" funcionará como esperado

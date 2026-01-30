# ✅ Guia de Teste - Melhorias na Aba de Relatórios

## 🚀 Como Testar as Mudanças

### 1️⃣ Compilação e Execução

```powershell
# Navegar até o diretório do projeto
cd "c:\Users\Tiago Neves\Documents\GitHub\appfinancas"

# Obter dependências
flutter pub get

# Executar o app em debug
flutter run

# Ou executar em um dispositivo/emulador específico
flutter run -d <device_id>
```

### 2️⃣ Validação de Código

```powershell
# Analisar código para erros
flutter analyze

# Formatar código
flutter format lib/main.dart
```

---

## 🎯 Checklist de Testes Visuais

### Gráfico de Pizza

- [ ] **Animação ao carregar**
  - O gráfico deve animar suavemente por ~1.5 segundos ao abrir
  - Os arcos devem crescer de forma suave
  - A animação usa curva "easeOutCubic"

- [ ] **Visual do gráfico**
  - Deve ter um "buraco" no centro (visual donut)
  - Deve ter sombra ao redor (efeito 3D)
  - Bordas devem ser arredondadas e suaves
  - Cores: Verde para entradas, Rosa/Vermelho para saídas

- [ ] **Legenda**
  - Lado direito do gráfico mostrando cores
  - Valores e percentuais corretos
  - Formatação monetária correta (R$ XXXXX,XX)

### Cards de Resumo (NOVO)

- [ ] **Card de Entradas**
  - Título: "Entradas"
  - Valor total em verde
  - Ícone de seta para cima no canto direito
  - Badge com percentual (ex: "60% do total")
  - Fundo com gradiente verde suave

- [ ] **Card de Saídas**
  - Título: "Saídas"
  - Valor total em rosa/vermelho
  - Ícone de seta para baixo no canto direito
  - Badge com percentual (ex: "40% do total")
  - Fundo com gradiente rosa/vermelho suave

- [ ] **Posicionamento**
  - Cards logo abaixo do gráfico
  - Distância correta (25px de espaçamento)
  - Alinhamento horizontal correto

### Responsividade

#### Mobile (< 600px width)
- [ ] **Gráfico** ocupa toda a largura
- [ ] **Cards de resumo** ficam em 1 coluna, um sobre o outro
- [ ] **Tabelas de categorias** ficam em 1 coluna
- [ ] Tudo alinhado verticalmente, legível

#### Desktop (≥ 600px width)
- [ ] **Gráfico** ocupa toda a largura (topo)
- [ ] **Cards de resumo** ficam lado a lado (2 colunas)
- [ ] **Tabelas de categorias** ficam lado a lado (2 colunas)
- [ ] Bom uso do espaço horizontal

### Funcionalidade de Mês

- [ ] **Seletor de mês** funciona (botões < e >)
- [ ] Ao mudar de mês:
  - Gráfico é atualizado
  - Animação é disparada novamente
  - Cards de resumo mostram novos valores
  - Categorias são atualizadas
- [ ] Dados mostram informações corretas para o mês selecionado

---

## 🔍 Validações de Dados

### Cálculos Corretos

- [ ] **Valor total de Entradas**
  - Soma correta de todas as transações de entrada do mês
  - Formatação: R$ com duas casas decimais
  - Alinhamento: Esquerda

- [ ] **Valor total de Saídas**
  - Soma correta de todas as transações de saída do mês
  - Formatação: R$ com duas casas decimais
  - Alinhamento: Esquerda

- [ ] **Percentuais**
  - Entrada: (totalEntrada / totalGeral) × 100
  - Saída: (totalSaída / totalGeral) × 100
  - Deve estar no badge dos cards
  - Formato: "XX.X%" (uma casa decimal)

### Gráfico vs Cards vs Tabelas

- [ ] Os totais mostrados no gráfico correspondem aos cards
- [ ] Os totais dos cards correspondem à soma das categorias
- [ ] Nenhuma discrepância de valores

---

## 📱 Testes Específicos por Dispositivo

### Emulador Android
```powershell
# Listar emuladores disponíveis
flutter emulators

# Executar no emulador
flutter run -d <emulator_id>
```

Testes:
- [ ] Rendimento (60 FPS)
- [ ] Animação suave
- [ ] Sem lag ao navegar
- [ ] Rotação de tela funciona

### iPhone Simulador
```powershell
# Abrir simulador iOS
open -a Simulator

# Executar no simulador
flutter run -d <simulator_id>
```

Testes:
- [ ] Visual consistente
- [ ] Animação suave
- [ ] Cores corretas
- [ ] Textos legíveis

### Dispositivo Físico
```powershell
# Conectar dispositivo via USB

# Listar dispositivos
flutter devices

# Executar no dispositivo
flutter run -d <device_id>
```

Testes:
- [ ] Performance em dispositivo real
- [ ] Animação suave
- [ ] Responsividade ao toque
- [ ] Sem aquecimento excessivo

---

## 🐛 Possíveis Problemas e Soluções

### Problema: Animação não funciona
**Solução**:
- Verifique se `AnimationController` está sendo inicializado
- Verifique se `_controller.forward()` está sendo chamado
- Limpe o cache: `flutter clean` e `flutter pub get`

### Problema: Cards não aparecem
**Solução**:
- Verifique se há dados de transações no mês
- Verifique se o método `_buildSummaryCard()` está sendo chamado
- Verifique o console para erros de compilação

### Problema: Valores incorretos
**Solução**:
- Verifique se as transações estão sendo filtradas por mês
- Verifique se as categorias estão categorizadas como "income" ou "expense"
- Verifique a função `formatCurrency()`

### Problema: Layout desalinhado em mobile
**Solução**:
- Verifique os valores de `crossAxisCount` no `GridView.count`
- Verifique os valores de `childAspectRatio`
- Teste com diferentes tamanhos de tela

### Problema: Cores desbotadas
**Solução**:
- Verifique o valor alpha das cores (deve ser entre 0 e 255)
- Verifique se `color.withAlpha()` está sendo usado corretamente
- Não use `withOpacity()` (deprecated)

---

## 📊 Casos de Teste Específicos

### Caso 1: Mês sem transações
**Esperado**:
- Tela mostra estado vazio
- Mensagem: "Sem dados para este mês"
- Cards de resumo não são exibidos

**Como testar**:
1. Selecionar mês com nenhuma transação
2. Verificar se o estado vazio é mostrado

### Caso 2: Apenas entradas
**Esperado**:
- Gráfico mostra apenas a cor verde
- Card de Entradas mostra 100%
- Card de Saídas mostra 0%

**Como testar**:
1. Criar transações apenas de entrada
2. Abrir Relatórios

### Caso 3: Apenas saídas
**Esperado**:
- Gráfico mostra apenas a cor rosa/vermelha
- Card de Entradas mostra 0%
- Card de Saídas mostra 100%

**Como testar**:
1. Criar transações apenas de saída
2. Abrir Relatórios

### Caso 4: Entradas e Saídas balanceadas
**Esperado**:
- Gráfico mostra 50% verde e 50% rosa
- Ambos os cards mostram ~50%

**Como testar**:
1. Criar transações com valores iguais
2. Abrir Relatórios

---

## 🎬 Gravação de Vídeo de Teste

Para documentar o funcionamento:

```powershell
# Flutter oferece suporte a captura de screenshots
flutter screenshot

# Para vídeo, use ferramentas do sistema operacional:
# Windows: Win + G (Game Bar)
# macOS: Cmd + Shift + 5
# Linux: gnome-screenshot ou similar
```

---

## 📝 Relatório de Teste

Use este template para documentar os testes:

```markdown
# Relatório de Teste - Melhorias em Relatórios

**Data**: [DATE]
**Testador**: [NAME]
**Dispositivo**: [DEVICE]
**Versão Flutter**: [VERSION]

## Resultados

### Gráfico
- [ ] Animação funciona ✓ / ✗
- [ ] Visual correto ✓ / ✗
- [ ] Cores corretas ✓ / ✗
- [ ] Observações: ________________

### Cards
- [ ] Entradas visível ✓ / ✗
- [ ] Saídas visível ✓ / ✗
- [ ] Valores corretos ✓ / ✗
- [ ] Percentuais corretos ✓ / ✗
- [ ] Observações: ________________

### Responsividade
- [ ] Mobile correto ✓ / ✗
- [ ] Desktop correto ✓ / ✗
- [ ] Observações: ________________

## Bugs Encontrados
1. [Descrição do bug]
2. [Como reproduzir]
3. [Comportamento esperado]
4. [Comportamento atual]

## Aprovação
- [ ] Tudo funcionando corretamente - APROVADO ✓
- [ ] Existem issues a resolver - REPROVADO ✗
```

---

## 🔄 Fluxo de Teste Recomendado

1. ✅ Compilação sem erros
2. ✅ Execução sem crashes
3. ✅ Animação do gráfico
4. ✅ Cards de resumo visíveis
5. ✅ Valores corretos
6. ✅ Navegação de meses
7. ✅ Responsividade mobile
8. ✅ Responsividade desktop
9. ✅ Performance (60 FPS)
10. ✅ Casos extremos (sem dados, apenas entradas, etc)

---

## 📞 Contato para Issues

Se encontrar problemas:
1. Descreva o problema em detalhes
2. Inclua screenshots/vídeos se possível
3. Mencione o dispositivo e versão Flutter
4. Incluir logs (veja com `flutter logs`)

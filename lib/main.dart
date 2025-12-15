import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_svg/flutter_svg.dart';
// (kIsWeb no longer required here)
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'auth/auth_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth/auth_service.dart';
import 'auth/mock_auth_service.dart';
import 'auth/google_auth_service.dart';
import 'models/user.dart';

// ===================================================================
// 1. CONSTANTES, MODELOS E UTILITÁRIOS (Unificados no arquivo principal)
// ===================================================================

// Mock de Cores
const Color primaryColor = Color.fromARGB(255, 0, 183, 255); // Indigo-600
const Color secondaryColor = Color(0xFFF3F4F6); // Gray-100
const Color incomeColor = Color(0xFF10B981); // Emerald-500
const Color expenseColor = Color(0xFFF43F5E); // Rose-500
const Color successColor = Color(0xFF10B981);

// Mock de Ícones (usando Material Icons)
Map<String, IconData> iconMap = {
  'LayoutDashboard': Icons.dashboard,
  'ArrowUpCircle': Icons.arrow_circle_up,
  'ArrowDownCircle': Icons.arrow_circle_down,
  'DollarSign': Icons.attach_money,
  'ShoppingCart': Icons.shopping_cart,
  'Home': Icons.home,
  'Car': Icons.directions_car,
  'Utensils': Icons.restaurant,
  'Briefcase': Icons.work,
  'Shield': Icons.local_hospital,
  'PiggyBank': Icons.savings,
  'Settings': Icons.settings,
  'Users': Icons.people,
  'Trash2': Icons.delete,
  'Plus': Icons.add,
  'X': Icons.close,
  'ListChecks': Icons.list,
};

// Small helper to provide circular hover effect for profile menu button.
class _ProfileMenuButton extends StatefulWidget {
  final Widget child;
  const _ProfileMenuButton({Key? key, required this.child}) : super(key: key);

  @override
  State<_ProfileMenuButton> createState() => _ProfileMenuButtonState();
}

class _ProfileMenuButtonState extends State<_ProfileMenuButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final hoverColor = Theme.of(context).colorScheme.primary.withOpacity(_hovering ? 0.08 : 0.0);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: hoverColor,
            shape: BoxShape.circle,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// --- Modelos de Dados ---
class Category {
  final String id;
  final String name;
  final String type; // 'income' ou 'expense'
  final String iconName;

  Category.fromMap(Map<String, dynamic> data)
    : id = data['id'],
      name = data['name'],
      type = data['type'],
      iconName = data['icon'];
}

class Transaction {
  final String id;
  final String description;
  final double amount;
  final String categoryId;
  final DateTime date;

  Transaction.fromMap(Map<String, dynamic> data)
    : id = data['id'],
      description = data['description'],
      amount = data['amount'].toDouble(),
      categoryId = data['categoryId'],
      date = DateTime.parse(data['date']);
}

// --- Custom Bottom Bar with Notch ---
class BottomBarItemData {
  final IconData icon;
  final String label;
  BottomBarItemData({required this.icon, required this.label});
}

class BottomBarWithNotch extends StatefulWidget {
  final List<BottomBarItemData> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final Color backgroundColor;
  final double height;

  const BottomBarWithNotch({
    Key? key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
    this.backgroundColor = Colors.white,
    this.height = 78,
  }) : super(key: key);

  @override
  State<BottomBarWithNotch> createState() => _BottomBarWithNotchState();
}

class _BottomBarWithNotchState extends State<BottomBarWithNotch> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final itemWidth = width / widget.items.length;
      const notchRadius = 28.0;
      const notchDepth = 10.0; // make the notch shallow so the circle sits above with a gap
      const gap = 6.0; // small space between circle bottom and the tab bar
      final notchCenterRaw = itemWidth * widget.selectedIndex + itemWidth / 2;
      final notchCenter = (notchCenterRaw.clamp(notchRadius + 12.0, width - notchRadius - 12.0)).toDouble();

      return SizedBox(
        height: widget.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Background with notch (shallow)
            ClipPath(
              clipper: _BottomBarClipper(notchCenter: notchCenter, notchRadius: notchRadius * 0.75 /* use smaller radius for notch */ , notchDepth: notchDepth),
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8, offset: const Offset(0, -2)),
                  ],
                ),
              ),
            ),

            // Row of items with hover backgrounds
            Positioned.fill(
              top: 0,
              child: Row(
                children: widget.items.asMap().entries.map((e) {
                  final i = e.key;
                  final it = e.value;
                  final selected = i == widget.selectedIndex;
                  final hovered = i == _hoveredIndex;
                  return Expanded(
                    child: MouseRegion(
                      onEnter: (_) => setState(() => _hoveredIndex = i),
                      onExit: (_) => setState(() => _hoveredIndex = null),
                      child: GestureDetector(
                        onTap: () => widget.onTap(i),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: selected ? 8 : 12),
                            // Icon with hover background stacked behind
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: hovered ? 48 : 0,
                                  height: hovered ? 48 : 0,
                                  decoration: BoxDecoration(
                                    color: widget.backgroundColor,
                                    shape: BoxShape.circle,
                                    boxShadow: hovered
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.06),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                Icon(
                                  it.icon,
                                  color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              it.label,
                              style: TextStyle(
                                fontSize: 11,
                                color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Floating circular selected icon positioned above the bar with a small gap
            Positioned(
              left: notchCenter - notchRadius,
              top: -(notchRadius * 2) - gap,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  key: ValueKey(widget.selectedIndex),
                  width: notchRadius * 2,
                  height: notchRadius * 2,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      widget.items[widget.selectedIndex].icon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _BottomBarClipper extends CustomClipper<Path> {
  final double notchCenter;
  final double notchRadius;
  final double notchDepth;
  _BottomBarClipper({required this.notchCenter, required this.notchRadius, this.notchDepth = 10.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    final r = notchRadius;
    final d = notchDepth.clamp(0.0, r);
    // Start at top-left
    path.moveTo(0, 0);
    // Line to left of notch
    final nx1 = notchCenter - r - 8;
    final nx2 = notchCenter + r + 8;
    path.lineTo(nx1 < 0 ? 0 : nx1, 0);
    // Notch - shallow curve using notchDepth
    path.quadraticBezierTo(notchCenter - r / 1.4, d * 0.6, notchCenter - r / 3, d);
    path.arcToPoint(Offset(notchCenter + r / 3, d), radius: Radius.circular(r), clockwise: false);
    path.quadraticBezierTo(notchCenter + r / 1.4, d * 0.6, nx2 > size.width ? size.width : nx2, 0);
    // Right top corner to right
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _BottomBarClipper oldClipper) {
    return oldClipper.notchCenter != notchCenter || oldClipper.notchRadius != notchRadius || oldClipper.notchDepth != notchDepth;
  }
}

// --- Modelo de Usuário ---
// User model moved to `lib/models/user.dart`.

// --- Modelo de Convite ---
class Invitation {
  final String id;
  final String email;
  final String role; // 'collaborator', 'viewer'
  final DateTime createdAt;
  final String createdBy;
  final bool accepted;

  Invitation({
    required this.id,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.createdBy,
    this.accepted = false,
  });

  Invitation.fromMap(Map<String, dynamic> data)
    : id = data['id'],
      email = data['email'],
      role = data['role'],
      createdAt = DateTime.parse(data['createdAt']),
      createdBy = data['createdBy'],
      accepted = data['accepted'] ?? false;

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'role': role,
    'createdAt': createdAt.toIso8601String(),
    'createdBy': createdBy,
    'accepted': accepted,
  };
}

// --- Funções de Formatação ---
String formatCurrency(double value) {
  // Formata valores como R$ 1.000,00 (separador de milhar)
  String sign = value < 0 ? '-' : '';
  double absValue = value.abs();

  String intPart = absValue.toStringAsFixed(0);
  String decimalPart = (absValue % 1)
      .toStringAsFixed(2)
      .substring(2); // Pega .xx

  // Adiciona separador de milhar
  String formatted = '';
  int count = 0;
  for (int i = intPart.length - 1; i >= 0; i--) {
    if (count > 0 && count % 3 == 0) {
      formatted = '.' + formatted;
    }
    formatted = intPart[i] + formatted;
    count++;
  }

  return '$sign R\$ $formatted,$decimalPart';
}

String formatDate(DateTime date) {
  // Formata a data em PT-BR
  return DateFormat('dd/MM/yyyy', 'pt_BR').format(date);
}

// --- Dados Mock (Simulando Banco de Dados) ---
final List<Map<String, dynamic>> mockCategoriesData = [
  {'id': 'cat-1', 'name': 'Salário', 'type': 'income', 'icon': 'Briefcase'},
  {'id': 'cat-2', 'name': 'Alimentação', 'type': 'expense', 'icon': 'Utensils'},
  {'id': 'cat-3', 'name': 'Moradia', 'type': 'expense', 'icon': 'Home'},
  {
    'id': 'cat-4',
    'name': 'Investimentos',
    'type': 'income',
    'icon': 'PiggyBank',
  },
  {'id': 'cat-5', 'name': 'Lazer', 'type': 'expense', 'icon': 'Car'},
];

final List<Map<String, dynamic>> mockTransactionsData = [
  {
    'id': 't1',
    'description': 'Salário Mensal',
    'amount': 4500.00,
    'categoryId': 'cat-1',
    'date': '2024-10-01',
  },
  {
    'id': 't2',
    'description': 'Aluguel Outubro',
    'amount': 1500.00,
    'categoryId': 'cat-3',
    'date': '2024-10-05',
  },
  {
    'id': 't3',
    'description': 'Supermercado Mensal',
    'amount': 350.50,
    'categoryId': 'cat-2',
    'date': '2024-10-10',
  },
  {
    'id': 't4',
    'description': 'Salário Novembro',
    'amount': 4800.00,
    'categoryId': 'cat-1',
    'date': '2024-11-01',
  },
  {
    'id': 't5',
    'description': 'Jantar Fora',
    'amount': 120.00,
    'categoryId': 'cat-2',
    'date': '2024-11-03',
  },
  {
    'id': 't6',
    'description': 'Conta de Luz',
    'amount': 180.00,
    'categoryId': 'cat-3',
    'date': '2024-11-10',
  },
  {
    'id': 't7',
    'description': 'Dividendos Ações',
    'amount': 50.00,
    'categoryId': 'cat-4',
    'date': '2024-11-15',
  },
  {
    'id': 't8',
    'description': 'Cinema',
    'amount': 80.00,
    'categoryId': 'cat-5',
    'date': '2024-11-20',
  },
  {
    'id': 't9',
    'description': 'Aluguel Novembro',
    'amount': 1500.00,
    'categoryId': 'cat-3',
    'date': '2024-11-05',
  },
  {
    'id': 't10',
    'description': 'Salário Dezembro',
    'amount': 4700.00,
    'categoryId': 'cat-1',
    'date': '2024-12-01',
  },
  {
    'id': 't11',
    'description': 'Supermercado Natal',
    'amount': 550.00,
    'categoryId': 'cat-2',
    'date': '2024-12-12',
  },
  {
    'id': 't12',
    'description': 'Aluguel Dezembro',
    'amount': 1500.00,
    'categoryId': 'cat-3',
    'date': '2024-12-05',
  },
];

// ===================================================================
// 2. WIDGET: FORMULÁRIO DE NOVA TRANSAÇÃO
// ===================================================================

// Small helper widget to render the app logo.
// On web some complex SVGs can fail in the vector parser, so we use
// a raster fallback (`assets/images/splash.png`) for web builds.
class AppLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxFit fit;

  const AppLogo({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    const svgPath = 'assets/images/logo.svg';
    const pngFallback = 'assets/images/splash.png';
    // Try to render the SVG everywhere. If it fails or is not supported,
    // fall back to the PNG asset. This ensures the logo appears on mobile
    // and web builds consistently.
    return SvgPicture.asset(
      svgPath,
      width: width,
      height: height,
      fit: fit,
      semanticsLabel: 'FinançasApp Logo',
      placeholderBuilder: (context) => Image.asset(
        pngFallback,
        width: width,
        height: height,
        fit: fit,
      ),
      // On error, the `placeholderBuilder` will show the PNG fallback.
    );
  }
}

class NewTransactionForm extends StatefulWidget {
  final List<Category> categories;
  final Function(Transaction) addTransaction;
  final Function(Transaction) updateTransaction;
  final Transaction? transactionToEdit;
  final String? defaultFilterType;

  const NewTransactionForm({
    super.key,
    required this.categories,
    required this.addTransaction,
    required this.updateTransaction,
    this.transactionToEdit,
    this.defaultFilterType,
  });

  @override
  State<NewTransactionForm> createState() => _NewTransactionFormState();
}

class _NewTransactionFormState extends State<NewTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  String _description = '';
  String _amount = '';
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();

  // Função auxiliar para formatar data com segurança
  String _formatDateSafe(DateTime date) {
    try {
      return formatDate(date);
    } catch (e) {
      // Fallback se houver erro com a localização
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  bool get _isEditing => widget.transactionToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final t = widget.transactionToEdit!;
      // Inicializa os campos do formulário com os dados da transação a ser editada.
      _description = t.description;
      // Formata o valor para usar vírgula, como esperado no input
      _amount = t.amount.toString().replaceAll('.', ',');
      _selectedCategoryId = t.categoryId;
      _selectedDate = t.date;
    } else {
      // Filtra categorias pelo tipo padrão se fornecido
      final categoriesToFilter = widget.defaultFilterType != null
          ? widget.categories.where((c) => c.type == widget.defaultFilterType).toList()
          : widget.categories;
      
      // Tenta pré-selecionar uma categoria padrão do tipo filtrado
      _selectedCategoryId = categoriesToFilter.isNotEmpty
          ? categoriesToFilter.first.id
          : null;
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _selectedCategoryId != null) {
      _formKey.currentState!.save();
      final newTransaction = Transaction.fromMap({
        // Mantém o ID original se estiver editando, ou 'temp' se for novo
        'id': _isEditing ? widget.transactionToEdit!.id : 'temp',
        'description': _description,
        // Converte a vírgula para ponto para o parse
        'amount': double.parse(_amount.replaceAll(',', '.')),
        'categoryId': _selectedCategoryId!,
        'date': _selectedDate.toIso8601String().substring(0, 10),
      });

      if (_isEditing) {
        widget.updateTransaction(newTransaction);
      } else {
        widget.addTransaction(newTransaction);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final incomeCategories = widget.categories
        .where((c) => c.type == 'income')
        .toList();
    final expenseCategories = widget.categories
        .where((c) => c.type == 'expense')
        .toList();

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isEditing ? 'Editar Transação' : 'Nova Transação',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              IconButton(
                icon: Icon(iconMap['X'], color: Colors.grey),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(height: 20),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Descrição',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
            onSaved: (value) => _description = value!,
            validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
            initialValue: _description,
          ),
          const SizedBox(height: 15),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Valor (R\$)',
              // Adiciona o valor inicial para o campo de valor.
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
            keyboardType: TextInputType.number,
            onSaved: (value) => _amount = value!,
            validator: (value) {
              if (value!.isEmpty) return 'Campo obrigatório';
              if (double.tryParse(value.replaceAll(',', '.')) == null)
                return 'Valor inválido. Use ponto ou vírgula.';
              return null;
            },
            initialValue: _amount,
          ),
          const SizedBox(height: 15),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Data: ${_formatDateSafe(_selectedDate)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.calendar_today, color: primaryColor),
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
                locale: const Locale('pt', 'BR'),
              );
              if (picked != null && picked != _selectedDate) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                  initialValue: _selectedCategoryId,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Selecione uma Categoria'),
                    ),
                    const DropdownMenuItem(
                      child: Divider(thickness: 2, height: 5),
                      value: 'divider1',
                      enabled: false,
                    ),
                    ...incomeCategories.map(
                      (cat) => DropdownMenuItem(
                        value: cat.id,
                        child: Text(
                          '${cat.name} (Entrada)',
                          style: TextStyle(color: incomeColor),
                        ),
                      ),
                    ),
                    const DropdownMenuItem(
                      child: Divider(thickness: 2, height: 5),
                      value: 'divider2',
                      enabled: false,
                    ),
                    ...expenseCategories.map(
                      (cat) => DropdownMenuItem(
                        value: cat.id,
                        child: Text(
                          '${cat.name} (Saída)',
                          style: TextStyle(color: expenseColor),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != 'divider1' && value != 'divider2') {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    }
                  },
                  validator: (value) =>
                      value == null ? 'Selecione uma categoria' : null,
                ),
              ),
              const SizedBox(width: 8),
              // Botão circular para adicionar categoria personalizada
              Material(
                color: Theme.of(context).colorScheme.primary,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkResponse(
                  onTap: () async {
                    // Dialog simples para adicionar categoria
                    final result = await showDialog<Map<String, String>>(
                      context: context,
                      builder: (context) {
                        String name = '';
                        String type = 'expense';
                        return AlertDialog(
                          title: const Text('Nova Categoria'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                decoration: const InputDecoration(labelText: 'Nome'),
                                onChanged: (v) => name = v,
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: type,
                                items: const [
                                  DropdownMenuItem(value: 'income', child: Text('Entrada')),
                                  DropdownMenuItem(value: 'expense', child: Text('Saída')),
                                ],
                                onChanged: (v) => type = v ?? 'expense',
                                decoration: const InputDecoration(labelText: 'Tipo'),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                            ElevatedButton(
                              onPressed: () {
                                if (name.trim().isEmpty) return;
                                Navigator.of(context).pop({'name': name.trim(), 'type': type});
                              },
                              child: const Text('Adicionar'),
                            ),
                          ],
                        );
                      },
                    );

                    if (result != null) {
                      // Criar categoria temporária e selecionar
                      final newId = 'cat_${DateTime.now().millisecondsSinceEpoch}';
                      final newCat = Category.fromMap({'id': newId, 'name': result['name']!, 'type': result['type']!, 'icon': 'PiggyBank'});
                      // Adiciona à lista (a referência vem do pai e deverá persistir)
                      widget.categories.add(newCat);
                      setState(() {
                        _selectedCategoryId = newCat.id;
                      });
                    }
                  },
                  customBorder: const CircleBorder(),
                  radius: 24,
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(child: Icon(Icons.add, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Salvar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// 3. WIDGET: TELA DE TRANSAÇÕES (Reutilizável para Entradas, Saídas, Todas)
// ===================================================================

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final Category category;
  final Color color;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.category,
    required this.color,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    // O widget Dismissible permite ações de deslizar.
    return Dismissible(
      key: Key(transaction.id),
      // Ação de confirmação para editar ou deletar.
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Deslizar para a direita (Excluir)
          if (onDelete != null) {
            // Aguarda a animação do dismiss para evitar sobreposição visual
            await Future.delayed(const Duration(milliseconds: 150));
            onDelete!();
          }
          // Retorna false para não remover o item automaticamente.
          // A remoção será controlada pelo estado do app.
          return false;
        } else if (direction == DismissDirection.endToStart) {
          // Deslizar para a esquerda (Editar)
          if (onEdit != null) {
            // Aguarda a animação do swipe terminar antes de abrir o diálogo
            await Future.delayed(const Duration(milliseconds: 150));
            onEdit!();
          }
          return false;
        }
        return false;
      },
      // Fundo para deslizar para a direita (Excluir)
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(iconMap['Trash2'], color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              'Excluir',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      // Fundo para deslizar para a esquerda (Editar)
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.blue[400],
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              'Editar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.edit, color: Colors.white),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: onEdit, // Clicar no card também edita
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withAlpha(102), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Ícone da Categoria
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    iconMap[category.iconName],
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Descrição
                      Text(
                        transaction.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Categoria e Data
                      Text(
                        '${category.name} • ${formatDate(transaction.date)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Valor
                Text(
                  formatCurrency(
                    transaction.amount,
                  ).replaceAll('-', ''), // Remove sinal para valores positivos
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TransactionsScreen extends StatelessWidget {
  final List<Transaction> transactions;
  final String filterType; // 'all', 'income', 'expense'
  final Category Function(String) getCategoryById;
  final Function(String) deleteTransaction;
  final Function(Transaction) editTransaction;
  final bool canEdit;

  const TransactionsScreen({
    super.key,
    required this.transactions,
    required this.filterType,
    required this.getCategoryById,
    required this.deleteTransaction,
    required this.editTransaction,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = transactions.where((t) {
      final cat = getCategoryById(t.categoryId);
      return filterType == 'all' || cat.type == filterType;
    }).toList();

    // Título da Tela
    String getTitle() {
      switch (filterType) {
        case 'income':
          return 'Entradas';
        case 'expense':
          return 'Saídas';
        case 'all':
        default:
          return 'Todas as Transações';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            getTitle(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredTransactions.length,
          itemBuilder: (context, index) {
            final t = filteredTransactions[index];
            final cat = getCategoryById(t.categoryId);
            final isIncome = cat.type == 'income';
            final color = isIncome ? incomeColor : expenseColor;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: TransactionCard(
                transaction: t,
                category: cat,
                color: color,
                // Permite editar/deletar apenas se tiver permissão
                onEdit: canEdit ? () => editTransaction(t) : null,
                onDelete: canEdit ? () => deleteTransaction(t.id) : null,
              ),
            );
          },
        ),
        if (filteredTransactions.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Text(
                'Nenhuma ${getTitle().toLowerCase()} encontrada.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        const SizedBox(height: 80), // Espaço para o FAB
      ],
    );
  }
}

// ===================================================================
// 4. WIDGET: TELA DE DASHBOARD
// ===================================================================

// --- Componente de Card Resumo ---
class SummaryCard extends StatelessWidget {
  final String title;
  final double value;
  final Color color;
  final bool isBalance;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    this.isBalance = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPositive = value >= 0;

    Color valueColor = color;
    if (isBalance) {
      valueColor = isPositive ? successColor : expenseColor;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withAlpha(102), width: 1),
      ),
      clipBehavior: Clip.hardEdge,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // Mantém a borda superior colorida já existente
          border: Border(top: BorderSide(color: color, width: 4)),
          color:
              Theme.of(context).cardTheme.color ??
              Theme.of(context).colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatCurrency(value),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Componente de Card com Gráfico ---
class ChartCard extends StatelessWidget {
  final String title;
  final Widget chartWidget;
  final double height;

  const ChartCard({
    super.key,
    required this.title,
    required this.chartWidget,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(height: height, child: chartWidget),
          ],
        ),
      ),
    );
  }
}

// --- Componente de Gráfico de Barras Anual ---
class AnnualBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final double maxIncome;
  final double maxExpense;

  const AnnualBarChart({
    super.key,
    required this.data,
    required this.maxIncome,
    required this.maxExpense,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('Sem dados anuais para exibir o gráfico.'),
      );
    }

    // Altura máxima da área do gráfico (base)
    const double maxHeight = 200;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        // Define a largura do SingleChildScrollView baseada no número de itens
        width: max(data.length * 80.0, MediaQuery.of(context).size.width - 32),
        height: maxHeight + 50, // Adiciona espaço para os rótulos
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: data.map((d) {
            final double income = d['income'] ?? 0.0;
            final double expense = d['expense'] ?? 0.0;
            final String year = d['year'].toString();

            // Calcula a altura proporcional das barras
            final double incomeHeight = maxIncome > 0
                ? (income / maxIncome) * maxHeight
                : 0;
            final double expenseHeight = maxExpense > 0
                ? (expense / maxExpense) * maxHeight
                : 0;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Bar Saída
                          Tooltip(
                            message: 'Saídas $year: ${formatCurrency(expense)}',
                            child: Container(
                              width: 15,
                              height: expenseHeight,
                              decoration: BoxDecoration(
                                color: expenseColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Bar Entrada
                          Tooltip(
                            message:
                                'Entradas $year: ${formatCurrency(income)}',
                            child: Container(
                              width: 15,
                              height: incomeHeight,
                              decoration: BoxDecoration(
                                color: incomeColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      year,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// --- Componente de Resumo por Categoria ---
class CategorySummaryCard extends StatelessWidget {
  final String title;
  final String icon;
  final List<Map<String, dynamic>> data;
  final Color color;

  const CategorySummaryCard({
    super.key,
    required this.title,
    required this.icon,
    required this.data,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconMap[icon], color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 200,
              child: data.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhuma transação de ${title.toLowerCase()} registrada.',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final cat = data[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Row(
                            children: [
                              // Ícone da Categoria
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: color.withAlpha(26),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  iconMap[cat['icon']],
                                  color: color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cat['name'] as String,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${cat['count']} transações',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Valor
                              Text(
                                formatCurrency(
                                  cat['amount'] as double,
                                ).replaceAll('-', ''), // Remove sinal
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final Map<String, double> summary;
  final Map<String, dynamic> aggregatedData;

  const DashboardScreen({
    super.key,
    required this.summary,
    required this.aggregatedData,
  });

  @override
  Widget build(BuildContext context) {
    // Dados Agregados
    final annualSummary =
        (aggregatedData['annualSummary'] as Map<dynamic, dynamic>)
            .cast<int, Map<String, double>>();
    final categorySummary =
        (aggregatedData['categorySummary'] as Map<dynamic, dynamic>)
            .cast<String, Map<String, dynamic>>();

    // Categorias Ordenadas (Top 5)
    final List<Map<String, dynamic>> sortedIncomeCats =
        categorySummary['income']!.values.cast<Map<String, dynamic>>().toList()
          ..sort(
            (a, b) => (b['amount'] as double).compareTo(a['amount'] as double),
          );
    final List<Map<String, dynamic>> sortedExpenseCats =
        categorySummary['expense']!.values.cast<Map<String, dynamic>>().toList()
          ..sort(
            (a, b) => (b['amount'] as double).compareTo(a['amount'] as double),
          );

    // Resumo Anual para o Gráfico
    final List<Map<String, dynamic>> annualList =
        annualSummary.entries
            .map(
              (e) => {
                'year': e.key,
                'income': e.value['income'],
                'expense': e.value['expense'],
              },
            )
            .toList()
          ..sort((a, b) => (a['year'] as int).compareTo(b['year'] as int));

    // Calcula os valores máximos para dimensionamento dos gráficos
    final double maxAnnualExpense = annualList.isEmpty
        ? 0
        : annualList.map((e) => e['expense'] as double).reduce(max) * 1.1;
    final double maxAnnualIncome = annualList.isEmpty
        ? 0
        : annualList.map((e) => e['income'] as double).reduce(max) * 1.1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
        ),

        // 1. Sumário Global (Cards) - Responsivo
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return GridView.count(
              crossAxisCount: isMobile ? 1 : 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isMobile ? 3.0 : 1.8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                SummaryCard(
                  title: 'Saldo Atual',
                  value: summary['balance']!,
                  color: primaryColor,
                  isBalance: true,
                ),
                SummaryCard(
                  title: 'Total de Entradas',
                  value: summary['income']!,
                  color: incomeColor,
                ),
                SummaryCard(
                  title: 'Total de Saídas',
                  value: summary['expense']!,
                  color: expenseColor,
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 25),

        // 2. Gráfico de Resumo Anual
        ChartCard(
          title: 'Resumo Anual de Entradas e Saídas',
          height: 250,
          chartWidget: AnnualBarChart(
            data: annualList,
            maxIncome: maxAnnualIncome,
            maxExpense: maxAnnualExpense,
          ),
        ),

        const SizedBox(height: 25),

        // 3. Resumo por Categoria - Responsivo
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return GridView.count(
              crossAxisCount: isMobile ? 1 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isMobile ? 1.0 : 0.9,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                CategorySummaryCard(
                  title: 'Entradas por Categoria',
                  icon: 'ArrowUpCircle',
                  data: sortedIncomeCats.take(5).toList(),
                  color: incomeColor,
                ),
                CategorySummaryCard(
                  title: 'Saídas por Categoria',
                  icon: 'ArrowDownCircle',
                  data: sortedExpenseCats.take(5).toList(),
                  color: expenseColor,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 80), // Espaço para o FAB
      ],
    );
  }
}

// ===================================================================
// 5. WIDGET PRINCIPAL E GERENCIAMENTO DE ESTADO
// ===================================================================

// --- Splash Screen (tela de inicialização) ---
class SplashScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const SplashScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A navegação deve ocorrer aqui, após o widget estar pronto.
    // Chamar no initState pode causar erros de renderização.
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // Simula um tempo de carregamento para a splash screen ser visível.
    // Protege a navegação com try/catch e adiciona um watchdog que garante
    // que a aplicação não fique travada na splash (fallback após 5s).
    try {
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;

      void doNavigate() {
        try {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => MainApp(
                toggleTheme: widget.toggleTheme,
                isDarkMode: widget.isDarkMode,
              ),
            ),
          );
        } catch (e, st) {
          // Se falhar, loga e tentará o fallback mais abaixo.
          // Não rethrow para não travar a UI.
          // ignore: avoid_print
          print('Navigation error in SplashScreen: $e\n$st');
        }
      }

      // Navega logo após o frame corrente para evitar problemas de render.
      WidgetsBinding.instance.addPostFrameCallback((_) => doNavigate());

      // Watchdog: se ainda estiver na splash após 5s, força navegação para
      // evitar que o app fique preso (ex.: erro silencioso em MainApp).
      Future.delayed(const Duration(seconds: 5), () {
        if (!mounted) return;
        final route = ModalRoute.of(context);
        if (route != null && route.isCurrent) {
          try {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => MainApp(
                  toggleTheme: widget.toggleTheme,
                  isDarkMode: widget.isDarkMode,
                ),
              ),
            );
          } catch (e) {
            // ignore: avoid_print
            print('Watchdog navigation failed: $e');
          }
        }
      });
    } catch (e, st) {
      // Em caso de erro inesperado, navega para evitar bloqueio da UI.
      // ignore: avoid_print
      print('Unexpected error in _navigateToHome: $e\n$st');
      if (!mounted) return;
      try {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MainApp(
              toggleTheme: widget.toggleTheme,
              isDarkMode: widget.isDarkMode,
            ),
          ),
        );
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scale,
                child: SizedBox(
                  width: 112,
                  height: 112,
                  // Usar SvgPicture.asset é mais eficiente e recomendado, especialmente para web.
                  child: const AppLogo(
                    width: 112,
                    height: 112,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Finanças App',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() async {
  // Inicializar intl para PT-BR (necessário para formatação de datas)
  await initializeDateFormatting('pt_BR', null);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    // Detectar tema do device automaticamente sem depender de MediaQuery
    // (evita usar context em initState)
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _isDarkMode = brightness == Brightness.dark;

    // Atualiza quando o tema do sistema muda
    WidgetsBinding
        .instance
        .platformDispatcher
        .onPlatformBrightnessChanged = () {
      final b = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      if (mounted) {
        setState(() {
          _isDarkMode = b == Brightness.dark;
        });
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finanças App (Flutter)',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB), // Gray-50
        fontFamily: 'Roboto',
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: primaryColor,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          margin: EdgeInsets.zero,
          color: Colors.white,
          shadowColor: Colors.black.withAlpha(26),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF3F4F6), // Gray-100
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          labelStyle: TextStyle(color: Colors.grey[700]),
          hintStyle: TextStyle(color: Colors.grey[600]),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1F2937), // Gray-800
        fontFamily: 'Roboto',
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF111827), // Gray-900
          foregroundColor: const Color(0xFF60A5FA), // Blue-400
          elevation: 0,
          centerTitle: false,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF60A5FA),
          ),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          margin: EdgeInsets.zero,
          color: const Color(0xFF374151), // Gray-700
          shadowColor: Colors.black.withAlpha(128),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF60A5FA),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF374151), // Gray-700
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF60A5FA), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          labelStyle: TextStyle(color: Colors.grey[300]),
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF374151),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
      ),
      home: SplashScreen(toggleTheme: _toggleTheme, isDarkMode: _isDarkMode),
    );
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }
}

class MainApp extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const MainApp({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  // Estado da Aplicação
  bool _isLoading = true;
  int _selectedIndex = 0; // 0: Dashboard, 1: Entradas, 2: Saídas, 3: Todas

  late final AuthService _authService;
  User? _currentUser;
  List<User> _collaborators = [];
  List<Invitation> _invitations = [];

  List<Transaction> _transactions = [];
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    // Configure auth service (mock or Google) based on config
    _authService = useMockAuth ? MockAuthService() : GoogleAuthService();
    _loadInitialData();
  }

  // --- Lógica Mock de Carregamento de Dados (Simulando Firebase) ---
  Future<void> _loadInitialData() async {
    // Simula o tempo de carregamento
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _categories = mockCategoriesData
          .map((data) => Category.fromMap(data))
          .toList();
      _transactions = mockTransactionsData
          .map((data) => Transaction.fromMap(data))
          .toList();
      _isLoading = false;
    });
  }

  // --- Autenticação via AuthService (mock ou Google) ---
  Future<void> _signInWithGoogle() async {
    try {
      final user = await _authService.signIn();
      if (user != null) {
        setState(() {
          _currentUser = user;
          _selectedIndex = 0;
        });
        _showWelcomeDialog(user);
      }
    } catch (error) {
      // mantém compatibilidade com mensagens antigas
      _showErrorSnackBar('Erro ao fazer login: $error');
    }
  }

  // --- Login Mock para Testes (delegado ao serviço de autenticação) ---
  void _mockLogin() async {
    try {
      final user = await _authService.signIn();
      if (user != null) {
        setState(() {
          _currentUser = user;
          _selectedIndex = 0;
        });
        _showWelcomeDialog(user);
      }
    } catch (e) {
      _showErrorSnackBar('Erro no login mock');
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      setState(() {
        _currentUser = null;
        _collaborators = [];
        _invitations = [];
      });
    } catch (error) {
      _showErrorSnackBar('Erro ao fazer logout');
    }
  }

  // --- Modal de Boas-Vindas ---
  void _showWelcomeDialog(User user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 3), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: successColor,
                size: 70,
              ),
              const SizedBox(height: 20),
              Text(
                'Bem-vindo(a), ${user.name}!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text('Login realizado com sucesso.'),
            ],
          ),
        );
      },
    );
  }

  // --- Gerenciamento de Convites ---
  void _showInviteCollaboratorDialog() {
    final emailController = TextEditingController();
    String selectedRole = 'collaborator';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Convidar Colaborador'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email do Colaborador',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),
              StatefulBuilder(
                builder: (context, setState) {
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Acesso',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                      initialValue: selectedRole,
                    items: const [
                      DropdownMenuItem(
                        value: 'collaborator',
                        child: Text('Colaborador (Editar e Visualizar)'),
                      ),
                      DropdownMenuItem(
                        value: 'viewer',
                        child: Text('Visualizador (Apenas Visualizar)'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value!;
                      });
                    },
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (emailController.text.isEmpty) {
                  _showErrorSnackBar('Digite um email válido');
                  return;
                }
                _sendInvitation(emailController.text, selectedRole);
                Navigator.of(context).pop();
              },
              child: const Text(
                'Enviar Convite',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendInvitation(String email, String role) async {
    // 1. Criar o convite no estado local (simulando o BD)
    final invitation = Invitation(
      id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      role: role,
      createdAt: DateTime.now(),
      createdBy: _currentUser!.email,
      accepted: false,
    );
    setState(() {
      _invitations.add(invitation);
    });

    // 2. Preparar e enviar o e-mail usando url_launcher
    final subject = 'Você foi convidado para colaborar no FinançasApp!';
    // URL pública do seu logo. Você precisa hospedar o logo em algum lugar.
    // Ex: Firebase Storage, Imgur, etc.
    const logoUrl =
        'https://raw.githubusercontent.com/Tiago-Neves-dos-Santos/appfinancas/main/assets/images/logo_email.png';

    final body =
        '''
      <div style="font-family: Arial, sans-serif; text-align: center; padding: 20px;">
        <img src="$logoUrl" alt="FinançasApp Logo" width="100" style="margin-bottom: 20px;">
        <h2 style="color: #4F46E5;">Convite para Colaborar</h2>
        <p>Olá!</p>
        <p>Você foi convidado por <strong>${_currentUser?.name ?? 'um usuário'}</strong> para colaborar em um painel financeiro no <strong>FinançasApp</strong>.</p>
        <p>Sua função será de: <strong>$role</strong>.</p>
        <p>Para aceitar, baixe o aplicativo e faça login com este e-mail.</p>
        <br>
        <a href="https://play.google.com/store" style="background-color: #4F46E5; color: white; padding: 12px 25px; text-decoration: none; border-radius: 8px; font-weight: bold;">
          Acessar o App
        </a>
        <hr style="margin: 30px 0;">
        <p style="font-size: 12px; color: #888;">Se você não esperava este convite, pode ignorar este e-mail.</p>
      </div>
    ''';

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      query:
          'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    if (!await launchUrl(emailLaunchUri)) {
      _showErrorSnackBar('Não foi possível abrir o app de e-mail.');
    } else {
      await launchUrl(emailLaunchUri);
      _showSuccessSnackBar('Abra seu app de e-mail para enviar o convite.');
    }
  }

  void _removeCollaborator(String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Remover Colaborador'),
          content: const Text(
            'Tem certeza que deseja remover este colaborador?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _collaborators.removeWhere((u) => u.id == userId);
                });
                Navigator.of(context).pop();
                _showSuccessSnackBar('Colaborador removido');
              },
              child: const Text(
                'Remover',
                style: TextStyle(
                  color: expenseColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateTransaction(Transaction transaction) {
    if (_isGuest) {
      _showAuthModal();
      return;
    }
    if (!_isCollaborator && !_isAdmin) {
      _showErrorSnackBar('Você não tem permissão para editar transações');
      return;
    }
    setState(() {
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
      }
    });
    // Fechar o modal (caso esteja aberto)
    if (Navigator.canPop(context)) Navigator.of(context).pop();

    // Mostrar diálogo centralizado de sucesso com ícone de confirmação
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        // Auto-fechar após curto tempo
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (Navigator.canPop(context)) Navigator.of(context).pop();
        });
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: successColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check_circle_outline,
                      color: successColor,
                      size: 44,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Transação atualizada',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'A transação foi editada com sucesso.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Funções Auxiliares ---
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: expenseColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: successColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String get _userRole {
    if (_currentUser == null) return 'guest';
    return _currentUser!.role;
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'owner':
        return 'Proprietário';
      case 'collaborator':
        return 'Colaborador';
      case 'viewer':
        return 'Visualizador';
      default:
        return role;
    }
  }

  bool get _isAdmin => _userRole == 'owner';
  bool get _isCollaborator => _userRole == 'collaborator';
  bool get _isGuest => _currentUser == null;

  // --- Funções Auxiliares de Dados ---
  Category _getCategoryById(String id) {
    return _categories.firstWhere(
      (cat) => cat.id == id,
      orElse: () => Category.fromMap({
        'id': 'fallback',
        'name': 'Sem Categoria',
        'type': 'expense',
        'icon': 'DollarSign',
      }),
    );
  }

  // --- Mocks de CRUD ---
  void _addTransaction(Transaction transaction) {
    if (_isGuest) {
      _showAuthModal();
      return;
    }
    // Apenas collaborators e owner podem adicionar
    if (!_isCollaborator && !_isAdmin) {
      _showErrorSnackBar('Você não tem permissão para adicionar transações');
      return;
    }
    setState(() {
      // Adiciona uma nova transação com ID mock
      _transactions.add(
        Transaction.fromMap({
          'id': 't${DateTime.now().millisecondsSinceEpoch}',
          'description': transaction.description,
          'amount': transaction.amount,
          'categoryId': transaction.categoryId,
          'date': transaction.date.toIso8601String().substring(0, 10),
        }),
      );
    });
    // Fechar o modal
    Navigator.of(context).pop();
    // Mudar para a tela de 'Todas as Transações' para ver o item recém-adicionado
    setState(() {
      _selectedIndex = 3;
    });
  }

  void _deleteTransaction(String id) {
    // Apenas owner e collaborator podem deletar
    if (!_isAdmin && !_isCollaborator) return;

    // A confirmação agora é feita pelo Dismissible, mas mantemos o dialog como fallback
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Theme.of(context).cardColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone de exclusão no centro com background arredondado
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Icon(
                    Icons.delete_outline,
                    color: expenseColor,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Título
              const Text(
                'Confirmar Exclusão',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Descrição
              Text(
                'Tem certeza que deseja deletar esta transação? Esta ação não pode ser desfeita.',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Botões de ação
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _transactions.removeWhere((t) => t.id == id);
                        });
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: expenseColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Deletar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAuthModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Faça Login Primeiro'),
          content: const Text(
            'Você precisa estar autenticado para realizar esta ação.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: primaryColor)),
            ),
          ],
        );
      },
    );
  }

  // --- Lógica de Derivação de Dados (Para Dashboard) ---
  Map<String, double> get _summary {
    double totalIncome = 0;
    double totalExpense = 0;

    for (var t in _transactions) {
      final category = _getCategoryById(t.categoryId);
      if (category.type == 'income') {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }
    return {
      'income': totalIncome,
      'expense': totalExpense,
      'balance': totalIncome - totalExpense,
    };
  }

  Map<String, dynamic> get _aggregatedData {
    final Map<int, Map<String, double>> annualSummary = {};
    final Map<String, Map<String, dynamic>> categorySummary = {
      'income': {},
      'expense': {},
    };

    for (var t in _transactions) {
      final year = t.date.year;
      final category = _getCategoryById(t.categoryId);
      final type = category.type;

      // Annual Summary
      annualSummary.putIfAbsent(year, () => {'income': 0.0, 'expense': 0.0});
      annualSummary[year]![type] =
          (annualSummary[year]![type] ?? 0.0) + t.amount;

      // Category Summary
      categorySummary[type]!.putIfAbsent(
        category.id,
        () => {
          'amount': 0.0,
          'count': 0,
          'icon': category.iconName,
          'name': category.name,
        },
      );
      categorySummary[type]![category.id]!['amount'] =
          (categorySummary[type]![category.id]!['amount'] as double) + t.amount;
      categorySummary[type]![category.id]!['count'] =
          (categorySummary[type]![category.id]!['count'] as int) + 1;
    }

    return {'annualSummary': annualSummary, 'categorySummary': categorySummary};
  }

  // --- Widgets de Tela ---
  Widget _getBody() {
    // Navegação entre as telas do BottomNavigationBar
    switch (_selectedIndex) {
      case 0: // Dashboard
        return DashboardScreen(
          summary: _summary,
          aggregatedData: _aggregatedData,
        );
      case 1: // Entradas
        return TransactionsScreen(
          transactions: _transactions,
          filterType: 'income',
          getCategoryById: _getCategoryById,
          deleteTransaction: _deleteTransaction,
          editTransaction: (t) => _showNewTransactionModal(t, 'income'),
          canEdit: _isAdmin || _isCollaborator,
        );
      case 2: // Saídas
        return TransactionsScreen(
          transactions: _transactions,
          filterType: 'expense',
          getCategoryById: _getCategoryById,
          deleteTransaction: _deleteTransaction,
          editTransaction: (t) => _showNewTransactionModal(t, 'expense'),
          canEdit: _isAdmin || _isCollaborator,
        );
      case 3: // Todas as Transações
        return TransactionsScreen(
          transactions: _transactions,
          filterType: 'all',
          getCategoryById: _getCategoryById,
          deleteTransaction: _deleteTransaction,
          editTransaction: _showNewTransactionModal,
          canEdit: _isAdmin || _isCollaborator,
        );
      default:
        return const Center(child: Text('Tela não encontrada.'));
    }
  }

  // --- Tela de Acesso Negado (Guest) ---
  Widget _buildGuestScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 60, color: primaryColor),
            const SizedBox(height: 20),
            const Text(
              'Bem-vindo ao FinançasApp',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Faça login com sua conta Google para acessar seu painel de controle financeiro e gerenciar transações.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: useMockAuth ? _mockLogin : _signInWithGoogle,
              icon: const Icon(Icons.login),
              label: const Text('Entrar com Google'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            // O botão de mock login só é exibido se o principal usar o Google real,
            // para evitar redundância na tela de teste.
            if (!useMockAuth) ...[
              const SizedBox(height: 15),
              TextButton(
                onPressed: _mockLogin,
                child: Text(
                  'Ou Entrar como Teste (Mock)',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- Modal de Nova Transação ---
  void _showNewTransactionModal([Transaction? transactionToEdit, String? defaultFilterType]) {
    // If editing an existing transaction, show a centered dialog
    if (transactionToEdit != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: SingleChildScrollView(
              child: Padding(
                // Ajusta o padding para o teclado (viewInsets)
                padding: EdgeInsets.only(
                  top: 20,
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // Evita ficar muito largo em telas grandes
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    minWidth: 300,
                  ),
                  child: NewTransactionForm(
                    categories: _categories,
                    addTransaction: _addTransaction,
                    updateTransaction: _updateTransaction,
                    transactionToEdit: transactionToEdit,
                    defaultFilterType: defaultFilterType,
                  ),
                ),
              ),
            ),
          );
        },
      );
      return;
    }

    // Caso contrário (nova transação) mantemos o bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          // Ajusta o padding para o teclado (viewInsets)
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: NewTransactionForm(
            categories: _categories,
            addTransaction: _addTransaction,
            updateTransaction: _updateTransaction,
            transactionToEdit: transactionToEdit,
            defaultFilterType: defaultFilterType,
          ),
        );
      },
    );
  }

  // --- Widget Principal ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Row(
          children: [
            // Logo SVG da pasta assets
            SizedBox(
              width: 40,
              height: 40,
              // Usar SvgPicture.asset é mais eficiente.
              // Garante que as cores originais do SVG sejam preservadas
              // passando `color: null` e definindo o `fit`.
              child: const AppLogo(width: 40, height: 40, fit: BoxFit.contain),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'FinançasApp',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).appBarTheme.titleTextStyle?.color,
                ),
              ),
            ),
          ],
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        actions: [
          // Botão de Tema (claro/escuro)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: IconButton(
                icon: Icon(
                  widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: primaryColor,
                ),
                tooltip: widget.isDarkMode ? 'Tema Claro' : 'Tema Escuro',
                onPressed: widget.toggleTheme,
              ),
            ),
          ),
          // Botão de Convites (apenas para owner)
          if (_isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: IconButton(
                  icon: Icon(Icons.person_add, color: primaryColor),
                  tooltip: 'Convidar Colaborador',
                  onPressed: _showInviteCollaboratorDialog,
                ),
              ),
            ),

          // Botão de Usuário e Logout
          if (!_isGuest)
            Tooltip(
              message: 'Menu',
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  if (value == 'logout') {
                    _signOut();
                  } else if (value == 'collaborators') {
                    _showCollaboratorsDialog();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'profile',
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentUser!.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _currentUser!.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'Papel: ${_getRoleDisplayName(_currentUser!.role)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  if (_isAdmin)
                    PopupMenuItem<String>(
                      value: 'collaborators',
                      child: Row(
                        children: [
                          Icon(Icons.group, color: primaryColor),
                          const SizedBox(width: 8),
                          const Text('Colaboradores'),
                        ],
                      ),
                    ),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sair',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                icon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: _ProfileMenuButton(
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: _currentUser!.photoUrl != null
                          ? Theme.of(context).colorScheme.surface
                          : Theme.of(context).colorScheme.primary,
                      backgroundImage: _currentUser!.photoUrl != null
                          ? NetworkImage(_currentUser!.photoUrl!)
                          : null,
                      child: _currentUser!.photoUrl == null
                          ? Text(
                              _currentUser!.name[0].toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 16,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  SizedBox(height: 15),
                  Text(
                    'Carregando dados...',
                    style: TextStyle(color: primaryColor, fontSize: 16),
                  ),
                ],
              ),
            )
          : _isGuest
          ? _buildGuestScreen()
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _getBody(),
              ),
            ),
      // Esconde a barra de navegação para visitantes
      bottomNavigationBar: !_isGuest
          ? BottomBarWithNotch(
              items: [
                BottomBarItemData(icon: iconMap['Home']!, label: 'Início'),
                BottomBarItemData(icon: iconMap['ArrowUpCircle']!, label: 'Entradas'),
                BottomBarItemData(icon: iconMap['ArrowDownCircle']!, label: 'Saídas'),
                BottomBarItemData(icon: iconMap['ListChecks']!, label: 'Todas'),
              ],
              selectedIndex: _selectedIndex,
              backgroundColor: Theme.of(context).colorScheme.surface,
              onTap: (index) {
                setState(() => _selectedIndex = index);
              },
            )
          : null,
      // Esconde o FAB para visitantes
      floatingActionButton: !_isGuest && (_isAdmin || _isCollaborator)
          ? FloatingActionButton(
              // Passa o tipo padrão de categoria baseado na aba selecionada
              onPressed: () {
                if (_selectedIndex == 1) {
                  // Aba Entradas
                  _showNewTransactionModal(null, 'income');
                } else if (_selectedIndex == 2) {
                  // Aba Saídas
                  _showNewTransactionModal(null, 'expense');
                } else {
                  // Aba Dashboard ou Todas
                  _showNewTransactionModal();
                }
              },
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              child: Icon(iconMap['Plus']), // FloatingActionButton usa 'child'
            )
          : null,
    );
  }

  void _showCollaboratorsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Menu'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_collaborators.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Colaboradores Ativos:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._collaborators.map(
                        (collab) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(child: Text(collab.name[0])),
                          title: Text(collab.name),
                          subtitle: Text(collab.email),
                          trailing: collab.id != _currentUser!.id
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _removeCollaborator(collab.id);
                                  },
                                )
                              : const Chip(label: Text('Você')),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                if (_invitations.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Convites Pendentes:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._invitations
                          .where((inv) => !inv.accepted)
                          .map(
                            (inv) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(inv.email),
                              subtitle: Text(
                                '${inv.role} • Enviado em ${formatDate(inv.createdAt)}',
                              ),
                              trailing: const Icon(Icons.pending_actions),
                            ),
                          ),
                    ],
                  ),
                if (_collaborators.isEmpty && _invitations.isEmpty)
                  Text(
                    'Nenhum colaborador ainda.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Fechar',
                style: TextStyle(color: primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }
}

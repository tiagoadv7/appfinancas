import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'auth/auth_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth/auth_service.dart';
import 'auth/mock_auth_service.dart';
import 'auth/google_auth_service.dart';
import 'models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ===================================================================
// 1. CONSTANTES, MODELOS E UTILITÁRIOS (Unificados no arquivo principal)
// ===================================================================

// Mock de Cores
const Color primaryColor = Color.fromARGB(255, 0, 183, 255); // Indigo-600
const Color secondaryColor = Color(0xFFF3F4F6); // Gray-100
const Color incomeColor = Color(0xFF10B981); // Emerald-500
const Color expenseColor = Color(0xFFF43F5E); // Rose-500
const Color successColor = Color(0xFF10B981);

// Mock de Ícones (usando FontAwesome Icons)
Map<String, IconData> iconMap = {
  'Painel': FontAwesomeIcons.chartLine,
  'SetaCima': FontAwesomeIcons.arrowUp,
  'SetaBaixo': FontAwesomeIcons.arrowDown,
  'Cifrão': FontAwesomeIcons.moneyBill,
  'CarrinhoCompras': FontAwesomeIcons.cartShopping,
  'Casa': FontAwesomeIcons.house,
  'Carro': FontAwesomeIcons.car,
  'Talheres': FontAwesomeIcons.utensils,
  'Maleta': FontAwesomeIcons.briefcase,
  'Escudo': FontAwesomeIcons.shield,
  'Porquinho': FontAwesomeIcons.piggyBank,
  'Engrenagem': FontAwesomeIcons.gear,
  'Usuarios': FontAwesomeIcons.peopleGroup,
  'Lixeira': FontAwesomeIcons.trash,
  'Mais': FontAwesomeIcons.plus,
  'X': FontAwesomeIcons.xmark,
  'ListaVerificacao': FontAwesomeIcons.listCheck,
  'ArquivoLinhas': FontAwesomeIcons.fileLines,
  'GraficoPizza': FontAwesomeIcons.chartPie,
  'CartaoCredito': FontAwesomeIcons.creditCard,
  'EdificioColunas': FontAwesomeIcons.building,
  'BombaGasolina': FontAwesomeIcons.gasPump,
  'Escola': FontAwesomeIcons.school,
  'Filme': FontAwesomeIcons.film,
  'Futebol': FontAwesomeIcons.futbol,
  'Aviao': FontAwesomeIcons.plane,
  'Hotel': FontAwesomeIcons.hotel,
  'Telefone': FontAwesomeIcons.phone,
  'Wifi': FontAwesomeIcons.wifi,
  'Cachorro': FontAwesomeIcons.dog,
  'Criancas': FontAwesomeIcons.child,
  'Halter': FontAwesomeIcons.dumbbell,
  'Musica': FontAwesomeIcons.music,
  'Paleta': FontAwesomeIcons.palette,
  'Camera': FontAwesomeIcons.camera,
  'Computador': FontAwesomeIcons.computer,
  'Fones': FontAwesomeIcons.headphones,
  'Controle': FontAwesomeIcons.gamepad,
  'GuardaSol': FontAwesomeIcons.umbrellaBeach,
  'Talheres2': FontAwesomeIcons.utensils,
  'Xicara': FontAwesomeIcons.mugHot,
  'CopoMartini': FontAwesomeIcons.martiniGlassEmpty,
  'BolsaCompras': FontAwesomeIcons.bagShopping,
  'Presente': FontAwesomeIcons.gift,
  'Recibo': FontAwesomeIcons.receipt,
  'Dinheiro': FontAwesomeIcons.moneyBillWave,
  'Porquinho2': FontAwesomeIcons.piggyBank,
  'SetaCimaTendencia': FontAwesomeIcons.chartLine,
  'SetaBaixoTendencia': FontAwesomeIcons.arrowDown,
  'Calendario': FontAwesomeIcons.calendar,
};

// --- Função Helper Global para Modais de Alerta ---
void showCenteredAlertModal({
  required BuildContext context,
  required String title,
  required String message,
  required IconData icon,
  required Color iconColor,
  Duration autoCloseDuration = const Duration(milliseconds: 2500),
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      // Auto-fechar após o tempo especificado
      Future.delayed(autoCloseDuration, () {
        if (Navigator.canPop(dialogContext)) {
          Navigator.of(dialogContext).pop();
        }
      });

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: Icon(icon, color: iconColor, size: 32)),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Small helper to provide circular hover effect for profile menu button.
class _ProfileMenuButton extends StatefulWidget {
  final Widget child;
  const _ProfileMenuButton({required this.child});

  @override
  State<_ProfileMenuButton> createState() => _ProfileMenuButtonState();
}

class _ProfileMenuButtonState extends State<_ProfileMenuButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final hoverColor = Theme.of(
      context,
    ).colorScheme.primary.withOpacity(_hovering ? 0.08 : 0.0);
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
          decoration: BoxDecoration(color: hoverColor, shape: BoxShape.circle),
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
      iconName = data['iconName'] ?? data['icon'] ?? 'Porquinho';

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type,
    'iconName': iconName,
  };
}

class Transaction {
  final String id;
  final String description;
  final double amount;
  final String categoryId;
  final DateTime date;
  final bool isPaid;

  Transaction.fromMap(Map<String, dynamic> data)
    : id = data['id'],
      description = data['description'],
      amount = data['amount'].toDouble(),
      categoryId = data['categoryId'],
      date = DateTime.parse(data['date']),
      isPaid = data['isPaid'] ?? false;

  Map<String, dynamic> toMap() => {
    'id': id,
    'description': description,
    'amount': amount,
    'categoryId': categoryId,
    'date': date.toIso8601String().substring(0, 10),
    'isPaid': isPaid,
  };

  // Helper para criar uma cópia com isPaid alterado
  Transaction copyWith({bool? isPaid}) => Transaction.fromMap({
    'id': id,
    'description': description,
    'amount': amount,
    'categoryId': categoryId,
    'date': date.toIso8601String(),
    'isPaid': isPaid ?? this.isPaid,
  });
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
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
    this.backgroundColor = Colors.white,
    this.height = 78,
  });

  @override
  State<BottomBarWithNotch> createState() => _BottomBarWithNotchState();
}

class _BottomBarWithNotchState extends State<BottomBarWithNotch> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final itemWidth = width / widget.items.length;
        const notchRadius = 28.0;
        const notchDepth =
            10.0; // make the notch shallow so the circle sits above with a gap
        const gap = 6.0; // small space between circle bottom and the tab bar
        final notchCenterRaw = itemWidth * widget.selectedIndex + itemWidth / 2;
        final notchCenter = (notchCenterRaw.clamp(
          notchRadius + 12.0,
          width - notchRadius - 12.0,
        )).toDouble();

        return SizedBox(
          height: widget.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Background with notch (shallow)
              ClipPath(
                clipper: _BottomBarClipper(
                  notchCenter: notchCenter,
                  notchRadius:
                      notchRadius * 0.75 /* use smaller radius for notch */,
                  notchDepth: notchDepth,
                ),
                child: Container(
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
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
                                                color: Colors.black.withOpacity(
                                                  0.06,
                                                ),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ), // Oculta o ícone base quando selecionado para exibir apenas o flutuante.
                                  Opacity(
                                    opacity: selected ? 0.0 : 1.0,
                                    child: Icon(
                                      it.icon,
                                      color: selected
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                it.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: selected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
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
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.35),
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
      },
    );
  }
}

class _BottomBarClipper extends CustomClipper<Path> {
  final double notchCenter;
  final double notchRadius;
  final double notchDepth;
  _BottomBarClipper({
    required this.notchCenter,
    required this.notchRadius,
    this.notchDepth = 10.0,
  });

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
    path.quadraticBezierTo(
      notchCenter - r / 1.4,
      d * 0.6,
      notchCenter - r / 3,
      d,
    );
    path.arcToPoint(
      Offset(notchCenter + r / 3, d),
      radius: Radius.circular(r),
      clockwise: false,
    );
    path.quadraticBezierTo(
      notchCenter + r / 1.4,
      d * 0.6,
      nx2 > size.width ? size.width : nx2,
      0,
    );
    // Right top corner to right
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _BottomBarClipper oldClipper) {
    return oldClipper.notchCenter != notchCenter ||
        oldClipper.notchRadius != notchRadius ||
        oldClipper.notchDepth != notchDepth;
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

  List<String> parts = absValue.toStringAsFixed(2).split('.');
  String intPart = parts[0];
  String decimalPart = parts[1];

  // Adiciona separador de milhar
  String formatted = '';
  int count = 0;
  for (int i = intPart.length - 1; i >= 0; i--) {
    if (count > 0 && count % 3 == 0) {
      formatted = '.$formatted';
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
  {'id': 'cat-1', 'name': 'Salário', 'type': 'income', 'iconName': 'Maleta'},
  {
    'id': 'cat-2',
    'name': 'Alimentação',
    'type': 'expense',
    'iconName': 'Talheres',
  },
  {'id': 'cat-3', 'name': 'Moradia', 'type': 'expense', 'iconName': 'Casa'},
  {
    'id': 'cat-4',
    'name': 'Investimentos',
    'type': 'income',
    'iconName': 'Porquinho',
  },
  {'id': 'cat-5', 'name': 'Educação', 'type': 'expense', 'iconName': 'Escola'},
];

final List<Map<String, dynamic>> mockTransactionsData = [
  {
    'id': 't1',
    'description': 'Salário Mensal',
    'amount': 4500.00,
    'categoryId': 'cat-1',
    'date': '2024-10-01',
    'isPaid': true,
  },
  {
    'id': 't2',
    'description': 'Aluguel Outubro',
    'amount': 1500.00,
    'categoryId': 'cat-3',
    'date': '2024-10-05',
    'isPaid': true,
  },
  {
    'id': 't3',
    'description': 'Supermercado Mensal',
    'amount': 350.50,
    'categoryId': 'cat-2',
    'date': '2024-10-10',
    'isPaid': true,
  },
  {
    'id': 't4',
    'description': 'Salário Novembro',
    'amount': 4800.00,
    'categoryId': 'cat-1',
    'date': '2024-11-01',
    'isPaid': true,
  },
  {
    'id': 't5',
    'description': 'Jantar Fora',
    'amount': 120.00,
    'categoryId': 'cat-2',
    'date': '2024-11-03',
    'isPaid': false,
  },
  {
    'id': 't6',
    'description': 'Conta de Luz',
    'amount': 180.00,
    'categoryId': 'cat-3',
    'date': '2024-11-10',
    'isPaid': false,
  },
  {
    'id': 't7',
    'description': 'Dividendos Ações',
    'amount': 50.00,
    'categoryId': 'cat-4',
    'date': '2024-11-15',
    'isPaid': true,
  },
  {
    'id': 't8',
    'description': 'Cinema',
    'amount': 80.00,
    'categoryId': 'cat-5',
    'date': '2024-11-20',
    'isPaid': false,
  },
  {
    'id': 't9',
    'description': 'Aluguel Novembro',
    'amount': 1500.00,
    'categoryId': 'cat-3',
    'date': '2024-11-05',
    'isPaid': true,
  },
  {
    'id': 't10',
    'description': 'Salário Dezembro',
    'amount': 4700.00,
    'categoryId': 'cat-1',
    'date': '2024-12-01',
    'isPaid': true,
  },
  {
    'id': 't11',
    'description': 'Supermercado Natal',
    'amount': 550.00,
    'categoryId': 'cat-2',
    'date': '2024-12-12',
    'isPaid': false,
  },
  {
    'id': 't12',
    'description': 'Aluguel Dezembro',
    'amount': 1500.00,
    'categoryId': 'cat-3',
    'date': '2024-12-05',
    'isPaid': true,
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
      placeholderBuilder: (context) =>
          Image.asset(pngFallback, width: width, height: height, fit: fit),
      // On error, the `placeholderBuilder` will show the PNG fallback.
    );
  }
}

// --- Custom Loader Painter (similar ao HTML splash) ---
class _CustomLoaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 2;

    // Desenha o círculo em quadrantes com cores diferentes
    // Top: Amarelo (#f8c800)
    paint.color = const Color(0xFFF8C800);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // Top (90 graus)
      3.14159 / 2, // 180 graus
      false,
      paint,
    );

    // Bottom: Azul (#0097D7)
    paint.color = const Color(0xFF0097D7);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14159 / 2, // Bottom (270 graus)
      3.14159 / 2, // 180 graus
      false,
      paint,
    );

    // Resto: Preto
    paint.color = const Color(0xFF000000);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0, // Direita
      3.14159 / 2, // 90 graus
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14159, // Esquerda
      3.14159 / 2, // 90 graus
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_CustomLoaderPainter oldDelegate) => false;
}

class NewTransactionForm extends StatefulWidget {
  final List<Category> categories;
  final Function(Transaction) addTransaction;
  final Function(Transaction) updateTransaction;
  final Transaction? transactionToEdit;
  final String? defaultFilterType;
  final Function(Category)? onCategoryAdded;

  const NewTransactionForm({
    super.key,
    required this.categories,
    required this.addTransaction,
    required this.updateTransaction,
    this.transactionToEdit,
    this.defaultFilterType,
    this.onCategoryAdded,
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
          ? widget.categories
                .where((c) => c.type == widget.defaultFilterType)
                .toList()
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
                borderRadius: BorderRadius.all(Radius.circular(16)),
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
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            keyboardType: TextInputType.number,
            onSaved: (value) => _amount = value!,
            validator: (value) {
              if (value!.isEmpty) return 'Campo obrigatório';
              if (double.tryParse(value.replaceAll(',', '.')) == null) {
                return 'Valor inválido. Use ponto ou vírgula.';
              }
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
            trailing: const Icon(
              FontAwesomeIcons.calendar,
              color: primaryColor,
            ),
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
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(24),
                  initialValue: _selectedCategoryId,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Selecione uma Categoria'),
                    ),
                    const DropdownMenuItem(
                      value: 'divider1',
                      enabled: false,
                      child: Divider(thickness: 2, height: 5),
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
                      value: 'divider2',
                      enabled: false,
                      child: Divider(thickness: 2, height: 5),
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
                        String selectedIcon = 'Porquinho';
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          title: const Text('Nova Categoria'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Nome',
                                ),
                                onChanged: (v) => name = v,
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: type,
                                decoration: const InputDecoration(
                                  labelText: 'Tipo',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(24),
                                    ),
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(24),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'income',
                                    child: Text('Entrada'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'expense',
                                    child: Text('Saída'),
                                  ),
                                ],
                                onChanged: (v) => type = v ?? 'expense',
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: selectedIcon,
                                items: iconMap.keys.map((iconKey) {
                                  return DropdownMenuItem(
                                    value: iconKey,
                                    child: Row(
                                      children: [
                                        Icon(iconMap[iconKey], size: 20),
                                        const SizedBox(width: 8),
                                        Text(iconKey),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) =>
                                    selectedIcon = v ?? 'Porquinho',
                                decoration: const InputDecoration(
                                  labelText: 'Ícone',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(24),
                                    ),
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton.icon(
                              icon: const Icon(FontAwesomeIcons.xmark),
                              label: const Text('Cancelar'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(FontAwesomeIcons.floppyDisk),
                              label: const Text('Adicionar'),
                              onPressed: () {
                                if (name.trim().isEmpty) return;
                                Navigator.of(context).pop({
                                  'name': name.trim(),
                                  'type': type,
                                  'icon': selectedIcon,
                                });
                              },
                            ),
                          ],
                        );
                      },
                    );

                    if (result != null) {
                      // Criar categoria temporária e selecionar
                      final newId =
                          'cat_${DateTime.now().millisecondsSinceEpoch}';
                      final newCat = Category.fromMap({
                        'id': newId,
                        'name': result['name']!,
                        'type': result['type']!,
                        'iconName': result['icon'] ?? 'Porquinho',
                      });
                      // Adiciona à lista via callback
                      widget.onCategoryAdded?.call(newCat);
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
                    child: Center(
                      child: Icon(FontAwesomeIcons.plus, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(FontAwesomeIcons.xmark),
                  label: const Text('Cancelar'),
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
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(FontAwesomeIcons.floppyDisk),
                  label: const Text('Salvar'),
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
  final Function(bool)? onPaidStatusChanged;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.category,
    required this.color,
    this.onDelete,
    this.onEdit,
    this.onPaidStatusChanged,
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
            Icon(iconMap['Lixeira'], color: Colors.white),
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
            const Icon(FontAwesomeIcons.penToSquare, color: Colors.white),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: onEdit, // Clicar no card também edita
        child: Card(
          elevation: transaction.isPaid ? 4 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: transaction.isPaid
                  ? color.withAlpha(204)
                  : color.withAlpha(102),
              width: transaction.isPaid ? 2 : 1,
            ),
          ),
          color: transaction.isPaid ? color.withAlpha(26) : Colors.white,
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
                    color: transaction.isPaid ? color : color,
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: transaction.isPaid ? color : null,
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
                // Coluna com valor e toggle
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Valor
                    Text(
                      formatCurrency(transaction.amount).replaceAll('-', ''),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: transaction.isPaid ? color : color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Toggle Switch para marcar como pago
                    GestureDetector(
                      onTap: () =>
                          onPaidStatusChanged?.call(!transaction.isPaid),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 52,
                        height: 28,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: transaction.isPaid ? color : Colors.grey[300],
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (transaction.isPaid
                                          ? color
                                          : Colors.grey[300])!
                                      .withOpacity(0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: AnimatedAlign(
                          alignment: transaction.isPaid
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          duration: const Duration(milliseconds: 300),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  transaction.isPaid
                                      ? Icons.check
                                      : Icons.close,
                                  size: 14,
                                  color: transaction.isPaid
                                      ? color
                                      : Colors.grey[400],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TransactionsScreen extends StatefulWidget {
  final List<Transaction> transactions;
  final String filterType; // 'all', 'income', 'expense'
  final Category Function(String) getCategoryById;
  final Function(String) deleteTransaction;
  final Function(Transaction) editTransaction;
  final Function(String, bool)?
  onPaidStatusChanged; // Callback para marcar como pago
  final bool canEdit;
  final Function(DateTime)? onDateChanged; // Callback quando a data muda

  const TransactionsScreen({
    super.key,
    required this.transactions,
    required this.filterType,
    required this.getCategoryById,
    required this.deleteTransaction,
    required this.editTransaction,
    required this.canEdit,
    this.onPaidStatusChanged,
    this.onDateChanged,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  DateTime _selectedDate = DateTime.now();

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          children: [
            Icon(
              iconMap['Calendario'],
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma transação em ${DateFormat('MMMM', 'pt_BR').format(_selectedDate)}',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = widget.transactions.where((t) {
      final cat = widget.getCategoryById(t.categoryId);
      final matchesType =
          widget.filterType == 'all' || cat.type == widget.filterType;
      final matchesDate =
          t.date.year == _selectedDate.year &&
          t.date.month == _selectedDate.month;
      return matchesType && matchesDate;
    }).toList();

    // Ordenar por data decrescente
    filteredTransactions.sort((a, b) => b.date.compareTo(a.date));

    // Calcular totais
    double totalIncome = 0;
    double totalExpense = 0;
    for (final t in filteredTransactions) {
      final cat = widget.getCategoryById(t.categoryId);
      if (cat.type == 'income') {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      iconMap['ArquivoLinhas'],
                      color: primaryColor,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Extrato',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Gerencie suas transações, adicione gastos e visualize seu histórico completo.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Month Selector
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(FontAwesomeIcons.chevronLeft),
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime(
                        _selectedDate.year,
                        _selectedDate.month - 1,
                      );
                      widget.onDateChanged?.call(_selectedDate);
                    });
                  },
                ),
                Text(
                  DateFormat(
                    'MMMM yyyy',
                    'pt_BR',
                  ).format(_selectedDate).toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(FontAwesomeIcons.chevronRight),
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime(
                        _selectedDate.year,
                        _selectedDate.month + 1,
                      );
                      widget.onDateChanged?.call(_selectedDate);
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Cards de Totais
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (widget.filterType == 'all') {
                // Side-by-side layout: left=Saídas (expense), right=Entradas (income)
                return Row(
                  children: [
                    // Left: Saídas (Expenses)
                    Expanded(
                      child: SummaryCard(
                        title: 'Saídas',
                        value: totalExpense,
                        color: expenseColor,
                        icon: Icons.trending_down,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Right: Entradas (Income)
                    Expanded(
                      child: SummaryCard(
                        title: 'Entradas',
                        value: totalIncome,
                        color: incomeColor,
                        icon: Icons.trending_up,
                      ),
                    ),
                  ],
                );
              } else if (widget.filterType == 'income') {
                return SummaryCard(
                  title: 'Total de Entradas',
                  value: totalIncome,
                  color: incomeColor,
                  icon: Icons.trending_up,
                );
              } else {
                return SummaryCard(
                  title: 'Total de Saídas',
                  value: totalExpense,
                  color: expenseColor,
                  icon: Icons.trending_down,
                );
              }
            },
          ),
        ),
        if (filteredTransactions.isEmpty)
          _buildEmptyState(context)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredTransactions.length,
            itemBuilder: (context, index) {
              final t = filteredTransactions[index];
              final cat = widget.getCategoryById(t.categoryId);
              final isIncome = cat.type == 'income';
              final color = isIncome ? incomeColor : expenseColor;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: TransactionCard(
                  transaction: t,
                  category: cat,
                  color: color,
                  // Permite editar/deletar apenas se tiver permissão
                  onEdit: widget.canEdit
                      ? () => widget.editTransaction(t)
                      : null,
                  onDelete: widget.canEdit
                      ? () => widget.deleteTransaction(t.id)
                      : null,
                  onPaidStatusChanged: widget.onPaidStatusChanged != null
                      ? (isPaid) => widget.onPaidStatusChanged!(t.id, isPaid)
                      : null,
                ),
              );
            },
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
  final IconData? icon;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    this.isBalance = false,
    this.icon,
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
        child: Stack(
          children: [
            if (icon != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: Opacity(
                  opacity: 0.1,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final iconSize = screenWidth < 600 ? 24.0 : 80.0;
                      return Icon(icon, color: color, size: iconSize);
                    },
                  ),
                ),
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                if (isMobile) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8), // Space for icon
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatCurrency(value),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: valueColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatCurrency(value),
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: valueColor,
                        ),
                      ),
                    ],
                  );
                }
              },
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                color: Theme.of(context).colorScheme.onSurface,
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

// --- Componente de Gráfico de Pizza (Melhorado com Animação - React Style) ---
class AnnualPieChart extends StatefulWidget {
  final List<Map<String, dynamic>> data;

  const AnnualPieChart({super.key, required this.data});

  @override
  State<AnnualPieChart> createState() => _AnnualPieChartState();
}

class _AnnualPieChartState extends State<AnnualPieChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnnualPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double totalIncome = 0;
    double totalExpense = 0;
    for (var d in widget.data) {
      totalIncome += (d['income'] as double);
      totalExpense += (d['expense'] as double);
    }
    final total = totalIncome + totalExpense;

    if (total == 0) {
      return const Center(child: Text('Sem dados para exibir o gráfico.'));
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = min(constraints.maxWidth, constraints.maxHeight);
                  return Center(
                    child: SizedBox(
                      width: size,
                      height: size,
                      child: CustomPaint(
                        painter: _ModernPieChartPainter(
                          income: totalIncome,
                          expense: totalExpense,
                          total: total,
                          incomeColor: incomeColor,
                          expenseColor: expenseColor,
                          animationValue: _animation.value,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ModernLegendItem(
                    color: incomeColor,
                    label: 'Entradas',
                    value: totalIncome,
                    total: total,
                  ),
                  const SizedBox(height: 16),
                  _ModernLegendItem(
                    color: expenseColor,
                    label: 'Saídas',
                    value: totalExpense,
                    total: total,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ModernLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double value;
  final double total;

  const _ModernLegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (value / total * 100).toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${formatCurrency(value)} ($percent%)',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ModernPieChartPainter extends CustomPainter {
  final double income;
  final double expense;
  final double total;
  final Color incomeColor;
  final Color expenseColor;
  final double animationValue;

  _ModernPieChartPainter({
    required this.income,
    required this.expense,
    required this.total,
    required this.incomeColor,
    required this.expenseColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 * 0.8;

    // Sombra do gráfico
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, radius + 10, shadowPaint);

    // Fundo do gráfico (anel externo leve)
    final backgroundPaint = Paint()
      ..color = Colors.grey.withAlpha(25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.3;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Gradiente para melhor aparência
    final incomeSweep = (income / total) * 2 * pi;
    final expenseSweep = (expense / total) * 2 * pi;

    // Income Slice com animação
    final incomePaint = Paint()
      ..color = incomeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.3
      ..strokeCap = StrokeCap.round;

    final incomeRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      incomeRect,
      -pi / 2,
      incomeSweep * animationValue,
      false,
      incomePaint,
    );

    // Expense Slice com animação
    final expensePaint = Paint()
      ..color = expenseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      incomeRect,
      -pi / 2 + (incomeSweep * animationValue),
      expenseSweep * animationValue,
      false,
      expensePaint,
    );

    // Centro do gráfico (para criar visual em donut)
    final centerCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.4, centerCirclePaint);
  }

  @override
  bool shouldRepaint(covariant _ModernPieChartPainter oldDelegate) {
    return oldDelegate.income != income ||
        oldDelegate.expense != expense ||
        oldDelegate.total != total ||
        oldDelegate.animationValue != animationValue;
  }
}

// --- Componente de Resumo por Categoria ---
class CategorySummaryCard extends StatefulWidget {
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
  State<CategorySummaryCard> createState() => _CategorySummaryCardState();
}

class _CategorySummaryCardState extends State<CategorySummaryCard> {
  bool _isScrollEnabled = false;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isScrollEnabled = true);
        },
        onTapUp: (_) {
          setState(() => _isScrollEnabled = false);
        },
        onTapCancel: () {
          setState(() => _isScrollEnabled = false);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(iconMap[widget.icon], color: widget.color),
                  const SizedBox(width: 8),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              if (widget.data.isEmpty)
                Center(
                  child: Text(
                    'Nenhuma transação de ${widget.title.toLowerCase()} registrada.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              else
                SingleChildScrollView(
                  child: Column(
                    children: List.generate(widget.data.length, (index) {
                      final cat = widget.data[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          children: [
                            // Ícone da Categoria
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: widget.color.withAlpha(26),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                iconMap[cat['icon']],
                                color: widget.color,
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
                                color: widget.color,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final Map<String, double> summary;
  final DateTime? selectedMonth;

  const DashboardScreen({super.key, required this.summary, this.selectedMonth});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Sumário Global (Cards) - Responsivo
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FontAwesomeIcons.chartLine,
                          color: primaryColor,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Visão Geral',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Acompanhe o saldo total, receitas e despesas do mês em tempo real.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    GridView.count(
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
                          icon: Icons.attach_money,
                        ),
                        SummaryCard(
                          title: 'Total de Entradas',
                          value: summary['income']!,
                          color: incomeColor,
                          icon: Icons.trending_up,
                        ),
                        SummaryCard(
                          title: 'Total de Saídas',
                          value: summary['expense']!,
                          color: expenseColor,
                          icon: Icons.trending_down,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 80), // Espaço para o FAB
      ],
    );
  }
}

class ReportsScreen extends StatefulWidget {
  final List<Transaction> transactions;
  final Category Function(String) getCategoryById;

  const ReportsScreen({
    super.key,
    required this.transactions,
    required this.getCategoryById,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    // 1. Filtrar transações pelo mês selecionado
    final monthlyTransactions = widget.transactions.where((t) {
      return t.date.year == _selectedDate.year &&
          t.date.month == _selectedDate.month;
    }).toList();

    // 2. Calcular totais e agrupamentos
    double totalIncome = 0;
    double totalExpense = 0;
    final Map<String, Map<String, dynamic>> categorySummary = {
      'income': {},
      'expense': {},
    };

    for (var t in monthlyTransactions) {
      final category = widget.getCategoryById(t.categoryId);
      final type = category.type;

      if (type == 'income') {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }

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

    // 3. Preparar dados para os gráficos
    final pieData = [
      {'income': totalIncome, 'expense': totalExpense},
    ];

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

    return Column(
      key: ValueKey(_selectedDate),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      iconMap['GraficoPizza'],
                      color: primaryColor,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Relatórios',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Analise suas transações com gráficos e relatórios detalhados por categoria.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Month Selector
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(FontAwesomeIcons.chevronLeft),
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime(
                        _selectedDate.year,
                        _selectedDate.month - 1,
                      );
                    });
                  },
                ),
                Text(
                  DateFormat(
                    'MMMM yyyy',
                    'pt_BR',
                  ).format(_selectedDate).toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(FontAwesomeIcons.chevronRight),
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime(
                        _selectedDate.year,
                        _selectedDate.month + 1,
                      );
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (monthlyTransactions.isEmpty)
          _buildEmptyState(context)
        else
          Flexible(
            child: SingleChildScrollView(
              child: _buildCharts(
                context,
                pieData,
                sortedIncomeCats,
                sortedExpenseCats,
              ),
            ),
          ),

        const SizedBox(height: 80), // Espaço para o FAB
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          children: [
            Icon(
              iconMap['GraficoPizza'],
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Sem dados para este mês.',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharts(
    BuildContext context,
    List<Map<String, dynamic>> pieData,
    List<Map<String, dynamic>> sortedIncomeCats,
    List<Map<String, dynamic>> sortedExpenseCats,
  ) {
    // Calcular totais do mês
    double totalIncome = 0;
    double totalExpense = 0;
    for (var d in pieData) {
      totalIncome += (d['income'] as double);
      totalExpense += (d['expense'] as double);
    }
    final totalGeneral = totalIncome + totalExpense;

    return Column(
      children: [
        // 1. Gráfico de Pizza (Topo)
        ChartCard(
          title: 'Distribuição Mensal',
          height: 250,
          chartWidget: AnnualPieChart(data: pieData),
        ),

        const SizedBox(height: 25),

        // 2. Cards de Resumo de Entradas e Saídas (Novo Layout)
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return GridView.count(
              crossAxisCount: isMobile ? 1 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isMobile ? 2.5 : 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildSummaryCard(
                  context: context,
                  title: 'Entradas',
                  amount: totalIncome,
                  percentage: totalGeneral > 0
                      ? (totalIncome / totalGeneral) * 100
                      : 0,
                  icon: 'SetaCimaTendencia',
                  color: incomeColor,
                ),
                _buildSummaryCard(
                  context: context,
                  title: 'Saídas',
                  amount: totalExpense,
                  percentage: totalGeneral > 0
                      ? (totalExpense / totalGeneral) * 100
                      : 0,
                  icon: 'Painel',
                  color: expenseColor,
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 25),

        // 3. Tabelas de Categorias (Entradas e Saídas)
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return GridView.count(
              crossAxisCount: isMobile ? 1 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: double.infinity,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                CategorySummaryCard(
                  title: 'Entradas',
                  icon: 'SetaCimaTendencia',
                  data: sortedIncomeCats.take(5).toList(),
                  color: incomeColor,
                ),
                CategorySummaryCard(
                  title: 'Saídas',
                  icon: 'Painel',
                  data: sortedExpenseCats.take(5).toList(),
                  color: expenseColor,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Widget para exibir o card resumido de entradas/saídas
  Widget _buildSummaryCard({
    required BuildContext context,
    required String title,
    required double amount,
    required double percentage,
    required String icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withAlpha(30), color.withAlpha(10)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatCurrency(amount),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withAlpha(50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(iconMap[icon], color: color, size: 24),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(1)}% do total',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================================================================
// 4.1 WIDGET: TELA DE PERFIL
// ===================================================================

class ProfileScreen extends StatefulWidget {
  final User user;
  final bool isAdmin;
  final VoidCallback onLogout;
  final Function(User) onUpdateUser;
  final VoidCallback onManageCollaborators;
  final VoidCallback onInviteCollaborator;
  final List<User> collaborators;
  final List<Category> categories;
  final Function(Category) onEditCategory;
  final Function(String) onDeleteCategory;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.isAdmin,
    required this.onLogout,
    required this.onUpdateUser,
    required this.onManageCollaborators,
    required this.onInviteCollaborator,
    required this.collaborators,
    required this.categories,
    required this.onEditCategory,
    required this.onDeleteCategory,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user.name != oldWidget.user.name && !_isEditing) {
      _nameController.text = widget.user.name;
    }
    if (widget.user.email != oldWidget.user.email && !_isEditing) {
      _emailController.text = widget.user.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty)
      return;

    final updatedUser = User(
      id: widget.user.id,
      email: _emailController.text.trim(),
      name: _nameController.text.trim(),
      photoUrl: widget.user.photoUrl,
      role: widget.user.role,
      salary: widget.user.salary,
    );

    widget.onUpdateUser(updatedUser);
    setState(() {
      _isEditing = false;
    });

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => Center(
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  FontAwesomeIcons.checkCircle,
                  color: successColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Perfil Atualizado')),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            FontAwesomeIcons.user,
                            color: primaryColor,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Nome',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                _nameController.text.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            FontAwesomeIcons.envelope,
                            color: primaryColor,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Email',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                updatedUser.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: successColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            FontAwesomeIcons.checkDouble,
                            color: successColor,
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Alterações salvas!',
                              style: TextStyle(
                                color: successColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(FontAwesomeIcons.xmark),
                label: const Text('Fechar'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton.icon(
                icon: const Icon(FontAwesomeIcons.check),
                label: const Text('OK'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showEditCategoryDialog(Category category) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        String name = category.name;
        String type = category.type;
        String selectedIcon = category.iconName;
        if (!iconMap.containsKey(selectedIcon)) selectedIcon = 'Porquinho';

        return Center(
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text('Editar Categoria'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: name,
                    decoration: const InputDecoration(labelText: 'Nome'),
                    onChanged: (v) => name = v,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'income', child: Text('Entrada')),
                      DropdownMenuItem(value: 'expense', child: Text('Saída')),
                    ],
                    onChanged: (v) => type = v ?? 'expense',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedIcon,
                    items: iconMap.keys.map((iconKey) {
                      return DropdownMenuItem(
                        value: iconKey,
                        child: Row(
                          children: [
                            Icon(iconMap[iconKey], size: 20),
                            const SizedBox(width: 8),
                            Text(iconKey),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => selectedIcon = v ?? 'Porquinho',
                    decoration: const InputDecoration(
                      labelText: 'Ícone',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(FontAwesomeIcons.xmark),
                label: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (name.trim().isEmpty) return;
                  Navigator.of(context).pop({
                    'name': name.trim(),
                    'type': type,
                    'icon': selectedIcon,
                  });
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(FontAwesomeIcons.floppyDisk),
                label: const Text('Salvar'),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      final updatedCat = Category.fromMap({
        'id': category.id,
        'name': result['name']!,
        'type': result['type']!,
        'iconName': result['icon']!,
      });
      widget.onEditCategory(updatedCat);
    }
  }

  void _showSalaryDialog() {
    TextEditingController salaryController = TextEditingController(
      text: widget.user.salary.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => Center(
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Gerenciar Salário'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: salaryController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valor do Salário',
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(FontAwesomeIcons.xmark),
              label: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton.icon(
              icon: const Icon(FontAwesomeIcons.floppyDisk),
              label: const Text('Salvar'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                if (salaryController.text.isNotEmpty) {
                  final newSalary =
                      double.tryParse(salaryController.text) ?? 0.0;

                  // Criar usuário atualizado com novo salário
                  final updatedUser = User(
                    id: widget.user.id,
                    email: widget.user.email,
                    name: widget.user.name,
                    photoUrl: widget.user.photoUrl,
                    role: widget.user.role,
                    salary: newSalary,
                  );

                  // Notificar widget pai
                  widget.onUpdateUser(updatedUser);

                  // Fechar diálogo
                  Navigator.of(context).pop();

                  // Mostrar sucesso
                  showCenteredAlertModal(
                    context: context,
                    title: 'Sucesso',
                    message:
                        'Salário atualizado para: R\$ ${NumberFormat('#,##0.00', 'pt_BR').format(newSalary)}',
                    icon: FontAwesomeIcons.circleCheck,
                    iconColor: successColor,
                  );
                } else {
                  showCenteredAlertModal(
                    context: context,
                    title: 'Erro',
                    message: 'Digite um valor válido para o salário',
                    icon: FontAwesomeIcons.circleExclamation,
                    iconColor: expenseColor,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FontAwesomeIcons.user,
                          color: primaryColor,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Meu Perfil',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gerencie suas informações pessoais e configurações de conta',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Avatar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: widget.user.photoUrl != null
                      ? NetworkImage(widget.user.photoUrl!)
                      : null,
                  child: widget.user.photoUrl == null
                      ? Text(
                          widget.user.name.isNotEmpty
                              ? widget.user.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : null,
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        FontAwesomeIcons.penToSquare,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Formulário ou Visualização
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                if (_isEditing)
                  Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          labelText: 'Nome de Exibição',
                          prefixIcon: const Icon(FontAwesomeIcons.user),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: const Icon(FontAwesomeIcons.envelope),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Botões de Ação
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isEditing = false;
                                  _nameController.text = widget.user.name;
                                  _emailController.text = widget.user.email;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(FontAwesomeIcons.xmark),
                              label: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _save,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(FontAwesomeIcons.floppyDisk),
                              label: const Text('Salvar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Text(
                        widget.user.name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.user.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Chip(
                        label: Text(
                          widget.user.role == 'owner'
                              ? 'Proprietário'
                              : widget.user.role == 'collaborator'
                              ? 'Colaborador'
                              : 'Visualizador',
                        ),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        side: BorderSide.none,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(FontAwesomeIcons.penToSquare),
                          label: const Text('Editar Perfil'),
                          onPressed: () => setState(() => _isEditing = true),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          const Divider(),

          // Admin Options
          if (widget.isAdmin) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(FontAwesomeIcons.userPlus),
                      label: const Text('Convidar Colaborador'),
                      onPressed: widget.onInviteCollaborator,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(
                      FontAwesomeIcons.moneyBill,
                      color: primaryColor,
                    ),
                    title: const Text('Gerenciar Salário'),
                    trailing: const Icon(FontAwesomeIcons.chevronRight),
                    onTap: _showSalaryDialog,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],

          // Gerenciar Colaboradores
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    FontAwesomeIcons.peopleGroup,
                    color: primaryColor,
                  ),
                  title: const Text('Gerenciar Colaboradores'),
                  trailing: const Icon(FontAwesomeIcons.chevronRight),
                  onTap: widget.onManageCollaborators,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Colaboradores Ativos
          if (widget.isAdmin && widget.collaborators.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Colaboradores Ativos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: widget.collaborators
                    .map(
                      (collab) => Card(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            child: Text(
                              collab.name.isNotEmpty
                                  ? collab.name[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Text(collab.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(collab.email),
                              Text(
                                'Permissões: ${collab.role == 'owner'
                                    ? 'Proprietário'
                                    : collab.role == 'collaborator'
                                    ? 'Colaborador'
                                    : 'Visualizador'}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: Chip(
                            label: const Text('Ativo'),
                            backgroundColor: successColor.withValues(
                              alpha: 0.1,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Categorias Personalizadas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const Icon(
                    FontAwesomeIcons.tag,
                    color: primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Categorias Personalizadas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Builder(
              builder: (context) {
                final customCats = widget.categories.where((c) {
                  return !mockCategoriesData.any((m) => m['id'] == c.id);
                }).toList();

                if (customCats.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Nenhuma categoria personalizada.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return Column(
                  children: customCats.map((cat) {
                    final isIncome = cat.type == 'income';
                    final color = isIncome ? incomeColor : expenseColor;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            iconMap[cat.iconName] ?? Icons.circle,
                            color: color,
                            size: 20,
                          ),
                        ),
                        title: Text(cat.name),
                        subtitle: Text(isIncome ? 'Entrada' : 'Saída'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                FontAwesomeIcons.penToSquare,
                                size: 20,
                              ),
                              onPressed: () => _showEditCategoryDialog(cat),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                size: 20,
                                color: expenseColor,
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: const Text('Confirmar Exclusão'),
                                    content: Text(
                                      'Deseja realmente excluir a categoria "${cat.name}"?',
                                    ),
                                    actions: [
                                      TextButton.icon(
                                        icon: const Icon(
                                          FontAwesomeIcons.xmark,
                                        ),
                                        label: const Text('Cancelar'),
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                      ),
                                      ElevatedButton.icon(
                                        icon: const Icon(
                                          FontAwesomeIcons.trash,
                                        ),
                                        label: const Text('Excluir'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: expenseColor,
                                        ),
                                        onPressed: () {
                                          widget.onDeleteCategory(cat.id);
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ListTile(
              leading: const Icon(
                FontAwesomeIcons.doorOpen,
                color: expenseColor,
              ),
              title: const Text(
                'Sair da Conta',
                style: TextStyle(color: expenseColor),
              ),
              onTap: widget.onLogout,
            ),
          ),
          const SizedBox(height: 80), // Space for FAB/BottomBar
        ],
      ),
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
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _rotationController;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
    _rotationController.repeat();
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
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo com loading ao redor (custom circular loader)
              SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Custom Circular Loader ao redor com rotacao
                    RotationTransition(
                      turns: _rotationController,
                      child: CustomPaint(
                        painter: _CustomLoaderPainter(),
                        size: const Size(150, 150),
                      ),
                    ),
                    // Logo no centro
                    ScaleTransition(
                      scale: _scale,
                      child: SizedBox(
                        width: 112,
                        height: 112,
                        child: const AppLogo(
                          width: 112,
                          height: 112,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Finanças App',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
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
      title: 'Finanças App',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
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
          elevation: 4,
          shadowColor: Colors.black12,
          surfaceTintColor: Colors.white,
          centerTitle: false,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        tabBarTheme: TabBarThemeData(
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: primaryColor,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
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
        tabBarTheme: const TabBarThemeData(
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Color(0xFF60A5FA),
          unselectedLabelColor: Color(0xFF9CA3AF),
          indicatorColor: Color(0xFF60A5FA),
          labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
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
  int _selectedIndex = 0; // 0: Início, 1: Extrato, 2: Relatórios
  DateTime _dashboardSelectedMonth =
      DateTime.now(); // Mês selecionado no Extrato

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
    _loadCachedData();
    _loadInitialData();
  }

  // --- Cache de Dados ---
  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('currentUser');
    if (userJson != null) {
      final userMap = Map<String, dynamic>.from(jsonDecode(userJson));
      _currentUser = User.fromMap(userMap);
    }
    final transactionsJson = prefs.getString('transactions');
    if (transactionsJson != null) {
      final transactionsList = List<Map<String, dynamic>>.from(
        jsonDecode(transactionsJson),
      );
      _transactions = transactionsList
          .map((data) => Transaction.fromMap(data))
          .toList();
    }
    final categoriesJson = prefs.getString('categories');
    if (categoriesJson != null) {
      final categoriesList = List<Map<String, dynamic>>.from(
        jsonDecode(categoriesJson),
      );
      _categories = categoriesList
          .map((data) => Category.fromMap(data))
          .toList();
    }
  }

  Future<void> _saveCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentUser != null) {
      await prefs.setString('currentUser', jsonEncode(_currentUser!.toMap()));
      // Salvar o email do usuário para uso em biometria
      await prefs.setString('biometricUserEmail', _currentUser!.email);
    }
    await prefs.setString(
      'transactions',
      jsonEncode(_transactions.map((t) => t.toMap()).toList()),
    );
    await prefs.setString(
      'categories',
      jsonEncode(_categories.map((c) => c.toMap()).toList()),
    );
  }

  // --- Lógica Mock de Carregamento de Dados (Simulando Firebase) ---
  Future<void> _loadInitialData() async {
    // Simula o tempo de carregamento
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      // Se não houver categorias carregadas do cache, use as categorias padrão
      if (_categories.isEmpty) {
        _categories = mockCategoriesData
            .map((data) => Category.fromMap(data))
            .toList();
      }
      // Se ainda estiver vazio, tenta novamente
      if (_categories.isEmpty) {
        _categories = mockCategoriesData
            .map((data) => Category.fromMap(data))
            .toList();
      }
      // Só zera transações se não houver dados carregados do cache
      if (_transactions.isEmpty) {
        _transactions = []; // Zerar dados fictícios apenas se vazio
      }
      _isLoading = false;
    });
  }

  Future<void> _signInWithGoogle() async {
    try {
      final user = await _authService.signIn();
      if (user != null) {
        setState(() {
          _currentUser = user;
          _selectedIndex = 0;
        });
        _saveCachedData();
        _showWelcomeDialog(user);
      }
    } catch (error) {
      // mantém compatibilidade com mensagens antigas
      _showErrorSnackBar('Erro ao fazer login: $error');
    }
  }

  // --- Login Mock para Testes (delegado ao serviço de autenticação) ---
  void _mockLogin({String? email, String? password}) async {
    try {
      final user = await _authService.signIn(email: email, password: password);
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

  Future<void> _biometricLogin() async {
    try {
      // Try to authenticate using device biometrics (fingerprint, face, iris)
      // This requires the local_auth package to be added to pubspec.yaml
      // For now, we use a mock implementation that simulates authentication

      // In a production app, uncomment the code below after adding local_auth:
      /*
      final LocalAuthentication auth = LocalAuthentication();
      final List<BiometricType> availableBiometrics = 
          await auth.getAvailableBiometrics();
      
      bool authenticated = false;
      if (availableBiometrics.isNotEmpty) {
        try {
          authenticated = await auth.authenticate(
            localizedReason: 'Autentique-se com sua biometria',
            options: const AuthenticationOptions(
              stickyAuth: true,
              biometricOnly: true,
            ),
          );
        } on PlatformException catch (e) {
          _showErrorSnackBar('Erro de biometria: ${e.message}');
          return;
        }
      } else {
        _showErrorSnackBar('Nenhuma biometria disponível no dispositivo');
        return;
      }
      */

      // Mock implementation for testing
      await Future.delayed(const Duration(milliseconds: 1500));
      bool authenticated = true;

      if (authenticated) {
        // Recuperar o email do usuário armazenado e fazer login via auth service
        final prefs = await SharedPreferences.getInstance();
        final savedEmail = prefs.getString('biometricUserEmail');

        if (savedEmail != null && savedEmail.isNotEmpty) {
          // Fazer login com o mesmo auth service usado no Google
          final user = await _authService.signIn(email: savedEmail);
          if (user != null) {
            setState(() {
              _currentUser = user;
              _selectedIndex = 0;
            });
            _saveCachedData();
            _showWelcomeDialog(user);
          }
        } else {
          _showErrorSnackBar('Nenhum usuário cadastrado para biometria');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Erro na autenticação biométrica: $e');
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
      _saveCachedData();
    } catch (error) {
      _showErrorSnackBar('Erro ao fazer logout');
    }
  }

  void _updateUser(User updatedUser) async {
    setState(() {
      _currentUser = updatedUser;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUser', jsonEncode(updatedUser.toMap()));
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
            borderRadius: BorderRadius.circular(24),
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
                    borderRadius: BorderRadius.all(Radius.circular(16)),
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
                        borderRadius: BorderRadius.all(Radius.circular(24)),
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
            TextButton.icon(
              icon: const Icon(FontAwesomeIcons.xmark),
              label: Text(
                'Cancelar',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton.icon(
              icon: const Icon(FontAwesomeIcons.paperPlane),
              label: const Text(
                'Enviar Convite',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                if (emailController.text.isEmpty) {
                  _showErrorSnackBar('Digite um email válido');
                  return;
                }
                _sendInvitation(emailController.text, selectedRole);
                Navigator.of(context).pop();
              },
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
      createdBy: _currentUser!.name,
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
            TextButton.icon(
              icon: const Icon(FontAwesomeIcons.xmark),
              label: Text(
                'Cancelar',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton.icon(
              icon: const Icon(FontAwesomeIcons.trash),
              label: const Text(
                'Remover',
                style: TextStyle(
                  color: expenseColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                setState(() {
                  _collaborators.removeWhere((u) => u.id == userId);
                });
                Navigator.of(context).pop();
                _showSuccessSnackBar('Colaborador removido');
              },
            ),
          ],
        );
      },
    );
  }

  void _removeInvitation(String email) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Cancelar Convite'),
          content: const Text(
            'Tem certeza que deseja cancelar este convite? O usuário não poderá mais acessar usando este convite.',
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(FontAwesomeIcons.xmark),
              label: Text(
                'Cancelar',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton.icon(
              icon: const Icon(FontAwesomeIcons.trash),
              label: const Text(
                'Remover Convite',
                style: TextStyle(
                  color: expenseColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                setState(() {
                  _invitations.removeWhere((inv) => inv.email == email);
                });
                Navigator.of(context).pop();
                _showSuccessSnackBar('Convite cancelado');
              },
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
    _saveCachedData();
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 24.0,
              horizontal: 24.0,
            ),
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
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _editCategory(Category category) {
    setState(() {
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
      }
    });
    _saveCachedData();
  }

  void _deleteCategory(String id) {
    setState(() {
      _categories.removeWhere((c) => c.id == id);
    });
    _saveCachedData();
  }

  void _togglePaidStatus(String transactionId, bool isPaid) {
    setState(() {
      final index = _transactions.indexWhere((t) => t.id == transactionId);
      if (index != -1) {
        final transaction = _transactions[index];
        _transactions[index] = transaction.copyWith(isPaid: isPaid);
      }
    });
    _saveCachedData();
  }

  // --- Funções Auxiliares ---
  void _showErrorSnackBar(String message) {
    showCenteredAlertModal(
      context: context,
      title: 'Erro',
      message: message,
      icon: FontAwesomeIcons.circleExclamation,
      iconColor: expenseColor,
    );
  }

  void _showSuccessSnackBar(String message) {
    showCenteredAlertModal(
      context: context,
      title: 'Sucesso',
      message: message,
      icon: FontAwesomeIcons.circleCheck,
      iconColor: successColor,
    );
  }

  String get _userRole {
    if (_currentUser == null) return 'guest';
    return _currentUser!.role;
  }

  bool get _isAdmin => _userRole == 'owner';
  bool get _isCollaborator => _userRole == 'collaborator';
  bool get _isGuest => _currentUser == null;

  // --- Método para atualizar o mês selecionado no Dashboard ---
  void _updateDashboardMonth(DateTime month) {
    setState(() {
      _dashboardSelectedMonth = month;
    });
  }

  // --- Funções Auxiliares de Dados ---
  Category _getCategoryById(String id) {
    return _categories.firstWhere(
      (cat) => cat.id == id,
      orElse: () => Category.fromMap({
        'id': 'fallback',
        'name': 'Sem Categoria',
        'type': 'expense',
        'iconName': 'DollarSign',
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
    _saveCachedData();
    // Fechar o modal
    Navigator.of(context).pop();
    // Mudar para a tela de 'Todas as Transações' para ver o item recém-adicionado
    setState(() {
      _selectedIndex = 1;
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
          contentPadding: const EdgeInsets.symmetric(
            vertical: 24,
            horizontal: 24,
          ),
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
                    Icons.warning_amber_rounded,
                    color: expenseColor,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Título
              const Text(
                'Confirmar Exclusão',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    child: OutlinedButton.icon(
                      icon: const Icon(FontAwesomeIcons.xmark),
                      label: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(FontAwesomeIcons.trash),
                      label: const Text('Excluir'),
                      onPressed: () {
                        setState(() {
                          _transactions.removeWhere((t) => t.id == id);
                        });
                        _saveCachedData();
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
            TextButton.icon(
              icon: const Icon(FontAwesomeIcons.check),
              label: const Text('OK', style: TextStyle(color: primaryColor)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  // --- Lógica de Derivação de Dados (Para Dashboard) ---
  // Calcula o sumário filtrado para um mês específico
  Map<String, double> _calculateSummaryForMonth(DateTime month) {
    double totalIncome = 0;
    double totalExpense = 0;

    for (var t in _transactions) {
      if (t.date.year == month.year && t.date.month == month.month) {
        final category = _getCategoryById(t.categoryId);
        if (category.type == 'income') {
          totalIncome += t.amount;
        } else {
          totalExpense += t.amount;
        }
      }
    }
    return {
      'income': totalIncome,
      'expense': totalExpense,
      'balance': totalIncome - totalExpense,
    };
  }

  // --- Widgets de Tela ---

  // --- Tela de Acesso Negado (Guest) ---
  Widget _buildGuestScreen() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // Espaço no topo
              const SizedBox(height: 40),

              // Logo e Boas-vindas
              Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: const AppLogo(
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Bem-vindo ao FinançasApp',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gerencie suas finanças com facilidade',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Espaço
              const SizedBox(height: 40),

              // Formulário de Email e Senha
              Column(
                children: [
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: const Icon(FontAwesomeIcons.envelope),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(FontAwesomeIcons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Botão Entrar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (emailController.text.isNotEmpty &&
                            passwordController.text.isNotEmpty) {
                          // Simulação de login com email/senha
                          _mockLogin(
                            email: emailController.text,
                            password: passwordController.text,
                          );
                        } else {
                          showCenteredAlertModal(
                            context: context,
                            title: 'Campos Vazios',
                            message: 'Preencha email e senha',
                            icon: FontAwesomeIcons.circleExclamation,
                            iconColor: expenseColor,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(FontAwesomeIcons.rightToBracket),
                      label: const Text(
                        'Entrar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Espaço
              const SizedBox(height: 24),

              // Divider com texto
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'ou',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Botão Google
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: useMockAuth
                      ? () => _mockLogin()
                      : _signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                  icon: const Icon(FontAwesomeIcons.google),
                  label: const Text(
                    'Entrar com Google',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              if (!kIsWeb) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _biometricLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(FontAwesomeIcons.fingerprint),
                    label: const Text(
                      'Entrar com Biometria',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Botão Cadastre-se
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Não tem conta? ',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => Scaffold(body: _buildSignUpScreen()),
                        ),
                      );
                    },
                    icon: const Icon(FontAwesomeIcons.userPlus),
                    label: const Text(
                      'Cadastre-se',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              // Espaço final
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- Tela de Cadastro (Sign Up) ---
  Widget _buildSignUpScreen() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // Espaço no topo
              const SizedBox(height: 40),

              // Voltar e Título
              Row(
                children: [
                  IconButton(
                    icon: const Icon(FontAwesomeIcons.chevronLeft),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Criar Conta',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Descrição
              Text(
                'Cadastre-se para começar a gerenciar suas finanças',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),

              // Espaço
              const SizedBox(height: 30),

              // Formulário
              Column(
                children: [
                  // Nome
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nome Completo',
                      prefixIcon: const Icon(FontAwesomeIcons.user),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: const Icon(FontAwesomeIcons.envelope),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // Senha
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(FontAwesomeIcons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      helperText: 'Mínimo 6 caracteres',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirmar Senha
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Senha',
                      prefixIcon: const Icon(FontAwesomeIcons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botão Cadastrar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Validações
                        if (nameController.text.isEmpty) {
                          showCenteredAlertModal(
                            context: context,
                            title: 'Erro',
                            message: 'Preencha o nome completo',
                            icon: FontAwesomeIcons.circleExclamation,
                            iconColor: expenseColor,
                          );
                          return;
                        }
                        if (emailController.text.isEmpty ||
                            !emailController.text.contains('@')) {
                          showCenteredAlertModal(
                            context: context,
                            title: 'Erro',
                            message: 'E-mail inválido',
                            icon: FontAwesomeIcons.circleExclamation,
                            iconColor: expenseColor,
                          );
                          return;
                        }
                        if (passwordController.text.length < 6) {
                          showCenteredAlertModal(
                            context: context,
                            title: 'Erro',
                            message: 'Senha deve ter no mínimo 6 caracteres',
                            icon: FontAwesomeIcons.circleExclamation,
                            iconColor: expenseColor,
                          );
                          return;
                        }
                        if (passwordController.text !=
                            confirmPasswordController.text) {
                          showCenteredAlertModal(
                            context: context,
                            title: 'Erro',
                            message: 'As senhas não correspondem',
                            icon: FontAwesomeIcons.circleExclamation,
                            iconColor: expenseColor,
                          );
                          return;
                        }

                        // Se passou em todas as validações
                        showCenteredAlertModal(
                          context: context,
                          title: 'Sucesso',
                          message:
                              'Conta criada com sucesso! Você pode fazer login agora.',
                          icon: FontAwesomeIcons.circleCheck,
                          iconColor: successColor,
                        );

                        // Navegar de volta após 2 segundos
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(FontAwesomeIcons.userPlus),
                      label: const Text(
                        'Cadastrar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Já tem conta?
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Já tem conta? ',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Faça login',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              // Espaço final
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showNewTransactionModal([
    Transaction? transactionToEdit,
    String? defaultFilterType,
  ]) {
    // If editing an existing transaction, show a centered dialog
    if (transactionToEdit != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
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
                    onCategoryAdded: (Category cat) {
                      _categories.add(cat);
                      setState(() {});
                      _saveCachedData();
                    },
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
            onCategoryAdded: (Category cat) {
              _categories.add(cat);
              setState(() {});
              _saveCachedData();
            },
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
          : IndexedStack(
              index: _selectedIndex,
              children: [
                // Aba 0: Dashboard
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DashboardScreen(
                      summary: _calculateSummaryForMonth(
                        _dashboardSelectedMonth,
                      ),
                      selectedMonth: _dashboardSelectedMonth,
                    ),
                  ),
                ),
                // Aba 1: Extrato
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: TransactionsScreen(
                      transactions: _transactions,
                      filterType: 'all',
                      getCategoryById: _getCategoryById,
                      deleteTransaction: _deleteTransaction,
                      editTransaction: _showNewTransactionModal,
                      canEdit: _isAdmin || _isCollaborator,
                      onDateChanged: _updateDashboardMonth,
                      onPaidStatusChanged: _togglePaidStatus,
                    ),
                  ),
                ),
                // Aba 2: Relatórios
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ReportsScreen(
                    transactions: _transactions,
                    getCategoryById: _getCategoryById,
                  ),
                ),
                // Aba 3: Perfil
                ProfileScreen(
                  user: _currentUser!,
                  isAdmin: _isAdmin,
                  onLogout: _signOut,
                  onUpdateUser: _updateUser,
                  onManageCollaborators: _showCollaboratorsDialog,
                  onInviteCollaborator: _showInviteCollaboratorDialog,
                  collaborators: _collaborators,
                  categories: _categories,
                  onEditCategory: _editCategory,
                  onDeleteCategory: _deleteCategory,
                ),
              ],
            ),
      // Esconde a barra de navegação para visitantes
      bottomNavigationBar: !_isGuest
          ? BottomBarWithNotch(
              items: [
                BottomBarItemData(icon: iconMap['Casa']!, label: 'Início'),
                BottomBarItemData(
                  icon: iconMap['ArquivoLinhas']!,
                  label: 'Extrato',
                ),
                BottomBarItemData(
                  icon: iconMap['GraficoPizza']!,
                  label: 'Relatórios',
                ),
                BottomBarItemData(icon: Icons.person, label: 'Perfil'),
              ],
              selectedIndex: _selectedIndex,
              backgroundColor: Theme.of(context).brightness == Brightness.light
                  ? const Color.fromARGB(255, 0, 52, 78)
                  : Theme.of(context).cardTheme.color ??
                        Theme.of(context).colorScheme.surface,
              onTap: (index) {
                setState(() => _selectedIndex = index);
              },
            )
          : null,
      // Esconde o FAB para visitantes
      floatingActionButton:
          !_isGuest &&
              (_isAdmin || _isCollaborator) &&
              _selectedIndex != 2 &&
              _selectedIndex !=
                  3 // Oculta o FAB na aba "Perfil" e "Todos"
          ? FloatingActionButton(
              // Passa o tipo padrão de categoria baseado na aba selecionada
              onPressed: () {
                _showNewTransactionModal();
              },
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              child: Icon(iconMap['Mais']), // FloatingActionButton usa 'child'
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
                                '${inv.role} • Enviado por ${inv.createdBy} em ${formatDate(inv.createdAt)}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.orange,
                                ),
                                tooltip: 'Cancelar convite',
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _removeInvitation(inv.email);
                                },
                              ),
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
            TextButton.icon(
              icon: const Icon(FontAwesomeIcons.xmark),
              label: const Text(
                'Fechar',
                style: TextStyle(color: primaryColor),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}

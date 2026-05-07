import 'dart:async';
import 'dart:ui' as ui;
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
import 'auth/firebase_auth_service.dart';
import 'services/firestore_service.dart';
import 'services/update_service.dart';
import 'models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// ===================================================================
// 1. CONSTANTES, MODELOS E UTILITÁRIOS (Unificados no arquivo principal)
// ===================================================================

// Mock de Cores
const Color primaryColor = Color.fromARGB(255, 0, 183, 255); // Indigo-600
const Color secondaryColor = Color(0xFFF3F4F6); // Gray-100
const Color incomeColor = Color(0xFF10B981); // Emerald-500
const Color expenseColor = Color(0xFFF43F5E); // Rose-500
const Color successColor = Color(0xFF10B981);

// Mapa de ícones como const — garante que todos os glyphs FontAwesome
// sejam incluídos no build release (evita tree-shaking incorreto).
const Map<String, IconData> iconMap = {
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
  'Saude': FontAwesomeIcons.stethoscope,
  'Odonto': FontAwesomeIcons.tooth,
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
  final bool isDefault;

  Category.fromMap(Map<String, dynamic> data)
    : id = (data['id'] ?? '').toString(),
      name = (data['name'] ?? 'Sem nome').toString(),
      type = (data['type'] ?? 'expense').toString(),
      iconName = (data['iconName'] ?? data['icon'] ?? 'Porquinho').toString(),
      isDefault = (data['isDefault'] as bool?) ?? false;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type,
    'iconName': iconName,
    'isDefault': isDefault,
  };
}

class Transaction {
  final String id;
  final String description;
  final double amount;
  final String categoryId;
  final DateTime date;
  final bool isPaid;
  final bool isRecurring;
  final String? recurringStartMonth; // formato 'yyyy-MM'
  final String? recurringEndMonth; // formato 'yyyy-MM'
  // Controla pago/não-pago por mês para transações recorrentes: {'yyyy-MM': true}
  final Map<String, bool> paidByMonth;
  // Meses excluídos individualmente (formato 'yyyy-MM') — não afeta outros meses
  final List<String> deletedMonths;
  final String? comments;

  Transaction.fromMap(Map<String, dynamic> data)
    : id = (data['id'] ?? '').toString(),
      description = (data['description'] ?? '').toString(),
      amount = (data['amount'] as num? ?? 0).toDouble(),
      categoryId = (data['categoryId'] ?? '').toString(),
      date = _parseDate(data['date']),
      isPaid = data['isPaid'] == true,
      isRecurring = data['isRecurring'] == true,
      recurringStartMonth = data['recurringStartMonth']?.toString(),
      recurringEndMonth = data['recurringEndMonth']?.toString(),
      paidByMonth = data['paidByMonth'] is Map
          ? Map<String, bool>.from(
              (data['paidByMonth'] as Map).map(
                (k, v) => MapEntry(k.toString(), v == true),
              ),
            )
          : {},
      deletedMonths = data['deletedMonths'] is List
          ? List<String>.from(data['deletedMonths'])
          : [],
      comments = data['comments']?.toString();

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'description': description,
    'amount': amount,
    'categoryId': categoryId,
    'date': date.toIso8601String().substring(0, 10),
    'isPaid': isPaid,
    'isRecurring': isRecurring,
    'recurringStartMonth': recurringStartMonth,
    'recurringEndMonth': recurringEndMonth,
    'paidByMonth': paidByMonth,
    'deletedMonths': deletedMonths,
    'comments': comments,
  };

  // Helper para criar uma cópia com campos alterados
  Transaction copyWith({
    bool? isPaid,
    Map<String, bool>? paidByMonth,
    String? recurringEndMonth,
    List<String>? deletedMonths,
  }) {
    final map = toMap();
    if (isPaid != null) map['isPaid'] = isPaid;
    if (paidByMonth != null) map['paidByMonth'] = paidByMonth;
    if (recurringEndMonth != null) map['recurringEndMonth'] = recurringEndMonth;
    if (deletedMonths != null) map['deletedMonths'] = deletedMonths;
    return Transaction.fromMap(map);
  }
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
                          child: SizedBox(
                            height: widget.height,
                            child: Stack(
                              children: [
                                // Ícone centralizado (some quando selecionado)
                                Positioned.fill(
                                  bottom: 22,
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          width: hovered ? 48 : 0,
                                          height: hovered ? 48 : 0,
                                          decoration: BoxDecoration(
                                            color: widget.backgroundColor,
                                            shape: BoxShape.circle,
                                            boxShadow: hovered
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.06,
                                                          ),
                                                      blurRadius: 6,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                        ),
                                        Opacity(
                                          opacity: selected ? 0.0 : 1.0,
                                          child: Icon(
                                            it.icon,
                                            color: Colors.white.withValues(
                                              alpha: 0.7,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Texto fixo na parte inferior — nunca se move
                                Positioned(
                                  bottom: 10,
                                  left: 0,
                                  right: 0,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 180),
                                    opacity: selected ? 1.0 : 0.6,
                                    child: Text(
                                      it.label,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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

/// Converte strings como "1.200,45" ou "1200,45" ou "1200.45" para double.
/// Regra: se há vírgula, ela é o separador decimal e pontos são separadores de milhar.
/// Se há só ponto, é o separador decimal (ex: "1200.45").
double? parseAmountInput(String value) {
  final v = value.trim();
  if (v.isEmpty) return null;
  if (v.contains(',')) {
    // Formato BR: remove pontos (milhar) e troca vírgula por ponto
    return double.tryParse(v.replaceAll('.', '').replaceAll(',', '.'));
  }
  // Sem vírgula: pode ter ponto decimal normal (1200.45) ou sem separador (1200)
  return double.tryParse(v);
}

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
  // ── Entradas ──────────────────────────────────────────────────────
  {
    'id': 'cat-1',
    'name': 'Salário',
    'type': 'income',
    'iconName': 'Maleta',
    'isDefault': true,
  },
  {
    'id': 'cat-2',
    'name': 'Freelancer',
    'type': 'income',
    'iconName': 'Computador',
    'isDefault': true,
  },
  {
    'id': 'cat-3',
    'name': 'Investimentos',
    'type': 'income',
    'iconName': 'SetaCimaTendencia',
    'isDefault': true,
  },
  {
    'id': 'cat-4',
    'name': 'Presente',
    'type': 'income',
    'iconName': 'Presente',
    'isDefault': true,
  },
  {
    'id': 'cat-5',
    'name': 'Reembolso',
    'type': 'income',
    'iconName': 'Recibo',
    'isDefault': true,
  },
  // ── Saídas ────────────────────────────────────────────────────────
  {
    'id': 'cat-6',
    'name': 'Alimentação',
    'type': 'expense',
    'iconName': 'Talheres',
    'isDefault': true,
  },
  {
    'id': 'cat-7',
    'name': 'Assinaturas',
    'type': 'expense',
    'iconName': 'CartaoCredito',
    'isDefault': true,
  },
  {
    'id': 'cat-8',
    'name': 'Compras',
    'type': 'expense',
    'iconName': 'CarrinhoCompras',
    'isDefault': true,
  },
  {
    'id': 'cat-9',
    'name': 'Educação',
    'type': 'expense',
    'iconName': 'Escola',
    'isDefault': true,
  },
  {
    'id': 'cat-10',
    'name': 'Lazer',
    'type': 'expense',
    'iconName': 'Controle',
    'isDefault': true,
  },
  {
    'id': 'cat-11',
    'name': 'Moradia',
    'type': 'expense',
    'iconName': 'Casa',
    'isDefault': true,
  },
  {
    'id': 'cat-12',
    'name': 'Odonto',
    'type': 'expense',
    'iconName': 'Odonto',
    'isDefault': true,
  },
  {
    'id': 'cat-13',
    'name': 'Outros',
    'type': 'expense',
    'iconName': 'Cifrão',
    'isDefault': true,
  },
  {
    'id': 'cat-14',
    'name': 'Saúde',
    'type': 'expense',
    'iconName': 'Saude',
    'isDefault': true,
  },
  {
    'id': 'cat-15',
    'name': 'Transporte',
    'type': 'expense',
    'iconName': 'Carro',
    'isDefault': true,
  },
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
    if (kIsWeb) {
      return Image.asset(
        'assets/images/splash.png',
        width: width,
        height: height,
        fit: fit,
      );
    }
    return SvgPicture.asset(
      'assets/images/logo.svg',
      width: width,
      height: height,
      fit: fit,
      semanticsLabel: 'FinançasApp Logo',
      placeholderBuilder: (_) => SizedBox(width: width, height: height),
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
  final double userSalary;

  const NewTransactionForm({
    super.key,
    required this.categories,
    required this.addTransaction,
    required this.updateTransaction,
    this.transactionToEdit,
    this.defaultFilterType,
    this.onCategoryAdded,
    this.userSalary = 0.0,
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
  bool _isRecurring = false;
  bool _isPaid = false;
  String _comments = '';
  DateTime _recurringStartMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  DateTime _recurringEndMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month + 1,
  );

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
      _isPaid = t.isPaid;
      _comments = t.comments ?? '';
    } else {
      // Filtra categorias pelo tipo padrão se fornecido
      final categoriesToFilter = widget.defaultFilterType != null
          ? widget.categories
                .where((c) => c.type == widget.defaultFilterType)
                .toList()
          : widget.categories;

      // Pré-seleciona Salário para entradas, Moradia para saídas
      if (widget.defaultFilterType == 'income') {
        final salario = categoriesToFilter
            .where((c) => c.name == 'Salário')
            .firstOrNull;
        _selectedCategoryId =
            salario?.id ??
            (categoriesToFilter.isNotEmpty
                ? categoriesToFilter.first.id
                : null);
      } else if (widget.defaultFilterType == 'expense') {
        final moradia = categoriesToFilter
            .where((c) => c.name == 'Moradia')
            .firstOrNull;
        _selectedCategoryId =
            moradia?.id ??
            (categoriesToFilter.isNotEmpty
                ? categoriesToFilter.first.id
                : null);
      } else {
        _selectedCategoryId = categoriesToFilter.isNotEmpty
            ? categoriesToFilter.first.id
            : null;
      }

      // Pré-preenche o valor com o salário cadastrado ao abrir para entrada
      if (widget.defaultFilterType == 'income' && widget.userSalary > 0) {
        _amount = widget.userSalary.toStringAsFixed(2).replaceAll('.', ',');
      }
    }
  }

  String _monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  void _submitForm() {
    if (_formKey.currentState!.validate() && _selectedCategoryId != null) {
      _formKey.currentState!.save();
      final map = {
        'id': _isEditing ? widget.transactionToEdit!.id : 'temp',
        'description': _description,
        'amount': parseAmountInput(_amount) ?? 0.0,
        'categoryId': _selectedCategoryId!,
        'date': _selectedDate.toIso8601String().substring(0, 10),
        'isPaid': _isPaid,
        'comments': _comments,
        'isRecurring': _isRecurring,
        'recurringStartMonth': _isRecurring
            ? _monthKey(_recurringStartMonth)
            : null,
        'recurringEndMonth': _isRecurring
            ? _monthKey(_recurringEndMonth)
            : null,
      };
      final newTransaction = Transaction.fromMap(map);

      if (_isEditing) {
        widget.updateTransaction(newTransaction);
      } else {
        widget.addTransaction(newTransaction);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final incomeDefault = widget.categories
        .where((c) => c.type == 'income' && c.isDefault)
        .toList();
    final incomeCustom = widget.categories
        .where((c) => c.type == 'income' && !c.isDefault)
        .toList();
    final expenseDefault = widget.categories
        .where((c) => c.type == 'expense' && c.isDefault)
        .toList();
    final expenseCustom = widget.categories
        .where((c) => c.type == 'expense' && !c.isDefault)
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          _isEditing ? 'Editar Transação' : 'Novo',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(iconMap['X'], color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // ── Campos com scroll ──────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Descrição
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                      ),
                      onSaved: (value) => _description = value!,
                      validator: (value) =>
                          value!.isEmpty ? 'Campo obrigatório' : null,
                      initialValue: _description,
                    ),
                    const SizedBox(height: 15),
                    // Valor
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Valor (R\$)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onSaved: (value) => _amount = value!,
                      validator: (value) {
                        if (value!.isEmpty) return 'Campo obrigatório';
                        final parsed = parseAmountInput(value);
                        if (parsed == null) {
                          return 'Valor inválido. Ex: 1.200,45 ou 1200,45';
                        }
                        if (parsed <= 0) {
                          return 'O valor precisa ser maior que zero';
                        }
                        return null;
                      },
                      initialValue: _amount,
                    ),
                    const SizedBox(height: 15),
                    // Data
                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: _formatDateSafe(_selectedDate),
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Data',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        suffixIcon: Icon(
                          FontAwesomeIcons.calendar,
                          color: primaryColor,
                          size: 18,
                        ),
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
                          setState(() => _selectedDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                    // Categoria
                    Row(
                      children: [
                        Expanded(
                          child: FormField<String>(
                            initialValue: _selectedCategoryId,
                            validator: (value) => value == null
                                ? 'Selecione uma categoria'
                                : null,
                            builder: (state) {
                              final selectedCat = state.value != null
                                  ? widget.categories.firstWhere(
                                      (c) => c.id == state.value,
                                      orElse: () => widget.categories.first,
                                    )
                                  : null;
                              return GestureDetector(
                                onTap: () async {
                                  final result = await showDialog<String>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      title: const Text(
                                        'Selecione uma Categoria',
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                      content: SizedBox(
                                        width: double.maxFinite,
                                        child: ListView(
                                          shrinkWrap: true,
                                          children: [
                                            if (incomeDefault.isNotEmpty) ...[
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                      16,
                                                      8,
                                                      16,
                                                      4,
                                                    ),
                                                child: Text(
                                                  'Entradas',
                                                  style: TextStyle(
                                                    color: incomeColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              ...incomeDefault.map(
                                                (cat) => ListTile(
                                                  leading: CircleAvatar(
                                                    radius: 16,
                                                    backgroundColor: incomeColor
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                    child: Icon(
                                                      iconMap[cat.iconName] ??
                                                          Icons.circle,
                                                      color: incomeColor,
                                                      size: 16,
                                                    ),
                                                  ),
                                                  title: Text(cat.name),
                                                  selected:
                                                      cat.id == state.value,
                                                  selectedTileColor: incomeColor
                                                      .withValues(alpha: 0.08),
                                                  onTap: () => Navigator.of(
                                                    ctx,
                                                  ).pop(cat.id),
                                                ),
                                              ),
                                            ],
                                            if (incomeCustom.isNotEmpty) ...[
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                      16,
                                                      8,
                                                      16,
                                                      4,
                                                    ),
                                                child: Text(
                                                  'Entradas Personalizadas',
                                                  style: TextStyle(
                                                    color: incomeColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              ...incomeCustom.map(
                                                (cat) => ListTile(
                                                  leading: CircleAvatar(
                                                    radius: 16,
                                                    backgroundColor: incomeColor
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                    child: Icon(
                                                      iconMap[cat.iconName] ??
                                                          Icons.circle,
                                                      color: incomeColor,
                                                      size: 16,
                                                    ),
                                                  ),
                                                  title: Text(cat.name),
                                                  selected:
                                                      cat.id == state.value,
                                                  selectedTileColor: incomeColor
                                                      .withValues(alpha: 0.08),
                                                  onTap: () => Navigator.of(
                                                    ctx,
                                                  ).pop(cat.id),
                                                ),
                                              ),
                                            ],
                                            if (incomeDefault.isNotEmpty ||
                                                incomeCustom.isNotEmpty)
                                              const Divider(height: 1),
                                            if (expenseDefault.isNotEmpty) ...[
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                      16,
                                                      8,
                                                      16,
                                                      4,
                                                    ),
                                                child: Text(
                                                  'Saídas',
                                                  style: TextStyle(
                                                    color: expenseColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              ...expenseDefault.map(
                                                (cat) => ListTile(
                                                  leading: CircleAvatar(
                                                    radius: 16,
                                                    backgroundColor:
                                                        expenseColor.withValues(
                                                          alpha: 0.15,
                                                        ),
                                                    child: Icon(
                                                      iconMap[cat.iconName] ??
                                                          Icons.circle,
                                                      color: expenseColor,
                                                      size: 16,
                                                    ),
                                                  ),
                                                  title: Text(cat.name),
                                                  selected:
                                                      cat.id == state.value,
                                                  selectedTileColor:
                                                      expenseColor.withValues(
                                                        alpha: 0.08,
                                                      ),
                                                  onTap: () => Navigator.of(
                                                    ctx,
                                                  ).pop(cat.id),
                                                ),
                                              ),
                                            ],
                                            if (expenseCustom.isNotEmpty) ...[
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                      16,
                                                      8,
                                                      16,
                                                      4,
                                                    ),
                                                child: Text(
                                                  'Saídas Personalizadas',
                                                  style: TextStyle(
                                                    color: expenseColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              ...expenseCustom.map(
                                                (cat) => ListTile(
                                                  leading: CircleAvatar(
                                                    radius: 16,
                                                    backgroundColor:
                                                        expenseColor.withValues(
                                                          alpha: 0.15,
                                                        ),
                                                    child: Icon(
                                                      iconMap[cat.iconName] ??
                                                          Icons.circle,
                                                      color: expenseColor,
                                                      size: 16,
                                                    ),
                                                  ),
                                                  title: Text(cat.name),
                                                  selected:
                                                      cat.id == state.value,
                                                  selectedTileColor:
                                                      expenseColor.withValues(
                                                        alpha: 0.08,
                                                      ),
                                                  onTap: () => Navigator.of(
                                                    ctx,
                                                  ).pop(cat.id),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton.icon(
                                          icon: const Icon(
                                            FontAwesomeIcons.xmark,
                                          ),
                                          label: const Text('Cancelar'),
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (result != null) {
                                    setState(
                                      () => _selectedCategoryId = result,
                                    );
                                    state.didChange(result);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Categoria',
                                    border: const OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(24),
                                      ),
                                    ),
                                    suffixIcon: const Icon(
                                      Icons.arrow_drop_down,
                                    ),
                                    errorText: state.errorText,
                                  ),
                                  child: selectedCat != null
                                      ? Row(
                                          children: [
                                            Icon(
                                              iconMap[selectedCat.iconName] ??
                                                  Icons.circle,
                                              size: 16,
                                              color:
                                                  selectedCat.type == 'income'
                                                  ? incomeColor
                                                  : expenseColor,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '${selectedCat.name} '
                                                '(${selectedCat.type == 'income' ? 'Entrada' : 'Saída'})',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          'Selecione uma Categoria',
                                          style: TextStyle(
                                            color: Theme.of(context).hintColor,
                                          ),
                                        ),
                                ),
                              );
                            },
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
                              final result =
                                  await showDialog<Map<String, String>>(
                                    context: context,
                                    builder: (context) {
                                      String name = '';
                                      String type = 'expense';
                                      String selectedIcon = 'Porquinho';
                                      return AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
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
                                                  borderRadius:
                                                      BorderRadius.all(
                                                        Radius.circular(24),
                                                      ),
                                                ),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(24),
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
                                              onChanged: (v) =>
                                                  type = v ?? 'expense',
                                            ),
                                            const SizedBox(height: 8),
                                            DropdownButtonFormField<String>(
                                              initialValue: selectedIcon,
                                              items: iconMap.keys.map((
                                                iconKey,
                                              ) {
                                                return DropdownMenuItem(
                                                  value: iconKey,
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        iconMap[iconKey],
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(iconKey),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (v) => selectedIcon =
                                                  v ?? 'Porquinho',
                                              decoration: const InputDecoration(
                                                labelText: 'Ícone',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                        Radius.circular(24),
                                                      ),
                                                ),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                            ),
                                          ],
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
                                              FontAwesomeIcons.floppyDisk,
                                            ),
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
                                final newId =
                                    'cat_${DateTime.now().millisecondsSinceEpoch}';
                                final newCat = Category.fromMap({
                                  'id': newId,
                                  'name': result['name']!,
                                  'type': result['type']!,
                                  'iconName': result['icon'] ?? 'Porquinho',
                                });
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
                                child: Icon(
                                  FontAwesomeIcons.plus,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // ── Comentários (NOVO) ────────────────────────────────────
                    TextFormField(
                      initialValue: _comments,
                      decoration: const InputDecoration(
                        labelText: 'Comentários',
                        hintText: 'Informações extras (opcional)',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                      ),
                      maxLines: 2,
                      onSaved: (v) => _comments = v ?? '',
                    ),
                    const SizedBox(height: 12),
                    // ── Este valor já foi recebido/pago? ─────────────────────
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isPaid
                              ? Colors.green
                              : Theme.of(context).dividerColor,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: CheckboxListTile(
                        dense: true,
                        title: const Text(
                          'Este valor já foi recebido/pago?',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          _isPaid
                              ? 'Sim! Já registrado.'
                              : 'Não registrado ainda.',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isPaid ? Colors.green : Colors.redAccent,
                          ),
                        ),
                        secondary: Icon(
                          FontAwesomeIcons.circleCheck,
                          color: _isPaid ? Colors.green : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                          size: 18,
                        ),
                        value: _isPaid,
                        activeColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onChanged: (v) => setState(() => _isPaid = v ?? false),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // ── Recorrência ───────────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isRecurring
                              ? primaryColor
                              : Theme.of(context).dividerColor,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            dense: true,
                            title: const Text(
                              'Se repete mensalmente',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            secondary: Icon(
                              FontAwesomeIcons.arrowsRotate,
                              color: _isRecurring ? primaryColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                              size: 18,
                            ),
                            value: _isRecurring,
                            activeColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            onChanged: (v) =>
                                setState(() => _isRecurring = v ?? false),
                          ),
                          if (_isRecurring) ...[
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _MonthPickerTile(
                                      label: 'Mês inicial',
                                      value: _recurringStartMonth,
                                      onChanged: (d) => setState(() {
                                        _recurringStartMonth = d;
                                        if (_recurringEndMonth.isBefore(d)) {
                                          _recurringEndMonth = DateTime(
                                            d.year,
                                            d.month + 1,
                                          );
                                        }
                                      }),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _MonthPickerTile(
                                      label: 'Mês final',
                                      value: _recurringEndMonth,
                                      minDate: _recurringStartMonth,
                                      onChanged: (d) => setState(
                                        () => _recurringEndMonth = d,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                  ], // fecha lista de campos
                ), // fecha Column dos campos
              ), // fecha SingleChildScrollView
            ), // fecha Expanded
            // ── Botões — sobem com o teclado ─────────────────────────────
            AnimatedPadding(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              padding: EdgeInsets.fromLTRB(24, 8, 24, kb > 0 ? kb + 8 : 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(FontAwesomeIcons.xmark),
                      label: const Text('Cancelar'),
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ], // fecha Column do Form
        ), // fecha Column
      ), // fecha Form (body do Scaffold)
    ); // fecha Scaffold
  }
}

// Widget auxiliar para exibir linha de credencial no banner DEV
class _DevCredentialRow extends StatelessWidget {
  final String label;
  final String value;

  const _DevCredentialRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFFA6ADC8)),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFFF5C2E7),
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

// Widget auxiliar para seleção de mês/ano de recorrência
class _MonthPickerTile extends StatelessWidget {
  final String label;
  final DateTime value;
  final DateTime? minDate;
  final ValueChanged<DateTime> onChanged;

  const _MonthPickerTile({
    required this.label,
    required this.value,
    required this.onChanged,
    this.minDate,
  });

  static const List<String> _months = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];

  Future<void> _pick(BuildContext context) async {
    int selectedYear = value.year;
    int selectedMonth = value.month;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setS) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(label),
              content: SizedBox(
                width: 280,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Seletor de ano
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            FontAwesomeIcons.chevronLeft,
                            size: 14,
                          ),
                          onPressed: () => setS(() => selectedYear--),
                        ),
                        Text(
                          '$selectedYear',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            FontAwesomeIcons.chevronRight,
                            size: 14,
                          ),
                          onPressed: () => setS(() => selectedYear++),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Grade de meses
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 1.6,
                      children: List.generate(12, (i) {
                        final month = i + 1;
                        final isSelected =
                            selectedYear == value.year &&
                            month == selectedMonth;
                        final isDisabled =
                            minDate != null &&
                            DateTime(selectedYear, month).isBefore(minDate!);
                        return GestureDetector(
                          onTap: isDisabled
                              ? null
                              : () => setS(() => selectedMonth = month),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryColor
                                  : isDisabled
                                  ? Colors.grey[100]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _months[i],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.white
                                    : isDisabled
                                    ? Colors.grey[400]
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    onChanged(DateTime(selectedYear, selectedMonth));
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthName = _months[value.month - 1];
    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: primaryColor.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65)),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(
                  FontAwesomeIcons.calendar,
                  size: 12,
                  color: primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  '$monthName/${value.year}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
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
          color: transaction.isPaid
              ? color.withAlpha(26)
              : const Color.fromARGB(255, 255, 220, 160),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    // Ícone da Categoria
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: transaction.isPaid
                            ? color.withAlpha(26)
                            : const Color.fromARGB(255, 255, 200, 140),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        iconMap[category.iconName],
                        color: transaction.isPaid
                            ? color
                            : const Color.fromARGB(255, 200, 100, 0),
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
                              color: transaction.isPaid
                                  ? color
                                  : const Color.fromARGB(255, 200, 100, 0),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Categoria e Data
                          Text(
                            '${category.name} • ${formatDate(transaction.date)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                            ),
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
                          formatCurrency(
                            transaction.amount,
                          ).replaceAll('-', ''),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: transaction.isPaid
                                ? color
                                : const Color.fromARGB(255, 200, 100, 0),
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
                              color: transaction.isPaid
                                  ? color
                                  : Colors.grey[300],
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
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
                // ── Linha de recorrência (parcelas) ─────────────────
                if (transaction.isRecurring &&
                    transaction.recurringStartMonth != null &&
                    transaction.recurringEndMonth != null)
                  Builder(
                    builder: (_) {
                      final start = DateTime.parse(
                        '${transaction.recurringStartMonth}-01',
                      );
                      final end = DateTime.parse(
                        '${transaction.recurringEndMonth}-01',
                      );
                      final current = DateTime(
                        transaction.date.year,
                        transaction.date.month,
                      );
                      final current_ =
                          (current.year - start.year) * 12 +
                          current.month -
                          start.month +
                          1;
                      final total =
                          (end.year - start.year) * 12 +
                          end.month -
                          start.month +
                          1;
                      final rowColor = transaction.isPaid
                          ? color
                          : const Color.fromARGB(255, 200, 100, 0);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: rowColor.withAlpha(140),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.schedule, size: 14, color: rowColor),
                              const SizedBox(width: 6),
                              Text(
                                transaction.isPaid
                                    ? 'Pago em ${formatDate(transaction.date)}'
                                    : 'Pagar em ${formatDate(transaction.date)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: rowColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: transaction.isPaid
                                      ? color
                                      : const Color.fromARGB(255, 200, 100, 0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$current_/$total',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
  final DateTime? focusDate; // Força navegação para este mês quando fornecido
  final Function(String)? onFilterChanged; // Notifica pai quando filtro muda

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
    this.focusDate,
    this.onFilterChanged,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  DateTime _selectedDate = DateTime.now();
  late String _activeFilter;
  List<Transaction> _filteredTransactions = [];

  // Mapeia valores legados ('income'/'expense') para os novos filtros granulares
  String _mapFilterType(String f) {
    if (f == 'income') return 'income_pending';
    if (f == 'expense') return 'expense_pending';
    return f;
  }

  void _computeFilteredTransactions() {
    final List<Transaction> expanded = [];
    for (final t in widget.transactions) {
      if (t.isRecurring &&
          t.recurringStartMonth != null &&
          t.recurringEndMonth != null) {
        final start = DateTime.parse('${t.recurringStartMonth}-01');
        final end = DateTime.parse('${t.recurringEndMonth}-01');
        final selected = DateTime(_selectedDate.year, _selectedDate.month);
        if (!selected.isBefore(start) && !selected.isAfter(end)) {
          final monthKey =
              '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}';
          if (t.deletedMonths.contains(monthKey)) continue;
          final day = t.date.day;
          final daysInMonth = DateUtils.getDaysInMonth(
            _selectedDate.year,
            _selectedDate.month,
          );
          final adjustedDay = day.clamp(1, daysInMonth);
          final map = t.toMap();
          map['id'] = '${t.id}@$monthKey';
          map['date'] =
              '$monthKey-${adjustedDay.toString().padLeft(2, '0')}';
          map['isPaid'] = t.paidByMonth[monthKey] ?? false;
          expanded.add(Transaction.fromMap(map));
        }
      } else if (t.date.year == _selectedDate.year &&
          t.date.month == _selectedDate.month) {
        expanded.add(t);
      }
    }
    _filteredTransactions = expanded.where((t) {
      final type = widget.getCategoryById(t.categoryId).type;
      switch (_activeFilter) {
        case 'income_pending':  return type == 'income' && !t.isPaid;
        case 'income_received': return type == 'income' && t.isPaid;
        case 'expense_pending': return type == 'expense' && !t.isPaid;
        case 'expense_paid':    return type == 'expense' && t.isPaid;
        default:                return true; // 'all'
      }
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  void initState() {
    super.initState();
    _activeFilter = _mapFilterType(widget.filterType);
    _computeFilteredTransactions();
  }

  @override
  void didUpdateWidget(TransactionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool needsRecompute = widget.transactions != oldWidget.transactions;

    if (widget.filterType != oldWidget.filterType) {
      _activeFilter = _mapFilterType(widget.filterType);
      needsRecompute = true;
    }
    if (widget.focusDate != null &&
        widget.focusDate != oldWidget.focusDate &&
        (widget.focusDate!.year != _selectedDate.year ||
            widget.focusDate!.month != _selectedDate.month)) {
      _selectedDate = DateTime(
        widget.focusDate!.year,
        widget.focusDate!.month,
      );
      needsRecompute = true;
    }
    if (needsRecompute) {
      setState(() => _computeFilteredTransactions());
    }
  }

  Widget _filterChip(String label, String value, Color color, IconData icon) {
    final selected = _activeFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = value;
          _computeFilteredTransactions();
        });
        widget.onFilterChanged?.call(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withAlpha(20),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: selected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          children: [
            Icon(
              iconMap['Calendario'],
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum registro cadastrado em ${DateFormat('MMMM', 'pt_BR').format(_selectedDate)}',
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
    final filteredTransactions = _filteredTransactions;

    return Column(
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
        const SizedBox(height: 12),

        // Month Selector — pill shape, full width
        Container(
          decoration: BoxDecoration(
            color: primaryColor.withAlpha(20),
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(FontAwesomeIcons.chevronLeft, size: 14),
                color: primaryColor,
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month - 1,
                    );
                    _computeFilteredTransactions();
                    widget.onDateChanged?.call(_selectedDate);
                  });
                },
              ),
              Expanded(
                child: GestureDetector(
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
                        _computeFilteredTransactions();
                        widget.onDateChanged?.call(_selectedDate);
                      });
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 17,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('MMMM yyyy', 'pt_BR').format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(FontAwesomeIcons.chevronRight, size: 14),
                color: primaryColor,
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month + 1,
                    );
                    _computeFilteredTransactions();
                    widget.onDateChanged?.call(_selectedDate);
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Filter chips — 4 filtros: A Receber / Recebidos / A Pagar / Pagos
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterChip(
              'A Receber',
              'income_pending',
              incomeColor,
              FontAwesomeIcons.arrowTrendUp,
            ),
            _filterChip(
              'Recebidos',
              'income_received',
              incomeColor,
              FontAwesomeIcons.circleCheck,
            ),
            _filterChip(
              'A Pagar',
              'expense_pending',
              expenseColor,
              FontAwesomeIcons.arrowTrendDown,
            ),
            _filterChip(
              'Pagos',
              'expense_paid',
              primaryColor,
              FontAwesomeIcons.checkDouble,
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (filteredTransactions.isEmpty)
          _buildEmptyState(context)
        else
          Flexible(
            child: ClipPath(
              clipper: const _InvertedCornerClipper(radius: 24),
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final t = filteredTransactions[index];
                    final cat = widget.getCategoryById(t.categoryId);
                    final isIncome = cat.type == 'income';
                    final color = isIncome ? incomeColor : expenseColor;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
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
                            ? (isPaid) =>
                                widget.onPaidStatusChanged!(t.id, isPaid)
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final iconSize = isMobile ? 52.0 : 72.0;
            final valueFontSize = isMobile ? 28.0 : 40.0;
            final titleFontSize = isMobile ? 16.0 : 20.0;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Texto (título + valor) à esquerda
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatCurrency(value),
                        style: TextStyle(
                          fontSize: valueFontSize,
                          fontWeight: FontWeight.w900,
                          color: valueColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Ícone transparente à direita, alinhado ao fim do card
                if (icon != null)
                  Opacity(
                    opacity: 0.12,
                    child: FaIcon(icon!, color: color, size: iconSize),
                  ),
              ],
            );
          },
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
      clipBehavior: Clip.antiAlias,
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
            const SizedBox(height: 16),
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FontAwesomeIcons.chartPie,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'Sem dados para exibir o gráfico.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return LayoutBuilder(
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
                    textColor: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            );
          },
        );
      },
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
  final Color textColor;

  _ModernPieChartPainter({
    required this.income,
    required this.expense,
    required this.total,
    required this.incomeColor,
    required this.expenseColor,
    required this.animationValue,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 * 0.75;
    final strokeW = radius * 0.38;
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    // ── Anel de fundo (trilha) ──────────────────────────────────────
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.grey.withAlpha(40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );

    final incomeSweep = income > 0 ? (income / total) * 2 * pi : 0.0;
    final expenseSweep = expense > 0 ? (expense / total) * 2 * pi : 0.0;
    final gap = incomeSweep > 0 && expenseSweep > 0 ? 0.03 : 0.0;

    // ── Segmento de Entradas ────────────────────────────────────────
    if (income > 0) {
      canvas.drawArc(
        arcRect,
        -pi / 2 + gap / 2,
        (incomeSweep - gap) * animationValue,
        false,
        Paint()
          ..color = incomeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.butt,
      );
    }

    // ── Segmento de Saídas ──────────────────────────────────────────
    if (expense > 0) {
      canvas.drawArc(
        arcRect,
        -pi / 2 + incomeSweep * animationValue + gap / 2,
        (expenseSweep - gap) * animationValue,
        false,
        Paint()
          ..color = expenseColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.butt,
      );
    }

    // ── Labels de porcentagem ────────────────────────────────────────
    // Segmento grande (>= 60°): label DENTRO do arco, cor branca.
    // Segmento pequeno (< 60°): label FORA do arco, na cor do segmento.
    if (animationValue >= 1.0) {
      void drawPctLabel(double sweep, double startAngle, Color color) {
        if (sweep < 0.08) return;
        final midAngle = startAngle + sweep / 2;
        final pct = '${(sweep / (2 * pi) * 100).toStringAsFixed(1)}%';
        final showInside = sweep >= pi / 3; // >= ~60°
        final labelRadius = showInside ? radius : radius + strokeW * 0.80;
        final labelColor = showInside ? Colors.white : color;

        final x = center.dx + labelRadius * cos(midAngle);
        final y = center.dy + labelRadius * sin(midAngle);

        final tp = TextPainter(
          text: TextSpan(
            text: pct,
            style: TextStyle(
              color: labelColor,
              fontSize: size.width * 0.062,
              fontWeight: FontWeight.bold,
              shadows: showInside
                  ? [Shadow(color: Colors.black38, blurRadius: 4)]
                  : null,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
      }

      drawPctLabel(incomeSweep, -pi / 2 + gap / 2, incomeColor);
      drawPctLabel(expenseSweep, -pi / 2 + incomeSweep + gap / 2, expenseColor);
    }

    // ── Texto central: "Total" + valor ─────────────────────────────
    if (animationValue > 0.4) {
      final fade = ((animationValue - 0.4) / 0.6).clamp(0.0, 1.0);

      // Linha "Total"
      final labelTp = TextPainter(
        text: TextSpan(
          text: 'Total',
          style: TextStyle(
            color: textColor.withAlpha((120 * fade).round()),
            fontSize: size.width * 0.065,
            fontWeight: FontWeight.w400,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      labelTp.paint(
        canvas,
        Offset(
          center.dx - labelTp.width / 2,
          center.dy - labelTp.height - size.width * 0.015,
        ),
      );

      // Valor formatado
      final valTp = TextPainter(
        text: TextSpan(
          text: formatCurrency(total),
          style: TextStyle(
            color: textColor.withAlpha((220 * fade).round()),
            fontSize: size.width * 0.072,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      valTp.paint(
        canvas,
        Offset(center.dx - valTp.width / 2, center.dy + size.width * 0.015),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ModernPieChartPainter oldDelegate) =>
      oldDelegate.income != income ||
      oldDelegate.expense != expense ||
      oldDelegate.total != total ||
      oldDelegate.animationValue != animationValue ||
      oldDelegate.textColor != textColor;
}

/// Gera um caminho com cantos côncavos (invertidos).
/// O ponto de controle de cada bezier é o vértice do canto, o que puxa
/// a curva para dentro e cria o efeito de encaixe.
class _InvertedCornerClipper extends CustomClipper<Path> {
  final double radius;
  const _InvertedCornerClipper({this.radius = 24.0});

  @override
  Path getClip(Size size) {
    final r = radius;
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, h - r)
      ..quadraticBezierTo(w, h, w - r, h)
      ..lineTo(r, h)
      ..quadraticBezierTo(0, h, 0, h - r)
      ..close();
  }

  @override
  bool shouldReclip(_InvertedCornerClipper old) => old.radius != radius;
}

// --- Componente de Resumo por Categoria ---
class CategorySummaryCard extends StatelessWidget {
  final String title;
  final String icon;
  final List<Map<String, dynamic>> data;
  final Color color;
  final double total;

  const CategorySummaryCard({
    super.key,
    required this.title,
    required this.icon,
    required this.data,
    required this.color,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                const Spacer(),
                Text(
                  formatCurrency(total).replaceAll('R\$', '').trim(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (data.isEmpty)
              Center(
                child: Text(
                  'Nenhuma transação de ${title.toLowerCase()} registrada.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.length,
                separatorBuilder: (context, index) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final cat = data[index];
                  return Row(
                    children: [
                      // Ícone da Categoria
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          iconMap[cat['icon']],
                          color: color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
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
                              '${cat['count']} registro${cat['count'] != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
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
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final Map<String, double> summary;
  final DateTime selectedMonth;
  final void Function(DateTime) onMonthChanged;
  final void Function(String filterType)? onNavigateToExtract;

  const DashboardScreen({
    super.key,
    required this.summary,
    required this.selectedMonth,
    required this.onMonthChanged,
    this.onNavigateToExtract,
  });

  @override
  Widget build(BuildContext context) {
    final paidIncome = summary['paidIncome'] ?? 0;
    final paidExpense = summary['paidExpense'] ?? 0;
    final totalIncome = summary['totalIncome'] ?? 0;
    final totalExpense = summary['totalExpense'] ?? 0;
    final balance = summary['balance'] ?? 0;
    final previsto = summary['previsto'] ?? 0;
    final pendingIncome = summary['pendingIncome'] ?? 0;
    final pendingExpense = summary['pendingExpense'] ?? 0;

    final totalSettled = paidIncome + paidExpense;
    final totalAll = totalIncome + totalExpense;
    final progress = totalAll > 0
        ? (totalSettled / totalAll).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Seletor de mês ──────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: primaryColor.withAlpha(20),
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(FontAwesomeIcons.chevronLeft, size: 14),
                color: primaryColor,
                onPressed: () => onMonthChanged(
                  DateTime(selectedMonth.year, selectedMonth.month - 1),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedMonth,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      initialDatePickerMode: DatePickerMode.year,
                    );
                    if (picked != null) {
                      onMonthChanged(DateTime(picked.year, picked.month));
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 17,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('MMMM yyyy', 'pt_BR').format(selectedMonth),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(FontAwesomeIcons.chevronRight, size: 14),
                color: primaryColor,
                onPressed: () => onMonthChanged(
                  DateTime(selectedMonth.year, selectedMonth.month + 1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Card Saldo Atual ─────────────────────────────────────────
        Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: incomeColor, width: 1),
          ),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: incomeColor, width: 3)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: incomeColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        FontAwesomeIcons.wallet,
                        color: incomeColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Saldo Atual',
                      style: TextStyle(
                        color: incomeColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Valor principal
                Text(
                  formatCurrency(balance),
                  style: TextStyle(
                    color: balance >= 0 ? incomeColor : expenseColor,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                // Recebido / Pago / Previsto
                IntrinsicHeight(
                  child: Row(
                    children: [
                      _balanceStat(
                        context,
                        icon: FontAwesomeIcons.arrowTrendUp,
                        label: 'Recebido',
                        value: paidIncome,
                        color: incomeColor,
                      ),
                      VerticalDivider(
                        color: Theme.of(context).dividerColor.withAlpha(80),
                        width: 24,
                      ),
                      _balanceStat(
                        context,
                        icon: FontAwesomeIcons.arrowTrendDown,
                        label: 'Pago',
                        value: paidExpense,
                        color: expenseColor,
                      ),
                      VerticalDivider(
                        color: Theme.of(context).dividerColor.withAlpha(80),
                        width: 24,
                      ),
                      _balanceStat(
                        context,
                        icon: Icons.event_note_outlined,
                        label: 'Previsto',
                        value: previsto,
                        color: previsto < 0 ? expenseColor : primaryColor,
                      ),
                    ],
                  ),
                ),
                Divider(
                  color: Theme.of(context).dividerColor.withAlpha(60),
                  height: 24,
                  thickness: 0.5,
                ),
                // Barra de progresso
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Progresso: ${(progress * 100).round()}% do mês',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: (balance >= 0 ? incomeColor : expenseColor).withAlpha(40),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                balance >= 0 ? incomeColor : expenseColor,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onNavigateToExtract != null)
                      GestureDetector(
                        onTap: () => onNavigateToExtract?.call('all'),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.chevron_right,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── ENTRADAS card ───────────────────────────────────────────
        GestureDetector(
          onTap: () => onNavigateToExtract?.call('income'),
          child: Card(
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              side: BorderSide(color: primaryColor, width: 1),
            ),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: primaryColor, width: 3)),
              ),
              padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        FontAwesomeIcons.arrowTrendUp,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contas a Receber',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatCurrency(totalIncome),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => onNavigateToExtract?.call('income'),
                      child: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Divider(height: 20, thickness: 0.5, color: Theme.of(context).dividerColor),
                Row(
                  children: [
                    _summaryItem(
                      context,
                      label: 'Recebido',
                      value: paidIncome,
                      color: incomeColor,
                    ),
                    const Spacer(),
                    _summaryItem(
                      context,
                      label: 'A Receber',
                      value: pendingIncome,
                      color: expenseColor,
                      align: CrossAxisAlignment.end,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        ),
        const SizedBox(height: 12),

        // ── SAÍDAS card ─────────────────────────────────────────────
        GestureDetector(
          onTap: () => onNavigateToExtract?.call('expense'),
          child: Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: expenseColor, width: 1),
          ),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: expenseColor, width: 3)),
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: expenseColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        FontAwesomeIcons.arrowTrendDown,
                        color: expenseColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contas a Pagar',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: expenseColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatCurrency(totalExpense),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: expenseColor,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => onNavigateToExtract?.call('expense'),
                      child: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Divider(height: 20, thickness: 0.5, color: Theme.of(context).dividerColor),
                Row(
                  children: [
                    _summaryItem(
                      context,
                      label: 'Pago',
                      value: paidExpense,
                      color: incomeColor,
                    ),
                    const Spacer(),
                    _summaryItem(
                      context,
                      label: 'A Pagar',
                      value: pendingExpense,
                      color: expenseColor,
                      align: CrossAxisAlignment.end,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _balanceStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required double value,
    Color color = primaryColor,
  }) {
    final text = formatCurrency(value.abs()).replaceAll('R\$', '').trim();
    final subColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: subColor, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
    BuildContext context, {
    required String label,
    required double value,
    required Color color,
    CrossAxisAlignment align = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formatCurrency(value),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
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
    // 1. Filtrar transações pelo mês selecionado (incluindo recorrentes)
    final List<Transaction> monthlyTransactions = [];
    for (final t in widget.transactions) {
      if (t.isRecurring &&
          t.recurringStartMonth != null &&
          t.recurringEndMonth != null) {
        final start = DateTime.parse('${t.recurringStartMonth}-01');
        final end = DateTime.parse('${t.recurringEndMonth}-01');
        final selected = DateTime(_selectedDate.year, _selectedDate.month);
        if (!selected.isBefore(start) && !selected.isAfter(end)) {
          // Cria cópia virtual com isPaid do mês correto
          final monthKey =
              '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}';
          if (t.deletedMonths.contains(monthKey)) continue;
          final map = t.toMap();
          map['isPaid'] = t.paidByMonth[monthKey] ?? false;
          monthlyTransactions.add(Transaction.fromMap(map));
        }
      } else if (t.date.year == _selectedDate.year &&
          t.date.month == _selectedDate.month) {
        monthlyTransactions.add(t);
      }
    }

    // 2. Calcular totais e agrupamentos
    double totalIncome = 0;
    double totalExpense = 0;
    final Map<String, Map<String, dynamic>> categorySummary = {
      'income': {},
      'expense': {},
    };

    for (var t in monthlyTransactions) {
      // Considerar apenas transações pagas/recebidas nos relatórios
      if (!t.isPaid) continue;

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

        // Month Selector — pill shape, full width
        Container(
          decoration: BoxDecoration(
            color: primaryColor.withAlpha(20),
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(FontAwesomeIcons.chevronLeft, size: 14),
                color: primaryColor,
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month - 1,
                    );
                  });
                },
              ),
              Expanded(
                child: GestureDetector(
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 17,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('MMMM yyyy', 'pt_BR').format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(FontAwesomeIcons.chevronRight, size: 14),
                color: primaryColor,
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
        const SizedBox(height: 16),

        if (monthlyTransactions.isEmpty)
          _buildEmptyState(context)
        else
          Flexible(
            child: ClipPath(
              clipper: const _InvertedCornerClipper(radius: 24),
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  child: _buildCharts(
                    context,
                    pieData,
                    sortedIncomeCats,
                    sortedExpenseCats,
                  ),
                ),
              ),
            ),
          ),
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
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
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
    final totalIncome =
        (pieData.isNotEmpty ? pieData[0]['income'] : 0.0) as double;
    final totalExpense =
        (pieData.isNotEmpty ? pieData[0]['expense'] : 0.0) as double;

    return Column(
      children: [
        // Gráfico de Pizza
        ChartCard(
          title: 'Distribuição Mensal',
          height: 250,
          chartWidget: AnnualPieChart(data: pieData),
        ),
        const SizedBox(height: 16),

        // Tabelas por categoria
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            if (isMobile) {
              return Column(
                children: [
                  CategorySummaryCard(
                    title: 'Entradas',
                    icon: 'SetaCimaTendencia',
                    data: sortedIncomeCats,
                    color: incomeColor,
                    total: totalIncome,
                  ),
                  const SizedBox(height: 16),
                  CategorySummaryCard(
                    title: 'Saídas',
                    icon: 'Painel',
                    data: sortedExpenseCats,
                    color: expenseColor,
                    total: totalExpense,
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CategorySummaryCard(
                    title: 'Entradas',
                    icon: 'SetaCimaTendencia',
                    data: sortedIncomeCats,
                    color: incomeColor,
                    total: totalIncome,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CategorySummaryCard(
                    title: 'Saídas',
                    icon: 'Painel',
                    data: sortedExpenseCats,
                    color: expenseColor,
                    total: totalExpense,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ===================================================================
// 4.1 WIDGET: TELA DE PERFIL
// ===================================================================

class _SyncTile extends StatelessWidget {
  final Future<void> Function() onSync;
  final Future<bool> Function() onCheckExisting;
  const _SyncTile({required this.onSync, required this.onCheckExisting});

  void _showSyncDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _SyncDialog(onSync: onSync, onCheckExisting: onCheckExisting),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.cloud_sync_outlined, color: primaryColor),
      title: const Text('Sincronizar'),
      subtitle: const Text('Salvar entradas e saídas na nuvem'),
      trailing: const Icon(FontAwesomeIcons.chevronRight),
      onTap: () => _showSyncDialog(context),
    );
  }
}

class _SyncDialog extends StatefulWidget {
  final Future<void> Function() onSync;
  final Future<bool> Function() onCheckExisting;
  const _SyncDialog({required this.onSync, required this.onCheckExisting});

  @override
  State<_SyncDialog> createState() => _SyncDialogState();
}

// Estados internos do fluxo de sincronização
enum _SyncStep { idle, checking, confirmReplace, syncing, done, error }

class _SyncDialogState extends State<_SyncDialog> {
  _SyncStep _step = _SyncStep.idle;
  String? _error;

  Future<void> _onSyncPressed() async {
    setState(() => _step = _SyncStep.checking);
    try {
      final hasData = await widget.onCheckExisting();
      if (!mounted) return;
      if (hasData) {
        setState(() => _step = _SyncStep.confirmReplace);
      } else {
        await _doSync();
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _step = _SyncStep.error;
          _error = e.toString();
        });
    }
  }

  Future<void> _doSync() async {
    setState(() => _step = _SyncStep.syncing);
    try {
      await widget.onSync();
      if (mounted) setState(() => _step = _SyncStep.done);
    } catch (e) {
      if (mounted)
        setState(() {
          _step = _SyncStep.error;
          _error = e.toString();
        });
    }
  }

  bool get _busy => _step == _SyncStep.checking || _step == _SyncStep.syncing;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, minWidth: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Cabeçalho ──────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sincronizar',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // ── Ícone central ───────────────────────────────────
                const SizedBox(height: 8),
                Center(
                  child: _busy
                      ? const SizedBox(
                          width: 56,
                          height: 56,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: primaryColor,
                          ),
                        )
                      : Icon(
                          _step == _SyncStep.done
                              ? Icons.cloud_done_outlined
                              : _step == _SyncStep.error
                              ? Icons.cloud_off_outlined
                              : _step == _SyncStep.confirmReplace
                              ? Icons.warning_amber_rounded
                              : Icons.cloud_sync_outlined,
                          size: 56,
                          color: _step == _SyncStep.done
                              ? incomeColor
                              : _step == _SyncStep.error
                              ? expenseColor
                              : _step == _SyncStep.confirmReplace
                              ? Colors.orange
                              : primaryColor,
                        ),
                ),
                const SizedBox(height: 16),

                // ── Mensagem de status ──────────────────────────────
                Center(
                  child: Text(
                    switch (_step) {
                      _SyncStep.checking => 'Verificando dados existentes...',
                      _SyncStep.syncing => 'Sincronizando entradas e saídas...',
                      _SyncStep.done => 'Dados sincronizados com sucesso!',
                      _SyncStep.error =>
                        'Erro ao sincronizar. Tente novamente.',
                      _SyncStep.confirmReplace =>
                        'Já existem registros salvos na sua conta.\nDeseja substituir os dados existentes?',
                      _SyncStep.idle =>
                        'Todos os dados de entradas e saídas serão salvos na sua conta do Firebase.',
                    },
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: _step == _SyncStep.done
                          ? incomeColor
                          : _step == _SyncStep.error
                          ? expenseColor
                          : _step == _SyncStep.confirmReplace
                          ? Colors.orange
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Botões ──────────────────────────────────────────
                if (_step == _SyncStep.done)
                  ElevatedButton.icon(
                    icon: const Icon(FontAwesomeIcons.check),
                    label: const Text('Concluído'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: incomeColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                else if (_step == _SyncStep.confirmReplace)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(FontAwesomeIcons.xmark),
                          label: const Text('Cancelar'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(FontAwesomeIcons.arrowsRotate),
                          label: const Text('Substituir'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _doSync,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(FontAwesomeIcons.xmark),
                          label: const Text('Cancelar'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _busy
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(FontAwesomeIcons.cloudArrowUp),
                          label: const Text('Sincronizar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _busy ? null : _onSyncPressed,
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
  final Future<void> Function()? onSyncToFirebase;
  final Future<bool> Function()? onCheckExistingData;
  final List<Transaction> transactions;
  final DateTime selectedMonth;
  final Category Function(String) getCategoryById;

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
    required this.transactions,
    required this.selectedMonth,
    required this.getCategoryById,
    this.onSyncToFirebase,
    this.onCheckExistingData,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _isEditing = false;

  /// Soma todas as entradas (income) do mês selecionado, incluindo recorrentes.
  /// Soma todas as entradas (income) do mês selecionado, incluindo recorrentes.
  double _incomeForSelectedMonth() {
    final month = widget.selectedMonth;
    double total = 0;
    for (final t in widget.transactions) {
      final cat = widget.getCategoryById(t.categoryId);
      if (cat.type != 'income') continue;
      bool matches;
      if (t.isRecurring &&
          t.recurringStartMonth != null &&
          t.recurringEndMonth != null) {
        final start = DateTime.parse('${t.recurringStartMonth}-01');
        final end = DateTime.parse('${t.recurringEndMonth}-01');
        final sel = DateTime(month.year, month.month);
        final mKey =
            '${month.year}-${month.month.toString().padLeft(2, '0')}';
        matches = !sel.isBefore(start) &&
            !sel.isAfter(end) &&
            !t.deletedMonths.contains(mKey);
      } else {
        matches = t.date.year == month.year && t.date.month == month.month;
      }
      if (matches) total += t.amount;
    }
    return total;
  }

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
                              Text(
                                'Nome',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                              Text(
                                'Email',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    final currentIncome = _incomeForSelectedMonth();
    final initialValue =
        widget.user.salary > 0 ? widget.user.salary : currentIncome;
    final initialText =
        NumberFormat('#,##0.00', 'pt_BR').format(initialValue);
    final monthLabel = DateFormat(
      'MMM/yyyy',
      'pt_BR',
    ).format(widget.selectedMonth);

    TextEditingController salaryController = TextEditingController(
      text: initialText,
    );
    salaryController.selection = TextSelection.fromPosition(
      TextPosition(offset: salaryController.text.length),
    );

    showDialog(
      context: context,
      builder: (context) => Center(
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Salário — $monthLabel'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: salaryController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                autofocus: true,
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
                      parseAmountInput(salaryController.text) ?? 0.0;

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

  void _showCustomCategoriesListDialog() {
    final customCats = widget.categories.where((c) => !c.isDefault).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(FontAwesomeIcons.tag, color: primaryColor),
              const SizedBox(width: 12),
              const Text('Categorias'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: customCats.isEmpty
                ? const Text('Nenhuma categoria personalizada cadastrada.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: customCats.length,
                    itemBuilder: (context, index) {
                      final cat = customCats[index];
                      final isIncome = cat.type == 'income';
                      final color = isIncome ? incomeColor : expenseColor;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        elevation: 0,
                        color: color.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Icon(
                            iconMap[cat.iconName] ?? Icons.circle,
                            color: color,
                          ),
                          title: Text(
                            cat.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(isIncome ? 'Entrada' : 'Saída'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  FontAwesomeIcons.penToSquare,
                                  size: 18,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showEditCategoryDialog(cat);
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  size: 18,
                                  color: expenseColor,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
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
                                              Navigator.of(ctx).pop(),
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
                                            Navigator.of(ctx).pop();
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
                    },
                  ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(FontAwesomeIcons.xmark),
              label: const Text('Fechar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
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
                  ListTile(
                    leading: const Icon(
                      FontAwesomeIcons.userPlus,
                      color: primaryColor,
                    ),
                    title: const Text('Convidar Colaborador'),
                    subtitle: const Text('Adicionar acesso compartilhado'),
                    trailing: const Icon(FontAwesomeIcons.chevronRight),
                    onTap: widget.onInviteCollaborator,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(
                      FontAwesomeIcons.moneyBill,
                      color: primaryColor,
                    ),
                    title: const Text('Renda'),
                    subtitle: Text(
                      '${formatCurrency(_incomeForSelectedMonth())} · ${DateFormat('MMM/yyyy', 'pt_BR').format(widget.selectedMonth)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
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
            child: ListTile(
              leading: const Icon(FontAwesomeIcons.tag, color: primaryColor),
              title: const Text('Categorias Personalizadas'),
              subtitle: Text(
                '${widget.categories.where((c) => !c.isDefault).length} cadastradas',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: const Icon(FontAwesomeIcons.chevronRight),
              onTap: _showCustomCategoriesListDialog,
            ),
          ),

          if (widget.onSyncToFirebase != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _SyncTile(
                onSync: widget.onSyncToFirebase!,
                onCheckExisting:
                    widget.onCheckExistingData ?? () async => false,
              ),
            ),
          ],

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
  late final AnimationController _fadeController;
  late final Animation<double> _scale;
  late final Animation<double> _fadeAnimation;

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
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
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

  PageRouteBuilder<void> _fadeRoute() => PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, _, _) => MainApp(
      toggleTheme: widget.toggleTheme,
      isDarkMode: widget.isDarkMode,
    ),
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );

  Future<void> _navigateToHome() async {
    try {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;

      // Fade-out da splash antes de navegar
      await _fadeController.forward();
      if (!mounted) return;

      void doNavigate() {
        try {
          Navigator.of(context).pushReplacement(_fadeRoute());
        } catch (e, st) {
          // ignore: avoid_print
          print('Navigation error in SplashScreen: $e\n$st');
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) => doNavigate());

      // Watchdog: garante saída da splash após 5s em caso de erro silencioso
      Future.delayed(const Duration(seconds: 5), () {
        if (!mounted) return;
        final route = ModalRoute.of(context);
        if (route != null && route.isCurrent) {
          try {
            Navigator.of(context).pushReplacement(_fadeRoute());
          } catch (e) {
            // ignore: avoid_print
            print('Watchdog navigation failed: $e');
          }
        }
      });
    } catch (e, st) {
      // ignore: avoid_print
      print('Unexpected error in _navigateToHome: $e\n$st');
      if (!mounted) return;
      try {
        Navigator.of(context).pushReplacement(_fadeRoute());
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _rotationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
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
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializar intl para PT-BR (necessário para formatação de datas)
  await initializeDateFormatting('pt_BR', null);
  // Inicializar Firebase (somente em produção; mock não precisa)
  if (!useMockAuth) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
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

// ──────────────────────────────────────────────────────────────────────────────

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

class _MainAppState extends State<MainApp>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // Estado da Aplicação
  bool _isLoading = true;
  // Na web inicia bloqueado para permitir preview da animação de desbloqueio
  // Inicia bloqueado na web (preview) — no dispositivo é definido após detectar biometria
  bool _isLocked = kIsWeb;
  bool _showUnlockAnimation = false;
  bool _isAuthenticating = false;
  late final AnimationController _unlockAnimController;
  late final AnimationController _unlockFadeController;


  // Visibilidade de senha nas telas de autenticação
  bool _loginObscure = true;
  bool _signupObscure = true;
  bool _signupConfirmObscure = true;

  // Controllers da tela de login — declarados aqui para sobreviver ao setState
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();
  int _selectedIndex = 0; // 0: Início, 1: Extrato, 2: Relatórios
  DateTime _dashboardSelectedMonth =
      DateTime.now(); // Mês selecionado no Dashboard
  DateTime? _extractFocusDate; // Força navegação do extrato para este mês
  String _extractFilterType = 'all'; // 'all', 'income', 'expense'

  late final AuthService _authService;
  final FirestoreService _firestoreService = FirestoreService();
  User? _currentUser;
  // UID do dono dos dados: igual ao _currentUser.id para owners,
  // ou uid do owner quando o usuário logado é um colaborador.
  String? _dataOwnerUid;
  List<User> _collaborators = [];
  List<Invitation> _invitations = [];

  List<Transaction> _transactions = [];
  List<Category> _categories = [];

  // Subscriptions de tempo real do Firestore
  StreamSubscription<List<Map<String, dynamic>>>? _txSub;
  StreamSubscription<List<Map<String, dynamic>>>? _catSub;

  @override
  void initState() {
    super.initState();
    _unlockAnimController = AnimationController(vsync: this);
    _unlockFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    WidgetsBinding.instance.addObserver(this);
    // Configure auth service: mock em debug, Firebase em produção
    _authService = useMockAuth ? MockAuthService() : FirebaseAuthService();
    _loadCachedData().then((_) {
      // Bloqueia ao iniciar se o dispositivo tiver PIN/biometria ativo
      _lockIfSecured();
      // Auto-dispara biometria no login se o usuário já tinha entrado antes
      if (!kIsWeb && _currentUser == null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final prefs = await SharedPreferences.getInstance();
          final savedEmail = prefs.getString('biometricUserEmail');
          if (savedEmail != null && savedEmail.isNotEmpty && mounted) {
            _biometricLogin();
          }
        });
      }
    });
    _loadInitialData();
    // Verifica atualização disponível ao abrir o app (foreground)
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    final update = await UpdateService.checkForUpdate();
    if (update != null && mounted) {
      await UpdateService.showUpdateDialog(context, update);
    }
  }

  @override
  void dispose() {
    _unlockAnimController.dispose();
    _unlockFadeController.dispose();
    _txSub?.cancel();
    _catSub?.cancel();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }


  /// Verifica se o dispositivo tem PIN/biometria ativo e bloqueia o app.
  Future<void> _lockIfSecured() async {
    if (kIsWeb || _isGuest || _currentUser == null) return;
    try {
      final auth = LocalAuthentication();
      final supported = await auth.isDeviceSupported();
      if (supported && mounted) {
        setState(() => _isLocked = true);
        // Dispara a biometria automaticamente ao bloquear (estilo app bancário)
        WidgetsBinding.instance.addPostFrameCallback((_) => _unlockApp());
      }
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Sem bloqueio na Web — biometria não se aplica
    if (kIsWeb) return;

    // Ignora mudanças de ciclo causadas pelo próprio diálogo biométrico
    if (_isAuthenticating) return;

    if (state == AppLifecycleState.paused && !_isGuest) {
      setState(() => _isLocked = true);
    }
    // Ao retornar ao foreground com tela bloqueada, dispara biometria
    if (state == AppLifecycleState.resumed && _isLocked && !_isGuest) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _unlockApp());
    }
  }

  Future<void> _unlockApp() async {
    if (!mounted || _isAuthenticating) return;

    bool authenticated = false;

    if (kIsWeb) {
      authenticated = true;
    } else {
      final auth = LocalAuthentication();
      try {
        final isSupported = await auth.isDeviceSupported();
        if (!isSupported) {
          authenticated = true;
        } else {
          setState(() => _isAuthenticating = true);
          authenticated = await auth.authenticate(
            localizedReason: 'Use sua digital ou PIN para acessar o Finanças App',
            options: const AuthenticationOptions(
              stickyAuth: true,
              biometricOnly: false,
            ),
          );
        }
      } catch (_) {
        // Mantém authenticated = false; usuário permanece na tela de bloqueio
        if (mounted) setState(() => _isAuthenticating = false);
        return;
      }
    }

    if (!mounted) return;
    if (authenticated) {
      // Desbloqueia IMEDIATAMENTE para que nenhum evento resumed
      // consiga disparar _unlockApp() uma segunda vez
      _unlockAnimController.reset();
      setState(() {
        _isLocked = false;
        _isAuthenticating = false;
        _showUnlockAnimation = true;
      });
    } else {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  Widget _buildWelcomeBackScreen() {
    final user = _currentUser!;
    final firstName = user.name.trim().split(' ').first;
    final photoUrl = user.photoUrl;
    final initials = user.name
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withAlpha(40),
              border: Border.all(color: primaryColor, width: 2),
              image: photoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(photoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: photoUrl == null
                ? Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: primaryColor,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 24),
          Text(
            'Bem-vindo de volta,',
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            firstName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 32),
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          // ── Fundo escuro com gradiente sutil ──────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0D1117), Color(0xFF111827)],
              ),
            ),
          ),

          // ── Painel modal inferior — oculto durante autenticação ──────────
          if (!_isAuthenticating)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF1C2333),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 32,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 20, 32, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Handle ─────────────────────────────────────────
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Logo ───────────────────────────────────────────
                      SvgPicture.asset(
                        'assets/images/logo.svg',
                        width: 72,
                        height: 72,
                      ),
                      const SizedBox(height: 14),

                      // ── Nome do app ────────────────────────────────────
                      const Text(
                        'Finanças App',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Ícone digital centralizado ─────────────────────
                      GestureDetector(
                        onTap: _unlockApp,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withValues(alpha: 0.12),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            FontAwesomeIcons.fingerprint,
                            color: primaryColor,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Texto principal ────────────────────────────────
                      const Text(
                        'Use sua digital para continuar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // ── Botão Cancelar ─────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _isLocked = false);
                            _signOut();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Dica do sensor ─────────────────────────────────
                      Text(
                        'Toque no sensor de impressão digital',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Cache de Dados ---
  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final userJson = prefs.getString('currentUser');
      if (userJson != null) {
        final userMap = Map<String, dynamic>.from(jsonDecode(userJson));
        _currentUser = User.fromMap(userMap);
      }
    } catch (_) {
      _currentUser = null;
    }

    try {
      final transactionsJson = prefs.getString('transactions');
      if (transactionsJson != null) {
        final transactionsList = List<Map<String, dynamic>>.from(
          jsonDecode(transactionsJson),
        );
        _transactions = transactionsList
            .map((data) => Transaction.fromMap(data))
            .toList();
      }
    } catch (_) {
      _transactions = [];
    }

    try {
      final categoriesJson = prefs.getString('categories');
      if (categoriesJson != null) {
        final categoriesList = List<Map<String, dynamic>>.from(
          jsonDecode(categoriesJson),
        );
        _categories = categoriesList
            .map((data) => Category.fromMap(data))
            .toList();
      }
    } catch (_) {
      _categories = [];
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
    setState(() {
      // Carrega categorias mock apenas em modo de desenvolvimento (debug/mock).
      // Em produção, as categorias vêm do Firestore após o login.
      if (_categories.isEmpty && useMockAuth) {
        _categories = mockCategoriesData
            .map((data) => Category.fromMap(data))
            .toList();
      }
      _isLoading = false;
    });
  }

  Future<void> _signInWithGoogle() async {
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        setState(() {
          _currentUser = user;
          _selectedIndex = 0;
        });
        _saveCachedData();
        await _postLoginSetup(user);
        _showWelcomeDialog(user);
      }
    } catch (error) {
      _showErrorSnackBar('Erro ao entrar com Google: $error');
    }
  }

  // --- Login com email/senha ---
  Future<void> _emailLogin({
    required String email,
    required String password,
    required BuildContext loginContext,
  }) async {
    try {
      final user = await _authService.signIn(email: email, password: password);
      if (user != null) {
        // Salva email para biometria
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('biometricUserEmail', user.email);
        setState(() {
          _currentUser = user;
          _selectedIndex = 0;
        });
        _saveCachedData();
        await _postLoginSetup(user);
        _showWelcomeDialog(user);
      }
    } catch (e) {
      showCenteredAlertModal(
        context: loginContext,
        title: 'Erro ao entrar',
        message: e.toString().replaceFirst('Exception: ', ''),
        icon: FontAwesomeIcons.circleExclamation,
        iconColor: expenseColor,
      );
    }
  }

  // --- Cadastro com email/senha e auto-login ---
  Future<void> _emailSignUp({
    required String name,
    required String email,
    required String password,
    required BuildContext signUpContext,
  }) async {
    try {
      final user = await _authService.signUp(
        name: name,
        email: email,
        password: password,
      );
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('biometricUserEmail', user.email);
        setState(() {
          _currentUser = user;
          _selectedIndex = 0;
        });
        _saveCachedData();
        await _postLoginSetup(user);
        // Fecha a tela de cadastro e mostra boas-vindas
        if (Navigator.canPop(signUpContext)) {
          Navigator.of(signUpContext).pop();
        }
        _showWelcomeDialog(user);
      }
    } catch (e) {
      showCenteredAlertModal(
        context: signUpContext,
        title: 'Erro no cadastro',
        message: e.toString().replaceFirst('Exception: ', ''),
        icon: FontAwesomeIcons.circleExclamation,
        iconColor: expenseColor,
      );
    }
  }

  Future<void> _biometricLogin() async {
    final auth = LocalAuthentication();
    try {
      final canCheck = await auth.canCheckBiometrics;
      final isDeviceSupported = await auth.isDeviceSupported();

      if (!canCheck && !isDeviceSupported) return;

      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('biometricUserEmail');
      if (savedEmail == null || savedEmail.isEmpty) return;

      bool authenticated = false;
      try {
        authenticated = await auth.authenticate(
          localizedReason: 'Confirme sua identidade para acessar o app',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false, // permite digital, face ou PIN do dispositivo
          ),
        );
      } catch (_) {
        return; // dispositivo sem biometria configurada — silencia o erro
      }

      if (!authenticated) return;

      try {
        final user = await _authService.signInWithBiometric(savedEmail);
        if (user != null && mounted) {
          setState(() {
            _currentUser = user;
            _selectedIndex = 0;
          });
          _saveCachedData();
          await _postLoginSetup(user);
          _showWelcomeDialog(user);
        }
      } catch (_) {
        // Sessão Firebase expirada — limpa o email salvo para não tentar de novo
        // e deixa o usuário fazer login manualmente
        await prefs.remove('biometricUserEmail');
      }
    } catch (_) {
      // Falha silenciosa: não interrompe o fluxo de login
    }
  }

  Future<void> _signOut() async {
    try {
      // Cancela streams antes de sair
      await _txSub?.cancel();
      await _catSub?.cancel();
      _txSub = null;
      _catSub = null;

      await _authService.signOut();
      setState(() {
        _currentUser = null;
        _dataOwnerUid = null;
        _collaborators = [];
        _invitations = [];
        _transactions = [];
        _categories = [];
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
    if (!useMockAuth && _activeUid != null) {
      await _firestoreService.updateSalary(_activeUid!, updatedUser.salary);
    }
  }

  // --- Integração Firebase: carregar dados do Firestore em tempo real ---

  /// Assina os streams do Firestore para o UID informado.
  /// Qualquer alteração no servidor é refletida automaticamente na UI.
  Future<void> _loadFirestoreData(String uid) async {
    if (useMockAuth) return;

    // Cancela subscriptions anteriores (ex: troca de conta / logout)
    await _txSub?.cancel();
    await _catSub?.cancel();

    // ── Sincroniza transações locais → Firebase se Firebase estiver vazio ──
    // Evita que o stream vazio do Firestore apague dados salvos no device.
    // Usa try-catch para que uma falha no sync não bloqueie a inicialização dos streams.
    try {
      final hasFirebaseData = await _firestoreService.hasExistingTransactions(
        uid,
      );
      if (!hasFirebaseData && _transactions.isNotEmpty) {
        await _syncToFirebase();
      }
    } catch (_) {
      // Falha no auto-sync: ignora e continua para iniciar os streams normalmente.
    }

    // Garante categorias padrão para contas novas (operação única)
    try {
      await _firestoreService.seedDefaultCategories(uid);
    } catch (_) {}

    // Migra ícones de categorias existentes para os nomes corretos
    try {
      await _firestoreService.migrateDefaultCategoryIcons(uid);
    } catch (_) {}

    // ── Categorias ────────────────────────────────────────────────────
    _catSub = _firestoreService.categoriesAppStream(uid).listen(
      (rawList) {
        if (!mounted) return;
        try {
          final cats = rawList.map((m) => Category.fromMap(m)).toList();
          setState(() {
            if (cats.isNotEmpty) _categories = cats;
          });
        } catch (_) {} // mantém dados do cache em caso de erro de parsing
      },
      onError: (_) {}, // mantém dados do cache em caso de erro de stream
    );

    // ── Transações ────────────────────────────────────────────────────
    _txSub = _firestoreService.transactionsAppStream(uid).listen(
      (rawList) {
        if (!mounted) return;
        try {
          final txs = rawList.map((m) => Transaction.fromMap(m)).toList();
          setState(() => _transactions = txs);
          _saveCachedData(); // mantém cache local sempre atualizado
        } catch (_) {} // mantém dados do cache em caso de erro de parsing
      },
      onError: (_) {}, // mantém dados do cache em caso de erro de stream
    );
  }

  /// Executado após qualquer login/cadastro bem-sucedido.
  /// Verifica se o usuário é colaborador de alguém e carrega os dados corretos.
  Future<void> _postLoginSetup(User user) async {
    if (useMockAuth) return;
    try {
      // 1. Verifica se este email foi convidado por algum owner
      final ownerInfo = await _firestoreService.findOwnerByCollaboratorEmail(
        user.email,
      );

      if (ownerInfo != null) {
        // Usuário é colaborador — carrega dados do dono
        final ownerUid = ownerInfo['ownerUid'] as String;
        final role = ownerInfo['role'] as String;

        setState(() {
          _dataOwnerUid = ownerUid;
          // Atualiza role do usuário para refletir permissões corretas
          _currentUser = User(
            id: user.id,
            email: user.email,
            name: user.name,
            photoUrl: user.photoUrl,
            role: role,
            salary: user.salary,
          );
        });
        await _loadFirestoreData(ownerUid);

        // Carrega lista de colaboradores do owner para a UI
        final collabMaps = await _firestoreService.getCollaborators(ownerUid);
        setState(() {
          _collaborators = collabMaps
              .map(
                (m) => User(
                  id: m['email'] as String,
                  email: m['email'] as String,
                  name: m['email'] as String,
                  role: m['role'] as String,
                ),
              )
              .toList();
        });
      } else {
        // Usuário é owner — carrega os próprios dados
        setState(() => _dataOwnerUid = null);
        await _loadFirestoreData(user.id);

        // Carrega lista de colaboradores do próprio owner
        final collabMaps = await _firestoreService.getCollaborators(user.id);
        setState(() {
          _collaborators = collabMaps
              .map(
                (m) => User(
                  id: m['email'] as String,
                  email: m['email'] as String,
                  name: m['email'] as String,
                  role: m['role'] as String,
                ),
              )
              .toList();
        });
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[postLoginSetup] erro ao verificar colaboração: $e');
      }
      // Falha na verificação de colaboração — continua como owner normal
      setState(() => _dataOwnerUid = null);
      await _loadFirestoreData(user.id);
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
                final emailRegex = RegExp(
                  r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
                );
                if (!emailRegex.hasMatch(emailController.text.trim())) {
                  _showErrorSnackBar(
                    'Email inválido. Use o formato: usuario@exemplo.com',
                  );
                  return;
                }
                _sendInvitation(emailController.text.trim(), selectedRole);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendInvitation(String email, String role) async {
    // 1. Criar o convite no estado local
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

    // 2. Persiste o colaborador no Firestore (owner sempre usa o próprio uid)
    if (!useMockAuth && _currentUser != null) {
      try {
        final ownerUid = _dataOwnerUid ?? _currentUser!.id;
        await _firestoreService.addCollaborator(ownerUid, email, role);
        // Atualiza lista local de colaboradores
        setState(() {
          if (!_collaborators.any((c) => c.email == email)) {
            _collaborators.add(
              User(id: email, email: email, name: email, role: role),
            );
          }
        });
      } catch (_) {}
    }

    // 3. Preparar e enviar o e-mail usando url_launcher
    // Nota: mailto: só suporta texto simples — HTML aparece como código bruto.
    final subject = 'Convite para colaborar no Finanças App 💰';

    final senderName = _currentUser?.name ?? 'um usuário';
    final roleLabel = role == 'collaborator'
        ? 'Colaborador'
        : role == 'viewer'
        ? 'Visualizador'
        : 'Proprietário';

    final body =
        '''Olá! 👋

Você recebeu um convite para colaborar no Finanças App.

━━━━━━━━━━━━━━━━━━━━━━━━
  💼 CONVITE PARA COLABORAR
━━━━━━━━━━━━━━━━━━━━━━━━

$senderName te convidou para fazer parte do painel financeiro dele no Finanças App.

📋 Sua função: $roleLabel

Para aceitar o convite:
1. Baixe o Finanças App
2. Crie sua conta com este e-mail
3. Você será adicionado automaticamente

🔗 Repositório do projeto:
https://github.com/tiagoadv7/appfinancas

━━━━━━━━━━━━━━━━━━━━━━━━

Se você não esperava este convite, pode ignorar este e-mail.

Finanças App — Controle suas finanças com simplicidade.
''';

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': subject, 'body': body},
    );

    final launched = await launchUrl(emailLaunchUri);
    if (!launched) {
      _showErrorSnackBar('Não foi possível abrir o app de e-mail.');
    } else {
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
                final collab = _collaborators.firstWhere(
                  (u) => u.id == userId,
                  orElse: () => User(
                    id: userId,
                    email: userId,
                    name: userId,
                    role: 'collaborator',
                  ),
                );
                setState(() {
                  _collaborators.removeWhere((u) => u.id == userId);
                });
                // Remove do Firestore
                if (!useMockAuth && _currentUser != null) {
                  final ownerUid = _dataOwnerUid ?? _currentUser!.id;
                  _firestoreService.removeCollaborator(
                    ownerUid,
                    collab.email,
                    collab.role,
                  );
                }
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
    final baseId = transaction.id.contains('@')
        ? transaction.id.substring(0, transaction.id.indexOf('@'))
        : transaction.id;
    Map<String, dynamic>? updatedMap;
    setState(() {
      // IDs virtuais de recorrentes usam 'baseId@monthKey'; resolve o base
      final index = _transactions.indexWhere((t) => t.id == baseId);
      if (index != -1) {
        final stored = _transactions[index];
        final map = transaction.toMap();
        map['id'] = baseId; // restaura ID base
        map['paidByMonth'] = stored.paidByMonth; // preserva status por mês
        _transactions[index] = Transaction.fromMap(map);
        updatedMap = map;
      }
    });
    _saveCachedData();
    // Persiste atualização no Firestore
    if (!useMockAuth && _activeUid != null && updatedMap != null) {
      _firestoreService.saveTransactionRaw(_activeUid!, baseId, updatedMap!);
    }
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
    if (!useMockAuth && _activeUid != null) {
      // Firestore usa 'icon', main.dart usa 'iconName' — mapeia corretamente
      _firestoreService.saveCategoryRaw(_activeUid!, category.id, {
        'name': category.name,
        'type': category.type,
        'icon': category.iconName,
        'isDefault': false,
      });
    }
  }

  void _deleteCategory(String id) {
    setState(() {
      _categories.removeWhere((c) => c.id == id);
    });
    _saveCachedData();
    if (!useMockAuth && _activeUid != null) {
      _firestoreService.deleteCategory(_activeUid!, id);
    }
  }

  Future<bool> _checkExistingFirebaseData() async {
    if (_activeUid == null || useMockAuth) return false;
    return _firestoreService.hasExistingTransactions(_activeUid!);
  }

  Future<void> _syncToFirebase() async {
    if (_activeUid == null || useMockAuth) return;
    final uid = _activeUid!;
    for (final tx in _transactions) {
      await _firestoreService.saveTransactionRaw(uid, tx.id, tx.toMap());
    }
    for (final cat in _categories) {
      await _firestoreService.saveCategoryRaw(uid, cat.id, cat.toMap());
    }
  }

  void _togglePaidStatus(String transactionId, bool isPaid) {
    final baseId = transactionId.contains('@')
        ? transactionId.substring(0, transactionId.indexOf('@'))
        : transactionId;
    Transaction? updated;
    setState(() {
      // IDs de recorrentes virtuais usam formato 'baseId@yyyy-MM'
      if (transactionId.contains('@')) {
        final sep = transactionId.indexOf('@');
        final monthKey = transactionId.substring(sep + 1);
        final index = _transactions.indexWhere((t) => t.id == baseId);
        if (index != -1) {
          final t = _transactions[index];
          final paidMap = Map<String, bool>.from(t.paidByMonth);
          paidMap[monthKey] = isPaid;
          updated = t.copyWith(paidByMonth: paidMap);
          // Nova referência de lista para que didUpdateWidget detecte a mudança
          _transactions = List<Transaction>.from(_transactions);
          _transactions[index] = updated!;
        }
      } else {
        final index = _transactions.indexWhere((t) => t.id == baseId);
        if (index != -1) {
          updated = _transactions[index].copyWith(isPaid: isPaid);
          _transactions = List<Transaction>.from(_transactions);
          _transactions[index] = updated!;
        }
      }
    });
    _saveCachedData();
    if (!useMockAuth && _activeUid != null && updated != null) {
      _firestoreService.saveTransactionRaw(
        _activeUid!,
        baseId,
        updated!.toMap(),
      );
    }
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

  /// UID a usar nas operações Firestore: owner do dados (pode ser outro user).
  String? get _activeUid => _dataOwnerUid ?? _currentUser?.id;

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
        'iconName': 'Cifrão',
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
    final baseTs = DateTime.now().millisecondsSinceEpoch;
    final newId = transaction.isRecurring ? 'r$baseTs' : 't$baseTs';
    final txMap = {
      'id': newId,
      'description': transaction.description,
      'amount': transaction.amount,
      'categoryId': transaction.categoryId,
      'date': transaction.date.toIso8601String().substring(0, 10),
      'isPaid': transaction.isPaid,
      'comments': transaction.comments,
      'isRecurring': transaction.isRecurring,
      'recurringStartMonth': transaction.recurringStartMonth,
      'recurringEndMonth': transaction.recurringEndMonth,
      'paidByMonth': <String, bool>{},
    };
    // Armazena UMA transação base; a expansão por mês é feita na exibição
    setState(() {
      _transactions = List<Transaction>.from(_transactions)
        ..add(Transaction.fromMap(txMap));
      _selectedIndex = 1;
      if (transaction.isRecurring && transaction.recurringStartMonth != null) {
        _extractFocusDate = DateTime.parse(
          '${transaction.recurringStartMonth}-01',
        );
      }
    });

    _saveCachedData();

    // Persiste no Firestore (fire-and-forget)
    if (!useMockAuth && _activeUid != null) {
      _firestoreService.saveTransactionRaw(_activeUid!, newId, txMap);
    }

    Navigator.of(context).pop();
  }

  void _deleteTransaction(String id) {
    // Apenas owner e collaborator podem deletar
    if (!_isAdmin && !_isCollaborator) return;

    final isVirtual = id.contains('@');
    final baseId = isVirtual ? id.substring(0, id.indexOf('@')) : id;
    final monthKey = isVirtual ? id.substring(id.indexOf('@') + 1) : null;

    // Se for recorrente virtual, mostra 3 opções de exclusão
    if (isVirtual && monthKey != null) {
      _showRecurringDeleteDialog(baseId, monthKey);
      return;
    }

    // Transação normal: dialog de confirmação padrão
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
              const Text(
                'Confirmar Exclusão',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Tem certeza que deseja deletar esta transação? Esta ação não pode ser desfeita.',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
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
                          _transactions.removeWhere((t) => t.id == baseId);
                        });
                        _saveCachedData();
                        if (!useMockAuth && _activeUid != null) {
                          _firestoreService.deleteTransaction(
                            _activeUid!,
                            baseId,
                          );
                        }
                        Navigator.of(context).pop();
                        _showDeleteSuccessDialog();
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

  /// Calcula o mês anterior no formato 'yyyy-MM'
  String _previousMonth(String monthKey) {
    final parts = monthKey.split('-');
    var year = int.parse(parts[0]);
    var month = int.parse(parts[1]);
    month -= 1;
    if (month == 0) {
      month = 12;
      year -= 1;
    }
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  void _showRecurringDeleteDialog(String baseId, String monthKey) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Theme.of(ctx).cardColor,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 24,
            horizontal: 24,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const SizedBox(height: 20),
              const Text(
                'Excluir Recorrência',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'O que deseja excluir desta transação recorrente?',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Opção 1: Somente este mês
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    final idx = _transactions.indexWhere((t) => t.id == baseId);
                    if (idx != -1) {
                      final t = _transactions[idx];
                      final updated = t.copyWith(
                        deletedMonths: [...t.deletedMonths, monthKey],
                      );
                      setState(() => _transactions[idx] = updated);
                      _saveCachedData();
                      if (!useMockAuth && _activeUid != null) {
                        _firestoreService.saveTransactionRaw(
                          _activeUid!,
                          baseId,
                          updated.toMap(),
                        );
                      }
                    }
                    Navigator.of(ctx).pop();
                    _showDeleteSuccessDialog();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Somente este mês'),
                ),
              ),
              const SizedBox(height: 10),
              // Opção 2: Este e os seguintes
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    final idx = _transactions.indexWhere((t) => t.id == baseId);
                    if (idx != -1) {
                      final t = _transactions[idx];
                      final prevMonth = _previousMonth(monthKey);
                      // Se o mês atual é o mês inicial, exclui tudo
                      if (prevMonth == _previousMonth(t.recurringStartMonth ?? monthKey) ||
                          monthKey == t.recurringStartMonth) {
                        setState(() => _transactions.removeAt(idx));
                        _saveCachedData();
                        if (!useMockAuth && _activeUid != null) {
                          _firestoreService.deleteTransaction(
                            _activeUid!,
                            baseId,
                          );
                        }
                      } else {
                        final updated = t.copyWith(
                          recurringEndMonth: prevMonth,
                        );
                        setState(() => _transactions[idx] = updated);
                        _saveCachedData();
                        if (!useMockAuth && _activeUid != null) {
                          _firestoreService.saveTransactionRaw(
                            _activeUid!,
                            baseId,
                            updated.toMap(),
                          );
                        }
                      }
                    }
                    Navigator.of(ctx).pop();
                    _showDeleteSuccessDialog();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Este e os seguintes'),
                ),
              ),
              const SizedBox(height: 10),
              // Opção 3: Todos
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(FontAwesomeIcons.trash, size: 14),
                  label: const Text('Todos'),
                  onPressed: () {
                    setState(() {
                      _transactions.removeWhere((t) => t.id == baseId);
                    });
                    _saveCachedData();
                    if (!useMockAuth && _activeUid != null) {
                      _firestoreService.deleteTransaction(_activeUid!, baseId);
                    }
                    Navigator.of(ctx).pop();
                    _showDeleteSuccessDialog();
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
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (ctx.mounted && Navigator.canPop(ctx)) Navigator.of(ctx).pop();
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
                    color: expenseColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(
                    child: Icon(
                      FontAwesomeIcons.trash,
                      color: expenseColor,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Dados excluídos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'A transação foi excluída com sucesso.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
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
    double paidIncome = 0;
    double paidExpense = 0;
    double totalIncome = 0;
    double totalExpense = 0;

    for (var t in _transactions) {
      bool matchesMonth;
      if (t.isRecurring &&
          t.recurringStartMonth != null &&
          t.recurringEndMonth != null) {
        final start = DateTime.parse('${t.recurringStartMonth}-01');
        final end = DateTime.parse('${t.recurringEndMonth}-01');
        final selected = DateTime(month.year, month.month);
        matchesMonth = !selected.isBefore(start) && !selected.isAfter(end);
      } else {
        matchesMonth = t.date.year == month.year && t.date.month == month.month;
      }
      if (!matchesMonth) continue;

      final monthKey =
          '${month.year}-${month.month.toString().padLeft(2, '0')}';
      if (t.isRecurring && t.deletedMonths.contains(monthKey)) continue;
      final isPaidForMonth = t.isRecurring
          ? (t.paidByMonth[monthKey] ?? false)
          : t.isPaid;

      final category = _getCategoryById(t.categoryId);
      if (category.type == 'income') {
        totalIncome += t.amount;
        if (isPaidForMonth) paidIncome += t.amount;
      } else {
        totalExpense += t.amount;
        if (isPaidForMonth) paidExpense += t.amount;
      }
    }
    return {
      'paidIncome': paidIncome,
      'paidExpense': paidExpense,
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'balance': paidIncome - paidExpense,
      'previsto': totalIncome - totalExpense,
      'pendingIncome': totalIncome - paidIncome,
      'pendingExpense': totalExpense - paidExpense,
      // Chaves legadas para compatibilidade
      'income': paidIncome,
      'expense': paidExpense,
    };
  }

  // --- Widgets de Tela ---

  // --- Tela de Acesso Negado (Guest) ---
  Widget _buildGuestScreen() {
    final emailController = _loginEmailController;
    final passwordController = _loginPasswordController;

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

              // Banner DEV — visível apenas em debug
              if (kDebugMode) ...[
                GestureDetector(
                  onTap: () {
                    emailController.text = devTestEmail;
                    passwordController.text = devTestPassword;
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF89DCEB),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              FontAwesomeIcons.codeBranch,
                              size: 13,
                              color: Color(0xFF89DCEB),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'AMBIENTE DE DESENVOLVIMENTO',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF89DCEB),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _DevCredentialRow(label: 'E-mail', value: devTestEmail),
                        const SizedBox(height: 4),
                        _DevCredentialRow(
                          label: 'Senha',
                          value: devTestPassword,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: const [
                            Icon(
                              FontAwesomeIcons.handPointer,
                              size: 11,
                              color: Color(0xFFCDD6F4),
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Toque para preencher',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFCDD6F4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],

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
                    obscureText: _loginObscure,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(FontAwesomeIcons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _loginObscure
                              ? FontAwesomeIcons.eyeSlash
                              : FontAwesomeIcons.eye,
                          size: 18,
                        ),
                        onPressed: () =>
                            setState(() => _loginObscure = !_loginObscure),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Link "Esqueceu a senha?"
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                Scaffold(body: _buildForgotPasswordScreen()),
                          ),
                        );
                      },
                      child: const Text(
                        'Esqueceu a senha?',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Botão Entrar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (emailController.text.isNotEmpty &&
                            passwordController.text.isNotEmpty) {
                          _emailLogin(
                            email: emailController.text.trim(),
                            password: passwordController.text,
                            loginContext: context,
                          );
                        } else {
                          showCenteredAlertModal(
                            context: context,
                            title: 'Campos Vazios',
                            message: 'Preencha e-mail e senha',
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
                  onPressed: _signInWithGoogle,
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
                    obscureText: _signupObscure,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(FontAwesomeIcons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _signupObscure
                              ? FontAwesomeIcons.eyeSlash
                              : FontAwesomeIcons.eye,
                          size: 18,
                        ),
                        onPressed: () =>
                            setState(() => _signupObscure = !_signupObscure),
                      ),
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
                    obscureText: _signupConfirmObscure,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Senha',
                      prefixIcon: const Icon(FontAwesomeIcons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _signupConfirmObscure
                              ? FontAwesomeIcons.eyeSlash
                              : FontAwesomeIcons.eye,
                          size: 18,
                        ),
                        onPressed: () => setState(
                          () => _signupConfirmObscure = !_signupConfirmObscure,
                        ),
                      ),
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

                        // Chama cadastro real com auto-login
                        _emailSignUp(
                          name: nameController.text.trim(),
                          email: emailController.text.trim(),
                          password: passwordController.text,
                          signUpContext: context,
                        );
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

  // --- Tela de Redefinição de Senha ---
  Widget _buildForgotPasswordScreen() {
    final emailController = TextEditingController();

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                      'Redefinir Senha',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                'Informe seu e-mail cadastrado. Enviaremos um link para redefinir sua senha.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 30),

              // E-mail
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'E-mail cadastrado',
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

              const SizedBox(height: 28),

              // Botão Enviar
              ElevatedButton.icon(
                onPressed: () async {
                  final email = emailController.text.trim();
                  final ctx = context;
                  final nav = Navigator.of(context);

                  if (email.isEmpty || !email.contains('@')) {
                    showCenteredAlertModal(
                      context: ctx,
                      title: 'Erro',
                      message: 'Informe um e-mail válido',
                      icon: FontAwesomeIcons.circleExclamation,
                      iconColor: expenseColor,
                    );
                    return;
                  }

                  try {
                    await _authService.resetPassword(email: email);

                    if (!mounted) return;

                    showCenteredAlertModal(
                      context: context,
                      title: 'E-mail enviado!',
                      message:
                          'Verifique sua caixa de entrada e clique no link para redefinir sua senha.',
                      icon: FontAwesomeIcons.circleCheck,
                      iconColor: successColor,
                    );
                    Future.delayed(const Duration(milliseconds: 2600), () {
                      if (mounted) nav.pop();
                    });
                  } catch (e) {
                    if (!mounted) return;
                    showCenteredAlertModal(
                      context: ctx,
                      title: 'Erro',
                      message: e.toString().replaceFirst('Exception: ', ''),
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
                icon: const Icon(FontAwesomeIcons.paperPlane),
                label: const Text(
                  'Enviar link de redefinição',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(FontAwesomeIcons.arrowLeft, size: 14),
                  label: const Text(
                    'Voltar ao login',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),

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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewTransactionForm(
          categories: _categories,
          addTransaction: _addTransaction,
          updateTransaction: _updateTransaction,
          transactionToEdit: transactionToEdit,
          defaultFilterType: defaultFilterType,
          userSalary: _currentUser?.salary ?? 0.0,
          onCategoryAdded: (Category cat) {
            _categories.add(cat);
            setState(() {});
            _saveCachedData();
          },
        ),
      ),
    );
  }

  // --- Widget Principal ---
  @override
  Widget build(BuildContext context) {
    // Animação de desbloqueio — exibida após biometria verificada
    if (_showUnlockAnimation) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: FadeTransition(
          opacity: ReverseAnimation(
            CurvedAnimation(
              parent: _unlockFadeController,
              curve: Curves.easeOut,
            ),
          ),
          child: Center(
            child: Lottie.asset(
              'assets/animations/unlock.json',
              controller: _unlockAnimController,
              width: 220,
              height: 220,
              repeat: false,
              onLoaded: (composition) {
                _unlockAnimController
                  ..duration = composition.duration
                  ..forward().whenComplete(() async {
                    if (!mounted) return;
                    await _unlockFadeController.forward();
                    if (mounted) {
                      setState(() {
                        _showUnlockAnimation = false;
                        _unlockFadeController.reset();
                      });
                    }
                  });
              },
            ),
          ),
        ),
      );
    }

    // Tela de bloqueio — exibida quando o app volta do segundo plano
    if (_isLocked && !_isGuest) return _buildLockScreen();

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
          ? _currentUser != null
                ? _buildWelcomeBackScreen()
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppLogo(width: 80, height: 80, fit: BoxFit.contain),
                        const SizedBox(height: 24),
                        const CircularProgressIndicator(color: primaryColor),
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
                  padding: const EdgeInsets.all(16.0),
                  child: DashboardScreen(
                    summary: _calculateSummaryForMonth(_dashboardSelectedMonth),
                    selectedMonth: _dashboardSelectedMonth,
                    onMonthChanged: _updateDashboardMonth,
                    onNavigateToExtract: (filterType) => setState(() {
                      _extractFilterType = filterType;
                      _selectedIndex = 1;
                    }),
                  ),
                ),
                // Aba 1: Extrato
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TransactionsScreen(
                    transactions: _transactions,
                    filterType: _extractFilterType,
                    getCategoryById: _getCategoryById,
                    deleteTransaction: _deleteTransaction,
                    editTransaction: _showNewTransactionModal,
                    canEdit: _isAdmin || _isCollaborator,
                    onDateChanged: _updateDashboardMonth,
                    onPaidStatusChanged: _togglePaidStatus,
                    focusDate: _extractFocusDate,
                    onFilterChanged: (f) =>
                        setState(() => _extractFilterType = f),
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
                  onSyncToFirebase: _syncToFirebase,
                  onCheckExistingData: _checkExistingFirebaseData,
                  transactions: _transactions,
                  selectedMonth: _dashboardSelectedMonth,
                  getCategoryById: _getCategoryById,
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
                  ? const Color.fromARGB(255, 0, 52, 78) // Cor para tema claro
                  : const Color(0xFF001F3F), // Cor para tema escuro
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
              onPressed: () {
                final filterType = _extractFilterType == 'all'
                    ? null
                    : _extractFilterType;
                _showNewTransactionModal(null, filterType);
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

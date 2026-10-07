import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Uma conta (ou recebimento) pendente que deve gerar lembrete.
class BillReminder {
  /// ID da ocorrência — o mesmo usado no extrato ('baseId' ou
  /// 'baseId@yyyy-MM' para recorrentes). Volta no toque da notificação.
  final String occurrenceId;
  final String description;

  /// Valor já formatado (ex: 'R$ 1.200,00').
  final String amountLabel;
  final DateTime dueDate;
  final bool isIncome;

  const BillReminder({
    required this.occurrenceId,
    required this.description,
    required this.amountLabel,
    required this.dueDate,
    required this.isIncome,
  });
}

/// Lembretes locais de contas a pagar/receber — notificações agendadas no
/// próprio aparelho, que aparecem mesmo com o app fechado.
class ReminderService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'bill_reminders';
  static const String _channelName = 'Lembretes de contas';

  /// Horário em que os lembretes aparecem.
  static const int reminderHour = 9;

  /// Quantos dias à frente são agendados (reagendado a cada mudança).
  static const int horizonDays = 45;

  /// Margem abaixo do limite de ~500 alarmes de alguns Android (Samsung).
  static const int _maxScheduled = 300;

  static bool _initialized = false;
  static bool _permissionRequested = false;

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Inicializa o plugin e o fuso horário. [onTap] recebe o occurrenceId
  /// quando o usuário toca numa notificação com o app aberto/em segundo plano.
  /// Retorna o occurrenceId se o app foi ABERTO pelo toque numa notificação.
  static Future<String?> init({
    required void Function(String occurrenceId) onTap,
  }) async {
    if (!isSupported || _initialized) return null;

    tzdata.initializeTimeZones();
    try {
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) onTap(payload);
      },
    );
    _initialized = true;

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      final payload = launch!.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) return payload;
    }
    return null;
  }

  /// Pede a permissão de notificações (Android 13+) uma vez por sessão.
  static Future<void> _ensurePermission() async {
    if (_permissionRequested) return;
    _permissionRequested = true;
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  /// Substitui todos os lembretes agendados pelos de [items]:
  /// um na véspera e outro no dia do vencimento, às [reminderHour]h.
  static Future<void> reschedule(List<BillReminder> items) async {
    if (!isSupported || !_initialized) return;

    await _plugin.cancelAll();
    if (items.isEmpty) return;
    await _ensurePermission();

    final now = tz.TZDateTime.now(tz.local);
    final limit = now.add(const Duration(days: horizonDays));
    final pending = <({BillReminder item, tz.TZDateTime when, bool dayBefore})>[];

    for (final item in items) {
      final due = tz.TZDateTime(
        tz.local,
        item.dueDate.year,
        item.dueDate.month,
        item.dueDate.day,
        reminderHour,
      );
      final dayBefore = due.subtract(const Duration(days: 1));
      if (dayBefore.isAfter(now) && dayBefore.isBefore(limit)) {
        pending.add((item: item, when: dayBefore, dayBefore: true));
      }
      if (due.isAfter(now) && due.isBefore(limit)) {
        pending.add((item: item, when: due, dayBefore: false));
      }
    }

    pending.sort((a, b) => a.when.compareTo(b.when));

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription:
            'Avisos de contas a pagar e a receber perto do vencimento',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      ),
    );

    for (final p in pending.take(_maxScheduled)) {
      final item = p.item;
      final when = p.dayBefore ? 'amanhã' : 'hoje';
      final title = item.isIncome
          ? '💰 ${item.description} — receber $when'
          : '💸 ${item.description} vence $when';
      final body = item.isIncome
          ? '${item.amountLabel} a receber. Toque para ver ou marcar como recebido.'
          : '${item.amountLabel} a pagar. Toque para ver ou marcar como pago.';

      await _plugin.zonedSchedule(
        id: _notificationId(item.occurrenceId, p.dayBefore),
        scheduledDate: p.when,
        notificationDetails: details,
        // Inexato: dispensa a permissão de alarme exato; o Android pode
        // atrasar alguns minutos, o que é aceitável para um lembrete.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
        payload: item.occurrenceId,
      );
    }
  }

  /// ID estável por ocorrência + tipo de aviso (véspera/dia).
  static int _notificationId(String occurrenceId, bool dayBefore) {
    // FNV-1a 31 bits — estável entre execuções (String.hashCode não é)
    var hash = 0x811c9dc5;
    for (final unit in '$occurrenceId|${dayBefore ? 1 : 0}'.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}

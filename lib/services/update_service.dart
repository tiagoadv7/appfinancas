import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class UpdateService {
  static const String _repoOwner = 'tiagoadv7';
  static const String _repoName = 'appfinancas';
  static const String _lastCheckKey = 'last_update_check';
  static const String bgTaskId = 'update_check_task';
  static const String bgTaskName = 'checkForUpdate';

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Inicializa o plugin de notificações locais.
  /// Deve ser chamado em main() antes de runApp().
  static Future<void> initNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notifications.initialize(settings);
  }

  /// Consulta o GitHub e retorna os dados da nova versão, ou null se já está atualizado.
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest',
            ),
            headers: {'Accept': 'application/vnd.github.v3+json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = (data['tag_name'] as String? ?? '').replaceFirst('v', '');
      final releaseUrl = data['html_url'] as String? ?? '';
      final releaseNotes = data['body'] as String? ?? '';

      if (tagName.isEmpty) return null;

      final packageInfo = await PackageInfo.fromPlatform();
      if (_isNewer(tagName, packageInfo.version)) {
        return UpdateInfo(
          version: tagName,
          url: releaseUrl,
          notes: releaseNotes,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Tarefa executada pelo WorkManager em background toda noite.
  static Future<void> runBackgroundCheck() async {
    await initNotifications();
    final update = await checkForUpdate();
    if (update != null) {
      await _showNotification(update.version);
    }
    await _saveLastCheckTime();
  }

  /// Exibe o diálogo de atualização na tela (foreground).
  static Future<void> showUpdateDialog(
    BuildContext context,
    UpdateInfo update,
  ) async {
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.system_update_rounded, color: Color(0xFF00B7FF)),
            SizedBox(width: 8),
            Text('Nova versão disponível'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Finanças App ${update.version} está disponível!',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (update.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                update.notes,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Mais tarde'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final uri = Uri.parse(update.url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers internos
  // ──────────────────────────────────────────────────────────────────────────

  static Future<void> _showNotification(String version) async {
    const androidDetails = AndroidNotificationDetails(
      'financas_update_channel',
      'Atualizações do App',
      channelDescription: 'Notificações de novas versões do Finanças App',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(
      0,
      'Finanças App — Atualização disponível',
      'Versão $version disponível. Toque para baixar.',
      details,
    );
  }

  static bool _isNewer(String remote, String current) {
    final r = remote.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final c = current.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    for (int i = 0; i < 3; i++) {
      final rv = i < r.length ? r[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (rv > cv) return true;
      if (rv < cv) return false;
    }
    return false;
  }

  static Future<void> _saveLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastCheckKey, DateTime.now().toIso8601String());
  }

  /// Calcula o delay até as 02:00 da madrugada (horário local).
  static Duration delayUntilNight() {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, 2, 0);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    return next.difference(now);
  }
}

class UpdateInfo {
  final String version;
  final String url;
  final String notes;

  const UpdateInfo({
    required this.version,
    required this.url,
    required this.notes,
  });
}

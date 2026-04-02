import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const String _repoOwner = 'tiagoadv7';
  static const String _repoName = 'appfinancas';
  static const String _branch = 'main';
  static const String _lastCheckKey = 'last_update_check';

  /// URL do version.json no repositório GitHub (raw content).
  static String get _versionUrl =>
      'https://raw.githubusercontent.com/$_repoOwner/$_repoName/$_branch/version.json';

  /// Consulta o version.json do repositório e retorna dados da nova versão,
  /// ou null se já está atualizado ou checagem foi há menos de 20 horas.
  static Future<UpdateInfo?> checkForUpdate() async {
    if (!await _shouldCheck()) return null;

    try {
      final response = await http
          .get(Uri.parse(_versionUrl))
          .timeout(const Duration(seconds: 10));

      await _saveLastCheckTime();

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final remoteVersion = data['version'] as String? ?? '';
      final releaseUrl = data['url'] as String? ?? '';
      final releaseNotes = data['notes'] as String? ?? '';

      if (remoteVersion.isEmpty) return null;

      final packageInfo = await PackageInfo.fromPlatform();
      if (_isNewer(remoteVersion, packageInfo.version)) {
        return UpdateInfo(
          version: remoteVersion,
          url: releaseUrl,
          notes: releaseNotes,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Exibe o diálogo de atualização na tela.
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

  static Future<bool> _shouldCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastCheckKey);
    if (raw == null) return true;
    final last = DateTime.tryParse(raw);
    if (last == null) return true;
    return DateTime.now().difference(last).inHours >= 20;
  }

  static Future<void> _saveLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastCheckKey, DateTime.now().toIso8601String());
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

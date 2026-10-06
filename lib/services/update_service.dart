import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Resultado de uma checagem de atualização.
enum UpdateCheckStatus { upToDate, updateAvailable, error }

class UpdateCheckResult {
  final UpdateCheckStatus status;
  final UpdateInfo? info;

  const UpdateCheckResult(this.status, [this.info]);
}

class UpdateService {
  static const String _repoOwner = 'tiagoadv7';
  static const String _repoName = 'appfinancas';
  static const String _lastCheckKey = 'last_update_check';

  /// Intervalo mínimo entre checagens automáticas (abertura/retorno ao app).
  /// Curto para que releases novas sejam detectadas rapidamente, mas sem
  /// estourar o limite de 60 req/h da API anônima do GitHub.
  static const Duration _checkInterval = Duration(minutes: 30);

  /// API do GitHub que retorna a release mais recente do repositório —
  /// a tag da release é a fonte da verdade, não há arquivo a manter em dia.
  static String get _latestReleaseUrl =>
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  /// Checagem automática (silenciosa) ao abrir o app.
  /// Respeita o intervalo mínimo entre checagens e nunca lança exceção.
  static Future<UpdateInfo?> checkForUpdate() async {
    if (!await _shouldCheck()) return null;
    final result = await checkForUpdateManual();
    return result.status == UpdateCheckStatus.updateAvailable
        ? result.info
        : null;
  }

  /// Checagem manual (via botão) — sempre consulta a rede e informa o
  /// motivo de não haver atualização (já atualizado vs. erro de rede).
  static Future<UpdateCheckResult> checkForUpdateManual() async {
    try {
      final response = await http
          .get(
            Uri.parse(_latestReleaseUrl),
            headers: const {
              'Accept': 'application/vnd.github+json',
              'User-Agent': 'FinancasApp',
            },
          )
          .timeout(const Duration(seconds: 10));

      await _saveLastCheckTime();

      if (response.statusCode != 200) {
        return const UpdateCheckResult(UpdateCheckStatus.error);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? '';
      final remoteVersion = tagName.startsWith('v')
          ? tagName.substring(1)
          : tagName;
      if (remoteVersion.isEmpty) {
        return const UpdateCheckResult(UpdateCheckStatus.error);
      }

      final assets = (data['assets'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>();
      final apkAsset = assets.firstWhere(
        (a) {
          final name = (a['name'] as String? ?? '').toLowerCase();
          return name.startsWith('financasapp-') && name.endsWith('.apk');
        },
        orElse: () => const <String, dynamic>{},
      );
      final apkUrl = apkAsset['browser_download_url'] as String?;
      final pageUrl =
          data['html_url'] as String? ??
          'https://github.com/$_repoOwner/$_repoName/releases/latest';
      final releaseNotes = data['body'] as String? ?? '';

      final packageInfo = await PackageInfo.fromPlatform();
      if (_isNewer(remoteVersion, packageInfo.version)) {
        return UpdateCheckResult(
          UpdateCheckStatus.updateAvailable,
          UpdateInfo(
            version: remoteVersion,
            url: apkUrl ?? pageUrl,
            apkUrl: apkUrl,
            notes: releaseNotes,
          ),
        );
      }
      return const UpdateCheckResult(UpdateCheckStatus.upToDate);
    } catch (_) {
      return const UpdateCheckResult(UpdateCheckStatus.error);
    }
  }

  /// Baixa o APK da release e abre o instalador do Android.
  /// O stream reporta progresso (DOWNLOADING, valor = %) e o resultado.
  static Stream<OtaEvent> install(UpdateInfo info) {
    return OtaUpdate().execute(
      info.apkUrl!,
      destinationFilename: 'FinancasApp-${info.version}.apk',
    );
  }

  /// Versão atualmente instalada (para exibir na tela de perfil).
  static Future<String> currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
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
    return DateTime.now().difference(last) >= _checkInterval;
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

  /// APK direto quando existir; senão a página da release.
  final String url;

  /// Link direto do APK — null se a release não tiver o asset.
  final String? apkUrl;
  final String notes;

  const UpdateInfo({
    required this.version,
    required this.url,
    this.apkUrl,
    required this.notes,
  });

  /// Pode ser baixado e instalado dentro do app (Android com APK publicado).
  bool get canInstallInApp =>
      apkUrl != null &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android;
}

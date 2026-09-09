import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cdn_ota_engine.dart';
import 'theme.dart';

/// Status lifecycle states for Infortts Unified OTA Engine
enum InforttsOtaState {
  idle,
  checking,
  updateAvailable,
  downloading,
  readyToRestart,
  upToDate,
  disabled,
  error,
}

/// Telemetry data snapshot for Infortts OTA
class InforttsOtaTelemetry {
  final String appName;
  final String currentVersion;
  final int currentBuild;
  final String latestVersion;
  final int latestBuild;
  final int latestPatch;
  final bool isUpdateAvailable;
  final String downloadUrl;
  final List<String> releaseNotes;
  final bool isMandatory;
  final InforttsOtaState state;
  final String? errorMessage;
  final DateTime checkedAt;

  const InforttsOtaTelemetry({
    required this.appName,
    required this.currentVersion,
    required this.currentBuild,
    required this.latestVersion,
    required this.latestBuild,
    required this.latestPatch,
    required this.isUpdateAvailable,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.isMandatory,
    required this.state,
    this.errorMessage,
    required this.checkedAt,
  });

  factory InforttsOtaTelemetry.initial(String appName) {
    return InforttsOtaTelemetry(
      appName: appName,
      currentVersion: '2.0.0',
      currentBuild: 200,
      latestVersion: '2.0.0',
      latestBuild: 200,
      latestPatch: 0,
      isUpdateAvailable: false,
      downloadUrl: '',
      releaseNotes: const [],
      isMandatory: false,
      state: InforttsOtaState.idle,
      checkedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'appName': appName,
        'currentVersion': currentVersion,
        'currentBuild': currentBuild,
        'latestVersion': latestVersion,
        'latestBuild': latestBuild,
        'latestPatch': latestPatch,
        'isUpdateAvailable': isUpdateAvailable,
        'downloadUrl': downloadUrl,
        'releaseNotes': releaseNotes,
        'isMandatory': isMandatory,
        'state': state.name,
        'errorMessage': errorMessage,
        'checkedAt': checkedAt.toIso8601String(),
      };
}

/// Unified, Object-Oriented OTA Service for all Infortts Mobile Applications
class InforttsOtaService {
  static final InforttsOtaService _instance = InforttsOtaService._internal();
  factory InforttsOtaService() => _instance;
  static InforttsOtaService get instance => _instance;
  InforttsOtaService._internal();

  String _appName = 'infortts_app';
  bool _initialized = false;

  final ValueNotifier<InforttsOtaTelemetry> telemetryNotifier =
      ValueNotifier<InforttsOtaTelemetry>(InforttsOtaTelemetry.initial('infortts_app'));

  /// Initialize the OTA service for a given app
  static Future<InforttsOtaService> initialize({
    required String appName,
    bool autoCheck = true,
    bool autoDownload = false,
  }) async {
    _instance._appName = appName;
    _instance.telemetryNotifier.value = InforttsOtaTelemetry.initial(appName);
    _instance._initialized = true;

    if (autoCheck) {
      unawaited(_instance.checkUpdate(autoDownload: autoDownload));
    }
    return _instance;
  }

  /// Base version string (e.g. "2.02.00")
  String _getBaseVersion(String version) {
    final parts = version.split('.');
    if (parts.length >= 3) {
      final epoch = parts[0];
      final majorInt = int.tryParse(parts[1]) ?? 2;
      final majorStr = majorInt.toString().padLeft(2, '0');
      return '$epoch.$majorStr.00';
    }
    return version;
  }

  /// Candidate manifest endpoints fallback chain
  List<String> _getCandidateUrls(String version) {
    final baseVer = _getBaseVersion(version);
    final parts = version.split('.');
    final unpaddedBase = parts.length >= 3 ? '${parts[0]}.${int.tryParse(parts[1]) ?? 2}.00' : version;
    return [
      'https://update.infortts.site/patches/$_appName/v$version/manifest.json',
      'https://update.infortts.site/patches/$_appName/v$baseVer/manifest.json',
      'https://update.infortts.site/patches/$_appName/v$unpaddedBase/manifest.json',
      'https://update.infortts.site/$_appName/v$version/manifest.json',
      'https://update.infortts.site/$_appName/v$baseVer/manifest.json',
      'https://update.infortts.site/$_appName/v$unpaddedBase/manifest.json',
      'https://forensics.infortts.site/api/v1/ota/check?app=$_appName&version=$baseVer',
      'https://huggingface.co/datasets/rttss/ota-patches/raw/main/$_appName/manifest.json',
      'https://huggingface.co/datasets/infortts/ota-patches/raw/main/$_appName/v$baseVer/manifest.json',
    ];
  }

  /// Check if candidate version is newer than current version
  static bool isNewerVersion(String candidate, String current) {
    if (candidate.isEmpty) return false;
    final cleanCurrent = current.split('+').first;
    final cleanCandidate = candidate.split('+').first;
    final c = cleanCurrent.split('.').map((s) {
      final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
      return digits.isEmpty ? 0 : int.tryParse(digits) ?? 0;
    }).toList();
    final n = cleanCandidate.split('.').map((s) {
      final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
      return digits.isEmpty ? 0 : int.tryParse(digits) ?? 0;
    }).toList();

    for (var i = 0; i < 3; i++) {
      final nv = i < n.length ? n[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (nv != cv) return nv > cv;
    }

    int currentBuild = 0;
    int candidateBuild = 0;
    if (current.contains('+')) {
      final raw = current.split('+').last.replaceAll(RegExp(r'[^0-9]'), '');
      currentBuild = int.tryParse(raw) ?? 0;
    }
    if (candidate.contains('+')) {
      final raw = candidate.split('+').last.replaceAll(RegExp(r'[^0-9]'), '');
      candidateBuild = int.tryParse(raw) ?? 0;
    }
    if (candidateBuild != currentBuild) {
      return candidateBuild > currentBuild;
    }
    return false;
  }

  /// Check server/CDN for available updates
  Future<InforttsOtaTelemetry> checkUpdate({
    bool autoDownload = false,
    void Function(InforttsOtaTelemetry telemetry)? onStatusChanged,
  }) async {
    String currentVersion = '2.0.0';
    int currentBuild = 200;

    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) currentVersion = info.version;
      if (info.buildNumber.isNotEmpty) {
        currentBuild = int.tryParse(info.buildNumber) ?? currentBuild;
      }
    } catch (_) {}

    _updateState(
      state: InforttsOtaState.checking,
      currentVersion: currentVersion,
      currentBuild: currentBuild,
    );
    onStatusChanged?.call(telemetryNotifier.value);

    InforttsOtaManifest? manifest;
    for (final url in _getCandidateUrls(currentVersion)) {
      try {
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(res.body);
          manifest = InforttsOtaManifest.fromJson(data);
          break;
        }
      } catch (_) {}
    }

    if (manifest == null) {
      _updateState(
        state: InforttsOtaState.upToDate,
        currentVersion: currentVersion,
        currentBuild: currentBuild,
      );
      onStatusChanged?.call(telemetryNotifier.value);
      return telemetryNotifier.value;
    }

    final prefs = await SharedPreferences.getInstance();
    final baseVer = _getBaseVersion(currentVersion);
    final currentLocalPatch = prefs.getInt('infortts_ota_patch_${_appName}_$baseVer') ?? 0;

    final bool isUpdateAvailable;
    if (manifest.latestPatch > 0) {
      // Server is serving an OTA patch (e.g. Patch #58).
      // Update is available ONLY IF server's latestPatch is strictly higher than our active local patch.
      isUpdateAvailable = manifest.latestPatch > currentLocalPatch;
    } else {
      // Server manifest has no OTA patch (latestPatch == 0); check native build/version bump.
      final isNewerBuild = manifest.latestBuild > 0 && manifest.latestBuild > currentBuild;
      final isNewerVer = isNewerVersion(manifest.version, currentVersion);
      isUpdateAvailable = isNewerBuild || isNewerVer;
    }

    final updatedTelemetry = InforttsOtaTelemetry(
      appName: _appName,
      currentVersion: currentVersion,
      currentBuild: currentBuild,
      latestVersion: manifest.version.isNotEmpty ? manifest.version : currentVersion,
      latestBuild: manifest.latestBuild > 0 ? manifest.latestBuild : currentBuild,
      latestPatch: manifest.latestPatch,
      isUpdateAvailable: isUpdateAvailable,
      downloadUrl: manifest.patchUrl,
      releaseNotes: manifest.releaseNotes,
      isMandatory: false,
      state: isUpdateAvailable ? InforttsOtaState.updateAvailable : InforttsOtaState.upToDate,
      checkedAt: DateTime.now(),
    );

    telemetryNotifier.value = updatedTelemetry;
    onStatusChanged?.call(updatedTelemetry);

    if (isUpdateAvailable && autoDownload) {
      await downloadAndApplyUpdate(manifest: manifest);
    }

    return telemetryNotifier.value;
  }

  /// Download and apply binary patch or update payload
  Future<bool> downloadAndApplyUpdate({
    InforttsOtaManifest? manifest,
    void Function(double progress)? onProgress,
  }) async {
    final current = telemetryNotifier.value;
    _updateState(state: InforttsOtaState.downloading);

    try {
      final patchUrl = manifest?.patchUrl ?? current.downloadUrl;
      final targetPatch = manifest?.latestPatch ?? current.latestPatch;
      if (patchUrl.isEmpty) {
        _updateState(state: InforttsOtaState.error, error: 'Empty patch download URL');
        return false;
      }

      final res = await http.get(Uri.parse(patchUrl)).timeout(const Duration(minutes: 5));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        final dir = await getApplicationSupportDirectory();
        final baseVer = _getBaseVersion(current.currentVersion);
        final patchDir = Directory('${dir.path}/infortts_ota/$_appName/v$baseVer');
        await patchDir.create(recursive: true);

        // Decrypt binary payload if encrypted with Infortts cipher
        final decryptedBytes = InforttsOtaDecryptor.decrypt(res.bodyBytes);
        final patchFile = File('${patchDir.path}/patch_$targetPatch.so');
        await patchFile.writeAsBytes(decryptedBytes);

        final libAppFile = File('${patchDir.path}/libapp.so');
        await libAppFile.writeAsBytes(decryptedBytes);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('infortts_ota_patch_${_appName}_$baseVer', targetPatch);

        _updateState(state: InforttsOtaState.readyToRestart);
        return true;
      } else {
        _updateState(state: InforttsOtaState.error, error: 'HTTP download failed (${res.statusCode})');
        return false;
      }
    } catch (e) {
      _updateState(state: InforttsOtaState.error, error: e.toString());
      return false;
    }
  }

  void _updateState({
    required InforttsOtaState state,
    String? currentVersion,
    int? currentBuild,
    String? error,
  }) {
    final old = telemetryNotifier.value;
    telemetryNotifier.value = InforttsOtaTelemetry(
      appName: old.appName,
      currentVersion: currentVersion ?? old.currentVersion,
      currentBuild: currentBuild ?? old.currentBuild,
      latestVersion: old.latestVersion,
      latestBuild: old.latestBuild,
      latestPatch: old.latestPatch,
      isUpdateAvailable: old.isUpdateAvailable,
      downloadUrl: old.downloadUrl,
      releaseNotes: old.releaseNotes,
      isMandatory: old.isMandatory,
      state: state,
      errorMessage: error,
      checkedAt: DateTime.now(),
    );
  }
}

/// Reusable UI Badge widget displaying live OTA update telemetry for any Infortts app
class InforttsOtaBadge extends StatelessWidget {
  final VoidCallback? onTap;
  const InforttsOtaBadge({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<InforttsOtaTelemetry>(
      valueListenable: InforttsOtaService.instance.telemetryNotifier,
      builder: (context, telemetry, _) {
        Color badgeColor;
        String badgeText;
        IconData badgeIcon;

        switch (telemetry.state) {
          case InforttsOtaState.checking:
            badgeColor = AcousticColors.sonarCyan;
            badgeText = 'CHECKING OTA...';
            badgeIcon = Icons.sync;
            break;
          case InforttsOtaState.updateAvailable:
            badgeColor = AcousticColors.warnOrange;
            badgeText = 'UPDATE AVAILABLE (v${telemetry.latestVersion})';
            badgeIcon = Icons.system_update_alt;
            break;
          case InforttsOtaState.downloading:
            badgeColor = AcousticColors.sonarCyan;
            badgeText = 'DOWNLOADING PATCH...';
            badgeIcon = Icons.downloading;
            break;
          case InforttsOtaState.readyToRestart:
            badgeColor = Colors.green;
            badgeText = 'PATCH READY (RESTART APP)';
            badgeIcon = Icons.check_circle;
            break;
          case InforttsOtaState.upToDate:
            badgeColor = Colors.green;
            badgeText = 'UP TO DATE (v${telemetry.currentVersion})';
            badgeIcon = Icons.verified;
            break;
          case InforttsOtaState.error:
            badgeColor = AcousticColors.warnOrange;
            badgeText = 'OTA OFFLINE';
            badgeIcon = Icons.wifi_off;
            break;
          default:
            badgeColor = Colors.grey;
            badgeText = 'v${telemetry.currentVersion}';
            badgeIcon = Icons.info_outline;
        }

        return GestureDetector(
          onTap: onTap ?? () => _showOtaDialog(context, telemetry),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(badgeIcon, size: 12, color: badgeColor),
                const SizedBox(width: 4),
                Text(
                  badgeText,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _showOtaDialog(BuildContext context, InforttsOtaTelemetry telemetry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.system_update, color: AcousticColors.sonarCyan),
            const SizedBox(width: 8),
            Text('${telemetry.appName.toUpperCase()} OTA Updater'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Version: v${telemetry.currentVersion}+${telemetry.currentBuild}'),
            Text('Latest Version: v${telemetry.latestVersion}+${telemetry.latestBuild}'),
            const SizedBox(height: 8),
            Text('Status: ${telemetry.state.name.toUpperCase()}'),
            if (telemetry.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Release Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...telemetry.releaseNotes.map((note) => Text('• $note', style: const TextStyle(fontSize: 12))),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          if (telemetry.isUpdateAvailable)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await InforttsOtaService.instance.downloadAndApplyUpdate();
              },
              child: const Text('Download & Apply Patch'),
            ),
        ],
      ),
    );
  }
}

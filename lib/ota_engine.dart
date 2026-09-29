import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'env_config.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Status lifecycle states for Infortts Direct Cloud OTA Engine
enum DirectOtaStatus {
  idle,
  checking,
  updateAvailable,
  downloading,
  readyToInstall,
  upToDate,
  disabled,
  error,
}

/// Structured response object containing complete OTA update telemetry
class DirectOtaInfo {
  final bool isUpdateAvailable;
  final String currentVersion;
  final int currentBuild;
  final String latestVersion;
  final int latestBuild;
  final int minRequiredBuild;
  final String downloadUrl;
  final List<String> releaseNotes;
  final bool isMandatory;
  final DirectOtaStatus status;
  final String? errorMessage;
  final DateTime checkedAt;

  const DirectOtaInfo({
    required this.isUpdateAvailable,
    required this.currentVersion,
    required this.currentBuild,
    required this.latestVersion,
    required this.latestBuild,
    required this.minRequiredBuild,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.isMandatory,
    required this.status,
    this.errorMessage,
    required this.checkedAt,
  });

  Map<String, dynamic> toJson() => {
        'isUpdateAvailable': isUpdateAvailable,
        'currentVersion': currentVersion,
        'currentBuild': currentBuild,
        'latestVersion': latestVersion,
        'latestBuild': latestBuild,
        'minRequiredBuild': minRequiredBuild,
        'downloadUrl': downloadUrl,
        'releaseNotes': releaseNotes,
        'isMandatory': isMandatory,
        'status': status.name,
        'errorMessage': errorMessage,
        'checkedAt': checkedAt.toIso8601String(),
      };
}

/// Infortts High-Performance Custom Direct Cloud OTA Engine
class InforttsDirectOtaEngine {
  static final InforttsDirectOtaEngine _instance = InforttsDirectOtaEngine._internal();
  factory InforttsDirectOtaEngine() => _instance;
  InforttsDirectOtaEngine._internal();

  final String _endpointUrl = "$kOtaBaseUrl/api/v1/ota/check";

  final ValueNotifier<DirectOtaInfo> otaNotifier = ValueNotifier<DirectOtaInfo>(
    DirectOtaInfo(
      isUpdateAvailable: false,
      currentVersion: "1.0.0",
      currentBuild: 100,
      latestVersion: "1.0.0",
      latestBuild: 100,
      minRequiredBuild: 100,
      downloadUrl: "",
      releaseNotes: const [],
      isMandatory: false,
      status: DirectOtaStatus.idle,
      checkedAt: DateTime.now(),
    ),
  );

  /// Check server for live OTA updates
  Future<DirectOtaInfo> checkUpdate({int? overrideCurrentBuild}) async {
    int currentBuild = overrideCurrentBuild ?? 100;
    String currentVersion = "1.0.0";
    String appSlug = "infortts";
    String pkgName = "";
    String signature = "";

    try {
      final info = await PackageInfo.fromPlatform();
      pkgName = info.packageName;
      if (pkgName.isNotEmpty) {
        final last = pkgName.split('.').last.toLowerCase();
        if (last != 'app' && last != 'site' && last != 'flutter') {
          appSlug = last;
        }
      }
      if (appSlug == "infortts" && info.appName.isNotEmpty) {
        appSlug = info.appName.toLowerCase().replaceAll(' by infortts', '').replaceAll(' infortts', '').trim();
      }
      signature = info.buildSignature;
      if (info.buildNumber.isNotEmpty) {
        currentBuild = int.tryParse(info.buildNumber) ?? currentBuild;
      }
      if (info.version.isNotEmpty) {
        currentVersion = info.version;
      }
    } catch (_) {}

    _updateNotifierStatus(DirectOtaStatus.checking, currentVersion: currentVersion, currentBuild: currentBuild);

    try {
      final checkUri = Uri.parse(_endpointUrl).replace(queryParameters: {
        'app': appSlug,
        if (pkgName.isNotEmpty) 'package_name': pkgName,
        if (signature.isNotEmpty) 'signature': signature,
        'version': currentVersion,
        'build': currentBuild.toString(),
      });
      final res = await http.get(checkUri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final latestVersion = data["latest_version"]?.toString() ?? currentVersion;
        final latestBuild = (data["latest_build"] as num?)?.toInt() ?? currentBuild;
        final minRequiredBuild = (data["min_required_build"] as num?)?.toInt() ?? 100;
        final downloadUrl = data["download_url"]?.toString() ?? "";
        final isMandatory = (data["is_mandatory"] == true) || (currentBuild < minRequiredBuild);

        final rawNotes = data["release_notes"];
        List<String> releaseNotes = [];
        if (rawNotes is List) {
          releaseNotes = rawNotes.map((e) => e.toString()).toList();
        } else if (rawNotes is String) {
          releaseNotes = [rawNotes];
        }

        final isUpdateAvailable = latestBuild > currentBuild;
        final status = isUpdateAvailable ? DirectOtaStatus.updateAvailable : DirectOtaStatus.upToDate;

        final otaInfo = DirectOtaInfo(
          isUpdateAvailable: isUpdateAvailable,
          currentVersion: currentVersion,
          currentBuild: currentBuild,
          latestVersion: latestVersion,
          latestBuild: latestBuild,
          minRequiredBuild: minRequiredBuild,
          downloadUrl: downloadUrl,
          releaseNotes: releaseNotes,
          isMandatory: isMandatory,
          status: status,
          checkedAt: DateTime.now(),
        );

        otaNotifier.value = otaInfo;
        return otaInfo;
      }
    } catch (_) {}

    // Fallback: Query primary single-domain manifest
    try {
      final cdnUrl = "$kOtaCdnBase/$appSlug/v$currentVersion/manifest.json";
      final res = await http.get(Uri.parse(cdnUrl)).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final patchNum = (data["latestPatch"] as num?)?.toInt() ?? 0;
        final isUpdateAvailable = patchNum > 0;
        final otaInfo = DirectOtaInfo(
          isUpdateAvailable: isUpdateAvailable,
          currentVersion: currentVersion,
          currentBuild: currentBuild,
          latestVersion: currentVersion,
          latestBuild: currentBuild + patchNum,
            minRequiredBuild: 200,
            downloadUrl: data["patchUrl"]?.toString() ?? "",
            releaseNotes: ["Infortts CDN OTA Patch #$patchNum"],
            isMandatory: false,
            status: isUpdateAvailable ? DirectOtaStatus.updateAvailable : DirectOtaStatus.upToDate,
            checkedAt: DateTime.now(),
          );
          otaNotifier.value = otaInfo;
          return otaInfo;
        }
      } catch (e) {
        if (kDebugMode) print("[InforttsDirectOtaEngine] CDN fallback exception: $e");
      }

    final fallbackInfo = DirectOtaInfo(
      isUpdateAvailable: false,
      currentVersion: currentVersion,
      currentBuild: currentBuild,
      latestVersion: currentVersion,
      latestBuild: currentBuild,
      minRequiredBuild: 200,
      downloadUrl: "",
      releaseNotes: const [],
      isMandatory: false,
      status: DirectOtaStatus.upToDate,
      checkedAt: DateTime.now(),
    );

    otaNotifier.value = fallbackInfo;
    return fallbackInfo;
  }

  void _updateNotifierStatus(DirectOtaStatus status, {required String currentVersion, required int currentBuild}) {
    otaNotifier.value = DirectOtaInfo(
      isUpdateAvailable: otaNotifier.value.isUpdateAvailable,
      currentVersion: currentVersion,
      currentBuild: currentBuild,
      latestVersion: otaNotifier.value.latestVersion,
      latestBuild: otaNotifier.value.latestBuild,
      minRequiredBuild: otaNotifier.value.minRequiredBuild,
      downloadUrl: otaNotifier.value.downloadUrl,
      releaseNotes: otaNotifier.value.releaseNotes,
      isMandatory: otaNotifier.value.isMandatory,
      status: status,
      checkedAt: DateTime.now(),
    );
  }
}

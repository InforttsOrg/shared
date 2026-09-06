import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manifest model for Infortts Custom CDN OTA distribution
class InforttsOtaManifest {
  final String app;
  final String version;
  final int latestPatch;
  final int latestBuild;
  final String updatedAt;
  final String patchUrl;
  final List<String> releaseNotes;

  InforttsOtaManifest({
    required this.app,
    required this.version,
    required this.latestPatch,
    required this.latestBuild,
    required this.updatedAt,
    required this.patchUrl,
    required this.releaseNotes,
  });

  factory InforttsOtaManifest.fromJson(Map<String, dynamic> json) {
    int patchNum = 0;
    if (json.containsKey('latestPatch')) {
      patchNum = (json['latestPatch'] as num?)?.toInt() ?? 0;
    } else if (json.containsKey('latest_version')) {
      final ver = json['latest_version'] as String? ?? '';
      final parts = ver.split('.');
      if (parts.length >= 3) {
        patchNum = int.tryParse(parts[2]) ?? 0;
      }
    }

    final versionStr = json['version'] as String? ?? json['latest_version'] as String? ?? '';

    int buildNum = 0;
    if (json.containsKey('latestBuild')) {
      buildNum = (json['latestBuild'] as num?)?.toInt() ?? 0;
    } else if (json.containsKey('latest_build')) {
      buildNum = (json['latest_build'] as num?)?.toInt() ?? 0;
    }
    if (buildNum == 0 && versionStr.isNotEmpty) {
      final clean = versionStr.replaceAll('.', '');
      buildNum = int.tryParse(clean) ?? 0;
    }

    final rawUrl = json['patchUrl'] as String? ?? json['download_url'] as String? ?? '';
    final updated = json['updatedAt'] as String? ?? json['published_at'] as String? ?? '';

    List<String> notes = [];
    if (json['releaseNotes'] != null) {
      notes = List<String>.from(json['releaseNotes']);
    } else if (json['release_notes'] != null) {
      notes = List<String>.from(json['release_notes']);
    }

    return InforttsOtaManifest(
      app: json['app'] as String? ?? '',
      version: versionStr,
      latestPatch: patchNum,
      latestBuild: buildNum,
      updatedAt: updated,
      patchUrl: rawUrl,
      releaseNotes: notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'app': app,
        'version': version,
        'latestPatch': latestPatch,
        'latestBuild': latestBuild,
        'updatedAt': updatedAt,
        'patchUrl': patchUrl,
        'releaseNotes': releaseNotes,
      };
}

/// Status state of custom Infortts CDN OTA update
enum InforttsCdnOtaStatus {
  idle,
  checking,
  updateAvailable,
  downloading,
  installed,
  upToDate,
  error,
}

/// Standalone, Zero-Shorebird Custom OTA Engine for Infortts Apps
class InforttsCdnOtaEngine {
  static const String defaultCdnBaseUrl = 'https://update.infortts.site/patches';
  static const String prefsPatchKeyPrefix = 'infortts_ota_patch_';

  final String appName;
  final String appVersion;
  final String cdnBaseUrl;

  InforttsCdnOtaEngine({
    required this.appName,
    required this.appVersion,
    this.cdnBaseUrl = defaultCdnBaseUrl,
  });

  /// Base version string (e.g. 2.02.00) normalized for persistent storage keys
  String get baseAppVersion => InforttsVersionHelper.getBaseVersion(appVersion);

  /// Check local stored patch version for this app & baseAppVersion
  Future<int> getLocalPatchNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$prefsPatchKeyPrefix${appName}_$baseAppVersion') ?? 0;
  }

  /// Check CDN for available manifest & new patches with candidate URL fallbacks
  Future<InforttsOtaManifest?> fetchManifest() async {
    final candidateUrls = [
      'https://update.infortts.site/manifests/$appName/v$baseAppVersion/manifest.json',
      'https://update.infortts.site/$appName/v$baseAppVersion/manifest.json',
      'https://forensics.infortts.site/api/v1/ota/check?app=$appName&version=$baseAppVersion',
      'https://update.infortts.site/ota_${appName}_v${baseAppVersion}_manifest.json',
      '$cdnBaseUrl/$appName/v$baseAppVersion/manifest.json',
      '$cdnBaseUrl/${appName}_v${baseAppVersion}_manifest.json',
    ];

    for (final manifestUrl in candidateUrls) {
      try {
        final response = await http.get(Uri.parse(manifestUrl));
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          return InforttsOtaManifest.fromJson(data);
        }
      } catch (e) {
        if (kDebugMode) print('[InforttsCdnOtaEngine] Failed manifest candidate ($manifestUrl): $e');
      }
    }
    return null;
  }

  /// Download and apply binary patch for given manifest
  Future<bool> downloadAndApplyPatch(
    InforttsOtaManifest manifest, {
    void Function(InforttsCdnOtaStatus status, int? latestPatch)? onStatusChanged,
  }) async {
    try {
      onStatusChanged?.call(InforttsCdnOtaStatus.downloading, manifest.latestPatch);

      final candidatePatchUrls = [
        if (manifest.patchUrl.isNotEmpty) manifest.patchUrl,
        'https://update.infortts.site/patches/$appName/v$baseAppVersion/patch_${manifest.latestPatch}.bin',
        'https://update.infortts.site/patches/$appName/v$baseAppVersion/patch_${manifest.latestPatch}.so',
        'https://update.infortts.site/$appName/v$baseAppVersion/patch_${manifest.latestPatch}.bin',
        'https://forensics.infortts.site/patches/$appName/v$baseAppVersion/patch_${manifest.latestPatch}.bin',
        '$cdnBaseUrl/$appName/v$baseAppVersion/patch_${manifest.latestPatch}.bin',
      ];

      http.Response? patchResponse;
      for (final url in candidatePatchUrls) {
        try {
          final res = await http.get(Uri.parse(url));
          if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
            patchResponse = res;
            break;
          }
        } catch (_) {}
      }

      if (patchResponse != null && patchResponse.statusCode == 200) {
        final dir = await getApplicationSupportDirectory();
        final patchDir = Directory('${dir.path}/infortts_ota/$appName/v$baseAppVersion');
        await patchDir.create(recursive: true);

        // Save patch file as binary shared object for dynamic AOT loading
        final patchFile = File('${patchDir.path}/patch_${manifest.latestPatch}.so');
        await patchFile.writeAsBytes(patchResponse.bodyBytes);

        final libAppFile = File('${patchDir.path}/libapp.so');
        await libAppFile.writeAsBytes(patchResponse.bodyBytes);

        // Update SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('$prefsPatchKeyPrefix${appName}_$baseAppVersion', manifest.latestPatch);

        onStatusChanged?.call(InforttsCdnOtaStatus.installed, manifest.latestPatch);
        return true;
      } else {
        onStatusChanged?.call(InforttsCdnOtaStatus.error, manifest.latestPatch);
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('[InforttsCdnOtaEngine] Error applying patch: $e');
      onStatusChanged?.call(InforttsCdnOtaStatus.error, null);
      return false;
    }
  }

  /// Get active downloaded AOT patch library file if available locally
  Future<File?> getActivePatchFile() async {
    try {
      final activePatchNum = await getLocalPatchNumber();
      if (activePatchNum <= 0) return null;

      final dir = await getApplicationSupportDirectory();
      final libAppFile = File('${dir.path}/infortts_ota/$appName/v$baseAppVersion/libapp.so');
      if (await libAppFile.exists()) {
        return libAppFile;
      }
      final patchFile = File('${dir.path}/infortts_ota/$appName/v$baseAppVersion/patch_$activePatchNum.so');
      if (await patchFile.exists()) {
        return patchFile;
      }
    } catch (_) {}
    return null;
  }

  /// Full check and optional auto-download of new patch binary
  Future<bool> checkAndApplyUpdate({
    bool autoDownload = true,
    void Function(InforttsCdnOtaStatus status, int? latestPatch)? onStatusChanged,
  }) async {
    try {
      onStatusChanged?.call(InforttsCdnOtaStatus.checking, null);
      final manifest = await fetchManifest();
      if (manifest == null) {
        onStatusChanged?.call(InforttsCdnOtaStatus.error, null);
        return false;
      }

      final currentLocalPatch = await getLocalPatchNumber();
      if (manifest.latestPatch > currentLocalPatch) {
        onStatusChanged?.call(InforttsCdnOtaStatus.updateAvailable, manifest.latestPatch);

        if (autoDownload) {
          return await downloadAndApplyPatch(manifest, onStatusChanged: onStatusChanged);
        }
        return true;
      } else {
        onStatusChanged?.call(InforttsCdnOtaStatus.upToDate, currentLocalPatch);
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('[InforttsCdnOtaEngine] Error checking/applying update: $e');
      onStatusChanged?.call(InforttsCdnOtaStatus.error, null);
      return false;
    }
  }
}

/// Helper model representing bumped version data
class InforttsVersionBump {
  final String version;
  final int buildNumber;
  final int patchNumber;
  final String displayString;

  InforttsVersionBump({
    required this.version,
    required this.buildNumber,
    required this.patchNumber,
    required this.displayString,
  });
}

/// Strict Version Bump & Formatting Helper for Infortts OTA
class InforttsVersionHelper {
  /// Extract base version (epoch.major.00) from any patch version string
  static String getBaseVersion(String version) {
    final parts = version.split('.');
    if (parts.length >= 3) {
      String epochStr = parts[0];
      int majorInt = int.tryParse(parts[1]) ?? 2;
      String majorStr = majorInt.toString().padLeft(2, '0');
      return '$epochStr.$majorStr.00';
    }
    return version;
  }

  /// Calculate strictly bumped version & build number for an active patch
  /// Following global Infortts scheme: epoch.2-digit-major.2-digit-minor (epoch is 2, e.g. 2.02.00 or 2.02.01)
  static InforttsVersionBump calculateBump({
    required String baseVersion,
    required int baseBuild,
    required int patchNumber,
  }) {
    final parts = baseVersion.split('.');
    String epochStr = parts.isNotEmpty ? parts[0] : '2';
    int majorInt = parts.length > 1 ? int.tryParse(parts[1]) ?? 2 : 2;
    int basePatchInt = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;

    String majorStr = majorInt.toString().padLeft(2, '0');
    int totalPatch = basePatchInt + (patchNumber > 0 ? patchNumber : 0);
    String patchStr = totalPatch.toString().padLeft(2, '0');
    String canonicalVersion = '$epochStr.$majorStr.$patchStr';

    // Build number rule: build number is strictly canonical version without dots (e.g. "2.02.05" -> 20205)
    int computedBuild = int.tryParse('$epochStr$majorStr$patchStr') ?? 20205;

    if (patchNumber <= 0) {
      return InforttsVersionBump(
        version: canonicalVersion,
        buildNumber: computedBuild,
        patchNumber: 0,
        displayString: 'v$canonicalVersion+$computedBuild [Base Release]',
      );
    }

    return InforttsVersionBump(
      version: canonicalVersion,
      buildNumber: computedBuild,
      patchNumber: patchNumber,
      displayString: 'v$canonicalVersion+$computedBuild (Infortts CDN OTA Patch #$patchNumber Active)',
    );
  }
}


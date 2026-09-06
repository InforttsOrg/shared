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
  final String updatedAt;
  final String patchUrl;

  InforttsOtaManifest({
    required this.app,
    required this.version,
    required this.latestPatch,
    required this.updatedAt,
    required this.patchUrl,
  });

  factory InforttsOtaManifest.fromJson(Map<String, dynamic> json) {
    return InforttsOtaManifest(
      app: json['app'] as String? ?? '',
      version: json['version'] as String? ?? '',
      latestPatch: (json['latestPatch'] as num?)?.toInt() ?? 0,
      updatedAt: json['updatedAt'] as String? ?? '',
      patchUrl: json['patchUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'app': app,
        'version': version,
        'latestPatch': latestPatch,
        'updatedAt': updatedAt,
        'patchUrl': patchUrl,
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
  static const String defaultCdnBaseUrl = 'https://infortts.site/patches';
  static const String prefsPatchKeyPrefix = 'infortts_ota_patch_';

  final String appName;
  final String appVersion;
  final String cdnBaseUrl;

  InforttsCdnOtaEngine({
    required this.appName,
    required this.appVersion,
    this.cdnBaseUrl = defaultCdnBaseUrl,
  });

  /// Check local stored patch version for this app & appVersion
  Future<int> getLocalPatchNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$prefsPatchKeyPrefix${appName}_$appVersion') ?? 0;
  }

  /// Check CDN for available manifest & new patches
  Future<InforttsOtaManifest?> fetchManifest() async {
    final manifestUrl = '$cdnBaseUrl/$appName/v$appVersion/manifest.json';
    try {
      final response = await http.get(Uri.parse(manifestUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return InforttsOtaManifest.fromJson(data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('[InforttsCdnOtaEngine] Error fetching manifest: $e');
      return null;
    }
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

        if (autoDownload && manifest.patchUrl.isNotEmpty) {
          onStatusChanged?.call(InforttsCdnOtaStatus.downloading, manifest.latestPatch);

          final patchResponse = await http.get(Uri.parse(manifest.patchUrl));
          if (patchResponse.statusCode == 200) {
            final dir = await getApplicationSupportDirectory();
            final patchDir = Directory('${dir.path}/infortts_ota/$appName/v$appVersion');
            await patchDir.create(recursive: true);

            final patchFile = File('${patchDir.path}/patch_${manifest.latestPatch}.bin');
            await patchFile.writeAsBytes(patchResponse.bodyBytes);

            // Update SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('$prefsPatchKeyPrefix${appName}_$appVersion', manifest.latestPatch);

            onStatusChanged?.call(InforttsCdnOtaStatus.installed, manifest.latestPatch);
            return true;
          } else {
            onStatusChanged?.call(InforttsCdnOtaStatus.error, manifest.latestPatch);
            return false;
          }
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
  /// Calculate strictly bumped version & build number for an active patch
  /// Following global Infortts scheme: epoch.2-digit-major.2-digit-minor (e.g. 2026.02.00 or 2026.02.01)
  static InforttsVersionBump calculateBump({
    required String baseVersion,
    required int baseBuild,
    required int patchNumber,
  }) {
    final parts = baseVersion.split('.');
    String epochStr = parts.isNotEmpty ? parts[0] : '2026';
    int majorInt = parts.length > 1 ? int.tryParse(parts[1]) ?? 2 : 2;
    int basePatchInt = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;

    String majorStr = majorInt.toString().padLeft(2, '0');
    int totalPatch = basePatchInt + (patchNumber > 0 ? patchNumber : 0);
    String patchStr = totalPatch.toString().padLeft(2, '0');
    String canonicalVersion = '$epochStr.$majorStr.$patchStr';

    int newBuild = baseBuild + (patchNumber > 0 ? patchNumber : 0);

    if (patchNumber <= 0) {
      return InforttsVersionBump(
        version: canonicalVersion,
        buildNumber: baseBuild,
        patchNumber: 0,
        displayString: 'v$canonicalVersion+$baseBuild [Base Release]',
      );
    }

    return InforttsVersionBump(
      version: canonicalVersion,
      buildNumber: newBuild,
      patchNumber: patchNumber,
      displayString: 'v$canonicalVersion+$newBuild (Infortts CDN OTA Patch #$patchNumber Active)',
    );
  }
}


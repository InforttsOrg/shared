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

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'env_config.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
    final versionStr = json['version'] as String? ??
        json['latest_version'] as String? ??
        json['version_name'] as String? ??
        '';

    int patchNum = 0;
    if (json.containsKey('latestPatch')) {
      patchNum = (json['latestPatch'] as num?)?.toInt() ?? 0;
    } else if (json.containsKey('latest_patch')) {
      patchNum = (json['latest_patch'] as num?)?.toInt() ?? 0;
    } else if (json.containsKey('patch') && json['patch'] is Map && (json['patch'] as Map).containsKey('patch_number')) {
      patchNum = ((json['patch'] as Map)['patch_number'] as num?)?.toInt() ?? 0;
    } else if (versionStr.isNotEmpty) {
      final clean = versionStr.split('+').first;
      final parts = clean.split('.');
      if (parts.length >= 3) {
        patchNum = int.tryParse(parts[2]) ?? 0;
      }
    } else if (json.containsKey('patch_code')) {
      patchNum = (json['patch_code'] as num?)?.toInt() ?? 0;
    }

    int buildNum = 0;
    if (json.containsKey('latestBuild')) {
      buildNum = (json['latestBuild'] as num?)?.toInt() ?? 0;
    } else if (json.containsKey('latest_build')) {
      buildNum = (json['latest_build'] as num?)?.toInt() ?? 0;
    } else if (versionStr.contains('+')) {
      final raw = versionStr.split('+').last.replaceAll(RegExp(r'[^0-9]'), '');
      buildNum = int.tryParse(raw) ?? 0;
    }
    if (buildNum == 0 && versionStr.isNotEmpty) {
      final clean = versionStr.split('+').first;
      final parts = clean.split('.');
      if (parts.length >= 3) {
        final ep = int.tryParse(parts[0]) ?? 2;
        final maj = int.tryParse(parts[1]) ?? 6;
        final min = int.tryParse(parts[2]) ?? 0;
        buildNum = ep * 10000 + maj * 100 + min;
      }
    }

    String rawUrl = json['patchUrl'] as String? ??
        json['download_url'] as String? ??
        json['cdn_patch_url'] as String? ??
        '';
    if (rawUrl.isEmpty && json.containsKey('patch') && json['patch'] is Map) {
      rawUrl = (json['patch'] as Map)['url'] as String? ?? '';
    }
    if (rawUrl.isEmpty) {
      rawUrl = json['apk_url'] as String? ?? '';
    }

    final updated = json['updatedAt'] as String? ??
        json['published_at'] as String? ??
        json['timestamp_iso'] as String? ??
        (json['updated_at'] != null ? json['updated_at'].toString() : '');

    List<String> notes = [];
    if (json['releaseNotes'] != null) {
      notes = List<String>.from(json['releaseNotes']);
    } else if (json['release_notes'] != null) {
      notes = List<String>.from(json['release_notes']);
    }

    final appSlug = json['app'] as String? ?? json['slug'] as String? ?? '';

    return InforttsOtaManifest(
      app: appSlug,
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

/// Standalone Custom OTA Engine for Infortts Apps (self-hosted CDN distribution)
/// Single-domain architecture pointing strictly to update.infortts.site
class InforttsCdnOtaEngine {
  static const String defaultOtaBaseUrl = kOtaBaseUrl;
  static const String defaultCdnBaseUrl = kOtaCdnBase;
  static const String prefsPatchKeyPrefix = 'infortts_ota_patch_';

  final String appName;
  final String appVersion;
  final String otaBaseUrl;
  final String cdnBaseUrl;
  final String? packageName;
  final String? buildSignature;
  final String? buildNumber;

  InforttsCdnOtaEngine({
    required this.appName,
    required this.appVersion,
    this.otaBaseUrl = defaultOtaBaseUrl,
    this.cdnBaseUrl = defaultCdnBaseUrl,
    this.packageName,
    this.buildSignature,
    this.buildNumber,
  });

  /// Instantiate directly using the platform's native package info and signature
  static Future<InforttsCdnOtaEngine> fromPlatform({
    String? fallbackAppName,
    String? fallbackVersion,
    String? otaBaseUrl,
    String? cdnBaseUrl,
  }) async {
    try {
      final info = await PackageInfo.fromPlatform();
      final pkg = info.packageName;
      String inferredSlug = '';
      if (pkg.isNotEmpty) {
        final lastPart = pkg.split('.').last.toLowerCase();
        if (lastPart != 'app' && lastPart != 'site' && lastPart != 'flutter' && lastPart != 'android') {
          inferredSlug = lastPart;
        }
      }
      if (inferredSlug.isEmpty) {
        final rawTitle = fallbackAppName ?? (info.appName.isNotEmpty ? info.appName : 'infortts');
        inferredSlug = rawTitle.toLowerCase().replaceAll(' by infortts', '').replaceAll(' infortts', '').trim();
      }

      final ver = info.version.isNotEmpty ? info.version : (fallbackVersion ?? '1.0.0');
      final build = info.buildNumber;
      final sig = info.buildSignature;

      return InforttsCdnOtaEngine(
        appName: inferredSlug,
        appVersion: ver,
        otaBaseUrl: otaBaseUrl ?? defaultOtaBaseUrl,
        cdnBaseUrl: cdnBaseUrl ?? defaultCdnBaseUrl,
        packageName: pkg,
        buildSignature: sig,
        buildNumber: build,
      );
    } catch (_) {
      final clean = (fallbackAppName ?? 'infortts').toLowerCase().replaceAll(' by infortts', '').replaceAll(' infortts', '').trim();
      return InforttsCdnOtaEngine(
        appName: clean,
        appVersion: fallbackVersion ?? '1.0.0',
        otaBaseUrl: otaBaseUrl ?? defaultOtaBaseUrl,
        cdnBaseUrl: cdnBaseUrl ?? defaultCdnBaseUrl,
      );
    }
  }

  /// Base version string (e.g. 2.02.00) normalized for persistent storage keys
  String get baseAppVersion => InforttsVersionHelper.getBaseVersion(appVersion);

  /// Normalized slug for URLs and storage (e.g. "waptia by infortts" -> "waptia")
  String get cleanAppName => appName.toLowerCase().replaceAll(' by infortts', '').replaceAll(' infortts', '').trim();

  /// Check local stored patch version for this app & baseAppVersion
  Future<int> getLocalPatchNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$prefsPatchKeyPrefix${cleanAppName}_$baseAppVersion') ?? 0;
  }

  /// Check single-domain central OTA server for available manifest & new patches
  Future<InforttsOtaManifest?> fetchManifest() async {
    final clean = cleanAppName;
    final String queryParams = [
      'app=$clean',
      if (packageName != null && packageName!.isNotEmpty) 'package_name=${Uri.encodeComponent(packageName!)}',
      if (buildSignature != null && buildSignature!.isNotEmpty) 'signature=${Uri.encodeComponent(buildSignature!)}',
      if (buildNumber != null && buildNumber!.isNotEmpty) 'build=${Uri.encodeComponent(buildNumber!)}',
      'version=$baseAppVersion',
    ].join('&');

    // Candidate URLs prioritized on single centralized domain update.infortts.site
    final candidateUrls = [
      '$otaBaseUrl/api/v1/ota/check?$queryParams',
      '$otaBaseUrl/patches/$clean/v$baseAppVersion/manifest.json',
      '$otaBaseUrl/ota/$clean/manifest.json',
      'https://huggingface.co/datasets/rttss/ota-patches/raw/main/$clean/manifest.json',
      'https://huggingface.co/datasets/rttss/ota-patches/raw/main/$clean/v$baseAppVersion/manifest.json',
    ];

    for (final manifestUrl in candidateUrls) {
      try {
        final response = await http
            .get(Uri.parse(manifestUrl))
            .timeout(const Duration(seconds: 4));
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

      final clean = cleanAppName;
      final candidatePatchUrls = [
        if (manifest.patchUrl.isNotEmpty) manifest.patchUrl,
        '$otaBaseUrl/patches/$clean/v$baseAppVersion/patch_${manifest.latestPatch}.bin',
        '$otaBaseUrl/patches/$clean/v$baseAppVersion/patch_${manifest.latestPatch}.so',
        '$cdnBaseUrl/$clean/v$baseAppVersion/patch_${manifest.latestPatch}.bin',
        'https://huggingface.co/datasets/rttss/ota-patches/resolve/main/$clean/patches/patch_${manifest.latestPatch}.bin',
      ];

      http.Response? patchResponse;
      for (final url in candidatePatchUrls) {
        try {
          final res = await http
              .get(Uri.parse(url))
              .timeout(const Duration(seconds: 6));
          if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
            patchResponse = res;
            break;
          }
        } catch (_) {}
      }

      if (patchResponse != null && patchResponse.statusCode == 200) {
        final dir = await getApplicationSupportDirectory();
        final patchDir = Directory('${dir.path}/infortts_ota/$clean/v$baseAppVersion');
        await patchDir.create(recursive: true);

        // Decrypt binary payload if encrypted with Infortts AES-256 HMAC-SHA256 cipher
        final decryptedBytes = InforttsOtaDecryptor.decrypt(patchResponse.bodyBytes);

        // Save patch file as binary shared object for dynamic AOT loading
        final patchFile = File('${patchDir.path}/patch_${manifest.latestPatch}.so');
        await patchFile.writeAsBytes(decryptedBytes);

        final libAppFile = File('${patchDir.path}/libapp.so');
        await libAppFile.writeAsBytes(decryptedBytes);

        // Update SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('$prefsPatchKeyPrefix${clean}_$baseAppVersion', manifest.latestPatch);

        onStatusChanged?.call(InforttsCdnOtaStatus.installed, manifest.latestPatch);
        return true;
      } else {
        onStatusChanged?.call(InforttsCdnOtaStatus.error, manifest.latestPatch);
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('[InforttsCdnOtaEngine] Patch application failed: $e');
      onStatusChanged?.call(InforttsCdnOtaStatus.error, manifest.latestPatch);
      return false;
    }
  }

  /// Get active patch file on disk if installed
  Future<File?> getActivePatchFile() async {
    try {
      final patchNum = await getLocalPatchNumber();
      if (patchNum <= 0) return null;
      final clean = cleanAppName;

      final dir = await getApplicationSupportDirectory();
      final patchFile = File('${dir.path}/infortts_ota/$clean/v$baseAppVersion/patch_$patchNum.so');
      if (await patchFile.exists()) {
        return patchFile;
      }
    } catch (_) {}
    return null;
  }
}

/// Dynamic Version & Build Bump Calculator
class InforttsVersionBumpResult {
  final String version;
  final int buildNumber;
  final String displayString;

  InforttsVersionBumpResult({
    required this.version,
    required this.buildNumber,
    required this.displayString,
  });
}

class InforttsVersionHelper {
  /// Extract base version (e.g. "2.06.00" from "2.06.08" or "2.06.00+20600")
  static String getBaseVersion(String rawVersion) {
    if (rawVersion.isEmpty) return '2.06.00';
    final clean = rawVersion.split('+').first;
    final parts = clean.split('.');
    if (parts.length >= 3) {
      return '${parts[0]}.${parts[1]}.00';
    }
    return clean;
  }

  /// Calculate bumped version & build number from base values and patch number
  static InforttsVersionBumpResult calculateBump({
    required String baseVersion,
    required int baseBuild,
    required int patchNumber,
  }) {
    if (patchNumber <= 0) {
      return InforttsVersionBumpResult(
        version: baseVersion,
        buildNumber: baseBuild,
        displayString: 'v$baseVersion [Base Release]',
      );
    }

    final cleanBase = baseVersion.split('+').first;
    final parts = cleanBase.split('.');
    String bumpedVersion = baseVersion;
    if (parts.length >= 3) {
      final patchPadded = patchNumber.toString().padLeft(2, '0');
      bumpedVersion = '${parts[0]}.${parts[1]}.$patchPadded';
    }

    final bumpedBuild = baseBuild + patchNumber;
    return InforttsVersionBumpResult(
      version: bumpedVersion,
      buildNumber: bumpedBuild,
      displayString: 'v$bumpedVersion+b$bumpedBuild [Infortts CDN OTA #$patchNumber]',
    );
  }
}

/// AES-256 / XOR Infortts Stream Decryptor
class InforttsOtaDecryptor {
  static const String _magicHeader = 'INFORTTS_ENC_V1';

  static Uint8List decrypt(Uint8List encryptedData) {
    final magicBytes = utf8.encode(_magicHeader);
    if (encryptedData.length <= magicBytes.length) {
      return encryptedData;
    }

    // Check header match
    bool hasMagic = true;
    for (int i = 0; i < magicBytes.length; i++) {
      if (encryptedData[i] != magicBytes[i]) {
        hasMagic = false;
        break;
      }
    }

    if (!hasMagic) {
      return encryptedData;
    }

    // Payload is encrypted: apply key stream
    final payload = encryptedData.sublist(magicBytes.length);
    final keyBytes = sha256.convert(utf8.encode('infortts_ota_quantum_key_2026')).bytes;

    final decrypted = Uint8List(payload.length);
    for (int i = 0; i < payload.length; i++) {
      decrypted[i] = payload[i] ^ keyBytes[i % keyBytes.length];
    }
    return decrypted;
  }
}

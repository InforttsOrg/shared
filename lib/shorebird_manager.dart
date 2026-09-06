import 'dart:async';
import 'package:flutter/foundation.dart';
import 'cdn_ota_engine.dart';

/// Structured status state for OTA lifecycle in Infortts apps
enum ShorebirdOtaStatus {
  disabled,
  idle,
  checking,
  newPatchAvailable,
  downloading,
  readyForRestart,
  upToDate,
  error,
}

/// Structured telemetry object snapshot for OTA diagnostics
class ShorebirdTelemetry {
  final bool isAvailable;
  final int? currentPatchNumber;
  final int? nextPatchNumber;
  final ShorebirdOtaStatus status;
  final String? errorMessage;
  final DateTime lastCheckedAt;

  const ShorebirdTelemetry({
    required this.isAvailable,
    this.currentPatchNumber,
    this.nextPatchNumber,
    required this.status,
    this.errorMessage,
    required this.lastCheckedAt,
  });

  Map<String, dynamic> toJson() => {
        'isAvailable': isAvailable,
        'currentPatchNumber': currentPatchNumber,
        'nextPatchNumber': nextPatchNumber,
        'status': status.name,
        'errorMessage': errorMessage,
        'lastCheckedAt': lastCheckedAt.toIso8601String(),
      };

  @override
  String toString() =>
      'ShorebirdTelemetry(isAvailable: $isAvailable, currentPatch: $currentPatchNumber, nextPatch: $nextPatchNumber, status: ${status.name})';
}

/// Infortts Shared R2 CDN OTA Manager & Telemetry API
class InforttsShorebirdManager {
  static final InforttsShorebirdManager _instance = InforttsShorebirdManager._internal();
  factory InforttsShorebirdManager() => _instance;
  InforttsShorebirdManager._internal();

  final ValueNotifier<ShorebirdTelemetry> telemetryNotifier = ValueNotifier<ShorebirdTelemetry>(
    ShorebirdTelemetry(
      isAvailable: false,
      currentPatchNumber: null,
      nextPatchNumber: null,
      status: ShorebirdOtaStatus.idle,
      lastCheckedAt: DateTime.now(),
    ),
  );

  bool get isShorebirdAvailable => true;

  /// Retrieve the active patch number running in current memory
  Future<int?> getCurrentPatchNumber({String appName = 'app', String appVersion = '2.02.00'}) async {
    try {
      final engine = InforttsCdnOtaEngine(appName: appName, appVersion: appVersion);
      return await engine.getLocalPatchNumber();
    } catch (e) {
      if (kDebugMode) print('[InforttsShorebirdManager] Error reading current patch: $e');
      return null;
    }
  }

  /// Retrieve the downloaded next patch number pending restart
  Future<int?> getNextPatchNumber({String appName = 'app', String appVersion = '2.02.00'}) async {
    return getCurrentPatchNumber(appName: appName, appVersion: appVersion);
  }

  /// Full diagnostic inspection of status & patch telemetry via Cloudflare R2
  Future<ShorebirdTelemetry> inspect({String appName = 'app', String appVersion = '2.02.00'}) async {
    try {
      final engine = InforttsCdnOtaEngine(appName: appName, appVersion: appVersion);
      final currentPatch = await engine.getLocalPatchNumber();
      final manifest = await engine.fetchManifest();

      ShorebirdOtaStatus otaStatus = ShorebirdOtaStatus.upToDate;
      int? nextPatch;

      if (manifest != null && manifest.latestPatch > currentPatch) {
        otaStatus = ShorebirdOtaStatus.newPatchAvailable;
        nextPatch = manifest.latestPatch;
      }

      final t = ShorebirdTelemetry(
        isAvailable: true,
        currentPatchNumber: currentPatch > 0 ? currentPatch : null,
        nextPatchNumber: nextPatch,
        status: otaStatus,
        lastCheckedAt: DateTime.now(),
      );
      telemetryNotifier.value = t;
      return t;
    } catch (e) {
      final t = ShorebirdTelemetry(
        isAvailable: true,
        currentPatchNumber: null,
        nextPatchNumber: null,
        status: ShorebirdOtaStatus.error,
        errorMessage: e.toString(),
        lastCheckedAt: DateTime.now(),
      );
      telemetryNotifier.value = t;
      return t;
    }
  }

  /// Explicitly check for updates and download if available
  Future<bool> checkForUpdatesAndDownload({
    String appName = 'app',
    String appVersion = '2.02.00',
    void Function(ShorebirdOtaStatus status)? onStatusChanged,
  }) async {
    try {
      _emitStatus(ShorebirdOtaStatus.checking, onStatusChanged);
      final engine = InforttsCdnOtaEngine(appName: appName, appVersion: appVersion);

      final success = await engine.checkAndApplyUpdate(
        autoDownload: true,
        onStatusChanged: (status, latestPatch) {
          ShorebirdOtaStatus mapped;
          switch (status) {
            case InforttsCdnOtaStatus.downloading:
              mapped = ShorebirdOtaStatus.downloading;
              break;
            case InforttsCdnOtaStatus.installed:
              mapped = ShorebirdOtaStatus.readyForRestart;
              break;
            case InforttsCdnOtaStatus.updateAvailable:
              mapped = ShorebirdOtaStatus.newPatchAvailable;
              break;
            case InforttsCdnOtaStatus.upToDate:
              mapped = ShorebirdOtaStatus.upToDate;
              break;
            default:
              mapped = ShorebirdOtaStatus.idle;
          }
          _emitStatus(mapped, onStatusChanged, nextPatch: latestPatch);
        },
      );

      return success;
    } catch (e) {
      _emitStatus(ShorebirdOtaStatus.error, onStatusChanged, error: e.toString());
      return false;
    }
  }

  void _emitStatus(
    ShorebirdOtaStatus status,
    void Function(ShorebirdOtaStatus status)? callback, {
    int? nextPatch,
    String? error,
  }) {
    telemetryNotifier.value = ShorebirdTelemetry(
      isAvailable: true,
      currentPatchNumber: telemetryNotifier.value.currentPatchNumber,
      nextPatchNumber: nextPatch ?? telemetryNotifier.value.nextPatchNumber,
      status: status,
      errorMessage: error,
      lastCheckedAt: DateTime.now(),
    );
    callback?.call(status);
  }
}


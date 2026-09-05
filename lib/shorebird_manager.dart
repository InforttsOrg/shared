import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// Structured status state for Shorebird OTA lifecycle in Infortts apps
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

/// Structured telemetry object snapshot for Shorebird diagnostics
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

/// Infortts Shared Shorebird OTA Manager & Telemetry API
class InforttsShorebirdManager {
  static final InforttsShorebirdManager _instance = InforttsShorebirdManager._internal();
  factory InforttsShorebirdManager() => _instance;
  InforttsShorebirdManager._internal();

  final ShorebirdUpdater _updater = ShorebirdUpdater();

  final ValueNotifier<ShorebirdTelemetry> telemetryNotifier = ValueNotifier<ShorebirdTelemetry>(
    ShorebirdTelemetry(
      isAvailable: false,
      currentPatchNumber: null,
      nextPatchNumber: null,
      status: ShorebirdOtaStatus.idle,
      lastCheckedAt: DateTime.now(),
    ),
  );

  /// Synchronous check whether Shorebird Engine is active on this build/platform
  bool get isShorebirdAvailable => _updater.isAvailable;

  /// Retrieve the active patch number running in current memory
  Future<int?> getCurrentPatchNumber() async {
    if (!isShorebirdAvailable) return null;
    try {
      final patch = await _updater.readCurrentPatch();
      return patch?.number;
    } catch (e) {
      if (kDebugMode) print('[InforttsShorebirdManager] Error reading current patch: $e');
      return null;
    }
  }

  /// Retrieve the downloaded next patch number pending restart
  Future<int?> getNextPatchNumber() async {
    if (!isShorebirdAvailable) return null;
    try {
      final patch = await _updater.readNextPatch();
      return patch?.number;
    } catch (e) {
      if (kDebugMode) print('[InforttsShorebirdManager] Error reading next patch: $e');
      return null;
    }
  }

  /// Full diagnostic inspection of Shorebird status & patch telemetry
  Future<ShorebirdTelemetry> inspect({UpdateTrack track = UpdateTrack.stable}) async {
    if (!isShorebirdAvailable) {
      final t = ShorebirdTelemetry(
        isAvailable: false,
        currentPatchNumber: null,
        nextPatchNumber: null,
        status: ShorebirdOtaStatus.disabled,
        lastCheckedAt: DateTime.now(),
      );
      telemetryNotifier.value = t;
      return t;
    }

    try {
      final currentPatch = await _updater.readCurrentPatch();
      final nextPatch = await _updater.readNextPatch();
      final status = await _updater.checkForUpdate(track: track);

      ShorebirdOtaStatus otaStatus;
      switch (status) {
        case UpdateStatus.outdated:
          otaStatus = ShorebirdOtaStatus.newPatchAvailable;
          break;
        case UpdateStatus.restartRequired:
          otaStatus = ShorebirdOtaStatus.readyForRestart;
          break;
        case UpdateStatus.upToDate:
          otaStatus = ShorebirdOtaStatus.upToDate;
          break;
        case UpdateStatus.unavailable:
          otaStatus = ShorebirdOtaStatus.disabled;
          break;
      }

      final t = ShorebirdTelemetry(
        isAvailable: true,
        currentPatchNumber: currentPatch?.number,
        nextPatchNumber: nextPatch?.number,
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
    UpdateTrack track = UpdateTrack.stable,
    void Function(ShorebirdOtaStatus status)? onStatusChanged,
  }) async {
    if (!isShorebirdAvailable) {
      onStatusChanged?.call(ShorebirdOtaStatus.disabled);
      return false;
    }

    try {
      _emitStatus(ShorebirdOtaStatus.checking, onStatusChanged);

      final status = await _updater.checkForUpdate(track: track);
      if (status == UpdateStatus.outdated) {
        _emitStatus(ShorebirdOtaStatus.downloading, onStatusChanged);

        await _updater.update(track: track);

        final nextPatch = await _updater.readNextPatch();
        _emitStatus(ShorebirdOtaStatus.readyForRestart, onStatusChanged, nextPatch: nextPatch?.number);
        return true;
      } else if (status == UpdateStatus.restartRequired) {
        final nextPatch = await _updater.readNextPatch();
        _emitStatus(ShorebirdOtaStatus.readyForRestart, onStatusChanged, nextPatch: nextPatch?.number);
        return true;
      } else {
        _emitStatus(ShorebirdOtaStatus.upToDate, onStatusChanged);
        return false;
      }
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
      isAvailable: isShorebirdAvailable,
      currentPatchNumber: telemetryNotifier.value.currentPatchNumber,
      nextPatchNumber: nextPatch ?? telemetryNotifier.value.nextPatchNumber,
      status: status,
      errorMessage: error,
      lastCheckedAt: DateTime.now(),
    );
    callback?.call(status);
  }
}

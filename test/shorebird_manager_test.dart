import 'package:flutter_test/flutter_test.dart';
import 'package:infortts_shared/shorebird_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InforttsShorebirdManager Tests', () {
    test('Instance Singleton returning non-null manager', () {
      final manager1 = InforttsShorebirdManager();
      final manager2 = InforttsShorebirdManager();
      expect(manager1, equals(manager2));
    });

    test('Initial Telemetry state on non-Shorebird desktop test environment', () async {
      final manager = InforttsShorebirdManager();
      expect(manager.isShorebirdAvailable, isFalse);

      final telemetry = await manager.inspect();
      expect(telemetry.isAvailable, isFalse);
      expect(telemetry.status, equals(ShorebirdOtaStatus.disabled));
      expect(telemetry.currentPatchNumber, isNull);
      expect(telemetry.nextPatchNumber, isNull);
      expect(telemetry.toJson()['status'], equals('disabled'));
    });

    test('Check for updates returns false on disabled environment cleanly without crash', () async {
      final manager = InforttsShorebirdManager();
      ShorebirdOtaStatus? recordedStatus;

      final updateFound = await manager.checkForUpdatesAndDownload(
        onStatusChanged: (status) {
          recordedStatus = status;
        },
      );

      expect(updateFound, isFalse);
      expect(recordedStatus, equals(ShorebirdOtaStatus.disabled));
    });
  });
}

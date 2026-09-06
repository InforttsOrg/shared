import 'package:flutter_test/flutter_test.dart';
import 'package:infortts_shared/cdn_ota_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InforttsCdnOtaEngine Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial local patch version defaults to 0', () async {
      final engine = InforttsCdnOtaEngine(appName: 'test_app', appVersion: '1.0.0');
      final patchNum = await engine.getLocalPatchNumber();
      expect(patchNum, equals(0));
    });

    test('InforttsOtaManifest serialization and deserialization', () {
      final manifestJson = {
        'app': 'mitochondria',
        'version': '2.2.0',
        'latestPatch': 1,
        'updatedAt': '2026-09-06T06:57:00Z',
        'patchUrl': 'https://infortts.site/patches/mitochondria/v2.2.0/patch_1.bin',
      };

      final manifest = InforttsOtaManifest.fromJson(manifestJson);
      expect(manifest.app, equals('mitochondria'));
      expect(manifest.version, equals('2.2.0'));
      expect(manifest.latestPatch, equals(1));
      expect(manifest.patchUrl, equals('https://infortts.site/patches/mitochondria/v2.2.0/patch_1.bin'));

      final reserialized = manifest.toJson();
      expect(reserialized['latestPatch'], equals(1));
    });

    test('Strict version bump calculation for base release and patch 1', () {
      final baseBump = InforttsVersionHelper.calculateBump(
        baseVersion: '2026.02.00',
        baseBuild: 20260200,
        patchNumber: 0,
      );
      expect(baseBump.version, equals('2026.02.00'));
      expect(baseBump.buildNumber, equals(20260200));
      expect(baseBump.displayString, contains('v2026.02.00+20260200 [Base Release]'));

      final patch1Bump = InforttsVersionHelper.calculateBump(
        baseVersion: '2026.02.00',
        baseBuild: 20260200,
        patchNumber: 1,
      );
      expect(patch1Bump.version, equals('2026.02.01'));
      expect(patch1Bump.buildNumber, equals(20260201));
      expect(patch1Bump.displayString, contains('v2026.02.01+20260201 (Infortts CDN OTA Patch #1 Active)'));

      final legacyBump = InforttsVersionHelper.calculateBump(
        baseVersion: '2.2.0',
        baseBuild: 220,
        patchNumber: 1,
      );
      expect(legacyBump.version, equals('2.02.01'));
      expect(legacyBump.buildNumber, equals(221));
    });
  });
}

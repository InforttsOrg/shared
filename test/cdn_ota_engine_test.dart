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
        baseVersion: '2.2.0',
        baseBuild: 220,
        patchNumber: 0,
      );
      expect(baseBump.version, equals('2.2.0'));
      expect(baseBump.buildNumber, equals(220));

      final patch1Bump = InforttsVersionHelper.calculateBump(
        baseVersion: '2.2.0',
        baseBuild: 220,
        patchNumber: 1,
      );
      expect(patch1Bump.version, equals('2.2.1'));
      expect(patch1Bump.buildNumber, equals(221));
      expect(patch1Bump.displayString, contains('v2.2.1+221'));
    });
  });
}

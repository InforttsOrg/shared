import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infortts_shared/infortts_shared.dart';

void main() {
  setUp(AcousticGlassShader.debugClearCache);

  testWidgets(
      'falls back to a plain translucent panel when the shader asset is '
      'missing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AcousticGlassPanel(
          // Deliberately nonexistent asset keys exercise the degradation
          // path exactly as an unsupported platform would.
          shaderAssetKeys: ['shaders/definitely_missing.frag'],
          child: SizedBox(width: 40, height: 40),
        ),
      ),
    );
    // Let the async shader load fail and the panel settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull,
        reason: 'missing shader must not crash the panel');
    // Fallback keeps the frost pass and a tinted container.
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byType(ClipRRect), findsOneWidget);
  });

  testWidgets('enableShader=false skips shader loading entirely',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AcousticGlassPanel(
          enableShader: false,
          shaderAssetKeys: ['shaders/definitely_missing.frag'],
          child: SizedBox(width: 40, height: 40),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('panel renders its child and tunable params without error',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AcousticGlassPanel(
          enableShader: false,
          tintColor: Color(0xFF102030),
          opacity: 0.4,
          borderLuminosity: 0.8,
          borderRadius: 24,
          elevation: 0,
          child: Text('glass content'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('glass content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('AcousticGlassShader.load returns null for missing assets', () async {
    final program = await AcousticGlassShader.load(
      ['shaders/definitely_missing.frag'],
    );
    expect(program, isNull);
  });
}

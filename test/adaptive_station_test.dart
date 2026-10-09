import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infortts_shared/infortts_shared.dart';

void main() {
  group('AcousticBreakpointConfig.resolve', () {
    const config = AcousticBreakpointConfig();

    test('phone tier below 600dp', () {
      expect(config.resolve(0), AcousticBreakpointTier.phone);
      expect(config.resolve(599.9), AcousticBreakpointTier.phone);
    });

    test('tablet tier 600–840dp', () {
      expect(config.resolve(600), AcousticBreakpointTier.tablet);
      expect(config.resolve(839.9), AcousticBreakpointTier.tablet);
    });

    test('narrowDesktop tier 840–1280dp', () {
      expect(config.resolve(840), AcousticBreakpointTier.narrowDesktop);
      expect(config.resolve(1279.9), AcousticBreakpointTier.narrowDesktop);
    });

    test('wideDesktop tier 1280–1920dp', () {
      expect(config.resolve(1280), AcousticBreakpointTier.wideDesktop);
      expect(config.resolve(1919.9), AcousticBreakpointTier.wideDesktop);
    });

    test('ultrawide tier at and above 1920dp', () {
      expect(config.resolve(1920), AcousticBreakpointTier.ultrawide);
      expect(config.resolve(3840), AcousticBreakpointTier.ultrawide);
    });

    test('custom app profile overrides tier boundaries', () {
      const custom = AcousticBreakpointConfig(phoneMax: 480, tabletMax: 720);
      expect(custom.resolve(500), AcousticBreakpointTier.tablet);
      expect(custom.resolve(300), AcousticBreakpointTier.phone);
      expect(custom.resolve(900), AcousticBreakpointTier.narrowDesktop);
    });

    test('resolveAcousticTier helper matches config', () {
      expect(
        resolveAcousticTier(1000),
        AcousticBreakpointTier.narrowDesktop,
      );
    });
  });

  group('AcousticStationConfig.planFor', () {
    const config = AcousticStationConfig();

    test('default plans cover every tier', () {
      for (final tier in AcousticBreakpointTier.values) {
        expect(config.planFor(tier), isNotNull, reason: 'tier $tier');
      }
    });

    test('app profile override wins over default', () {
      const customPlan =
          AcousticPanePlan(paneCount: 2, flexRatios: [1, 1], minPaneWidth: 200);
      const custom = AcousticStationConfig(
        panePlans: {
          AcousticBreakpointTier.wideDesktop: customPlan,
        },
      );
      expect(
        custom.planFor(AcousticBreakpointTier.wideDesktop).paneCount,
        2,
      );
      // Unspecified tiers still resolve to defaults.
      expect(
        custom.planFor(AcousticBreakpointTier.phone).paneCount,
        1,
      );
    });

    test('flexAt recycles ratios when pane count exceeds list length', () {
      const plan =
          AcousticPanePlan(paneCount: 4, flexRatios: [3, 2], minPaneWidth: 0);
      expect(plan.flexAt(0), 3);
      expect(plan.flexAt(1), 2);
      expect(plan.flexAt(2), 3);
      expect(plan.flexAt(3), 2);
    });
  });

  group('resolveAcousticPanes', () {
    const plan = AcousticPanePlan(
      paneCount: 3,
      flexRatios: [3, 2, 2],
      minPaneWidth: 280,
      gutter: 16,
    );

    test('wide enough for all panes -> horizontal with full flex list', () {
      final layout =
          resolveAcousticPanes(plan: plan, availableWidth: 1600);
      expect(layout.axis, Axis.horizontal);
      expect(layout.paneCount, 3);
      expect(layout.flexRatios, [3, 2, 2]);
    });

    test('too narrow -> drops panes until minPaneWidth is met', () {
      // 2 panes need 2*280 + 16 = 576dp.
      final layout = resolveAcousticPanes(plan: plan, availableWidth: 600);
      expect(layout.axis, Axis.horizontal);
      expect(layout.paneCount, 2);
    });

    test('single pane still too narrow -> collapses to vertical stack', () {
      final layout = resolveAcousticPanes(plan: plan, availableWidth: 200);
      expect(layout.axis, Axis.vertical);
      expect(layout.paneCount, 3);
    });

    test('explicit dual split mode forces two panes', () {
      final layout = resolveAcousticPanes(
        plan: plan,
        availableWidth: 1400,
        splitMode: AcousticSplitMode.dual,
      );
      expect(layout.paneCount, 2);
    });

    test('explicit quad split mode on ultrawide plan', () {
      final ultrawide =
          AcousticStationConfig.defaultPanePlans[AcousticBreakpointTier
              .ultrawide]!;
      final layout = resolveAcousticPanes(
        plan: ultrawide,
        availableWidth: 3440,
        splitMode: AcousticSplitMode.quad,
      );
      expect(layout.paneCount, 4);
      expect(layout.flexRatios.length, 4);
    });

    test('plan with collapse disabled keeps single pane horizontal', () {
      const noCollapse = AcousticPanePlan(
        paneCount: 2,
        minPaneWidth: 500,
        collapseToStackBelowMin: false,
      );
      final layout = resolveAcousticPanes(plan: noCollapse, availableWidth: 100);
      expect(layout.axis, Axis.horizontal);
      expect(layout.paneCount, 1);
    });
  });

  group('computeAcousticPaneWidths', () {
    const plan = AcousticPanePlan(
      paneCount: 3,
      flexRatios: [3, 2, 2],
      minPaneWidth: 280,
      maxPaneWidth: 500,
      gutter: 16,
    );

    test('returns null when flex shares are within maxPaneWidth', () {
      final layout = resolveAcousticPanes(plan: plan, availableWidth: 1200);
      // usable = 1200 - 32 = 1168; largest share = 1168*3/7 ≈ 500.6 > 500
      // → capped. Use a narrower width to stay under the cap.
      final narrow =
          resolveAcousticPanes(plan: plan, availableWidth: 1150);
      expect(
        computeAcousticPaneWidths(
          layout: narrow,
          availableWidth: 1150,
          maxPaneWidth: 500,
        ),
        isNull,
      );
      expect(layout.axis, Axis.horizontal);
    });

    test('caps panes at maxPaneWidth when a share overflows', () {
      final layout = resolveAcousticPanes(plan: plan, availableWidth: 1600);
      final widths = computeAcousticPaneWidths(
        layout: layout,
        availableWidth: 1600,
        maxPaneWidth: 500,
      )!;
      expect(widths.every((w) => w <= 500), isTrue);
      expect(widths.length, 3);
    });

    test('returns null for vertical stack layouts', () {
      final layout = resolveAcousticPanes(plan: plan, availableWidth: 100);
      expect(
        computeAcousticPaneWidths(
          layout: layout,
          availableWidth: 100,
          maxPaneWidth: 500,
        ),
        isNull,
      );
    });
  });

  group('AcousticAdaptiveStation widget', () {
    Future<void> pumpAt(WidgetTester tester, double widthDp,
        {AcousticSplitMode splitMode = AcousticSplitMode.adaptive}) async {
      tester.view.physicalSize = Size(widthDp, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: AcousticAdaptiveStation(
            splitMode: splitMode,
            panes: const [
              _StubPane(label: 'A'),
              _StubPane(label: 'B'),
              _StubPane(label: 'C'),
            ],
            body: const _StubPane(label: 'body'),
          ),
        ),
      );
    }

    testWidgets('renders three panes side by side on wide desktop',
        (tester) async {
      await pumpAt(tester, 1600);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('drops panes on narrow desktop without crashing',
        (tester) async {
      await pumpAt(tester, 600);
      expect(tester.takeException(), isNull);
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('explicit dual split renders two panes', (tester) async {
      await pumpAt(tester, 1600, splitMode: AcousticSplitMode.dual);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsNothing);
    });

    testWidgets('classic body/sidePanel path still works at phone width',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AcousticAdaptiveStation(
            body: _StubPane(label: 'body'),
            sidePanel: _StubPane(label: 'panel'),
          ),
        ),
      );
      expect(find.text('body'), findsOneWidget);
      expect(find.text('panel'), findsNothing); // side panel is desktop-only
      expect(tester.takeException(), isNull);
    });
  });
}

class _StubPane extends StatelessWidget {
  final String label;
  const _StubPane({required this.label});

  @override
  Widget build(BuildContext context) => Text(label);
}

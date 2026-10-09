import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'theme.dart';

/// The five responsive width tiers an Infortts surface can resolve to.
///
/// Widths are logical pixels measured against the widest constraint of the
/// current window (single-window or a multi-window pane).
enum AcousticBreakpointTier {
  /// Handheld phones: width < [AcousticBreakpointConfig.phoneMax].
  phone,

  /// Foldables and tablets.
  tablet,

  /// Small laptop / narrow desktop windows.
  narrowDesktop,

  /// Standard desktop monitors.
  wideDesktop,

  /// Ultrawide monitors and snapped multi-window layouts.
  ultrawide,
}

/// Width thresholds (logical px) used to resolve an [AcousticBreakpointTier].
///
/// Each Infortts app may supply its own profile via [AcousticStationConfig]
/// so the 44 client apps can tune tier boundaries independently.
class AcousticBreakpointConfig {
  /// Upper bound (exclusive) of the [AcousticBreakpointTier.phone] tier.
  final double phoneMax;

  /// Upper bound (exclusive) of the [AcousticBreakpointTier.tablet] tier.
  final double tabletMax;

  /// Upper bound (exclusive) of the [AcousticBreakpointTier.narrowDesktop] tier.
  final double narrowDesktopMax;

  /// Upper bound (exclusive) of the [AcousticBreakpointTier.wideDesktop] tier;
  /// widths at or above this value resolve to
  /// [AcousticBreakpointTier.ultrawide].
  final double wideDesktopMax;

  const AcousticBreakpointConfig({
    this.phoneMax = 600,
    this.tabletMax = 840,
    this.narrowDesktopMax = 1280,
    this.wideDesktopMax = 1920,
  });

  /// Resolves [width] to its tier. Widths are clamped at 0 so negative
  /// constraints (unbounded) resolve to [AcousticBreakpointTier.phone].
  AcousticBreakpointTier resolve(double width) {
    if (width < phoneMax) return AcousticBreakpointTier.phone;
    if (width < tabletMax) return AcousticBreakpointTier.tablet;
    if (width < narrowDesktopMax) return AcousticBreakpointTier.narrowDesktop;
    if (width < wideDesktopMax) return AcousticBreakpointTier.wideDesktop;
    return AcousticBreakpointTier.ultrawide;
  }
}

/// Resolves [width] against [config] (or the defaults) to a tier.
AcousticBreakpointTier resolveAcousticTier(
  double width, {
  AcousticBreakpointConfig config = const AcousticBreakpointConfig(),
}) =>
    config.resolve(width);

/// How many panes side by side the caller wants, independent of the tier.
///
/// [AcousticSplitMode.adaptive] defers entirely to the tier's
/// [AcousticPanePlan]; every other value is an explicit multi-window /
/// split-mode request that is honoured as long as the panes fit.
enum AcousticSplitMode {
  /// Use the tier's pane plan (default).
  adaptive,

  /// Force a single pane.
  single,

  /// Force two side-by-side panes.
  dual,

  /// Force three side-by-side panes.
  triple,

  /// Force four side-by-side panes.
  quad,
}

/// Describes how panes are laid out for one [AcousticBreakpointTier].
class AcousticPanePlan {
  /// Preferred number of side-by-side panes at this tier.
  final int paneCount;

  /// Relative flex ratios per pane; recycled if [paneCount] exceeds the
  /// list length, truncated otherwise.
  final List<int> flexRatios;

  /// Minimum logical width a pane needs to remain side by side. Below this,
  /// panes are dropped (or the whole plan collapses to a vertical stack).
  final double minPaneWidth;

  /// Maximum logical width a single pane may occupy. Extra space is left
  /// unused so panes never stretch beyond a comfortable reading measure.
  final double maxPaneWidth;

  /// Gap between adjacent panes (width for rows, height for columns).
  final double gutter;

  /// Whether the layout may collapse into a vertical adaptive stack when a
  /// single pane cannot even reach [minPaneWidth].
  final bool collapseToStackBelowMin;

  const AcousticPanePlan({
    required this.paneCount,
    this.flexRatios = const [3, 2],
    this.minPaneWidth = 320,
    this.maxPaneWidth = double.infinity,
    this.gutter = 16,
    this.collapseToStackBelowMin = true,
  });

  /// Flex ratio for pane [index], recycling [flexRatios] when shorter than
  /// the pane count.
  int flexAt(int index) =>
      flexRatios.isEmpty ? 1 : flexRatios[index % flexRatios.length];
}

/// Per-tier pane plans plus the breakpoint table, forming the profile each
/// Infortts app passes to [AcousticAdaptiveStation].
class AcousticStationConfig {
  /// Width thresholds used to resolve the tier.
  final AcousticBreakpointConfig breakpoints;

  /// Pane plan per tier. Missing entries fall back to [defaultPanePlans].
  final Map<AcousticBreakpointTier, AcousticPanePlan> panePlans;

  const AcousticStationConfig({
    this.breakpoints = const AcousticBreakpointConfig(),
    this.panePlans = defaultPanePlans,
  });

  /// Infortts default profile:
  ///
  /// | Tier            | Panes | Flex      | Min pane | Gutter |
  /// |-----------------|-------|-----------|----------|--------|
  /// | phone           | 1     | [1]       | 0        | 0      |
  /// | tablet          | 1     | [1]       | 0        | 12     |
  /// | narrowDesktop   | 2     | [3, 2]    | 320      | 16     |
  /// | wideDesktop     | 3     | [3, 2, 2] | 280      | 16     |
  /// | ultrawide       | 4     | [3, 2, 2, 2] | 280  | 24     |
  static const Map<AcousticBreakpointTier, AcousticPanePlan> defaultPanePlans =
      {
    AcousticBreakpointTier.phone: AcousticPanePlan(
      paneCount: 1,
      flexRatios: [1],
      minPaneWidth: 0,
      gutter: 0,
      collapseToStackBelowMin: false,
    ),
    AcousticBreakpointTier.tablet: AcousticPanePlan(
      paneCount: 1,
      flexRatios: [1],
      minPaneWidth: 0,
      gutter: 12,
      collapseToStackBelowMin: false,
    ),
    AcousticBreakpointTier.narrowDesktop: AcousticPanePlan(
      paneCount: 2,
      flexRatios: [3, 2],
      minPaneWidth: 320,
      gutter: 16,
    ),
    AcousticBreakpointTier.wideDesktop: AcousticPanePlan(
      paneCount: 3,
      flexRatios: [3, 2, 2],
      minPaneWidth: 280,
      gutter: 16,
    ),
    AcousticBreakpointTier.ultrawide: AcousticPanePlan(
      paneCount: 4,
      flexRatios: [3, 2, 2, 2],
      minPaneWidth: 280,
      gutter: 24,
    ),
  };

  /// The pane plan for [tier], falling back to the Infortts default when the
  /// app profile does not override it.
  AcousticPanePlan planFor(AcousticBreakpointTier tier) =>
      panePlans[tier] ?? defaultPanePlans[tier]!;
}

/// The resolved pane geometry for a given width.
class AcousticPaneLayout {
  /// Whether panes run side by side ([Axis.horizontal]) or stacked
  /// ([Axis.vertical] adaptive stack).
  final Axis axis;

  /// Number of panes rendered at this width.
  final int paneCount;

  /// Flex (or weight) ratio per rendered pane.
  final List<int> flexRatios;

  /// Gap between adjacent panes.
  final double gutter;

  const AcousticPaneLayout({
    required this.axis,
    required this.paneCount,
    required this.flexRatios,
    required this.gutter,
  });
}

/// Resolves how [plan] renders at [availableWidth], honouring an explicit
/// [splitMode] request when one is made.
///
/// Panes that cannot reach [AcousticPanePlan.minPaneWidth] are dropped one
/// by one; when a single pane still cannot fit and the plan allows it, all
/// panes collapse into a vertical adaptive stack.
AcousticPaneLayout resolveAcousticPanes({
  required AcousticPanePlan plan,
  required double availableWidth,
  AcousticSplitMode splitMode = AcousticSplitMode.adaptive,
}) {
  final desired = switch (splitMode) {
    AcousticSplitMode.adaptive => plan.paneCount,
    AcousticSplitMode.single => 1,
    AcousticSplitMode.dual => 2,
    AcousticSplitMode.triple => 3,
    AcousticSplitMode.quad => 4,
  };

  bool fits(int n) =>
      n <= 1 ||
      availableWidth >= n * plan.minPaneWidth + (n - 1) * plan.gutter;

  var count = desired;
  while (count > 1 && !fits(count)) {
    count--;
  }

  if (count <= 1 &&
      plan.collapseToStackBelowMin &&
      availableWidth < plan.minPaneWidth) {
    // Adaptive stack: every requested pane stacked vertically.
    return AcousticPaneLayout(
      axis: Axis.vertical,
      paneCount: desired,
      flexRatios: List.generate(desired, plan.flexAt),
      gutter: plan.gutter,
    );
  }

  return AcousticPaneLayout(
    axis: Axis.horizontal,
    paneCount: count,
    flexRatios: List.generate(count, plan.flexAt),
    gutter: plan.gutter,
  );
}

/// Fixed per-pane widths for [layout], or `null` when plain flex (`Expanded`)
/// children already respect [maxPaneWidth].
///
/// Returns capped widths when any pane's flex share would exceed
/// [maxPaneWidth]; callers should lay the panes out start-aligned with the
/// layout [gutter] between them, leaving unused space at the end.
List<double>? computeAcousticPaneWidths({
  required AcousticPaneLayout layout,
  required double availableWidth,
  required double maxPaneWidth,
}) {
  if (layout.axis != Axis.horizontal || !maxPaneWidth.isFinite) return null;
  final gutterTotal = layout.gutter * (layout.paneCount - 1);
  final usable = availableWidth - gutterTotal;
  final totalFlex =
      layout.flexRatios.fold<int>(0, (sum, flex) => sum + flex);
  if (totalFlex <= 0 || usable <= 0) return null;
  final widths = layout.flexRatios
      .map((flex) => usable * flex / totalFlex)
      .toList(growable: false);
  if (widths.every((w) => w <= maxPaneWidth)) return null;
  return widths
      .map((w) => math.min(w, maxPaneWidth))
      .toList(growable: false);
}

/// AcousticAdaptiveStation: Responsive multi-surface container.
/// Seamlessly scales across Phone (compact < 600dp), Foldable / Tablet (medium 600-840dp),
/// and Desktop Mode 2.0 / External Monitors (expanded > 840dp), with narrow
/// desktop, wide desktop and ultrawide multi-window tiers above that.
///
/// The station is driven by an [AcousticStationConfig] profile so each Infortts
/// app can supply its own breakpoints and per-tier pane plans. Pass [panes]
/// for a true multi-pane layout resolved by [resolveAcousticPanes], or keep
/// the classic [body]/[sidePanel] pair and the station will route it through
/// the same tier resolver.
class AcousticAdaptiveStation extends StatelessWidget {
  final Widget body;
  final Widget? sidePanel;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final List<NavigationDestination> destinations;

  /// Breakpoint and pane-plan profile for this app. Defaults to
  /// [AcousticStationConfig.defaultPanePlans].
  final AcousticStationConfig config;

  /// Explicit multi-window / split-mode request. Defaults to
  /// [AcousticSplitMode.adaptive], which follows the tier's pane plan.
  final AcousticSplitMode splitMode;

  /// Optional explicit pane content. When non-empty, panes are laid out
  /// side by side (or stacked) per the resolved plan instead of the classic
  /// [body]/[sidePanel] pair.
  final List<Widget>? panes;

  const AcousticAdaptiveStation({
    super.key,
    required this.body,
    this.sidePanel,
    this.appBar,
    this.floatingActionButton,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.destinations = const [],
    this.config = const AcousticStationConfig(),
    this.splitMode = AcousticSplitMode.adaptive,
    this.panes,
  });

  Widget _destinationsRail({required bool allLabels}) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: allLabels
          ? NavigationRailLabelType.all
          : NavigationRailLabelType.selected,
      backgroundColor: AcousticColors.panelBg,
      destinations: destinations
          .map(
            (d) => NavigationRailDestination(
              icon: d.icon,
              selectedIcon: d.selectedIcon,
              label: Text(d.label),
            ),
          )
          .toList(),
    );
  }

  /// Builds the resolved pane row/column, honouring capped widths when
  /// [computeAcousticPaneWidths] applies.
  Widget _buildPanes(
    AcousticPaneLayout layout,
    AcousticPanePlan plan,
    double availableWidth,
  ) {
    final paneList = panes!;
    final widths = computeAcousticPaneWidths(
      layout: layout,
      availableWidth: availableWidth,
      maxPaneWidth: plan.maxPaneWidth,
    );

    final children = <Widget>[];
    for (var i = 0; i < layout.paneCount && i < paneList.length; i++) {
      if (i > 0) {
        children.add(
          layout.axis == Axis.horizontal
              ? SizedBox(width: layout.gutter)
              : SizedBox(height: layout.gutter),
        );
      }
      final pane = layout.axis == Axis.horizontal
          ? (widths != null
              ? SizedBox(width: widths[i], child: paneList[i])
              : Expanded(flex: layout.flexRatios[i], child: paneList[i]))
          : Expanded(flex: layout.flexRatios[i], child: paneList[i]);
      children.add(pane);
    }

    return layout.axis == Axis.horizontal
        ? Row(children: children)
        : Column(children: children);
  }

  Widget _panesBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tier = config.breakpoints.resolve(constraints.maxWidth);
        final plan = config.planFor(tier);
        final layout = resolveAcousticPanes(
          plan: plan,
          availableWidth: constraints.maxWidth,
          splitMode: splitMode,
        );
        Widget content = _buildPanes(layout, plan, constraints.maxWidth);
        if (destinations.isNotEmpty && tier != AcousticBreakpointTier.phone) {
          content = Row(
            children: [
              _destinationsRail(allLabels: tier == AcousticBreakpointTier.tablet),
              Expanded(child: content),
            ],
          );
        }
        return Scaffold(
          appBar: appBar,
          floatingActionButton: floatingActionButton,
          bottomNavigationBar:
              destinations.isNotEmpty && tier == AcousticBreakpointTier.phone
                  ? NavigationBar(
                      selectedIndex: selectedIndex,
                      onDestinationSelected: onDestinationSelected,
                      destinations: destinations,
                    )
                  : null,
          body: content,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (panes != null && panes!.isNotEmpty) {
      return _panesBody();
    }

    // LayoutBuilder-driven so window resizes re-resolve the tier at runtime.
    return LayoutBuilder(
      builder: (context, constraints) {
        final tier = config.breakpoints.resolve(constraints.maxWidth);
        return switch (tier) {
          AcousticBreakpointTier.narrowDesktop ||
          AcousticBreakpointTier.wideDesktop ||
          AcousticBreakpointTier.ultrawide =>
            _desktopBody(),
          AcousticBreakpointTier.tablet => _tabletBody(),
          AcousticBreakpointTier.phone => _phoneBody(),
        };
      },
    );
  }

  // Expanded / Desktop Mode 2.0 layout: Side Navigation Rail + Multi-pane split
  Widget _desktopBody() {
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          if (destinations.isNotEmpty) _destinationsRail(allLabels: false),
          Expanded(
            flex: sidePanel != null ? 3 : 1,
            child: body,
          ),
          if (sidePanel != null) ...[
            const VerticalDivider(width: 1, thickness: 1, color: Colors.white10),
            Expanded(
              flex: 2,
              child: sidePanel!,
            ),
          ],
        ],
      ),
    );
  }

  // Medium / Foldable layout: Side Navigation Rail + Body
  Widget _tabletBody() {
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          if (destinations.isNotEmpty) _destinationsRail(allLabels: true),
          Expanded(child: body),
        ],
      ),
    );
  }

  // Compact / Handheld Phone layout: Bottom Navigation Bar + Body
  Widget _phoneBody() {
    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: destinations.isNotEmpty
          ? NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: destinations,
            )
          : null,
    );
  }
}

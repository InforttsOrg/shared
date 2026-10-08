import 'package:flutter/material.dart';
import 'theme.dart';

/// AcousticAdaptiveStation: Responsive multi-surface container.
/// Seamlessly scales across Phone (compact < 600dp), Foldable / Tablet (medium 600-840dp),
/// and Desktop Mode 2.0 / External Monitors (expanded > 840dp).
class AcousticAdaptiveStation extends StatelessWidget {
  final Widget body;
  final Widget? sidePanel;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final List<NavigationDestination> destinations;

  const AcousticAdaptiveStation({
    super.key,
    required this.body,
    this.sidePanel,
    this.appBar,
    this.floatingActionButton,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.destinations = const [],
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktopMode = constraints.maxWidth >= 840;
        final isTabletMode = constraints.maxWidth >= 600 && constraints.maxWidth < 840;

        if (isDesktopMode) {
          // Expanded / Desktop Mode 2.0 layout: Side Navigation Rail + Multi-pane split
          return Scaffold(
            appBar: appBar,
            floatingActionButton: floatingActionButton,
            body: Row(
              children: [
                if (destinations.isNotEmpty)
                  NavigationRail(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: onDestinationSelected,
                    labelType: NavigationRailLabelType.selected,
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
                  ),
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
        } else if (isTabletMode) {
          // Medium / Foldable layout: Side Navigation Rail + Body
          return Scaffold(
            appBar: appBar,
            floatingActionButton: floatingActionButton,
            body: Row(
              children: [
                if (destinations.isNotEmpty)
                  NavigationRail(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: onDestinationSelected,
                    labelType: NavigationRailLabelType.all,
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
                  ),
                Expanded(child: body),
              ],
            ),
          );
        } else {
          // Compact / Handheld Phone layout: Bottom Navigation Bar + Body
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
      },
    );
  }
}

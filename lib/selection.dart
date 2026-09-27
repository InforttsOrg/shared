import 'package:flutter/material.dart';

/// A wrapper component that enforces native, high-performance text selectability
/// across all Infortts™ frontends, fully aligning with Dart's tactile data-accessibility principles.
class AcousticSelection extends StatelessWidget {
  final Widget child;

  const AcousticSelection({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (Overlay.maybeOf(context) == null) {
      return child;
    }
    return SelectionArea(
      child: child,
    );
  }
}

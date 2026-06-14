import 'package:flutter/material.dart';
import 'theme.dart';

/// The official "by Infortts™" watermark / badge widget.
/// Used to maintain consistent trademark branding across all Flutter/Dart frontends.
class InforttsWatermark extends StatelessWidget {
  final bool isDark;
  final double size;

  const InforttsWatermark({
    super.key,
    this.isDark = true,
    this.size = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'BY ',
          style: TextStyle(
            color: isDark ? AcousticColors.midGray : Colors.black38,
            fontSize: size * 0.8,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          'INFORTTS',
          style: TextStyle(
            color: isDark ? AcousticColors.titanium : Colors.black87,
            fontSize: size,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        Text(
          '™',
          style: TextStyle(
            color: AcousticColors.sonarCyan,
            fontSize: size * 0.8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

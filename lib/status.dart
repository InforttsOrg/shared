import 'package:flutter/material.dart';
import 'theme.dart';

enum AcousticStatus { active, idle, warning }

/// A high-performance, looping, animated status indicator widget.
/// Simulates motivated practical glowing status LED diodes inside spacecraft corridors.
class AcousticStatusIndicator extends StatefulWidget {
  final AcousticStatus status;
  final double size;

  const AcousticStatusIndicator({
    super.key,
    this.status = AcousticStatus.active,
    this.size = 8.0,
  });

  @override
  State<AcousticStatusIndicator> createState() => _AcousticStatusIndicatorState();
}

class _AcousticStatusIndicatorState extends State<AcousticStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.85, end: 0.35).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    switch (widget.status) {
      case AcousticStatus.active:
        return AcousticColors.sonarCyan;
      case AcousticStatus.idle:
        return AcousticColors.midGray;
      case AcousticStatus.warning:
        return AcousticColors.warnOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color,
                    blurRadius: 8.0,
                  ),
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 18.0,
                    spreadRadius: 2.0,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

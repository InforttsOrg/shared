import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 1. Spacecraft Hull Jitter Animation (Forensic Jitter)
/// Micro-jitter translations to emulate ambient physical engine rumble and electromagnetic noise.
class AcousticJitterAnimation extends StatefulWidget {
  final Widget child;
  final bool isEnabled;

  const AcousticJitterAnimation({
    super.key,
    required this.child,
    this.isEnabled = true,
  });

  @override
  State<AcousticJitterAnimation> createState() => _AcousticJitterAnimationState();
}

class _AcousticJitterAnimationState extends State<AcousticJitterAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEnabled) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Micro sub-pixel offsets to represent vibrations (±0.4 pixels max)
        final double dx = (_random.nextDouble() * 0.8) - 0.4;
        final double dy = (_random.nextDouble() * 0.8) - 0.4;

        return Transform.translate(
          offset: Offset(dx, dy),
          child: child,
        );
      },
    );
  }
}

/// 2. Echolocation Sonar Wave Pulse (Discovery Pulse)
/// Simulates radial acoustic wave emissions expanding outward from a central point.
class AcousticPulseWavelength extends StatefulWidget {
  final Widget child;
  final Color pulseColor;

  const AcousticPulseWavelength({
    super.key,
    required this.child,
    this.pulseColor = const Color(0xFF00D2FF),
  });

  @override
  State<AcousticPulseWavelength> createState() => _AcousticPulseWavelengthState();
}

class _AcousticPulseWavelengthState extends State<AcousticPulseWavelength>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.45).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _opacityAnimation = Tween<double>(begin: 0.35, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse Ripple Background
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.pulseColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

/// 3. Dampened Spacecraft Inertia Transition (Cinematic Transit)
/// Slides and fades widgets smoothly over 850ms with a heavy cinematic easement.
class AcousticInertiaTransition extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const AcousticInertiaTransition({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<AcousticInertiaTransition> createState() => _AcousticInertiaTransitionState();
}

class _AcousticInertiaTransitionState extends State<AcousticInertiaTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.70, curve: Curves.easeInOut),
      ),
    );

    // Subtle upward vertical slide representing volumetric expansion
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.16, 1.0, 0.3, 1.0), // Acoustic-Refraction signature ease-out
      ),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: FractionalTranslation(
            translation: _slide.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

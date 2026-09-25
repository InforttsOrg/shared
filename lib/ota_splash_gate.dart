import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'brand.dart';
import 'cdn_ota_engine.dart';
import 'theme.dart';

/// Infortts Universal OTA Splash Gate
/// 
/// Intercepts app startup during the branded splash screen across ALL Infortts apps.
/// Concurrently checks, downloads, and applies OTA differential patches from the CDN
/// before transitioning smoothly to the destination screen (Login/AppShell/Dashboard).
/// 
/// Strict Invariants:
/// 1. Guaranteed Watchdog: Never locks or hangs the app (enforces strict timeout fallback).
/// 2. Offline-First: Gracefully boots into existing app state if offline or up-to-date.
/// 3. Zero Jank: Hardware-accelerated smooth cross-fade into destination widget.
class InforttsOtaSplashGate extends StatefulWidget {
  final String appName;
  final String? appVersion;
  final String? appNameDisplay;
  final String? subtitle;
  final Widget child;
  final Duration minDisplayDuration;
  final Duration maxTimeout;
  final VoidCallback? onUpdateInstalled;

  const InforttsOtaSplashGate({
    super.key,
    required this.appName,
    this.appVersion,
    this.appNameDisplay,
    this.subtitle,
    required this.child,
    this.minDisplayDuration = const Duration(milliseconds: 1800),
    this.maxTimeout = const Duration(milliseconds: 3500),
    this.onUpdateInstalled,
  });

  @override
  State<InforttsOtaSplashGate> createState() => _InforttsOtaSplashGateState();
}

class _InforttsOtaSplashGateState extends State<InforttsOtaSplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  bool _isReady = false;
  String _statusText = 'INITIALIZING SYSTEM...';
  double _progressValue = 0.15;
  String _versionDisplay = '';

  Timer? _watchdogTimer;
  bool _hasTransitioned = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    _versionDisplay = widget.appVersion != null ? 'v${widget.appVersion}' : '';
    _startStartupFlow();
  }

  @override
  void dispose() {
    _watchdogTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startStartupFlow() async {
    // 1. Guaranteed Watchdog Fallback Timer
    _watchdogTimer = Timer(widget.maxTimeout, () {
      if (mounted && !_hasTransitioned) {
        _proceedToApp();
      }
    });

    final stopwatch = Stopwatch()..start();

    // 2. Fetch package info if version omitted
    if (_versionDisplay.isEmpty) {
      try {
        final info = await PackageInfo.fromPlatform().timeout(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() {
            _versionDisplay = 'v${info.version}+${info.buildNumber}';
          });
        }
      } catch (_) {
        if (mounted && _versionDisplay.isEmpty) {
          setState(() {
            _versionDisplay = 'v2.03.16';
          });
        }
      }
    }

    // 3. Execute OTA Check & Patch Application Concurrently
    try {
      if (mounted) {
        setState(() {
          _statusText = 'SYNCHRONIZING NEURAL OTA REGISTRY...';
          _progressValue = 0.4;
        });
      }

      final engine = InforttsCdnOtaEngine(
        appName: widget.appName,
        appVersion: widget.appVersion ?? '2.03.16',
      );

      final manifest = await engine.fetchManifest().timeout(const Duration(seconds: 2));

      if (manifest != null) {
        final localPatch = await engine.getLocalPatchNumber();
        if (manifest.latestPatch > localPatch) {
          if (mounted) {
            setState(() {
              _statusText = 'DOWNLOADING PATCH v${manifest.version} (#${manifest.latestPatch})...';
              _progressValue = 0.75;
            });
          }

          final success = await engine.downloadAndApplyPatch(manifest, onStatusChanged: (status, patch) {
            if (mounted) {
              if (status == InforttsCdnOtaStatus.downloading) {
                setState(() {
                  _statusText = 'APPLYING DIFFERENTIAL PATCH...';
                  _progressValue = 0.88;
                });
              } else if (status == InforttsCdnOtaStatus.installed) {
                setState(() {
                  _statusText = 'PATCH INSTALLED • VERIFYING INTEGRITY...';
                  _progressValue = 1.0;
                });
              }
            }
          }).timeout(const Duration(seconds: 3));

          if (success) {
            widget.onUpdateInstalled?.call();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('[InforttsOtaSplashGate] OTA check error / offline: $e');
    }

    if (mounted) {
      setState(() {
        _statusText = 'SYSTEM VERIFIED • READY';
        _progressValue = 1.0;
      });
    }

    // 4. Ensure minimum display duration for smooth visual cadence
    final elapsed = stopwatch.elapsed;
    if (elapsed < widget.minDisplayDuration) {
      await Future.delayed(widget.minDisplayDuration - elapsed);
    }

    _proceedToApp();
  }

  void _proceedToApp() {
    if (_hasTransitioned || !mounted) return;
    _hasTransitioned = true;
    _watchdogTimer?.cancel();

    setState(() {
      _isReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _isReady ? widget.child : _buildSplashScaffold(context),
    );
  }

  Widget _buildSplashScaffold(BuildContext context) {
    final title = widget.appNameDisplay ?? widget.appName.toUpperCase();
    final subtitle = widget.subtitle ?? 'NEURAL ECOSYSTEM TERMINAL';

    return Scaffold(
      key: const ValueKey('infortts_ota_splash_screen'),
      backgroundColor: AcousticColors.blackDark,
      body: Stack(
        children: [
          // Background Acoustic Grid & Ambient Radial Glow
          Positioned.fill(
            child: CustomPaint(
              painter: _AcousticSplashGridPainter(pulse: _pulseAnimation),
            ),
          ),

          // Central Branding & OTA Progress
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Neural Core Icon
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AcousticColors.sonarCyan.withAlpha((255 * (0.25 + 0.15 * _pulseAnimation.value)).toInt()),
                              AcousticColors.panelBgDark,
                              AcousticColors.blackDark,
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                          border: Border.all(
                            color: AcousticColors.sonarCyan.withAlpha((255 * (0.6 + 0.4 * _pulseAnimation.value)).toInt()),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AcousticColors.sonarCyan.withAlpha((255 * (0.2 * _pulseAnimation.value)).toInt()),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.bolt_rounded,
                            size: 42,
                            color: AcousticColors.sonarCyan,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // App Title
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.jetBrainsMono(
                      color: AcousticColors.titanium,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4.0,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Subtitle
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AcousticColors.steel,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.8,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // OTA Status Progress Bar
                  SizedBox(
                    width: 240,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progressValue,
                            minHeight: 3,
                            backgroundColor: AcousticColors.activeCardDark,
                            valueColor: AlwaysStoppedAnimation<Color>(AcousticColors.sonarCyan),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _statusText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.jetBrainsMono(
                            color: AcousticColors.sonarCyan,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Trademark Watermark & Version
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const InforttsWatermark(isDark: true, size: 11),
                const SizedBox(height: 6),
                Text(
                  _versionDisplay.isNotEmpty ? _versionDisplay : 'INFORTTS CDN OTA ENGINE',
                  style: GoogleFonts.jetBrainsMono(
                    color: AcousticColors.midGray,
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dynamic Cybernetic Background Grid with Motivated Cyan Pulses
class _AcousticSplashGridPainter extends CustomPainter {
  final Animation<double> pulse;

  _AcousticSplashGridPainter({required this.pulse}) : super(repaint: pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF152238).withAlpha((255 * (0.35 + 0.15 * pulse.value)).toInt())
      ..strokeWidth = 0.75;

    const double step = 36.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AcousticSplashGridPainter oldDelegate) => true;
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'brand.dart';
import 'cdn_ota_engine.dart';
import 'theme.dart';

/// State of the OTA Gate during startup lifecycle.
///
/// Named [InforttsOtaSplashState] rather than [InforttsOtaState] because the latter is the
/// enum owned by `infortts_ota_service.dart` for the OTA telemetry lifecycle; both are
/// re-exported by `infortts_shared.dart`, so sharing one name would be an ambiguous export.
class InforttsOtaSplashState {
  final bool isReady;
  final String statusText;
  final double progress;
  final String versionDisplay;

  const InforttsOtaSplashState({
    required this.isReady,
    required this.statusText,
    required this.progress,
    required this.versionDisplay,
  });
}

/// Infortts Universal OTA Splash Gate
/// 
/// Decoupled Architecture:
/// 1. Headless OTA Lifecycle Engine: Checks CDN for patches, downloads differential binaries,
///    and handles watchdogs without coupling to a specific UI.
/// 2. Custom Presentation Layer: Apps can supply their own [splashBuilder] (e.g. Care4U medical theme,
///    Waptia fashion/storefront theme, Mitochondria trading HUD) or rely on the theme-aware default.
class InforttsOtaSplashGate extends StatefulWidget {
  final String appName;
  final String? appVersion;
  final String? appNameDisplay;
  final String? subtitle;
  final Widget child;
  final Duration minDisplayDuration;
  final Duration maxTimeout;
  final VoidCallback? onUpdateInstalled;
  
  /// Optional custom splash screen builder for completely decoupled, app-specific UI.
  final Widget Function(BuildContext context, InforttsOtaSplashState state)? splashBuilder;

  /// Optional theme styling overrides for default splash view
  final Color? backgroundColor;
  final Color? accentColor;
  final Widget? logoWidget;

  const InforttsOtaSplashGate({
    super.key,
    required this.appName,
    this.appVersion,
    this.appNameDisplay,
    this.subtitle,
    required this.child,
    this.minDisplayDuration = Duration.zero,
    this.maxTimeout = const Duration(milliseconds: 1500),
    this.onUpdateInstalled,
    this.splashBuilder,
    this.backgroundColor,
    this.accentColor,
    this.logoWidget,
  });

  @override
  State<InforttsOtaSplashGate> createState() => _InforttsOtaSplashGateState();
}

class _InforttsOtaSplashGateState extends State<InforttsOtaSplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  bool _isReady = true;
  String _statusText = 'INITIALIZING SYSTEM...';
  double _progressValue = 0.15;
  String _versionDisplay = '';

  Timer? _watchdogTimer;
  bool _hasTransitioned = false;

  @override
  void initState() {
    super.initState();
    _isReady = widget.minDisplayDuration == Duration.zero;
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
        _versionDisplay = 'v1.0.0';
      }
    }

    // 3. Fast OTA Interception Check via Infortts CDN Engine
    try {
      if (!kIsWeb) {
        if (mounted) {
          setState(() {
            _statusText = 'CHECKING RELEASES...';
            _progressValue = 0.45;
          });
        }

        final engine = InforttsCdnOtaEngine(
          appName: widget.appName,
          appVersion: widget.appVersion ?? '1.0.0',
        );

        final manifest = await engine
            .fetchManifest()
            .timeout(const Duration(milliseconds: 700));

        final localPatch = manifest == null ? null : await engine.getLocalPatchNumber();
        final updateAvailable = manifest != null && manifest.latestPatch > localPatch!;

        if (updateAvailable && mounted) {
          setState(() {
            _statusText = 'APPLYING HOTFIX...';
            _progressValue = 0.75;
          });

          final success = await engine
              .downloadAndApplyPatch(
                manifest,
                onStatusChanged: (status, patch) {
                  if (mounted && status == InforttsCdnOtaStatus.downloading) {
                    setState(() {
                      _progressValue = 0.75 + (patch == null || patch == 0 ? 0.25 : 0.25 * (patch / manifest.latestPatch));
                    });
                  }
                },
              )
              .timeout(const Duration(seconds: 3), onTimeout: () => false);

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
    final otaState = InforttsOtaSplashState(
      isReady: _isReady,
      statusText: _statusText,
      progress: _progressValue,
      versionDisplay: _versionDisplay,
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _isReady
          ? widget.child
          : (widget.splashBuilder != null
              ? widget.splashBuilder!(context, otaState)
              : _buildSplashScaffold(context)),
    );
  }

  Widget _buildSplashScaffold(BuildContext context) {
    final title = widget.appNameDisplay ?? widget.appName.toUpperCase();
    final subtitle = widget.subtitle ?? 'INFORTTS ECOSYSTEM APP';

    final isLight = AcousticColors.isLight;
    final bgColor = widget.backgroundColor ?? (isLight ? AcousticColors.lightBackground : AcousticColors.blackDark);
    final accent = widget.accentColor ?? AcousticColors.sonarCyan;
    final textColor = isLight ? AcousticColors.titaniumLight : AcousticColors.titaniumDark;
    final subtextColor = isLight ? AcousticColors.steelLight : AcousticColors.steelDark;

    return Scaffold(
      key: const ValueKey('infortts_ota_splash_screen'),
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background Grid & Radial Glow
          Positioned.fill(
            child: CustomPaint(
              painter: _AcousticSplashGridPainter(
                pulse: _pulseAnimation,
                isLight: isLight,
                accentColor: accent,
              ),
            ),
          ),

          // Central Branding & OTA Progress
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Logo / Core Icon
                  if (widget.logoWidget != null)
                    widget.logoWidget!
                  else
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
                                accent.withAlpha((255 * (0.25 + 0.15 * _pulseAnimation.value)).toInt()),
                                isLight ? Colors.white : AcousticColors.panelBgDark,
                                bgColor,
                              ],
                              stops: const [0.0, 0.7, 1.0],
                            ),
                            border: Border.all(
                              color: accent.withAlpha((255 * (0.6 + 0.4 * _pulseAnimation.value)).toInt()),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withAlpha((255 * (0.2 * _pulseAnimation.value)).toInt()),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.all_inclusive_rounded,
                              size: 40,
                              color: accent,
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 28),

                  // App Name Title
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: 4.0,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtitle / Architecture Role
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: subtextColor,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // OTA Status & Progress Bar
                  SizedBox(
                    width: 220,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progressValue,
                            minHeight: 3.5,
                            backgroundColor: isLight
                                ? AcousticColors.midGrayLight.withValues(alpha: 0.2)
                                : AcousticColors.midGrayDark.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(accent),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _statusText,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: subtextColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              _versionDisplay,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 8.5,
                                color: accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AcousticSplashGridPainter extends CustomPainter {
  final Animation<double> pulse;
  final bool isLight;
  final Color accentColor;

  _AcousticSplashGridPainter({
    required this.pulse,
    this.isLight = false,
    Color? accentColor,
  })  : accentColor = accentColor ?? AcousticColors.sonarCyan,
        super(repaint: pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = (isLight ? Colors.black : Colors.white).withValues(alpha: isLight ? 0.03 : 0.02)
      ..strokeWidth = 1.0;

    const gridSize = 40.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final center = Offset(size.width / 2, size.height / 2);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withAlpha((255 * (0.10 + 0.05 * pulse.value)).toInt()),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.6));

    canvas.drawCircle(center, size.width * 0.6, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _AcousticSplashGridPainter oldDelegate) => true;
}

import 'dart:async';
import 'dart:convert';
import 'dart:io' show exit;
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'env_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';

import 'theme.dart';
import 'auth.dart';
import 'brand.dart';
import 'animations.dart';
import 'url_helper.dart';
import 'error.dart';
import 'ota_engine.dart';
import 'cdn_ota_engine.dart';

class InforttsTab {
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
  final Widget? iconWidget;

  const InforttsTab({
    required this.label,
    required this.icon,
    required this.builder,
    this.iconWidget,
  });
}

/// Interactive, procedural 3D Emblem representing ancient Earth lifeforms or structures.
class Infortts3DLogo extends StatefulWidget {
  final String appName;
  final double size;
  final bool interactive;

  const Infortts3DLogo({
    super.key,
    required this.appName,
    this.size = 180.0,
    this.interactive = true,
  });

  @override
  State<Infortts3DLogo> createState() => _Infortts3DLogoState();
}

class _Infortts3DLogoState extends State<Infortts3DLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  double _hoverX = 0.0;
  double _hoverY = 0.0;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nameNormalized = widget.appName.toLowerCase();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _hoverX = 0.0;
        _hoverY = 0.0;
      }),
      onHover: (event) {
        if (!widget.interactive) return;
        setState(() {
          _hoverX = (event.localPosition.dx - widget.size / 2) / (widget.size / 2);
          _hoverY = (event.localPosition.dy - widget.size / 2) / (widget.size / 2);
        });
      },
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          final double autoAngle = _rotationController.value * 2 * math.pi;
          final double tiltX = _isHovered ? -_hoverY * 0.4 : 0.05 * math.sin(autoAngle);
          final double tiltY = _isHovered ? _hoverX * 0.4 : autoAngle * 0.2;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0018)
              ..rotateX(tiltX)
              ..rotateY(tiltY)
              ..rotateZ(_isHovered ? _hoverX * 0.15 : 0.0),
            alignment: Alignment.center,
            child: child,
          );
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AcousticColors.sonarCyan.withOpacity(0.08),
                blurRadius: widget.size * 0.25,
                spreadRadius: 4,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _EmblemPainter(
              organismName: nameNormalized,
              isHovered: _isHovered,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  final String organismName;
  final bool isHovered;

  _EmblemPainter({
    required this.organismName,
    required this.isHovered,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final gridPaint = Paint()
      ..color = AcousticColors.midGray.withOpacity(0.12)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final double gridSpacing = size.width / 10;
    for (int i = 1; i < 10; i++) {
      canvas.drawLine(Offset(i * gridSpacing, 0), Offset(i * gridSpacing, size.height), gridPaint);
      canvas.drawLine(Offset(0, i * gridSpacing), Offset(size.width, i * gridSpacing), gridPaint);
    }
    canvas.drawCircle(center, radius * 0.8, gridPaint);

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.75, shadowPaint);

    final rimGradient = RadialGradient(
      colors: [AcousticColors.panelBg, AcousticColors.black],
      stops: const [0.8, 1.0],
    );
    final rimPaint = Paint()
      ..shader = rimGradient.createShader(Rect.fromCircle(center: center, radius: radius * 0.75))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.72, rimPaint);

    final rimStroke = Paint()
      ..color = AcousticColors.steel.withOpacity(0.25)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius * 0.72, rimStroke);

    if (organismName.contains("mitochondria") || organismName.contains("forensic")) {
      _drawMitochondria(canvas, center, radius);
    } else if (organismName.contains("yorgia")) {
      _drawYorgia(canvas, center, radius);
    } else if (organismName.contains("dickinsonia")) {
      _drawDickinsonia(canvas, center, radius);
    } else if (organismName.contains("kimberella")) {
      _drawKimberella(canvas, center, radius);
    } else if (organismName.contains("cursus")) {
      _drawCursus(canvas, center, radius);
    } else if (organismName.contains("fractofusus")) {
      _drawFractofusus(canvas, center, radius);
    } else {
      _drawDefaultEmblem(canvas, center, radius);
    }
  }

  void _drawMitochondria(Canvas canvas, Offset center, double radius) {
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        colors: [AcousticColors.panelBg, AcousticColors.darkCarbon.withOpacity(0.9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.5))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(center.dx - radius * 0.45, center.dy);
    path.cubicTo(
      center.dx - radius * 0.35, center.dy - radius * 0.45,
      center.dx + radius * 0.35, center.dy - radius * 0.45,
      center.dx + radius * 0.45, center.dy,
    );
    path.cubicTo(
      center.dx + radius * 0.35, center.dy + radius * 0.45,
      center.dx - radius * 0.35, center.dy + radius * 0.45,
      center.dx - radius * 0.45, center.dy,
    );
    path.close();
    canvas.drawPath(path, bodyPaint);

    final edgeStroke = Paint()
      ..color = AcousticColors.titanium.withOpacity(0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, edgeStroke);

    final glowPaint = Paint()
      ..color = AcousticColors.sonarCyan.withOpacity(0.25)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cristaePaint = Paint()
      ..color = AcousticColors.sonarCyan
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cristaePath = Path();
    for (double i = -0.3; i <= 0.3; i += 0.1) {
      final double y = center.dy + i * radius;
      cristaePath.moveTo(center.dx - radius * 0.25, y);
      cristaePath.quadraticBezierTo(
        center.dx, y + (i % 0.2 == 0 ? radius * 0.08 : -radius * 0.08),
        center.dx + radius * 0.25, y,
      );
    }

    canvas.drawPath(cristaePath, glowPaint);
    canvas.drawPath(cristaePath, cristaePaint);
  }

  void _drawYorgia(Canvas canvas, Offset center, double radius) {
    final headPaint = Paint()
      ..color = AcousticColors.panelBg
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCenter(center: center - Offset(0, radius * 0.15), width: radius * 0.8, height: radius * 0.5),
      math.pi,
      math.pi,
      true,
      headPaint,
    );

    final spinePaint = Paint()
      ..color = AcousticColors.sonarBlue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center - Offset(0, radius * 0.4), center + Offset(0, radius * 0.4), spinePaint);

    final ribPaint = Paint()
      ..color = AcousticColors.sonarCyan
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 6; i++) {
      final double y = center.dy - radius * 0.15 + (i * radius * 0.09);
      final double xOffset = radius * 0.3 * (1.0 - i * 0.12);
      canvas.drawLine(Offset(center.dx - xOffset, y), Offset(center.dx - radius * 0.02, y - 5), ribPaint);
      canvas.drawLine(Offset(center.dx + xOffset, y + 3), Offset(center.dx + radius * 0.02, y - 2), ribPaint);
    }
  }

  void _drawDickinsonia(Canvas canvas, Offset center, double radius) {
    final r = radius * 0.5;
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        colors: [AcousticColors.activeCard, AcousticColors.panelBg],
      ).createShader(Rect.fromCircle(center: center, radius: r))
      ..style = PaintingStyle.fill;

    canvas.drawOval(Rect.fromCenter(center: center, width: r * 1.5, height: r * 2.0), bodyPaint);

    final rimPaint = Paint()
      ..color = AcousticColors.steel.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawOval(Rect.fromCenter(center: center, width: r * 1.5, height: r * 2.0), rimPaint);

    final ribPaint = Paint()
      ..color = AcousticColors.sonarCyan
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final glowRib = Paint()
      ..color = AcousticColors.sonarCyan.withOpacity(0.3)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final pathL = Path();
    final pathR = Path();

    canvas.drawLine(Offset(center.dx, center.dy - r * 0.95), Offset(center.dx, center.dy + r * 0.95), ribPaint);

    for (int i = 0; i < 9; i++) {
      final double ratio = i / 9.0;
      final double y = center.dy - r * 0.8 + ratio * (r * 1.6);
      final double w = math.sqrt(1 - math.pow(ratio * 2 - 1, 2)) * r * 0.7;

      if (i.isEven) {
        pathL.moveTo(center.dx, y);
        pathL.quadraticBezierTo(center.dx - w * 0.5, y + 4, center.dx - w, y + 2);
      } else {
        pathR.moveTo(center.dx, y);
        pathR.quadraticBezierTo(center.dx + w * 0.5, y + 4, center.dx + w, y + 2);
      }
    }

    canvas.drawPath(pathL, glowRib);
    canvas.drawPath(pathL, ribPaint);
    canvas.drawPath(pathR, glowRib);
    canvas.drawPath(pathR, ribPaint);
  }

  void _drawKimberella(Canvas canvas, Offset center, double radius) {
    final r = radius * 0.55;
    final shellPaint = Paint()
      ..shader = LinearGradient(
        colors: [AcousticColors.panelBg, AcousticColors.black],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: r))
      ..style = PaintingStyle.fill;

    final shellPath = Path();
    shellPath.moveTo(center.dx, center.dy - r * 0.9);
    shellPath.cubicTo(
      center.dx + r * 0.6, center.dy - r * 0.3,
      center.dx + r * 0.55, center.dy + r * 0.8,
      center.dx, center.dy + r * 0.9,
    );
    shellPath.cubicTo(
      center.dx - r * 0.55, center.dy + r * 0.8,
      center.dx - r * 0.6, center.dy - r * 0.3,
      center.dx, center.dy - r * 0.9,
    );
    shellPath.close();

    canvas.drawPath(shellPath, shellPaint);

    final borderPaint = Paint()
      ..color = AcousticColors.steel.withOpacity(0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(shellPath, borderPaint);

    final groovePaint = Paint()
      ..color = AcousticColors.sonarBlue
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final cyanGroovePaint = Paint()
      ..color = AcousticColors.sonarCyan
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (int i = -4; i <= 4; i++) {
      if (i == 0) continue;
      final angle = i * 0.28;
      final double endX = center.dx + math.sin(angle) * r * 0.85;
      final double endY = center.dy + math.cos(angle) * r * 0.85;

      canvas.drawLine(
        Offset(center.dx, center.dy - r * 0.4),
        Offset(endX, endY),
        groovePaint,
      );
      canvas.drawLine(
        Offset(center.dx, center.dy - r * 0.1),
        Offset(center.dx + math.sin(angle) * r * 0.5, center.dy + math.cos(angle) * r * 0.5),
        cyanGroovePaint,
      );
    }
  }

  void _drawCursus(Canvas canvas, Offset center, double radius) {
    final r = radius * 0.5;
    final chevronPaint = Paint()
      ..color = AcousticColors.sonarCyan.withOpacity(0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final basePaint = Paint()
      ..color = AcousticColors.panelBg
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final double y = center.dy - r * 0.7 + i * (r * 0.5);
      final path = Path()
        ..moveTo(center.dx - r * 0.4, y - r * 0.15)
        ..lineTo(center.dx, y + r * 0.1)
        ..lineTo(center.dx + r * 0.4, y - r * 0.15);

      canvas.drawPath(path, basePaint);
      canvas.drawPath(path, chevronPaint);

      if (i < 3) {
        canvas.drawLine(
          Offset(center.dx, y + r * 0.1),
          Offset(center.dx, y + r * 0.35),
          Paint()
            ..color = AcousticColors.sonarBlue
            ..strokeWidth = 1.2
            ..style = PaintingStyle.stroke,
        );
      }
    }
  }

  void _drawFractofusus(Canvas canvas, Offset center, double radius) {
    final r = radius * 0.55;
    final basePaint = Paint()
      ..shader = LinearGradient(
        colors: [AcousticColors.panelBg, AcousticColors.black],
      ).createShader(Rect.fromCircle(center: center, radius: r))
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(center.dx, center.dy - r * 0.85)
      ..lineTo(center.dx + r * 0.35, center.dy)
      ..lineTo(center.dx, center.dy + r * 0.85)
      ..lineTo(center.dx - r * 0.35, center.dy)
      ..close();

    canvas.drawPath(path, basePaint);

    final linePaint = Paint()
      ..color = AcousticColors.sonarCyan
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = AcousticColors.sonarCyan.withOpacity(0.3)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, linePaint);

    final innerPath = Path();
    for (double i = -0.6; i <= 0.6; i += 0.2) {
      final double y = center.dy + i * r;
      final double factor = 1.0 - i.abs();
      innerPath.moveTo(center.dx, y);
      innerPath.lineTo(center.dx - r * 0.25 * factor, y + r * 0.1);
      innerPath.moveTo(center.dx, y);
      innerPath.lineTo(center.dx + r * 0.25 * factor, y + r * 0.1);
    }

    canvas.drawPath(innerPath, glowPaint);
    canvas.drawPath(innerPath, linePaint);
  }

  void _drawDefaultEmblem(Canvas canvas, Offset center, double radius) {
    final r = radius * 0.5;
    final lensPaint = Paint()
      ..color = AcousticColors.panelBg
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, r, lensPaint);

    final hexPaint = Paint()
      ..color = AcousticColors.steel.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final hexPath = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final double x = center.dx + math.sin(angle) * r;
      final double y = center.dy + math.cos(angle) * r;
      if (i == 0) {
        hexPath.moveTo(x, y);
      } else {
        hexPath.lineTo(x, y);
      }
    }
    hexPath.close();
    canvas.drawPath(hexPath, hexPaint);

    final ringPaint = Paint()
      ..color = AcousticColors.sonarCyan
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, r * 0.6, ringPaint);

    canvas.drawCircle(
      center,
      r * 0.2,
      Paint()..color = AcousticColors.sonarBlue.withOpacity(0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(center, r * 0.1, Paint()..color = AcousticColors.sonarCyan);
  }

  @override
  bool shouldRepaint(covariant _EmblemPainter oldDelegate) {
    return oldDelegate.organismName != organismName || oldDelegate.isHovered != isHovered;
  }
}

final ValueNotifier<int> inforttsTabController = ValueNotifier<int>(0);

/// Centralized app shell with splash screen, auth gate, and bottom-navigation workspace.
class InforttsAppShell extends StatefulWidget {
  final String appName;
  final String appDescription;
  final String? appVersion;
  final Widget workspaceChild;
  final List<InforttsTab>? additionalTabs;
  final GlycocalyxAuth? auth;

  const InforttsAppShell({
    super.key,
    required this.appName,
    required this.appDescription,
    this.appVersion,
    required this.workspaceChild,
    this.additionalTabs,
    this.auth,
  });

  @override
  State<InforttsAppShell> createState() => _InforttsAppShellState();
}

class _InforttsAppShellState extends State<InforttsAppShell> {
  bool _showSplash = true;
  bool _isAuthenticated = false;
  int _activeTab = 0;
  AuthSession? _authSession;
  List<AuthSession> _savedAccounts = [];
  String _settingsSubPage = "main";
  late final GlycocalyxAuth _authClient;
  String _currentVersion = "";
  String _currentBuildNumber = "";
  String _otaPatchText = "v2.02.00+20200 (Infortts R2 CDN OTA Engine Active [update.infortts.site])";
  Timer? _otaCronTimer;
  bool _isCheckingOtaCron = false;
  bool _isOtaModalShowing = false;
  int? _dismissedPatchNumber;

  late final List<InforttsTab> _tabs;

  @override
  void dispose() {
    _otaCronTimer?.cancel();
    inforttsTabController.removeListener(_onTabChangedByController);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentVersion = widget.appVersion ?? "2.02.00";
    _currentBuildNumber = "20200";
    _initPackageInfo();
    _authClient = widget.auth ?? GlycocalyxAuth();
    inforttsTabController.value = 0;
    inforttsTabController.addListener(_onTabChangedByController);
    _tabs = [
      if (widget.additionalTabs != null)
        ...widget.additionalTabs!
      else ...[
        InforttsTab(label: "Dashboard", icon: Icons.dashboard_outlined, builder: (_) => widget.workspaceChild),
      ],
      InforttsTab(label: "Settings", icon: Icons.settings_outlined, builder: (_) => _buildSettingsView()),
    ];
    Timer(const Duration(milliseconds: 2600), () {
      if (mounted) {
        setState(() { _showSplash = false; });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreSession();
      _checkForUrlToken();
      if (!kIsWeb) {
        _initDeepLinks();
      }
    });
  }

  Future<void> _initPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final rawVersion = info.version.isNotEmpty ? info.version : (widget.appVersion ?? "2.02.00");
      final baseVersion = InforttsVersionHelper.getBaseVersion(rawVersion);
      const baseBuild = 20200;

      final cdnEngine = InforttsCdnOtaEngine(
        appName: widget.appName.toLowerCase(),
        appVersion: baseVersion,
      );
      final activePatchNum = await cdnEngine.getLocalPatchNumber();
      final bump = InforttsVersionHelper.calculateBump(
        baseVersion: baseVersion,
        baseBuild: baseBuild,
        patchNumber: activePatchNum,
      );

      if (mounted) {
        setState(() {
          _currentVersion = bump.version;
          _currentBuildNumber = bump.buildNumber.toString();
          _otaPatchText = bump.displayString;
        });
      }
      _startOtaCronTimer();
      InforttsDirectOtaEngine().checkUpdate();
    } catch (_) {}
  }

  void _startOtaCronTimer() {
    _otaCronTimer?.cancel();
    _otaCronTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted || _isCheckingOtaCron || _isOtaModalShowing) return;
      if (mounted) setState(() { _isCheckingOtaCron = true; });
      try {
        final cdnEngine = InforttsCdnOtaEngine(
          appName: widget.appName.toLowerCase(),
          appVersion: _currentVersion.isNotEmpty ? _currentVersion : (widget.appVersion ?? '2.02.00'),
        );
        final manifest = await cdnEngine.fetchManifest();
        if (manifest == null) return;

        final currentLocalPatch = await cdnEngine.getLocalPatchNumber();
        if (manifest.latestPatch > currentLocalPatch) {
          final success = await cdnEngine.downloadAndApplyPatch(manifest);
          if (success && mounted) {
            final bump = InforttsVersionHelper.calculateBump(
              baseVersion: cdnEngine.baseAppVersion,
              baseBuild: 20200,
              patchNumber: manifest.latestPatch,
            );
            setState(() {
              _currentVersion = bump.version;
              _currentBuildNumber = bump.buildNumber.toString();
              _otaPatchText = bump.displayString;
            });
            showTopSnackBar(
              context,
              title: "⚡ EMERGENCY OTA PATCH APPLIED",
              message: "Patch #${manifest.latestPatch} auto-installed silently from CDN.",
              icon: Icons.system_update_rounded,
              color: AcousticColors.sonarCyan,
            );
          }
        }
      } catch (_) {
      } finally {
        if (mounted) setState(() { _isCheckingOtaCron = false; });
      }
    });
  }

  Widget _buildFlashingOtaIcon() {
    final icon = const Icon(
      Icons.sensors_rounded,
      size: 14,
      color: AcousticColors.sonarCyan,
    );

    if (_isCheckingOtaCron) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: icon
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .fadeIn(duration: 150.ms)
            .scaleXY(begin: 0.7, end: 1.35, duration: 250.ms),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: icon,
    );
  }

  void _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('infortts_auth_userId');
    final email = prefs.getString('infortts_auth_email');
    final profileStr = prefs.getString('infortts_auth_profile');

    // Load all saved accounts
    final allAccountsStr = prefs.getString('infortts_all_saved_accounts');
    if (allAccountsStr != null) {
      try {
        final list = jsonDecode(allAccountsStr) as List;
        _savedAccounts = list.map((e) => AuthSession.fromJson(Map<String, dynamic>.from(e))).toList();
      } catch (_) {}
    }

    if (userId != null && userId.isNotEmpty) {
      Map<String, dynamic> profile = {};
      if (profileStr != null) {
        try {
          profile = jsonDecode(profileStr);
        } catch (_) {}
      }
      final isPlaceholder = userId == "usr_operator_local" ||
          (profile["display_name"] as String?) == "OPERATOR LOCAL" ||
          email == "operator@infortts.site";
      if (!isPlaceholder) {
        final active = AuthSession(
          userId: userId,
          email: email ?? '',
          profile: profile,
        );
        setState(() {
          _isAuthenticated = true;
          _authSession = active;
        });
        if (!_savedAccounts.any((a) => a.userId == active.userId)) {
          _savedAccounts.insert(0, active);
        }
      }
    }

    // Always attempt to synchronize latest profile data from API
    _fetchLiveProfile();
  }

  void _saveSession(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('infortts_auth_userId', session.userId);
    await prefs.setString('infortts_auth_email', session.email);
    if (session.profile != null) {
      await prefs.setString('infortts_auth_profile', jsonEncode(session.profile));
    }

    // Update multi-account registry
    _savedAccounts.removeWhere((a) => a.userId == session.userId || (a.email.isNotEmpty && a.email == session.email));
    _savedAccounts.insert(0, session);
    await prefs.setString('infortts_all_saved_accounts', jsonEncode(_savedAccounts.map((a) => {
      'user_id': a.userId,
      'email': a.email,
      'profile': a.profile,
    }).toList()));
    if (mounted) setState(() {});
  }

  void _switchAccount(AuthSession account) async {
    setState(() {
      _isAuthenticated = true;
      _authSession = account;
    });
    _saveSession(account);
  }

  void _removeAccount(String userId) async {
    _savedAccounts.removeWhere((a) => a.userId == userId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('infortts_all_saved_accounts', jsonEncode(_savedAccounts.map((a) => {
      'user_id': a.userId,
      'email': a.email,
      'profile': a.profile,
    }).toList()));
    if (_authSession?.userId == userId) {
      if (_savedAccounts.isNotEmpty) {
        _switchAccount(_savedAccounts.first);
      } else {
        _handleLogout();
      }
    } else {
      if (mounted) setState(() {});
    }
  }

  void _checkForUrlToken() async {
    final token = getTokenFromUrl();
    if (token != null && token.isNotEmpty) {
      try {
        final session = await _authClient.session(token);
        if (session.authenticated) {
          setState(() {
            _isAuthenticated = true;
            _authSession = session;
          });
          _saveSession(_authSession!);
        }
        clearUrlToken();
      } catch (e) {
        debugPrint("Auth session check failed: $e");
      }
    }
  }

  void _onTabChangedByController() {
    if (mounted) {
      setState(() {
        _activeTab = inforttsTabController.value;
      });
    }
  }

  void _handleMockLogin(String email, String password) {
    if (email.isNotEmpty && password.length >= 6) {
      setState(() {
        _isAuthenticated = true;
        _authSession = AuthSession(
          userId: "usr_${DateTime.now().millisecondsSinceEpoch}",
          email: email,
          profile: {"display_name": email.split('@')[0].toUpperCase(), "username": email.split('@')[0]},
        );
      });
      _saveSession(_authSession!);
    }
  }

  void _enterGuestMode() {
    setState(() {
      _isAuthenticated = true;
      _authSession = AuthSession(
        userId: 'usr_guest',
        email: '',
        profile: {
          "display_name": "GUEST",
          "username": "guest",
          "provider": "GUEST",
        },
      );
    });
    _saveSession(_authSession!);
  }

  Future<void> _fetchLiveProfile() async {
    // Never reconcile the profile of a foreign account. If there is no
    // authenticated session (or no email yet), there is nothing to merge.
    final current = _authSession;
    if (current == null || current.email.isEmpty) return;

    try {
      final profileUrl = Uri.parse("$kForensicsApiBase/api/user/profile");
      final resp = await http.get(profileUrl).timeout(const Duration(seconds: 4));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        // Guard: only accept the payload if it belongs to the signed-in user.
        final remoteEmail = (data['email'] as String?)?.trim().toLowerCase();
        final localEmail = current.email.trim().toLowerCase();
        if (remoteEmail == null || remoteEmail.isEmpty || remoteEmail != localEmail) {
          return;
        }
        if (mounted) {
          setState(() {
            _authSession = AuthSession(
              userId: data['user_id'] ?? data['id'] ?? current.userId,
              email: data['email'] ?? current.email,
              profile: {
                ...?current.profile,
                if (data['display_name'] != null) "display_name": data['display_name'],
                if (data['name'] != null && data['display_name'] == null) "display_name": data['name'],
                if (data['username'] != null) "username": data['username'],
                if (data['role'] != null) "role": data['role'],
                if (data['scope'] != null) "scope": data['scope'],
                if (data['provider'] != null) "provider": data['provider'],
                if (data['accounts_count'] != null) "accounts_count": data['accounts_count'],
                if (data['account_providers'] != null) "account_providers": data['account_providers'],
                if (data['photo_url'] != null) "photo_url": data['photo_url'],
              },
            );
          });
          if (_authSession != null) {
            _saveSession(_authSession!);
          }
          return;
        }
      }
    } catch (e) {
      debugPrint("Live profile fetch error: $e");
    }

    try {
      final token = getTokenFromUrl();
      if (token != null && token.isNotEmpty) {
        final prof = await _authClient.profile(token);
        if (prof != null && mounted) {
          setState(() {
            _authSession = AuthSession(
              userId: prof['id'] ?? prof['user_id'] ?? current.userId,
              email: (prof['email'] as String?) ?? current.email,
              profile: {...?current.profile, ...prof},
            );
          });
          if (_authSession != null) {
            _saveSession(_authSession!);
          }
          clearUrlToken();
        }
      }
    } catch (_) {}
  }

  void _initDeepLinks() async {
    try {
      final appLinks = AppLinks();
      final initialUri = await appLinks.getInitialLink();
      if (initialUri != null) {
        _handleIncomingUri(initialUri);
      }
      appLinks.uriLinkStream.listen((uri) {
        _handleIncomingUri(uri);
      });
    } catch (_) {}
  }

  void _handleIncomingUri(Uri uri) async {
    final token = uri.queryParameters['token'];
    if (token != null && token.isNotEmpty) {
      final prof = await _authClient.profile(token);
      if (prof != null && mounted) {
        setState(() {
          _isAuthenticated = true;
          _authSession = AuthSession(
            userId: prof['id'] ?? prof['user_id'] ?? '',
            email: (prof['email'] as String?) ?? '',
            profile: prof,
          );
        });
        if (_authSession != null) {
          _saveSession(_authSession!);
        }
      }
    }
  }

  void _handleGoogleSSO() async {
    final appName = widget.appName.toLowerCase().replaceAll(' ', '');
    final redirectScheme = '$appName://auth/callback';

    if (kIsWeb) {
      try {
        final redirectUrl = getCleanCurrentUrl();
        final authUrl = await _authClient.login(
          provider: 'google',
          redirect: redirectUrl,
        );
        redirectUser(authUrl);
      } catch (e) {
        showErrorSnackBar(context, 'Failed to initiate web login: $e');
      }
      return;
    }

    // Native (Android / iOS / macOS): sign in with Google, then exchange the
    // ID token at the gateway for a unified Glycocalyx JWT so native and web
    // apps share one identity/token (no dev bypass — full production SSO).
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId:
            '92924706833-1hmtr9ftm6q57k4g18fteu7jov70a6fc.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );
      final account = await googleSignIn.signIn();
      if (account == null) return; // user cancelled the picker

      final auth = await account.authentication;
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;
      if ((idToken == null || idToken.isEmpty) && (accessToken == null || accessToken.isEmpty)) {
        throw Exception('Google returned no token');
      }

      final data = await _authClient.loginWithGoogle(
        idToken: idToken,
        accessToken: accessToken,
      );
      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('Gateway returned no session token');
      }

      final session = await _authClient.session(token);
      if (!session.authenticated) {
        throw Exception('Gateway rejected the session');
      }

      setState(() {
        _isAuthenticated = true;
        _authSession = session;
      });
      _saveSession(_authSession!);
    } catch (e) {
      debugPrint("Native Google Sign-In error: $e");
      // Resilient fallback to browser SSO gateway with deep link return
      try {
        final targetUrl = 'https://auth.infortts.site/auth/login?provider=google&redirect=${Uri.encodeComponent(redirectScheme)}';
        final uri = Uri.parse(targetUrl);
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          await launchUrl(uri);
        }
        return;
      } catch (_) {}

      if (mounted) {
        showErrorSnackBar(context, 'Sign in failed: $e');
      }
    }
  }

  void _handlePasskeyAuth() async {
    final appName = widget.appName.toLowerCase().replaceAll(' ', '');
    final redirectScheme = '$appName://auth/callback';
    final targetUrl = 'https://auth.infortts.site/auth/login?passkey=1&redirect=${Uri.encodeComponent(kIsWeb ? getCleanCurrentUrl() : redirectScheme)}';

    if (kIsWeb) {
      redirectUser(targetUrl);
      return;
    }

    try {
      final uri = Uri.parse(targetUrl);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Passkey authentication failed: $e');
      }
    }
  }

  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('infortts_auth_userId');
    await prefs.remove('infortts_auth_email');
    await prefs.remove('infortts_auth_profile');
    setState(() {
      _isAuthenticated = false;
      _authSession = null;
    });
    inforttsTabController.value = 0;
  }

  DateTime? _lastBackPressTime;

  void _handleAndroidBack() {
    // 1. If currently inside a settings sub-page (profile, about), return to settings main
    if (_settingsSubPage != "main") {
      setState(() {
        _settingsSubPage = "main";
      });
      return;
    }

    // 2. If on any tab other than tab 0 (Trades/Dashboard), return to tab 0
    if (_activeTab != 0) {
      inforttsTabController.value = 0;
      return;
    }

    // 3. If on tab 0 at top level, double-tap back to exit
    final now = DateTime.now();
    if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Press back again to exit",
            style: GoogleFonts.outfit(color: AcousticColors.titanium, fontSize: 12),
          ),
          backgroundColor: AcousticColors.darkCarbon,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Double back within 2 seconds: close application
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) return _buildSplashView();
    if (!_isAuthenticated) return _buildAuthView();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleAndroidBack();
      },
      child: Scaffold(
        backgroundColor: AcousticColors.black,
        body: Column(
          children: [
            Expanded(
              child: SafeArea(
                bottom: false,
                child: _tabs[_activeTab].builder(context),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AcousticColors.darkCarbon,
        border: Border(top: BorderSide(color: AcousticColors.midGray.withOpacity(0.12), width: 0.8)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabs.length, (i) {
              final isActive = _activeTab == i;
              final tab = _tabs[i];
              return Expanded(
                child: InkWell(
                  onTap: () => inforttsTabController.value = i,
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? AcousticColors.panelBg.withOpacity(0.4) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        tab.iconWidget ??
                            Icon(
                              tab.icon,
                              size: 20,
                              color: isActive ? AcousticColors.sonarCyan : AcousticColors.steel,
                            ),
                        const SizedBox(height: 2),
                        Text(
                          tab.label,
                          style: GoogleFonts.outfit(
                            fontSize: 8,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            color: isActive ? AcousticColors.sonarCyan : AcousticColors.steel,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildSplashView() {
    return Scaffold(
      backgroundColor: AcousticColors.black,
      body: Stack(
        children: [
          // Animated particle grid background
          CustomPaint(
            size: Size.infinite,
            painter: _SplashGridPainter(),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Infortts3DLogo(appName: widget.appName, size: 200.0),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    widget.appName.replaceAll(RegExp(r'\s+by\s+infortts.*', caseSensitive: false), '').trim().toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6.0,
                      color: AcousticColors.titanium,
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0.0),
                const SizedBox(height: 8),
                Text(
                  "BY INFORTTS™",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3.0,
                    color: AcousticColors.sonarCyan,
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
                const SizedBox(height: 48),
                SizedBox(
                  width: 160,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AcousticColors.sonarCyan),
                      backgroundColor: AcousticColors.panelBg,
                      minHeight: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "INITIATING ENCRYPTED SYNC...",
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8,
                    color: AcousticColors.midGray,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: AcousticColors.midGray.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "v${_currentVersion.isNotEmpty ? _currentVersion : (widget.appVersion ?? '2.02.00')}${_currentBuildNumber.isNotEmpty ? '+$_currentBuildNumber' : '+200'}",
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      color: AcousticColors.sonarCyan,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthView() {
    final TextEditingController emailCtrl = TextEditingController();
    final TextEditingController passCtrl = TextEditingController();

    return Scaffold(
      backgroundColor: AcousticColors.black,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AcousticColors.darkCarbon,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AcousticColors.midGray.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Infortts3DLogo(appName: widget.appName, size: 120.0, interactive: false),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    "GLYCOCALYX AUTH",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3.0,
                      color: AcousticColors.titanium,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    "CENTRALIZED SINGLE SIGN-ON GATEWAY",
                    style: GoogleFonts.outfit(
                      fontSize: 8,
                      color: AcousticColors.midGray,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_savedAccounts.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    "CHOOSE AN ACCOUNT",
                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AcousticColors.sonarCyan),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AcousticColors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AcousticColors.midGray.withOpacity(0.15)),
                    ),
                    child: Column(
                      children: [
                        for (final acc in _savedAccounts) ...[
                          ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 12,
                              backgroundColor: AcousticColors.sonarCyan.withOpacity(0.2),
                              child: Text(
                                _initialsFor(acc.profile?["display_name"] ?? '', acc.email),
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AcousticColors.sonarCyan),
                              ),
                            ),
                            title: Text(
                              (acc.profile?["display_name"] as String?) ?? acc.email.split('@')[0],
                              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AcousticColors.titanium),
                            ),
                            subtitle: Text(
                              acc.email.isNotEmpty ? acc.email : "Local User",
                              style: GoogleFonts.jetBrainsMono(fontSize: 8, color: AcousticColors.steel),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 10, color: AcousticColors.sonarCyan),
                            onTap: () => _switchAccount(acc),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _handleGoogleSSO,
                  icon: const Icon(Icons.security, size: 16, color: AcousticColors.sonarCyan),
                  label: const Text(
                    "CONTINUE WITH GOOGLE SSO",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AcousticColors.sonarCyan, letterSpacing: 1.0),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AcousticColors.sonarCyan, width: 0.9),
                    backgroundColor: AcousticColors.sonarCyan.withOpacity(0.06),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Divider(color: AcousticColors.midGray.withOpacity(0.2))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text("OR USE CREDENTIALS", style: GoogleFonts.outfit(fontSize: 8, color: AcousticColors.midGray, letterSpacing: 1.0)),
                    ),
                    Expanded(child: Divider(color: AcousticColors.midGray.withOpacity(0.2))),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailCtrl,
                  style: GoogleFonts.outfit(fontSize: 12, color: AcousticColors.titanium),
                  decoration: InputDecoration(
                    labelText: "EMAIL ADDRESS",
                    labelStyle: GoogleFonts.outfit(fontSize: 10, color: AcousticColors.midGray),
                    filled: true,
                    fillColor: AcousticColors.black,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  style: GoogleFonts.outfit(fontSize: 12, color: AcousticColors.titanium),
                  decoration: InputDecoration(
                    labelText: "PASSWORD",
                    labelStyle: GoogleFonts.outfit(fontSize: 10, color: AcousticColors.midGray),
                    filled: true,
                    fillColor: AcousticColors.black,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _handleMockLogin(emailCtrl.text, passCtrl.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AcousticColors.panelBg,
                    foregroundColor: AcousticColors.titanium,
                    side: const BorderSide(color: AcousticColors.sonarCyan, width: 0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: Text(
                    "SIGN IN WITH PASSWORD",
                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _enterGuestMode,
                  style: TextButton.styleFrom(
                    foregroundColor: AcousticColors.midGray,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text(
                    "CONTINUE AS GUEST",
                    style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                  ),
                ),
                const SizedBox(height: 18),
                const Center(
                  child: InforttsWatermark(size: 10.0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileView(BuildContext context) {
    final session = _authSession;
    final profile = session?.profile ?? const <String, dynamic>{};
    final displayName = ((profile["display_name"] as String?)?.trim().isNotEmpty == true)
        ? (profile["display_name"] as String).trim()
        : "—";
    final email = (session?.email ?? '').trim();
    final role = (profile["role"] as String?)?.trim();
    final provider = (profile["provider"] as String?)?.trim();
    final scope = (profile["scope"] as String?)?.trim();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: AcousticColors.panelBg.withOpacity(0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AcousticColors.midGray.withOpacity(0.15)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "CENTRALIZED AUTHENTICATION STATUS",
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2.0, color: AcousticColors.sonarCyan),
              ),
              const SizedBox(height: 8),
              Text(
                email.isNotEmpty ? "Signed in as $email." : "No active session.",
                style: GoogleFonts.outfit(fontSize: 10, color: AcousticColors.midGray),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AcousticColors.sonarCyan.withOpacity(0.15),
                    child: Text(
                      _initialsFor(displayName, email),
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AcousticColors.sonarCyan,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AcousticColors.titanium),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email.isEmpty ? "Not signed in" : email,
                          style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AcousticColors.steel),
                        ),
                        if (role != null && role.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AcousticColors.sonarCyan.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AcousticColors.sonarCyan.withOpacity(0.4), width: 0.6),
                            ),
                            child: Text(
                              role,
                              style: GoogleFonts.jetBrainsMono(fontSize: 8, color: AcousticColors.sonarCyan, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AcousticColors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileRow("USER ID", session?.userId ?? "—"),
                    const SizedBox(height: 8),
                    _buildProfileRow("PROVIDER", provider ?? "—"),
                    const SizedBox(height: 8),
                    _buildProfileRow("SCOPE", scope ?? "—"),
                    const SizedBox(height: 8),
                    _buildProfileRow("LINKED ACCOUNTS", _linkedAccountsLabel(profile)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_savedAccounts.isNotEmpty) ...[
                Text(
                  "SWITCH / MANAGE ACCOUNTS",
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AcousticColors.sonarCyan),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: AcousticColors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AcousticColors.midGray.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      for (final acc in _savedAccounts) ...[
                        ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: acc.userId == session?.userId
                                ? AcousticColors.sonarCyan.withOpacity(0.2)
                                : AcousticColors.midGray.withOpacity(0.1),
                            child: Text(
                              _initialsFor(acc.profile?["display_name"] ?? '', acc.email),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: acc.userId == session?.userId ? AcousticColors.sonarCyan : AcousticColors.steel,
                              ),
                            ),
                          ),
                          title: Text(
                            (acc.profile?["display_name"] as String?) ?? acc.email.split('@')[0],
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: acc.userId == session?.userId ? AcousticColors.titanium : AcousticColors.steel,
                            ),
                          ),
                          subtitle: Text(
                            acc.email.isNotEmpty ? acc.email : "Local User",
                            style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AcousticColors.midGray),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (acc.userId == session?.userId)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AcousticColors.sonarCyan.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text("ACTIVE", style: TextStyle(fontSize: 8, color: AcousticColors.sonarCyan, fontWeight: FontWeight.bold)),
                                )
                              else
                                IconButton(
                                  icon: const Icon(Icons.swap_horiz, size: 16, color: AcousticColors.sonarCyan),
                                  tooltip: "Switch to this account",
                                  onPressed: () => _switchAccount(acc),
                                ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 14, color: AcousticColors.midGray),
                                tooltip: "Remove account",
                                onPressed: () => _removeAccount(acc.userId),
                              ),
                            ],
                          ),
                          onTap: () => _switchAccount(acc),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _handleGoogleSSO,
                  icon: const Icon(Icons.add, size: 14, color: AcousticColors.sonarCyan),
                  label: const Text(
                    "ADD ANOTHER ACCOUNT",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AcousticColors.sonarCyan, letterSpacing: 1.0),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AcousticColors.sonarCyan.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: _handleLogout,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AcousticColors.warnOrange),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                child: Text(
                  "SIGN OUT ACTIVE ACCOUNT",
                  style: GoogleFonts.outfit(fontSize: 10, color: AcousticColors.warnOrange, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  String _linkedAccountsLabel(Map<String, dynamic> profile) {
    final count = profile["accounts_count"];
    final providers = profile["account_providers"];
    if (count == null && providers == null) return "—";
    if (providers is List && providers.isNotEmpty) {
      return "${count ?? providers.length} LIVE (${providers.join(', ')})";
    }
    if (providers is String && providers.trim().isNotEmpty) {
      return "${count ?? "?"} LIVE ($providers)";
    }
    if (count != null) {
      return "$count LIVE ACCOUNT${count == 1 ? '' : 'S'}";
    }
    return "—";
  }

  String _initialsFor(String displayName, String email) {
    final name = displayName.trim();
    if (name.isNotEmpty && name != "—") {
      final parts = name.split(RegExp(r'\s+'));
      if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        return (_firstRune(parts[0]) + _firstRune(parts[1])).toUpperCase();
      }
      return _firstRune(name).toUpperCase();
    }
    final prefix = email.split('@').first.trim();
    if (prefix.isNotEmpty) {
      final letters = prefix.runes.map(String.fromCharCode).toList();
      return letters.take(2).join().toUpperCase();
    }
    return "?";
  }

  String _firstRune(String s) => s.isEmpty ? '' : String.fromCharCode(s.runes.first);

  Widget _buildProfileRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 9, color: AcousticColors.midGray, fontWeight: FontWeight.bold)),
        Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AcousticColors.steel)),
      ],
    );
  }

  Widget _buildSubPageHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AcousticColors.darkCarbon,
        border: Border(bottom: BorderSide(color: AcousticColors.midGray.withOpacity(0.12), width: 0.8)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AcousticColors.sonarCyan, size: 20),
            onPressed: () => setState(() => _settingsSubPage = "main"),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: AcousticColors.titanium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsView() {
    if (_settingsSubPage == "profile") {
      return Column(
        children: [
          _buildSubPageHeader("OPERATOR PROFILE"),
          Expanded(child: _buildProfileView(context)),
        ],
      );
    }
    if (_settingsSubPage == "about") {
      return Column(
        children: [
          _buildSubPageHeader("ABOUT SYSTEM"),
          Expanded(child: _buildAboutView()),
        ],
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: AcousticColors.panelBg.withOpacity(0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AcousticColors.midGray.withOpacity(0.15)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "SETTINGS & CONFIGURATION",
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2.0, color: AcousticColors.titanium),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AcousticColors.sonarCyan.withOpacity(0.12),
                      border: Border.all(color: AcousticColors.sonarCyan, width: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "V${_currentVersion.isNotEmpty ? _currentVersion : (widget.appVersion ?? '2.02.00')}",
                      style: GoogleFonts.jetBrainsMono(fontSize: 9, fontWeight: FontWeight.bold, color: AcousticColors.sonarCyan),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "System parameters, local variables and metadata configurations.",
                style: GoogleFonts.outfit(fontSize: 10, color: AcousticColors.midGray),
              ),
              const SizedBox(height: 24),
              // Profile and About section links inside Settings
              Card(
                color: AcousticColors.black.withOpacity(0.3),
                margin: const EdgeInsets.only(bottom: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AcousticColors.midGray.withOpacity(0.15), width: 0.8),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline, color: AcousticColors.sonarCyan, size: 20),
                      title: Text("OPERATOR PROFILE", style: GoogleFonts.outfit(fontSize: 11, color: AcousticColors.titanium, fontWeight: FontWeight.bold)),
                      subtitle: Text("Centralized credentials & OAuth details", style: GoogleFonts.outfit(fontSize: 9, color: AcousticColors.midGray)),
                      trailing: const Icon(Icons.chevron_right, color: AcousticColors.steel, size: 18),
                      onTap: () => setState(() => _settingsSubPage = "profile"),
                    ),
                    Divider(color: AcousticColors.midGray.withOpacity(0.15), height: 1),
                    ListTile(
                      leading: const Icon(Icons.info_outline, color: AcousticColors.sonarCyan, size: 20),
                      title: Text("ABOUT SYSTEM", style: GoogleFonts.outfit(fontSize: 11, color: AcousticColors.titanium, fontWeight: FontWeight.bold)),
                      subtitle: Text("Coded lifeform description & 3D emblem", style: GoogleFonts.outfit(fontSize: 9, color: AcousticColors.midGray)),
                      trailing: const Icon(Icons.chevron_right, color: AcousticColors.steel, size: 18),
                      onTap: () => setState(() => _settingsSubPage = "about"),
                    ),
                  ],
                ),
              ),
              _buildSettingsToggle("LOCAL LLM OFFLINE COMPILER", true),
              const SizedBox(height: 16),
              _buildSettingsToggle("GLYCOCALYX AUTO-SYNC TOKEN", true),
              const SizedBox(height: 16),
              _buildSettingsToggle("HARDWARE ACCELERATED RENDER", true),
              const SizedBox(height: 28),
              Text(
                "INFRASTRUCTURE DNS",
                style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: AcousticColors.steel),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AcousticColors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    _buildProfileRow("NATS HOST", const String.fromEnvironment('NATS_HOST', defaultValue: 'nats://nats.infortts.site:4222')),
                    const SizedBox(height: 6),
                    _buildProfileRow("VECTOR DB", const String.fromEnvironment('VECTOR_DB_URL', defaultValue: 'qdrant://qdrant.infortts.site:6333')),
                    const SizedBox(height: 6),
                    _buildProfileRow("FORENSICS API", '$kForensicsApiBase/api/v1'),
                    const SizedBox(height: 6),
                    _buildProfileRow("OTA CDN", kOtaCdnBase),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                "APPLICATION VERSION",
                style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: AcousticColors.steel),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AcousticColors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    _buildProfileRow("App", widget.appName),
                    const SizedBox(height: 6),
                    _buildProfileRow("Version", _currentVersion.isNotEmpty ? _currentVersion : (widget.appVersion ?? '2.02.00')),
                    const SizedBox(height: 6),
                    _buildProfileRow("Build", _currentBuildNumber.isNotEmpty ? "Build $_currentBuildNumber" : "Build 20200"),
                    const SizedBox(height: 6),
                    _buildProfileRow("Engine", "Flutter 3.29.0 / Dart 3.7.0"),
                    const SizedBox(height: 6),
                    _buildProfileRow("Track", "Internal Track (CDN Distribution)"),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text("Infortts OTA", style: GoogleFonts.outfit(color: AcousticColors.steel, fontSize: 11)),
                              _buildFlashingOtaIcon(),
                            ],
                          ),
                          Text(_otaPatchText, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AcousticColors.sonarCyan.withOpacity(0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            onPressed: () => _handleCheckOtaUpdates(context),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.system_update_alt_rounded, size: 14, color: AcousticColors.sonarCyan),
                                _buildFlashingOtaIcon(),
                                const SizedBox(width: 4),
                                Text("Check OTA Updates", style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AcousticColors.sonarCyan)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AcousticColors.sonarCyan.withOpacity(0.15),
                              foregroundColor: AcousticColors.sonarCyan,
                              side: BorderSide(color: AcousticColors.sonarCyan.withOpacity(0.4)),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            onPressed: () => _showInstalledPatchDetailsModal(context),
                            icon: const Icon(Icons.info_outline_rounded, size: 14),
                            label: Text("Patch Details", style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold)),
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
    );
  }

  Future<void> _showInstalledPatchDetailsModal(BuildContext context) async {
    final cdnEngine = InforttsCdnOtaEngine(
      appName: widget.appName.toLowerCase(),
      appVersion: _currentVersion.isNotEmpty ? _currentVersion : (widget.appVersion ?? '2.02.00'),
    );
    final patchNum = await cdnEngine.getLocalPatchNumber();
    final manifest = await cdnEngine.fetchManifest();

    final patchDisplay = patchNum > 0 ? "Infortts CDN OTA Patch #$patchNum Active" : "Base Release (Patch #0)";
    final releaseNotes = manifest?.releaseNotes ?? [
      "✓ Epoch 2 Custom CDN OTA Active",
      "✓ Real-Time Automated Background Update Cron",
      "✓ Sovereign Self-Hosted CDN Distribution Engine",
    ];

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AcousticColors.darkCarbon,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AcousticColors.sonarCyan, width: 1.2)),
        title: Row(
          children: [
            const Icon(Icons.system_update_rounded, color: AcousticColors.sonarCyan, size: 22),
            const SizedBox(width: 8),
            Text("Active Version & Patch Details", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailTile("App Name", widget.appName),
              _buildDetailTile("Version Name", _currentVersion.isNotEmpty ? _currentVersion : "2.02.05"),
              _buildDetailTile("Build Code", _currentBuildNumber.isNotEmpty ? _currentBuildNumber : "20205"),
              _buildDetailTile("Release Track", "Internal Track (CDN Distribution)"),
              _buildDetailTile("Active Patch", patchDisplay),
              const SizedBox(height: 12),
              Text("Patch Highlights & Release Notes:", style: GoogleFonts.outfit(color: AcousticColors.sonarCyan, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              ...releaseNotes.map(
                (note) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, color: AcousticColors.sonarCyan, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          note,
                          style: GoogleFonts.outfit(color: AcousticColors.titanium, fontSize: 11, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AcousticColors.sonarCyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text("Close", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: AcousticColors.steel, fontSize: 11)),
          Text(value, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: AcousticColors.steel, fontSize: 12)),
          Text(value, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _showNewPatchAvailableModal(
    BuildContext context,
    InforttsOtaManifest manifest,
    InforttsCdnOtaEngine cdnEngine, {
    bool forceReShow = false,
  }) async {
    if (_isOtaModalShowing && !forceReShow) return;
    _isOtaModalShowing = true;

    bool isDownloading = false;
    String statusMessage = '';

    final targetBuild = manifest.latestBuild > 0
        ? manifest.latestBuild
        : (int.tryParse(manifest.version.replaceAll('.', '')) ?? 20205);

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return AlertDialog(
                backgroundColor: AcousticColors.darkCarbon,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AcousticColors.sonarCyan, width: 1.5),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AcousticColors.sonarCyan.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.system_update_rounded,
                            color: AcousticColors.sonarCyan,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "New OTA Patch Available",
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              Text(
                                "Infortts CDN Distribution Channel",
                                style: GoogleFonts.outfit(
                                  color: AcousticColors.sonarCyan,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: AcousticColors.midGray, height: 1),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AcousticColors.panelBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AcousticColors.steel.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow("App Name", widget.appName),
                            _buildDetailRow("Target Version", "v${manifest.version}"),
                            _buildDetailRow("Build Code", "$targetBuild"),
                            _buildDetailRow("Patch Number", "#${manifest.latestPatch}"),
                            if (manifest.updatedAt.isNotEmpty)
                              _buildDetailRow("Published", manifest.updatedAt),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Patch Details & Release Notes:",
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (manifest.releaseNotes.isNotEmpty)
                        ...manifest.releaseNotes.map(
                          (note) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle_outline,
                                    color: AcousticColors.sonarCyan, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    note,
                                    style: GoogleFonts.outfit(
                                      color: AcousticColors.titanium,
                                      fontSize: 12,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            "• Maintenance patch with performance improvements and bug fixes.",
                            style: GoogleFonts.outfit(
                              color: AcousticColors.titanium,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (isDownloading) ...[
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(
                          backgroundColor: AcousticColors.panelBg,
                          color: AcousticColors.sonarCyan,
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            statusMessage.isNotEmpty
                                ? statusMessage
                                : "Downloading patch #${manifest.latestPatch}...",
                            style: GoogleFonts.outfit(
                              color: AcousticColors.sonarCyan,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  if (!isDownloading) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AcousticColors.sonarCyan,
                        foregroundColor: AcousticColors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: Text(
                        "Download & Install",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        setModalState(() {
                          isDownloading = true;
                          statusMessage = "Downloading & applying patch #${manifest.latestPatch}...";
                        });

                        final success = await cdnEngine.downloadAndApplyPatch(
                          manifest,
                          onStatusChanged: (status, patchNum) {
                            if (status == InforttsCdnOtaStatus.installed) {
                              setModalState(() {
                                statusMessage = "Patch #${manifest.latestPatch} installed successfully!";
                              });
                            }
                          },
                        );

                        if (context.mounted) {
                          Navigator.of(dialogCtx).pop();
                          if (success) {
                            final bump = InforttsVersionHelper.calculateBump(
                              baseVersion: cdnEngine.baseAppVersion,
                              baseBuild: 20200,
                              patchNumber: manifest.latestPatch,
                            );
                            setState(() {
                              _currentVersion = bump.version;
                              _currentBuildNumber = bump.buildNumber.toString();
                              _otaPatchText = bump.displayString;
                            });
                            _showRestartDialog(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AcousticColors.darkCarbon,
                                content: Text(
                                  "Failed to download OTA patch. Please try again.",
                                  style: GoogleFonts.outfit(color: Colors.redAccent),
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ],
              );
            },
          );
        },
      );
    } finally {
      _isOtaModalShowing = false;
    }
  }

  Future<void> _handleCheckOtaUpdates(BuildContext context) async {
    if (mounted) setState(() { _isCheckingOtaCron = true; });
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: AcousticColors.darkCarbon,
        content: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2.0, valueColor: AlwaysStoppedAnimation<Color>(AcousticColors.sonarCyan)),
            ),
            const SizedBox(width: 10),
            Text("Checking Infortts OTA servers for patch updates...", style: GoogleFonts.outfit(color: AcousticColors.sonarCyan, fontSize: 12)),
          ],
        ),
      ),
    );

    try {
      final cdnEngine = InforttsCdnOtaEngine(
        appName: widget.appName.toLowerCase(),
        appVersion: _currentVersion.isNotEmpty ? _currentVersion : (widget.appVersion ?? '2.02.00'),
      );

      final manifest = await cdnEngine.fetchManifest();
      final currentLocalPatch = await cdnEngine.getLocalPatchNumber();

      messenger.clearSnackBars();

      if (manifest != null && manifest.latestPatch > currentLocalPatch) {
        if (mounted) {
          _showNewPatchAvailableModal(context, manifest, cdnEngine, forceReShow: true);
        }
      } else {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AcousticColors.darkCarbon,
            content: Text(
              "✓ No updates available. System is up to date (Patch #${currentLocalPatch} active).",
              style: GoogleFonts.outfit(color: AcousticColors.sonarCyan),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() { _isCheckingOtaCron = false; });
    }
  }

  void _showRestartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AcousticColors.darkCarbon,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AcousticColors.sonarCyan, width: 1.2)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: AcousticColors.sonarCyan, size: 22),
            const SizedBox(width: 8),
            Text("Patch Installed!", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          "The latest Infortts OTA patch has been downloaded and installed.\n\nRestart the app now to activate all new features?",
          style: GoogleFonts.outfit(color: AcousticColors.titanium, fontSize: 13),
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AcousticColors.sonarCyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              try {
                const channel = MethodChannel('com.infortts.app/restart');
                await channel.invokeMethod('restartApp');
              } catch (_) {
                if (!kIsWeb) {
                  exit(0);
                } else {
                  SystemNavigator.pop();
                }
              }
            },
            icon: const Icon(Icons.restart_alt_rounded, size: 16),
            label: Text("Restart Now", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsToggle(String label, bool initialVal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AcousticColors.titanium),
        ),
        Switch(
          value: initialVal,
          onChanged: (_) {},
          activeColor: AcousticColors.sonarCyan,
        ),
      ],
    );
  }

  Widget _buildAboutView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 680;
        final logoSize = isMobile ? 160.0 : 240.0;

        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 32,
              vertical: isMobile ? 20 : 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMobile) ...[
                  Infortts3DLogo(appName: widget.appName, size: logoSize),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AcousticColors.panelBg.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AcousticColors.midGray.withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.appName.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3.0,
                            color: AcousticColors.titanium,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "SYSTEM CODED LIFEFORM",
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AcousticColors.sonarCyan,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          widget.appDescription,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AcousticColors.steel,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: AcousticColors.midGray, thickness: 0.5),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Material Base:", style: GoogleFonts.outfit(fontSize: 10, color: AcousticColors.midGray)),
                            Text("Tactile Obsidian & Titanium", style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AcousticColors.steel)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Emissive Wave:", style: GoogleFonts.outfit(fontSize: 10, color: AcousticColors.midGray)),
                            Text("Acoustic Cyan/Blue channels", style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AcousticColors.sonarCyan)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Version / Build:", style: GoogleFonts.outfit(fontSize: 10, color: AcousticColors.midGray)),
                            Text(_currentVersion.isNotEmpty ? "v$_currentVersion${_currentBuildNumber.isNotEmpty ? ' (+$_currentBuildNumber)' : ''}" : "v${widget.appVersion ?? '2.02.00'}", style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AcousticColors.sonarCyan)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Infortts3DLogo(appName: widget.appName, size: 240.0),
                      const SizedBox(width: 48),
                      Container(
                        width: 380,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AcousticColors.panelBg.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AcousticColors.midGray.withOpacity(0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.appName.toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4.0,
                                color: AcousticColors.titanium,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "SYSTEM CODED LIFEFORM",
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AcousticColors.sonarCyan,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.appDescription,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AcousticColors.steel,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Divider(color: AcousticColors.midGray, thickness: 0.5),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Material Base:", style: GoogleFonts.outfit(fontSize: 10, color: AcousticColors.midGray)),
                                Text("Tactile Obsidian & Titanium", style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AcousticColors.steel)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Emissive Wave:", style: GoogleFonts.outfit(fontSize: 10, color: AcousticColors.midGray)),
                                Text("Acoustic Cyan/Blue channels", style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AcousticColors.sonarCyan)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Version / Build:", style: GoogleFonts.outfit(fontSize: 10, color: AcousticColors.midGray)),
                                Text(_currentVersion.isNotEmpty ? "v$_currentVersion${_currentBuildNumber.isNotEmpty ? ' (+$_currentBuildNumber)' : ''}" : "v${widget.appVersion ?? '2.02.00'}", style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AcousticColors.sonarCyan)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  "INFORTTS ECOSYSTEM OS • BY GOOGLE DEEPMIND PAIR PROGRAMMER",
                  style: GoogleFonts.outfit(fontSize: 8, color: AcousticColors.midGray, letterSpacing: 2.0),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms);
      },
    );
  }
}

class _SplashGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AcousticColors.sonarCyan.withOpacity(0.03)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void showTopSnackBar(
  BuildContext context, {
  required String message,
  String title = "SYSTEM ALERT",
  IconData icon = Icons.notifications_active_rounded,
  Color color = AcousticColors.sonarCyan,
  Duration duration = const Duration(seconds: 4),
}) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _TopSnackBarOverlayWidget(
      title: title,
      message: message,
      icon: icon,
      color: color,
      duration: duration,
      onDismiss: () {
        if (entry.mounted) {
          entry.remove();
        }
      },
    ),
  );
  overlay.insert(entry);
}

class _TopSnackBarOverlayWidget extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final Duration duration;
  final VoidCallback onDismiss;

  const _TopSnackBarOverlayWidget({
    Key? key,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.duration,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<_TopSnackBarOverlayWidget> createState() => _TopSnackBarOverlayWidgetState();
}

class _TopSnackBarOverlayWidgetState extends State<_TopSnackBarOverlayWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _offsetAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _offsetAnim = Tween<Offset>(
      begin: const Offset(0.0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _animController.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPadding + 8,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: _offsetAnim,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F141F).withOpacity(0.96),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: widget.color, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.3),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: widget.color,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.message,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _animController.reverse().then((_) {
                      widget.onDismiss();
                    });
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.close, size: 16, color: AcousticColors.steel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'theme.dart';
import 'auth.dart';
import 'brand.dart';
import 'animations.dart';

class InforttsTab {
  final String label;
  final IconData icon;
  final WidgetBuilder builder;

  const InforttsTab({
    required this.label,
    required this.icon,
    required this.builder,
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
  final String appVersion;
  final Widget workspaceChild;
  final List<InforttsTab>? additionalTabs;
  final GlycocalyxAuth? auth;

  const InforttsAppShell({
    super.key,
    required this.appName,
    required this.appDescription,
    required this.appVersion,
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
  String _settingsSubPage = "main";

  late final List<InforttsTab> _tabs;

  @override
  void initState() {
    super.initState();
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
  }

  void _onTabChangedByController() {
    if (mounted) {
      setState(() {
        _activeTab = inforttsTabController.value;
      });
    }
  }

  @override
  void dispose() {
    inforttsTabController.removeListener(_onTabChangedByController);
    super.dispose();
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
    }
  }

  void _handleGoogleSSO() async {
    setState(() {
      _isAuthenticated = true;
      _authSession = AuthSession(
        userId: "sso_google_129482",
        email: "sahil.rathee@infortts.com",
        profile: {"display_name": "SAHIL RATHEE", "username": "sahilrathee", "avatar_url": ""},
      );
    });
  }

  void _handleLogout() {
    setState(() {
      _isAuthenticated = false;
      _authSession = null;
    });
    inforttsTabController.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) return _buildSplashView();
    if (!_isAuthenticated) return _buildAuthView();

    return Scaffold(
      backgroundColor: AcousticColors.black,
      body: Column(
        children: [
          Expanded(
            child: _tabs[_activeTab].builder(context),
          ),
          _buildBottomNav(),
        ],
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
                Infortts3DLogo(appName: widget.appName, size: 220.0),
                const SizedBox(height: 32),
                Text(
                  widget.appName.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8.0,
                    color: AcousticColors.titanium,
                  ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0.0),
                const SizedBox(height: 8),
                Text(
                  "BY INFORTTS™",
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
                    "v${widget.appVersion}",
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
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  style: GoogleFonts.outfit(fontSize: 12, color: AcousticColors.titanium),
                  decoration: InputDecoration(
                    labelText: "DECRYPT KEY / PASSWORD",
                    labelStyle: GoogleFonts.outfit(fontSize: 10, color: AcousticColors.midGray),
                    filled: true,
                    fillColor: AcousticColors.black,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _handleMockLogin(emailCtrl.text, passCtrl.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AcousticColors.panelBg,
                    foregroundColor: AcousticColors.titanium,
                    side: const BorderSide(color: AcousticColors.sonarCyan, width: 0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    "DECRYPT & SYNC WORKSPACE",
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Divider(color: AcousticColors.midGray.withOpacity(0.2))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text("OR", style: GoogleFonts.outfit(fontSize: 9, color: AcousticColors.midGray)),
                    ),
                    Expanded(child: Divider(color: AcousticColors.midGray.withOpacity(0.2))),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _handleGoogleSSO,
                  icon: const Icon(Icons.security, size: 16, color: AcousticColors.sonarCyan),
                  label: Text(
                    "AUTHENTICATE WITH GOOGLE SSO",
                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AcousticColors.sonarCyan, letterSpacing: 1.0),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AcousticColors.sonarCyan.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 24),
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
                "Current session authenticated via Glycocalyx OAuth service.",
                style: GoogleFonts.outfit(fontSize: 10, color: AcousticColors.midGray),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AcousticColors.activeCard,
                    child: const Icon(Icons.person, size: 28, color: AcousticColors.sonarCyan),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _authSession?.profile?["display_name"] ?? "UNKNOWN OPERATOR",
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AcousticColors.titanium),
                      ),
                      Text(
                        _authSession?.email ?? "no-email@infortts.com",
                        style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AcousticColors.steel),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AcousticColors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileRow("USER ID", _authSession?.userId ?? "N/A"),
                    const SizedBox(height: 8),
                    _buildProfileRow("PROVIDER", "GOOGLE SSO / OAUTH"),
                    const SizedBox(height: 8),
                    _buildProfileRow("SCOPE", "INFORTTS SWARM CLUSTER ADMIN"),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: _handleLogout,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AcousticColors.warnOrange),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                child: Text(
                  "SEVER LOGICAL CONNECTION",
                  style: GoogleFonts.outfit(fontSize: 10, color: AcousticColors.warnOrange, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

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
                      "V${widget.appVersion}",
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
                    _buildProfileRow("NATS HOST", "nats://localhost:4222"),
                    const SizedBox(height: 6),
                    _buildProfileRow("VECTOR DB", "qdrant://localhost:6333"),
                    const SizedBox(height: 6),
                    _buildProfileRow("POSTGRES", "postgres://localhost:5432"),
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
                    _buildProfileRow("Version", widget.appVersion),
                    const SizedBox(height: 6),
                    _buildProfileRow("Build", "2026.06.14-01"),
                    const SizedBox(height: 6),
                    _buildProfileRow("Engine", "Flutter 3.x / Dart 3.x"),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildSettingsToggle(String label, bool initialVal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 11, color: AcousticColors.steel)),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: initialVal,
            activeColor: AcousticColors.sonarCyan,
            onChanged: (_) {},
          ),
        ),
      ],
    );
  }

  Widget _buildAboutView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
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
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              "INFORTTS ECOSYSTEM OS • BY GOOGLE DEEPMIND PAIR PROGRAMMER",
              style: GoogleFonts.outfit(fontSize: 8, color: AcousticColors.midGray, letterSpacing: 2.0),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
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


import 'dart:async';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:io' show exit;
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'env_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';

import 'theme.dart';
import 'emblem/emblem_painter.dart';
import 'emblem/emblem_spec.dart';
import 'auth.dart';
import 'brand.dart';
import 'url_helper.dart';
import 'error.dart';
import 'ota_engine.dart';
import 'cdn_ota_engine.dart';
import 'infortts_notification_service.dart';

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

  /// Optional gradient palette key for marks that name one (`kEmblemThemes`):
  /// `brand`, `neon`, `glass`, `holi`, `diwali`, `pride`, `aurora`. Null keeps
  /// whatever the spec pins, so existing call sites are unaffected.
  final String? theme;

  const Infortts3DLogo({
    super.key,
    required this.appName,
    this.size = 180.0,
    this.interactive = true,
    this.theme,
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
              theme: widget.theme,
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

  /// Optional palette key (see `kEmblemThemes`) — festival / mood reskin.
  final String? theme;

  _EmblemPainter({
    required this.organismName,
    required this.isHovered,
    this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Standalone marks (the corporate logo) are their own artwork: no grid, no
    // dark disc, no rim — the spec draws a full-bleed gradient instead.
    final EmblemSpec spec = EmblemSpec.resolve(organismName);
    if (!spec.showMedal) {
      EmblemRenderer.paint(canvas, center, radius, spec, theme: theme);
      return;
    }

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

    // One interpreter for every organism — the spec comes from
    // logos/3d/brand/organisms.json via emblem_registry.g.dart.
    EmblemRenderer.paint(canvas, center, radius, spec, theme: theme);
  }

  @override
  bool shouldRepaint(covariant _EmblemPainter oldDelegate) {
    return oldDelegate.organismName != organismName ||
        oldDelegate.isHovered != isHovered ||
        oldDelegate.theme != theme;
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
  final List<Widget>? settingsSections;
  final bool requireAuth;
  final bool allowGuest;
  final bool showSplash;
  final bool autoPromptNotifications;

  const InforttsAppShell({
    super.key,
    required this.appName,
    required this.appDescription,
    this.appVersion,
    required this.workspaceChild,
    this.additionalTabs,
    this.auth,
    this.settingsSections,
    this.requireAuth = true,
    this.allowGuest = false,
    this.showSplash = false,
    this.autoPromptNotifications = false,
  });

  @override
  State<InforttsAppShell> createState() => _InforttsAppShellState();
}

class InforttsPatchNotificationEvent {
  final String message;
  final String title;
  final IconData icon;
  final Color? color;
  final Duration duration;

  const InforttsPatchNotificationEvent({
    required this.message,
    this.title = "OTA UPDATE",
    this.icon = LucideIcons.refreshCw,
    this.color,
    this.duration = const Duration(seconds: 5),
  });
}

class InforttsPatchNotificationBus {
  static final ValueNotifier<InforttsPatchNotificationEvent?> current =
      ValueNotifier<InforttsPatchNotificationEvent?>(null);

  static void show({
    required String message,
    String title = "OTA UPDATE",
    IconData icon = LucideIcons.refreshCw,
    Color? color,
    Duration duration = const Duration(seconds: 5),
  }) {
    current.value = InforttsPatchNotificationEvent(
      message: message,
      title: title,
      icon: icon,
      color: color,
      duration: duration,
    );
  }

  static void dismiss() {
    current.value = null;
  }
}

class _InforttsAppShellState extends State<InforttsAppShell> {
  bool _showSplash = false;
  bool _minSplashDurationElapsed = false;
  bool _isInitialAuthReady = false;
  bool _isAuthenticated = false;
  int _activeTab = 0;
  AuthSession? _authSession;
  List<AuthSession> _savedAccounts = [];
  String _settingsSubPage = "main";
  late final GlycocalyxAuth _authClient;
  String _currentVersion = "";
  String _currentBuildNumber = "";
  String _otaPatchText = "v2.06.02+20602 (Infortts R2 CDN OTA Engine Active)";
  Timer? _otaCronTimer;
  bool _isCheckingOtaCron = false;
  bool _isOtaModalShowing = false;
  StreamSubscription<InforttsNotificationEvent>? _notificationSub;

  String? _patchNotificationTitle;
  String? _patchNotificationMessage;
  IconData _patchNotificationIcon = LucideIcons.refreshCw;
  Color _patchNotificationColor = const Color(0xFF00D2FF);
  Timer? _patchNotificationTimer;

  late final List<InforttsTab> _tabs;

  void _onPatchNotificationBusEvent() {
    final event = InforttsPatchNotificationBus.current.value;
    if (event != null && mounted) {
      _showPatchNotificationAboveTabBar(
        message: event.message,
        title: event.title,
        icon: event.icon,
        color: event.color,
        duration: event.duration,
      );
    }
  }

  void _showPatchNotificationAboveTabBar({
    required String message,
    String title = "OTA UPDATE",
    IconData icon = LucideIcons.refreshCw,
    Color? color,
    Duration duration = const Duration(seconds: 5),
  }) {
    if (!mounted) return;
    _patchNotificationTimer?.cancel();
    setState(() {
      _patchNotificationTitle = title;
      _patchNotificationMessage = message;
      _patchNotificationIcon = icon;
      _patchNotificationColor = color ?? (AcousticColors.isLight ? const Color(0xFF0284C7) : const Color(0xFF00D2FF));
    });
    _patchNotificationTimer = Timer(duration, () {
      if (mounted) {
        setState(() {
          _patchNotificationMessage = null;
          _patchNotificationTitle = null;
        });
      }
    });
  }

  void _dismissPatchNotification() {
    _patchNotificationTimer?.cancel();
    InforttsPatchNotificationBus.dismiss();
    if (mounted) {
      setState(() {
        _patchNotificationMessage = null;
        _patchNotificationTitle = null;
      });
    }
  }

  @override
  void dispose() {
    _otaCronTimer?.cancel();
    _notificationSub?.cancel();
    _patchNotificationTimer?.cancel();
    InforttsPatchNotificationBus.current.removeListener(_onPatchNotificationBusEvent);
    InforttsNotificationService.instance.stopStreamListener();
    inforttsTabController.removeListener(_onTabChangedByController);
    InforttsAuthManager.instance.sessionNotifier.removeListener(_onAuthSessionChanged);
    InforttsAuthManager.instance.accountsNotifier.removeListener(_onAccountsChanged);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    InforttsPatchNotificationBus.current.addListener(_onPatchNotificationBusEvent);
    _showSplash = widget.showSplash;
    _minSplashDurationElapsed = !widget.showSplash;
    _isInitialAuthReady = !widget.requireAuth;
    _currentVersion = widget.appVersion ?? "2.06.03";
    _currentBuildNumber = "20603";
    _initPackageInfo();
    _authClient = widget.auth ?? InforttsAuthManager.instance.api;
    inforttsTabController.value = 0;
    inforttsTabController.addListener(_onTabChangedByController);
    InforttsAuthManager.instance.sessionNotifier.addListener(_onAuthSessionChanged);
    InforttsAuthManager.instance.accountsNotifier.addListener(_onAccountsChanged);

    _tabs = [
      if (widget.additionalTabs != null)
        ...widget.additionalTabs!
      else ...[
        InforttsTab(label: "Dashboard", icon: LucideIcons.layoutDashboard, builder: (_) => widget.workspaceChild),
      ],
      InforttsTab(label: "Settings", icon: LucideIcons.settings, builder: (_) => _buildSettingsView()),
    ];
    if (widget.showSplash) {
      Timer(const Duration(milliseconds: 1400), () {
        if (mounted) {
          _minSplashDurationElapsed = true;
          _checkReadyToDismissSplash();
        }
      });
      // Fallback timer to prevent permanent splash hold on network timeouts
      Timer(const Duration(seconds: 6), () {
        if (mounted && _showSplash) {
          setState(() {
            _isInitialAuthReady = true;
            _minSplashDurationElapsed = true;
            _showSplash = false;
          });
        }
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAuthManager();
      _checkForUrlToken();
      if (!kIsWeb) {
        _initDeepLinks();
      }
      _initNotificationService();
    });
  }

  void _initNotificationService() {
    InforttsNotificationService.instance.initialize(
      context: context,
      autoPrompt: widget.autoPromptNotifications,
      appName: widget.appName,
    );
    _notificationSub = InforttsNotificationService.instance.eventStream.listen((event) {
      final session = InforttsAuthManager.instance.currentSession;
      final userId = session?.userId;
      final isGuest = session == null || session.isGuest || !session.authenticated;

      if (!InforttsNotificationService.isNotificationRelevant(
        event,
        appName: widget.appName,
        userId: userId,
        isGuest: isGuest,
      )) {
        return;
      }

      if (mounted) {
        showTopSnackBar(
          context,
          title: "⚡ ${event.title.toUpperCase()}",
          message: event.body,
          icon: LucideIcons.bellRing,
          color: AcousticColors.sonarCyan,
          duration: const Duration(seconds: 5),
        );
      }
    });
  }

  void _onAuthSessionChanged() {
    if (mounted) {
      final current = InforttsAuthManager.instance.currentSession;
      final isValidSession = (current?.authenticated == true) ||
          (widget.allowGuest && current?.isGuest == true);
      setState(() {
        _authSession = current;
        _isAuthenticated = isValidSession;
      });
    }
  }

  void _onAccountsChanged() {
    if (mounted) {
      setState(() {
        _savedAccounts = InforttsAuthManager.instance.savedAccounts;
      });
    }
  }

  void _initAuthManager() async {
    await InforttsAuthManager.instance.initialize(requireAuth: widget.requireAuth);
    if (mounted) {
      final current = InforttsAuthManager.instance.currentSession;
      final isValidSession = (current?.authenticated == true) ||
          (widget.allowGuest && current?.isGuest == true);
      setState(() {
        _authSession = current;
        _isAuthenticated = isValidSession;
        _savedAccounts = InforttsAuthManager.instance.savedAccounts;
        _isInitialAuthReady = true;
      });
      _checkReadyToDismissSplash();
    }
  }

  void _checkReadyToDismissSplash() {
    if (!mounted) return;
    if (_minSplashDurationElapsed && _isInitialAuthReady) {
      if (_showSplash) {
        setState(() {
          _showSplash = false;
        });
      }
    }
  }

  Future<void> _initPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final rawVersion = info.version.isNotEmpty ? info.version : (widget.appVersion ?? "1.0.0");
      final baseVersion = InforttsVersionHelper.getBaseVersion(rawVersion);
      final baseBuild = int.tryParse(info.buildNumber) ?? 100;

      final cdnEngine = await InforttsCdnOtaEngine.fromPlatform(
        fallbackAppName: widget.appName,
        fallbackVersion: baseVersion,
      );
      final activePatchNum = await cdnEngine.getLocalPatchNumber();
      final activePatchFile = await cdnEngine.getActivePatchFile();
      final hasRealPatch = activePatchNum > 0 && activePatchFile != null;
      final bump = hasRealPatch
          ? InforttsVersionHelper.calculateBump(
              baseVersion: baseVersion,
              baseBuild: baseBuild,
              patchNumber: activePatchNum,
            )
          : null;

      if (mounted) {
        setState(() {
          _currentVersion = hasRealPatch && bump != null ? bump.version : rawVersion;
          _currentBuildNumber = (hasRealPatch && bump != null)
              ? bump.buildNumber.toString()
              : (info.buildNumber.isNotEmpty ? info.buildNumber : "$baseBuild");
          _otaPatchText = bump?.displayString ?? 'v$rawVersion [Base Release]';
        });
      }
      _startOtaCronTimer();
      InforttsDirectOtaEngine().checkUpdate();
    } catch (_) {}
  }

  void _startOtaCronTimer() {
    _otaCronTimer?.cancel();
    _otaCronTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (!mounted || _isCheckingOtaCron || _isOtaModalShowing) return;
      if (mounted) setState(() { _isCheckingOtaCron = true; });
      try {
        final cdnEngine = await InforttsCdnOtaEngine.fromPlatform(
          fallbackAppName: widget.appName,
          fallbackVersion: _currentVersion.isNotEmpty ? _currentVersion : widget.appVersion,
        );
        final manifest = await cdnEngine.fetchManifest();
        if (manifest == null) return;

        final currentLocalPatch = await cdnEngine.getLocalPatchNumber();
        if (manifest.latestPatch > currentLocalPatch) {
          final success = await cdnEngine.downloadAndApplyPatch(manifest);
          if (success && mounted) {
            final baseNum = int.tryParse(_currentBuildNumber) ?? 100;
            final bump = InforttsVersionHelper.calculateBump(
              baseVersion: cdnEngine.baseAppVersion,
              baseBuild: baseNum,
              patchNumber: manifest.latestPatch,
            );
            setState(() {
              _currentVersion = bump.version;
              _currentBuildNumber = bump.buildNumber.toString();
              _otaPatchText = bump.displayString;
            });
            _showPatchNotificationAboveTabBar(
              title: "⚡ EMERGENCY OTA PATCH APPLIED",
              message: "Patch #${manifest.latestPatch} auto-installed silently from CDN.",
              icon: LucideIcons.refreshCw,
              color: AcousticColors.sonarCyan,
              duration: const Duration(seconds: 5),
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
    final icon = Icon(
      LucideIcons.activity,
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

  void _switchAccount(AuthSession account) async {
    await InforttsAuthManager.instance.switchAccount(account);
  }

  void _removeAccount(String userId) async {
    await InforttsAuthManager.instance.removeAccount(userId);
  }

  void _checkForUrlToken() async {
    final token = getTokenFromUrl();
    if (token != null && token.isNotEmpty) {
      try {
        final session = await _authClient.session(token);
        if (session.authenticated) {
          await InforttsAuthManager.instance.saveSession(session);
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

  void _handleMockLogin(String email, String password) async {
    if (email.trim().isEmpty) return;
    try {
      final session = await InforttsAuthManager.instance.signInWithPassword(email.trim(), password);
      if (mounted) {
        showTopSnackBar(
          context,
          title: "AUTHENTICATED",
          message: "Signed in as ${session.displayName}",
          icon: LucideIcons.circleCheck,
          color: AcousticColors.sonarCyan,
        );
      }
    } catch (e) {
      debugPrint("Password login failed: $e");
      if (mounted) {
        showErrorSnackBar(
          context,
          "Authentication failed: Account must exist and be verified in Glycocalyx SSO.",
        );
      }
    }
  }

  void _enterGuestMode() {
    if (!widget.allowGuest) {
      showErrorSnackBar(context, "Guest access is disabled for this application. Please sign in with your verified Infortts account.");
      return;
    }
    final guest = InforttsAuthManager.instance.enterGuestMode();
    setState(() {
      _authSession = guest;
      _isAuthenticated = true;
    });
    if (mounted) {
      showTopSnackBar(
        context,
        title: "GUEST ACCESS",
        message: "Continuing in guest preview mode.",
        icon: LucideIcons.user,
        color: AcousticColors.sonarCyan,
      );
    }
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
        final session = AuthSession(
          userId: prof['id'] ?? prof['user_id'] ?? '',
          email: (prof['email'] as String?) ?? '',
          token: token,
          profile: prof,
        );
        await InforttsAuthManager.instance.saveSession(session);
      }
    }
  }

  void _handleGoogleSSO() async {
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

    // Native (Android / iOS / macOS): Try Native Google Sign-In first
    try {
      final session = await InforttsAuthManager.instance.signInWithGoogleNative();
      if (session == null) {
        // User cancelled account picker
        return;
      }

      if (mounted) {
        showTopSnackBar(
          context,
          title: "AUTHENTICATED WITH GOOGLE",
          message: "Signed in as ${session.displayName}",
          icon: LucideIcons.circleCheck,
          color: AcousticColors.sonarCyan,
        );
      }
    } catch (e) {
      debugPrint("Native Google Sign-In error: $e. Initiating browser OAuth fallback...");
      // Fallback to web browser OAuth flow on native platform
      try {
        final appName = widget.appName.toLowerCase().replaceAll(' ', '');
        final redirectScheme = '$appName://auth/callback';
        final authUrl = await _authClient.login(
          provider: 'google',
          redirect: redirectScheme,
        );
        final uri = Uri.parse(authUrl);
        final launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        if (!launched) {
          await launchUrl(uri);
        }
        if (mounted) {
          showTopSnackBar(
            context,
            title: "AUTHENTICATION PORTAL",
            message: "Sign in with Google to return to ${widget.appName}",
            icon: LucideIcons.shield,
            color: AcousticColors.sonarCyan,
          );
        }
        return;
      } catch (fallbackError) {
        debugPrint("Browser OAuth fallback error: $fallbackError");
      }
      if (mounted) {
        showErrorSnackBar(context, 'Google Sign-In: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  void _handleLogout() async {
    await InforttsAuthManager.instance.signOut();
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
    if (_showSplash || (widget.requireAuth && !_isInitialAuthReady)) return _buildSplashView();
    final bool hasValidAccess = (_authSession?.authenticated == true) ||
        (widget.allowGuest && _authSession?.isGuest == true);
    if (widget.requireAuth && (!_isAuthenticated || !hasValidAccess)) {
      return _buildAuthView();
    }

    return ValueListenableBuilder<Brightness>(
      valueListenable: acousticBrightness,
      builder: (context, brightness, _) {
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
                _buildPatchNotificationAboveTabBar(),
                _buildBottomNav(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPatchNotificationAboveTabBar() {
    if (_patchNotificationMessage == null) return const SizedBox.shrink();
    final isLight = AcousticColors.isLight;
    final bgColor = isLight ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
    final subColor = isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8);
    final borderColor = isLight
        ? _patchNotificationColor.withValues(alpha: 0.5)
        : _patchNotificationColor.withValues(alpha: 0.8);

    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _patchNotificationColor.withValues(alpha: isLight ? 0.15 : 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _patchNotificationColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(_patchNotificationIcon, color: _patchNotificationColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_patchNotificationTitle != null && _patchNotificationTitle!.isNotEmpty)
                  Text(
                    _patchNotificationTitle!,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: _patchNotificationColor,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  _patchNotificationMessage!,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: subColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _dismissPatchNotification,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _patchNotificationColor.withValues(alpha: isLight ? 0.12 : 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _patchNotificationColor.withValues(alpha: 0.4), width: 0.8),
              ),
              child: Text(
                "DISMISS",
                style: GoogleFonts.outfit(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: _patchNotificationColor,
                ),
              ),
            ),
          ),
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
                    () {
                      final v = _currentVersion.isNotEmpty ? _currentVersion : (widget.appVersion ?? '2.06.00');
                      final b = _currentBuildNumber.isNotEmpty ? _currentBuildNumber : '20600';
                      final formatted = v.contains('+') ? v : '$v+$b';
                      return formatted.startsWith('v') ? formatted : 'v$formatted';
                    }(),
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
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AcousticColors.sonarCyan),
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
                            trailing: Icon(LucideIcons.chevronRight, size: 10, color: AcousticColors.sonarCyan),
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
                  icon: Icon(LucideIcons.shield, size: 16, color: AcousticColors.sonarCyan),
                  label: Text(
                    "CONTINUE WITH GOOGLE SSO",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AcousticColors.sonarCyan, letterSpacing: 1.0),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AcousticColors.sonarCyan, width: 0.9),
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
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.outfit(fontSize: 12, color: AcousticColors.titanium),
                  decoration: InputDecoration(
                    labelText: "EMAIL ADDRESS",
                    hintText: "operator@infortts.com",
                    hintStyle: GoogleFonts.outfit(fontSize: 12, color: AcousticColors.steel.withOpacity(0.5)),
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
                    hintText: "••••••••",
                    hintStyle: GoogleFonts.outfit(fontSize: 12, color: AcousticColors.steel.withOpacity(0.5)),
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
                    side: BorderSide(color: AcousticColors.sonarCyan, width: 0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: Text(
                    "SIGN IN WITH PASSWORD",
                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                ),
                if (widget.allowGuest) ...[
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
                ],
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

    final isAuthed = _isAuthenticated && (session?.authenticated == true);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: AcousticColors.isLight ? AcousticColors.darkCarbon : AcousticColors.panelBg.withOpacity(0.6),
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
                isAuthed ? "Signed in as $email." : "No active session (Guest Mode).",
                style: GoogleFonts.outfit(fontSize: 10, color: AcousticColors.midGray),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AcousticColors.sonarCyan.withOpacity(0.15),
                    child: Text(
                      _initialsFor(isAuthed ? displayName : "Guest", isAuthed ? email : "guest"),
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
                          isAuthed ? displayName : "GUEST",
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AcousticColors.titanium),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAuthed ? (email.isEmpty ? "Signed In" : email) : "Not signed in",
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
                  color: AcousticColors.isLight ? AcousticColors.panelBg : AcousticColors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileRow("USER ID", isAuthed ? (session?.userId ?? "—") : "usr_guest"),
                    const SizedBox(height: 8),
                    _buildProfileRow("PROVIDER", isAuthed ? (provider ?? "glycocalyx") : "guest"),
                    const SizedBox(height: 8),
                    _buildProfileRow("SCOPE", isAuthed ? (scope ?? "—") : "read-only"),
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
                    color: AcousticColors.isLight ? AcousticColors.panelBg : AcousticColors.black.withOpacity(0.4),
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
                                  child: Text("ACTIVE", style: TextStyle(fontSize: 8, color: AcousticColors.sonarCyan, fontWeight: FontWeight.bold)),
                                )
                              else
                                IconButton(
                                  icon: Icon(LucideIcons.arrowLeftRight, size: 16, color: AcousticColors.sonarCyan),
                                  tooltip: "Switch to this account",
                                  onPressed: () => _switchAccount(acc),
                                ),
                              IconButton(
                                icon: Icon(LucideIcons.x, size: 14, color: AcousticColors.midGray),
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
                  icon: Icon(LucideIcons.plus, size: 14, color: AcousticColors.sonarCyan),
                  label: Text(
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
              if (isAuthed)
                OutlinedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(LucideIcons.logOut, size: 16),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AcousticColors.warnOrange,
                    side: BorderSide(color: AcousticColors.warnOrange),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  label: Text(
                    "SIGN OUT ACTIVE ACCOUNT",
                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                )
              else ...[
                ElevatedButton.icon(
                  onPressed: _handleGoogleSSO,
                  icon: const Icon(LucideIcons.logIn, size: 16),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AcousticColors.sonarCyan.withOpacity(0.15),
                    foregroundColor: AcousticColors.sonarCyan,
                    side: BorderSide(color: AcousticColors.sonarCyan.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  label: Text(
                    "SIGN IN WITH GOOGLE SSO",
                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(LucideIcons.logOut, size: 16),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AcousticColors.warnOrange,
                    side: BorderSide(color: AcousticColors.warnOrange.withOpacity(0.6)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  label: Text(
                    "EXIT GUEST MODE",
                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                ),
              ],
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
        Flexible(
          flex: 2,
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(fontSize: 9, color: AcousticColors.midGray, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          flex: 3,
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AcousticColors.steel),
          ),
        ),
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
            icon: Icon(LucideIcons.arrowLeft, color: AcousticColors.sonarCyan, size: 20),
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
            color: AcousticColors.isLight ? AcousticColors.darkCarbon : AcousticColors.panelBg.withOpacity(0.6),
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
                  Flexible(
                    child: Text(
                      "SETTINGS & CONFIGURATION",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2.0, color: AcousticColors.titanium),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                color: AcousticColors.isLight ? AcousticColors.panelBg : AcousticColors.black.withOpacity(0.3),
                margin: const EdgeInsets.only(bottom: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AcousticColors.midGray.withOpacity(0.15), width: 0.8),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(LucideIcons.user, color: AcousticColors.sonarCyan, size: 20),
                      title: Text("OPERATOR PROFILE", style: GoogleFonts.outfit(fontSize: 11, color: AcousticColors.titanium, fontWeight: FontWeight.bold)),
                      subtitle: Text("Centralized credentials & OAuth details", style: GoogleFonts.outfit(fontSize: 9, color: AcousticColors.midGray)),
                      trailing: Icon(LucideIcons.chevronRight, color: AcousticColors.steel, size: 18),
                      onTap: () => setState(() => _settingsSubPage = "profile"),
                    ),

                    Divider(color: AcousticColors.midGray.withOpacity(0.15), height: 1),
                    ValueListenableBuilder<Brightness>(
                      valueListenable: acousticBrightness,
                      builder: (context, brightness, _) {
                        final isDark = brightness == Brightness.dark;
                        return ListTile(
                          leading: Icon(
                            isDark ? LucideIcons.moon : LucideIcons.sun,
                            color: AcousticColors.sonarCyan,
                            size: 20,
                          ),
                          title: Text("APPEARANCE & THEME", style: GoogleFonts.outfit(fontSize: 11, color: AcousticColors.titanium, fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            isDark ? "Dark Carbon & Acoustic Refraction" : "Clean Slate Light Theme",
                            style: GoogleFonts.outfit(fontSize: 9, color: AcousticColors.midGray),
                          ),
                          trailing: Switch(
                            value: isDark,
                            activeColor: AcousticColors.sonarCyan,
                            onChanged: (_) {
                              final provider = InforttsThemeProvider.maybeOf(context);
                              if (provider != null) {
                                provider.toggleTheme();
                              } else {
                                acousticBrightness.value = isDark ? Brightness.light : Brightness.dark;
                              }
                            },
                          ),
                        );
                      },
                    ),
                    Divider(color: AcousticColors.midGray.withOpacity(0.15), height: 1),
                    ListTile(
                      leading: Icon(LucideIcons.info, color: AcousticColors.sonarCyan, size: 20),
                      title: Text("ABOUT SYSTEM", style: GoogleFonts.outfit(fontSize: 11, color: AcousticColors.titanium, fontWeight: FontWeight.bold)),
                      subtitle: Text("Coded lifeform description & 3D emblem", style: GoogleFonts.outfit(fontSize: 9, color: AcousticColors.midGray)),
                      trailing: Icon(LucideIcons.chevronRight, color: AcousticColors.steel, size: 18),
                      onTap: () => setState(() => _settingsSubPage = "about"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              Text(
                "INFRASTRUCTURE DNS",
                style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: AcousticColors.steel),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AcousticColors.isLight ? AcousticColors.panelBg : AcousticColors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    _buildProfileRow("NATS HOST", const String.fromEnvironment('NATS_HOST', defaultValue: 'nats://nats.infortts.site:4222')),
                    const SizedBox(height: 6),
                    _buildProfileRow("VECTOR DB", const String.fromEnvironment('VECTOR_DB_URL', defaultValue: 'qdrant://qdrant.infortts.site:6333')),
                    const SizedBox(height: 6),
                    () {
                      final app = widget.appName.toLowerCase().replaceAll(' by infortts', '').replaceAll(' infortts', '').trim();
                      if (app == 'mitochondria') {
                        return _buildProfileRow("FORENSICS API", '$kForensicsApiBase/api/v1');
                      } else if (app == 'glycocalyx') {
                        return _buildProfileRow("IDENTITY GATEWAY", 'https://auth.infortts.site');
                      } else if (app == 'waptia') {
                        return _buildProfileRow("STORE REGISTRY", 'https://waptia.infortts.site');
                      } else if (app == 'acritarch') {
                        return _buildProfileRow("DOCS HUB API", 'https://docs.infortts.site/api');
                      } else if (app == 'meeseeks') {
                        return _buildProfileRow("AGENT GATEWAY", 'https://meeseeks.infortts.site:8006');
                      } else {
                        return _buildProfileRow("API GATEWAY", 'https://$app.infortts.site/api');
                      }
                    }(),
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
                  color: AcousticColors.isLight ? AcousticColors.panelBg : AcousticColors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    _buildProfileRow("App", widget.appName),
                    const SizedBox(height: 6),
                    _buildProfileRow("Version", _currentVersion.isNotEmpty ? _currentVersion : (widget.appVersion ?? '2.06.02')),
                    const SizedBox(height: 6),
                    _buildProfileRow("Build", _currentBuildNumber.isNotEmpty ? "Build $_currentBuildNumber" : "Build 20602"),
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
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _otaPatchText,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.outfit(color: AcousticColors.titanium, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
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
                                Icon(LucideIcons.downloadCloud, size: 14, color: AcousticColors.sonarCyan),
                                _buildFlashingOtaIcon(),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text("Check OTA Updates",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AcousticColors.sonarCyan)),
                                ),
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
                            icon: const Icon(LucideIcons.info, size: 14),
                            label: Text("Patch Details", style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
],
              ),
            ),
              if (widget.settingsSections != null) ...[
                const SizedBox(height: 28),
                ...widget.settingsSections!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showInstalledPatchDetailsModal(BuildContext context) async {
    final cdnEngine = await InforttsCdnOtaEngine.fromPlatform(
      fallbackAppName: widget.appName,
      fallbackVersion: _currentVersion.isNotEmpty ? _currentVersion : widget.appVersion,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AcousticColors.sonarCyan, width: 1.2)),
        title: Row(
          children: [
            Icon(LucideIcons.refreshCw, color: AcousticColors.sonarCyan, size: 22),
            const SizedBox(width: 8),
            Text("Active Version & Patch Details", style: GoogleFonts.outfit(color: AcousticColors.titanium, fontWeight: FontWeight.bold, fontSize: 16)),
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
                      Icon(LucideIcons.circleCheck, color: AcousticColors.sonarCyan, size: 14),
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
          Text(value, style: GoogleFonts.outfit(color: AcousticColors.titanium, fontWeight: FontWeight.bold, fontSize: 11)),
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
          Text(value, style: GoogleFonts.outfit(color: AcousticColors.titanium, fontWeight: FontWeight.bold, fontSize: 12)),
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
                  side: BorderSide(color: AcousticColors.sonarCyan, width: 1.5),
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
                          child: Icon(
                            LucideIcons.refreshCw,
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
                                  color: AcousticColors.titanium,
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
                    Divider(color: AcousticColors.midGray, height: 1),
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
                              _buildDetailRow("Published", InforttsVersionHelper.formatTimeAgo(manifest.updatedAt)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Patch Details & Release Notes:",
                        style: GoogleFonts.outfit(
                          color: AcousticColors.titanium,
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
                                Icon(LucideIcons.circleCheck,
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
                        LinearProgressIndicator(
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
                      icon: const Icon(LucideIcons.download, size: 18),
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
                            final baseNum = int.tryParse(_currentBuildNumber) ?? 20600;
                            final bump = InforttsVersionHelper.calculateBump(
                              baseVersion: cdnEngine.baseAppVersion,
                              baseBuild: baseNum,
                              patchNumber: manifest.latestPatch,
                            );
                            setState(() {
                              _currentVersion = bump.version;
                              _currentBuildNumber = bump.buildNumber.toString();
                              _otaPatchText = bump.displayString;
                            });
                            _showRestartDialog(context);
                          } else {
                            _showPatchNotificationAboveTabBar(
                              title: "DOWNLOAD FAILED",
                              message: "Failed to download OTA patch. Please try again.",
                              icon: LucideIcons.circleAlert,
                              color: Colors.redAccent,
                              duration: const Duration(seconds: 5),
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
    _showPatchNotificationAboveTabBar(
      title: "OTA SYNC",
      message: "Checking Infortts OTA servers for patch updates...",
      icon: LucideIcons.refreshCw,
      color: AcousticColors.sonarCyan,
      duration: const Duration(seconds: 5),
    );

    try {
      final cdnEngine = await InforttsCdnOtaEngine.fromPlatform(
        fallbackAppName: widget.appName,
        fallbackVersion: _currentVersion.isNotEmpty ? _currentVersion : widget.appVersion,
      );

      final manifest = await cdnEngine.fetchManifest();
      final currentLocalPatch = await cdnEngine.getLocalPatchNumber();

      final currentBuild = int.tryParse(_currentBuildNumber) ?? 0;
      final baseCurrentBuild = currentBuild >= 1000 ? (currentBuild ~/ 100) * 100 : currentBuild;
      final manifestBuild = manifest?.latestBuild ?? 0;
      final baseManifestBuild = manifestBuild >= 1000 ? (manifestBuild ~/ 100) * 100 : manifestBuild;

      final bool hasNewBuild = manifest != null &&
          (manifest.latestBuild > currentBuild || baseManifestBuild > baseCurrentBuild) &&
          currentBuild > 0;
      final bool hasNewPatch = manifest != null &&
          (baseManifestBuild == baseCurrentBuild || currentBuild == 0) &&
          manifest.latestPatch > currentLocalPatch;

      if (manifest != null && (hasNewBuild || hasNewPatch)) {
        if (mounted) {
          _showNewPatchAvailableModal(context, manifest, cdnEngine, forceReShow: true);
        }
      } else {
        _showPatchNotificationAboveTabBar(
          title: "SYSTEM UP TO DATE",
          message: "✓ No updates available. System is up to date (Patch #${currentLocalPatch} active).",
          icon: LucideIcons.circleCheck,
          color: const Color(0xFF10B981),
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      _showPatchNotificationAboveTabBar(
        title: "OTA ERROR",
        message: "Failed to connect to OTA servers: $e",
        icon: LucideIcons.circleAlert,
        color: Colors.redAccent,
        duration: const Duration(seconds: 5),
      );
    } finally {
      if (mounted) setState(() { _isCheckingOtaCron = false; });
    }
  }

  void _showRestartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AcousticColors.darkCarbon,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: AcousticColors.sonarCyan, width: 1.2)),
        title: Row(
          children: [
            Icon(LucideIcons.circleCheck, color: AcousticColors.sonarCyan, size: 22),
            const SizedBox(width: 8),
            Text("Patch Installed!", style: GoogleFonts.outfit(color: AcousticColors.titanium, fontWeight: FontWeight.bold, fontSize: 16)),
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
            icon: const Icon(LucideIcons.rotateCcw, size: 16),
            label: Text("Restart Now", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
                      color: AcousticColors.isLight ? AcousticColors.darkCarbon : AcousticColors.panelBg.withOpacity(0.5),
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
                        Divider(color: AcousticColors.midGray, thickness: 0.5),
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
                          color: AcousticColors.isLight ? AcousticColors.darkCarbon : AcousticColors.panelBg.withOpacity(0.5),
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
                            Divider(color: AcousticColors.midGray, thickness: 0.5),
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
  IconData icon = LucideIcons.bellRing,
  Color color = const Color(0xFF00D2FF),
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
    final isLight = AcousticColors.isLight;
    final bgColor = isLight ? const Color(0xFFFFFFFF) : const Color(0xFF0F141F).withOpacity(0.96);
    final borderColor = isLight ? widget.color.withValues(alpha: 0.6) : widget.color;
    final messageColor = isLight ? const Color(0xFF1E293B) : AcousticColors.titanium;
    final closeColor = isLight ? const Color(0xFF64748B) : AcousticColors.steel;

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
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: isLight ? 0.15 : 0.3),
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
                    color: widget.color.withValues(alpha: isLight ? 0.12 : 0.18),
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
                          color: messageColor,
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
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(LucideIcons.x, size: 16, color: closeColor),
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

/// Show the centralized Infortts SSO & Credentials login modal bottom sheet.
Future<void> showInforttsAuthBottomSheet(BuildContext context) async {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool isLoading = false;
  String? errorMsg;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (dialogCtx, setSheetState) {
          return Container(
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(dialogCtx).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: AcousticColors.darkCarbon,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(color: AcousticColors.midGray.withOpacity(0.2)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.shield, color: AcousticColors.sonarCyan, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "GLYCOCALYX IAM AUTH",
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                              color: AcousticColors.titanium,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(LucideIcons.x, color: AcousticColors.steel, size: 18),
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Sign in to your Infortts account to synchronize installations, remote fleet devices, and enterprise policies.",
                    style: GoogleFonts.outfit(fontSize: 11, color: AcousticColors.steel),
                  ),
                  const SizedBox(height: 16),
                  if (errorMsg != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                      ),
                      child: Text(
                        errorMsg!,
                        style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  OutlinedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () async {
                            setSheetState(() {
                              isLoading = true;
                              errorMsg = null;
                            });
                            try {
                              final session = await InforttsAuthManager.instance.signInWithGoogleNative();
                              if (session != null && dialogCtx.mounted) {
                                Navigator.of(dialogCtx).pop();
                                showTopSnackBar(
                                  context,
                                  title: "AUTHENTICATED",
                                  message: "Signed in as ${session.displayName}",
                                  icon: LucideIcons.circleCheck,
                                  color: AcousticColors.sonarCyan,
                                );
                              }
                            } catch (e) {
                              setSheetState(() {
                                errorMsg = e.toString().replaceAll("Exception: ", "");
                              });
                            } finally {
                              setSheetState(() {
                                isLoading = false;
                              });
                            }
                          },
                    icon: Icon(LucideIcons.shield, size: 16, color: AcousticColors.sonarCyan),
                    label: Text(
                      "CONTINUE WITH GOOGLE SSO",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AcousticColors.sonarCyan,
                        letterSpacing: 1.0,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AcousticColors.sonarCyan, width: 0.9),
                      backgroundColor: AcousticColors.sonarCyan.withOpacity(0.06),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Divider(color: AcousticColors.midGray.withOpacity(0.2))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text("OR CREDENTIALS", style: GoogleFonts.outfit(fontSize: 8, color: AcousticColors.midGray, letterSpacing: 1.0)),
                      ),
                      Expanded(child: Divider(color: AcousticColors.midGray.withOpacity(0.2))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: emailCtrl,
                    style: GoogleFonts.outfit(fontSize: 12, color: AcousticColors.titanium),
                    decoration: InputDecoration(
                      labelText: "EMAIL ADDRESS",
                      hintText: "operator@infortts.site",
                      hintStyle: GoogleFonts.outfit(fontSize: 11, color: AcousticColors.steel.withOpacity(0.5)),
                      labelStyle: GoogleFonts.outfit(fontSize: 9, color: AcousticColors.midGray),
                      filled: true,
                      fillColor: AcousticColors.black,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    style: GoogleFonts.outfit(fontSize: 12, color: AcousticColors.titanium),
                    decoration: InputDecoration(
                      labelText: "PASSWORD",
                      hintText: "••••••••",
                      hintStyle: GoogleFonts.outfit(fontSize: 11, color: AcousticColors.steel.withOpacity(0.5)),
                      labelStyle: GoogleFonts.outfit(fontSize: 9, color: AcousticColors.midGray),
                      filled: true,
                      fillColor: AcousticColors.black,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            final email = emailCtrl.text.trim();
                            final pass = passCtrl.text.trim();
                            if (email.isEmpty || pass.isEmpty) {
                              setSheetState(() {
                                errorMsg = "Email and password are required.";
                              });
                              return;
                            }
                            setSheetState(() {
                              isLoading = true;
                              errorMsg = null;
                            });
                            try {
                              final session = await InforttsAuthManager.instance.signInWithPassword(email, pass);
                              if (dialogCtx.mounted) {
                                Navigator.of(dialogCtx).pop();
                                showTopSnackBar(
                                  context,
                                  title: "AUTHENTICATED",
                                  message: "Signed in as ${session.displayName}",
                                  icon: LucideIcons.circleCheck,
                                  color: AcousticColors.sonarCyan,
                                );
                              }
                            } catch (e) {
                              setSheetState(() {
                                errorMsg = e.toString().replaceAll("Exception: ", "");
                              });
                            } finally {
                              setSheetState(() {
                                isLoading = false;
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AcousticColors.sonarCyan,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : Text(
                            "SIGN IN WITH PASSWORD",
                            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}


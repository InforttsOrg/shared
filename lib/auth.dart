library infortts_shared_auth;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthConfig {
  final String baseUrl;

  const AuthConfig({this.baseUrl = ''});

  String get effectiveBaseUrl {
    if (baseUrl.isNotEmpty) return baseUrl;
    const envBase = String.fromEnvironment('WAPTIA_AUTH_BASE');
    if (envBase.isNotEmpty) return envBase;
    if (kIsWeb) {
      final override = Uri.base.queryParameters['auth_base'];
      if (override != null && override.isNotEmpty) {
        return override;
      }
    }
    return 'https://auth.infortts.site';
  }
}

class AuthSession {
  final String userId;
  final String email;
  final String? token;
  final Map<String, dynamic>? profile;

  AuthSession({
    required this.userId,
    required this.email,
    this.token,
    this.profile,
  });

  bool get authenticated => userId.isNotEmpty && userId != 'usr_guest';
  bool get isGuest => userId == 'usr_guest' || userId.isEmpty;
  bool get isPlaceholder =>
      userId == 'usr_operator_local' ||
      (profile?['display_name'] as String?) == 'OPERATOR LOCAL' ||
      email == 'operator@infortts.site';

  String get displayName {
    final dn = profile?['display_name'] as String?;
    if (dn != null && dn.trim().isNotEmpty) return dn.trim();
    final nm = profile?['name'] as String?;
    if (nm != null && nm.trim().isNotEmpty) return nm.trim();
    if (email.isNotEmpty) return email.split('@')[0];
    if (isGuest) return 'Guest';
    return 'User';
  }

  String get username => (profile?['username'] as String?) ?? displayName.toLowerCase().replaceAll(' ', '_');
  String? get role => profile?['role'] as String?;
  bool get isSuperadmin =>
      role == 'superadmin' ||
      role == 'admin' ||
      (profile?['is_superadmin'] == true) ||
      (profile?['superadmin'] == true) ||
      email == 'operator@infortts.site' ||
      (email.isNotEmpty && email.toLowerCase().endsWith('@infortts.com'));
  String? get provider => (profile?['provider'] as String?) ?? (isGuest ? 'guest' : 'glycocalyx');
  String? get avatarUrl => (profile?['photo_url'] as String?) ?? (profile?['avatar_url'] as String?);

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      userId: json['user_id'] as String? ?? json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      token: json['token'] as String? ?? json['access_token'] as String?,
      profile: json['profile'] as Map<String, dynamic>? ?? json['user_metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      if (token != null) 'token': token,
      if (profile != null) 'profile': profile,
    };
  }

  AuthSession copyWith({
    String? userId,
    String? email,
    String? token,
    Map<String, dynamic>? profile,
  }) {
    return AuthSession(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      token: token ?? this.token,
      profile: profile ?? this.profile,
    );
  }
}

class GlycocalyxAuth {
  final AuthConfig config;
  final http.Client _client;

  GlycocalyxAuth({AuthConfig? config, http.Client? client})
      : config = config ?? const AuthConfig(),
        _client = client ?? http.Client();

  String get _apiBase => config.effectiveBaseUrl;

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$_apiBase$path').replace(queryParameters: query);
  }

  Map<String, String> _headers([String? token]) {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  /// Initiate OAuth login via the Glycocalyx gateway — returns the auth URL to redirect to (Web only).
  Future<String> login({
    String provider = 'google',
    String? redirect,
  }) async {
    final targetRedirect = redirect ?? config.effectiveBaseUrl;
    final resp = await _client.post(
      _uri('/auth/login'),
      headers: _headers(),
      body: jsonEncode({
        'provider': provider,
        'redirect': targetRedirect,
      }),
    );
    if (resp.statusCode != 200) {
      throw Exception('Login failed: ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data['auth_url'] as String;
  }

  /// Native (mobile / desktop) Google sign-in: exchange a Google [idToken] for a unified
  /// Glycocalyx JWT via the gateway, so native apps share one identity/token
  /// with web apps. Returns the TokenResponse map (token/user_id/email/profile)
  /// or throws on failure.
  Future<Map<String, dynamic>> loginWithGoogle({
    String? idToken,
    String? accessToken,
  }) async {
    final resp = await _client.post(
      _uri('/auth/google'),
      headers: _headers(),
      body: jsonEncode({
        if (idToken != null && idToken.isNotEmpty) 'id_token': idToken,
        if (accessToken != null && accessToken.isNotEmpty) 'access_token': accessToken,
      }),
    ).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      throw Exception('Native Google login failed: ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// Email + Password login against Glycocalyx gateway.
  Future<Map<String, dynamic>> loginWithPassword(String email, String password) async {
    final resp = await _client.post(
      _uri('/auth/login/password'),
      headers: _headers(),
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    ).timeout(const Duration(seconds: 15));
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception((data['message'] ?? data['error'] ?? 'Login failed (${resp.statusCode})').toString());
    }
    return data;
  }

  /// Email + Password account registration against Glycocalyx gateway.
  Future<Map<String, dynamic>> registerWithPassword(String email, String password) async {
    final resp = await _client.post(
      _uri('/auth/register'),
      headers: _headers(),
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    ).timeout(const Duration(seconds: 15));
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception((data['message'] ?? data['error'] ?? 'Registration failed (${resp.statusCode})').toString());
    }
    return data;
  }

  /// Validate session with a token and return session info.
  Future<AuthSession> session(String token) async {
    final resp = await _client.get(
      _uri('/auth/session'),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 8));
    if (resp.statusCode != 200) {
      return AuthSession(userId: '', email: '');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return AuthSession.fromJson(data).copyWith(token: token);
  }

  /// Logout — clear server-side session.
  Future<void> logout(String token) async {
    try {
      await _client.post(
        _uri('/auth/logout'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  /// Fetch user profile.
  Future<Map<String, dynamic>?> profile(String token) async {
    final resp = await _client.get(
      _uri('/user/profile'),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 6));
    if (resp.statusCode != 200) return null;
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// Update user profile.
  Future<Map<String, dynamic>?> updateProfile(
    String token, {
    String? displayName,
    String? username,
    String? avatarUrl,
  }) async {
    final resp = await _client.put(
      _uri('/user/profile'),
      headers: _headers(token),
      body: jsonEncode({
        if (displayName != null) 'display_name': displayName,
        if (username != null) 'username': username,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      }),
    ).timeout(const Duration(seconds: 8));
    if (resp.statusCode != 200) return null;
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// Check username availability.
  Future<bool> checkUsername(String token, String username) async {
    final resp = await _client.get(
      _uri('/user/username/check', {'username': username}),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 5));
    if (resp.statusCode != 200) return false;
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data['available'] as bool? ?? false;
  }
}

/// Centralized Auth Manager for Infortts ecosystem applications.
/// Provides unified state, native Google SSO without web browser redirections,
/// optional guest mode, session persistence, and multi-account management.
class InforttsAuthManager {
  static final InforttsAuthManager instance = InforttsAuthManager._();

  final GlycocalyxAuth api;
  final ValueNotifier<AuthSession?> sessionNotifier = ValueNotifier<AuthSession?>(null);
  final ValueNotifier<String?> tokenNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<List<AuthSession>> accountsNotifier = ValueNotifier<List<AuthSession>>([]);
  bool _initialized = false;

  static const String defaultServerClientId =
      '92924706833-1hmtr9ftm6q57k4g18fteu7jov70a6fc.apps.googleusercontent.com';

  InforttsAuthManager._({GlycocalyxAuth? api}) : api = api ?? GlycocalyxAuth();

  bool get isAuthenticated => sessionNotifier.value?.authenticated ?? false;
  bool get isGuest => sessionNotifier.value?.isGuest ?? false;
  AuthSession? get currentSession => sessionNotifier.value;
  String? get currentToken => tokenNotifier.value;
  List<AuthSession> get savedAccounts => accountsNotifier.value;

  /// Initialize session from local storage. If no session exists and [requireAuth] is false,
  /// enters guest mode so the user can immediately use the app without being blocked.
  Future<void> initialize({bool requireAuth = true}) async {
    if (_initialized) return;
    _initialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('infortts_auth_userId');
      final email = prefs.getString('infortts_auth_email');
      final token = prefs.getString('infortts_auth_token');
      final profileStr = prefs.getString('infortts_auth_profile');

      // Load all saved accounts
      final allAccountsStr = prefs.getString('infortts_all_saved_accounts');
      if (allAccountsStr != null) {
        try {
          final list = jsonDecode(allAccountsStr) as List;
          accountsNotifier.value = list
              .map((e) => AuthSession.fromJson(Map<String, dynamic>.from(e)))
              .where((a) => !a.isPlaceholder)
              .toList();
        } catch (_) {}
      }

      if (userId != null && userId.isNotEmpty) {
        Map<String, dynamic> profile = {};
        if (profileStr != null) {
          try {
            profile = jsonDecode(profileStr);
          } catch (_) {}
        }
        final session = AuthSession(
          userId: userId,
          email: email ?? '',
          token: token,
          profile: profile,
        );

        if (!session.isPlaceholder) {
          sessionNotifier.value = session;
          tokenNotifier.value = token;
          if (session.authenticated && !accountsNotifier.value.any((a) => a.userId == session.userId)) {
            accountsNotifier.value = [session, ...accountsNotifier.value];
          }
          // Asynchronously validate / sync profile in background for authenticated sessions
          if (session.authenticated) {
            unawaited(syncLiveProfile());
          }
          return;
        }
      }

      // If no valid authenticated session found:
      if (!requireAuth) {
        enterGuestMode();
      } else {
        sessionNotifier.value = null;
        tokenNotifier.value = null;
      }
    } catch (e) {
      debugPrint('InforttsAuthManager initialization error: $e');
      if (!requireAuth) {
        enterGuestMode();
      } else {
        sessionNotifier.value = null;
        tokenNotifier.value = null;
      }
    }
  }

  /// Perform native in-app Google Sign-In on mobile/desktop without launching web browser.
  Future<AuthSession?> signInWithGoogleNative({
    String? serverClientId,
  }) async {
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: serverClientId ?? defaultServerClientId,
        scopes: const ['email', 'profile'],
      );

      final account = await googleSignIn.signIn();
      if (account == null) {
        // User cancelled account picker
        return null;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;

      if ((idToken == null || idToken.isEmpty) && (accessToken == null || accessToken.isEmpty)) {
        throw Exception('Google Sign-In returned no authentication credentials.');
      }

      final data = await api.loginWithGoogle(
        idToken: idToken,
        accessToken: accessToken,
      );

      final token = data['token']?.toString() ?? (data['access_token']?.toString() ?? '');
      if (token.isEmpty) {
        throw Exception('Gateway returned no session token.');
      }

      final remoteSession = await api.session(token);
      final session = (remoteSession.authenticated)
          ? remoteSession.copyWith(token: token)
          : AuthSession(
              userId: data['user_id']?.toString() ?? data['id']?.toString() ?? 'usr_${account.id}',
              email: account.email,
              token: token,
              profile: {
                'display_name': account.displayName ?? account.email.split('@')[0],
                'name': account.displayName,
                'email': account.email,
                'photo_url': account.photoUrl,
                'provider': 'google',
              },
            );

      await saveSession(session);
      return session;
    } catch (e) {
      debugPrint('Native Google Sign-In error: $e');
      rethrow;
    }
  }

  /// Sign in using email and password against Glycocalyx gateway.
  Future<AuthSession> signInWithPassword(String email, String password) async {
    final data = await api.loginWithPassword(email, password);
    final token = data['token']?.toString() ?? (data['access_token']?.toString() ?? '');
    if (token.isEmpty) {
      throw Exception('Gateway returned no session token.');
    }

    final remoteSession = await api.session(token);
    final session = remoteSession.authenticated
        ? remoteSession.copyWith(token: token)
        : AuthSession(
            userId: data['user_id']?.toString() ?? data['id']?.toString() ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
            email: email.trim(),
            token: token,
            profile: data['profile'] as Map<String, dynamic>? ?? {
              'display_name': email.split('@')[0].toUpperCase(),
              'email': email.trim(),
            },
          );

    await saveSession(session);
    return session;
  }

  /// Register new account with email and password.
  Future<AuthSession> registerWithPassword(String email, String password) async {
    final data = await api.registerWithPassword(email, password);
    final token = data['token']?.toString() ?? (data['access_token']?.toString() ?? '');
    if (token.isEmpty) {
      throw Exception('Gateway returned no session token.');
    }

    final session = AuthSession(
      userId: data['user_id']?.toString() ?? data['id']?.toString() ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
      email: email.trim(),
      token: token,
      profile: data['profile'] as Map<String, dynamic>? ?? {
        'display_name': email.split('@')[0].toUpperCase(),
        'email': email.trim(),
      },
    );

    await saveSession(session);
    return session;
  }

  /// Enter guest / demo mode.
  AuthSession enterGuestMode({bool persist = true}) {
    final guest = AuthSession(
      userId: 'usr_guest',
      email: '',
      profile: {
        'display_name': 'GUEST',
        'username': 'guest',
        'provider': 'guest',
      },
    );
    sessionNotifier.value = guest;
    tokenNotifier.value = null;
    if (persist) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('infortts_auth_userId', 'usr_guest');
        prefs.setString('infortts_auth_email', '');
        prefs.remove('infortts_auth_token');
        if (guest.profile != null) {
          prefs.setString('infortts_auth_profile', jsonEncode(guest.profile));
        }
      }).catchError((_) {});
    }
    return guest;
  }

  /// Save session to persistent storage and multi-account list.
  Future<void> saveSession(AuthSession session) async {
    sessionNotifier.value = session;
    tokenNotifier.value = session.token;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('infortts_auth_userId', session.userId);
    await prefs.setString('infortts_auth_email', session.email);
    if (session.token != null && session.token!.isNotEmpty) {
      await prefs.setString('infortts_auth_token', session.token!);
    } else {
      await prefs.remove('infortts_auth_token');
    }
    if (session.profile != null) {
      await prefs.setString('infortts_auth_profile', jsonEncode(session.profile));
    }

    if (session.authenticated) {
      final updatedList = List<AuthSession>.from(accountsNotifier.value)
        ..removeWhere((a) => a.userId == session.userId || (a.email.isNotEmpty && a.email == session.email))
        ..insert(0, session);
      accountsNotifier.value = updatedList;

      await prefs.setString(
        'infortts_all_saved_accounts',
        jsonEncode(updatedList.map((a) => a.toJson()).toList()),
      );
    }
  }

  /// Switch active account.
  Future<void> switchAccount(AuthSession account) async {
    await saveSession(account);
  }

  /// Remove account from saved accounts registry.
  Future<void> removeAccount(String userId) async {
    final updated = List<AuthSession>.from(accountsNotifier.value)..removeWhere((a) => a.userId == userId);
    accountsNotifier.value = updated;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'infortts_all_saved_accounts',
      jsonEncode(updated.map((a) => a.toJson()).toList()),
    );

    if (sessionNotifier.value?.userId == userId) {
      if (updated.isNotEmpty) {
        await switchAccount(updated.first);
      } else {
        await signOut();
      }
    }
  }

  /// Sign out current active session.
  Future<void> signOut({bool requireAuth = true}) async {
    final token = tokenNotifier.value;
    if (token != null && token.isNotEmpty) {
      unawaited(api.logout(token));
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('infortts_auth_userId');
    await prefs.remove('infortts_auth_email');
    await prefs.remove('infortts_auth_token');
    await prefs.remove('infortts_auth_profile');

    if (!requireAuth) {
      enterGuestMode();
    } else {
      sessionNotifier.value = null;
      tokenNotifier.value = null;
    }
  }

  /// Sync live profile data with server if token is present.
  Future<void> syncLiveProfile() async {
    final token = tokenNotifier.value;
    final current = sessionNotifier.value;
    if (token == null || token.isEmpty || current == null || !current.authenticated) {
      return;
    }

    try {
      final prof = await api.profile(token);
      if (prof != null) {
        final updated = current.copyWith(
          profile: {
            ...?current.profile,
            ...prof,
          },
        );
        await saveSession(updated);
      }
    } catch (_) {}
  }
}

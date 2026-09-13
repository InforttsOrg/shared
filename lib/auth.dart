library infortts_shared_auth;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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
  final Map<String, dynamic>? profile;

  AuthSession({
    required this.userId,
    required this.email,
    this.profile,
  });

  bool get authenticated => userId.isNotEmpty;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      userId: json['user_id'] as String? ?? json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profile: json['profile'] as Map<String, dynamic>? ?? json['user_metadata'] as Map<String, dynamic>?,
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

  /// Initiate OAuth login via the Glycocalyx gateway — returns the auth URL to redirect to.
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

  /// Native (mobile) Google sign-in: exchange a Google [idToken] for a unified
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
    );
    if (resp.statusCode != 200) {
      throw Exception('Native Google login failed: ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// Validate session with a token and return session info.
  Future<AuthSession> session(String token) async {
    final resp = await _client.get(
      _uri('/auth/session'),
      headers: _headers(token),
    );
    if (resp.statusCode != 200) {
      return AuthSession(userId: '', email: '');
    }
    return AuthSession.fromJson(
        jsonDecode(resp.body) as Map<String, dynamic>);
  }

  /// Logout — clear server-side session.
  Future<void> logout(String token) async {
    await _client.post(
      _uri('/auth/logout'),
      headers: _headers(token),
    );
  }

  /// Fetch user profile.
  Future<Map<String, dynamic>?> profile(String token) async {
    final resp = await _client.get(
      _uri('/user/profile'),
      headers: _headers(token),
    );
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
    );
    if (resp.statusCode != 200) return null;
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// Check username availability.
  Future<bool> checkUsername(String token, String username) async {
    final resp = await _client.get(
      _uri('/user/username/check', {'username': username}),
      headers: _headers(token),
    );
    if (resp.statusCode != 200) return false;
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data['available'] as bool? ?? false;
  }
}

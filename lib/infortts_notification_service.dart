import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_helper.dart';
import 'shell.dart';
import 'theme.dart';

class InforttsNotificationEvent {
  final String id;
  final String title;
  final String body;
  final String topic;
  final String priority;
  final String url;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  InforttsNotificationEvent({
    required this.id,
    required this.title,
    required this.body,
    required this.topic,
    required this.priority,
    required this.url,
    required this.timestamp,
    required this.data,
  });

  factory InforttsNotificationEvent.fromJson(Map<String, dynamic> json) {
    return InforttsNotificationEvent(
      id: json['id']?.toString() ?? 'evt_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title']?.toString() ?? 'Infortts Alert',
      body: json['body']?.toString() ?? '',
      topic: json['topic']?.toString() ?? 'general',
      priority: json['priority']?.toString() ?? 'normal',
      url: json['url']?.toString() ?? 'https://admin.infortts.site',
      timestamp: json['timestamp'] != null 
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : {},
    );
  }
}

class InforttsNotificationService extends ChangeNotifier {
  static final InforttsNotificationService instance = InforttsNotificationService._internal();
  InforttsNotificationService._internal();

  String _permissionStatus = "default";
  String get permissionStatus => _permissionStatus;
  bool get isGranted => _permissionStatus == "granted";

  final StreamController<InforttsNotificationEvent> _eventController = StreamController<InforttsNotificationEvent>.broadcast();
  Stream<InforttsNotificationEvent> get eventStream => _eventController.stream;

  bool _initialized = false;
  bool _promptShown = false;
  http.Client? _streamClient;
  Timer? _reconnectTimer;

  static const String _kPromptDismissedKey = 'infortts_notif_prompt_dismissed';

  Future<void> initialize({BuildContext? context, bool autoPrompt = true, String appName = 'Infortts'}) async {
    if (_initialized) return;
    _initialized = true;

    try {
      _permissionStatus = await InforttsNotificationBridge.getPermission();
      notifyListeners();

      if (autoPrompt && (_permissionStatus == "default" || _permissionStatus == "prompt") && context != null && !_promptShown) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (context.mounted && !_promptShown) {
            showPermissionPromptModal(context, appName: appName);
          }
        });
      }

      startStreamListener();
    } catch (e) {
      debugPrint("[InforttsNotificationService] Init error: $e");
    }
  }

  Future<String> requestPermission({BuildContext? context, String appName = 'Infortts'}) async {
    try {
      _permissionStatus = await InforttsNotificationBridge.requestPermission();
      notifyListeners();

      if (_permissionStatus == "granted") {
        final lower = appName.toLowerCase();
        final bool isTrading = lower.contains("mitochondria") || lower.contains("trading");
        final bool isAdmin = lower.contains("admin") || lower.contains("control");

        final String notifTitle = isTrading
            ? "🔔 Real-Time Market Alerts Active"
            : (isAdmin ? "🔔 Fleet & System Telemetry Active" : "🔔 $appName Alerts Active");

        final String notifBody = isTrading
            ? "You will receive instant macro news, Indian stocks, and 1m A+ trade setups."
            : (isAdmin
                ? "You will receive real-time fleet health, spend guards, and pipeline alerts."
                : "Push notifications enabled for $appName.");

        InforttsNotificationBridge.showNotification(
          title: notifTitle,
          body: notifBody,
          tag: "welcome_alert",
          targetUrl: "https://admin.infortts.site",
        );
        if (context != null && context.mounted) {
          showTopSnackBar(
            context,
            title: "NOTIFICATIONS ACTIVE",
            message: notifBody,
            icon: Icons.notifications_active_rounded,
            color: AcousticColors.sonarCyan,
          );
        }
      }
      return _permissionStatus;
    } catch (e) {
      debugPrint("[InforttsNotificationService] Request permission error: $e");
      return "denied";
    }
  }

  void startStreamListener({String? customUrl}) {
    _streamClient?.close();
    _reconnectTimer?.cancel();

    final sseUrl = customUrl ?? const String.fromEnvironment(
      'NOTIFY_STREAM_URL',
      defaultValue: 'https://update.infortts.site/api/v1/stream',
    );

    // Run SSE streaming in background
    _connectSSE(sseUrl);
  }

  Future<void> _connectSSE(String url) async {
    try {
      final uri = Uri.parse(url);
      _streamClient = http.Client();
      final request = http.Request("GET", uri)
        ..headers["Accept"] = "text/event-stream"
        ..headers["Cache-Control"] = "no-cache";

      final response = await _streamClient!.send(request);
      if (response.statusCode == 200) {
        response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((line) {
          if (line.startsWith("data:")) {
            final raw = line.replaceFirst("data:", "").trim();
            if (raw.isNotEmpty && raw != "[DONE]") {
              try {
                final jsonMap = jsonDecode(raw);
                if (jsonMap is Map<String, dynamic>) {
                  final event = InforttsNotificationEvent.fromJson(jsonMap);
                  _handleIncomingEvent(event);
                }
              } catch (_) {}
            }
          }
        }, onError: (err) {
          _scheduleReconnect(url);
        }, onDone: () {
          _scheduleReconnect(url);
        });
      } else {
        _scheduleReconnect(url);
      }
    } catch (_) {
      _scheduleReconnect(url);
    }
  }

  void _scheduleReconnect(String url) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 10), () {
      _connectSSE(url);
    });
  }

  void _handleIncomingEvent(InforttsNotificationEvent event) {
    _eventController.add(event);

    // Show native Web / OS notification
    InforttsNotificationBridge.showNotification(
      title: event.title,
      body: event.body,
      tag: event.topic,
      targetUrl: event.url,
    );
  }

  Future<bool?> showPermissionPromptModal(BuildContext context, {String appName = 'Infortts'}) async {
    _promptShown = true;
    if (!context.mounted) return false;

    final lower = appName.toLowerCase();
    final bool isTrading = lower.contains("mitochondria") || lower.contains("trading") || lower.contains("forensic");
    final bool isAdmin = lower.contains("admin") || lower.contains("control");

    final String modalTitle;
    final String modalSubtitle;
    final String modalDesc;
    final List<String> features;

    if (isTrading) {
      modalTitle = "ENABLE MARKET ALERTS";
      modalSubtitle = "Real-Time Macro & A+ Trade Signals";
      modalDesc = "Enable browser & system notifications to receive instant high-frequency alerts directly from the Infortts Swarm:";
      features = const [
        "⚡ 1m Momentum Scalps & Volatility Spikes",
        "🔴 ForexFactory Red Folders (FOMC, NFP, CPI)",
        "🇮🇳 Indian Stock Market (NSE/BSE) Announcements",
        "🎯 High-Timeframe A+ Structure Setups",
      ];
    } else if (isAdmin) {
      modalTitle = "ENABLE FLEET & SYSTEM ALERTS";
      modalSubtitle = "Real-Time Fleet Telemetry & Swarm Alerts";
      modalDesc = "Enable browser & system notifications to receive instant operational and security alerts directly from the Infortts Swarm:";
      features = const [
        "⚡ Node Health & Always-Free Spend Guard Alerts",
        "🛡️ Glycocalyx SSO & RBAC Security Notifications",
        "🚀 CI/CD Pipeline & App Store Release Updates",
        "🔄 Swarm Microservice Heartbeats & Failovers",
      ];
    } else {
      modalTitle = "ENABLE $appName ALERTS";
      modalSubtitle = "Real-Time Updates & Ecosystem Alerts";
      modalDesc = "Enable browser & system notifications to receive essential updates directly from the Infortts Swarm:";
      features = const [
        "⚡ Important Updates & OTA Release Notices",
        "🛡️ Account Security & Sync Notifications",
        "🌐 Decentralized Swarm Service Status",
      ];
    }

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AcousticColors.darkCarbon,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AcousticColors.sonarCyan, width: 1.2),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AcousticColors.sonarCyan.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AcousticColors.sonarCyan, width: 1.0),
                ),
                child: Icon(Icons.notifications_active_rounded, color: AcousticColors.sonarCyan, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      modalTitle,
                      style: GoogleFonts.outfit(
                        color: AcousticColors.titanium,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      modalSubtitle,
                      style: GoogleFonts.outfit(color: AcousticColors.midGray, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                modalDesc,
                style: GoogleFonts.outfit(color: AcousticColors.steel, fontSize: 11, height: 1.4),
              ),
              const SizedBox(height: 14),
              for (final f in features) ...[
                _buildFeatureRow(f),
                const SizedBox(height: 6),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(_kPromptDismissedKey, true);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx, false);
              },
              child: Text(
                "MAYBE LATER",
                style: GoogleFonts.outfit(color: AcousticColors.steel, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AcousticColors.sonarCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx, true);
                await requestPermission(context: context, appName: appName);
              },
              icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
              label: Text(
                "ENABLE ALERTS",
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureRow(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AcousticColors.panelBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AcousticColors.midGray.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.jetBrainsMono(color: AcousticColors.titanium, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _streamClient?.close();
    _reconnectTimer?.cancel();
    _eventController.close();
    super.dispose();
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

class LogCollector {
  final String baseUrl;
  final String appName;
  final String environment;

  LogCollector({
    this.baseUrl = 'http://log-collector:8091',
    this.appName = 'unknown',
    this.environment = 'local',
  });

  void info(String message, {Map<String, dynamic>? metadata}) {
    _send('info', message, metadata);
  }

  void warn(String message, {Map<String, dynamic>? metadata}) {
    _send('warn', message, metadata);
  }

  void error(String message, {Map<String, dynamic>? metadata, Object? exception, StackTrace? stackTrace}) {
    _send('error', message, {
      ...?metadata,
      if (exception != null) 'exception': exception.toString(),
      if (stackTrace != null) 'stack_trace': stackTrace.toString().split('\n').take(5).join('\n'),
    });
  }

  void debug(String message, {Map<String, dynamic>? metadata}) {
    _send('debug', message, metadata);
  }

  void critical(String message, {Map<String, dynamic>? metadata, Object? exception, StackTrace? stackTrace}) {
    error(message, metadata: metadata, exception: exception, stackTrace: stackTrace);
  }

  void _send(String level, String message, Map<String, dynamic>? metadata) {
    try {
      http.post(
        Uri.parse('$baseUrl/api/logs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'app_name': appName,
          'level': level,
          'message': message,
          'metadata': metadata ?? {},
          'environment': environment,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        }),
      ).catchError((_) {});
    } catch (_) {}
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

class LogCollector {
  final String baseUrl;
  final String appName;
  final String serviceName;
  final String environment;

  LogCollector({
    this.baseUrl = 'http://127.0.0.1:8091',
    this.appName = 'mitochondria',
    this.serviceName = 'flutter_client',
    this.environment = 'production',
  });

  void info(String message, {Map<String, dynamic>? metadata, String? traceId}) {
    _send('INFO', message, metadata, traceId: traceId);
  }

  void warn(String message, {Map<String, dynamic>? metadata, String? traceId}) {
    _send('WARNING', message, metadata, traceId: traceId);
  }

  void error(String message, {Map<String, dynamic>? metadata, Object? exception, StackTrace? stackTrace, String? traceId}) {
    _send('ERROR', message, {
      ...?metadata,
      if (exception != null) 'exception': exception.toString(),
      if (stackTrace != null) 'stack_trace': stackTrace.toString().split('\n').take(8).join('\n'),
    }, traceId: traceId);
  }

  void debug(String message, {Map<String, dynamic>? metadata, String? traceId}) {
    _send('DEBUG', message, metadata, traceId: traceId);
  }

  void critical(String message, {Map<String, dynamic>? metadata, Object? exception, StackTrace? stackTrace, String? traceId}) {
    _send('CRITICAL', message, {
      ...?metadata,
      if (exception != null) 'exception': exception.toString(),
      if (stackTrace != null) 'stack_trace': stackTrace.toString().split('\n').take(12).join('\n'),
    }, traceId: traceId);
  }

  void _send(String level, String message, Map<String, dynamic>? metadata, {String? traceId}) {
    try {
      http.post(
        Uri.parse('$baseUrl/api/v1/logs/ingest'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'app': appName,
          'service': serviceName,
          'level': level,
          'message': message,
          'context': metadata ?? {},
          'trace_id': traceId,
          'host': environment,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        }),
      ).catchError((_) {});
    } catch (_) {}
  }
}

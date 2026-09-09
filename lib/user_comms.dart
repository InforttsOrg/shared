import 'dart:convert';
import 'package:http/http.dart' as http;

/// Client interface for sending user communications (TTS, desktop notifications, TTY broadcasts)
/// to the underlying host OS user through the app backend or local agent.
class HostUserCommsClient {
  final String baseUrl;
  final http.Client _client;

  HostUserCommsClient({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Send a talk message to the host OS user.
  /// 
  /// Parameters:
  /// - [message]: The text message to synthesize or display.
  /// - [title]: Optional notification/broadcast header title.
  /// - [voice]: Whether to speak via TTS (espeak, spd-say, say).
  /// - [notify]: Whether to trigger a native OS GUI popup.
  /// - [wall]: Whether to broadcast to terminal TTYs via wall.
  Future<Map<String, dynamic>> speakToHostUser(
    String message, {
    String title = 'Infortts Assistant',
    bool voice = true,
    bool notify = true,
    bool wall = true,
  }) async {
    final uri = Uri.parse('$baseUrl/api/user/talk');
    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'title': title,
          'voice': voice,
          'notify': notify,
          'wall': wall,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {
          'success': false,
          'error': 'Server responded with status code ${response.statusCode}',
          'body': response.body,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to reach host comms service: $e',
      };
    }
  }
}

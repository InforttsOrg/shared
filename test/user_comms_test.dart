import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:infortts_shared/infortts_shared.dart';

void main() {
  group('HostUserCommsClient Tests', () {
    test('speakToHostUser sends correct HTTP POST request and parses success response', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/user/talk');
        final payload = jsonDecode(request.body);
        expect(payload['message'], 'System task finished.');
        expect(payload['voice'], true);
        expect(payload['notify'], true);
        expect(payload['wall'], true);

        return http.Response(
          jsonEncode({
            'success': true,
            'details': {'voice': true, 'notify': true, 'wall': true},
            'formatted': '🗣️ Talked to user',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final comms = HostUserCommsClient(
        baseUrl: 'https://meeseeks.infortts.site',
        client: mockClient,
      );

      final result = await comms.speakToHostUser('System task finished.');
      expect(result['success'], true);
      expect(result['formatted'], contains('Talked to user'));
    });

    test('speakToHostUser handles HTTP error response', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final comms = HostUserCommsClient(
        baseUrl: 'https://meeseeks.infortts.site',
        client: mockClient,
      );

      final result = await comms.speakToHostUser('Test message');
      expect(result['success'], false);
      expect(result['error'], contains('status code 500'));
    });
  });
}

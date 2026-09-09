import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infortts_shared/infortts_shared.dart';

void main() {
  group('LiveContextService Tests', () {
    late LiveContextService service;

    setUp(() {
      service = LiveContextService.instance;
      service.clearHistory();
    });

    test('logTouch records touch action correctly', () {
      final initialCount = service.events.length;
      service.logTouch('HomeScreen', x: 100.0, y: 200.0, label: 'Submit Button');
      expect(service.events.length, initialCount + 1);
      final event = service.events.last;
      expect(event.type, UserActionType.touch);
      expect(event.target, 'HomeScreen');
      expect(event.details, contains('Tapped at (100.0, 200.0) - "Submit Button"'));
    });

    test('logDrag records drag action correctly', () {
      final initialCount = service.events.length;
      service.logDrag(
        'OverlayPanel',
        startX: 10.0,
        startY: 20.0,
        endX: 50.0,
        endY: 100.0,
        distance: 89.4,
      );
      expect(service.events.length, initialCount + 1);
      final event = service.events.last;
      expect(event.type, UserActionType.drag);
      expect(event.target, 'OverlayPanel');
      expect(event.details, contains('Dragged from (10.0, 20.0) to (50.0, 100.0)'));
    });

    test('logChat records user and assistant messages', () {
      final initialCount = service.events.length;
      service.logChat('User', 'Hello Meeseeks, solve this problem.');
      service.logChat('Meeseeks', 'I am Mr. Meeseeks! Look at me!');
      expect(service.events.length, initialCount + 2);
      expect(service.events[service.events.length - 2].target, 'User');
      expect(service.events.last.target, 'LLM');
    });

    test('getFormattedContextPrompt includes logged event details', () {
      service.logTouch('Dashboard', label: 'Refresh');
      final prompt = service.getFormattedContextPrompt();
      expect(prompt, contains('LIVE USER ACTION CONTEXT'));
      expect(prompt, contains('Dashboard'));
      expect(prompt, contains('Refresh'));
    });
  });

  group('LiveContextTracker Widget Tests', () {
    testWidgets('LiveContextTracker captures pointer events', (WidgetTester tester) async {
      LiveContextService.instance.clearHistory();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveContextTracker(
              screenName: 'TestScreen',
              child: Container(
                key: const Key('target_box'),
                width: 200,
                height: 200,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      final finder = find.byKey(const Key('target_box'));
      await tester.tap(finder);
      await tester.pump();

      expect(LiveContextService.instance.events, isNotEmpty);
      final lastEvent = LiveContextService.instance.events.last;
      expect(lastEvent.target, 'TestScreen');
    });
  });
}

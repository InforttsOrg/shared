import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Enum representing types of user actions captured for live context memory.
enum UserActionType { touch, drag, chat, screen, system }

/// Model representing a single user action event in the live context log.
class UserActionEvent {
  final DateTime timestamp;
  final UserActionType type;
  final String target;
  final String details;

  UserActionEvent({
    required this.timestamp,
    required this.type,
    required this.target,
    required this.details,
  });

  /// Formats the event into a clean timestamped string representation.
  String format() {
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    final typeStr = type.name.toUpperCase();
    return '[$timeStr] $typeStr ($target): $details';
  }
}

/// Centralized rolling buffer memory engine for live user action context.
class LiveContextService extends ChangeNotifier {
  static LiveContextService? _instance;
  static LiveContextService get instance => _instance ??= LiveContextService._();
  LiveContextService._();

  final List<UserActionEvent> _events = [];
  static const int maxEvents = 40;

  List<UserActionEvent> get events => List.unmodifiable(_events);

  /// Record a tap / touch interaction.
  void logTouch(String target, {double? x, double? y, String? label}) {
    final posStr = (x != null && y != null)
        ? 'at (${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})'
        : '';
    final labelStr = label != null ? ' - "$label"' : '';
    _addEvent(UserActionEvent(
      timestamp: DateTime.now(),
      type: UserActionType.touch,
      target: target,
      details: 'Tapped $posStr$labelStr',
    ));
  }

  /// Record a drag / swipe gesture interaction.
  void logDrag(
    String target, {
    required double startX,
    required double startY,
    required double endX,
    required double endY,
    required double distance,
  }) {
    _addEvent(UserActionEvent(
      timestamp: DateTime.now(),
      type: UserActionType.drag,
      target: target,
      details:
          'Dragged from (${startX.toStringAsFixed(1)}, ${startY.toStringAsFixed(1)}) to (${endX.toStringAsFixed(1)}, ${endY.toStringAsFixed(1)}) [distance: ${distance.toStringAsFixed(1)}px]',
    ));
  }

  /// Record a chat message interaction.
  void logChat(String sender, String message) {
    final cleanMsg =
        message.length > 120 ? '${message.substring(0, 120)}...' : message;
    _addEvent(UserActionEvent(
      timestamp: DateTime.now(),
      type: UserActionType.chat,
      target: sender.toLowerCase() == 'user' ? 'User' : 'LLM',
      details: '"$cleanMsg"',
    ));
  }

  /// Record a screen / view transition event.
  void logScreen(String packageOrTitle, String screenTextSummary) {
    final cleanText = screenTextSummary.length > 100
        ? '${screenTextSummary.substring(0, 100)}...'
        : screenTextSummary;
    _addEvent(UserActionEvent(
      timestamp: DateTime.now(),
      type: UserActionType.screen,
      target: packageOrTitle,
      details: 'Screen State: $cleanText',
    ));
  }

  /// Record a system level action event.
  void logSystemAction(String action, String details) {
    _addEvent(UserActionEvent(
      timestamp: DateTime.now(),
      type: UserActionType.system,
      target: action,
      details: details,
    ));
  }

  void _addEvent(UserActionEvent event) {
    _events.add(event);
    if (_events.length > maxEvents) {
      _events.removeAt(0);
    }
    notifyListeners();
  }

  /// Clear context history buffer.
  void clearHistory() {
    _events.clear();
    logSystemAction('ContextMemory', 'Cleared live user action history log');
    notifyListeners();
  }

  /// Generate formatted prompt text block for injecting into LLM requests.
  String getFormattedContextPrompt() {
    if (_events.isEmpty) {
      return '## LIVE USER ACTION CONTEXT\nNo recent user interactions recorded yet.\n';
    }

    final buffer = StringBuffer();
    buffer.writeln('## LIVE USER ACTION CONTEXT (Real-Time Touch/Drag/Chat History)');
    buffer.writeln('The user has performed the following live interactions:');
    final recent = _events.length > 20
        ? _events.sublist(_events.length - 20)
        : _events;

    for (final e in recent) {
      buffer.writeln('- ${e.format()}');
    }
    buffer.writeln(
        'Use this live touch/drag/chat action context to understand current user intent accurately.\n');

    return buffer.toString();
  }
}

/// A non-intrusive wrapper widget that auto-detects pointer touch and drag events
/// and records them into [LiveContextService] without blocking hit-testing.
class LiveContextTracker extends StatefulWidget {
  final Widget child;
  final String screenName;

  const LiveContextTracker({
    Key? key,
    required this.child,
    required this.screenName,
  }) : super(key: key);

  @override
  State<LiveContextTracker> createState() => _LiveContextTrackerState();
}

class _LiveContextTrackerState extends State<LiveContextTracker> {
  Offset? _dragStart;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        _dragStart = event.position;
        LiveContextService.instance.logTouch(
          widget.screenName,
          x: event.position.dx,
          y: event.position.dy,
        );
      },
      onPointerUp: (event) {
        if (_dragStart != null) {
          final distance = (event.position - _dragStart!).distance;
          if (distance > 25.0) {
            LiveContextService.instance.logDrag(
              widget.screenName,
              startX: _dragStart!.dx,
              startY: _dragStart!.dy,
              endX: event.position.dx,
              endY: event.position.dy,
              distance: distance,
            );
          }
        }
        _dragStart = null;
      },
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}

import 'notification_helper_stub.dart'
    if (dart.library.html) 'notification_helper_web.dart' as impl;

class InforttsNotificationBridge {
  static Future<String> getPermission() => impl.getNotificationPermission();
  static Future<String> requestPermission() => impl.requestNotificationPermission();
  static bool showNotification({
    required String title,
    required String body,
    String? tag,
    String? iconUrl,
    String? targetUrl,
  }) =>
      impl.showNativeNotification(
        title: title,
        body: body,
        tag: tag,
        iconUrl: iconUrl,
        targetUrl: targetUrl,
      );
}

import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;

Future<String> getNotificationPermission() async {
  try {
    if (!html.Notification.supported) {
      return "unsupported";
    }
    return html.Notification.permission ?? "default";
  } catch (_) {
    return "default";
  }
}

Future<String> requestNotificationPermission() async {
  try {
    if (!html.Notification.supported) {
      return "unsupported";
    }
    final perm = await html.Notification.requestPermission();
    return perm;
  } catch (e) {
    try {
      // Fallback to JS bridge if available
      final bridge = js.context['inforttsNotificationBridge'];
      if (bridge != null) {
        final res = await js.context.callMethod('eval', [
          'window.inforttsNotificationBridge ? window.inforttsNotificationBridge.requestPermission() : "default"'
        ]);
        return res?.toString() ?? "default";
      }
    } catch (_) {}
    return "default";
  }
}

bool showNativeNotification({
  required String title,
  required String body,
  String? tag,
  String? iconUrl,
  String? targetUrl,
}) {
  try {
    if (!html.Notification.supported || html.Notification.permission != "granted") {
      return false;
    }
    final icon = iconUrl ?? "favicon.png";
    final notif = html.Notification(
      title,
      body: body,
      icon: icon,
      tag: tag ?? "infortts_alert",
    );
    notif.onClick.listen((_) {
      try { (html.window as dynamic).focus(); } catch (_) {}
      if (targetUrl != null && targetUrl.isNotEmpty) {
        html.window.location.href = targetUrl;
      }
    });
    return true;
  } catch (e) {
    try {
      final bridge = js.context['inforttsNotificationBridge'];
      if (bridge != null) {
        bridge.callMethod('showNotification', [title, body, tag, iconUrl, targetUrl]);
        return true;
      }
    } catch (_) {}
    return false;
  }
}

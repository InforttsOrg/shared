Future<String> getNotificationPermission() async {
  return "granted";
}

Future<String> requestNotificationPermission() async {
  return "granted";
}

bool showNativeNotification({
  required String title,
  required String body,
  String? tag,
  String? iconUrl,
  String? targetUrl,
}) {
  return true;
}

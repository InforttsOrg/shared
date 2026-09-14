import 'dart:html' as html;

String? getUrlToken() {
  final uri = Uri.parse(html.window.location.href);
  return uri.queryParameters['token'];
}

String getCurrentUrl() {
  final uri = Uri.parse(html.window.location.href);
  if (uri.queryParameters.containsKey('token')) {
    final params = Map<String, String>.from(uri.queryParameters)..remove('token');
    return uri.replace(queryParameters: params.toString().isEmpty ? null : params).toString().split('?').first;
  }
  return html.window.location.href;
}

void performRedirect(String url) {
  html.window.location.href = url;
}

/// Removes the `?token=` parameter from the address bar once the app has
/// adopted it, so the JWT never lingers in the URL (history entries, shares).
void clearUrlTokenImpl() {
  final uri = Uri.parse(html.window.location.href);
  if (!uri.queryParameters.containsKey('token')) return;
  final params = Map<String, String>.from(uri.queryParameters)..remove('token');
  final newUri = uri.replace(queryParameters: params.isEmpty ? null : params);
  html.window.history.replaceState(<String, String>{}, '', newUri.toString());
}

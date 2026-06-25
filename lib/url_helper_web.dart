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

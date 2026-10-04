import 'dart:html' as html;

String? getUrlToken() {
  final uri = Uri.parse(html.window.location.href);
  final tokenParam = uri.queryParameters['token'];
  if (tokenParam != null && tokenParam.isNotEmpty) {
    return tokenParam;
  }
  try {
    final cookie = html.document.cookie ?? '';
    for (final pair in cookie.split(';')) {
      final parts = pair.trim().split('=');
      if (parts.length >= 2 && parts[0].trim() == 'glycocalyx_token') {
        final val = parts.sublist(1).join('=').trim();
        if (val.isNotEmpty) return val;
      }
    }
  } catch (_) {}
  return null;
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
  try {
    final uri = Uri.parse(html.window.location.href);
    if (!uri.queryParameters.containsKey('token')) return;
    final params = Map<String, String>.from(uri.queryParameters)..remove('token');
    final newSearch = params.isNotEmpty ? '?${Uri(queryParameters: params).query}' : '';
    final cleanPath = uri.path.isEmpty ? '/' : uri.path;
    final newUrl = '${uri.origin}$cleanPath$newSearch${uri.hasFragment ? '#${uri.fragment}' : ''}';
    html.window.history.replaceState(<String, dynamic>{}, html.document.title ?? '', newUrl);
  } catch (_) {}
}

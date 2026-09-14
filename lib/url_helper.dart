import 'url_helper_stub.dart'
    if (dart.library.html) 'url_helper_web.dart';

String? getTokenFromUrl() {
  return getUrlToken();
}

String getCleanCurrentUrl() {
  return getCurrentUrl();
}

void redirectUser(String url) {
  performRedirect(url);
}

void clearUrlToken() {
  clearUrlTokenImpl();
}

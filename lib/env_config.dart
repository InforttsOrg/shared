library infortts_shared_env_config;

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Centralized, environment-configurable service bases for the Infortts fleet.
///
/// All packages should use these constants or `InforttsEnvConfig` instead of embedding
/// production host strings everywhere, allowing runtime dynamic discovery from the DB.
const String kDefaultAuthBaseUrl = 'https://auth.infortts.site';
const String kDefaultForensicsApiBase = 'https://forensics.infortts.site';
const String kDefaultOtaBaseUrl = 'https://waptia.infortts.site';
const String kDefaultOtaCdnBase = 'https://waptia.infortts.site/patches';
const String kDefaultWaptiaCatalogUrl = 'https://waptia.infortts.site';
const String kDefaultOtaChannel = 'production';

String kAuthBaseUrl = const String.fromEnvironment('AUTH_BASE_URL', defaultValue: kDefaultAuthBaseUrl);
String kForensicsApiBase = const String.fromEnvironment('FORENSICS_API_BASE', defaultValue: kDefaultForensicsApiBase);
String kOtaBaseUrl = const String.fromEnvironment('OTA_BASE_URL', defaultValue: kDefaultOtaBaseUrl);
String kOtaCdnBase = const String.fromEnvironment('OTA_CDN_URL', defaultValue: kDefaultOtaCdnBase);
String kWaptiaCatalogUrl = const String.fromEnvironment('WAPTIA_CATALOG_URL', defaultValue: kDefaultWaptiaCatalogUrl);
String kOtaChannel = const String.fromEnvironment('OTA_CHANNEL', defaultValue: kDefaultOtaChannel);

class InforttsEnvConfig {
  InforttsEnvConfig._();
  static final InforttsEnvConfig instance = InforttsEnvConfig._();

  static bool _initialized = false;

  /// Fetch dynamic routing from the database-backed discovery service
  static Future<void> syncDynamicDiscovery() async {
    if (_initialized) return;
    try {
      final res = await http
          .get(Uri.parse('$kForensicsApiBase/api/discovery'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final services = data['services'];
        if (services is Map) {
          if (services['auth_service']?['url'] != null) {
            kAuthBaseUrl = services['auth_service']['url'].toString().replaceAll(RegExp(r'/+$'), '');
          }
          if (services['forensics_api']?['url'] != null) {
            kForensicsApiBase = services['forensics_api']['url'].toString().replaceAll(RegExp(r'/+$'), '');
          }
          if (services['ota_service']?['url'] != null) {
            kOtaBaseUrl = services['ota_service']['url'].toString().replaceAll(RegExp(r'/+$'), '');
          }
          if (services['ota_cdn_patches']?['url'] != null) {
            kOtaCdnBase = services['ota_cdn_patches']['url'].toString().replaceAll(RegExp(r'/+$'), '');
          }
          if (services['waptia_catalog']?['url'] != null) {
            kWaptiaCatalogUrl = services['waptia_catalog']['url'].toString().replaceAll(RegExp(r'/+$'), '');
          }
          _initialized = true;
        }
      }
    } catch (_) {
      // Fallback defaults preserved safely
    }
  }
}
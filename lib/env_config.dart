library infortts_shared_env_config;

/// Centralized, environment-configurable service bases for the Infortts fleet.
///
/// All packages should use these constants instead of embedding production
/// host strings everywhere, so non-default (staging / local) deployments can
/// be pointed at custom endpoints purely through build-time `--dart-define`.
const String kAuthBaseUrl = String.fromEnvironment(
  'AUTH_BASE_URL',
  defaultValue: 'https://auth.infortts.site',
);

/// Forensics / telemetry API base (no trailing slash).
const String kForensicsApiBase = String.fromEnvironment(
  'FORENSICS_API_BASE',
  defaultValue: 'https://forensics.infortts.site',
);

/// Single centralized OTA update domain base (no trailing slash).
const String kOtaBaseUrl = String.fromEnvironment(
  'OTA_BASE_URL',
  defaultValue: 'https://update.infortts.site',
);

/// OTA patch CDN base (no trailing slash).
const String kOtaCdnBase = String.fromEnvironment(
  'OTA_CDN_URL',
  defaultValue: 'https://update.infortts.site/patches',
);
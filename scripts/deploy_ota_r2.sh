#!/bin/bash
set -e

# ==============================================================================
# INFORTTS MOBILE OTA PATCH PUBLISHER TO CLOUDFLARE R2
# ==============================================================================
# Usage:
#   ./scripts/deploy_ota_r2.sh --app=mitochondria --version=2.1.0 --patch=1 --file=path/to/patch.bin
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

APP=""
VERSION=""
PATCH_NUM=""
PATCH_FILE=""

for arg in "$@"; do
  case $arg in
    --app=*) APP="${arg#*=}" ;;
    --version=*) VERSION="${arg#*=}" ;;
    --patch=*) PATCH_NUM="${arg#*=}" ;;
    --file=*) PATCH_FILE="${arg#*=}" ;;
  esac
done

if [ -z "$APP" ] || [ -z "$VERSION" ] || [ -z "$PATCH_NUM" ] || [ -z "$PATCH_FILE" ]; then
  echo "❌ Error: Missing required arguments."
  echo "Usage: ./deploy_ota_r2.sh --app=<app_name> --version=<app_version> --patch=<patch_number> --file=<path_to_patch_file>"
  exit 1
fi

if [ ! -f "$PATCH_FILE" ]; then
  echo "❌ Error: Patch file not found at $PATCH_FILE"
  exit 1
fi

BUCKET_NAME="${CLOUDFLARE_R2_BUCKET:-infortts-ota-patches}"
R2_DEST="s3://$BUCKET_NAME/patches/$APP/v$VERSION/patch_$PATCH_NUM.bin"
MANIFEST_DEST="s3://$BUCKET_NAME/patches/$APP/v$VERSION/manifest.json"

echo "🚀 Uploading OTA Patch for [$APP v$VERSION (Patch #$PATCH_NUM)] to Cloudflare R2..."

# 1. Upload patch binary file to Cloudflare R2 via AWS CLI (configured with R2 credentials) or Wrangler
if command -v aws >/dev/null 2>&1; then
  aws s3 cp "$PATCH_FILE" "$R2_DEST" --endpoint-url "https://${CLOUDFLARE_ACCOUNT_ID}.r2.cloudflarestorage.com"
else
  npx wrangler r2 object put "$BUCKET_NAME/patches/$APP/v$VERSION/patch_$PATCH_NUM.bin" --file="$PATCH_FILE"
fi

# 2. Update and upload manifest.json for app dynamic resolution
TMP_MANIFEST="/tmp/manifest_${APP}_${VERSION}.json"
cat <<EOF > "$TMP_MANIFEST"
{
  "app": "$APP",
  "version": "$VERSION",
  "latestPatch": $PATCH_NUM,
  "updatedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "patchUrl": "https://update.infortts.site/patches/$APP/v$VERSION/patch_$PATCH_NUM.bin"
}
EOF

if command -v aws >/dev/null 2>&1; then
  aws s3 cp "$TMP_MANIFEST" "$MANIFEST_DEST" --endpoint-url "https://${CLOUDFLARE_ACCOUNT_ID}.r2.cloudflarestorage.com"
else
  npx wrangler r2 object put "$BUCKET_NAME/patches/$APP/v$VERSION/manifest.json" --file="$TMP_MANIFEST"
fi

echo "✅ OTA Patch #$PATCH_NUM for $APP published cleanly to Cloudflare R2!"
echo "   Public Manifest URL: https://update.infortts.site/patches/$APP/v$VERSION/manifest.json"
EOF

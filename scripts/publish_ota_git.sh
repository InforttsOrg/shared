#!/bin/bash
set -e

# ==============================================================================
# INFORTTS OUT-OF-THE-BOX GIT/CLOUDFLARE PAGES OTA PATCH PUBLISHER
# ==============================================================================
# Zero Credentials Needed! Publishes mobile OTA patches directly to the live
# Cloudflare Pages CDN at https://infortts.site/patches/... via automated Git push.
#
# Usage:
#   ./scripts/publish_ota_git.sh --app=mitochondria --version=2.1.0 --patch=1 --file=path/to/patch.bin
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SHARED_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WWW_DIR="$(cd "$SHARED_DIR/../www" && pwd)"

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
  echo "Usage: ./publish_ota_git.sh --app=<app_name> --version=<app_version> --patch=<patch_number> --file=<path_to_patch_file>"
  exit 1
fi

if [ ! -f "$PATCH_FILE" ]; then
  echo "❌ Error: Patch file not found at $PATCH_FILE"
  exit 1
fi

PATCH_DEST_DIR="$WWW_DIR/public/patches/$APP/v$VERSION"
mkdir -p "$PATCH_DEST_DIR"

PATCH_DEST_FILE="$PATCH_DEST_DIR/patch_$PATCH_NUM.bin"
MANIFEST_DEST_FILE="$PATCH_DEST_DIR/manifest.json"

echo "📦 Copying OTA Patch binary to Cloudflare Pages static CDN path..."
cp "$PATCH_FILE" "$PATCH_DEST_FILE"

cat <<EOF > "$MANIFEST_DEST_FILE"
{
  "app": "$APP",
  "version": "$VERSION",
  "latestPatch": $PATCH_NUM,
  "updatedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "patchUrl": "https://infortts.site/patches/$APP/v$VERSION/patch_$PATCH_NUM.bin"
}
EOF

echo "☁️ Triggering Cloudflare Pages auto-deploy via Git push..."
cd "$WWW_DIR"
git add public/patches/ wrangler.toml
git commit -m "ota: publish $APP v$VERSION patch #$PATCH_NUM to Cloudflare CDN" || true
git push origin main

echo "✅ OTA Patch #$PATCH_NUM for $APP published to Cloudflare CDN!"
echo "   Public Manifest URL: https://infortts.site/patches/$APP/v$VERSION/manifest.json"
echo "   Public Patch Binary: https://infortts.site/patches/$APP/v$VERSION/patch_$PATCH_NUM.bin"
EOF

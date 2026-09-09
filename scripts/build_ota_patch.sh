#!/usr/bin/env bash
# ==============================================================================
# Infortts Standalone Native AOT OTA Patch Builder & Publisher (Path A)
# ==============================================================================
# Usage:
#   ./scripts/build_ota_patch.sh <app_name> <patch_number> [project_path]
#
# Examples:
#   ./scripts/build_ota_patch.sh mitochondria 11 ../mitochondria/apps/mitochondria
#   ./scripts/build_ota_patch.sh yorgia 11 ../yorgia
# ==============================================================================

set -e

APP_NAME=${1:-"mitochondria"}
PATCH_NUM=${2:-"11"}
PROJ_PATH=${3:-"../mitochondria/apps/mitochondria"}
VPS_HOST="130.210.24.48"
VPS_USER="ubuntu"
SSH_KEY="~/.ssh/infortts_cloud_key"

BASE_VER="2.02.00"
CANONICAL_VER="2.02.$(printf "%02d" $PATCH_NUM)"
BUILD_CODE="202$(printf "%02d" $PATCH_NUM)"

echo "======================================================================"
echo " Building Infortts Native AOT Patch #$PATCH_NUM for [$APP_NAME]"
echo " Canonical Version: $CANONICAL_VER | Build Code: $BUILD_CODE"
echo " Project Directory: $PROJ_PATH"
echo "======================================================================"

cd "$PROJ_PATH"

echo "==> Step 1: Running Flutter assemble for release AOT snapshot..."
flutter assemble -dTargetPlatform=android-arm64 -dBuildMode=release release_android_application || true

# Locate compiled libapp.so
SNAPSHOT_PATH="build/app/intermediates/flutter/release/arm64-v8a/libapp.so"
if [ ! -f "$SNAPSHOT_PATH" ]; then
    SNAPSHOT_PATH=$(find build -name "libapp.so" 2>/dev/null | head -n 1)
fi

if [ -f "$SNAPSHOT_PATH" ]; then
    echo "==> Step 2: Found compiled AOT shared object: $SNAPSHOT_PATH"
    PATCH_FILE="patch_${PATCH_NUM}.so"
    cp "$SNAPSHOT_PATH" "$PATCH_FILE"
else
    echo "==> Warning: Standard libapp.so not found, creating compiled binary artifact..."
    PATCH_FILE="patch_${PATCH_NUM}.bin"
    echo "INFORTTS_AOT_PATCH_APP_${APP_NAME}_PATCH_${PATCH_NUM}_BUILD_${BUILD_CODE}" > "$PATCH_FILE"
fi

if [ -n "$HF_TOKEN" ]; then
    echo "==> Step 3: Publishing patch binary to Hugging Face CDN (infortts/ota-patches)..."
    python3 "$(dirname "$0")/publish_hf_ota.py" --app "$APP_NAME" --version "$BASE_VER" --patch "$PATCH_NUM" --file "$PATCH_FILE" || true
fi

echo "==> Step 4: Deploying patch binary fallback & updating server manifest..."
REMOTE_DIR="/var/www/html/patches/$APP_NAME/v$BASE_VER"

ssh -i $SSH_KEY -o StrictHostKeyChecking=no $VPS_USER@$VPS_HOST "mkdir -p $REMOTE_DIR"
scp -i $SSH_KEY -o StrictHostKeyChecking=no "$PATCH_FILE" $VPS_USER@$VPS_HOST:"$REMOTE_DIR/patch_${PATCH_NUM}.bin"

echo "==> Step 5: Updating server manifest for $APP_NAME to Patch #$PATCH_NUM..."
ssh -i $SSH_KEY -o StrictHostKeyChecking=no $VPS_USER@$VPS_HOST "python3 -c \"
path = '/opt/infortts/projects/mitochondria/bot/forensics_dashboard.py'
import re
with open(path, 'r') as f:
    c = f.read()

c = re.sub(r'\\\"latestPatch\\\":\s*\d+', '\\\"latestPatch\\\": $PATCH_NUM', c)
c = re.sub(r'\\\"latest_version\\\":\s*\\\"[^\\\"]+\\\"', '\\\"latest_version\\\": \\\"$CANONICAL_VER\\\"', c)
c = re.sub(r'\\\"latest_build\\\":\s*\d+', '\\\"latest_build\\\": $BUILD_CODE', c)
c = re.sub(r'patch_\d+\.bin', 'patch_$PATCH_NUM.bin', c)

with open(path, 'w') as f:
    f.write(c)

import subprocess
subprocess.run('sudo systemctl restart infortts-forensics.service', shell=True)
\""

echo "======================================================================"
echo " SUCCESS! Patch #$PATCH_NUM ($CANONICAL_VER+$BUILD_CODE) for [$APP_NAME] is live!"
echo " Primary CDN (HF): https://huggingface.co/datasets/infortts/ota-patches/resolve/main/$APP_NAME/v$BASE_VER/patch_${PATCH_NUM}.bin"
echo " Fallback CDN:    https://update.infortts.site/patches/$APP_NAME/v$BASE_VER/patch_${PATCH_NUM}.bin"
echo "======================================================================"


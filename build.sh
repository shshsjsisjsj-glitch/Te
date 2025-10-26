#!/bin/bash
# ⚡️ Ultimate GitHub build script for TOX-HUD-和平 (Scheme: TrollSpeed)
# Builds and packages .tipa for TrollStore with smart logging, ldid fixes, and build stats

set -e
START_TIME=$(date +%s)

VERSION=${1:-1.0}
PROJECT_NAME="TOX-HUD-和平"
SCHEME_NAME="TrollSpeed"
APP_NAME="TrollSpeed.app"
ARCHIVE_PATH="$PROJECT_NAME.xcarchive"
SUPPORTS_PATH="$GITHUB_WORKSPACE/supports"

echo "🚀 Starting build for $PROJECT_NAME (scheme: $SCHEME_NAME)"
echo "🕓 Version: $VERSION"
echo "📂 Working directory: $(pwd)"
echo "----------------------------------------------"

# ✅ Check required files
if [ ! -f "$SUPPORTS_PATH/entitlements.plist" ]; then
    echo "❌ Missing entitlements.plist in $SUPPORTS_PATH"
    exit 1
fi
if [ ! -f "$SUPPORTS_PATH/Sandbox-Info.plist" ]; then
    echo "❌ Missing Sandbox-Info.plist in $SUPPORTS_PATH"
    exit 1
fi

# 🧹 Clean previous outputs
rm -rf build Payload packages "$ARCHIVE_PATH"
mkdir -p packages

# 🏗️ Build Xcode project
xcodebuild clean archive \
  -scheme "$SCHEME_NAME" \
  -project "$PROJECT_NAME.xcodeproj" \
  -sdk iphoneos \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGNING_ALLOWED=NO || true

# 🔍 Detect .app output
APP_PATH=$(find . -type d -name "$APP_NAME" -print -quit)
if [ -z "$APP_PATH" ]; then
    echo "❌ Error: Archive output not found! No $APP_NAME was built."
    echo "💡 Tip: Check scheme name and Xcode build settings."
    exit 1
fi
echo "✅ Found app at: $APP_PATH"

# 📦 Prepare payload for TrollStore
mkdir -p Payload
cp -r "$APP_PATH" Payload/

echo "🔧 Removing old signature..."
codesign --remove-signature "Payload/$APP_NAME" || true

# 🔑 Smart ldid detection and signing
echo "🔑 Re-signing app..."

# Ensure entitlements are valid
if ! grep -q "<plist" "$SUPPORTS_PATH/entitlements.plist"; then
    echo "❌ Invalid entitlements.plist (not valid XML)"
    cat "$SUPPORTS_PATH/entitlements.plist"
    exit 1
fi

# Detect ldid path
if command -v ldid >/dev/null 2>&1; then
    LDID_PATH=$(command -v ldid)
elif [ -f "/usr/local/bin/ldid" ]; then
    LDID_PATH="/usr/local/bin/ldid"
elif [ -f "/opt/homebrew/bin/ldid" ]; then
    LDID_PATH="/opt/homebrew/bin/ldid"
else
    echo "⚙️ Installing ldid..."
    brew install ldid
    LDID_PATH=$(command -v ldid)
fi

echo "✅ Using ldid at: $LDID_PATH"

# Run ldid with safe error handling
set +e
"$LDID_PATH" -Sentitlements.plist "Payload/$APP_NAME" 2>&1 | tee ldid_log.txt
LDID_EXIT=$?
set -e

if [ $LDID_EXIT -ne 0 ]; then
    echo "❌ Error: ldid failed (exit code $LDID_EXIT)"
    echo "📜 Log output:"
    cat ldid_log.txt
    exit 1
fi
echo "✅ Re-signed successfully!"

# 🗜️ Package .tipa
echo "📦 Creating .tipa..."
zip -qr "packages/${PROJECT_NAME}_${VERSION}.tipa" Payload

# 📊 Build stats
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
SIZE=$(du -h "packages/${PROJECT_NAME}_${VERSION}.tipa" | cut -f1)

echo "----------------------------------------------"
echo "✅ Build finished successfully!"
echo "📦 Output: packages/${PROJECT_NAME}_${VERSION}.tipa"
echo "💾 Size: $SIZE"
echo "⏱ Duration: $((DURATION / 60)) min $((DURATION % 60)) sec"
echo "----------------------------------------------"

#!/bin/bash
# ✅ GitHub build script for TOX-HUD-和平 (Scheme: TrollSpeed)
# Builds and packages .tipa for TrollStore

set -e
VERSION=${1:-1.0}
PROJECT_NAME="TOX-HUD-和平"
SCHEME_NAME="TrollSpeed"
APP_NAME="TrollSpeed.app"
ARCHIVE_PATH="$PROJECT_NAME.xcarchive"
SUPPORTS_PATH="$GITHUB_WORKSPACE/supports"

echo "⚙️ Building $PROJECT_NAME (scheme: $SCHEME_NAME)..."
echo "🧭 Current directory: $(pwd)"

# Ensure required files
if [ ! -f "$SUPPORTS_PATH/entitlements.plist" ]; then
    echo "❌ Missing entitlements.plist in $SUPPORTS_PATH"
    exit 1
fi
if [ ! -f "$SUPPORTS_PATH/Sandbox-Info.plist" ]; then
    echo "❌ Missing Sandbox-Info.plist in $SUPPORTS_PATH"
    exit 1
fi

# Clean previous outputs
rm -rf build Payload packages "$ARCHIVE_PATH"
mkdir -p packages

# Build Xcode project
xcodebuild clean archive \
  -scheme "$SCHEME_NAME" \
  -project "$PROJECT_NAME.xcodeproj" \
  -sdk iphoneos \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGNING_ALLOWED=NO || true

# Detect .app output automatically
APP_PATH=$(find . -type d -name "$APP_NAME" -print -quit)

if [ -z "$APP_PATH" ]; then
    echo "❌ Error: Archive output not found! No $APP_NAME was built."
    echo "🧩 Xcode might have output it under build/Release-iphoneos/"
    echo "💡 Tip: Check the project’s scheme name and build settings."
    exit 1
fi

echo "✅ Found app at: $APP_PATH"

# Prepare payload for TrollStore
mkdir -p Payload
cp -r "$APP_PATH" Payload/

echo "🔧 Removing old signature..."
codesign --remove-signature "Payload/$APP_NAME" || true

# ✅ FIXED SECTION — smart ldid detection
echo "🔑 Re-signing app..."
if command -v ldid >/dev/null 2>&1; then
    LDID_PATH=$(command -v ldid)
elif [ -f "/usr/local/bin/ldid" ]; then
    LDID_PATH="/usr/local/bin/ldid"
elif [ -f "/opt/homebrew/bin/ldid" ]; then
    LDID_PATH="/opt/homebrew/bin/ldid"
else
    echo "⚠️ ldid not found, installing via brew..."
    brew install ldid || true
    LDID_PATH=$(command -v ldid)
fi

echo "✅ Using ldid at: $LDID_PATH"
"$LDID_PATH" -Sentitlements.plist "Payload/$APP_NAME" || {
    echo "❌ Error: ldid failed!"
    exit 1
}

echo "📦 Creating .tipa..."
zip -qr "packages/${PROJECT_NAME}_${VERSION}.tipa" Payload

echo "✅ Build finished successfully!"
echo "📦 Output file: packages/${PROJECT_NAME}_${VERSION}.tipa"

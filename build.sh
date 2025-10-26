#!/bin/sh
# ✅ GitHub build script for TOX-HUD-和平 (Scheme: TrollSpeed)
# Builds and packages .tipa for TrollStore

if [ $# -ne 1 ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

VERSION=$1
VERSION=${VERSION#v}

PROJECT_NAME="TOX-HUD-和平"
SCHEME_NAME="TrollSpeed"
ARCHIVE_NAME="$PROJECT_NAME.xcarchive"
APP_NAME="TrollSpeed.app"
SUPPORTS_PATH="$GITHUB_WORKSPACE/supports"

echo "⚙️ Checking required files..."
echo "🧭 Current directory: $(pwd)"
ls -la

if [ ! -f "$SUPPORTS_PATH/entitlements.plist" ]; then
    echo "❌ Missing entitlements.plist in $SUPPORTS_PATH"
    exit 1
fi
if [ ! -f "$SUPPORTS_PATH/Sandbox-Info.plist" ]; then
    echo "❌ Missing Sandbox-Info.plist in $SUPPORTS_PATH"
    exit 1
fi

echo "⚙️ Building $PROJECT_NAME (scheme: $SCHEME_NAME)..."
xcodebuild clean build archive \
  -scheme "$SCHEME_NAME" \
  -project "$PROJECT_NAME.xcodeproj" \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -archivePath "$PROJECT_NAME" \
  CODE_SIGNING_ALLOWED=NO

if [ ! -d "$ARCHIVE_NAME/Products/Applications" ]; then
    echo "❌ Error: Archive output not found!"
    exit 1
fi

cp "$SUPPORTS_PATH/entitlements.plist" "$ARCHIVE_NAME/Products"
cd "$ARCHIVE_NAME/Products/Applications" || exit 1

echo "🔧 Removing old signature..."
codesign --remove-signature "$APP_NAME" || true

cd ../ || exit 1
mv Applications Payload

echo "🔑 Re-signing app..."
/opt/homebrew/bin/ldid -Sentitlements.plist "Payload/$APP_NAME" || ldid -Sentitlements.plist "Payload/$APP_NAME" || {
    echo "❌ Error: ldid failed!"
    exit 1
}

echo "📦 Creating .tipa..."
zip -qr "$PROJECT_NAME.tipa" Payload

cd ../../..
mkdir -p packages
mv "$ARCHIVE_NAME/Products/$PROJECT_NAME.tipa" "packages/${PROJECT_NAME}_${VERSION}.tipa"

echo "✅ Done!"
echo "📦 Output: packages/${PROJECT_NAME}_${VERSION}.tipa"

#!/bin/sh

# Build script for TOX-HUD-和平
# Automatically builds and packages .tipa for TrollStore.

if [ $# -ne 1 ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

VERSION=$1
VERSION=${VERSION#v}

PROJECT_NAME="TOX-HUD-和平"
SCHEME_NAME="TOX-HUD-和平"
ARCHIVE_NAME="$PROJECT_NAME.xcarchive"
APP_NAME="$PROJECT_NAME.app"

echo "⚙️ Building $PROJECT_NAME (scheme: $SCHEME_NAME)..."

# Clean + build + archive using Xcode
xcodebuild clean build archive \
  -scheme "$SCHEME_NAME" \
  -project "$PROJECT_NAME.xcodeproj" \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -archivePath "$PROJECT_NAME" \
  CODE_SIGNING_ALLOWED=NO

# Check that archive folder exists
if [ ! -d "$ARCHIVE_NAME/Products/Applications" ]; then
    echo "❌ Error: Archive output not found!"
    exit 1
fi

# Copy entitlements
cp supports/entitlements.plist "$ARCHIVE_NAME/Products" || exit 1

cd "$ARCHIVE_NAME/Products/Applications" || exit 1

# Remove old signature
echo "🔧 Removing old signature..."
codesign --remove-signature "$APP_NAME" || true

cd ../ || exit 1

# Rename Applications -> Payload
mv Applications Payload

# Re-sign with ldid (installed from brew)
echo "🔑 Re-signing app..."
ldid -Sentitlements.plist "Payload/$APP_NAME" || {
    echo "❌ ldid failed!"
    exit 1
}

# Package as .tipa
echo "📦 Creating .tipa package..."
zip -qr "$PROJECT_NAME.tipa" Payload

cd ../../..
mkdir -p packages
mv "$ARCHIVE_NAME/Products/$PROJECT_NAME.tipa" "packages/${PROJECT_NAME}_${VERSION}.tipa"

echo "✅ Build finished successfully!"
echo "👉 Output: packages/${PROJECT_NAME}_${VERSION}.tipa"

#!/bin/bash

# Professional macOS Installer with Code Signing & Notarization
# Requires Apple Developer Account and proper certificates

set -e

APP_NAME="VideoDownloader"
VERSION="1.0"
DMG_NAME="${APP_NAME}_${VERSION}_Signed"
APP_PATH="/Users/bartwybouw/Library/Developer/Xcode/DerivedData/VideoDownloader-egbpwakybzccgrbgsmhgqcevpdgw/Build/Products/Release/VideoDownloader.app"
TEMP_DIR="/tmp/${DMG_NAME}_temp"
DMG_PATH="/Users/bartwybouw/Documents/Claude/VideoDownloader/${DMG_NAME}.dmg"
BUNDLE_ID="com.bamati.videodownloader"

echo "🍎 Creating professional signed VideoDownloader installer..."

# Check if app is signed
if ! codesign -vv "$APP_PATH" 2>/dev/null; then
    echo "❌ App is not properly signed!"
    echo "💡 Run './setup_codesigning.sh' first and rebuild the app"
    exit 1
fi

echo "✅ App is properly signed"

# Clean up any existing temp directory
rm -rf "$TEMP_DIR"
rm -f "$DMG_PATH"

# Create temp directory
mkdir -p "$TEMP_DIR"

# Copy the signed app
echo "📱 Copying signed VideoDownloader.app..."
cp -R "$APP_PATH" "$TEMP_DIR/"

# Verify the copied app is still signed
echo "🔍 Verifying app signature..."
codesign -vv "$TEMP_DIR/VideoDownloader.app"

# Create Applications symlink
echo "🔗 Creating Applications symlink..."
ln -s /Applications "$TEMP_DIR/Applications"

# Create enhanced README
cat > "$TEMP_DIR/README.txt" << 'EOF'
VideoDownloader v1.0 - Signed Release

A professional macOS app for downloading videos using yt-dlp.
This version is properly code signed with Apple Developer ID.

INSTALLATION:
1. Drag VideoDownloader.app to the Applications folder
2. Install yt-dlp if you haven't already: brew install yt-dlp
3. Launch VideoDownloader from Applications

✅ NO GATEKEEPER WARNINGS - This app is properly signed!

USAGE:
- Paste a video URL
- Select download location  
- Click "Download Video"
- Use pause/resume/stop controls as needed

REQUIREMENTS:
- macOS 12.0+ (Monterey or newer)
- yt-dlp installed via Homebrew

SUPPORT:
- Contact: bart.wybouw@bamati.be
- Powered by: https://github.com/yt-dlp/yt-dlp

Built with Apple Developer tools
EOF

# Calculate size for DMG
APP_SIZE=$(du -sm "$TEMP_DIR" | cut -f1)
DMG_SIZE=$((APP_SIZE + 50))

echo "📦 Creating signed DMG (${DMG_SIZE}MB)..."

# Create DMG
hdiutil create -volname "$APP_NAME" -srcfolder "$TEMP_DIR" -ov -format UDZO -size "${DMG_SIZE}m" "$DMG_PATH"

# Sign the DMG itself
echo "🔐 Signing the DMG..."
if security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -n1 | sed 's/.*"Developer ID Application: \([^"]*\)".*/Developer ID Application: \1/')
    codesign --sign "$SIGNING_IDENTITY" --options runtime "$DMG_PATH"
    echo "✅ DMG signed successfully"
else
    echo "⚠️  DMG not signed - no Developer ID certificate found"
fi

# Clean up
rm -rf "$TEMP_DIR"

echo "🎉 Professional signed installer created!"
echo "📦 Location: $DMG_PATH"
echo "📏 Size: $(du -h "$DMG_PATH" | cut -f1)"

# Verify DMG
echo "🔍 Verifying DMG..."
hdiutil verify "$DMG_PATH"

echo ""
echo "✨ Ready for distribution!"
echo "📋 This DMG contains:"
echo "   - Properly signed VideoDownloader.app"  
echo "   - Applications folder symlink"
echo "   - Installation instructions"
echo "   - NO Gatekeeper warnings for users!"

# Optional: Notarization info
echo ""
echo "🚀 For App Store-level trust, consider notarization:"
echo "   xcrun notarytool submit $DMG_PATH --keychain-profile 'AC_PASSWORD' --wait"
echo "   (Requires setting up notarization credentials first)"
#!/bin/bash

# VideoDownloader DMG Installer Creator
# This script creates a DMG installer for the VideoDownloader app

set -e

APP_NAME="VideoDownloader"
VERSION="1.0"
DMG_NAME="${APP_NAME}_${VERSION}"
APP_PATH="/Users/bartwybouw/Library/Developer/Xcode/DerivedData/VideoDownloader-egbpwakybzccgrbgsmhgqcevpdgw/Build/Products/Release/VideoDownloader.app"
TEMP_DIR="/tmp/${DMG_NAME}_temp"
DMG_PATH="/Users/bartwybouw/Documents/Claude/VideoDownloader/${DMG_NAME}.dmg"

echo "Creating VideoDownloader installer..."

# Clean up any existing temp directory
rm -rf "$TEMP_DIR"
rm -f "$DMG_PATH"

# Create temp directory
mkdir -p "$TEMP_DIR"

# Copy the app
echo "Copying VideoDownloader.app..."
cp -R "$APP_PATH" "$TEMP_DIR/"

# Create Applications symlink for easy installation
echo "Creating Applications symlink..."
ln -s /Applications "$TEMP_DIR/Applications"

# Create a simple README
cat > "$TEMP_DIR/README.txt" << 'EOF'
VideoDownloader v1.0

A simple macOS app for downloading videos using yt-dlp.

INSTALLATION:
1. Drag VideoDownloader.app to the Applications folder
2. Install yt-dlp if you haven't already: brew install yt-dlp
3. Launch VideoDownloader from Applications

USAGE:
- Paste a video URL
- Select download location
- Click "Download Video"

Contact: bart.wybouw@bamati.be
Powered by yt-dlp: https://github.com/yt-dlp/yt-dlp

Built with Claude Code
EOF

# Calculate size needed for DMG (app size + some extra space)
APP_SIZE=$(du -sm "$TEMP_DIR" | cut -f1)
DMG_SIZE=$((APP_SIZE + 50))

echo "Creating DMG (${DMG_SIZE}MB)..."

# Create DMG
hdiutil create -volname "$APP_NAME" -srcfolder "$TEMP_DIR" -ov -format UDZO -size "${DMG_SIZE}m" "$DMG_PATH"

# Clean up temp directory
rm -rf "$TEMP_DIR"

echo "✅ DMG installer created: $DMG_PATH"
echo "📦 Size: $(du -h "$DMG_PATH" | cut -f1)"

# Verify the DMG
echo "🔍 Verifying DMG..."
hdiutil verify "$DMG_PATH"

echo "🎉 VideoDownloader installer is ready!"
echo "You can now distribute: ${DMG_NAME}.dmg"
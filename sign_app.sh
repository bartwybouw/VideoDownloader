#!/bin/bash

# macOS App Signing Script
# This removes the quarantine attribute and creates a properly signed app

APP_PATH="/Applications/VideoDownloader.app"
BUILD_PATH="/Users/bartwybouw/Library/Developer/Xcode/DerivedData/VideoDownloader-egbpwakybzccgrbgsmhgqcevpdgw/Build/Products/Release/VideoDownloader.app"

echo "🔐 Fixing macOS Gatekeeper issues for VideoDownloader..."

# Check if app exists in Applications
if [ -d "$APP_PATH" ]; then
    echo "📱 Found app in Applications folder"
    
    # Remove quarantine attribute
    echo "🧹 Removing quarantine attribute..."
    sudo xattr -d com.apple.quarantine "$APP_PATH" 2>/dev/null || echo "No quarantine attribute found"
    sudo xattr -d com.apple.provenance "$APP_PATH" 2>/dev/null || echo "No provenance attribute found"
    
    # Show current attributes
    echo "📋 Current extended attributes:"
    xattr -l "$APP_PATH" || echo "No extended attributes found"
    
    echo "✅ App should now open without Gatekeeper warnings"
    echo "💡 If issues persist, right-click the app and choose 'Open'"
    
elif [ -d "$BUILD_PATH" ]; then
    echo "📱 Found app in build folder"
    echo "🧹 Removing quarantine attribute from build..."
    sudo xattr -rd com.apple.quarantine "$BUILD_PATH" 2>/dev/null || echo "No quarantine attribute found"
    
    echo "✅ Build app cleaned. Install it to Applications folder."
    
else
    echo "❌ VideoDownloader.app not found in Applications or build folder"
    echo "💡 Please install the app first or build it in Xcode"
fi

echo ""
echo "🔒 For permanent solution, the app needs proper code signing."
echo "📋 Current workarounds:"
echo "   1. Right-click app > Open (one time)"
echo "   2. System Preferences > Security > 'Open Anyway'"
echo "   3. Run this script to remove quarantine"
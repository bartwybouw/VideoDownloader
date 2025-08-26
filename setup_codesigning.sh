#!/bin/bash

# Apple Developer Code Signing Setup
# Run this after installing your Developer ID Application certificate

echo "🍎 Setting up Apple Developer Code Signing..."

# Check for Developer ID certificates
echo "🔍 Checking for available certificates..."
CERTIFICATES=$(security find-identity -v -p codesigning | grep "Developer ID Application")

if [ -z "$CERTIFICATES" ]; then
    echo "❌ No Developer ID Application certificate found"
    echo ""
    echo "📋 Please follow these steps:"
    echo "1. Go to https://developer.apple.com/account/resources/certificates/list"
    echo "2. Click '+' to create a new certificate"
    echo "3. Select 'Developer ID Application' (for distribution outside Mac App Store)"
    echo "4. Follow the instructions to create and download the certificate"
    echo "5. Double-click the downloaded .cer file to install it in Keychain"
    echo "6. Re-run this script"
    exit 1
fi

echo "✅ Found certificates:"
echo "$CERTIFICATES"
echo ""

# Extract the certificate name for code signing
CERT_NAME=$(echo "$CERTIFICATES" | head -n1 | sed 's/.*"Developer ID Application: \([^"]*\)".*/\1/' | sed 's/.*"Developer ID Application: //' | sed 's/".*//')
echo "🎯 Will use certificate: Developer ID Application: $CERT_NAME"

# Update Xcode project with code signing settings
echo "⚙️  Updating Xcode project settings..."

# Add code signing settings to both Debug and Release configurations
python3 << EOF
import re

# Read the project file
with open('VideoDownloader.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Add code signing settings to Debug configuration
debug_pattern = r'(A10000018 /\* Debug \*/ = \{[^}]*buildSettings = \{[^}]*)(CODE_SIGN_STYLE = Automatic;)'
if 'CODE_SIGN_IDENTITY = "Developer ID Application"' not in content:
    content = re.sub(
        r'(A10000018 /\* Debug \*/ = \{[^}]*buildSettings = \{[^}]*)(CODE_SIGN_STYLE = Automatic;)',
        r'\1CODE_SIGN_IDENTITY = "Developer ID Application";\n\t\t\t\t\2',
        content
    )

# Add code signing settings to Release configuration  
release_pattern = r'(A10000019 /\* Release \*/ = \{[^}]*buildSettings = \{[^}]*)(CODE_SIGN_STYLE = Automatic;)'
if 'CODE_SIGN_IDENTITY = "Developer ID Application"' not in content:
    content = re.sub(
        r'(A10000019 /\* Release \*/ = \{[^}]*buildSettings = \{[^}]*)(CODE_SIGN_STYLE = Automatic;)',
        r'\1CODE_SIGN_IDENTITY = "Developer ID Application";\n\t\t\t\t\2',
        content
    )

# Write back
with open('VideoDownloader.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("✅ Project updated with code signing settings")
EOF

echo ""
echo "🎉 Code signing setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Build the app in Xcode (Release configuration)"
echo "2. The app will now be properly signed with your Developer ID"
echo "3. Create a new DMG with: ./create_installer.sh"
echo "4. Distribute the signed DMG - no more Gatekeeper warnings!"
echo ""
echo "🔐 To verify signing worked:"
echo "   codesign -vv -d /path/to/VideoDownloader.app"
#!/usr/bin/env bash
#
# Build a signed, notarized, stapled Developer-ID release of News of the
# World and package it as a DMG.
#
# Usage:
#   scripts/release.sh <version>                 # e.g. scripts/release.sh 0.1.0
#   scripts/release.sh                           # picks up MARKETING_VERSION from the project
#
# Prerequisites (one-time):
#   * "Developer ID Application" certificate installed in the Keychain
#   * App-specific App Store Connect API key stored under the profile
#     NEWS_OF_THE_WORLD_NOTARY, e.g. via:
#       xcrun notarytool store-credentials "NEWS_OF_THE_WORLD_NOTARY" \
#         --key ~/.appstoreconnect/private_keys/AuthKey_XXX.p8 \
#         --key-id XXX --issuer YYY
#   * create-dmg (brew install create-dmg)
#
# Outputs land in build/release/:
#   * NewsOfTheWorld-<version>.app              (signed, stapled)
#   * NewsOfTheWorld-<version>.dmg              (signed, stapled, ready to upload)
#   * NewsOfTheWorld-<version>.dmg.sha256       (checksum for the Homebrew cask)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

# Force full Xcode even if xcode-select points at Command Line Tools.
if [[ -z "${DEVELOPER_DIR:-}" ]] || [[ "$DEVELOPER_DIR" == *CommandLineTools* ]]; then
    if [[ -d /Applications/Xcode.app/Contents/Developer ]]; then
        export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
    else
        echo "Xcode.app not found at /Applications/Xcode.app — install Xcode or" >&2
        echo "run: sudo xcode-select -s /path/to/Xcode.app/Contents/Developer" >&2
        exit 1
    fi
fi

SCHEME="newsoftheworld"
PROJECT="newsoftheworld.xcodeproj"
APP_NAME="newsoftheworld"
PRODUCT_LABEL="NewsOfTheWorld"
NOTARY_PROFILE="NEWS_OF_THE_WORLD_NOTARY"
EXPORT_OPTS="$REPO_ROOT/ExportOptions.plist"

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
    VERSION=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" \
        -configuration Release -showBuildSettings 2>/dev/null \
        | awk -F ' = ' '/^ *MARKETING_VERSION/ {gsub(/ /, "", $2); print $2; exit}')
fi
if [[ -z "$VERSION" ]]; then
    VERSION="0.0.0"
fi
echo "==> Release version: $VERSION"

BUILD_DIR="$REPO_ROOT/build/release"
ARCHIVE_PATH="$BUILD_DIR/$PRODUCT_LABEL-$VERSION.xcarchive"
EXPORT_DIR="$BUILD_DIR/$PRODUCT_LABEL-$VERSION-export"
DMG_PATH="$BUILD_DIR/$PRODUCT_LABEL-$VERSION.dmg"

rm -rf "$ARCHIVE_PATH" "$EXPORT_DIR" "$DMG_PATH" "$DMG_PATH.sha256"
mkdir -p "$BUILD_DIR"

echo "==> Archiving $SCHEME $VERSION"
xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -destination 'generic/platform=macOS' \
    archive

echo "==> Exporting archive"
xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist "$EXPORT_OPTS" \
    -exportPath "$EXPORT_DIR"

APP_BUNDLE="$EXPORT_DIR/$APP_NAME.app"
if [[ ! -d "$APP_BUNDLE" ]]; then
    echo "Exported app bundle not found at $APP_BUNDLE" >&2
    exit 1
fi

echo "==> Verifying signature"
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

echo "==> Preparing notarization archive (zip)"
NOTARY_ZIP="$EXPORT_DIR/$PRODUCT_LABEL-$VERSION-notarize.zip"
ditto -c -k --keepParent "$APP_BUNDLE" "$NOTARY_ZIP"

echo "==> Submitting to Apple notarization (may take a minute or two)"
xcrun notarytool submit "$NOTARY_ZIP" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait

echo "==> Stapling notarization ticket"
xcrun stapler staple "$APP_BUNDLE"
xcrun stapler validate "$APP_BUNDLE"

echo "==> Building DMG"
if ! command -v create-dmg >/dev/null 2>&1; then
    echo "create-dmg not found. Install with: brew install create-dmg" >&2
    exit 1
fi
create-dmg \
    --volname "$PRODUCT_LABEL $VERSION" \
    --window-pos 200 200 \
    --window-size 560 360 \
    --icon-size 96 \
    --icon "$APP_NAME.app" 150 160 \
    --hide-extension "$APP_NAME.app" \
    --app-drop-link 410 160 \
    --no-internet-enable \
    "$DMG_PATH" \
    "$APP_BUNDLE"

echo "==> Signing DMG"
codesign --sign "Developer ID Application" --timestamp "$DMG_PATH"

echo "==> Notarizing DMG"
xcrun notarytool submit "$DMG_PATH" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait
xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"

echo "==> Computing SHA-256"
shasum -a 256 "$DMG_PATH" | tee "$DMG_PATH.sha256"

echo
echo "==> Done"
echo "App:    $APP_BUNDLE"
echo "DMG:    $DMG_PATH"
echo "SHA256: $DMG_PATH.sha256"

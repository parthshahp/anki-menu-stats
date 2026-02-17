#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Anki Menu Stats"
EXECUTABLE_NAME="anki-menu-stats"
BUNDLE_ID="com.parth.ankimenustats"
PLIST_PATH="Info.plist"
DIST_DIR="dist"
BUILD_CONFIG="release"
SIGN_IDENTITY="-"

usage() {
  cat <<USAGE
Usage: $0 [options]

Options:
  --sign-identity "Developer ID Application: Your Name (TEAMID)"
      Use a real signing identity instead of ad-hoc signing.
  --version X.Y.Z
      Override CFBundleShortVersionString for this build.
  -h, --help
      Show this help.
USAGE
}

VERSION_OVERRIDE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sign-identity)
      SIGN_IDENTITY="$2"
      shift 2
      ;;
    --version)
      VERSION_OVERRIDE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ ! -f "$PLIST_PATH" ]]; then
  echo "Missing $PLIST_PATH" >&2
  exit 1
fi

if [[ -n "$VERSION_OVERRIDE" ]]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION_OVERRIDE" "$PLIST_PATH"
fi

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST_PATH")
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PLIST_PATH")

APP_DIR="$DIST_DIR/${APP_NAME}.app"
PKG_DIR="$DIST_DIR/pkg"
DMG_PATH="$DIST_DIR/${APP_NAME// /-}-${VERSION}.dmg"
VOL_NAME="${APP_NAME} ${VERSION}"

rm -rf "$APP_DIR" "$PKG_DIR" "$DMG_PATH"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

echo "[1/6] Building Swift package ($BUILD_CONFIG)..."
swift build -c "$BUILD_CONFIG"

echo "[2/6] Preparing app bundle..."
cp ".build/${BUILD_CONFIG}/${EXECUTABLE_NAME}" "$APP_DIR/Contents/MacOS/${EXECUTABLE_NAME}"
chmod +x "$APP_DIR/Contents/MacOS/${EXECUTABLE_NAME}"
cp "$PLIST_PATH" "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable $EXECUTABLE_NAME" "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_DIR/Contents/Info.plist"
plutil -lint "$APP_DIR/Contents/Info.plist" >/dev/null

echo "[3/6] No compiled app icon configured in this SwiftPM release flow."

echo "[4/6] Signing app bundle with identity: $SIGN_IDENTITY"
if [[ "$SIGN_IDENTITY" == "-" ]]; then
  codesign --force --deep --sign "-" "$APP_DIR"
else
  codesign --force --deep --timestamp --sign "$SIGN_IDENTITY" "$APP_DIR"
fi
codesign --verify --deep --strict "$APP_DIR"

echo "[5/6] Creating DMG..."
mkdir -p "$PKG_DIR"
cp -R "$APP_DIR" "$PKG_DIR/"
ln -s /Applications "$PKG_DIR/Applications"
hdiutil create \
  -volname "$VOL_NAME" \
  -srcfolder "$PKG_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null
rm -rf "$PKG_DIR"

if [[ "$SIGN_IDENTITY" != "-" ]]; then
  echo "[6/6] DMG created. Consider notarizing before distribution."
else
  echo "[6/6] DMG created (ad-hoc signed app; suitable for local use)."
fi

echo ""
echo "Artifacts:"
echo "- App: $APP_DIR"
echo "- DMG: $DMG_PATH"

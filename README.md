# Anki Menu Stats

Minimal macOS menu bar app (SwiftUI) that shows:
- cards left to review today
- time reviewed today

Data comes from a local Anki instance via AnkiConnect.

## Requirements
- macOS 14+
- Xcode / Swift toolchain
- Anki running with AnkiConnect enabled at `http://127.0.0.1:8765`

## Run (dev)
```bash
swift build
open Package.swift
```
Run the `anki-menu-stats` scheme in Xcode.

## Build + install locally
```bash
swift build -c release

APP_NAME="Anki Menu Stats"
APP_DIR="dist/${APP_NAME}.app"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp .build/release/anki-menu-stats "$APP_DIR/Contents/MacOS/anki-menu-stats"
chmod +x "$APP_DIR/Contents/MacOS/anki-menu-stats"
cp Info.plist "$APP_DIR/Contents/Info.plist"

codesign --force --deep --sign - "$APP_DIR"
cp -R "$APP_DIR" /Applications/
open "/Applications/${APP_NAME}.app"
```

## Notes
- This app uses `deckNames` + `getDeckStats` + `getCollectionStatsHTML` for compatibility with AnkiConnect API v6.
- If **Open Anki** does nothing, ensure Anki is installed in `/Applications/Anki.app` or `~/Applications/Anki.app`.

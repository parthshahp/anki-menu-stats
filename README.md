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

## One-command release (app + DMG)
```bash
./scripts/release.sh

# Optional: real signing identity
./scripts/release.sh --sign-identity "Developer ID Application: Your Name (TEAMID)"
```

Artifacts are written to `dist/`:
- `dist/Anki Menu Stats.app`
- `dist/Anki-Menu-Stats-<version>.dmg`

## Install locally
```bash
cp -R "dist/Anki Menu Stats.app" /Applications/
open "/Applications/Anki Menu Stats.app"
```

## Notes
- This app uses `deckNames` + `getDeckStats` + `getCollectionStatsHTML` for compatibility with AnkiConnect API v6.
- If **Open Anki** does nothing, ensure Anki is installed in `/Applications/Anki.app` or `~/Applications/Anki.app`.

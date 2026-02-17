# Anki Menu Stats

Minimal macOS menu bar app (SwiftUI) that shows:
- cards left to review today
- time reviewed today

Data comes from a local Anki instance via AnkiConnect.

<img width="332" height="279" alt="Screenshot 2026-02-16 at 10 00 35 PM" src="https://github.com/user-attachments/assets/b89c16ad-2daf-40bf-9360-bbbe4e2ead8d" />


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

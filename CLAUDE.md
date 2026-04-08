# CLAUDE.md

Project-level instructions for Claude Code when working in this repository.

## Project Overview

YouTube Music Bar is a native macOS menu bar app for YouTube Music. It uses a hidden WKWebView as the audio engine, injected JavaScript for playback control/observation, and the YouTube Music internal API (`youtubei/v1`) with SAPISIDHASH authentication.

## Repository Structure

```
YouTubeMusicBar/          ← Main app source (release-ready)
  App/                    — YouTubeMusicBarApp, AppDelegate, FloatingPanel, StatusBarLyricView
  Models/                 — Track, PlaybackState, RepeatMode, Playlist, SearchResult, PlaybackContext
  Services/               — PlayerService, AuthService, WebKitManager, SingletonPlayerWebView
    API/                  — YTMusicClient, APICache, Parsers.swift (all parsers)
  Views/                  — MainPanelView, HomeView, SearchView, LibraryView, NowPlayingView, etc.
  Utilities/              — Constants
  Resources/              — controls.js, observer.js, Info.plist, entitlements, assets
YouTubeMusicBarTests/     ← Unit tests
kaset/                    ← Upstream reference app (read-only, do not modify)
website/                  ← Product landing page (React + Vite, deployed to GitHub Pages)
docs/                     ← Screenshots and multi-language READMEs
.github/workflows/        ← GitHub Actions (website deployment)
project.yml               ← XcodeGen project spec
```

## Build & Run

```bash
# Generate Xcode project (requires xcodegen)
xcodegen

# Open in Xcode
open YouTubeMusicBar.xcodeproj
# Select YouTubeMusicBar scheme → Run (⌘R)

# Run tests
xcodebuild test -project YouTubeMusicBar.xcodeproj -scheme YouTubeMusicBar -destination 'platform=macOS'

# Build website locally
cd website && npm install && npm run dev
```

## Key Technical Details

- **Swift 6.0** with strict concurrency (`SWIFT_STRICT_CONCURRENCY: complete`)
- **macOS 26+** deployment target (Liquid Glass design)
- **No third-party dependencies** — pure Apple frameworks
- **LSUIElement: true** — menu bar app, no Dock icon
- **Bundle ID:** `com.youtubemusicbar.app`
- **Product name:** `YouTube Music Bar` (with spaces)
- **Test module import:** `@testable import YouTube_Music_Bar` (underscores)

## Architecture Rules

- All playback goes through the hidden WKWebView via `evaluateJSFire()` — never play audio outside it
- State flows one-way: JS → Swift via WKScriptMessageHandler (`observer`, `trackEnded`, `lyricsTime`)
- Services use `@MainActor @Observable` pattern
- Views use SwiftUI Environment for DI (`AuthService`, `PlayerService`, `YTMusicClient`, etc.)
- API authentication: cookies from WKWebView cookie store → SAPISIDHASH header, refreshed per request

## Code Style

- No unnecessary comments, docstrings, or type annotations on unchanged code
- Prefer editing existing files over creating new ones
- All parsers live in `Parsers.swift` — add new parsers there
- Use `Dictionary.dig()` extension for safe nested JSON access
- Keep views within 320px width (menu bar panel constraint)
- Liquid Glass: use `glassEffect()` on macOS 26+, `.ultraThinMaterial` fallback

## Things to Avoid

- Do NOT modify anything in `kaset/` — it's the upstream reference
- Do NOT add third-party dependencies without explicit approval
- Do NOT remove the service worker blocking rule (`blockSW`)
- Do NOT bypass the cookie-based auth flow
- Do NOT commit `.env`, credentials, or signing identities

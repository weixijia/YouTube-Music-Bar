# Project Conventions

## Language & Framework

- **Swift 6.2+** with strict concurrency enabled
- **SwiftUI** for all UI (views, state, animations)
- **AppKit** only for system integration (NSStatusItem, NSPopover, WKWebView wrapping)
- **Minimum deployment**: macOS 13 (Ventura)
- **Liquid Glass target**: macOS 26 (Tahoe) with fallback

## Naming Conventions

### Swift
- Types: `UpperCamelCase` — `PlaybackState`, `WebViewBridge`
- Properties/methods: `lowerCamelCase` — `isPlaying`, `togglePlayback()`
- Constants: `lowerCamelCase` — `let maxVolume = 100`
- Protocols: noun or adjective — `Playable`, `TrackProviding`
- Enums: `UpperCamelCase` type, `lowerCamelCase` cases

### Files
- One primary type per file, named after the type: `PlaybackControls.swift`
- Views: `*View.swift` — `MiniPlayerView.swift`, `SettingsView.swift`
- ViewModels: `*ViewModel.swift` — `PlayerViewModel.swift`
- Services: `*Service.swift` or `*Manager.swift` — `WebViewManager.swift`
- JavaScript files: `*.js` in Resources folder — `observer.js`, `controls.js`

### Project Structure
```
YtbMusicBar/
├── App/
│   ├── YtbMusicBarApp.swift        # @main entry point
│   └── AppDelegate.swift           # AppKit lifecycle if needed
├── Views/
│   ├── MiniPlayerView.swift        # Main popover content
│   ├── PlaybackControlsView.swift  # Play/pause/skip/like
│   ├── AlbumArtView.swift          # Album art display
│   ├── ProgressBarView.swift       # Track progress
│   └── SettingsView.swift          # Preferences
├── ViewModels/
│   └── PlayerViewModel.swift       # Playback state & logic
├── Services/
│   ├── WebViewManager.swift        # WKWebView setup & JS bridge
│   ├── MediaKeyHandler.swift       # MPRemoteCommandCenter
│   └── NowPlayingService.swift     # MPNowPlayingInfoCenter
├── Models/
│   ├── Track.swift                 # Track info model
│   └── PlaybackState.swift         # Playing/paused/etc
├── Resources/
│   ├── observer.js                 # MutationObserver script
│   ├── controls.js                 # Playback control functions
│   └── Assets.xcassets             # App icon, menu bar icon
├── Utilities/
│   └── Constants.swift             # URLs, selectors, keys
└── Info.plist
```

## Code Style

- Prefer `let` over `var` unless mutation is required
- Use trailing closure syntax for single-closure parameters
- Use `guard` for early returns
- Avoid force unwrapping (`!`) — use `if let` or `guard let`
- Prefer `async/await` over completion handlers
- Keep functions under 40 lines; extract when larger
- No commented-out code in commits

## Dependencies

- **Zero external dependencies** for MVP (no SPM packages)
- All functionality via Apple frameworks: SwiftUI, WebKit, MediaPlayer, ServiceManagement
- If a dependency is truly needed later, use Swift Package Manager

## Git Conventions

See [../Skills/conventional-commit.md](../Skills/conventional-commit.md) for commit format.

- Branch from `main` for features: `feat/menu-bar-popover`
- Keep commits atomic and independently buildable
- Tag releases with semver: `v0.1.0`, `v0.2.0`

## Related
- [architecture-rules.md](architecture-rules.md) — Architecture patterns
- [ux-rules.md](ux-rules.md) — UX constraints
- [../Skills/swift-concurrency.md](../Skills/swift-concurrency.md) — Concurrency rules

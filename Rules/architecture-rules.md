# Architecture Rules

## Pattern: MVVM with Services

```
View ←→ ViewModel ←→ Service
                   ←→ WebViewManager
                   ←→ MediaKeyHandler
```

### Views (SwiftUI)
- Pure UI rendering — no business logic
- Observe ViewModel via `@Observable` (macOS 14+) or `@ObservableObject`
- Never call WebView JavaScript directly from views

### ViewModels
- `@Observable @MainActor` classes
- Own the playback state and UI state
- Coordinate between services
- Single source of truth for what the UI displays

### Services
- Encapsulate system integration (WebKit, MediaPlayer, etc.)
- Communicate via async callbacks or Combine publishers
- Can be `actor` if they manage shared mutable state

## Module Boundaries

```
┌─────────────────────────────────────────┐
│  Views (SwiftUI)                        │
│  - Reads ViewModel state                │
│  - Sends user actions to ViewModel      │
├─────────────────────────────────────────┤
│  ViewModel (PlayerViewModel)            │
│  - @Observable @MainActor               │
│  - Owns Track, PlaybackState            │
│  - Coordinates services                 │
├─────────────────────────────────────────┤
│  Services                               │
│  ┌──────────────┐ ┌──────────────────┐ │
│  │ WebViewManager│ │ MediaKeyHandler  │ │
│  │ - WKWebView  │ │ - MPRemoteCmd    │ │
│  │ - JS Bridge  │ │ - MPNowPlaying   │ │
│  └──────────────┘ └──────────────────┘ │
├─────────────────────────────────────────┤
│  Models                                 │
│  - Track, PlaybackState (value types)   │
└─────────────────────────────────────────┘
```

## Hard Rules

### 1. WebView is Hidden
The WKWebView is an **audio engine**, not a visible UI component. Users interact with native SwiftUI controls, not the web page.

Exception: Initial Google login flow shows the WebView for authentication.

### 2. Single Source of Truth
`PlayerViewModel` is the single source of truth. The JS bridge pushes state to the ViewModel; the ViewModel pushes commands to the JS bridge. Never read state from two places.

### 3. No Private APIs
Use only public Apple frameworks. No `MediaRemote`, no `IOKit` hacks, no private selectors. These break across macOS versions.

### 4. Concurrency Boundaries
| Component | Isolation |
|-----------|-----------|
| All Views | `@MainActor` (implicit) |
| PlayerViewModel | `@MainActor` (explicit) |
| WebViewManager | `@MainActor` (WebKit requirement) |
| MediaKeyHandler | `@MainActor` (MediaPlayer requirement) |
| Network image loading | `nonisolated async` → dispatch to `@MainActor` |

### 5. Memory Budget
- Target: < 80MB total memory
- WebView is the biggest consumer — keep only one instance
- Cache album art images, don't re-fetch on every observer callback
- Release WebView resources when popover is hidden for > 5 minutes (optional)

### 6. Error Handling
- JS bridge failures: silently retry, log to console, don't crash
- Network errors: show offline indicator in UI
- WebView crashes: auto-reload with `webViewWebContentProcessDidTerminate`
- Never show raw error messages to user

### 7. Testability
- ViewModels are testable by injecting mock services
- Services are protocol-based for mocking
- JS scripts have known input/output contracts

## State Flow

```
YouTube Music Web ──(JS Observer)──→ WKScriptMessageHandler
                                          │
                                          ▼
                                    WebViewManager
                                          │
                                          ▼
                                    PlayerViewModel ──→ Views update
                                          │
                                          ▼
                                    NowPlayingService ──→ Control Center
                                    MediaKeyHandler ←── Media Keys
                                          │
                                          ▼
                                    PlayerViewModel
                                          │
                                          ▼
                          WebViewManager ──(evaluateJavaScript)──→ YouTube Music Web
```

## Related
- [project-conventions.md](project-conventions.md) — Naming & structure
- [ux-rules.md](ux-rules.md) — UX constraints
- [../References/youtube-music-integration.md](../References/youtube-music-integration.md) — JS bridge details
- [../References/open-source-projects.md](../References/open-source-projects.md) — Reference implementations

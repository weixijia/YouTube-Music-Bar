# Open Source Projects Reference

## Tier 1: Native macOS Swift (Primary References)

### sozercan/kaset ⭐ 915
- **URL**: https://github.com/sozercan/kaset
- **Language**: Swift 98.5% (SwiftUI) | MIT | Actively maintained
- **Architecture**: NOT a simple WebView wrapper — has its own `YTMusicClient.swift` making direct API calls to YouTube Music's internal API
- **Key features**:
  - SAPISID cookie-based auth for direct API calls
  - Hidden `SingletonPlayerWebView` for audio playback
  - Extensive JS observer scripts
  - Synced lyrics display
  - Apple Intelligence integration
  - AirPlay support
  - Queue management
  - URL schemes & AppleScript support
  - Mini player mode
- **Learnings**:
  - Most sophisticated approach: API + WebView hybrid
  - Shows how to extract SAPISID for authenticated API calls
  - Good reference for advanced features (lyrics, queue, AirPlay)
- **Considerations**: Complex architecture; overkill for a menu bar app MVP

### steve228uk/YouTube-Music ⭐ 2805
- **URL**: https://github.com/steve228uk/YouTube-Music
- **Language**: Swift 93.7% + ObjC | MIT | Older but proven
- **Architecture**: AppKit + WKWebView, established the core pattern
- **Key pattern** (used by all subsequent projects):
  ```javascript
  // Inject custom.js with MutationObserver on ytmusic-player-bar
  // Send data via window.webkit.messageHandlers.observer.postMessage()
  ```
- **Notable tricks**:
  - Plays `silence.mp3` via AVPlayer to claim Now Playing ownership
  - Uses `MediaKeyTap` + `Magnet` for hotkeys
  - Touch Bar support via private API
- **Learnings**:
  - The original pattern setter — all other Swift projects follow this model
  - `silence.mp3` trick may still be useful for Now Playing registration
- **Considerations**: Uses older AppKit patterns; no SwiftUI

### 0xjemm/youtube-music-macos ⭐ 21
- **URL**: https://github.com/0xjemm/youtube-music-macos
- **Language**: Swift (modern SwiftUI) | MIT | Dec 2025
- **Architecture**: Only 4 Swift source files! Modern SwiftUI + `NSViewRepresentable`
- **Key features**:
  - Complete JS bridge for track info (polls + MutationObserver)
  - `MediaKeyHandler.swift` with full MPRemoteCommandCenter + MPNowPlayingInfoCenter
  - Discord Rich Presence
  - Frameless window design
- **Learnings**:
  - **Best starting reference** for our project due to:
    - Modern SwiftUI architecture
    - Minimal codebase (easy to understand)
    - Already implements the exact JS bridge + media key pattern we need
  - Shows how to structure a clean, small YouTube Music wrapper
- **Considerations**: No menu bar mode; window-based app; no Liquid Glass

## Tier 2: Electron Desktop Apps (Architecture Reference)

### ytmdesktop/ytmdesktop ⭐ 5793
- **URL**: https://github.com/ytmdesktop/ytmdesktop
- **Stack**: TypeScript/Vue | GPL-3.0
- **Value**: Most popular YT Music desktop app; good feature reference list

### Venipa/ytmdesktop2 ⭐ 892
- **URL**: https://github.com/Venipa/ytmdesktop2
- **Stack**: TypeScript/Vue 3 | CC0
- **Value**: Modern rewrite with plugin architecture

## Tier 3: API Libraries

### sigma67/ytmusicapi ⭐ 2586
- **URL**: https://github.com/sigma67/ytmusicapi
- **Stack**: Python | MIT
- **Value**: The definitive reverse-engineered YouTube Music API. Documents all endpoints.
- **Relevance**: Reference for understanding YT Music API structure if we pursue direct API calls

## Key Technical Patterns (Shared Across All Projects)

### 1. WebView User Agent Spoofing
```swift
webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " +
    "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
```
**Why**: Google blocks login in embedded WebViews; Safari UA bypasses this.

### 2. JavaScript Playback State Extraction
All projects use the same selectors:
- `.title.ytmusic-player-bar` → track title
- `.byline.ytmusic-player-bar a` → artist name
- `img.image.ytmusic-player-bar` → album art URL
- `video` element → paused, currentTime, duration, volume
- `#movie_player` → playVideo(), pauseVideo(), nextVideo(), previousVideo()

### 3. Media Control Integration
All use `MPRemoteCommandCenter` + `MPNowPlayingInfoCenter`. **None use private APIs.**

### 4. Service Worker Blocking
Block `sw.js` to prevent caching issues with WKWebView.

## Our Innovation Opportunity

**No existing project combines:**
- Menu bar (NSPopover / MenuBarExtra) form factor
- Liquid Glass design (macOS 26+)
- Modern SwiftUI-first architecture

This is our unique value proposition.

## Recommended Approach

Start with the **0xjemm/youtube-music-macos** pattern (simplest, modern SwiftUI) and adapt:
1. Replace window with MenuBarExtra popover
2. Add Liquid Glass controls
3. Keep the JS bridge + MediaKey handler pattern as-is
4. Add album art extraction + Now Playing integration from kaset

## Related
- [youtube-music-integration.md](youtube-music-integration.md) — Integration details
- [menu-bar-app-architecture.md](menu-bar-app-architecture.md) — Our architecture
- [../Rules/architecture-rules.md](../Rules/architecture-rules.md) — Code rules

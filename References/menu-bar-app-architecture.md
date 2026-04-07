# macOS Menu Bar App Architecture

## Overview

Menu bar apps (status bar apps) live in the system menu bar, providing quick access without a full window or Dock presence. This is the core interaction model for Ytb Music Bar.

## Key Architecture Decisions

### NSPopover (Recommended) vs NSMenu

| Approach | Pros | Cons |
|----------|------|------|
| **NSPopover** | Rich content, custom views, WebView support | More complex setup |
| NSMenu | Native feel, fast | Too restrictive for music player UI |

**Decision: Use NSPopover** — we need album art, playback controls, and an embedded WebView.

### SwiftUI + AppKit Hybrid (70/30 Split)

- **SwiftUI (70%)**: Views, state management, animations, Liquid Glass
- **AppKit (30%)**: NSStatusItem, NSPopover, WKWebView wrapping, system integration

### macOS 13+ MenuBarExtra

```swift
@main
struct YtbMusicBarApp: App {
    var body: some Scene {
        MenuBarExtra("YT Music", systemImage: "music.note") {
            ContentView()
        }
        .menuBarExtraStyle(.window) // popover-style, not menu-style
        
        Settings {
            SettingsView()
        }
    }
}
```

## Key Specifications

| Property | Value |
|----------|-------|
| Menu bar icon | 16x16pt template image (auto-tints for dark mode) |
| Popover width | ~320pt |
| Popover height | ~400-480pt |
| Info.plist | `LSUIElement: true` (hide from Dock) |
| Min deployment | macOS 13 (Ventura) for MenuBarExtra |
| Liquid Glass | macOS 26 (Tahoe) with fallback |

## App Lifecycle

```
Launch → NSStatusItem created → Icon visible in menu bar
Click icon → NSPopover shown → WebView loads YouTube Music
Click outside → Popover dismissed → App stays in menu bar
```

### Launch at Login

Use `SMAppService` (macOS 13+):
```swift
import ServiceManagement

try SMAppService.mainApp.register() // enable
try SMAppService.mainApp.unregister() // disable
```

### No Dock Icon

Set `LSUIElement = YES` in Info.plist, or use:
```swift
NSApp.setActivationPolicy(.accessory)
```

## Popover Layout Structure

```
┌──────────────────────────┐
│  ┌────────┐              │
│  │ Album  │ Track Title  │
│  │  Art   │ Artist Name  │
│  │120x120 │              │
│  └────────┘              │
│ ─────────────────────── │  ← Progress bar
│  0:00            3:45    │
│                          │
│  ⏮   advancement   advancement  ♡  │  ← Playback controls
│                          │
│  🔊 ═══════════════     │  ← Volume
│                          │
│  [Open in Browser]       │  ← Secondary action
└──────────────────────────┘
```

## Memory Footprint Target

- Native Swift: ~50-80MB (target)
- vs Electron: ~200-300MB (avoid)

## Related
- [youtube-music-integration.md](youtube-music-integration.md) — WebView integration
- [liquid-glass-design.md](liquid-glass-design.md) — Visual design
- [open-source-projects.md](open-source-projects.md) — Reference implementations
- [../Rules/architecture-rules.md](../Rules/architecture-rules.md) — Code architecture

# Ytb Music Bar

A native macOS menu bar app for YouTube Music with Liquid Glass design.

## Project Overview

**What**: A lightweight menu bar application that provides quick access to YouTube Music playback controls, album art, and track info — without opening a browser.

**How**: Native Swift/SwiftUI app with a hidden WKWebView as the audio engine. YouTube Music web player runs invisibly; users interact only with native macOS controls.

**Unique Value**: First YouTube Music menu bar app with Apple Liquid Glass design (macOS 26+), combining the convenience of a status bar utility with modern Apple aesthetics.

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Language | Swift 6.2+ |
| UI Framework | SwiftUI (70%) + AppKit (30%) |
| Web Engine | WKWebView (hidden, audio only) |
| Media Controls | MPRemoteCommandCenter + MPNowPlayingInfoCenter |
| Design | Liquid Glass (macOS 26+) with .ultraThinMaterial fallback |
| Min Deployment | macOS 14 (Sonoma) |
| Dependencies | Zero external packages — Apple frameworks only |

## Architecture

MVVM with Services. See [Rules/architecture-rules.md](Rules/architecture-rules.md) for details.

```
Views (SwiftUI) → ViewModel → Services (WebView, MediaKeys, NowPlaying)
                                    ↕
                            YouTube Music Web (hidden WKWebView)
```

## Knowledge Base

### Skills/ — Coding rules and best practices
| File | Purpose |
|------|---------|
| [swiftui-expert.md](Skills/swiftui-expert.md) | SwiftUI state management, view composition, macOS patterns |
| [liquid-glass.md](Skills/liquid-glass.md) | Liquid Glass API: `.glassEffect()`, `GlassEffectContainer` |
| [swift-concurrency.md](Skills/swift-concurrency.md) | Swift 6.2+ actor isolation, Sendable, `@MainActor` |
| [ios-hig-design.md](Skills/ios-hig-design.md) | Apple HIG: layout, typography, color, accessibility |
| [refactoring-ui.md](Skills/refactoring-ui.md) | Visual hierarchy, spacing scales, typography system |
| [conventional-commit.md](Skills/conventional-commit.md) | Git commit format: `feat(scope): message` |

### References/ — Research and technical documentation
| File | Purpose |
|------|---------|
| [menu-bar-app-architecture.md](References/menu-bar-app-architecture.md) | NSPopover, MenuBarExtra, LSUIElement, popover layout |
| [youtube-music-integration.md](References/youtube-music-integration.md) | WKWebView setup, JS bridge, selectors, media key integration |
| [liquid-glass-design.md](References/liquid-glass-design.md) | Where to apply glass, visual composition, fallback strategy |
| [design-inspirations.md](References/design-inspirations.md) | Sleeve, Tuneful, Spotica Menu — design patterns to adopt |
| [open-source-projects.md](References/open-source-projects.md) | kaset, YouTube-Music, youtube-music-macos — code references |

### Rules/ — Project-specific constraints
| File | Purpose |
|------|---------|
| [project-conventions.md](Rules/project-conventions.md) | Naming, file structure, code style, zero dependencies |
| [architecture-rules.md](Rules/architecture-rules.md) | MVVM, module boundaries, state flow, memory budget |
| [ux-rules.md](Rules/ux-rules.md) | Popover behavior, controls, keyboard shortcuts, anti-patterns |

## Key Technical Decisions

1. **Hidden WebView** — WKWebView is the audio engine, not visible UI. Users interact with native SwiftUI controls.
2. **JS Bridge Pattern** — MutationObserver on `ytmusic-player-bar` → `window.webkit.messageHandlers` → Swift. Proven pattern used by all existing YT Music wrappers.
3. **Safari User Agent** — Required for Google login in WKWebView. All existing projects use this approach.
4. **No Private APIs** — Only public Apple frameworks. Private MediaRemote API broke in macOS 15.4.
5. **Liquid Glass with Fallback** — `.glassEffect()` on macOS 26+, `.ultraThinMaterial` on earlier versions.
6. **Zero Dependencies** — No SPM packages. Everything via Apple frameworks.

## Development Workflow

1. Read relevant Skills/ files before implementing a feature
2. Consult References/ for technical patterns and code examples
3. Follow Rules/ for conventions and constraints
4. Use `feat/`, `fix/`, `refactor/` branch naming
5. Commit with conventional commit format

## Quick Start (Future)

```bash
# Clone and open in Xcode
open YtbMusicBar.xcodeproj

# Build and run
⌘R in Xcode

# The app appears in the menu bar (no Dock icon)
```

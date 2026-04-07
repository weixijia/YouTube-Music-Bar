# SwiftUI Liquid Glass Skill

> Source: [skills.sh/dimillian/skills](https://skills.sh/dimillian/skills/swiftui-liquid-glass)
> Applies to: iOS 26+ / macOS 26+ (Tahoe)

## Overview

Liquid Glass is Apple's design language introduced at WWDC 2025 — translucent material with real-time refraction, specular highlights, and dynamic depth. It is the biggest visual evolution since iOS 7.

## Core Guidelines

- Prefer native Liquid Glass APIs over custom blurs
- Use `GlassEffectContainer` when multiple glass elements coexist
- Apply `.glassEffect(...)` **after** layout and visual modifiers
- Use `.interactive()` for touch/pointer responsive elements
- Maintain shape consistency across related elements
- Gate with `#available(iOS 26, macOS 26, *)` and provide non-glass fallbacks

## Glass Variants

| Variant | Use Case |
|---------|----------|
| `.regular` | Standard glass surfaces (toolbars, cards) |
| `.clear` | High transparency for media contexts (album art overlay) |
| `.identity` | No glass effect (opt-out within container) |

## Implementation Patterns

### Basic Glass Surface
```swift
Text("Now Playing")
    .padding()
    .glassEffect(.regular, in: .rect(cornerRadius: 12))
```

### Glass Buttons
```swift
Button("Play") { togglePlayback() }
    .buttonStyle(.glass)          // standard
    .buttonStyle(.glassProminent) // emphasized
```

### Multiple Glass Elements
```swift
GlassEffectContainer {
    HStack {
        playbackControls
            .glassEffect(.regular.interactive(), in: .capsule)
        volumeSlider
            .glassEffect(.regular, in: .rect(cornerRadius: 8))
    }
}
```

### Morphing Transitions
```swift
@Namespace var ns

// Use glassEffectID for smooth morphing between states
view.glassEffect(.regular, in: .capsule)
    .glassEffectID("player", in: ns)
```

## Critical Rules

- **Glass cannot sample other glass** — avoid nesting glass effects
- Apply glass to **controls and surfaces**, NOT to content (album art, text blocks)
- `.interactive()` only on tappable/focusable elements
- Toolbar, menu, sidebar elements auto-adopt glass when recompiled with Xcode 26
- Always provide `.ultraThinMaterial` fallback for pre-macOS 26

## Review Checklist

- [ ] `#available(macOS 26, *)` with fallback UI present
- [ ] Multiple glass views wrapped in `GlassEffectContainer`
- [ ] `glassEffect` applied after layout/appearance modifiers
- [ ] `.interactive()` only where user interaction exists
- [ ] `glassEffectID` with `@Namespace` for morphing transitions
- [ ] Shapes, tinting, spacing aligned across feature

## For This Project

Apply Liquid Glass to:
- Playback control bar (play/pause, skip, like buttons)
- Mini player popover background
- Volume slider container

Do NOT apply to:
- Album art display
- Track title / artist text
- WebView content area

## Related Skills
- [swiftui-expert.md](swiftui-expert.md) — SwiftUI patterns
- [ios-hig-design.md](ios-hig-design.md) — Design guidelines

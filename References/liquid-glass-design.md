# Liquid Glass Design Reference

## What is Liquid Glass?

Introduced at WWDC 2025, Liquid Glass is Apple's new design language for macOS Tahoe (26), iOS 26, and beyond. It provides translucent material effects with:

- **Real-time refraction** — content behind glass bends and distorts
- **Specular highlights** — simulated light reflection on glass surface
- **Dynamic depth** — elements feel physically layered in 3D space
- **Adaptive tinting** — glass picks up ambient color from surrounding content

## Design Philosophy for This App

### Where to Apply Glass

| Element | Glass Type | Why |
|---------|-----------|-----|
| Playback control bar | `.regular.interactive()` | Primary interaction surface |
| Volume slider container | `.regular` | Secondary control |
| Like/dislike buttons | `.buttonStyle(.glass)` | Tappable actions |
| Mini player background | `.clear` | Let album art show through |

### Where NOT to Apply Glass

| Element | Why |
|---------|-----|
| Album art | Content should be crisp and unobstructed |
| Track title / artist text | Readability is paramount |
| WebView content | Already has its own styling |
| Progress bar | Too thin for glass to be effective |

## Visual Composition

```
┌─────────────────────────────┐
│                             │  ← Popover: .ultraThinMaterial (pre-26)
│  ┌───────────────────────┐  │     or subtle glass container (26+)
│  │     Album Art         │  │  ← NO glass — crisp image
│  │     (120x120)         │  │
│  └───────────────────────┘  │
│                             │
│  Track Title (bold)         │  ← NO glass — clear text
│  Artist Name (secondary)    │
│                             │
│  ════════════════════════   │  ← Progress bar: thin, subtle
│                             │
│  ┌─────────────────────┐   │
│  │ ⏮   ▶️   ⏭   ♡    │   │  ← Glass control bar (.regular.interactive())
│  └─────────────────────┘   │
│                             │
│  🔊 ══════════════════     │  ← Volume in glass container
│                             │
└─────────────────────────────┘
```

## Fallback Strategy

```swift
@ViewBuilder
var controlBar: some View {
    if #available(macOS 26, *) {
        GlassEffectContainer {
            HStack {
                playbackButtons
                    .glassEffect(.regular.interactive(), in: .capsule)
            }
        }
    } else {
        HStack {
            playbackButtons
        }
        .background(.ultraThinMaterial, in: .capsule)
    }
}
```

## Color Considerations

- Glass tinting: use `.tint(Color.accentColor.opacity(0.1))` for subtle brand color
- Text on glass: ensure sufficient contrast (use `.primary` and `.secondary` label colors)
- Album art colors can influence glass tint via adaptive coloring

## Animation with Glass

- Use `withAnimation(.smooth)` for glass state transitions
- `glassEffectID` with `@Namespace` for morphing between mini/expanded player
- Glass transitions should feel physical — avoid abrupt opacity changes

## Related
- [menu-bar-app-architecture.md](menu-bar-app-architecture.md) — Layout specs
- [../Skills/liquid-glass.md](../Skills/liquid-glass.md) — Implementation rules
- [../Skills/ios-hig-design.md](../Skills/ios-hig-design.md) — Design guidelines

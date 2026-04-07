# Design Inspirations

## Reference Apps

### Sleeve (Desktop Widget Music Player)
- **What**: Floating desktop widget showing album art + track info
- **Why relevant**: Beautiful album art presentation, highly customizable appearance
- **Key takeaway**: Album art as the visual anchor; minimal chrome around content
- **URL**: https://replay.software/sleeve

### Tuneful (Menu Bar + Notch Player)
- **What**: Music controller in menu bar, notch, or mini player
- **Key takeaway**: Multiple display modes (menu bar icon, notch integration, floating mini player)
- **Design pattern**: Compact layout with album art left, info + controls right

### Spotica Menu (Spotify Menu Bar)
- **What**: Spotify menu bar controller with album cover in status bar
- **Key takeaway**: Shows album art directly in the menu bar (tiny square next to icon)
- **Design pattern**: Global hotkeys for all controls without opening popover

### Status Bar Music Player
- **What**: Multiple clickable buttons in the status bar itself
- **Key takeaway**: Play/pause, skip directly from status bar without popover
- **Tradeoff**: Takes more menu bar space but zero-click interaction

### NepTunes
- **What**: macOS menu bar music scrobbler + controller
- **Key takeaway**: Last.fm integration, notification-based track display

## Design Patterns to Adopt

### 1. Album Art as Hero
All successful music menu bar apps center the album art prominently. It provides:
- Instant visual recognition of current track
- Color palette for adaptive theming
- Emotional connection to the music

### 2. Compact Information Hierarchy
```
[Album Art] [Title     ]
            [Artist    ]
            [Album     ] ← optional, often omitted for space
```

### 3. Essential Controls Only
In a menu bar popover, show only:
- Play/Pause (most used)
- Previous / Next
- Like (heart)
- Volume (optional, can use system volume)

Advanced controls (shuffle, repeat, queue) go in a secondary view or the full web player.

### 4. Status Bar Icon States
| State | Icon |
|-------|------|
| Idle / Not playing | `music.note` (outline) |
| Playing | `music.note` (filled) or animated equalizer bars |
| Loading | `music.note` with progress indicator |

### 5. Keyboard Shortcuts
| Shortcut | Action |
|----------|--------|
| Media keys | Play/Pause, Next, Previous (via MPRemoteCommandCenter) |
| ⌘⌥P | Toggle play/pause (global hotkey) |
| ⌘⌥→ | Next track |
| ⌘⌥← | Previous track |
| ⌘⌥↑ | Volume up |
| ⌘⌥↓ | Volume down |

## Anti-Patterns to Avoid

- **Too much information** — Don't show lyrics, queue, recommendations in the popover
- **Web-like UI** — Don't replicate YouTube Music's web interface; extract the essence
- **No feedback** — Always show current state (playing/paused) clearly
- **Slow popover** — WebView must be pre-loaded; popover should feel instant
- **Large footprint** — Keep under 80MB memory; no background CPU when paused

## Related
- [menu-bar-app-architecture.md](menu-bar-app-architecture.md) — Technical specs
- [liquid-glass-design.md](liquid-glass-design.md) — Visual effects
- [../Skills/refactoring-ui.md](../Skills/refactoring-ui.md) — UI design principles
- [../Rules/ux-rules.md](../Rules/ux-rules.md) — UX constraints

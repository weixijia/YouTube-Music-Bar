# UX Rules

## Core Principle

**The app should feel like a native macOS utility, not a web wrapper.** Users should forget they're using YouTube Music's web player underneath.

## Menu Bar Interaction

### Popover Behavior
- **Click** menu bar icon → toggle popover open/close
- **Click outside** popover → dismiss
- **Right-click** menu bar icon → context menu (Quit, Settings, About)
- Popover appears **instantly** — WebView must be pre-loaded in background

### Status Bar Icon
- Use SF Symbol `music.note` as template image (auto-tints for dark/light mode)
- Optional: show animated equalizer bars when playing
- Optional: show track title scrolling in menu bar (user preference, off by default)
- Icon must be 16x16pt template image

### Popover Sizing
- Width: ~320pt (fixed)
- Height: ~400-480pt (adaptive based on content)
- No resize handle — fixed size popover
- Position: anchored below menu bar icon (system default)

## Playback Controls

### Essential Controls (Always Visible)
| Control | Action | Shortcut |
|---------|--------|----------|
| ◀◀ | Previous track | Media key / ⌘⌥← |
| ▶ / ⏸ | Play / Pause | Media key / ⌘⌥P |
| ▶▶ | Next track | Media key / ⌘⌥→ |
| ♡ | Like / Unlike | — |

### Secondary Controls (Accessible but not prominent)
- Volume slider (or rely on system volume)
- Open in browser (launch YouTube Music in Safari)
- Shuffle / Repeat toggle
- Settings

### Progress Bar
- Thin, horizontal bar showing track progress
- Clickable to seek (optional for MVP)
- Show elapsed time and total duration
- Update smoothly (not in discrete jumps)

## Information Display

### Track Info Priority
1. **Album art** — 120x120pt, rounded corners, prominent
2. **Track title** — primary text, bold, single line with truncation
3. **Artist name** — secondary text, lighter, single line with truncation
4. **Album name** — tertiary, optional (can omit for space)

### Truncation
- Use `lineLimit(1)` with `.truncationMode(.tail)` for all text
- Tooltip on hover shows full text (optional)

## Responsiveness

### Instant Feel
- Popover open: < 100ms (WebView pre-loaded)
- Play/pause response: < 200ms perceived
- Track info update: < 500ms after track change
- Album art load: async with fade-in animation

### Loading States
- First launch: show skeleton/placeholder while WebView loads
- Track change: keep previous album art until new one loads (crossfade)
- Network loss: show last known state with "Offline" indicator

## Keyboard & System Integration

### Media Keys
Handled via `MPRemoteCommandCenter` — works with:
- Physical media keys on keyboard
- AirPods play/pause
- Touch Bar (if applicable)
- Control Center Now Playing widget

### Global Hotkeys
Register via `NSEvent.addGlobalMonitorForEvents` or Carbon API:
- ⌘⌥P — Play/Pause
- ⌘⌥→ — Next
- ⌘⌥← — Previous
- ⌘⌥↑ — Volume up
- ⌘⌥↓ — Volume down

### Notifications
- **Don't** show notifications for every track change (annoying)
- Only show notification when popover is closed AND track changes (user preference, off by default)

## Login Flow

1. First launch → popover shows "Sign in to YouTube Music" prompt
2. User clicks sign in → WebView becomes visible for Google OAuth
3. After successful login → WebView hides, native UI takes over
4. Cookies persist across app launches
5. Provide "Sign Out" option in Settings

## Settings (Preferences)

Minimal settings for MVP:
- [ ] Launch at login (SMAppService)
- [ ] Show track title in menu bar
- [ ] Show notifications on track change
- [ ] Global hotkey customization (later)

## Anti-Patterns

- **Don't** show the full YouTube Music web UI in the popover
- **Don't** add a search bar (use YouTube Music in browser for discovery)
- **Don't** show queue/playlist management (too complex for menu bar)
- **Don't** auto-play on launch (respect user intent)
- **Don't** block menu bar click while loading
- **Don't** use aggressive CPU when paused (< 1% CPU idle)

## Accessibility

See [../Skills/ios-hig-design.md](../Skills/ios-hig-design.md) for full guidelines.

Key for this app:
- All controls have `.accessibilityLabel`
- Play/Pause button announces current state
- Track info readable by VoiceOver
- Keyboard navigation works within popover
- Volume slider accessible via keyboard

## Related
- [project-conventions.md](project-conventions.md) — Code conventions
- [architecture-rules.md](architecture-rules.md) — Technical architecture
- [../References/design-inspirations.md](../References/design-inspirations.md) — Design references
- [../References/liquid-glass-design.md](../References/liquid-glass-design.md) — Visual design

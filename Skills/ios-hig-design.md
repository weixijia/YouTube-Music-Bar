# Apple Human Interface Guidelines Design Skill

> Source: [skills.sh/wondelai/skills](https://skills.sh/wondelai/skills/ios-hig-design)
> Foundation: Apple's official Human Interface Guidelines

## Core Philosophy

Three pillars: **Clarity** (legible, purposeful elements), **Deference** (interface serves content), **Depth** (layering and motion convey hierarchy).

## Eight Design Areas

### 1. Layout & Safe Areas
- Standard content margins: 16-20pt from edges
- Minimum touch target: 44 x 44pt
- Standard spacing: 8 / 16 / 24pt increments
- Menu bar popover: ~320pt wide x ~400pt tall (for this project)

### 2. Typography & Dynamic Type
- San Francisco (SF Pro) typeface with semantic text styles
- Large Title: 34pt Bold | Title: 17pt Medium | Body: 17pt Regular
- Caption: 12-13pt minimum
- Line height minimum: 1.3x font size
- Minimum contrast ratio: 4.5:1 (WCAG AA)
- **Never** disable Dynamic Type or set fixed font sizes

### 3. Color & Dark Mode
- Use semantic system colors: `Color(.label)`, `Color(.secondaryLabel)`, `Color(.systemBackground)`
- Dark Mode is **mandatory** — always test both appearances
- `Color(.systemBlue)` for default tint/accent
- `Color(.systemRed)` for destructive actions
- Maintain 4.5:1 contrast ratio in both appearances

### 4. Navigation
- Use native navigation patterns (NavigationStack, tab bars)
- **Never use hamburger menus** on iOS
- Modals for focused tasks; dismiss via swipe-down or explicit close
- For menu bar app: popover is the primary navigation surface

### 5. Controls & Inputs
- Primary buttons: filled with theme color
- Secondary buttons: outlined or text-only
- Destructive actions: red with confirmation
- Match keyboard type to input context

### 6. Accessibility (Mandatory)
- Every interactive element needs `.accessibilityLabel`
- Use `.accessibilityValue` for current state
- Group related elements with `.accessibilityElement(children: .combine)`
- Support Dynamic Type at all sizes
- Minimum touch target: 44 x 44pt
- **Never** convey meaning through color alone
- **Test with VoiceOver** — as critical as visual testing

### 7. Icons & Images
- Use SF Symbols (`Image(systemName:)`) for all standard icons
- `.symbolRenderingMode(.hierarchical)` for multi-color depth
- App icon: 1024x1024px, iOS applies squircle mask
- Keep icon designs simple with recognizable silhouettes

### 8. Gestures & Haptics
- Never override standard gestures (swipe-back, swipe-dismiss, pull-to-refresh)
- Haptic types: Impact (physical), Notification (outcomes), Selection (state changes)
- Call `.prepare()` before triggering haptics

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Touch targets under 44pt | Ensure all interactive elements >= 44x44pt |
| Ignoring safe areas | Always respect safe area insets |
| Skipping Dark Mode | Use semantic colors; test both appearances |
| Hardcoding font sizes | Use semantic text styles |
| Low contrast text | Maintain 4.5:1 minimum |

## Related Skills
- [refactoring-ui.md](refactoring-ui.md) — Visual design system
- [liquid-glass.md](liquid-glass.md) — Liquid Glass design
- [swiftui-expert.md](swiftui-expert.md) — SwiftUI implementation

# Refactoring UI Design System Skill

> Source: [skills.sh/wondelai/skills](https://skills.sh/wondelai/skills/refactoring-ui)
> Based on: Adam Wathan & Steve Schoger's _Refactoring UI_

## Core Principle

**"Design in grayscale first. Add color last."** Enforce hierarchy via spacing, contrast, and typography — not color.

## Seven Principles

### 1. Visual Hierarchy
- Primary elements: ONE emphasis lever (large OR bold OR dark)
- Reserve all three for the single most important element
- De-emphasize labels by reducing size, lightness, or using uppercase

### 2. Spacing & Sizing
- Constrained scale: **4, 8, 16, 24, 32, 48, 64px**
- Spacing defines relationships — tighter = more related
- Start with excessive white space, then subtract
- Text blocks: 45-75 characters max width

### 3. Typography
- Modular scale: 12, 14, 16, 20, 24, 30, 36px (1.25 ratio)
- Headings: tight line-height (1.0-1.25)
- Body text: relaxed line-height (1.5-1.75)
- Limit to two font families max
- Font weights below 400 are unreadable; use 600-700 for emphasis

### 4. Color
- 5-9 shades per color (50-900 range)
- Avoid pure black; use #111827-level darks
- Add saturation to grays (cool: blue-tinted; warm: yellow-tinted)
- Contrast: 4.5:1 body text, 3:1 large text (18px+)

### 5. Depth & Shadows
- Small shadows: raised elements (buttons, cards)
- Large shadows: floating elements (modals, dropdowns, popovers)
- Two-part shadows: tight+dark plus larger+softer
- Don't overuse — excessive shadows flatten hierarchy

### 6. Images & Icons
- Size icons contextually — no universal sizing
- Consistent stroke widths within sets
- Use SF Symbols for this project (see [ios-hig-design.md](ios-hig-design.md))

### 7. Layout & Composition
- Default to left-alignment
- Center only: short headlines, heroes, single CTAs, empty states
- Cards can bleed images to edges, overlap containers

## Quick Diagnostic

- [ ] Does hierarchy survive the blur test?
- [ ] Does grayscale rendering work without color?
- [ ] Sufficient white space?
- [ ] Labels de-emphasized vs values?
- [ ] Spacing follows 4/8/16/24/32/48/64 scale?
- [ ] Text width constrained (~65ch max)?
- [ ] Color contrast meets WCAG?

## For This Project

Menu bar popover design priorities:
- **Album art** is the hero — largest, most prominent
- **Track title** is primary text — bold, full opacity
- **Artist name** is secondary — lighter weight, reduced opacity
- **Controls** use spacing to group (play/skip tight, volume separate)
- **Progress bar** is subtle — thin, low-contrast background

## Related Skills
- [ios-hig-design.md](ios-hig-design.md) — Apple HIG
- [liquid-glass.md](liquid-glass.md) — Glass effects for depth

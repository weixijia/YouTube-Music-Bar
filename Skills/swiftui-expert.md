# SwiftUI Expert Skill

> Source: [skills.sh/avdlee/swiftui-agent-skill](https://skills.sh/avdlee/swiftui-agent-skill/swiftui-expert-skill)
> Applies to: iOS 15+ / macOS 12+ through iOS 26 / macOS 26

## Operating Rules

1. Prefer native SwiftUI over UIKit/AppKit bridging unless necessary
2. Focus on correctness and performance; don't enforce specific architectures
3. Follow Apple's Human Interface Guidelines and API design patterns
4. Only adopt Liquid Glass when explicitly requested (see [liquid-glass.md](liquid-glass.md))
5. Present performance optimizations as suggestions, not requirements
6. Use `#available` gating with sensible fallbacks for version-specific APIs
7. Consult latest API references to avoid deprecated APIs

## Correctness Checklist (Hard Rules)

- `@State` properties are `private`
- `@Binding` only where a child modifies parent state
- Passed values never declared as `@State` or `@StateObject`
- `@StateObject` for view-owned objects; `@ObservedObject` for injected
- iOS 17+ / macOS 14+: `@State` with `@Observable`; `@Bindable` for injected observables needing bindings
- `ForEach` uses stable identity (never `.indices` for dynamic content)
- Constant number of views per `ForEach` element
- `.animation(_:value:)` always includes the `value` parameter
- `@FocusState` properties are `private`
- iOS 26+ / macOS 26+ APIs gated with `#available` and fallback provided
- `import Charts` present in files using chart types

## Task Workflows

### Review Existing SwiftUI Code
- Identify applicable topics and flag deprecated APIs
- Validate `#available` gating and fallback paths for iOS 26+ features

### Improve Existing SwiftUI Code
- Replace deprecated APIs with modern equivalents
- Refactor hot paths to reduce unnecessary state updates
- Extract complex view bodies into separate subviews

### Implement New SwiftUI Feature
- Design data flow first: identify owned vs injected state
- Structure views for optimal diffing (extract subviews early)
- Apply correct animation patterns (implicit vs explicit, transitions)
- Use `Button` for all tappable elements; add accessibility grouping and labels
- Gate version-specific APIs with `#available` and provide fallbacks

## macOS-Specific Patterns

- Use `MenuBarExtra` for menu bar scene (macOS 13+)
- `Settings` scene for preferences window
- `Window` and `WindowGroup` for standalone windows
- `.windowStyle(.hiddenTitleBar)` for frameless windows
- `NSViewRepresentable` for wrapping AppKit views (e.g., WKWebView)
- `.onCommand()` for menu item keyboard shortcuts

## Related Skills
- [liquid-glass.md](liquid-glass.md) — Liquid Glass API
- [swift-concurrency.md](swift-concurrency.md) — Concurrency safety
- [ios-hig-design.md](ios-hig-design.md) — Design guidelines

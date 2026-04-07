# Swift Concurrency Expert Skill

> Source: [skills.sh/dimillian/skills](https://skills.sh/dimillian/skills/swift-concurrency-expert)
> Applies to: Swift 6.2+

## Overview

Review and fix Swift Concurrency issues by applying actor isolation, Sendable safety, and modern concurrency patterns with minimal behavior changes.

## Three-Step Workflow

### 1. Triage the Issue
- Capture exact compiler diagnostics and offending symbols
- Check project settings: Swift version (6.2+), strict concurrency level
- Identify current actor context (`@MainActor`, `actor`, `nonisolated`)
- Confirm whether code is UI-bound or off-main-actor work

### 2. Apply the Smallest Safe Fix

| Scenario | Fix |
|----------|-----|
| UI-bound types | Annotate with `@MainActor` |
| Protocol conformance on main actor types | `extension Foo: @MainActor SomeProtocol` |
| Global/static state | Protect with `@MainActor` or move into actor |
| Background work | `@concurrent` async function on `nonisolated` type |
| Sendable errors | Prefer immutable/value types; add `Sendable` only when correct |

### 3. Verify the Fix
- Rebuild and confirm all diagnostics resolved
- Run test suite for regressions
- Iteratively resolve any new warnings

## Key Rules

- **Prefer `@MainActor` for all UI code** — ViewModels, UI state, delegates
- **Never use `@unchecked Sendable`** unless absolutely unavoidable
- Use `actor` for shared mutable state accessed from multiple contexts
- Use `nonisolated` explicitly when breaking out of an actor's isolation
- `Task { @MainActor in }` for dispatching to main actor from background
- `Task.detached` only when you need a truly independent task context

## For This Project

Critical concurrency boundaries:
- **WKWebView JS Bridge** → `@MainActor` (WebKit is main-thread only)
- **MPNowPlayingInfoCenter** → `@MainActor` (UIKit/AppKit API)
- **Network image loading** → `nonisolated` async, dispatch result to `@MainActor`
- **Playback state model** → `@Observable @MainActor` class

## Related Skills
- [swiftui-expert.md](swiftui-expert.md) — SwiftUI patterns

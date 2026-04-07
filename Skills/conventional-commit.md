# Conventional Commit Skill

> Source: [skills.sh/marcelorodrigo/agent-skills](https://skills.sh/marcelorodrigo/agent-skills/conventional-commit)

## Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

Header required; scope optional. All lines under 100 characters.

## Commit Types

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code refactoring (no behavior change) |
| `perf` | Performance improvement |
| `style` | Code style and formatting |
| `docs` | Documentation changes |
| `test` | Tests added, updated or improved |
| `build` | Build system or CI changes |
| `ci` | Continuous integration configuration |
| `deps` | Dependency updates |
| `chore` | Routine maintenance tasks |
| `revert` | Revert a previous commit |

## Rules

- Use imperative, present tense ("Add feature" not "Added feature")
- Capitalize first letter
- No period at the end
- Maximum 70 characters for subject line
- Body: explain **what and why**, not how

## Branch Naming

```
git checkout -b <type>/<short-description>
```

Examples:
- `feat/menu-bar-popover`
- `fix/webview-auth-cookie`
- `refactor/extract-js-bridge`

## Breaking Changes

Use `BREAKING CHANGE:` footer or append `!` after type/scope.

## Principles

- Each commit: single, stable change
- Commits independently reviewable
- Repository in working state after each commit

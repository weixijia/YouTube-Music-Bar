# Ytb Music Bar

Native YouTube Music for your macOS menu bar.

<!-- Screenshot slot: add a real screenshot before release, for example:
<img src="docs/screenshot.png" alt="Ytb Music Bar screenshot">
-->

Ytb Music Bar is a native macOS menu bar app for YouTube Music, built with Swift, SwiftUI, and a hidden `WKWebView` audio engine. It keeps playback in the background, puts controls in a compact floating panel, and can show the current lyric line directly in the menu bar when synced lyrics are available.

## Features

- 🎵 **Native menu bar experience**. Runs as an `LSUIElement` utility with a floating panel instead of a full browser window.
- 🎧 **Hidden YouTube Music playback engine**. Audio playback runs inside a persistent hidden `WKWebView`, while the user interacts with native macOS UI.
- 🏠 **Core browsing views**. Home, Search, Collection, and Now Playing are already implemented in the panel UI.
- 📚 **Collection support**. Browse library playlists, open playlist details, and load liked songs with continuation pagination.
- 📃 **Queue view**. See the current track and Up Next items fetched from YouTube Music.
- 🎛️ **Playback controls and likes**. Play, pause, next, previous, seek, volume, shuffle, repeat, and like actions are wired through the native interface.
- 🎹 **macOS media integration**. Media keys and Now Playing / Control Center integration are handled through `MPRemoteCommandCenter` and `MPNowPlayingInfoCenter`.
- 📝 **Lyrics support**. The app resolves synced lyrics from YouTube Music first, falls back to LRCLib when needed, and falls back to plain lyrics when synced timing is unavailable.
- 💬 **Status bar lyric display**. When synced lyrics are available, the menu bar text can switch from `track title, artist` to the current lyric line.
- 🔐 **Google sign-in flow**. Login is handled in-app with cookie persistence for YouTube Music sessions.
- ⚙️ **Practical settings**. Includes Launch at Login, track change notifications, account sign-out, and image cache clearing.

## Requirements

- macOS 14.0 or later
- A Google account that can sign in to YouTube Music

## Download

Download the latest `.dmg` from the GitHub Releases page once releases are published for this repository.

If you're building locally, see [RELEASE.md](RELEASE.md) for the universal macOS build and DMG packaging workflow.

> **Unsigned build note**
> This project is currently set up for local or direct distribution builds, not App Store distribution.
> If you ship an unsigned app, macOS may attach quarantine attributes to the downloaded app.
> You can clear them after copying the app to `/Applications` with:
>
> ```bash
> xattr -cr "/Applications/Ytb Music Bar.app"
> ```

## Build from source

Open `YtbMusicBar.xcodeproj` in Xcode 16 or later and run the `YtbMusicBar` scheme on macOS.

For command line release builds, universal archives, and DMG packaging, use the commands in [RELEASE.md](RELEASE.md).

## Project status

This repository already contains the native app shell, login flow, hidden WebView playback engine, direct YouTube Music API access for app data, queue and collection views, now playing integration, synced and plain lyrics, and custom menu bar lyric rendering.

It does **not** currently document App Store distribution, Homebrew distribution, auto-updates, or code signing / notarization automation in this repo.

## Disclaimer

Ytb Music Bar is an unofficial application and is not affiliated with YouTube or Google. "YouTube" and "YouTube Music" are trademarks of Google.

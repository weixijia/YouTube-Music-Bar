# 🎵 YouTube Music Bar

> YouTube Music, tucked into your Mac menu bar.

🌐 [🇬🇧 English](README.md) | [🇨🇳 中文](docs/README_CN.md) | [🇯🇵 日本語](docs/README_JP.md) | [🇰🇷 한국어](docs/README_KR.md) | [🇫🇷 Français](docs/README_FR.md) | [🇩🇪 Deutsch](docs/README_DE.md) | [🇮🇹 Italiano](docs/README_IT.md) | [🇪🇸 Español](docs/README_ES.md)

<p align="center">
  <img src="docs/screenshot.png?v=2" alt="YouTube Music Bar Screenshot" width="680">
</p>

<p align="center">
  <em>Home feed & Now Playing — all from a tiny floating panel</em>
</p>

---

YouTube Music Bar is a small, native macOS app for people who want their music close by — without giving up a full browser tab or a Dock slot. It lives in the menu bar, pops open a compact panel, and gets out of your way.

Click, pick something, keep working. ✨

## ✨ Features

- 🎵 **Menu Bar Native** — Lives in the macOS menu bar, no Dock icon, no browser tab needed
- 🔍 **Quick Search** — Find songs, albums, and playlists with debounced search and filter chips
- 🏠 **Home Feed** — Personalized recommendations, mixes, and "Listen again" section right from YouTube Music
- 📚 **Library & Liked Music** — Browse your saved playlists and liked songs with pagination support
- 🎛️ **Full Playback Controls** — Play, pause, skip, seek, shuffle, repeat, and like — all from native macOS UI
- 📃 **Queue / Up Next** — See what's playing now and what's coming up next
- 🎤 **Synced Lyrics** — Line-by-line lyrics overlay on album art, tap any line to seek, with LRCLib fallback
- 💬 **Lyrics in Menu Bar** — Current lyric line scrolls right in the status bar while you work
- 🎧 **Media Key Support** — Play/pause, next, previous, and seek via keyboard media keys and Control Center
- 📡 **AirPlay** — Route audio to AirPlay devices from the built-in picker
- 🔔 **Track Notifications** — Get notified when the track changes (optional)
- 🔊 **Background Playback** — Music keeps playing even when the panel is closed
- 🚀 **Launch at Login** — Start automatically when you log in
- 🎨 **Liquid Glass Design** — macOS Tahoe Liquid Glass styling with vibrancy fallback on older systems
- 🔐 **Secure Auth** — Google sign-in via WebView, cookies stored in macOS Keychain

## 📋 Requirements

- macOS 14 (Sonoma) or later
- A [Google](https://accounts.google.com) account with access to YouTube Music

## 📦 Installation

### Download

Download the latest `.dmg` from the [**Releases**](https://github.com/user/YouTube-Music-Bar/releases) page.

> **Note:** This is currently an unsigned app.
> If macOS blocks it after moving to `/Applications`, run:
> ```bash
> xattr -cr "/Applications/YouTube Music Bar.app"
> ```

### Build from Source

```bash
# 1. Clone the repo
git clone https://github.com/user/YouTube-Music-Bar.git
cd YouTube-Music-Bar

# 2. Generate the Xcode project (requires XcodeGen)
xcodegen

# 3. Open and run
open YouTubeMusicBar.xcodeproj
# Select the YouTubeMusicBar scheme → Run (⌘R)
```

For full release build and DMG packaging instructions, see [RELEASE.md](RELEASE.md).

## 🏗️ Architecture

```
YouTubeMusicBar/
├── App/            — App entry, AppDelegate, FloatingPanel, StatusBarLyricView
├── Models/         — Track, PlaybackState, Playlist, SearchResult
├── Services/       — PlayerService, AuthService, WebKitManager, API client
│   └── API/        — YTMusicClient, APICache, Parsers
├── Views/          — Home, Search, Collection, NowPlaying, Lyrics, Queue, Settings
├── Utilities/      — Constants
└── Resources/      — controls.js, observer.js, assets, Info.plist
```

**How it works:**
1. 🔒 Sign in via Google OAuth in a WKWebView → cookies saved to Keychain
2. 🎶 A hidden 1×1 WKWebView loads YouTube Music and acts as the audio engine
3. 📡 Injected JavaScript observes playback state and sends updates to Swift
4. 🎯 Native SwiftUI UI controls playback via JS function calls
5. 🌐 YouTube Music internal API (`youtubei/v1`) fetches search, browse, lyrics, and queue data

## 🤝 Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

## ⚠️ Disclaimer

YouTube Music Bar is an **unofficial** app and is **not affiliated** with YouTube or Google.
"YouTube", "YouTube Music", and the "YouTube Logo" are registered trademarks of Google Inc.

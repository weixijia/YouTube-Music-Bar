# YouTube Music Bar

YouTube Music in your macOS menu bar.

<!-- Add a real screenshot before the next public release.
<img src="docs/screenshot.png" alt="YouTube Music Bar screenshot">
-->

YouTube Music Bar is a lightweight Mac app that keeps YouTube Music one click away. It lives in the menu bar, stays out of the Dock, and gives you playback, search, queue, library, and lyrics without leaving the desktop.

## Why it exists

- Fast access from the menu bar
- Native playback controls
- Search, queue, and library in one compact panel
- Current lyric line right in the menu bar

## What it can do

- Play, pause, skip, seek, shuffle, repeat, and like tracks
- Browse Home, Search, Collection, and Now Playing
- Show synced lyrics when available, with a plain-lyrics fallback
- Display the current lyric line in the menu bar
- Support media keys and Now Playing / Control Center
- Keep music running in the background
- Handle sign-in, sign-out, notifications, and launch at login

## Requirements

- macOS 14 or later
- A Google account with access to YouTube Music

## Download

Grab the latest `.dmg` from the [Releases](https://github.com/weixijia/Ytb_Music_Bar/releases) page.

If macOS quarantines the app after download, run:

```bash
xattr -cr "/Applications/Ytb Music Bar.app"
```

## Build from source

Open `YtbMusicBar.xcodeproj` in Xcode and run the `YtbMusicBar` scheme.

If you want a universal build or a DMG, use the steps in [RELEASE.md](RELEASE.md).

## Notes

- This is an unofficial app.
- It is not affiliated with YouTube or Google.
- The current release flow is direct distribution, not App Store distribution.

## Disclaimer

YouTube and YouTube Music are trademarks of Google.

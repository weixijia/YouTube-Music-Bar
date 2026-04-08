# YouTube Music Bar

YouTube Music, tucked into your Mac menu bar.

YouTube Music Bar is a small macOS app for people who want their music close by, but not taking over the whole desktop. It lives in the menu bar, stays out of the Dock, and gives you a quick little player for browsing, searching, queuing, and reading lyrics.

It is meant to feel easy. Click, pick something, keep working.

## What it is

YouTube Music Bar keeps the essentials one click away:

- Home, Search, Collection, and Now Playing in a compact panel
- Playback controls for play, pause, skip, seek, shuffle, repeat, and like
- Queue access without opening a full desktop app
- Lyrics support, including synced lyrics when available
- The current lyric line right in the menu bar
- Media key support and Now Playing / Control Center integration
- Background playback, track change notifications, and launch at login

## Why you might want it

- You use YouTube Music every day and want faster access
- You like menu bar apps that stay light and out of the way
- You want lyrics and playback controls nearby while you work

## Requirements

- macOS 14 or later
- A Google account with access to YouTube Music

## Installation

### Download

Download the latest `.dmg` from the [Releases](https://github.com/weixijia/YouTube-Music-Bar/releases) page.

This project is currently distributed directly through GitHub Releases.

If macOS quarantines the app after you move it to `/Applications`, run:

```bash
xattr -cr "/Applications/YouTube Music Bar.app"
```

## Build from source

Open `YouTubeMusicBar.xcodeproj` in Xcode, then run the `YouTubeMusicBar` scheme.

If you want to build a release app or package a DMG, the current steps are in [RELEASE.md](RELEASE.md).

## Disclaimer

YouTube Music Bar is an unofficial app and is not affiliated with YouTube or Google.

YouTube and YouTube Music are trademarks of Google.

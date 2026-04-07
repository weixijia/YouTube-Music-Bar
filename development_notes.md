# Development Notes

Last updated: 2026-04-07

Repository: `github.com:weixijia/Ytb_Music_Bar.git`

Current branch: `main`

Latest pushed commit at time of writing: `ef1c1c7 fix: fallback to lrclib for synced lyrics`

## Purpose

This document records the working state of the YouTube Music menu bar app, the important design decisions made so far, issues discovered during development, how they were fixed, what was copied or adapted from the local `kaset` reference app, and the remaining risks/work.

Use this file as the first handoff note for future work. The older planning/reference docs are still useful, but this file reflects the actual implementation state after the fixes made in this repo.

## Project Goal

Build a native macOS menu bar app for YouTube Music.

Core user experience:

- The app lives in the macOS system menu bar at the top of the screen.
- The Dock icon is hidden via accessory-style app behavior.
- A click on the menu bar item opens a native floating panel.
- YouTube Music playback runs in a hidden persistent `WKWebView`.
- The user interacts with native SwiftUI/AppKit UI rather than the YouTube Music web UI.
- The menu bar status item can show the currently playing track, and when synced lyrics are available it should show the current lyric sentence instead.

## Current High-Level Architecture

The app is a Swift/SwiftUI + AppKit macOS project with no external Swift package dependencies.

Key pieces:

- `YtbMusicBar/App/AppDelegate.swift`
  Owns the app lifecycle, `NSStatusItem`, floating panel setup, login detection callback, sleep handling, and menu bar status text rendering.

- `YtbMusicBar/App/FloatingPanel.swift`
  AppKit floating panel container for the SwiftUI app UI.

- `YtbMusicBar/App/YtbMusicBarApp.swift`
  SwiftUI app entry point, delegates lifecycle to `AppDelegate`.

- `YtbMusicBar/Services/SingletonPlayerWebView.swift`
  Persistent hidden `WKWebView` that hosts YouTube Music. It injects JavaScript, receives playback state through script message handlers, and exposes JS control helpers.

- `YtbMusicBar/Resources/observer.js`
  Injected JavaScript observer. Reads YouTube Music DOM/video state, posts state updates to Swift, posts track-ended messages, and includes high-frequency lyrics time polling.

- `YtbMusicBar/Resources/controls.js`
  Injected JavaScript controls for play/pause, next, previous, seek, volume, shuffle, repeat, and like.

- `YtbMusicBar/Services/PlayerService.swift`
  Central playback state service. Tracks current `Track`, playback state, volume, repeat/shuffle, queue state, album art, current playback time, and the current synced lyric line for menu bar display.

- `YtbMusicBar/Services/API/YTMusicClient.swift`
  Direct YouTube Music internal API client using SAPISID/SAPISIDHASH-style authenticated requests. Also now resolves lyrics through YouTube Music first and LRCLib fallback second.

- `YtbMusicBar/Services/API/Parsers.swift`
  Parsers for search, browse, library, playlist, lyrics, LRC synced lyrics, and up-next responses.

- `YtbMusicBar/Services/WebKitManager.swift`
  Cookie backup/restore and auth-cookie extraction for YouTube/Google cookies.

- `YtbMusicBar/Views/*`
  Native SwiftUI panels for home, library, search, queue, now playing, player controls, settings, rows/cards, image loading, and lyrics overlay.

- `YtbMusicBarTests/*`
  XCTest tests for parsers, playback state, and track model behavior.

## Reference App

Local reference path:

`/Users/weixijia/Documents/Ytb_Music_Bar/kaset`

Important rule from the user: if our app does not work, compare how `kaset` does it and follow/reuse that approach as much as practical.

The `kaset` repo is intentionally ignored by this repo and must not be committed. It is a local reference only.

Important `kaset` patterns already used:

- YouTube Music API `WEB_REMIX` client context and client version.
- SAPISIDHASH authenticated request pattern.
- YouTube Music lyrics lookup from `timedLyricsModel`.
- LRCLib fallback for synced LRC lyrics when YouTube Music does not provide timed lyrics.
- High-frequency playback-time polling at roughly 10Hz while synced lyrics are active.
- Raw playback timestamp for synced lyric display, with no artificial lead offset.

## Git History Summary

Current important commits:

- `20dd14b feat: initial youtube music menu bar app`
  Initial implementation of the native app, docs, project, services, JavaScript bridge, views, and tests.

- `e3c92b2 fix: align youtube music api auth with kaset`
  Aligned YouTube Music API auth with `kaset`: `WEB_REMIX` client version, domain-matching cookies, SAPISID auth behavior, and 401/403 auth-expired handling.

- `ac3295c fix: tidy search rows and debug logging`
  Fixed wide thumbnail clipping in search rows and removed noisy app-generated debug logging.

- `a2177c9 fix: sync lyrics polling and thumbnail clipping`
  Added high-frequency lyric time polling, a WebKit `lyricsTime` message handler, parser support for the current `timedLyricsModel.lyricsData` shape, and thumbnail clipping fixes across main/home page cards and rows.

- `7b4a679 fix: show synced lyrics in menu bar`
  Added first version of menu bar lyric display, status lyric loading, reason-tracked lyric polling, and current lyric line callbacks.

- `3799e91 fix: load menu bar lyrics from current track`
  Made the macOS top menu bar lyric loader proactive from status bar rendering, not dependent only on `onTrackChanged`. Removed the status lyric display lead offset to better match actual playback time.

- `ef1c1c7 fix: fallback to lrclib for synced lyrics`
  Added `kaset`-style LRCLib synced lyric fallback, used it for both menu bar lyrics and overlay lyrics, reset the menu bar request marker on track changes, removed the overlay lead offset, and added an LRC parser test.

## What Works Now

### App Shell

- The app builds as a native macOS app.
- The app uses accessory behavior so it lives as a menu bar utility rather than a normal Dock app.
- `NSStatusItem` is created in `AppDelegate`.
- Left-click toggles the floating panel.
- Right-click opens a context menu.
- Floating panel content is SwiftUI.

### Hidden YouTube Music Engine

- `SingletonPlayerWebView` owns a persistent `WKWebView`.
- The WebView uses the default persistent data store, not an ephemeral session, so Google/YouTube cookies can persist.
- A Safari-like user agent is configured.
- Service worker blocking rules are configured for YouTube Music service worker issues.
- JavaScript files are injected at document end:
  - `controls.js`
  - `observer.js`
- YouTube Music can be loaded invisibly after login.

### Login/Auth

- Login uses a Google/YouTube Music login URL rather than a generic page.
- Cookie detection is relaxed to SAPISID-style cookies rather than overly strict full cookie sets.
- Cookie backup/restore is handled through `WebKitManager`.
- Direct API calls use current cookies matching YouTube domains.
- 401/403 API responses are treated as auth-expired errors.

### YouTube Music API

- API client uses:
  - Base URL: `https://music.youtube.com/youtubei/v1`
  - `WEB_REMIX` client name
  - `clientVersion = "1.20231204.01.00"` from `kaset`
  - Safari user agent
  - `SAPISIDHASH` auth header
  - full cookie header when available
- Supported operations include search, browse, library, liked songs, up next, like/remove like/dislike, and lyrics.

### Playback

- Playback state is observed from the hidden WebView through `observer.js`.
- `PlayerService` tracks:
  - current track
  - playback state
  - volume
  - shuffle
  - repeat mode
  - queue
  - album art
  - current playback time
- Playback controls call JavaScript helpers into YouTube Music.
- Media/Now Playing integration exists through `NowPlayingManager`.

### Home/Library/Search UI

- Home, library, liked songs, search, queue, now playing, settings, and player bar views exist.
- Wide video thumbnails are clipped into fixed frames in the places that were known to break layout:
  - Search rows
  - Home/main page compact cards
  - Home/main page small cards
  - Section cards
  - Song rows
- This specifically fixed the problem where wide video thumbnails overlapped text.

### Lyrics Overlay

- Lyrics overlay can load lyrics for the current track.
- It now calls `apiClient.lyricsWithFallback(for:)`.
- Resolver order:
  - YouTube Music timed lyrics from `timedLyricsModel`.
  - LRCLib synced LRC lyrics fallback.
  - Plain lyrics fallback if synced lyrics are unavailable.
- Synced overlay now uses raw `currentTimeMs` without the previous `0.35s` lead offset.

### Top macOS Menu Bar Lyrics

This refers to the macOS system menu bar at the top of the screen, not the panel content.

Current intended behavior:

- When nothing is playing, only the app icon is shown.
- When a track is playing and no synced lyric line is available, the status item shows:
  - `track title — artist`
- When synced lyrics are available and playback time reaches a lyric line, the status item shows:
  - the current lyric sentence
- Long status text scrolls horizontally.
- Short lyric lines are shown statically until the lyric line changes.

Implementation path:

- `AppDelegate.updateStatusBar()` reads `playerService.currentLyricLine`.
- If `currentLyricLine` is empty, it shows track title/artist.
- If `currentLyricLine` is non-empty, it shows the lyric.
- `AppDelegate.loadStatusLyricsIfNeeded(for:)` proactively loads lyrics when the status bar renders a playing track.
- `AppDelegate.loadStatusLyrics(for:)` calls `apiClient.lyricsWithFallback(for:)`.
- `PlayerService.setStatusLyrics(_:for:)` stores synced lines and timestamps, starts lyric polling with reason `status`, and calculates the current lyric line.
- `observer.js` posts playback time every 100ms while lyric polling is active.
- `SingletonPlayerWebView` receives `lyricsTime` and calls `PlayerService.handleLyricsTimeUpdate`.
- `PlayerService.updateStatusLyricLine()` binary-searches timestamps and calls `onLyricLineChanged`.
- `AppDelegate.onLyricLineChanged` calls `updateStatusBar()` to redraw the menu bar text.

## Issues Found And Fixes

### 1. Direct API Auth Was Too Different From `kaset`

Symptom:

- Direct YouTube Music API calls were unreliable.

Root cause:

- API auth and client context did not closely match the working `kaset` implementation.

Fix:

- Set the API client to use `WEB_REMIX`.
- Set the client version to `1.20231204.01.00`.
- Use SAPISIDHASH auth.
- Use current domain-matching YouTube cookies.
- Treat HTTP 401/403 as auth-expired.

Files:

- `YtbMusicBar/Services/API/YTMusicClient.swift`
- `YtbMusicBar/Services/WebKitManager.swift`

### 2. Search Row Video Thumbnails Broke Layout

Symptom:

- Search results could include videos.
- Video thumbnails are wider than square album thumbnails.
- Wide images overlapped text and made the row messy.

Root cause:

- Thumbnail views did not force a fixed square clipping frame everywhere.

Fix:

- Forced thumbnails into fixed-size clipped/rounded containers.
- Used scaled-to-fill behavior and clipping so wide thumbnails cannot overlap text.

Files:

- `YtbMusicBar/Views/SearchView.swift`

### 3. Home/Main Page Thumbnail Layout Also Broke With Video Images

Symptom:

- Similar wide-thumbnail overlap appeared on the main page/home page.

Root cause:

- Fixing search rows was not enough; other card/row components had the same assumption that thumbnails were square.

Fix:

- Applied fixed frame + clipped thumbnail containers to home/main page components.

Files:

- `YtbMusicBar/Views/HomeView.swift`
- `YtbMusicBar/Views/SectionCardView.swift`
- `YtbMusicBar/Views/SongRowView.swift`

### 4. App-Generated Debug Logs Were Too Noisy

Symptom:

- Runtime logs contained app-generated debug lines such as parser and collection load messages.

Root cause:

- Temporary print/debug logging had been left in parsers and collection/loading paths.

Fix:

- Removed noisy app-generated logging.
- Kept graceful failure behavior by clearing failed results instead of printing noisy diagnostics.

Files:

- `YtbMusicBar/Services/API/Parsers.swift`
- `YtbMusicBar/Views/LibraryView.swift`
- `YtbMusicBar/Views/SearchView.swift`

Important note:

- The remaining repeated `WebContent`, `RunningBoard`, `networkd`, `pboard`, `DetachedSignatures`, and Apple Intelligence log lines are macOS/WebKit/Xcode sandbox diagnostics, not app logs. They should not be fixed by adding private Apple entitlements.

### 5. Lyrics Overlay Was Not Real-Time Enough

Symptom:

- Lyrics overlay did not roll/update in sync with the song.

Root cause:

- The general playback observer was too coarse. It was not a dedicated high-frequency lyrics clock.

Fix:

- Added high-frequency lyrics polling in `observer.js` at about 10Hz.
- Added `lyricsTime` WebKit message handler.
- Added `PlayerService.currentTimeMs`.
- Updated lyrics overlay to react to `currentTimeMs`.
- Started/stopped lyric polling only while synced lyrics are active.

Files:

- `YtbMusicBar/Resources/observer.js`
- `YtbMusicBar/Services/SingletonPlayerWebView.swift`
- `YtbMusicBar/Services/PlayerService.swift`
- `YtbMusicBar/Views/LyricsView.swift`

### 6. YouTube Music Timed Lyrics Parser Did Not Handle Current Shape

Symptom:

- Timed lyrics could fail to parse even when YouTube Music returned them.

Root cause:

- Parser did not support the current `timedLyricsModel["lyricsData"] as [[String: Any]]` shape used by `kaset`.

Fix:

- Added support for:
  - direct `lyricsData` array
  - older nested `lyricsData.timedLyricsData`
  - older `timedLyricsData`
  - `cueRange.startTimeMilliseconds` fallback
- Added parser regression test.

Files:

- `YtbMusicBar/Services/API/Parsers.swift`
- `YtbMusicBarTests/ParsersTests.swift`

### 7. Menu Bar Lyrics Were Initially Only Tied To Track-Change Callback

Symptom:

- The macOS top menu bar still showed song title even while a song was playing.

Root cause:

- The first menu bar lyrics implementation loaded lyrics only from `onTrackChanged`.
- If the app started while a track was already playing, or if state was cleared without resetting the request marker, the current track could be considered already requested and never reloaded.

Fix:

- Added `loadStatusLyricsIfNeeded(for:)`.
- Called it from `updateStatusBar()` for playing tracks.
- Reset `statusLyricsRequestedVideoId` on track changes.
- The menu bar now tries to load lyrics for the current playing track from its own render path.

Files:

- `YtbMusicBar/App/AppDelegate.swift`

### 8. Menu Bar Lyrics Still Failed For Songs Without YouTube Timed Lyrics

Symptom:

- After the menu bar loader fix, some tracks still showed only title.

Root cause:

- Our app only used YouTube Music timed lyrics.
- `kaset` uses YouTube Music timed lyrics first, then LRCLib synced lyrics fallback.

Fix:

- Added `YTMusicClient.lyricsWithFallback(for:)`.
- Added LRCLib search by track title and artist.
- Chose closest LRCLib match by duration when duration is known.
- Added LRC parser adapted from `kaset`.
- Converted LRCLib synced LRC into the app’s existing `LyricsResult` / `LyricsLine` model.
- Used the same fallback path for both menu bar lyrics and overlay lyrics.
- Added LRC parser regression test.

Files:

- `YtbMusicBar/Services/API/YTMusicClient.swift`
- `YtbMusicBar/Services/API/Parsers.swift`
- `YtbMusicBar/App/AppDelegate.swift`
- `YtbMusicBar/Views/LyricsView.swift`
- `YtbMusicBarTests/ParsersTests.swift`

### 9. Lyrics Timing Felt Slightly Unsynchronized

Symptom:

- Lyrics felt slightly out of sync with the song.

Root cause:

- The app had a `0.35s` display lead in some synced lyrics code.
- `kaset` uses raw playback time for line selection.

Fix:

- Removed the status menu bar lead offset.
- Removed the lyrics overlay `0.35s` lead.
- Both now use raw playback time.

Files:

- `YtbMusicBar/Services/PlayerService.swift`
- `YtbMusicBar/Views/LyricsView.swift`

## Current Validation State

Most recent validation after LRCLib fallback:

```bash
xcodebuild -project YtbMusicBar.xcodeproj -scheme YtbMusicBar -configuration Debug -destination 'platform=macOS' build-for-testing
```

Result:

- Passed.

Direct test bundle command:

```bash
DYLD_LIBRARY_PATH='/Users/weixijia/Library/Developer/Xcode/DerivedData/YtbMusicBar-feaucapranjpwuafntffehunsxkb/Build/Products/Debug/Ytb Music Bar.app/Contents/MacOS' xcrun xctest '/Users/weixijia/Library/Developer/Xcode/DerivedData/YtbMusicBar-feaucapranjpwuafntffehunsxkb/Build/Products/Debug/Ytb Music Bar.app/Contents/PlugIns/YtbMusicBarTests.xctest'
```

Result:

- Passed.
- 10 tests.
- 0 failures.

Why direct `xcrun xctest` is used:

- Normal `xcodebuild test` app-host launch has previously hung locally before XCTest output.
- `build-for-testing` followed by direct `xcrun xctest` has been reliable.

## Security Notes

During development, a sensitive OpenAI/session payload was pasted into the conversation.

Actions taken:

- The repository was searched for that payload.
- It was not found in project files.
- It was not committed.

Important:

- Do not paste or repeat the token/session contents.
- If not already done, revoke/rotate that exposed session/token externally.

## Known Runtime Logs That Are Not App Bugs

These log categories have appeared during runs:

- `no reasons from unifiedReasons for identifier: com.apple.Settings.AppleIntelligence.Partner.ChatGPT`
- `cannot open file ... /private/var/db/DetachedSignatures`
- `WebContent[...] Connection to 'pboard' server had an error`
- `Sandbox restriction`
- `launchservicesd prohibited`
- `RunningBoard`
- `networkd_settings_read_from_file_locked`
- `RBSServiceErrorDomain ... com.apple.runningboard.assertions.webkit`
- `Failed to acquire RBS assertion 'WebKit Media Playback'`

Current assessment:

- These are macOS/WebKit/Xcode runtime diagnostics from sandboxed WebContent or system services.
- They are not emitted by our app logging.
- Do not add private Apple entitlements to silence them.
- If playback is actually interrupted in a packaged app, investigate entitlements and sandbox settings separately, but do not treat these logs alone as app bugs.

## Remaining Work And Risks

### 1. Some Songs May Still Show Track Title Instead Of Lyrics

Reason:

- The menu bar can only show synced lyric lines if YouTube Music or LRCLib returns synced lyrics.
- If both sources lack synced lyrics, the app intentionally falls back to title/artist.

Possible future improvement:

- Add more lyrics providers.
- Add an explicit “No synced lyrics available” debug state in development builds only.
- Cache per-video lyric availability so failures are easier to diagnose.

### 2. LRCLib Matching Is Simple

Current behavior:

- Search LRCLib by `track.title` and `track.artist`.
- If duration is known, choose the closest duration match.

Risk:

- Remixes, live versions, covers, translations, region variants, and YouTube video titles with extra text may match imperfectly.

Possible future improvement:

- Normalize titles by stripping common suffixes like `(Official Video)`, `(Lyrics)`, `(Live)`.
- Use album when available.
- Add better scoring based on title/artist similarity and duration.

### 3. Lyrics Fallback Is Not Yet Cached

Current behavior:

- YouTube Music API calls use `APICache` for some paths, but LRCLib fallback is not explicitly cached in the current implementation.

Risk:

- Repeated lyric loads for the same track can re-query LRCLib.

Possible future improvement:

- Add an in-memory cache keyed by `videoId` or normalized title/artist/duration.
- Cache both synced hits and misses with a short TTL.

### 4. Status Bar Text Width Is Static

Current behavior:

- `scrollMaxChars = 40`.
- Long text scrolls horizontally.

Risk:

- The macOS menu bar may become crowded on small displays, many status items, or long lyric lines.

Possible future improvement:

- Add a setting for max status text width.
- Add a setting to disable menu bar lyrics and only show title/artist.
- Consider truncating instead of scrolling if users find scrolling distracting.

### 5. Normal `xcodebuild test` Can Hang

Current behavior:

- `build-for-testing` passes.
- Direct `xcrun xctest` passes.
- Normal `xcodebuild test` has previously hung locally before test output.

Possible future improvement:

- Investigate app-hosted test launch configuration.
- Add a non-app-hosted test target for pure parser/model tests.
- Add CI that runs the direct XCTest command or a better-separated test suite.

### 6. App Store/Distribution Is Not Solved

Risk:

- YouTube Music wrappers may have App Store review and Google ToS concerns.

Possible future improvement:

- Decide distribution channel:
  - GitHub Releases
  - Homebrew cask
  - Direct signed/notarized download
- Add signing/notarization workflow only after the feature set stabilizes.

### 7. OS/WebKit Diagnostics Are Still Verbose

Current behavior:

- macOS/WebKit emits noisy diagnostics during WebContent operations.

Possible future improvement:

- Do nothing unless there is an actual user-facing bug.
- If a real packaged-app playback issue appears, inspect sandbox/hardened runtime entitlements using public Apple capabilities only.

## Suggested Next Steps

1. Manually test a song known to have LRCLib synced lyrics and verify the top macOS menu bar changes from title to lyric sentence.
2. Manually test a song with only plain/no lyrics and confirm it gracefully remains title/artist.
3. Test wide video thumbnails again in search and home page.
4. Add lyric source/debug UI in a hidden development-only panel if menu bar lyric debugging remains difficult.
5. Add cache for `lyricsWithFallback(for:)`.
6. Consider extracting lyrics resolution into its own service if more providers are added.

## Quick Commands

Build for testing:

```bash
xcodebuild -project YtbMusicBar.xcodeproj -scheme YtbMusicBar -configuration Debug -destination 'platform=macOS' build-for-testing
```

Run direct tests:

```bash
DYLD_LIBRARY_PATH='/Users/weixijia/Library/Developer/Xcode/DerivedData/YtbMusicBar-feaucapranjpwuafntffehunsxkb/Build/Products/Debug/Ytb Music Bar.app/Contents/MacOS' xcrun xctest '/Users/weixijia/Library/Developer/Xcode/DerivedData/YtbMusicBar-feaucapranjpwuafntffehunsxkb/Build/Products/Debug/Ytb Music Bar.app/Contents/PlugIns/YtbMusicBarTests.xctest'
```

Open project:

```bash
open YtbMusicBar.xcodeproj
```

Check repo state:

```bash
git status --short
git log --oneline -10
```

## Do Not Commit

Do not commit:

- `kaset/`
- `.DS_Store`
- `.claude/`
- Xcode user data such as `xcuserdata/`
- Secrets, cookies, session tokens, or auth payloads

These are currently ignored or should remain local-only.

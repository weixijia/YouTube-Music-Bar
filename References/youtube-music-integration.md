# YouTube Music Integration Reference

## Core Approach

Embed YouTube Music web app via WKWebView, extract playback state via JavaScript bridge, and integrate with macOS media controls.

## WKWebView Setup

### User Agent (Critical)

Google blocks OAuth in embedded WebViews. All existing YT Music wrappers solve this by setting a Safari-like user agent:

```swift
let webView = WKWebView(frame: .zero, configuration: config)
webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
```

### Block Service Worker

YouTube Music's service worker can cause issues. Block `sw.js`:

```swift
let blockRule = """
[{
    "trigger": {"url-filter": ".*sw\\\\.js$"},
    "action": {"type": "block"}
}]
"""
WKContentRuleListStore.default().compileContentRuleList(
    forIdentifier: "blockSW", encodedContentRuleList: blockRule
) { ruleList, error in
    if let ruleList { config.userContentController.add(ruleList) }
}
```

### Cookie Persistence

Use `WKWebsiteDataStore.default()` (NOT `.nonPersistent()`) to keep Google login session:

```swift
let config = WKWebViewConfiguration()
config.websiteDataStore = .default()
```

## JavaScript Bridge

### Injecting Observer Script

Use `WKUserScript` + `MutationObserver` to watch `ytmusic-player-bar`:

```javascript
// Key selectors (proven across all open-source projects)
const SELECTORS = {
    title:    '.title.ytmusic-player-bar',
    artist:   '.byline.ytmusic-player-bar a',
    albumArt: 'img.image.ytmusic-player-bar',
    progress: '#progress-bar',
    video:    'video',
};

// MutationObserver on player bar
const observer = new MutationObserver(() => {
    const title = document.querySelector(SELECTORS.title)?.textContent;
    const artist = document.querySelector(SELECTORS.artist)?.textContent;
    const artUrl = document.querySelector(SELECTORS.albumArt)?.src;
    const video = document.querySelector(SELECTORS.video);
    
    window.webkit.messageHandlers.observer.postMessage({
        title: title,
        artist: artist,
        albumArt: artUrl,
        isPlaying: video && !video.paused,
        currentTime: video?.currentTime,
        duration: video?.duration,
        volume: video?.volume,
    });
});

// Observe the player bar for changes
const playerBar = document.querySelector('ytmusic-player-bar');
if (playerBar) {
    observer.observe(playerBar, { subtree: true, childList: true, characterData: true });
}
```

### Playback Control via JS

```javascript
// movie_player API (available on YouTube Music)
const player = document.getElementById('movie_player');

player.playVideo();        // Play
player.pauseVideo();       // Pause
player.nextVideo();        // Next track
player.previousVideo();    // Previous track
player.setVolume(80);      // Set volume (0-100)
player.seekTo(30);         // Seek to 30 seconds
player.getPlayerState();   // -1:unstarted, 0:ended, 1:playing, 2:paused, 3:buffering
```

### Swift-Side Handler

```swift
class WebViewMessageHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ controller: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String: Any] else { return }
        // Update playback state model
    }
}
```

## macOS Media Controls

### MPNowPlayingInfoCenter

```swift
import MediaPlayer

func updateNowPlaying(title: String, artist: String, duration: Double, currentTime: Double, artwork: NSImage?) {
    var info: [String: Any] = [
        MPMediaItemPropertyTitle: title,
        MPMediaItemPropertyArtist: artist,
        MPMediaItemPropertyPlaybackDuration: duration,
        MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
        MPNowPlayingInfoPropertyPlaybackRate: 1.0,
    ]
    if let artwork {
        info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artwork.size) { _ in artwork }
    }
    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
}
```

### MPRemoteCommandCenter (Media Keys)

```swift
let commandCenter = MPRemoteCommandCenter.shared()

commandCenter.playCommand.addTarget { _ in
    webView.evaluateJavaScript("document.getElementById('movie_player').playVideo()")
    return .success
}
commandCenter.pauseCommand.addTarget { _ in
    webView.evaluateJavaScript("document.getElementById('movie_player').pauseVideo()")
    return .success
}
commandCenter.nextTrackCommand.addTarget { _ in
    webView.evaluateJavaScript("document.getElementById('movie_player').nextVideo()")
    return .success
}
commandCenter.previousTrackCommand.addTarget { _ in
    webView.evaluateJavaScript("document.getElementById('movie_player').previousVideo()")
    return .success
}
```

> **WARNING**: Do NOT use private `MediaRemote` framework — it broke in macOS Sequoia 15.4.

## Google Authentication

- Let user sign in directly in WKWebView with persistent cookies
- No separate OAuth flow needed
- Advanced: Extract SAPISID cookie for direct API calls (see kaset project)

## App Store Considerations

- YouTube Music wrappers may face App Store scrutiny
- Consider distributing via: direct download, Homebrew cask, or GitHub releases
- Technically violates Google ToS but universally used by all existing wrappers

## Related
- [menu-bar-app-architecture.md](menu-bar-app-architecture.md) — App architecture
- [open-source-projects.md](open-source-projects.md) — Reference implementations
- [../Skills/swift-concurrency.md](../Skills/swift-concurrency.md) — Concurrency for JS bridge

import Foundation
import WebKit
import AppKit

/// A persistent WKWebView that serves as the audio engine for YouTube Music playback.
/// Hidden at 1x1 pixel during normal use; shown full-size only for login.
@MainActor @Observable
final class SingletonPlayerWebView: NSObject {

    let webView: WKWebView
    private let webKitManager: WebKitManager

    // Callbacks
    var onStateUpdate: ((TrackState) -> Void)?
    var onTrackEnded: (() -> Void)?
    var onAuthCookieDetected: (() -> Void)?

    /// Parsed state from JavaScript observer.
    struct TrackState: Sendable {
        var title: String = ""
        var artist: String = ""
        var albumArt: String = ""
        var videoId: String = ""
        var albumTitle: String = ""
        var isPlaying: Bool = false
        var currentTime: Double = 0
        var duration: Double = 0
        var volume: Int = 100
        var isLiked: Bool = false
    }

    init(webKitManager: WebKitManager) {
        self.webKitManager = webKitManager

        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsAirPlayForMediaPlayback = true

        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        config.defaultWebpagePreferences = preferences

        self.webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 1, height: 1), configuration: config)

        super.init()

        webView.customUserAgent = Constants.safariUserAgent
        webView.navigationDelegate = self

        setupContentRules()
        injectScripts()

        // Register message handlers
        let handlers = ["observer", "trackEnded"]
        for handler in handlers {
            config.userContentController.add(self, name: handler)
        }

        // Monitor cookies for login detection
        config.websiteDataStore.httpCookieStore.add(self)
    }

    // MARK: - Public API

    func loadYouTubeMusic() {
        let request = URLRequest(url: Constants.ytMusicURL)
        webView.load(request)
    }

    func loadLoginPage() {
        let request = URLRequest(url: Constants.ytMusicLoginURL)
        webView.load(request)
    }

    func play(videoId: String) {
        let url = Constants.ytMusicURL.appendingPathComponent("watch")
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        components.queryItems = [URLQueryItem(name: "v", value: videoId)]
        if let finalURL = components.url {
            webView.load(URLRequest(url: finalURL))
        }
    }

    func playPlaylist(id: String) {
        let url = Constants.ytMusicURL.appendingPathComponent("watch")
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        components.queryItems = [URLQueryItem(name: "list", value: id)]
        if let finalURL = components.url {
            webView.load(URLRequest(url: finalURL))
        }
    }

    func evaluateJS(_ script: String) async {
        do {
            _ = try await webView.evaluateJavaScript(script)
        } catch {
            print("[PlayerWebView] JS error: \(error.localizedDescription)")
        }
    }

    func evaluateJSFire(_ script: String) {
        webView.evaluateJavaScript(script) { _, _ in }
    }

    // MARK: - Setup

    private func setupContentRules() {
        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "blockSW",
            encodedContentRuleList: Constants.blockServiceWorkerRule
        ) { [weak self] ruleList, _ in
            if let ruleList {
                self?.webView.configuration.userContentController.add(ruleList)
            }
        }
    }

    private func injectScripts() {
        // Inject Viewport Meta Tag for responsive scaling in the 320x480 LoginView
        let viewportScriptSource = """
        var meta = document.createElement('meta');
        meta.name = 'viewport';
        meta.content = 'width=320, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
        document.getElementsByTagName('head')[0].appendChild(meta);
        """
        let viewportScript = WKUserScript(
            source: viewportScriptSource,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        webView.configuration.userContentController.addUserScript(viewportScript)

        let scripts = ["controls", "observer"]
        for name in scripts {
            guard let path = Bundle.main.path(forResource: name, ofType: "js"),
                  let source = try? String(contentsOfFile: path) else {
                print("[PlayerWebView] Failed to load \\(name).js")
                continue
            }
            let script = WKUserScript(
                source: source,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true
            )
            webView.configuration.userContentController.addUserScript(script)
        }
    }
}

// MARK: - WKScriptMessageHandler

extension SingletonPlayerWebView: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        switch message.name {
        case "observer":
            guard let dict = message.body as? [String: Any] else { return }
            let state = TrackState(
                title: dict["title"] as? String ?? "",
                artist: dict["artist"] as? String ?? "",
                albumArt: dict["albumArt"] as? String ?? "",
                videoId: dict["videoId"] as? String ?? "",
                albumTitle: dict["albumTitle"] as? String ?? "",
                isPlaying: dict["isPlaying"] as? Bool ?? false,
                currentTime: dict["currentTime"] as? Double ?? 0,
                duration: dict["duration"] as? Double ?? 0,
                volume: dict["volume"] as? Int ?? 100,
                isLiked: dict["isLiked"] as? Bool ?? false
            )
            onStateUpdate?(state)

        case "trackEnded":
            onTrackEnded?()

        default:
            break
        }
    }
}

// MARK: - WKNavigationDelegate

extension SingletonPlayerWebView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Save cookies after each navigation
        Task {
            await webKitManager.saveCookies(from: webView.configuration.websiteDataStore)
        }
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction
    ) async -> WKNavigationActionPolicy {
        guard let url = navigationAction.request.url, let host = url.host else {
            return .allow
        }

        // Allow YouTube Music and Google auth domains
        if host.contains("youtube.com") || host.contains("google.com")
            || host.contains("gstatic.com") || host.contains("googleapis.com") {
            return .allow
        }

        // External links → open in default browser
        if navigationAction.navigationType == .linkActivated {
            NSWorkspace.shared.open(url)
            return .cancel
        }

        return .allow
    }
}

// MARK: - WKHTTPCookieStoreObserver

extension SingletonPlayerWebView: WKHTTPCookieStoreObserver {
    func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
        Task {
            let hasAuth = await webKitManager.hasAuthCookies(in: webView.configuration.websiteDataStore)
            if hasAuth {
                await webKitManager.saveCookies(from: webView.configuration.websiteDataStore)
                onAuthCookieDetected?()
            }
        }
    }
}

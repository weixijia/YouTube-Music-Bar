import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem?
    private var panel: FloatingPanel?
    private var hiddenWindow: NSWindow?
    private var wasPlayingBeforeSleep = false
    private var statusLyricsTask: Task<Void, Never>?
    private var statusLyricsRequestedVideoId: String?

    // Scrolling text in the single status item
    private var scrollTimer: Timer?
    private var scrollOffset: Int = 0
    private var scrollFullText: String = ""
    private let scrollMaxChars = 40
    private var lastScrollTextKey: String = ""
    private var isShowingText = false

    // Services (shared across the app)
    let webKitManager = WebKitManager()
    lazy var authService = AuthService(webKitManager: webKitManager)
    lazy var playerWebView = SingletonPlayerWebView(webKitManager: webKitManager)
    lazy var playerService = PlayerService(playerWebView: playerWebView)
    lazy var nowPlayingManager = NowPlayingManager(playerService: playerService)
    lazy var apiClient = YTMusicClient(webKitManager: webKitManager)
    let notificationService = NotificationService()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        nowPlayingManager.setup()

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = playerWebView.webView
        hiddenWindow = window

        // Wire API client to player service for like/dislike sync
        playerService.apiClient = apiClient

        setupStatusItem()
        setupPanel()
        notificationService.requestPermission()

        playerService.onPlaybackStateChanged = { [weak self] isPlaying in
            self?.updateStatusBar()
        }
        playerService.onTrackChanged = { [weak self] track in
            self?.notificationService.notifyTrackChange(track: track)
            self?.statusLyricsRequestedVideoId = nil
            self?.updateStatusBar()
        }
        playerService.onLyricLineChanged = { [weak self] _ in
            self?.updateStatusBar()
        }

        // Login detection via cookie observer (moved from LoginView for stable references)
        playerWebView.onAuthCookieDetected = { [weak self] in
            self?.handleLoginDetected()
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification, object: nil, queue: nil
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.wasPlayingBeforeSleep = self.playerService.playbackState.isPlaying
                if self.wasPlayingBeforeSleep { self.playerService.pause() }
            }
        }

        Task {
            await authService.checkLoginState()
            if authService.state == .loggedIn {
                playerWebView.loadYouTubeMusic()
            }
        }
    }

    /// Called when auth cookies are detected after login.
    /// Stable reference in AppDelegate — no SwiftUI closure capture issues.
    private func handleLoginDetected() {
        guard authService.state != .loggedIn else { return }

        // 1. Save cookies immediately (kaset: forceBackupCookies)
        Task {
            await webKitManager.saveCookies(from: playerWebView.webView.configuration.websiteDataStore)
        }

        // 2. Transition to logged-in state
        authService.onLoginDetected()

        // 3. After cookies settle, reload YouTube Music and restore WebView
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            playerWebView.loadYouTubeMusic()
            restoreHiddenWebView()
        }
    }

    func restoreHiddenWebView() {
        hiddenWindow?.contentView = playerWebView.webView
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationWillTerminate(_ notification: Notification) {
        playerService.saveState()
        nowPlayingManager.teardown()
        statusLyricsTask?.cancel()
        scrollTimer?.invalidate()
    }

    private func loadStatusLyrics(for track: Track) {
        statusLyricsTask?.cancel()
        guard !track.videoId.isEmpty else {
            statusLyricsRequestedVideoId = nil
            playerService.clearStatusLyrics()
            return
        }

        let videoId = track.videoId
        statusLyricsRequestedVideoId = videoId
        statusLyricsTask = Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await self.apiClient.lyricsWithFallback(for: track)
                guard !Task.isCancelled else { return }
                self.playerService.setStatusLyrics(result, for: videoId)
            } catch {
                guard !Task.isCancelled else { return }
                self.playerService.clearStatusLyrics()
            }
        }
    }

    private func loadStatusLyricsIfNeeded(for track: Track) {
        guard !track.videoId.isEmpty else {
            if statusLyricsRequestedVideoId != nil {
                statusLyricsRequestedVideoId = nil
                playerService.clearStatusLyrics()
            }
            return
        }

        guard statusLyricsRequestedVideoId != track.videoId else { return }
        loadStatusLyrics(for: track)
    }

    // MARK: - Status Item (single item: icon + optional scrolling text)

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }

        let image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "YT Music")
        image?.isTemplate = true
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        button.image = image?.withSymbolConfiguration(config)
        button.imagePosition = .imageLeading
        button.action = #selector(statusItemClicked)
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    /// Update the status bar: icon + scrolling "Now Playing" text in one item
    private func updateStatusBar() {
        guard let button = statusItem?.button else { return }

        let track = playerService.track
        let isPlaying = playerService.playbackState.isPlaying

        // Icon
        let symbolName = isPlaying ? "waveform" : "music.note"
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "YT Music")
        image?.isTemplate = true
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        button.image = image?.withSymbolConfiguration(config)

        if track.isEmpty || !isPlaying {
            // Not playing → icon only
            button.title = ""
            button.attributedTitle = NSAttributedString(string: "")
            isShowingText = false
            scrollTimer?.invalidate()
            scrollTimer = nil
            scrollOffset = 0
            lastScrollTextKey = ""
            return
        }

        loadStatusLyricsIfNeeded(for: track)

        // Playing → prefer synced lyric line when available, otherwise show track info.
        let lyricLine = playerService.currentLyricLine
        let newText = lyricLine.isEmpty ? " \(track.title) — \(track.artist)" : " \(lyricLine)"
        let newTextKey = lyricLine.isEmpty ? "track:\(track.id)" : "lyric:\(track.id):\(lyricLine)"

        if newTextKey != lastScrollTextKey {
            lastScrollTextKey = newTextKey
            scrollFullText = newText
            scrollOffset = 0
        } else {
            scrollFullText = newText
        }
        isShowingText = true
        renderScrollText()

        if scrollFullText.count > scrollMaxChars && scrollTimer == nil {
            scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.tickScroll() }
            }
        } else if scrollFullText.count <= scrollMaxChars {
            scrollTimer?.invalidate()
            scrollTimer = nil
            scrollOffset = 0
        }
    }

    private func tickScroll() {
        guard !scrollFullText.isEmpty else { return }
        let paddedText = scrollFullText + "   ♫   "
        scrollOffset = (scrollOffset + 1) % paddedText.count
        renderScrollText()
    }

    private func renderScrollText() {
        guard let button = statusItem?.button else { return }

        let displayText: String
        if scrollFullText.count <= scrollMaxChars {
            displayText = scrollFullText
        } else {
            let paddedText = scrollFullText + "   ♫   "
            let chars = Array(paddedText)
            var visible = ""
            for i in 0..<scrollMaxChars {
                visible.append(chars[(scrollOffset + i) % chars.count])
            }
            displayText = visible
        }

        button.title = displayText
        let font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        button.attributedTitle = NSAttributedString(
            string: displayText,
            attributes: [.font: font, .baselineOffset: 0.5]
        )
    }

    @objc private func statusItemClicked() {
        guard let button = statusItem?.button else { return }
        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu()
        } else {
            panel?.toggle(relativeTo: button)
        }
    }

    // MARK: - Context Menu

    private func showContextMenu() {
        let menu = NSMenu()

        let track = playerService.track
        if !track.isEmpty {
            let info = NSMenuItem(title: "\(track.title) — \(track.artist)", action: nil, keyEquivalent: "")
            info.isEnabled = false
            menu.addItem(info)
            menu.addItem(.separator())

            let ppTitle = playerService.playbackState.isPlaying ? "Pause" : "Play"
            menu.addItem(NSMenuItem(title: ppTitle, action: #selector(menuTogglePlayPause), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Next Track", action: #selector(menuNextTrack), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Previous Track", action: #selector(menuPreviousTrack), keyEquivalent: ""))
            menu.addItem(.separator())

            let likeTitle = track.isLiked ? "Unlike" : "Like"
            menu.addItem(NSMenuItem(title: likeTitle, action: #selector(menuToggleLike), keyEquivalent: ""))
            menu.addItem(.separator())
        }

        if authService.state == .loggedIn {
            menu.addItem(NSMenuItem(title: "Sign Out", action: #selector(menuSignOut), keyEquivalent: ""))
        }
        menu.addItem(NSMenuItem(title: "About Ytb Music Bar", action: #selector(menuShowAbout), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Ytb Music Bar", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func menuTogglePlayPause() { playerService.togglePlayPause() }
    @objc private func menuNextTrack() { playerService.nextTrack() }
    @objc private func menuPreviousTrack() { playerService.previousTrack() }
    @objc private func menuToggleLike() { playerService.toggleLike() }
    @objc private func menuSignOut() { Task { await authService.signOut() } }

    @objc private func menuShowAbout() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.2.0"
        let alert = NSAlert()
        alert.messageText = "Ytb Music Bar"
        alert.informativeText = "Version \(version)\n\nA native macOS menu bar app for YouTube Music."
        alert.alertStyle = .informational
        alert.icon = NSApp.applicationIconImage
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func quitApp() { NSApplication.shared.terminate(nil) }

    // MARK: - Panel

    private func setupPanel() {
        panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 320, height: 540))
        let contentView = MainPanelView()
            .environment(authService)
            .environment(playerService)
            .environment(playerWebView)
            .environment(nowPlayingManager)
            .environment(apiClient)
        panel?.setContent(contentView)
    }
}

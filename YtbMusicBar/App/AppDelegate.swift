import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem?
    private var statusContentView: StatusBarLyricView?
    private var panel: FloatingPanel?
    private var settingsWindow: NSWindow?
    private var hiddenWindow: NSWindow?
    private var wasPlayingBeforeSleep = false
    private var statusLyricsTask: Task<Void, Never>?
    private var statusLyricsRequestKey: String?
    private var statusLyricsRetryTask: Task<Void, Never>?
    private var statusLyricsRetryKey: String?
    private var statusLyricsRetryAttempt = 0

    private let maxStatusLyricsRetryAttempts = 3
    private let baseStatusLyricsRetryDelay: TimeInterval = 1.2

    // Services (shared across the app)
    let webKitManager = WebKitManager()
    lazy var authService = AuthService(webKitManager: webKitManager)
    lazy var playerWebView = SingletonPlayerWebView(webKitManager: webKitManager)
    lazy var playerService = PlayerService(playerWebView: playerWebView)
    lazy var nowPlayingManager = NowPlayingManager(playerService: playerService)
    lazy var apiClient = YTMusicClient(webKitManager: webKitManager, authService: authService)
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

        setupStatusItem()
        setupPanel()

        playerService.onPlaybackStateChanged = { [weak self] isPlaying in
            self?.updateStatusBar()
        }
        playerService.onTrackChanged = { [weak self] track in
            guard let self else { return }
            self.notificationService.notifyTrackChange(track: track)
            self.statusLyricsRequestKey = nil
            self.loadStatusLyrics(for: track)
            self.updateStatusBar()
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
        authService.completeLogin()

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
        statusLyricsRetryTask?.cancel()
        statusContentView?.stopMarqueeAnimation()
    }

    private func loadStatusLyrics(for track: Track) {
        statusLyricsTask?.cancel()
        statusLyricsRetryTask?.cancel()
        guard !track.videoId.isEmpty else {
            statusLyricsRequestKey = nil
            resetStatusLyricsRetryState()
            playerService.clearStatusLyrics()
            return
        }

        let videoId = track.videoId
        let requestKey = statusLyricsKey(for: track)
        if statusLyricsRetryKey != requestKey {
            statusLyricsRetryKey = requestKey
            statusLyricsRetryAttempt = 0
        }
        statusLyricsRequestKey = requestKey
        statusLyricsTask = Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await self.apiClient.lyricsWithFallback(for: track)
                guard !Task.isCancelled else { return }
                self.playerService.setStatusLyrics(result, for: videoId)
                if self.playerService.hasStatusLyrics {
                    self.resetStatusLyricsRetryState(for: requestKey)
                } else {
                    self.handleStatusLyricsFailure(for: track, requestKey: requestKey)
                }
            } catch {
                guard !Task.isCancelled else { return }
                self.handleStatusLyricsFailure(for: track, requestKey: requestKey)
            }
        }
    }

    private func loadStatusLyricsIfNeeded(for track: Track) {
        guard !track.videoId.isEmpty else {
            if statusLyricsRequestKey != nil {
                statusLyricsRequestKey = nil
                resetStatusLyricsRetryState()
                playerService.clearStatusLyrics()
            }
            return
        }

        guard statusLyricsRequestKey != statusLyricsKey(for: track) else { return }
        loadStatusLyrics(for: track)
    }

    private func handleStatusLyricsFailure(for track: Track, requestKey: String) {
        playerService.clearStatusLyrics()

        guard statusLyricsRetryKey == requestKey else { return }
        guard statusLyricsRetryAttempt < maxStatusLyricsRetryAttempts else { return }

        scheduleStatusLyricsRetry(for: track, requestKey: requestKey)
    }

    private func scheduleStatusLyricsRetry(for track: Track, requestKey: String) {
        statusLyricsRetryTask?.cancel()
        statusLyricsRetryAttempt += 1
        let delay = min(
            baseStatusLyricsRetryDelay * pow(2, Double(statusLyricsRetryAttempt - 1)),
            9.6
        )

        statusLyricsRetryTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard let self, !Task.isCancelled else { return }
            let refreshedTrack = self.playerService.track
            guard self.statusLyricsKey(for: refreshedTrack) == requestKey else { return }
            guard refreshedTrack.videoId == track.videoId, self.playerService.currentLyricLine.isEmpty else { return }
            self.loadStatusLyrics(for: refreshedTrack)
        }
    }

    private func resetStatusLyricsRetryState(for requestKey: String? = nil) {
        if let requestKey {
            guard statusLyricsRetryKey == requestKey else { return }
        }

        statusLyricsRetryTask?.cancel()
        statusLyricsRetryKey = nil
        statusLyricsRetryAttempt = 0
    }

    private func statusLyricsKey(for track: Track) -> String {
        [
            track.videoId,
            track.title.trimmingCharacters(in: .whitespacesAndNewlines),
            track.artist.trimmingCharacters(in: .whitespacesAndNewlines),
        ].joined(separator: "|")
    }

    // MARK: - Status Item (single item: icon + optional scrolling text)

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }

        button.image = nil
        button.title = ""
        button.action = #selector(statusItemClicked)
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        let contentView = StatusBarLyricView(frame: button.bounds)
        contentView.autoresizingMask = [.width, .height]
        contentView.onPreferredLengthChanged = { [weak self] length in
            self?.statusItem?.length = length
        }
        button.addSubview(contentView)
        statusContentView = contentView
        statusItem?.length = contentView.preferredLength
    }

    private func updateStatusBar() {
        guard let button = statusItem?.button, let statusContentView else { return }

        let track = playerService.track
        let isPlaying = playerService.playbackState.isPlaying

        let symbolName = isPlaying ? "waveform" : "music.note"

        if track.isEmpty || !isPlaying {
            statusContentView.update(symbolName: symbolName, text: nil)
            button.toolTip = track.isEmpty ? "YT Music" : "\(track.title) — \(track.artist)"
            return
        }

        loadStatusLyricsIfNeeded(for: track)

        let lyricLine = playerService.currentLyricLine
        let statusText = lyricLine.isEmpty ? "\(track.title) — \(track.artist)" : lyricLine
        statusContentView.update(symbolName: symbolName, text: statusText)
        button.toolTip = statusText
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
        menu.autoenablesItems = false

        let track = playerService.track
        if !track.isEmpty {
            let info = NSMenuItem(title: "\(track.title) — \(track.artist)", action: nil, keyEquivalent: "")
            info.isEnabled = false
            menu.addItem(info)
            menu.addItem(.separator())

            let ppTitle = playerService.playbackState.isPlaying ? "Pause" : "Play"
            menu.addItem(makeMenuItem(title: ppTitle, action: #selector(menuTogglePlayPause)))
            menu.addItem(makeMenuItem(title: "Next Track", action: #selector(menuNextTrack)))
            menu.addItem(makeMenuItem(title: "Previous Track", action: #selector(menuPreviousTrack)))
            menu.addItem(.separator())

            let likeTitle = track.isLiked ? "Unlike" : "Like"
            menu.addItem(makeMenuItem(title: likeTitle, action: #selector(menuToggleLike)))
            menu.addItem(.separator())
        }

        if authService.state == .loggedIn {
            menu.addItem(makeMenuItem(title: "Settings…", action: #selector(menuOpenSettings), keyEquivalent: ","))
            menu.addItem(.separator())
            menu.addItem(makeMenuItem(title: "Sign Out", action: #selector(menuSignOut)))
        }
        else {
            menu.addItem(makeMenuItem(title: "Settings…", action: #selector(menuOpenSettings), keyEquivalent: ","))
        }
        menu.addItem(makeMenuItem(title: "About Ytb Music Bar", action: #selector(menuShowAbout)))
        menu.addItem(.separator())
        menu.addItem(makeMenuItem(title: "Quit Ytb Music Bar", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    private func makeMenuItem(title: String, action: Selector, keyEquivalent: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        item.isEnabled = true
        return item
    }

    @objc private func menuTogglePlayPause() { playerService.togglePlayPause() }
    @objc private func menuNextTrack() { playerService.nextTrack() }
    @objc private func menuPreviousTrack() { playerService.previousTrack() }
    @objc private func menuToggleLike() { playerService.toggleLike() }
    @objc private func menuOpenSettings() {
        NSApp.activate(ignoringOtherApps: true)
        openSettingsWindow()
    }
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
        panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 320, height: 480))
        let contentView = MainPanelView()
            .environment(authService)
            .environment(playerService)
            .environment(playerWebView)
            .environment(nowPlayingManager)
            .environment(apiClient)
        panel?.setContent(contentView)
    }

    func openSettingsWindow() {
        if settingsWindow == nil {
            let contentView = SettingsView()
                .environment(authService)

            let hostingController = NSHostingController(rootView: contentView)
            let window = NSWindow(contentViewController: hostingController)
            window.title = "Settings"
            window.identifier = NSUserInterfaceItemIdentifier("com.ytbmusicbar.settings")
            window.setContentSize(NSSize(width: 520, height: 420))
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }

        guard let settingsWindow else { return }
        settingsWindow.makeKeyAndOrderFront(nil)
        settingsWindow.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }
}

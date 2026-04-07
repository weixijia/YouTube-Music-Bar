import Foundation
import AppKit
import Observation

/// Central player service coordinating WebView playback, queue, and state.
@MainActor @Observable
final class PlayerService {

    // MARK: - Playback State

    var track: Track = .empty
    var playbackState: PlaybackState = .idle
    var volume: Double = 100
    var isShuffle: Bool = false
    var repeatMode: RepeatMode = .off
    var albumArtImage: NSImage?
    /// High-resolution playback time in milliseconds, updated at ~10Hz while synced lyrics are visible.
    var currentTimeMs: Int = 0
    var currentLyricLine: String = ""

    // MARK: - Queue

    var queue: [Track] = []
    var queueIndex: Int = -1
    private var forwardSkipStack: [Int] = []

    // MARK: - Callbacks

    /// Called when playback state changes (for status bar icon updates etc.)
    var onPlaybackStateChanged: ((Bool) -> Void)?
    /// Called when the track changes (for notifications)
    var onTrackChanged: ((Track) -> Void)?
    /// Called when the synced lyric line changes (for status bar text updates).
    var onLyricLineChanged: ((String) -> Void)?

    // MARK: - Dependencies

    private let playerWebView: SingletonPlayerWebView
    var apiClient: YTMusicClient?
    private var artworkLoadTask: Task<Void, Never>?
    private var lastArtURL: URL?
    private var lyricsSyncReasons: Set<String> = []
    private var statusLyricLines: [String] = []
    private var statusLyricTimestampsMs: [Int] = []
    private let lyricDisplayLeadMs = 350

    init(playerWebView: SingletonPlayerWebView) {
        self.playerWebView = playerWebView

        playerWebView.onStateUpdate = { [weak self] state in
            self?.handleStateUpdate(state)
        }
        playerWebView.onTrackEnded = { [weak self] in
            self?.handleTrackEnded()
        }
        playerWebView.onLyricsTimeUpdate = { [weak self] time in
            self?.handleLyricsTimeUpdate(time)
        }

        restoreState()
    }

    // MARK: - Playback Controls

    func togglePlayPause() {
        playerWebView.evaluateJSFire("ytmTogglePlayPause()")
    }

    func play() {
        playerWebView.evaluateJSFire("ytmPlay()")
    }

    func pause() {
        playerWebView.evaluateJSFire("ytmPause()")
    }

    func nextTrack() {
        if queueIndex >= 0 {
            forwardSkipStack.append(queueIndex)
        }
        playerWebView.evaluateJSFire("ytmNext()")
    }

    func previousTrack() {
        if let prevIndex = forwardSkipStack.popLast() {
            queueIndex = prevIndex
        }
        playerWebView.evaluateJSFire("ytmPrevious()")
    }

    func seek(to fraction: Double) {
        let seconds = fraction * track.duration
        playerWebView.evaluateJSFire("ytmSeekTo(\(seconds))")
    }

    func setVolume(_ value: Double) {
        volume = value
        playerWebView.evaluateJSFire("ytmSetVolume(\(Int(value)))")
    }

    func toggleShuffle() {
        isShuffle.toggle()
        playerWebView.evaluateJSFire("ytmToggleShuffle()")
    }

    func cycleRepeat() {
        repeatMode = repeatMode.next
        playerWebView.evaluateJSFire("ytmCycleRepeat()")
    }

    func startLyricsSync(reason: String = "overlay") {
        let shouldStart = lyricsSyncReasons.isEmpty
        lyricsSyncReasons.insert(reason)
        if shouldStart {
            playerWebView.startLyricsPoll()
        }
    }

    func stopLyricsSync(reason: String = "overlay") {
        lyricsSyncReasons.remove(reason)
        if lyricsSyncReasons.isEmpty {
            playerWebView.stopLyricsPoll()
        }
    }

    func updateCurrentLyricLine(_ line: String) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard currentLyricLine != trimmed else { return }
        currentLyricLine = trimmed
        onLyricLineChanged?(trimmed)
    }

    func clearCurrentLyricLine() {
        updateCurrentLyricLine("")
    }

    func setStatusLyrics(_ result: LyricsResult?, for videoId: String) {
        guard videoId == track.videoId else { return }
        guard let result, result.isSynced else {
            clearStatusLyrics()
            return
        }

        let timedLines = result.lines.compactMap { line -> (String, Int)? in
            let text = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty, let startTimeMs = line.startTimeMs else { return nil }
            return (text, startTimeMs)
        }

        guard !timedLines.isEmpty else {
            clearStatusLyrics()
            return
        }

        statusLyricLines = timedLines.map(\.0)
        statusLyricTimestampsMs = timedLines.map(\.1)
        startLyricsSync(reason: "status")
        updateStatusLyricLine()
    }

    func clearStatusLyrics() {
        statusLyricLines = []
        statusLyricTimestampsMs = []
        clearCurrentLyricLine()
        stopLyricsSync(reason: "status")
    }

    func toggleLike() {
        // Click WebView button for immediate visual feedback
        playerWebView.evaluateJSFire("ytmToggleLike()")
        track.isLiked.toggle()

        // Also call API for cloud sync (ensures it persists server-side)
        let videoId = track.videoId
        let shouldLike = track.isLiked
        if !videoId.isEmpty, let apiClient = apiClient {
            Task {
                do {
                    if shouldLike {
                        try await apiClient.like(videoId: videoId)
                    } else {
                        try await apiClient.removeLike(videoId: videoId)
                    }
                } catch {
                    print("[Player] Like API error: \(error)")
                }
            }
        }
    }

    // MARK: - Play Specific Content

    func play(videoId: String) {
        playerWebView.play(videoId: videoId)
    }

    func play(searchResult: SearchResult) {
        guard let videoId = searchResult.videoId else { return }
        play(videoId: videoId)
    }

    /// Play a playlist/mix by navigating WebView to the playlist watch URL.
    func playPlaylist(id: String) {
        playerWebView.playPlaylist(id: id)
    }

    // MARK: - Queue Management

    /// Replace queue with fetched upNext tracks from YouTube Music API.
    func setQueue(_ tracks: [Track], currentIndex: Int = 0) {
        queue = tracks
        queueIndex = tracks.isEmpty ? -1 : currentIndex
        forwardSkipStack.removeAll()
    }

    func addToQueue(_ track: Track) {
        queue.append(track)
    }

    func removeFromQueue(at index: Int) {
        guard queue.indices.contains(index) else { return }
        queue.remove(at: index)
        if index < queueIndex { queueIndex -= 1 }
    }

    func moveInQueue(from: IndexSet, to: Int) {
        queue.move(fromOffsets: from, toOffset: to)
    }

    func clearQueue() {
        queue.removeAll()
        queueIndex = -1
        forwardSkipStack.removeAll()
    }

    // MARK: - State Persistence

    func saveState() {
        UserDefaults.standard.set(volume, forKey: "playerVolume")
        UserDefaults.standard.set(isShuffle, forKey: "playerShuffle")
        UserDefaults.standard.set(repeatMode.rawValue, forKey: "playerRepeat")
    }

    private func restoreState() {
        volume = UserDefaults.standard.double(forKey: "playerVolume")
        if volume == 0 { volume = 100 }
        isShuffle = UserDefaults.standard.bool(forKey: "playerShuffle")
        repeatMode = RepeatMode(rawValue: UserDefaults.standard.integer(forKey: "playerRepeat")) ?? .off
    }

    // MARK: - Private

    private func handleStateUpdate(_ state: SingletonPlayerWebView.TrackState) {
        let trackChanged = track.videoId != state.videoId
            || (track.title != state.title && !state.title.isEmpty)

        track.title = state.title
        track.artist = state.artist
        track.videoId = state.videoId
        track.albumTitle = state.albumTitle
        track.duration = state.duration
        track.currentTime = state.currentTime
        currentTimeMs = Int(state.currentTime * 1000)
        track.isLiked = state.isLiked

        if let url = URL(string: state.albumArt), !state.albumArt.isEmpty {
            track.albumArtURL = url
        }

        let newPlaybackState: PlaybackState = state.title.isEmpty ? .idle : (state.isPlaying ? .playing : .paused)
        let playbackChanged = playbackState != newPlaybackState
        playbackState = newPlaybackState

        // Notify status icon update
        if playbackChanged {
            onPlaybackStateChanged?(playbackState.isPlaying)
        }

        // Notify track change
        if trackChanged && !track.isEmpty {
            clearStatusLyrics()
            onTrackChanged?(track)
        }

        // Load album art on track change
        if trackChanged, let artURL = track.albumArtURL, artURL != lastArtURL {
            loadAlbumArt(from: artURL)
        }
    }

    private func handleTrackEnded() {
        // Auto-advance handled by YouTube Music's queue
        // We just need to track our queue index
        if queueIndex < queue.count - 1 {
            queueIndex += 1
        }
    }

    private func handleLyricsTimeUpdate(_ time: Double) {
        currentTimeMs = Int(time * 1000)
        track.currentTime = time
        updateStatusLyricLine()
    }

    private func updateStatusLyricLine() {
        guard !statusLyricLines.isEmpty, statusLyricLines.count == statusLyricTimestampsMs.count else {
            clearCurrentLyricLine()
            return
        }

        let displayTimeMs = currentTimeMs + lyricDisplayLeadMs
        guard let firstTimestamp = statusLyricTimestampsMs.first, displayTimeMs >= firstTimestamp else {
            clearCurrentLyricLine()
            return
        }

        var lo = 0, hi = statusLyricTimestampsMs.count - 1
        while lo < hi {
            let mid = (lo + hi + 1) / 2
            if statusLyricTimestampsMs[mid] <= displayTimeMs {
                lo = mid
            } else {
                hi = mid - 1
            }
        }

        updateCurrentLyricLine(statusLyricLines[lo])
    }

    private func loadAlbumArt(from url: URL) {
        lastArtURL = url
        artworkLoadTask?.cancel()
        artworkLoadTask = Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if !Task.isCancelled, let image = NSImage(data: data) {
                    self.albumArtImage = image
                }
            } catch {
                if !Task.isCancelled { self.albumArtImage = nil }
            }
        }
    }
}

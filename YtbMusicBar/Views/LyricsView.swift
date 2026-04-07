import SwiftUI

/// Lyrics overlay on album art. Current line highlighted. Tap to seek (when synced).
/// For plain lyrics (no timestamps), estimates current line from playback progress.
struct LyricsOverlay: View {
    @Environment(PlayerService.self) private var playerService
    @Environment(YTMusicClient.self) private var apiClient

    @State private var lines: [String] = []
    @State private var currentLineIndex: Int = -1
    @State private var isLoading = true
    @State private var error: String?
    @State private var source: String = ""
    @State private var lineTimestamps: [TimeInterval] = []
    @State private var isSynced = false
    private let syncedLyricsDisplayLead: TimeInterval = 0.35

    var body: some View {
        ZStack {
            // Blurred dark background
            Color.black.opacity(0.8)
                .background(.ultraThinMaterial)

            if isLoading {
                ProgressView()
                    .tint(.white)
            } else if let error {
                VStack(spacing: 6) {
                    Image(systemName: "text.quote")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.4))
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            } else {
                lyricsContent
            }
        }
        .task {
            await loadLyrics()
        }
        .onChange(of: playerService.track.videoId) {
            Task { await loadLyrics() }
        }
        .onChange(of: isSynced) { _, synced in
            synced ? playerService.startLyricsSync() : playerService.stopLyricsSync()
        }
        .onAppear {
            if isSynced {
                playerService.startLyricsSync()
                updateCurrentLine()
            }
        }
        .onDisappear {
            playerService.stopLyricsSync()
        }
    }

    // MARK: - Lyrics Content

    private var lyricsContent: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    Spacer(minLength: 30)

                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        lyricLine(line, index: index)
                            .id(index)
                    }

                    if !source.isEmpty {
                        Text(source)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.2))
                            .padding(.top, 8)
                    }

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 12)
            }
            .onChange(of: currentLineIndex) { _, newIndex in
                guard newIndex >= 0 else { return }
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
            .onChange(of: playerService.currentTimeMs) { _, _ in
                if isSynced {
                    updateCurrentLine()
                }
            }
            .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
                if !isSynced {
                    updateCurrentLine()
                }
            }
        }
    }

    private func lyricLine(_ text: String, index: Int) -> some View {
        let isCurrent = index == currentLineIndex
        let distance = abs(index - currentLineIndex)
        let opacity = isCurrent ? 1.0 : max(0.15, 1.0 - Double(distance) * 0.2)

        return Button {
            if isSynced { seekToLine(index) }
        } label: {
            Text(text.isEmpty ? " " : text)
                .font(isCurrent ? .callout.bold() : .caption)
                .foregroundStyle(.white.opacity(opacity))
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    // MARK: - Logic

    private func updateCurrentLine() {
        guard !lines.isEmpty else { return }

        let newIndex: Int
        if isSynced && !lineTimestamps.isEmpty {
            // Synced: binary search on timestamps
            let currentTime = (Double(playerService.currentTimeMs) / 1000.0) + syncedLyricsDisplayLead
            if let firstTimestamp = lineTimestamps.first, currentTime < firstTimestamp {
                newIndex = -1
            } else {
                var lo = 0, hi = lineTimestamps.count - 1
                while lo < hi {
                    let mid = (lo + hi + 1) / 2
                    if lineTimestamps[mid] <= currentTime { lo = mid } else { hi = mid - 1 }
                }
                newIndex = lo
            }
        } else {
            // Plain lyrics: estimate from playback progress
            let progress = playerService.track.progress
            newIndex = min(Int(progress * Double(lines.count)), lines.count - 1)
        }

        if newIndex != currentLineIndex {
            currentLineIndex = newIndex
        }
    }

    private func seekToLine(_ index: Int) {
        guard index < lineTimestamps.count else { return }
        let time = lineTimestamps[index]
        let duration = playerService.track.duration
        guard duration > 0 else { return }
        playerService.seek(to: time / duration)
    }

    private func loadLyrics() async {
        let videoId = playerService.track.videoId
        isLoading = true
        lines = []
        lineTimestamps = []
        currentLineIndex = -1
        isSynced = false
        error = nil
        source = ""

        guard !videoId.isEmpty else {
            error = "No track"
            isLoading = false
            return
        }

        defer { isLoading = false }

        do {
            if let result = try await apiClient.lyrics(videoId: videoId) {
                let parsed = result.lines.map(\.text).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                source = result.source

                if parsed.isEmpty {
                    error = "No lyrics available"
                    return
                }
                lines = parsed

                // Check for timed lyrics
                let timestamps = result.lines
                    .filter { !$0.text.trimmingCharacters(in: .whitespaces).isEmpty }
                    .compactMap(\.startTimeMs)
                    .map { Double($0) / 1000.0 }

                if timestamps.count == parsed.count && !timestamps.isEmpty {
                    lineTimestamps = timestamps
                    isSynced = true
                    updateCurrentLine()
                }
            } else {
                error = "No lyrics available"
            }
        } catch {
            self.error = "Failed to load lyrics"
        }
    }
}

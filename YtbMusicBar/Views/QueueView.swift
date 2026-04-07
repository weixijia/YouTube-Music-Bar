import SwiftUI

struct QueueView: View {
    @Environment(PlayerService.self) private var playerService
    @Environment(YTMusicClient.self) private var apiClient

    @State private var upNextTracks: [Track] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Queue")
                    .font(.headline)
                Spacer()
                if !upNextTracks.isEmpty {
                    Text("\(upNextTracks.count) tracks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)

            Divider()

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage {
                queueStateView(icon: "exclamationmark.triangle", title: errorMessage, buttonTitle: "Try Again") {
                    Task { await loadQueue() }
                }
            } else if upNextTracks.isEmpty && playerService.track.isEmpty {
                queueStateView(icon: "list.bullet", title: "Play something to see the queue")
            } else if upNextTracks.isEmpty {
                queueStateView(icon: "list.bullet", title: "Queue is empty")
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        // Current track
                        if !playerService.track.isEmpty {
                            HStack(spacing: 10) {
                                CachedAsyncImage(url: playerService.track.albumArtURL, cornerRadius: 6)
                                    .frame(width: 44, height: 44)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(playerService.track.title)
                                        .font(.callout.bold())
                                        .lineLimit(1)
                                    Text(playerService.track.artist)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                SongRowView.EqualizerView()
                                    .frame(width: 16, height: 16)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                            .padding(.horizontal, 8)

                            if !upNextTracks.isEmpty {
                                HStack {
                                    Text("Up Next")
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                            }
                        }

                        // Up next tracks
                        ForEach(Array(upNextTracks.enumerated()), id: \.element.id) { index, track in
                            QueueTrackRow(track: track, index: index + 1) {
                                playerService.play(
                                    videoId: track.videoId,
                                    playlistId: playerService.playbackContext?.playlistId,
                                    browseId: playerService.playbackContext?.browseId,
                                    source: .queue,
                                    resultType: playerService.playbackContext?.resultType
                                )
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .task(id: queueTaskID) {
            await loadQueue()
        }
    }

    private var queueTaskID: String {
        [playerService.queueRequestVideoId, playerService.playbackContext?.taskID ?? ""].joined(separator: "|")
    }

    private func loadQueue() async {
        let videoId = playerService.queueRequestVideoId
        guard !videoId.isEmpty else {
            upNextTracks = []
            return
        }

        isLoading = upNextTracks.isEmpty
        errorMessage = nil
        defer { isLoading = false }

        do {
            let tracks = try await apiClient.upNext(videoId: videoId, playlistId: playerService.playbackContext?.playlistId)
            // Filter out current track
            upNextTracks = tracks.filter { $0.videoId != videoId }
            // Sync to PlayerService queue
            playerService.setQueue(tracks)
            errorMessage = nil
        } catch {
            upNextTracks = []
            errorMessage = error.userFacingMessage
            print("[Queue] Error: \(error)")
        }
    }

    private func queueStateView(icon: String, title: String, buttonTitle: String? = nil, action: (() -> Void)? = nil) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            if let buttonTitle, let action {
                Button(buttonTitle, action: action)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Queue Track Row

struct QueueTrackRow: View {
    let track: Track
    let index: Int
    let onTap: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Text("\(index)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(width: 20)

                CachedAsyncImage(url: track.albumArtURL, cornerRadius: 4)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.callout)
                        .lineLimit(1)
                    Text(track.artist)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isHovering ? Color.primary.opacity(0.06) : .clear, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .padding(.horizontal, 8)
    }
}

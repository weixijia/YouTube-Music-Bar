import SwiftUI

struct QueueView: View {
    @Environment(PlayerService.self) private var playerService
    @Environment(YTMusicClient.self) private var apiClient

    @State private var upNextTracks: [Track] = []
    @State private var isLoading = false

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
            } else if upNextTracks.isEmpty && playerService.track.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("Play something to see the queue")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if upNextTracks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("Queue is empty")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                                playerService.play(videoId: track.videoId)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .task(id: playerService.track.videoId) {
            await loadQueue()
        }
    }

    private func loadQueue() async {
        let videoId = playerService.track.videoId
        guard !videoId.isEmpty else {
            upNextTracks = []
            return
        }

        isLoading = upNextTracks.isEmpty
        defer { isLoading = false }

        do {
            let tracks = try await apiClient.upNext(videoId: videoId)
            // Filter out current track
            upNextTracks = tracks.filter { $0.videoId != videoId }
            // Sync to PlayerService queue
            playerService.setQueue(tracks)
        } catch {
            print("[Queue] Error: \(error)")
        }
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

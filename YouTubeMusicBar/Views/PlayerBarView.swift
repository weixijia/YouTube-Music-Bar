import SwiftUI

/// Bottom-pinned playback control bar with Liquid Glass styling.
struct PlayerBarView: View {
    @Environment(PlayerService.self) private var player
    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 6) {
            // Mini progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.quaternary).frame(height: 3)
                    Capsule().fill(.primary).frame(width: geo.size.width * player.track.progress, height: 3)
                }
            }
            .frame(height: 3)
            .padding(.horizontal, 12)

            HStack(spacing: 12) {
                // Track info (left)
                HStack(spacing: 8) {
                    CachedAsyncImage(url: player.track.albumArtURL, cornerRadius: 4)
                        .aspectRatio(1, contentMode: .fill)
                        .frame(width: 36, height: 36)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    VStack(alignment: .leading, spacing: 1) {
                        Text(player.track.title)
                            .font(.caption.bold())
                            .lineLimit(1)
                        Text(player.track.artist)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: 120, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Controls (center)
                HStack(spacing: 16) {
                    Button { player.previousTrack() } label: {
                        Image(systemName: "backward.fill").font(.caption)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Previous")

                    Button { player.togglePlayPause() } label: {
                        Image(systemName: player.playbackState.systemImageName)
                            .font(.body.bold())
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(player.playbackState.isPlaying ? "Pause" : "Play")

                    Button { player.nextTrack() } label: {
                        Image(systemName: "forward.fill").font(.caption)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Next")
                }
                .glassControlBar()

                // Right controls
                HStack(spacing: 8) {
                    // Like
                    Button { player.toggleLike() } label: {
                        Image(systemName: player.track.isLiked ? "heart.fill" : "heart")
                            .font(.caption)
                            .foregroundStyle(player.track.isLiked ? .red : .secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(player.track.isLiked ? "Unlike" : "Like")

                    // Volume
                    VolumePopoverButton(volume: player.volume) { newVolume in
                        player.setVolume(newVolume)
                    }
                }
                .frame(width: 60, alignment: .trailing)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 6)
        }
        .padding(.top, 4)
    }
}

// MARK: - Volume Popover Button

struct VolumePopoverButton: View {
    var volume: Double
    var onChange: (Double) -> Void
    @State private var showPopover = false

    var body: some View {
        Button { showPopover.toggle() } label: {
            Image(systemName: volumeIcon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 18, height: 18) // Fixed frame prevents layout jumping
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showPopover) {
            Slider(value: Binding(
                get: { volume },
                set: { onChange($0) }
            ), in: 0...100)
            .frame(width: 120)
            .padding(10)
        }
    }

    private var volumeIcon: String {
        switch volume {
        case 0: return "speaker.slash.fill"
        case 1...33: return "speaker.wave.1.fill"
        case 34...66: return "speaker.wave.2.fill"
        default: return "speaker.wave.3.fill"
        }
    }
}

// MARK: - Glass Control Bar Modifier

extension View {
    @ViewBuilder
    func glassControlBar() -> some View {
        if #available(macOS 26, *) {
            self.padding(.horizontal, 12)
                .padding(.vertical, 6)
                .glassEffect(.regular.interactive(), in: .capsule)
        } else {
            self.padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }
}

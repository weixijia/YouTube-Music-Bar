import SwiftUI
import AVKit

/// Now Playing view — Apple Music inspired layout.
/// Album art centered at ~55% height, controls below with breathing room.
struct NowPlayingView: View {
    @Environment(PlayerService.self) private var playerService
    @State private var showLyrics = false
    @State private var showVolumeSlider = false

    var body: some View {
        let track = playerService.track

        if !track.isEmpty {
            playerContent(track)
        } else {
            idleContent
        }
    }

    // MARK: - Player Content

    @ViewBuilder
    private func playerContent(_ track: Track) -> some View {
        GeometryReader { geo in
            let artSize = min(geo.size.width - 80, 200) // Max 200, with 40px margin each side

            VStack(spacing: 0) {
                Spacer(minLength: 8)

                // Album Art — centered, not full-width
                ZStack {
                    CachedAsyncImage(url: track.albumArtURL, cornerRadius: 10)
                        .aspectRatio(1, contentMode: .fill)
                        .frame(width: artSize, height: artSize)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 4)

                    if showLyrics {
                        LyricsOverlay()
                            .frame(width: artSize, height: artSize)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: showLyrics)

                Spacer(minLength: 12).frame(maxHeight: 16)

                // Track Info
                VStack(spacing: 3) {
                    Text(track.title)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)
                    Text(track.artist)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 32)

                Spacer(minLength: 8).frame(maxHeight: 12)

                // Progress Bar
                ProgressBarView(track: track) { fraction in
                    playerService.seek(to: fraction)
                }
                .padding(.horizontal, 28)

                Spacer(minLength: 4).frame(maxHeight: 8)

                // Main Controls
                HStack(spacing: 28) {
                    Button { playerService.previousTrack() } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 20))
                    }
                    .buttonStyle(.plain)

                    Button { playerService.togglePlayPause() } label: {
                        Image(systemName: playerService.playbackState.systemImageName)
                            .font(.system(size: 34))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)

                    Button { playerService.nextTrack() } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 20))
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 4).frame(maxHeight: 8)

                // Secondary Controls
                HStack(spacing: 18) {
                    Button { playerService.toggleShuffle() } label: {
                        Image(systemName: "shuffle")
                            .foregroundStyle(playerService.isShuffle ? Color.accentColor : .secondary)
                    }
                    .buttonStyle(.plain)

                    Button { playerService.toggleLike() } label: {
                        Image(systemName: playerService.track.isLiked ? "heart.fill" : "heart")
                            .foregroundStyle(playerService.track.isLiked ? .red : .secondary)
                    }
                    .buttonStyle(.plain)

                    Button { showLyrics.toggle() } label: {
                        Image(systemName: "quote.bubble")
                            .foregroundStyle(showLyrics ? Color.accentColor : .secondary)
                    }
                    .buttonStyle(.plain)

                    Button { showVolumeSlider.toggle() } label: {
                        Image(systemName: volumeIcon)
                            .foregroundStyle(.secondary)
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showVolumeSlider) {
                        Slider(value: Binding(
                            get: { playerService.volume },
                            set: { playerService.setVolume($0) }
                        ), in: 0...100)
                        .frame(width: 120)
                        .padding(10)
                    }

                    Button { playerService.cycleRepeat() } label: {
                        Image(systemName: playerService.repeatMode.systemImageName)
                            .foregroundStyle(playerService.repeatMode != .off ? Color.accentColor : .secondary)
                    }
                    .buttonStyle(.plain)

                    RoutePickerRepresentable()
                        .frame(width: 20, height: 20)
                }
                .font(.system(size: 14))

                Spacer(minLength: 8)
            }
        }
    }

    private var volumeIcon: String {
        switch playerService.volume {
        case 0: return "speaker.slash.fill"
        case 1...33: return "speaker.wave.1.fill"
        case 34...66: return "speaker.wave.2.fill"
        default: return "speaker.wave.3.fill"
        }
    }

    // MARK: - Idle

    private var idleContent: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "music.note")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("Nothing playing")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Play a song from Home or Search")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - AVRoutePickerView wrapper

struct RoutePickerRepresentable: NSViewRepresentable {
    func makeNSView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.isRoutePickerButtonBordered = false
        if let button = picker.subviews.first(where: { $0 is NSButton }) as? NSButton {
            button.image = NSImage(systemSymbolName: "airplayaudio", accessibilityDescription: "Audio Output")
            button.contentTintColor = .secondaryLabelColor
        }
        return picker
    }

    func updateNSView(_ nsView: AVRoutePickerView, context: Context) {}
}

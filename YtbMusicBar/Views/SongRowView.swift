import SwiftUI

/// A consistent song row: thumbnail + title/artist + duration + play icon.
struct SongRowView: View {
    let title: String
    let subtitle: String
    var thumbnailURL: URL?
    var duration: String?
    var isPlaying: Bool = false
    var onTap: (() -> Void)?

    @State private var isHovered = false

    /// Convenience init from Track
    init(track: Track, isNowPlaying: Bool = false, onTap: (() -> Void)? = nil) {
        self.title = track.title
        self.subtitle = track.artist
        self.thumbnailURL = track.albumArtURL
        self.duration = track.formattedDuration
        self.isPlaying = isNowPlaying
        self.onTap = onTap
    }

    init(title: String, subtitle: String, thumbnailURL: URL? = nil, duration: String? = nil, isPlaying: Bool = false, onTap: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.thumbnailURL = thumbnailURL
        self.duration = duration
        self.isPlaying = isPlaying
        self.onTap = onTap
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 12) {
                CachedAsyncImage(url: thumbnailURL, cornerRadius: 6)
                    .frame(width: 48, height: 48)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)
                        .foregroundStyle(isPlaying ? Color.accentColor : .primary)

                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if let duration {
                    Text(duration)
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }

                if isHovered && !isPlaying {
                    Image(systemName: "play.circle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }

                if isPlaying {
                    EqualizerView()
                        .frame(width: 16, height: 16)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background(isHovered ? Color.primary.opacity(0.06) : .clear, in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    /// Animated equalizer bars for the "now playing" indicator.
    struct EqualizerView: View {
        @State private var isAnimating = false

        var body: some View {
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.accentColor)
                        .frame(width: 3)
                        .frame(height: isAnimating ? CGFloat.random(in: 4...14) : 4)
                        .animation(
                            .easeInOut(duration: Double.random(in: 0.3...0.6))
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.1),
                            value: isAnimating
                        )
                }
            }
            .onAppear { isAnimating = true }
        }
    }
}

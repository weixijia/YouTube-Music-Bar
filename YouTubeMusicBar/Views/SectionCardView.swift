import SwiftUI

/// A 140x140 card for horizontal browse sections (like kaset's HomeSectionItemCard).
struct SectionCardView: View {
    let title: String
    var subtitle: String?
    var thumbnailURL: URL?
    var onTap: (() -> Void)?

    @State private var isHovered = false

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                // Thumbnail
                CachedAsyncImage(url: thumbnailURL, cornerRadius: 8)
                    .frame(width: 140, height: 140)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        if isHovered {
                            ZStack {
                                Color.black.opacity(0.3)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                Image(systemName: "play.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundStyle(.white)
                            }
                            .transition(.opacity)
                        }
                    }

                // Title
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(2)

                // Subtitle
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(width: 140)
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

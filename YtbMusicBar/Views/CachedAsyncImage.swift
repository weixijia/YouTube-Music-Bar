import SwiftUI

/// A simple async image view with in-memory caching.
struct CachedAsyncImage: View {
    let url: URL?
    var cornerRadius: CGFloat = 8

    @State private var image: NSImage?
    @State private var isLoading = false

    private static var cache: [URL: NSImage] = [:]

    static func clearCache() {
        cache.removeAll()
    }

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(.quaternary)
                    .overlay {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.5)
                        } else {
                            Image(systemName: "music.note")
                                .font(.title2)
                                .foregroundStyle(.tertiary)
                        }
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .task(id: url) {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let url else {
            image = nil
            return
        }

        // Check cache
        if let cached = Self.cache[url] {
            image = cached
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let nsImage = NSImage(data: data) {
                Self.cache[url] = nsImage
                withAnimation(.easeIn(duration: 0.2)) {
                    image = nsImage
                }
            }
        } catch {
            image = nil
        }
    }
}

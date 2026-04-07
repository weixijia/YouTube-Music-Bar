import AppKit

/// Provides macOS native share functionality for YouTube Music content.
@MainActor
final class ShareService {

    static func shareURL(for track: Track, from view: NSView) {
        guard !track.videoId.isEmpty else { return }
        let url = URL(string: "https://music.youtube.com/watch?v=\(track.videoId)")!
        let text = "\(track.title) - \(track.artist)"

        let picker = NSSharingServicePicker(items: [url, text])
        picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
    }

    static func copyLink(for track: Track) {
        guard !track.videoId.isEmpty else { return }
        let url = "https://music.youtube.com/watch?v=\(track.videoId)"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url, forType: .string)
    }
}

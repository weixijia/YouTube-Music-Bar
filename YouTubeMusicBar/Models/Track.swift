import Foundation

struct Track: Equatable, Sendable, Identifiable {
    var id: String { videoId.isEmpty ? title + artist : videoId }

    var videoId: String = ""
    var title: String = ""
    var artist: String = ""
    var albumTitle: String = ""
    var albumArtURL: URL?
    var duration: TimeInterval = 0
    var currentTime: TimeInterval = 0
    var isLiked: Bool = false
    var isDisliked: Bool = false

    var progress: Double {
        guard duration > 0, duration.isFinite, !currentTime.isNaN, currentTime.isFinite else { return 0 }
        let fraction = currentTime / duration
        if fraction.isNaN || !fraction.isFinite { return 0 }
        return max(0, min(1, fraction))
    }

    var formattedCurrentTime: String { formatTime(currentTime) }
    var formattedDuration: String { formatTime(duration) }
    var isEmpty: Bool { title.isEmpty }

    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite, !time.isNaN else { return "0:00" }
        let totalSeconds = max(0, Int(time))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    static let empty = Track()
}

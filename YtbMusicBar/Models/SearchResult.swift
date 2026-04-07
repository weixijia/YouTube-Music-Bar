import Foundation

struct SearchResult: Identifiable, Equatable {
    var id: String { videoId ?? title + subtitle }

    var title: String
    var subtitle: String = ""
    var videoId: String?
    var thumbnailURL: URL?
    var resultType: ResultType = .song

    enum ResultType: String, Equatable {
        case song
        case album
        case artist
        case playlist
        case other
    }
}

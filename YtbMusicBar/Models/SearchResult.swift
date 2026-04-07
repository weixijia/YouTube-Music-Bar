import Foundation

struct SearchResult: Identifiable, Equatable {
    var id: String { videoId ?? playlistId ?? browseId ?? title + subtitle }

    var title: String
    var subtitle: String = ""
    var videoId: String?
    var playlistId: String?
    var browseId: String?
    var thumbnailURL: URL?
    var resultType: ResultType = .song

    enum ResultType: String, Equatable, Sendable {
        case song
        case album
        case artist
        case playlist
        case other
    }
}

struct PlaybackContext: Equatable, Sendable {
    enum Source: String, Equatable, Sendable {
        case search
        case home
        case queue
        case collection
        case web
    }

    var source: Source
    var videoId: String?
    var playlistId: String?
    var browseId: String?
    var resultType: SearchResult.ResultType?

    var taskID: String {
        [videoId ?? "", playlistId ?? "", browseId ?? ""].joined(separator: "|")
    }
}

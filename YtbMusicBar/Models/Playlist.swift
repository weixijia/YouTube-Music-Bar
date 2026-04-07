import Foundation

struct Playlist: Identifiable, Equatable {
    var id: String
    var title: String
    var description: String = ""
    var thumbnailURL: URL?
    var songCount: Int = 0
}

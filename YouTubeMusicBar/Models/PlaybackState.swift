import Foundation

enum PlaybackState: Equatable, Sendable {
    case idle
    case loading
    case playing
    case paused

    var isPlaying: Bool { self == .playing }

    var systemImageName: String {
        switch self {
        case .idle, .loading: return "play.fill"
        case .playing: return "pause.fill"
        case .paused: return "play.fill"
        }
    }
}

enum RepeatMode: Int, Sendable {
    case off = 0
    case all = 1
    case one = 2

    var systemImageName: String {
        switch self {
        case .off: return "repeat"
        case .all: return "repeat"
        case .one: return "repeat.1"
        }
    }

    var next: RepeatMode {
        RepeatMode(rawValue: (rawValue + 1) % 3) ?? .off
    }
}

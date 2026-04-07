import Foundation

/// Manages like/unlike/dislike state for tracks via the YouTube Music API.
@MainActor @Observable
final class FavoritesManager {

    private var apiClient: YTMusicClient?

    func configure(apiClient: YTMusicClient) {
        self.apiClient = apiClient
    }

    func like(videoId: String) async throws {
        try await apiClient?.like(videoId: videoId)
    }

    func removeLike(videoId: String) async throws {
        try await apiClient?.removeLike(videoId: videoId)
    }

    func dislike(videoId: String) async throws {
        try await apiClient?.dislike(videoId: videoId)
    }

    func toggleLike(videoId: String, currentlyLiked: Bool) async throws {
        if currentlyLiked {
            try await removeLike(videoId: videoId)
        } else {
            try await like(videoId: videoId)
        }
    }
}

import Foundation
import CryptoKit

/// Direct YouTube Music API client using SAPISIDHASH authentication.
/// Bypasses WebView for data operations (search, browse, like, lyrics).
@MainActor @Observable
final class YTMusicClient {

    private let webKitManager: WebKitManager
    private let authService: AuthService
    private let cache = APICache()
    private let session: URLSession

    /// Continuation token for liked songs pagination (kaset pattern)
    var likedSongsContinuationToken: String?

    private let baseURL = URL(string: "https://music.youtube.com/youtubei/v1")!
    private let apiKey = "AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30"
    private static let clientVersion = "1.20231204.01.00"

    // Client context matching kaset's exact format
    private var clientContext: [String: Any] {
        [
            "client": [
                "clientName": "WEB_REMIX",
                "clientVersion": Self.clientVersion,
                "hl": "en",
                "gl": "US",
                "experimentIds": [] as [String],
                "experimentsToken": "",
                "browserName": "Safari",
                "browserVersion": "17.0",
                "osName": "Macintosh",
                "osVersion": "10_15_7",
                "platform": "DESKTOP",
                "userAgent": Constants.safariUserAgent,
                "utcOffsetMinutes": -TimeZone.current.secondsFromGMT() / 60,
            ] as [String: Any],
            "user": [
                "lockedSafetyMode": false,
            ] as [String: Any],
        ]
    }

    var hasSapisid: Bool { webKitManager.sapisid != nil }

    init(webKitManager: WebKitManager, authService: AuthService) {
        self.webKitManager = webKitManager
        self.authService = authService
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 10_000_000, diskCapacity: 50_000_000)
        self.session = URLSession(configuration: config)
    }

    // MARK: - Search

    func search(query: String, filter: SearchFilter = .all) async throws -> [SearchResult] {
        let cacheKey = "search:\(query):\(filter.rawValue)"
        if let cached: [SearchResult] = cache.get(cacheKey) { return cached }

        var params: [String: Any] = ["query": query]
        if let filterParam = filter.param {
            params["params"] = filterParam
        }

        let data = try await apiRequest(endpoint: "search", params: params)
        let results = SearchResponseParser.parse(data)
        cache.set(cacheKey, value: results, ttl: 300)
        return results
    }

    // MARK: - Browse

    func browse(id: String) async throws -> BrowseResponse {
        let cacheKey = "browse:\(id)"
        if let cached: BrowseResponse = cache.get(cacheKey) { return cached }

        let data = try await apiRequest(endpoint: "browse", params: ["browseId": id])
        let response = BrowseResponseParser.parse(data)
        cache.set(cacheKey, value: response, ttl: 3600)
        return response
    }

    // MARK: - Library (kaset exact pattern)

    /// Get user's saved playlists. Uses dedicated library parser (not browse parser).
    func getLibraryPlaylists() async throws -> [LibraryPlaylist] {
        // Try FEmusic_liked_playlists first, fall back to FEmusic_library_landing (kaset uses both)
        let data = try await apiRequest(endpoint: "browse", params: ["browseId": "FEmusic_liked_playlists"])
        var result = LibraryParser.parsePlaylists(data)

        if result.isEmpty {
            // Fallback: library landing page has more content
            let landingData = try await apiRequest(endpoint: "browse", params: ["browseId": "FEmusic_library_landing"])
            result = LibraryParser.parsePlaylists(landingData)
        }

        return result
    }

    // MARK: - Playlist / Album Details

    func playlistDetails(id: String) async throws -> PlaylistDetail {
        let cacheKey = "playlist:\(id)"
        if let cached: PlaylistDetail = cache.get(cacheKey) { return cached }

        let data = try await apiRequest(endpoint: "browse", params: ["browseId": id])
        let detail = PlaylistParser.parse(data)
        cache.set(cacheKey, value: detail, ttl: 600)
        return detail
    }

    // MARK: - Like / Dislike

    func like(videoId: String) async throws {
        _ = try await apiRequest(endpoint: "like/like", params: [
            "target": ["videoId": videoId]
        ])
    }

    func removeLike(videoId: String) async throws {
        _ = try await apiRequest(endpoint: "like/removelike", params: [
            "target": ["videoId": videoId]
        ])
    }

    func dislike(videoId: String) async throws {
        _ = try await apiRequest(endpoint: "like/dislike", params: [
            "target": ["videoId": videoId]
        ])
    }

    // MARK: - Lyrics

    /// Fetch lyrics for a video. Matches kaset's two-step approach:
    /// 1. Try synced/timed lyrics from the "next" response (timedLyricsModel)
    /// 2. Fall back to plain lyrics via browse endpoint
    func lyrics(videoId: String) async throws -> LyricsResult? {
        let nextData = try await apiRequest(endpoint: "next", params: [
            "videoId": videoId,
            "isAudioOnly": true,
            "enablePersistentPlaylistPanel": true,
            "tunerSettingValue": "AUTOMIX_SETTING_NORMAL",
        ])

        // Step 1: Try timed lyrics (embedded in next response)
        if let synced = LyricsParser.extractTimedLyrics(from: nextData) {
            return synced
        }

        // Step 2: Fall back to plain lyrics via browse
        guard let browseId = LyricsParser.extractBrowseId(from: nextData) else { return nil }
        let lyricsData = try await apiRequest(endpoint: "browse", params: ["browseId": browseId])
        return LyricsParser.parse(lyricsData)
    }

    /// Fetch synced lyrics using kaset's order: YouTube Music first, LRCLib as fallback.
    func lyricsWithFallback(for track: Track) async throws -> LyricsResult? {
        guard !track.videoId.isEmpty else { return nil }

        let ytMusicResult = try await lyrics(videoId: track.videoId)
        if ytMusicResult?.isSynced == true {
            return ytMusicResult
        }

        if let lrcResult = await searchLRCLib(for: track),
           lrcResult.isSynced || ytMusicResult == nil {
            return lrcResult
        }

        return ytMusicResult
    }

    private func searchLRCLib(for track: Track) async -> LyricsResult? {
        guard !track.title.isEmpty, !track.artist.isEmpty else { return nil }

        var components = URLComponents(string: "https://lrclib.net/api/search")
        components?.queryItems = [
            URLQueryItem(name: "track_name", value: track.title),
            URLQueryItem(name: "artist_name", value: track.artist),
        ]

        guard let url = components?.url else { return nil }

        var request = URLRequest(url: url)
        request.setValue("Kaset/1.0", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }

            let results = try JSONDecoder().decode([LRCLibModel].self, from: data)
            let validResults = results.filter {
                (($0.syncedLyrics?.isEmpty == false) || ($0.plainLyrics?.isEmpty == false)) &&
                    ($0.instrumental == false || $0.instrumental == nil)
            }
            guard !validResults.isEmpty else { return nil }

            let bestMatch: LRCLibModel
            if track.duration > 0 {
                bestMatch = validResults.min { a, b in
                    abs((a.duration ?? 0) - track.duration) < abs((b.duration ?? 0) - track.duration)
                } ?? validResults[0]
            } else {
                bestMatch = validResults[0]
            }

            if let synced = bestMatch.syncedLyrics,
               let parsed = LRCParser.parse(synced, source: "LRCLib") {
                return parsed
            }

            if let plain = bestMatch.plainLyrics, !plain.isEmpty {
                let lines = plain.components(separatedBy: "\n").map { LyricsLine(text: $0) }
                return LyricsResult(lines: lines, isSynced: false, source: "Source: LRCLib")
            }

            return nil
        } catch {
            return nil
        }
    }

    // MARK: - Liked Songs (kaset exact pattern: VLLM + continuation)

    func getLikedSongs() async throws -> ([Track], String?) {
        let data = try await apiRequest(endpoint: "browse", params: ["browseId": "VLLM"])
        let detail = PlaylistParser.parse(data)
        let token = PlaylistParser.extractContinuationToken(from: data)
        likedSongsContinuationToken = token
        return (detail.tracks, token)
    }

    func getLikedSongsContinuation() async throws -> ([Track], String?) {
        guard let token = likedSongsContinuationToken else { return ([], nil) }
        let data = try await apiRequest(endpoint: "browse", params: ["continuation": token])
        let tracks = PlaylistParser.parseContinuation(data)
        let nextToken = PlaylistParser.extractContinuationTokenFromContinuation(data)
        likedSongsContinuationToken = nextToken
        return (tracks, nextToken)
    }

    // MARK: - Queue / Up Next

    func upNext(videoId: String, playlistId: String? = nil) async throws -> [Track] {
        var params: [String: Any] = [
            "videoId": videoId,
            "enablePersistentPlaylistPanel": true,
            "isAudioOnly": true,
        ]
        if let playlistId {
            params["playlistId"] = playlistId
        }
        let data = try await apiRequest(endpoint: "next", params: params)
        return UpNextParser.parse(data)
    }

    // MARK: - API Request

    private func apiRequest(endpoint: String, params: [String: Any]) async throws -> [String: Any] {
        let url = baseURL.appendingPathComponent(endpoint)
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { throw YTMusicError.requestFailed }
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "prettyPrint", value: "false"),
        ]

        guard let componentsUrl = components.url else { throw YTMusicError.requestFailed }
        var request = URLRequest(url: componentsUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Constants.safariUserAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("https://music.youtube.com", forHTTPHeaderField: "Referer")
        request.setValue("https://music.youtube.com", forHTTPHeaderField: "Origin")
        request.setValue("https://music.youtube.com", forHTTPHeaderField: "X-Origin")
        request.setValue("0", forHTTPHeaderField: "X-Goog-AuthUser")

        // Full cookie + SAPISIDHASH authentication (kaset pattern: send matching cookies)
        guard let authHeaders = await webKitManager.currentAuthHeaders() else {
            authService.sessionExpired()
            throw YTMusicError.authExpired
        }

        let sapisid = authHeaders.sapisid
        let hash = generateSAPISIDHash(sapisid: sapisid)
        request.setValue("SAPISIDHASH \(hash)", forHTTPHeaderField: "Authorization")
        if let cookieHeader = authHeaders.cookieHeader {
            request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        } else {
            request.setValue("SAPISID=\(sapisid)", forHTTPHeaderField: "Cookie")
        }

        // Build body
        var body = params
        body["context"] = clientContext

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw YTMusicError.requestFailed
        }

        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            authService.sessionExpired()
            throw YTMusicError.authExpired
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw YTMusicError.requestFailed
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw YTMusicError.parseFailed
        }

        return json
    }

    /// Generate SAPISIDHASH for authenticated API requests.
    /// Format: {timestamp}_{SHA1(timestamp + " " + sapisid + " " + origin)}
    private func generateSAPISIDHash(sapisid: String) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let origin = "https://music.youtube.com"
        let input = "\(timestamp) \(sapisid) \(origin)"
        let hash = Insecure.SHA1.hash(data: Data(input.utf8))
        let hashString = hash.map { String(format: "%02x", $0) }.joined()
        return "\(timestamp)_\(hashString)"
    }
}

private struct LRCLibModel: Decodable {
    let id: Int
    let trackName: String?
    let artistName: String?
    let albumName: String?
    let duration: TimeInterval?
    let instrumental: Bool?
    let plainLyrics: String?
    let syncedLyrics: String?
}

// MARK: - Error Types

enum YTMusicError: Error, LocalizedError {
    case requestFailed
    case parseFailed
    case authExpired
    case notFound

    var errorDescription: String? {
        switch self {
        case .requestFailed: return "API request failed"
        case .parseFailed: return "Failed to parse response"
        case .authExpired: return "Authentication expired"
        case .notFound: return "Content not found"
        }
    }

    var userFacingMessage: String {
        switch self {
        case .authExpired:
            return "Your session expired. Sign in again to keep listening."
        case .requestFailed:
            return "Couldn't reach YouTube Music. Check your connection and try again."
        case .parseFailed:
            return "YouTube Music returned something unexpected. Try again."
        case .notFound:
            return "That content is no longer available."
        }
    }
}

extension Error {
    var userFacingMessage: String {
        if let ytMusicError = self as? YTMusicError {
            return ytMusicError.userFacingMessage
        }

        if let urlError = self as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .timedOut:
                return "You're offline. Reconnect and try again."
            default:
                return "Couldn't reach YouTube Music. Check your connection and try again."
            }
        }

        return "Something went wrong. Try again."
    }
}

// MARK: - Search Filter

enum SearchFilter: String {
    case all
    case songs
    case albums
    case artists
    case playlists

    var param: String? {
        switch self {
        case .all: return nil
        case .songs: return "EgWKAQIIAWoMEAMQBBAJEA4QChAF"
        case .albums: return "EgWKAQIYAWoMEAMQBBAJEA4QChAF"
        case .artists: return "EgWKAQIgAWoMEAMQBBAJEA4QChAF"
        case .playlists: return "EgWKAQIoAWoMEAMQBBAJEA4QChAF"
        }
    }
}

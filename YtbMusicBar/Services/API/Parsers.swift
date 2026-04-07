import Foundation

// MARK: - Search Response Parser

enum SearchResponseParser {
    static func parse(_ json: [String: Any]) -> [SearchResult] {
        var results: [SearchResult] = []

        guard let contents = json.dig("contents", "tabbedSearchResultsRenderer", "tabs") as? [[String: Any]],
              let firstTab = contents.first,
              let sections = firstTab.dig("tabRenderer", "content", "sectionListRenderer", "contents") as? [[String: Any]]
        else { return results }

        for section in sections {
            guard let items = section.dig("musicShelfRenderer", "contents") as? [[String: Any]] else { continue }

            for item in items {
                guard let flexColumns = item.dig("musicResponsiveListItemRenderer", "flexColumns") as? [[String: Any]]
                else { continue }

                let title = extractText(from: flexColumns, index: 0)
                let subtitle = extractText(from: flexColumns, index: 1)
                let videoId = item.dig("musicResponsiveListItemRenderer", "overlay",
                                       "musicItemThumbnailOverlayRenderer", "content",
                                       "musicPlayButtonRenderer", "playNavigationEndpoint",
                                       "watchEndpoint", "videoId") as? String

                let thumbnailURL = extractThumbnail(from: item.dig("musicResponsiveListItemRenderer", "thumbnail",
                                                                    "musicThumbnailRenderer", "thumbnail",
                                                                    "thumbnails") as? [[String: Any]])

                if !title.isEmpty {
                    results.append(SearchResult(
                        title: title,
                        subtitle: subtitle,
                        videoId: videoId,
                        thumbnailURL: thumbnailURL,
                        resultType: videoId != nil ? .song : .other
                    ))
                }
            }
        }

        return results
    }

    private static func extractText(from columns: [[String: Any]], index: Int) -> String {
        guard index < columns.count,
              let runs = columns[index].dig("musicResponsiveListItemFlexColumnRenderer", "text", "runs") as? [[String: Any]],
              let firstRun = runs.first
        else { return "" }
        return firstRun["text"] as? String ?? ""
    }

    private static func extractThumbnail(from thumbnails: [[String: Any]]?) -> URL? {
        guard let thumbnails, let last = thumbnails.last,
              let urlString = last["url"] as? String else { return nil }
        return URL(string: urlString)
    }
}

// MARK: - Browse Response

struct BrowseResponse {
    var title: String = ""
    var sections: [BrowseSection] = []
}

struct BrowseSection {
    var title: String
    var items: [SearchResult]
}

enum BrowseResponseParser {
    static func parse(_ json: [String: Any]) -> BrowseResponse {
        var response = BrowseResponse()

        if let header = json.dig("header", "musicImmersiveHeaderRenderer", "title", "runs") as? [[String: Any]],
           let title = header.first?["text"] as? String {
            response.title = title
        }

        guard let sections = json.dig("contents", "singleColumnBrowseResultsRenderer", "tabs") as? [[String: Any]],
              let firstTab = sections.first,
              let sectionContents = firstTab.dig("tabRenderer", "content", "sectionListRenderer", "contents") as? [[String: Any]]
        else { return response }

        for section in sectionContents {
            // 1. musicImmersiveCarouselShelfRenderer — featured mixes (Supermix, Discover Mix)
            if let immersive = section["musicImmersiveCarouselShelfRenderer"] as? [String: Any] {
                let title = (immersive.dig("header", "musicImmersiveCarouselShelfBasicHeaderRenderer", "title", "runs") as? [[String: Any]])?
                    .first?["text"] as? String
                    ?? (immersive.dig("header", "musicCarouselShelfBasicHeaderRenderer", "title", "runs") as? [[String: Any]])?
                        .first?["text"] as? String ?? ""
                let items = (immersive["contents"] as? [[String: Any]])?.compactMap { parseCarouselItem($0) } ?? []
                if !items.isEmpty {
                    response.sections.append(BrowseSection(title: title, items: items))
                }
            }
            // 2. musicCardShelfRenderer — large cards (personalized mixes, "Mixed for you")
            else if let cardShelf = section["musicCardShelfRenderer"] as? [String: Any] {
                let title = (cardShelf.dig("header", "musicCardShelfHeaderBasicRenderer", "title", "runs") as? [[String: Any]])?
                    .first?["text"] as? String ?? ""

                var items: [SearchResult] = []

                // The card shelf itself may be a playable item
                if let mainTitle = (cardShelf.dig("title", "runs") as? [[String: Any]])?.first?["text"] as? String {
                    let subtitle = (cardShelf.dig("subtitle", "runs") as? [[String: Any]])?
                        .compactMap { $0["text"] as? String }.joined() ?? ""
                    let thumbnails = cardShelf.dig("thumbnail", "musicThumbnailRenderer", "thumbnail", "thumbnails") as? [[String: Any]]
                    let thumbURL = thumbnails?.last?["url"] as? String

                    let videoId = cardShelf.dig("onTap", "watchEndpoint", "videoId") as? String
                        ?? cardShelf.dig("onTap", "watchPlaylistEndpoint", "playlistId") as? String
                    let browseId = cardShelf.dig("onTap", "browseEndpoint", "browseId") as? String

                    let playId = videoId ?? browseId
                    let resultType: SearchResult.ResultType = videoId != nil ? .song : .playlist

                    if !mainTitle.isEmpty {
                        items.append(SearchResult(
                            title: mainTitle,
                            subtitle: subtitle,
                            videoId: playId,
                            thumbnailURL: thumbURL.flatMap { URL(string: $0) },
                            resultType: resultType
                        ))
                    }
                }

                // Sub-items in the card shelf (contents array)
                let subItems = (cardShelf["contents"] as? [[String: Any]])?.compactMap { parseCarouselItem($0) } ?? []
                items.append(contentsOf: subItems)

                if !items.isEmpty {
                    response.sections.append(BrowseSection(title: title, items: items))
                }
            }
            // 3. musicCarouselShelfRenderer — standard horizontal carousels
            else if let carousel = section["musicCarouselShelfRenderer"] as? [String: Any] {
                let title = (carousel.dig("header", "musicCarouselShelfBasicHeaderRenderer", "title", "runs") as? [[String: Any]])?
                    .first?["text"] as? String ?? ""
                let items = (carousel["contents"] as? [[String: Any]])?.compactMap { parseCarouselItem($0) } ?? []
                if !items.isEmpty {
                    response.sections.append(BrowseSection(title: title, items: items))
                }
            }
            // 4. musicShelfRenderer — vertical list items
            else if let shelf = section["musicShelfRenderer"] as? [String: Any] {
                let title = (shelf.dig("title", "runs") as? [[String: Any]])?.first?["text"] as? String ?? ""
                let items = (shelf["contents"] as? [[String: Any]])?.compactMap { parseShelfItem($0) } ?? []
                if !items.isEmpty {
                    response.sections.append(BrowseSection(title: title, items: items))
                }
            }
            // 5. itemSectionRenderer — wrapper, recurse into its contents
            else if let wrapper = section["itemSectionRenderer"] as? [String: Any],
                    let innerContents = wrapper["contents"] as? [[String: Any]] {
                for inner in innerContents {
                    if let carousel = inner["musicCarouselShelfRenderer"] as? [String: Any] {
                        let title = (carousel.dig("header", "musicCarouselShelfBasicHeaderRenderer", "title", "runs") as? [[String: Any]])?
                            .first?["text"] as? String ?? ""
                        let items = (carousel["contents"] as? [[String: Any]])?.compactMap { parseCarouselItem($0) } ?? []
                        if !items.isEmpty {
                            response.sections.append(BrowseSection(title: title, items: items))
                        }
                    }
                }
            }
        }

        return response
    }

    // MARK: - Carousel Item (musicTwoRowItemRenderer — cards with thumbnail + title + subtitle)

    private static func parseCarouselItem(_ item: [String: Any]) -> SearchResult? {
        if let renderer = item["musicTwoRowItemRenderer"] as? [String: Any] {
            let title = (renderer.dig("title", "runs") as? [[String: Any]])?.first?["text"] as? String ?? ""
            guard !title.isEmpty else { return nil }

            let subtitle = (renderer.dig("subtitle", "runs") as? [[String: Any]])?
                .map { $0["text"] as? String ?? "" }
                .joined() ?? ""

            let thumbnails = renderer.dig("thumbnailRenderer", "musicThumbnailRenderer", "thumbnail", "thumbnails") as? [[String: Any]]
            let thumbnailURL = thumbnails?.last?["url"] as? String

            // Try to get videoId from various navigation endpoints
            let videoId = renderer.dig("navigationEndpoint", "watchEndpoint", "videoId") as? String
                ?? renderer.dig("overlay", "musicItemThumbnailOverlayRenderer", "content",
                                "musicPlayButtonRenderer", "playNavigationEndpoint",
                                "watchEndpoint", "videoId") as? String

            // Playlist ID for mixes (Supermix, Discover Mix, etc.)
            let playlistId = renderer.dig("navigationEndpoint", "watchEndpoint", "playlistId") as? String
                ?? renderer.dig("navigationEndpoint", "watchPlaylistEndpoint", "playlistId") as? String
                ?? renderer.dig("overlay", "musicItemThumbnailOverlayRenderer", "content",
                                "musicPlayButtonRenderer", "playNavigationEndpoint",
                                "watchEndpoint", "playlistId") as? String
                ?? renderer.dig("overlay", "musicItemThumbnailOverlayRenderer", "content",
                                "musicPlayButtonRenderer", "playNavigationEndpoint",
                                "watchPlaylistEndpoint", "playlistId") as? String

            let browseId = renderer.dig("navigationEndpoint", "browseEndpoint", "browseId") as? String

            // Determine type and playable ID
            let resultType: SearchResult.ResultType
            let playableId: String?
            if videoId != nil {
                resultType = .song
                playableId = videoId
            } else if let playlistId {
                resultType = .playlist
                playableId = playlistId
            } else if let browseId, browseId.hasPrefix("MPRE") || browseId.hasPrefix("OLAK") {
                resultType = .album
                playableId = browseId
            } else if let browseId, browseId.hasPrefix("UC") || browseId.hasPrefix("MPLAUC") {
                resultType = .artist
                playableId = browseId
            } else if let browseId, browseId.hasPrefix("VL") || browseId.hasPrefix("PL") || browseId.hasPrefix("RDCLAK") || browseId.hasPrefix("RD") {
                resultType = .playlist
                playableId = browseId
            } else {
                resultType = browseId != nil ? .other : .other
                playableId = browseId
            }

            return SearchResult(
                title: title,
                subtitle: subtitle,
                videoId: playableId,
                thumbnailURL: thumbnailURL.flatMap { URL(string: $0) },
                resultType: resultType
            )
        }

        // Fallback: try musicResponsiveListItemRenderer
        return parseShelfItem(item)
    }

    // MARK: - Shelf Item (musicResponsiveListItemRenderer — list rows)

    private static func parseShelfItem(_ item: [String: Any]) -> SearchResult? {
        guard let columns = item.dig("musicResponsiveListItemRenderer", "flexColumns") as? [[String: Any]] else {
            return nil
        }

        let title = (columns.first?.dig("musicResponsiveListItemFlexColumnRenderer", "text", "runs") as? [[String: Any]])?
            .first?["text"] as? String ?? ""
        guard !title.isEmpty else { return nil }

        let subtitle = columns.count > 1
            ? ((columns[1].dig("musicResponsiveListItemFlexColumnRenderer", "text", "runs") as? [[String: Any]])?
                .compactMap { $0["text"] as? String }
                .joined() ?? "")
            : ""

        let videoId = item.dig("musicResponsiveListItemRenderer", "overlay",
                                "musicItemThumbnailOverlayRenderer", "content",
                                "musicPlayButtonRenderer", "playNavigationEndpoint",
                                "watchEndpoint", "videoId") as? String

        let thumbnails = item.dig("musicResponsiveListItemRenderer", "thumbnail",
                                   "musicThumbnailRenderer", "thumbnail",
                                   "thumbnails") as? [[String: Any]]
        let thumbnailURL = thumbnails?.last?["url"] as? String

        return SearchResult(
            title: title,
            subtitle: subtitle,
            videoId: videoId,
            thumbnailURL: thumbnailURL.flatMap { URL(string: $0) },
            resultType: videoId != nil ? .song : .other
        )
    }
}

// MARK: - Playlist Parser

struct PlaylistDetail {
    var title: String = ""
    var description: String = ""
    var thumbnailURL: URL?
    var tracks: [Track] = []
}

enum PlaylistParser {
    /// Parse a playlist/browse response into PlaylistDetail.
    /// Handles multiple response layouts like kaset:
    /// 1. singleColumnBrowseResultsRenderer (most common)
    /// 2. twoColumnBrowseResultsRenderer (some playlists)
    static func parse(_ json: [String: Any]) -> PlaylistDetail {
        var detail = PlaylistDetail()

        // Try various header renderers
        if let header = json.dig("header", "musicImmersiveHeaderRenderer") as? [String: Any] {
            detail.title = (header.dig("title", "runs") as? [[String: Any]])?.first?["text"] as? String ?? ""
            detail.description = (header.dig("description", "runs") as? [[String: Any]])?.first?["text"] as? String ?? ""
        } else if let header = json.dig("header", "musicDetailHeaderRenderer") as? [String: Any] {
            detail.title = (header.dig("title", "runs") as? [[String: Any]])?.first?["text"] as? String ?? ""
        } else if let header = json.dig("header", "musicHeaderRenderer") as? [String: Any] {
            detail.title = (header.dig("title", "runs") as? [[String: Any]])?.first?["text"] as? String ?? ""
        }

        // Try multiple response layout paths (like kaset)
        let sectionContents = findSectionContents(json)

        // Collect all sections to parse — unwrap itemSectionRenderer wrappers (kaset pattern)
        var allSections: [[String: Any]] = []
        for section in sectionContents {
            if let wrapper = section["itemSectionRenderer"] as? [String: Any],
               let innerContents = wrapper["contents"] as? [[String: Any]] {
                allSections.append(contentsOf: innerContents)
            } else {
                allSections.append(section)
            }
        }

        for section in allSections {
            // musicShelfRenderer — standard song list
            if let shelf = section["musicShelfRenderer"] as? [String: Any],
               let items = shelf["contents"] as? [[String: Any]] {
                for item in items {
                    if let track = parseTrack(from: item) {
                        detail.tracks.append(track)
                    }
                }
            }
            // musicPlaylistShelfRenderer — some playlist pages
            if let shelf = section["musicPlaylistShelfRenderer"] as? [String: Any],
               let items = shelf["contents"] as? [[String: Any]] {
                for item in items {
                    if let track = parseTrack(from: item) {
                        detail.tracks.append(track)
                    }
                }
            }
        }

        return detail
    }

    /// Find section contents from various response layouts
    private static func findSectionContents(_ json: [String: Any]) -> [[String: Any]] {
        // Path 1: singleColumnBrowseResultsRenderer > tabs
        if let sections = json.dig("contents", "singleColumnBrowseResultsRenderer", "tabs") as? [[String: Any]],
           let firstTab = sections.first,
           let contents = firstTab.dig("tabRenderer", "content", "sectionListRenderer", "contents") as? [[String: Any]] {
            return contents
        }

        // Path 2: twoColumnBrowseResultsRenderer > secondaryContents
        if let contents = json.dig("contents", "twoColumnBrowseResultsRenderer", "secondaryContents",
                                    "sectionListRenderer", "contents") as? [[String: Any]] {
            return contents
        }

        // Path 3: twoColumnBrowseResultsRenderer > tabs
        if let sections = json.dig("contents", "twoColumnBrowseResultsRenderer", "tabs") as? [[String: Any]],
           let firstTab = sections.first,
           let contents = firstTab.dig("tabRenderer", "content", "sectionListRenderer", "contents") as? [[String: Any]] {
            return contents
        }

        return []
    }

    /// Parse a track from musicResponsiveListItemRenderer
    private static func parseTrack(from item: [String: Any]) -> Track? {
        guard let renderer = item["musicResponsiveListItemRenderer"] as? [String: Any] else { return nil }
        guard let columns = renderer["flexColumns"] as? [[String: Any]] else { return nil }

        let title = (columns.first?.dig("musicResponsiveListItemFlexColumnRenderer", "text", "runs") as? [[String: Any]])?
            .first?["text"] as? String ?? ""
        guard !title.isEmpty else { return nil }

        // Artist from second flex column (join all text runs)
        let artist = columns.count > 1
            ? ((columns[1].dig("musicResponsiveListItemFlexColumnRenderer", "text", "runs") as? [[String: Any]])?
                .compactMap { $0["text"] as? String }
                .joined() ?? "")
            : ""

        // Video ID: try playlistItemData first (kaset pattern), then overlay, then navigation
        let videoId = renderer.dig("playlistItemData", "videoId") as? String
            ?? renderer.dig("overlay", "musicItemThumbnailOverlayRenderer", "content",
                            "musicPlayButtonRenderer", "playNavigationEndpoint",
                            "watchEndpoint", "videoId") as? String
            ?? renderer.dig("navigationEndpoint", "watchEndpoint", "videoId") as? String

        // Thumbnail
        let thumbnails = renderer.dig("thumbnail", "musicThumbnailRenderer", "thumbnail", "thumbnails") as? [[String: Any]]
        let thumbnailURL = thumbnails?.last?["url"] as? String

        guard let videoId, !videoId.isEmpty else { return nil }

        return Track(
            videoId: videoId,
            title: title,
            artist: artist,
            albumArtURL: thumbnailURL.flatMap { URL(string: $0) }
        )
    }

    // MARK: - Continuation Token (kaset pattern)

    /// Extract continuation token from a browse response for pagination.
    static func extractContinuationToken(from json: [String: Any]) -> String? {
        let sectionContents = findSectionContents(json)
        // Unwrap itemSectionRenderer wrappers
        var allSections: [[String: Any]] = []
        for section in sectionContents {
            if let wrapper = section["itemSectionRenderer"] as? [String: Any],
               let inner = wrapper["contents"] as? [[String: Any]] {
                allSections.append(contentsOf: inner)
            } else {
                allSections.append(section)
            }
        }
        for section in allSections {
            // musicShelfRenderer continuations
            if let shelf = section["musicShelfRenderer"] as? [String: Any],
               let continuations = shelf["continuations"] as? [[String: Any]],
               let first = continuations.first,
               let token = first.dig("nextContinuationData", "continuation") as? String {
                return token
            }
            // musicPlaylistShelfRenderer continuations
            if let shelf = section["musicPlaylistShelfRenderer"] as? [String: Any],
               let continuations = shelf["continuations"] as? [[String: Any]],
               let first = continuations.first,
               let token = first.dig("nextContinuationData", "continuation") as? String {
                return token
            }
        }
        return nil
    }

    /// Parse tracks from a continuation response (kaset supports legacy + 2025 format).
    static func parseContinuation(_ json: [String: Any]) -> [Track] {
        var tracks: [Track] = []

        // Legacy format: continuationContents → musicShelfContinuation/musicPlaylistShelfContinuation
        if let continuationContents = json["continuationContents"] as? [String: Any] {
            let shelf = continuationContents["musicShelfContinuation"] as? [String: Any]
                ?? continuationContents["musicPlaylistShelfContinuation"] as? [String: Any]
            if let contents = shelf?["contents"] as? [[String: Any]] {
                for item in contents {
                    if let track = parseTrack(from: item) {
                        tracks.append(track)
                    }
                }
            }
        }

        // 2025 format: onResponseReceivedActions → appendContinuationItemsAction
        if tracks.isEmpty,
           let actions = json["onResponseReceivedActions"] as? [[String: Any]] {
            for action in actions {
                if let appendAction = action["appendContinuationItemsAction"] as? [String: Any],
                   let items = appendAction["continuationItems"] as? [[String: Any]] {
                    for item in items {
                        if let track = parseTrack(from: item) {
                            tracks.append(track)
                        }
                    }
                }
            }
        }

        return tracks
    }

    /// Extract continuation token from a continuation response.
    static func extractContinuationTokenFromContinuation(_ json: [String: Any]) -> String? {
        // Legacy format
        if let continuationContents = json["continuationContents"] as? [String: Any] {
            let shelf = continuationContents["musicShelfContinuation"] as? [String: Any]
                ?? continuationContents["musicPlaylistShelfContinuation"] as? [String: Any]
            if let continuations = shelf?["continuations"] as? [[String: Any]],
               let first = continuations.first,
               let token = first.dig("nextContinuationData", "continuation") as? String {
                return token
            }
        }

        // 2025 format
        if let actions = json["onResponseReceivedActions"] as? [[String: Any]] {
            for action in actions {
                if let appendAction = action["appendContinuationItemsAction"] as? [String: Any],
                   let items = appendAction["continuationItems"] as? [[String: Any]] {
                    for item in items {
                        if let token = item.dig("continuationItemRenderer", "continuationEndpoint",
                                                 "continuationCommand", "token") as? String {
                            return token
                        }
                    }
                }
            }
        }

        return nil
    }
}

// MARK: - Library Parser (kaset exact pattern)

struct LibraryPlaylist: Identifiable, Equatable {
    var id: String
    var title: String
    var subtitle: String = ""
    var thumbnailURL: URL?
}

enum LibraryParser {
    /// Parse user's saved playlists from FEmusic_liked_playlists response.
    /// Handles: gridRenderer (musicTwoRowItemRenderer), musicShelfRenderer (musicResponsiveListItemRenderer)
    static func parsePlaylists(_ data: [String: Any]) -> [LibraryPlaylist] {
        var playlists: [LibraryPlaylist] = []

        let sections = extractSections(from: data)
        for section in sections {
            // gridRenderer — kaset's primary path for library items
            if let grid = section["gridRenderer"] as? [String: Any],
               let items = grid["items"] as? [[String: Any]] {
                for item in items {
                    if let renderer = item["musicTwoRowItemRenderer"] as? [String: Any],
                       let playlist = parseFromTwoRow(renderer) {
                        playlists.append(playlist)
                    }
                }
            }

            // musicShelfRenderer — alternative path
            if let shelf = section["musicShelfRenderer"] as? [String: Any],
               let items = shelf["contents"] as? [[String: Any]] {
                for item in items {
                    if let renderer = item["musicResponsiveListItemRenderer"] as? [String: Any],
                       let playlist = parseFromResponsive(renderer) {
                        playlists.append(playlist)
                    }
                }
            }

            // itemSectionRenderer — kaset handles this as a wrapper with nested renderers
            if let wrapper = section["itemSectionRenderer"] as? [String: Any],
               let innerContents = wrapper["contents"] as? [[String: Any]] {
                for inner in innerContents {
                    // musicShelfRenderer inside itemSectionRenderer
                    if let shelf = inner["musicShelfRenderer"] as? [String: Any],
                       let items = shelf["contents"] as? [[String: Any]] {
                        for item in items {
                            if let renderer = item["musicResponsiveListItemRenderer"] as? [String: Any],
                               let playlist = parseFromResponsive(renderer) {
                                playlists.append(playlist)
                            }
                        }
                    }

                    // gridRenderer inside itemSectionRenderer
                    if let grid = inner["gridRenderer"] as? [String: Any],
                       let items = grid["items"] as? [[String: Any]] {
                        for item in items {
                            if let renderer = item["musicTwoRowItemRenderer"] as? [String: Any],
                               let playlist = parseFromTwoRow(renderer) {
                                playlists.append(playlist)
                            }
                        }
                    }

                    // Direct musicTwoRowItemRenderer inside itemSectionRenderer
                    if let renderer = inner["musicTwoRowItemRenderer"] as? [String: Any],
                       let playlist = parseFromTwoRow(renderer) {
                        playlists.append(playlist)
                    }

                    // Direct musicResponsiveListItemRenderer
                    if let renderer = inner["musicResponsiveListItemRenderer"] as? [String: Any],
                       let playlist = parseFromResponsive(renderer) {
                        playlists.append(playlist)
                    }
                }
            }
        }

        return playlists
    }

    private static func extractSections(from data: [String: Any]) -> [[String: Any]] {
        guard let contents = data.dig("contents", "singleColumnBrowseResultsRenderer", "tabs") as? [[String: Any]],
              let firstTab = contents.first,
              let sectionContents = firstTab.dig("tabRenderer", "content", "sectionListRenderer", "contents") as? [[String: Any]]
        else { return [] }
        return sectionContents
    }

    /// Parse from musicTwoRowItemRenderer (grid items)
    private static func parseFromTwoRow(_ renderer: [String: Any]) -> LibraryPlaylist? {
        guard let browseId = renderer.dig("navigationEndpoint", "browseEndpoint", "browseId") as? String else { return nil }
        // Only accept playlist-like browse IDs
        guard browseId.hasPrefix("VL") || browseId.hasPrefix("PL") || browseId.hasPrefix("RDCLAK") else { return nil }

        let title = (renderer.dig("title", "runs") as? [[String: Any]])?.first?["text"] as? String ?? ""
        guard !title.isEmpty else { return nil }

        let subtitle = (renderer.dig("subtitle", "runs") as? [[String: Any]])?
            .compactMap { $0["text"] as? String }.joined() ?? ""
        let thumbnails = renderer.dig("thumbnailRenderer", "musicThumbnailRenderer", "thumbnail", "thumbnails") as? [[String: Any]]
        let thumbURL = thumbnails?.last?["url"] as? String

        return LibraryPlaylist(id: browseId, title: title, subtitle: subtitle, thumbnailURL: thumbURL.flatMap { URL(string: $0) })
    }

    /// Parse from musicResponsiveListItemRenderer (shelf items)
    private static func parseFromResponsive(_ renderer: [String: Any]) -> LibraryPlaylist? {
        let browseId = renderer.dig("navigationEndpoint", "browseEndpoint", "browseId") as? String
            ?? renderer.dig("overlay", "musicItemThumbnailOverlayRenderer", "content",
                            "musicPlayButtonRenderer", "playNavigationEndpoint",
                            "watchPlaylistEndpoint", "playlistId") as? String
        guard let browseId, browseId.hasPrefix("VL") || browseId.hasPrefix("PL") || browseId.hasPrefix("RDCLAK") else { return nil }

        guard let columns = renderer["flexColumns"] as? [[String: Any]] else { return nil }
        let title = (columns.first?.dig("musicResponsiveListItemFlexColumnRenderer", "text", "runs") as? [[String: Any]])?
            .first?["text"] as? String ?? ""
        guard !title.isEmpty else { return nil }

        let subtitle = columns.count > 1
            ? ((columns[1].dig("musicResponsiveListItemFlexColumnRenderer", "text", "runs") as? [[String: Any]])?
                .compactMap { $0["text"] as? String }.joined() ?? "")
            : ""
        let thumbnails = renderer.dig("thumbnail", "musicThumbnailRenderer", "thumbnail", "thumbnails") as? [[String: Any]]
        let thumbURL = thumbnails?.last?["url"] as? String

        return LibraryPlaylist(id: browseId, title: title, subtitle: subtitle, thumbnailURL: thumbURL.flatMap { URL(string: $0) })
    }
}

// MARK: - Lyrics Parser

struct LyricsResult {
    var lines: [LyricsLine]
    var isSynced: Bool
    var source: String
}

struct LyricsLine {
    var text: String
    var startTimeMs: Int?
}

enum LyricsParser {

    // MARK: - Extract timed lyrics from "next" response (kaset pattern)
    // Recursively searches for timedLyricsModel embedded in the response

    static func extractTimedLyrics(from json: [String: Any]) -> LyricsResult? {
        guard let lyricsData = findValue(for: "timedLyricsModel", in: json) as? [String: Any],
              let lyrics = lyricsData["lyricsData"] as? [String: Any],
              let lines = lyrics["timedLyricsData"] as? [[String: Any]]
        else { return nil }

        var result: [LyricsLine] = []
        for line in lines {
            let text = line["lyricLine"] as? String ?? ""
            let startMs = (line["startTimeMs"] as? String).flatMap { Int($0) }
                ?? line["startTimeMs"] as? Int
            let _ = (line["durationMs"] as? String).flatMap { Int($0) }
            result.append(LyricsLine(text: text, startTimeMs: startMs))
        }

        guard !result.isEmpty else { return nil }
        return LyricsResult(lines: result, isSynced: true, source: "YouTube Music")
    }

    // MARK: - Extract lyrics browse ID from "next" response

    static func extractBrowseId(from json: [String: Any]) -> String? {
        // Path 1: standard tabs in next response
        if let tabs = json.dig("contents", "singleColumnMusicWatchNextResultsRenderer",
                                "tabbedRenderer", "watchNextTabbedResultsRenderer", "tabs") as? [[String: Any]] {
            for tab in tabs {
                if let browseId = tab.dig("tabRenderer", "endpoint", "browseEndpoint", "browseId") as? String,
                   browseId.hasPrefix("MPLYt") {
                    return browseId
                }
            }
        }

        // Path 2: recursive deep search (fallback)
        return findValue(for: "browseId", in: json, matching: { ($0 as? String)?.hasPrefix("MPLYt") == true }) as? String
    }

    // MARK: - Parse plain lyrics from "browse" response

    static func parse(_ json: [String: Any]) -> LyricsResult? {
        guard let sections = json.dig("contents", "sectionListRenderer", "contents") as? [[String: Any]],
              let firstSection = sections.first
        else { return nil }

        // musicDescriptionShelfRenderer — plain text lyrics (most common)
        if let renderer = firstSection["musicDescriptionShelfRenderer"] as? [String: Any],
           let description = (renderer.dig("description", "runs") as? [[String: Any]])?.first?["text"] as? String,
           !description.isEmpty {
            let lines = description.components(separatedBy: "\n").map { LyricsLine(text: $0) }
            let source = (renderer.dig("footer", "runs") as? [[String: Any]])?.first?["text"] as? String ?? ""
            return LyricsResult(lines: lines, isSynced: false, source: source)
        }

        return nil
    }

    // MARK: - Recursive search helpers

    private static func findValue(for key: String, in obj: Any, matching: ((Any) -> Bool)? = nil) -> Any? {
        if let dict = obj as? [String: Any] {
            if let value = dict[key] {
                if let matching { if matching(value) { return value } }
                else { return value }
            }
            for value in dict.values {
                if let found = findValue(for: key, in: value, matching: matching) { return found }
            }
        } else if let array = obj as? [Any] {
            for item in array {
                if let found = findValue(for: key, in: item, matching: matching) { return found }
            }
        }
        return nil
    }
}

// MARK: - Up Next Parser

enum UpNextParser {
    static func parse(_ json: [String: Any]) -> [Track] {
        guard let contents = json.dig("contents", "singleColumnMusicWatchNextResultsRenderer",
                                       "tabbedRenderer", "watchNextTabbedResultsRenderer", "tabs") as? [[String: Any]],
              let firstTab = contents.first,
              let playlist = firstTab.dig("tabRenderer", "content", "musicQueueRenderer",
                                          "content", "playlistPanelRenderer", "contents") as? [[String: Any]]
        else { return [] }

        return playlist.compactMap { item -> Track? in
            guard let renderer = item["playlistPanelVideoRenderer"] as? [String: Any] else { return nil }

            let title = (renderer.dig("title", "runs") as? [[String: Any]])?.first?["text"] as? String ?? ""
            let artist = (renderer.dig("shortBylineText", "runs") as? [[String: Any]])?.first?["text"] as? String ?? ""
            let videoId = renderer["videoId"] as? String ?? ""
            let thumbnails = renderer.dig("thumbnail", "thumbnails") as? [[String: Any]]
            let thumbnailURL = thumbnails?.last?["url"] as? String

            guard !title.isEmpty else { return nil }
            return Track(
                videoId: videoId,
                title: title,
                artist: artist,
                albumArtURL: thumbnailURL.flatMap { URL(string: $0) }
            )
        }
    }
}

// MARK: - Dictionary Helper

extension Dictionary where Key == String, Value == Any {
    /// Dig into nested dictionaries with a variadic key path.
    func dig(_ keys: String...) -> Any? {
        var current: Any = self
        for key in keys {
            guard let dict = current as? [String: Any], let next = dict[key] else { return nil }
            current = next
        }
        return current
    }
}

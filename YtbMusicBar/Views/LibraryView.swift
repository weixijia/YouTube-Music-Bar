import SwiftUI

/// Collection tab — matches kaset's Library with two sub-views:
/// 1. Library (user playlists from FEmusic_liked_playlists)
/// 2. Liked Music (songs from VLLM with continuation pagination)
struct CollectionView: View {
    @Environment(YTMusicClient.self) private var apiClient
    @Environment(PlayerService.self) private var playerService
    @Environment(AuthService.self) private var authService

    @State private var selectedSection: CollectionSection = .library
    @State private var playlists: [LibraryPlaylist] = []
    @State private var likedSongs: [Track] = []
    @State private var hasMoreLiked = false
    @State private var isLoading = false
    @State private var isLoadingMore = false

    // Detail view state
    @State private var detailTracks: [Track] = []
    @State private var detailTitle: String = ""
    @State private var isLoadingDetail = false
    @State private var showDetail = false

    enum CollectionSection: String, CaseIterable {
        case library = "Library"
        case liked = "Liked Music"
    }

    var body: some View {
        VStack(spacing: 0) {
            if showDetail {
                detailView
            } else {
                collectionRoot
            }
        }
    }

    // MARK: - Root

    private var collectionRoot: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Collection")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)

            // Section picker (Library / Liked Music)
            HStack(spacing: 8) {
                ForEach(CollectionSection.allCases, id: \.self) { section in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedSection = section
                        }
                    } label: {
                        Text(section.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(selectedSection == section
                                    ? Color.accentColor.opacity(0.2)
                                    : Color.primary.opacity(0.05))
                            )
                            .foregroundStyle(selectedSection == section ? Color.accentColor : .primary)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            Divider()

            // Content
            switch selectedSection {
            case .library:
                libraryContent
            case .liked:
                likedMusicContent
            }
        }
        .task {
            await loadLibrary()
        }
        .task(id: selectedSection) {
            if selectedSection == .liked && likedSongs.isEmpty {
                await loadLikedSongs()
            }
        }
        // Reload when auth state changes (e.g., after fresh login)
        .onChange(of: authService.state) { _, newState in
            if newState == .loggedIn {
                playlists = []
                likedSongs = []
                Task {
                    // Small delay for cookies to be fully saved
                    try? await Task.sleep(for: .milliseconds(800))
                    await loadLibrary()
                    if selectedSection == .liked {
                        await loadLikedSongs()
                    }
                }
            }
        }
    }

    // MARK: - Library (Playlists)

    private var libraryContent: some View {
        Group {
            if isLoading && playlists.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if playlists.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "square.stack")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("No playlists found")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(playlists) { playlist in
                            Button {
                                openPlaylist(browseId: playlist.id, title: playlist.title)
                            } label: {
                                HStack(spacing: 10) {
                                    CachedAsyncImage(url: playlist.thumbnailURL, cornerRadius: 6)
                                        .aspectRatio(1, contentMode: .fill)
                                        .frame(width: 44, height: 44)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 6))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(playlist.title)
                                            .font(.callout)
                                            .lineLimit(1)
                                        if !playlist.subtitle.isEmpty {
                                            Text(playlist.subtitle)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 8)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Liked Music (kaset pattern: VLLM + continuation)

    private var likedMusicContent: some View {
        Group {
            if isLoading && likedSongs.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if likedSongs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "heart")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("No liked songs")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        // Song count header
                        HStack {
                            Text("\(likedSongs.count) songs")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)

                        ForEach(likedSongs) { track in
                            SongRowView(track: track, isNowPlaying: track.videoId == playerService.track.videoId) {
                                playerService.play(videoId: track.videoId)
                            }
                        }

                        // Pagination trigger (kaset pattern: load more at bottom)
                        if hasMoreLiked {
                            if isLoadingMore {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding(8)
                            } else {
                                Color.clear
                                    .frame(height: 1)
                                    .onAppear { loadMoreLikedSongs() }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Detail View

    private var detailView: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    showDetail = false
                    detailTracks = []
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body)
                }
                .buttonStyle(.plain)

                Text(detailTitle)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Text("\(detailTracks.count) songs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)

            Divider()

            if isLoadingDetail {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if detailTracks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("No tracks found")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(detailTracks) { track in
                            SongRowView(track: track, isNowPlaying: track.videoId == playerService.track.videoId) {
                                playerService.play(videoId: track.videoId)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Data Loading

    private func loadLibrary() async {
        guard playlists.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        print("[Collection] loadLibrary called, authenticated=\(apiClient.hasSapisid)")
        do {
            playlists = try await apiClient.getLibraryPlaylists()
            print("[Collection] Loaded \(playlists.count) playlists")
        } catch {
            print("[Collection] Error loading playlists: \(error)")
        }
    }

    private func loadLikedSongs() async {
        isLoading = true
        defer { isLoading = false }

        print("[Collection] loadLikedSongs called")
        do {
            let (songs, token) = try await apiClient.getLikedSongs()
            print("[Collection] Loaded \(songs.count) liked songs, hasMore=\(token != nil)")
            var seen = Set<String>()
            likedSongs = songs.filter { seen.insert($0.videoId).inserted }
            hasMoreLiked = token != nil
        } catch {
            print("[Collection] Error loading liked songs: \(error)")
        }
    }

    private func loadMoreLikedSongs() {
        guard hasMoreLiked, !isLoadingMore else { return }
        isLoadingMore = true

        Task {
            defer { isLoadingMore = false }
            do {
                let (songs, token) = try await apiClient.getLikedSongsContinuation()
                var seen = Set(likedSongs.map(\.videoId))
                let newSongs = songs.filter { seen.insert($0.videoId).inserted }
                likedSongs.append(contentsOf: newSongs)
                hasMoreLiked = token != nil
            } catch {
                print("[Collection] Error loading more: \(error)")
            }
        }
    }

    private func openPlaylist(browseId: String, title: String) {
        detailTitle = title
        isLoadingDetail = true
        showDetail = true

        Task {
            defer { isLoadingDetail = false }
            do {
                let detail = try await apiClient.playlistDetails(id: browseId)
                detailTracks = detail.tracks
            } catch {
                print("[Collection] Error loading \(title): \(error)")
                detailTracks = []
            }
        }
    }
}

import SwiftUI

struct SearchView: View {
    @Environment(YTMusicClient.self) private var apiClient
    @Environment(PlayerService.self) private var playerService

    @State private var query = ""
    @State private var results: [SearchResult] = []
    @State private var isSearching = false
    @State private var selectedFilter: SearchFilter = .all
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.caption)

                TextField("Search songs, artists, albums...", text: $query)
                    .textFieldStyle(.plain)
                    .font(.callout)
                    .onSubmit { performSearch() }
                    .onChange(of: query) { _, newValue in
                        debounceSearch(newValue)
                    }

                if !query.isEmpty {
                    Button {
                        query = ""
                        results = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background {
                if #available(macOS 26, *) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.quaternary.opacity(0.5))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.quaternary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach([SearchFilter.all, .songs, .albums, .artists, .playlists], id: \.rawValue) { filter in
                        FilterChip(title: filter.rawValue.capitalized, isSelected: selectedFilter == filter) {
                            selectedFilter = filter
                            if !query.isEmpty { performSearch() }
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
            .padding(.bottom, 8)

            Divider()

            // Results
            if isSearching {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if results.isEmpty && !query.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("No results found")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if results.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("Search YouTube Music")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(results) { result in
                            SearchResultRow(result: result) {
                                if let videoId = result.videoId {
                                    playerService.play(videoId: videoId)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func debounceSearch(_ newQuery: String) {
        searchTask?.cancel()
        guard !newQuery.isEmpty else {
            results = []
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            performSearch()
        }
    }

    private func performSearch() {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        Task {
            isSearching = true
            defer { isSearching = false }
            do {
                results = try await apiClient.search(query: query, filter: selectedFilter)
            } catch {
                results = []
            }
        }
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let result: SearchResult
    let onTap: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                CachedAsyncImage(url: result.thumbnailURL, cornerRadius: 6)
                    .frame(width: 44, height: 44)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .layoutPriority(1)

                VStack(alignment: .leading, spacing: 2) {
                    Text(result.title)
                        .font(.callout)
                        .lineLimit(1)
                    Text(result.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(2)

                Image(systemName: typeIcon)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(width: 14)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isHovering ? Color.primary.opacity(0.06) : .clear, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }

    private var typeIcon: String {
        switch result.resultType {
        case .song: return "music.note"
        case .album: return "square.stack"
        case .artist: return "person.fill"
        case .playlist: return "list.bullet"
        case .other: return "ellipsis"
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background {
                    if isSelected {
                        Capsule().fill(Color.accentColor.opacity(0.2))
                    } else {
                        Capsule().fill(.quaternary.opacity(0.5))
                    }
                }
                .foregroundStyle(isSelected ? Color.accentColor : .primary)
        }
        .buttonStyle(.plain)
    }
}

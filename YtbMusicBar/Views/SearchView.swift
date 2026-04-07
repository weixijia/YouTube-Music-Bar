import SwiftUI

struct SearchView: View {
    @Environment(YTMusicClient.self) private var apiClient
    @Environment(PlayerService.self) private var playerService

    @State private var query = ""
    @State private var results: [SearchResult] = []
    @State private var isSearching = false
    @State private var selectedFilter: SearchFilter = .all
    @State private var searchTask: Task<Void, Never>?
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.caption)

                TextField("Search songs, albums, playlists...", text: $query)
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
                        errorMessage = nil
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
                    ForEach([SearchFilter.all, .songs, .albums, .playlists], id: \.rawValue) { filter in
                        FilterChip(title: filter.rawValue.capitalized, isSelected: selectedFilter == filter) {
                            selectedFilter = filter
                            if !query.isEmpty { scheduleImmediateSearch() }
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
            } else if let errorMessage, results.isEmpty && !query.isEmpty {
                statusView(
                    icon: "exclamationmark.triangle",
                    title: errorMessage,
                    buttonTitle: "Try Again",
                    action: performSearch
                )
            } else if results.isEmpty && !query.isEmpty {
                statusView(icon: "music.note.list", title: "No results found")
            } else if results.isEmpty {
                statusView(icon: "magnifyingglass", title: "Search YouTube Music")
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(results) { result in
                            SearchResultRow(result: result) {
                                handleResultTap(result)
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
            isSearching = false
            errorMessage = nil
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await performSearch(query: newQuery, filter: selectedFilter)
        }
    }

    private func scheduleImmediateSearch() {
        searchTask?.cancel()
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }
        let filter = selectedFilter
        searchTask = Task {
            await performSearch(query: trimmedQuery, filter: filter)
        }
    }

    private func performSearch() {
        scheduleImmediateSearch()
    }

    private func performSearch(query: String, filter: SearchFilter) async {
        guard !query.isEmpty else { return }
        isSearching = true
        errorMessage = nil
        defer {
            if self.query.trimmingCharacters(in: .whitespacesAndNewlines) == query && self.selectedFilter == filter {
                isSearching = false
            }
        }

        do {
            let fetchedResults = try await apiClient.search(query: query, filter: filter)
            guard !Task.isCancelled,
                  self.query.trimmingCharacters(in: .whitespacesAndNewlines) == query,
                  self.selectedFilter == filter else { return }
            errorMessage = nil
            results = fetchedResults.filter { $0.resultType != .artist }
        } catch {
            guard !Task.isCancelled,
                  self.query.trimmingCharacters(in: .whitespacesAndNewlines) == query,
                  self.selectedFilter == filter else { return }
            errorMessage = error.userFacingMessage
            results = []
        }
    }

    private func handleResultTap(_ result: SearchResult) {
        switch result.resultType {
        case .song, .playlist, .album:
            Task {
                await playerService.play(searchResult: result, apiClient: apiClient, source: .search)
            }
        case .artist, .other:
            return
        }
    }

    private func statusView(icon: String, title: String, buttonTitle: String? = nil, action: (() -> Void)? = nil) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            if let buttonTitle, let action {
                Button(buttonTitle, action: action)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

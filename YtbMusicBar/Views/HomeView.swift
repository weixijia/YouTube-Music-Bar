import SwiftUI

/// Home feed — default landing page.
/// Initial view fits the panel without scrolling. When user scrolls down,
/// more sections progressively appear (like YouTube Music web lazy scroll).
struct HomeView: View {
    @Environment(YTMusicClient.self) private var apiClient
    @Environment(PlayerService.self) private var playerService

    @State private var sections: [BrowseSection] = []
    @State private var isLoading = false
    @State private var hasError = false
    @State private var errorMessage = "Couldn't load your feed"
    @State private var visibleSectionCount = 2 // Start with just 2 sections visible

    var body: some View {
        VStack(spacing: 0) {
            if isLoading && sections.isEmpty {
                loadingState
            } else if hasError && sections.isEmpty {
                errorState
            } else if sections.isEmpty {
                emptyState
            } else {
                feedContent
            }
        }
        .task {
            await loadHome()
        }
    }

    // MARK: - Feed Content

    private var feedContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                // Greeting header
                greetingHeader
                    .padding(.horizontal, 14)
                    .padding(.top, 8)

                // Show sections progressively
                let visibleSections = Array(sections.prefix(visibleSectionCount))

                ForEach(Array(visibleSections.enumerated()), id: \.offset) { index, section in
                    if index == 0 && section.items.count >= 4 {
                        compactGridSection(section)
                    } else {
                        horizontalSection(section)
                    }
                }

                // "Load more" trigger — appears when scrolled to bottom
                if visibleSectionCount < sections.count {
                    Color.clear
                        .frame(height: 1)
                        .onAppear {
                            // Progressive reveal: show 2 more sections
                            withAnimation(.easeOut(duration: 0.3)) {
                                visibleSectionCount = min(visibleSectionCount + 2, sections.count)
                            }
                        }

                    HStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.7)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(.bottom, 8)
        }
    }

    // MARK: - Greeting

    private var greetingHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Good \(timeOfDayGreeting)")
                    .font(.headline)

                if !playerService.track.isEmpty {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 5, height: 5)
                        Text(playerService.track.title)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
        }
    }

    // MARK: - Compact Grid Section (2-col pills, like YTM "Listen again")

    private func compactGridSection(_ section: BrowseSection) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(section.title)
                .font(.subheadline.bold())
                .padding(.horizontal, 14)

            let columns = Array(section.items.prefix(6))
            let rows = stride(from: 0, to: columns.count, by: 2).map { i in
                (columns[i], i + 1 < columns.count ? columns[i + 1] : nil)
            }

            VStack(spacing: 5) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, pair in
                    HStack(spacing: 5) {
                        CompactCard(item: pair.0) { playItem(pair.0) }
                        if let second = pair.1 {
                            CompactCard(item: second) { playItem(second) }
                        } else {
                            Spacer().frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
        }
    }

    // MARK: - Horizontal Scroll Section

    private func horizontalSection(_ section: BrowseSection) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(section.title)
                .font(.subheadline.bold())
                .padding(.horizontal, 14)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(section.items) { item in
                        SmallCard(item: item) { playItem(item) }
                    }
                }
                .padding(.horizontal, 14)
            }
            .scrollClipDisabled()
        }
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4).fill(.quaternary).frame(width: 140, height: 20)
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)

            VStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: 5) {
                        skeletonPill
                        skeletonPill
                    }
                }
            }
            .padding(.horizontal, 14)

            Spacer()
        }
    }

    private var skeletonPill: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.quaternary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
    }

    private var errorState: some View {
        VStack(spacing: 10) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("Couldn't load your feed")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            if errorMessage != "Couldn't load your feed" {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            Button("Try Again") {
                sections = []
                Task { await loadHome() }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "music.note.house")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text("Your feed will appear here")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Helpers

    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "morning"
        case 12..<17: return "afternoon"
        case 17..<22: return "evening"
        default: return "night"
        }
    }

    private func playItem(_ item: SearchResult) {
        switch item.resultType {
        case .song, .playlist, .album:
            Task {
                await playerService.play(searchResult: item, apiClient: apiClient, source: .home)
            }
        default:
            break
        }
    }

    private func loadHome() async {
        guard sections.isEmpty else { return }
        isLoading = true
        hasError = false
        errorMessage = "Couldn't load your feed"
        defer { isLoading = false }

        do {
            let response = try await apiClient.browse(id: "FEmusic_home")
            withAnimation(.easeOut(duration: 0.3)) {
                sections = response.sections
                visibleSectionCount = min(2, response.sections.count)
            }
        } catch {
            hasError = true
            errorMessage = error.userFacingMessage
            print("[Home] Error: \(error)")
        }
    }
}

// MARK: - Compact Card (pill-shaped, 2-col grid)

private struct CompactCard: View {
    let item: SearchResult
    let onTap: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                CachedAsyncImage(url: item.thumbnailURL, cornerRadius: 6)
                    .frame(width: 44, height: 44)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .layoutPriority(1)

                Text(item.title)
                    .font(.caption)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(2)
            }
            .padding(4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovering ? Color.primary.opacity(0.08) : Color.primary.opacity(0.04))
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Small Card (horizontal scroll)

private struct SmallCard: View {
    let item: SearchResult
    let onTap: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                CachedAsyncImage(url: item.thumbnailURL, cornerRadius: 6)
                    .frame(width: 110, height: 110)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        if isHovering {
                            ZStack {
                                Color.black.opacity(0.3)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                            .transition(.opacity)
                        }
                    }

                Text(item.title)
                    .font(.caption2)
                    .lineLimit(2)
                    .frame(width: 110, alignment: .leading)

                if !item.subtitle.isEmpty {
                    Text(item.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .frame(width: 110, alignment: .leading)
                }
            }
            .frame(width: 110)
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isHovering)
        .onHover { isHovering = $0 }
    }
}

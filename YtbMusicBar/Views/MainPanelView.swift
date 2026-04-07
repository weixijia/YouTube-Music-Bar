import SwiftUI

/// Navigation tabs — Home is default, matching kaset's sidebar structure adapted for menu bar.
enum PanelTab: String, CaseIterable {
    case home = "Home"
    case search = "Search"
    case collection = "Collection"
    case nowPlaying = "Playing"

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .search: return "magnifyingglass"
        case .collection: return "square.stack.fill"
        case .nowPlaying: return "play.circle.fill"
        }
    }
}

/// Root view for the floating panel.
struct MainPanelView: View {
    @Environment(AuthService.self) private var authService
    @Environment(PlayerService.self) private var playerService

    @State private var selectedTab: PanelTab = .home

    var body: some View {
        VStack(spacing: 0) {
            if authService.state != .loggedIn {
                loginContent
            } else {
                mainContent
            }
        }
        .frame(width: 320, height: 480)
        .background {
            if #available(macOS 26, *) {
                Color.clear.glassEffect(.regular, in: .rect(cornerRadius: 12))
            } else {
                VisualEffectView(material: .popover, blendingMode: .behindWindow)
                    .ignoresSafeArea()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        // Page content
        ZStack {
            switch selectedTab {
            case .home:
                HomeView()
            case .search:
                SearchView()
            case .collection:
                CollectionView()
            case .nowPlaying:
                NowPlayingView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)

        // Player bar (always visible when track is playing, except on Now Playing tab)
        if !playerService.track.isEmpty && selectedTab != .nowPlaying {
            Divider()
            PlayerBarView()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedTab = .nowPlaying
                    }
                }
        }

        // Tab bar
        Divider()
        tabBar
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(PanelTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 3) {
                        ZStack {
                            Image(systemName: tab.icon)
                                .font(.system(size: 16))

                            // Show dot indicator on Now Playing tab when something is playing
                            if tab == .nowPlaying && !playerService.track.isEmpty && selectedTab != .nowPlaying {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 5, height: 5)
                                    .offset(x: 10, y: -8)
                            }
                        }

                        Text(tab.rawValue)
                            .font(.system(size: 9))
                    }
                    .foregroundStyle(selectedTab == tab ? Color.accentColor : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 2)
    }

    // MARK: - Login

    @ViewBuilder
    private var loginContent: some View {
        switch authService.state {
        case .unknown, .validating:
            VStack {
                ProgressView()
                Text("Checking login...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 300)

        case .loggedOut:
            VStack(spacing: 16) {
                Image(systemName: "music.note.tv")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("YouTube Music")
                    .font(.title2.bold())

                Text(authService.needsReauth ? "Your session expired. Sign in again to keep listening." : "Sign in to start listening")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Button(authService.needsReauth ? "Sign In Again" : "Sign In") {
                    authService.startLogin()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .frame(maxWidth: .infinity, minHeight: 300)

        case .loggingIn:
            LoginView()
                .frame(width: 320, height: 480)

        case .loggedIn:
            EmptyView()
        }
    }
}

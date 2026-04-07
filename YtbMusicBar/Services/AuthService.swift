import Foundation
import WebKit
import Observation

/// Manages authentication state for YouTube Music.
@MainActor @Observable
final class AuthService {

    enum AuthState: Equatable {
        case unknown
        case loggedOut
        case loggingIn
        case validating
        case loggedIn

        var isLoggedIn: Bool {
            self == .loggedIn
        }
    }

    var state: AuthState = .unknown
    var needsReauth = false
    private let webKitManager: WebKitManager

    init(webKitManager: WebKitManager) {
        self.webKitManager = webKitManager
    }

    /// Check if we have valid cookies from a previous session.
    func checkLoginState() async {
        state = .validating

        let dataStore = WKWebsiteDataStore.default()
        _ = await webKitManager.restoreCookies(to: dataStore)

        if await webKitManager.hasAuthCookies(in: dataStore) {
            state = .loggedIn
            needsReauth = false
        } else {
            state = .loggedOut
        }
    }

    /// Called when the cookie observer detects auth cookies after user login.
    /// Saves cookies immediately (kaset: forceBackupCookies) and transitions to logged in.
    func completeLogin() {
        guard state != .loggedIn || needsReauth else { return }

        // Force save cookies to Keychain immediately (kaset pattern)
        Task {
            await webKitManager.saveCookies(from: WKWebsiteDataStore.default())
        }

        state = .loggedIn
        needsReauth = false
    }

    func sessionExpired() {
        state = .loggedOut
        needsReauth = true
    }

    /// Sign out: clear cookies and reset state.
    func signOut() async {
        webKitManager.clearCookies()

        let dataStore = WKWebsiteDataStore.default()
        let records = await dataStore.dataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes())
        for record in records {
            let displayName = record.displayName.lowercased()
            if displayName.contains("youtube") || displayName.contains("google") {
                await dataStore.removeData(ofTypes: record.dataTypes, for: [record])
            }
        }

        state = .loggedOut
        needsReauth = false
    }

    /// Start login flow (user will see WebView).
    func startLogin() {
        state = .loggingIn
    }
}

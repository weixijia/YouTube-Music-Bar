import Foundation
import WebKit
import Security

/// Manages WKWebView cookie persistence via macOS Keychain.
/// Stores auth cookies securely and restores them on app launch.
@MainActor @Observable
final class WebKitManager {

    private static let keychainService = "com.ytbmusicbar.cookies"
    private static let keychainAccount = "ytmusic-auth"

    /// Cookie names that can authenticate YouTube Music requests.
    private static let authCookieNames: Set<String> = ["__Secure-3PAPISID", "SAPISID"]

    /// The SAPISID value used for API authentication.
    var sapisid: String?

    /// Cached YouTube Music cookie header for API requests.
    var cookieHeader: String?

    // MARK: - Cookie Operations

    /// Save YouTube/Google cookies from WKWebView to Keychain.
    func saveCookies(from dataStore: WKWebsiteDataStore) async {
        let cookies = await dataStore.httpCookieStore.allCookies()
        updateCachedAuth(from: cookies)

        let authCookies = cookies.filter { isYouTubeOrGoogleCookie($0) && isPersistent($0) }
        guard !authCookies.isEmpty else { return }

        guard let data = try? NSKeyedArchiver.archivedData(
            withRootObject: authCookies,
            requiringSecureCoding: true
        ) else { return }

        saveToKeychain(data: data)
    }

    /// Restore cookies from Keychain into WKWebView.
    func restoreCookies(to dataStore: WKWebsiteDataStore) async -> Bool {
        guard let data = loadFromKeychain() else { return false }

        guard let cookies = try? NSKeyedUnarchiver.unarchivedObject(
            ofClasses: [NSArray.self, HTTPCookie.self, NSDictionary.self, NSString.self, NSNumber.self, NSDate.self],
            from: data
        ) as? [HTTPCookie] else { return false }

        for cookie in cookies {
            await dataStore.httpCookieStore.setCookie(cookie)
        }

        updateCachedAuth(from: cookies)
        return sapisid != nil
    }

    /// Check if auth cookies exist in a data store.
    func hasAuthCookies(in dataStore: WKWebsiteDataStore) async -> Bool {
        let cookies = await dataStore.httpCookieStore.allCookies()
        updateCachedAuth(from: cookies)
        return sapisid != nil
    }

    /// Returns the latest auth material for YouTube Music API requests.
    func currentAuthHeaders(for domain: String = "youtube.com") async -> (sapisid: String, cookieHeader: String?)? {
        let cookies = await WKWebsiteDataStore.default().httpCookieStore.allCookies()
        updateCachedAuth(from: cookies)

        guard let sapisid else { return nil }
        let domainCookies = cookiesMatching(domain: domain, in: cookies)
        let header = HTTPCookie.requestHeaderFields(with: domainCookies)["Cookie"]
        cookieHeader = header
        return (sapisid, header)
    }

    /// Clear all stored cookies.
    func clearCookies() {
        sapisid = nil
        cookieHeader = nil
        deleteFromKeychain()
    }

    // MARK: - Cookie Helpers

    private func updateCachedAuth(from cookies: [HTTPCookie]) {
        let domainCookies = cookiesMatching(domain: "music.youtube.com", in: cookies)
            .filter(isPersistent)

        let authDomainCookies = domainCookies.filter { Self.authCookieNames.contains($0.name) }

        if let secureCookie = authDomainCookies.first(where: { $0.name == "__Secure-3PAPISID" }) {
            sapisid = secureCookie.value
        } else if let fallbackCookie = authDomainCookies.first(where: { $0.name == "SAPISID" }) {
            sapisid = fallbackCookie.value
        } else {
            sapisid = nil
        }

        cookieHeader = HTTPCookie.requestHeaderFields(with: domainCookies)["Cookie"]
    }

    private func cookiesMatching(domain: String, in cookies: [HTTPCookie]) -> [HTTPCookie] {
        let normalizedDomain = domain.lowercased()
        return cookies.filter { cookie in
            guard isPersistent(cookie) else { return false }

            let cookieDomain = cookie.domain.lowercased()
            if cookieDomain == normalizedDomain {
                return true
            }
            if cookieDomain.hasPrefix(".") {
                let withoutDot = String(cookieDomain.dropFirst())
                return normalizedDomain == withoutDot || normalizedDomain.hasSuffix("." + withoutDot)
            }
            return normalizedDomain.hasSuffix("." + cookieDomain)
        }
    }

    private func isYouTubeOrGoogleCookie(_ cookie: HTTPCookie) -> Bool {
        let domain = cookie.domain.lowercased()
        return domain == "youtube.com" || domain == "google.com"
            || domain.hasSuffix(".youtube.com") || domain.hasSuffix(".google.com")
    }

    private func isPersistent(_ cookie: HTTPCookie) -> Bool {
        if let expiresDate = cookie.expiresDate {
            return expiresDate > Date()
        }
        return true
    }

    // MARK: - Keychain

    private func saveToKeychain(data: Data) {
        deleteFromKeychain() // Remove old entry first

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    private func deleteFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

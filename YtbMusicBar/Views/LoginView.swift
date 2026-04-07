import SwiftUI
import WebKit

/// Full-panel WebView for Google OAuth login to YouTube Music.
/// Login detection is handled by AppDelegate via the cookie observer.
struct LoginView: View {
    @Environment(AuthService.self) private var authService
    @Environment(SingletonPlayerWebView.self) private var playerWebView

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") {
                    authService.state = .loggedOut
                    restoreWebView()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                Spacer()
                Text(authService.needsReauth ? "Session expired — sign in again" : "Sign in to YouTube Music")
                    .font(.caption.bold())
                    .multilineTextAlignment(.center)
                Spacer()
                Color.clear.frame(width: 50, height: 1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            WebViewRepresentable(webView: playerWebView.webView)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            playerWebView.loadLoginPage()
        }
    }

    private func restoreWebView() {
        if let delegate = NSApp.delegate as? AppDelegate {
            delegate.restoreHiddenWebView()
        }
    }
}

struct WebViewRepresentable: NSViewRepresentable {
    let webView: WKWebView

    func makeNSView(context: Context) -> WKWebView {
        webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}

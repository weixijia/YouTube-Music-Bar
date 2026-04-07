import SwiftUI

@main
struct YtbMusicBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .onAppear {
                    if let window = NSApp.windows.first(where: { $0.title == "Settings" || $0.identifier?.rawValue == "com.apple.SwiftUI.SettingsWindow" }) {
                        window.isOpaque = false
                        window.backgroundColor = .clear
                    }
                }
        }
    }
}

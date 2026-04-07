import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showNotifications") private var showNotifications = true

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "gear") }

            accountTab
                .tabItem { Label("Account", systemImage: "person.crop.circle") }

            aboutTab
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 450, height: 300)
    }

    // MARK: - General

    private var generalTab: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        do {
                            if enabled {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            print("[Settings] Launch at login: \(error)")
                        }
                    }
            }

            Section("Notifications") {
                Toggle("Show track change notifications", isOn: $showNotifications)
            }

            Section("Cache") {
                HStack {
                    Text("Image Cache")
                    Spacer()
                    Button("Clear") {
                        CachedAsyncImage.clearCache()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Account

    private var accountTab: some View {
        Form {
            Section("YouTube Music Account") {
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading) {
                        Text("Signed In")
                            .font(.callout)
                        Text("via Google Account")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Sign Out", role: .destructive) {
                        signOut()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - About

    private var aboutTab: some View {
        Form {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "music.note")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.accentColor)

                    Text("Ytb Music Bar")
                        .font(.title3.bold())

                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.2.0")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section {
                Text("A native macOS menu bar app for YouTube Music with Liquid Glass design.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Actions

    private func signOut() {
        Task { @MainActor in
            guard let delegate = NSApp.delegate as? AppDelegate else { return }
            await delegate.authService.signOut()
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }

    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}

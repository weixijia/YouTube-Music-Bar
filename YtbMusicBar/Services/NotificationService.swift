import Foundation
import UserNotifications

/// Posts macOS notifications when the track changes (configurable).
@MainActor
final class NotificationService {

    private var lastNotifiedTrackId: String = ""

    func notifyTrackChange(track: Track) {
        guard UserDefaults.standard.bool(forKey: "showNotifications") else { return }
        guard !track.isEmpty, track.id != lastNotifiedTrackId else { return }

        lastNotifiedTrackId = track.id

        let content = UNMutableNotificationContent()
        content.title = track.title
        content.subtitle = track.artist
        content.sound = nil // Silent notification

        let request = UNNotificationRequest(
            identifier: "trackChange-\(track.id)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, _ in }
    }
}

import Foundation
import MediaPlayer
import AppKit

/// Manages media key remote commands.
/// Now Playing info display (album art in Control Center) is handled natively by
/// WKWebView's MediaSession — we only register MPRemoteCommandCenter handlers
/// to route media keys to our PlayerService. This matches kaset's approach.
@MainActor @Observable
final class NowPlayingManager {

    private let playerService: PlayerService
    private let commandCenter = MPRemoteCommandCenter.shared()

    init(playerService: PlayerService) {
        self.playerService = playerService
    }

    func setup() {
        setupRemoteCommands()
    }

    func teardown() {
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        commandCenter.nextTrackCommand.removeTarget(nil)
        commandCenter.previousTrackCommand.removeTarget(nil)
        commandCenter.changePlaybackPositionCommand.removeTarget(nil)
    }

    // MARK: - Remote Commands

    private func setupRemoteCommands() {
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.playerService.play() }
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.playerService.pause() }
            return .success
        }

        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.playerService.togglePlayPause() }
            return .success
        }

        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.playerService.nextTrack() }
            return .success
        }

        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.playerService.previousTrack() }
            return .success
        }

        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let posEvent = event as? MPChangePlaybackPositionCommandEvent,
                  let self else { return .commandFailed }
            let fraction = self.playerService.track.duration > 0
                ? posEvent.positionTime / self.playerService.track.duration
                : 0
            Task { @MainActor in self.playerService.seek(to: fraction) }
            return .success
        }
    }
}

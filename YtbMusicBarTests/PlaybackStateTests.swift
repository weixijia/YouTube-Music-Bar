import XCTest
@testable import Ytb_Music_Bar

final class PlaybackStateTests: XCTestCase {

    func testPlaybackStateIsPlaying() {
        XCTAssertTrue(PlaybackState.playing.isPlaying)
        XCTAssertFalse(PlaybackState.paused.isPlaying)
        XCTAssertFalse(PlaybackState.idle.isPlaying)
        XCTAssertFalse(PlaybackState.loading.isPlaying)
    }

    func testPlaybackStateIcons() {
        XCTAssertEqual(PlaybackState.playing.systemImageName, "pause.fill")
        XCTAssertEqual(PlaybackState.paused.systemImageName, "play.fill")
        XCTAssertEqual(PlaybackState.idle.systemImageName, "play.fill")
        XCTAssertEqual(PlaybackState.loading.systemImageName, "play.fill")
    }

    func testRepeatModeTransitions() {
        var mode = RepeatMode.off
        XCTAssertEqual(mode.systemImageName, "repeat")
        
        mode = mode.next
        XCTAssertEqual(mode, .all)
        XCTAssertEqual(mode.systemImageName, "repeat")
        
        mode = mode.next
        XCTAssertEqual(mode, .one)
        XCTAssertEqual(mode.systemImageName, "repeat.1")
        
        mode = mode.next
        XCTAssertEqual(mode, .off)
    }
}

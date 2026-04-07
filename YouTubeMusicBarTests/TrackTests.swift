import XCTest
@testable import YouTube_Music_Bar

final class TrackTests: XCTestCase {

    func testTrackInitialization() {
        let track = Track(videoId: "v123", title: "Test Song", artist: "Test Artist")
        XCTAssertEqual(track.videoId, "v123")
        XCTAssertEqual(track.title, "Test Song")
        XCTAssertEqual(track.artist, "Test Artist")
        XCTAssertFalse(track.isEmpty)
    }

    func testTrackEmptyState() {
        let track = Track.empty
        XCTAssertTrue(track.isEmpty)
        XCTAssertEqual(track.id, "")
        XCTAssertEqual(track.progress, 0)
    }

    func testTrackFormatting() {
        var track = Track.empty
        track.currentTime = 65
        track.duration = 125
        
        XCTAssertEqual(track.formattedCurrentTime, "1:05")
        XCTAssertEqual(track.formattedDuration, "2:05")
        XCTAssertEqual(track.progress, 65.0 / 125.0)
    }
}

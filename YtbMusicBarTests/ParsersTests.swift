import XCTest
@testable import Ytb_Music_Bar

final class ParsersTests: XCTestCase {

    func testDictionaryDig() {
        let dict: [String: Any] = [
            "level1": [
                "level2": [
                    "target": "found"
                ]
            ]
        ]
        
        let result = dict.dig("level1", "level2", "target") as? String
        XCTAssertEqual(result, "found")
        
        let missing = dict.dig("level1", "wrong", "target")
        XCTAssertNil(missing)
    }
    
    func testUpNextParser() {
        let json: [String: Any] = [
            "contents": [
                "singleColumnMusicWatchNextResultsRenderer": [
                    "tabbedRenderer": [
                        "watchNextTabbedResultsRenderer": [
                            "tabs": [
                                [
                                    "tabRenderer": [
                                        "content": [
                                            "musicQueueRenderer": [
                                                "content": [
                                                    "playlistPanelRenderer": [
                                                        "contents": [
                                                            [
                                                                "playlistPanelVideoRenderer": [
                                                                    "title": ["runs": [["text": "Next Song"]]],
                                                                    "shortBylineText": ["runs": [["text": "Next Artist"]]],
                                                                    "videoId": "xyz123"
                                                                ]
                                                            ]
                                                        ]
                                                    ]
                                                ]
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
        
        let tracks = UpNextParser.parse(json)
        XCTAssertEqual(tracks.count, 1)
        XCTAssertEqual(tracks.first?.title, "Next Song")
        XCTAssertEqual(tracks.first?.artist, "Next Artist")
        XCTAssertEqual(tracks.first?.videoId, "xyz123")
    }
}

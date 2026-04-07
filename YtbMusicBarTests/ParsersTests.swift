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

    func testTimedLyricsParserSupportsKasetShape() {
        let json: [String: Any] = [
            "contents": [
                "timedLyricsModel": [
                    "lyricsData": [
                        [
                            "lyricLine": "First line",
                            "startTimeMs": "1200",
                            "durationMs": "3000"
                        ],
                        [
                            "lyricLine": "Second line",
                            "startTimeMs": "4200",
                            "durationMs": "2500"
                        ]
                    ]
                ]
            ]
        ]

        let result = LyricsParser.extractTimedLyrics(from: json)
        XCTAssertEqual(result?.lines.count, 2)
        XCTAssertEqual(result?.lines.first?.text, "First line")
        XCTAssertEqual(result?.lines.first?.startTimeMs, 1200)
        XCTAssertTrue(result?.isSynced == true)
    }

    func testLRCParserSupportsLRCLibSyncedLyrics() {
        let raw = """
        [ar:Artist]
        [offset:100]
        [00:01.20]First line
        [00:03.45]<00:03.45>Second <00:04.00>line
        """

        let result = LRCParser.parse(raw, source: "LRCLib")
        XCTAssertEqual(result?.lines.count, 2)
        XCTAssertEqual(result?.lines[0].text, "First line")
        XCTAssertEqual(result?.lines[0].startTimeMs, 1100)
        XCTAssertEqual(result?.lines[1].text, "Second line")
        XCTAssertEqual(result?.lines[1].startTimeMs, 3350)
        XCTAssertEqual(result?.source, "LRCLib")
        XCTAssertTrue(result?.isSynced == true)
    }
}

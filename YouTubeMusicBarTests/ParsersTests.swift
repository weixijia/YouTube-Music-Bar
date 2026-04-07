import XCTest
@testable import YouTube_Music_Bar

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

    func testSearchParserSupportsAlbumAndPlaylistResults() {
        let json: [String: Any] = [
            "contents": [
                "tabbedSearchResultsRenderer": [
                    "tabs": [
                        [
                            "tabRenderer": [
                                "content": [
                                    "sectionListRenderer": [
                                        "contents": [
                                            [
                                                "musicShelfRenderer": [
                                                    "contents": [
                                                        [
                                                            "musicResponsiveListItemRenderer": [
                                                                "flexColumns": [
                                                                    [
                                                                        "musicResponsiveListItemFlexColumnRenderer": [
                                                                            "text": ["runs": [["text": "Album Result"]]]
                                                                        ]
                                                                    ],
                                                                    [
                                                                        "musicResponsiveListItemFlexColumnRenderer": [
                                                                            "text": ["runs": [["text": "Album Artist"]]]
                                                                        ]
                                                                    ],
                                                                ],
                                                                "navigationEndpoint": [
                                                                    "browseEndpoint": ["browseId": "MPREb_album"]
                                                                ],
                                                            ]
                                                        ],
                                                        [
                                                            "musicResponsiveListItemRenderer": [
                                                                "flexColumns": [
                                                                    [
                                                                        "musicResponsiveListItemFlexColumnRenderer": [
                                                                            "text": ["runs": [["text": "Playlist Result"]]]
                                                                        ]
                                                                    ],
                                                                    [
                                                                        "musicResponsiveListItemFlexColumnRenderer": [
                                                                            "text": ["runs": [["text": "Playlist Author"]]]
                                                                        ]
                                                                    ],
                                                                ],
                                                                "navigationEndpoint": [
                                                                    "watchPlaylistEndpoint": ["playlistId": "PLplaylist123"]
                                                                ],
                                                            ]
                                                        ],
                                                    ]
                                                ]
                                            ],
                                        ]
                                    ]
                                ]
                            ]
                        ],
                    ]
                ]
            ]
        ]

        let results = SearchResponseParser.parse(json)
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].title, "Album Result")
        XCTAssertEqual(results[0].resultType, .album)
        XCTAssertNil(results[0].videoId)
        XCTAssertNil(results[0].playlistId)
        XCTAssertEqual(results[0].browseId, "MPREb_album")
        XCTAssertEqual(results[1].title, "Playlist Result")
        XCTAssertEqual(results[1].resultType, .playlist)
        XCTAssertNil(results[1].videoId)
        XCTAssertEqual(results[1].playlistId, "PLplaylist123")
        XCTAssertNil(results[1].browseId)
    }

    func testBrowseParserPreservesCardShelfPlaylistIdentifiers() {
        let json: [String: Any] = [
            "contents": [
                "singleColumnBrowseResultsRenderer": [
                    "tabs": [
                        [
                            "tabRenderer": [
                                "content": [
                                    "sectionListRenderer": [
                                        "contents": [
                                            [
                                                "musicCardShelfRenderer": [
                                                    "header": [
                                                        "musicCardShelfHeaderBasicRenderer": [
                                                            "title": ["runs": [["text": "Made For You"]]]
                                                        ]
                                                    ],
                                                    "title": ["runs": [["text": "Daily Mix"]]],
                                                    "subtitle": ["runs": [["text": "Updated today"]]],
                                                    "onTap": [
                                                        "watchPlaylistEndpoint": ["playlistId": "RDAMVMplaylist"]
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

        let response = BrowseResponseParser.parse(json)
        XCTAssertEqual(response.sections.count, 1)
        XCTAssertEqual(response.sections[0].items.count, 1)
        let item = response.sections[0].items[0]
        XCTAssertEqual(item.title, "Daily Mix")
        XCTAssertEqual(item.resultType, .playlist)
        XCTAssertEqual(item.playlistId, "RDAMVMplaylist")
        XCTAssertNil(item.videoId)
    }

    func testBrowseShelfParserSeparatesSongAndPlaylistIdentifiers() {
        let json: [String: Any] = [
            "contents": [
                "singleColumnBrowseResultsRenderer": [
                    "tabs": [
                        [
                            "tabRenderer": [
                                "content": [
                                    "sectionListRenderer": [
                                        "contents": [
                                            [
                                                "musicShelfRenderer": [
                                                    "title": ["runs": [["text": "Shelf"]]],
                                                    "contents": [
                                                        [
                                                            "musicResponsiveListItemRenderer": [
                                                                "flexColumns": [
                                                                    ["musicResponsiveListItemFlexColumnRenderer": ["text": ["runs": [["text": "Song Item"]]]]],
                                                                    ["musicResponsiveListItemFlexColumnRenderer": ["text": ["runs": [["text": "Artist"]]]]]
                                                                ],
                                                                "navigationEndpoint": ["watchEndpoint": ["videoId": "song123"]]
                                                            ]
                                                        ],
                                                        [
                                                            "musicResponsiveListItemRenderer": [
                                                                "flexColumns": [
                                                                    ["musicResponsiveListItemFlexColumnRenderer": ["text": ["runs": [["text": "Playlist Item"]]]]],
                                                                    ["musicResponsiveListItemFlexColumnRenderer": ["text": ["runs": [["text": "Curator"]]]]]
                                                                ],
                                                                "navigationEndpoint": ["watchPlaylistEndpoint": ["playlistId": "PL987"]]
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

        let response = BrowseResponseParser.parse(json)
        XCTAssertEqual(response.sections.count, 1)
        XCTAssertEqual(response.sections[0].items.count, 2)
        XCTAssertEqual(response.sections[0].items[0].videoId, "song123")
        XCTAssertNil(response.sections[0].items[0].playlistId)
        XCTAssertEqual(response.sections[0].items[1].playlistId, "PL987")
        XCTAssertNil(response.sections[0].items[1].videoId)
    }

    func testSearchParserPrefersAlbumTypeWhenBrowseIdAndPlaylistIdCoexist() {
        let json: [String: Any] = [
            "contents": [
                "tabbedSearchResultsRenderer": [
                    "tabs": [[
                        "tabRenderer": [
                            "content": [
                                "sectionListRenderer": [
                                    "contents": [[
                                        "musicShelfRenderer": [
                                            "contents": [[
                                                "musicResponsiveListItemRenderer": [
                                                    "flexColumns": [
                                                        ["musicResponsiveListItemFlexColumnRenderer": ["text": ["runs": [["text": "Album With Playlist"]]]]],
                                                        ["musicResponsiveListItemFlexColumnRenderer": ["text": ["runs": [["text": "Artist"]]]]]
                                                    ],
                                                    "navigationEndpoint": [
                                                        "browseEndpoint": ["browseId": "MPRE_album_123"],
                                                        "watchPlaylistEndpoint": ["playlistId": "PL_album_playlist"]
                                                    ]
                                                ]
                                            ]]
                                        ]
                                    ]]
                                ]
                            ]
                        ]
                    ]]
                ]
            ]
        ]

        let results = SearchResponseParser.parse(json)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].resultType, .album)
        XCTAssertEqual(results[0].playlistId, "PL_album_playlist")
        XCTAssertEqual(results[0].browseId, "MPRE_album_123")
    }

    func testPlaylistParserPrefersEndpointPlaylistIdOverUnrelatedNestedValue() {
        let json: [String: Any] = [
            "contents": [
                "singleColumnBrowseResultsRenderer": [
                    "tabs": [[
                        "tabRenderer": [
                            "content": [
                                "sectionListRenderer": [
                                    "contents": [[
                                        "musicShelfRenderer": [
                                            "contents": [[
                                                "musicResponsiveListItemRenderer": [
                                                    "flexColumns": [
                                                        ["musicResponsiveListItemFlexColumnRenderer": ["text": ["runs": [["text": "Song"]]]]],
                                                        ["musicResponsiveListItemFlexColumnRenderer": ["text": ["runs": [["text": "Artist"]]]]]
                                                    ],
                                                    "navigationEndpoint": [
                                                        "watchEndpoint": [
                                                            "videoId": "song123",
                                                            "playlistId": "PL_correct_context"
                                                        ]
                                                    ],
                                                    "menu": [
                                                        "menuRenderer": [
                                                            "items": [[
                                                                "menuNavigationItemRenderer": [
                                                                    "navigationEndpoint": [
                                                                        "browseEndpoint": [
                                                                            "browseId": "MISC",
                                                                            "playlistId": "PL_wrong_nested"
                                                                        ]
                                                                    ]
                                                                ]
                                                            ]]
                                                        ]
                                                    ]
                                                ]
                                            ]]
                                        ]
                                    ]]
                                ]
                            ]
                        ]
                    ]]
                ]
            ]
        ]

        let detail = PlaylistParser.parse(json)
        XCTAssertEqual(detail.playlistId, "PL_correct_context")
    }
}

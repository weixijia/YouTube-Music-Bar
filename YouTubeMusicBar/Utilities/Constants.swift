import Foundation

enum Constants {
    static let ytMusicURL = URL(string: "https://music.youtube.com")!
    static let ytMusicLoginURL = URL(string: "https://accounts.google.com/ServiceLogin?service=youtube&uilel=3&passive=true&continue=https%3A%2F%2Fwww.youtube.com%2Fsignin%3Faction_handle_signin%3Dtrue%26app%3Ddesktop%26hl%3Den%26next%3Dhttps%253A%252F%252Fmusic.youtube.com%252F")!

    static let safariUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        + "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

    static let blockServiceWorkerRule = """
    [{
        "trigger": {"url-filter": ".*sw\\\\.js$"},
        "action": {"type": "block"}
    }]
    """

    // YouTube Music API
    static let ytMusicAPIBase = URL(string: "https://music.youtube.com/youtubei/v1")!
    static let ytMusicAPIKey = "AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30"
}

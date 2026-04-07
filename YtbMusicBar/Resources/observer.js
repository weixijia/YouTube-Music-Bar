// observer.js — YouTube Music playback state observer
// Matching kaset's pattern: MutationObserver + video events + Player API fallback + 1Hz polling

(function() {
    'use strict';

    const SELECTORS = {
        playerBar: 'ytmusic-player-bar',
        title: '.title.ytmusic-player-bar',
        artist: '.byline.ytmusic-player-bar a',
        albumArt: 'img.image.ytmusic-player-bar',
        video: 'video',
        likeButton: 'ytmusic-like-button-renderer',
        progressBar: '#progress-bar',
        // Fallbacks
        titleAlt: '.title.ytmusic-player-bar .yt-formatted-string',
        artistAlt: '.subtitle .yt-formatted-string a',
    };

    let lastSentData = '';
    let lastUpdateTime = 0;
    const THROTTLE_MS = 500;
    let pollInterval = null;
    let currentVideoElement = null;

    function querySelector(primary, fallback) {
        return document.querySelector(primary) || (fallback ? document.querySelector(fallback) : null);
    }

    // Try to get metadata from YouTube's internal player API (more reliable than DOM)
    function getPlayerAPIData() {
        try {
            const player = document.querySelector('ytmusic-player');
            if (player && player.playerApi) {
                const data = player.playerApi.getVideoData();
                if (data) {
                    return {
                        videoId: data.video_id || '',
                        title: data.title || '',
                        artist: data.author || '',
                    };
                }
            }
        } catch (e) {}

        // Fallback: movie_player
        try {
            const mp = document.getElementById('movie_player');
            if (mp && mp.getVideoData) {
                const data = mp.getVideoData();
                if (data) {
                    return {
                        videoId: data.video_id || '',
                        title: data.title || '',
                        artist: data.author || '',
                    };
                }
            }
        } catch (e) {}

        return null;
    }

    function getTrackInfo() {
        // DOM-based metadata
        const titleEl = querySelector(SELECTORS.title, SELECTORS.titleAlt);
        const domTitle = titleEl?.textContent?.trim() || '';

        const artistElements = document.querySelectorAll(SELECTORS.artist);
        let domArtist = '';
        if (artistElements.length > 0) {
            domArtist = Array.from(artistElements).map(a => a.textContent.trim()).join(', ');
        } else {
            const altArtist = document.querySelector(SELECTORS.artistAlt);
            domArtist = altArtist?.textContent?.trim() || '';
        }

        // Player API metadata (preferred when available — DOM can lag behind)
        const apiData = getPlayerAPIData();
        let title = domTitle;
        let artist = domArtist;
        let videoId = '';

        if (apiData && apiData.videoId) {
            videoId = apiData.videoId;
            // Prefer API title/artist if DOM is empty or stale
            if (!title || (apiData.title && apiData.title !== title)) {
                title = apiData.title || title;
            }
            if (!artist && apiData.artist) {
                artist = apiData.artist;
            }
        }

        // Fallback: video ID from URL
        if (!videoId) {
            try {
                const url = new URL(window.location.href);
                videoId = url.searchParams.get('v') || '';
            } catch (e) {}
        }

        // Album art
        const artImg = querySelector(SELECTORS.albumArt);
        let albumArt = artImg?.src || '';
        if (albumArt) {
            albumArt = albumArt.replace(/=w\d+-h\d+/, '=w544-h544');
        }

        // Playback state from video element (language-agnostic, like kaset)
        const video = document.querySelector(SELECTORS.video);
        const isPlaying = video ? !video.paused : false;
        const currentTime = video?.currentTime || 0;
        let duration = video?.duration || 0;

        // Also try progress bar for duration (more reliable when video hasn't loaded)
        if (!duration || !isFinite(duration)) {
            const progressBar = document.querySelector(SELECTORS.progressBar);
            if (progressBar) {
                const max = parseFloat(progressBar.getAttribute('aria-valuemax'));
                if (max && isFinite(max)) duration = max;
            }
        }

        const volume = video ? Math.round(video.volume * 100) : 100;

        // Album title
        const albumEl = document.querySelector('.byline.ytmusic-player-bar .yt-formatted-string[title]');
        const albumTitle = albumEl?.getAttribute('title') || '';

        // Like state
        const likeBtn = document.querySelector(SELECTORS.likeButton);
        const isLiked = likeBtn?.getAttribute('like-status') === 'LIKE';

        return {
            title, artist, albumArt, videoId, albumTitle,
            isPlaying, currentTime, duration, volume, isLiked,
        };
    }

    function sendUpdate() {
        const now = Date.now();
        if (now - lastUpdateTime < THROTTLE_MS) return;
        lastUpdateTime = now;

        const data = getTrackInfo();
        const serialized = JSON.stringify(data);

        if (serialized !== lastSentData) {
            lastSentData = serialized;
            try {
                window.webkit.messageHandlers.observer.postMessage(data);
            } catch (e) {}
        }
    }

    // Force send (bypasses deduplication, still throttled)
    function forceSend() {
        const now = Date.now();
        if (now - lastUpdateTime < 200) return; // 200ms min between force sends
        lastUpdateTime = now;

        const data = getTrackInfo();
        lastSentData = JSON.stringify(data);
        try {
            window.webkit.messageHandlers.observer.postMessage(data);
        } catch (e) {}
    }

    function sendTrackEnded() {
        try {
            window.webkit.messageHandlers.trackEnded.postMessage({});
        } catch (e) {}
    }

    // Attach listeners to a video element
    function attachVideoListeners(video) {
        if (!video || video === currentVideoElement) return;
        currentVideoElement = video;

        video.addEventListener('play', sendUpdate);
        video.addEventListener('playing', sendUpdate);
        video.addEventListener('pause', sendUpdate);
        video.addEventListener('ended', sendTrackEnded);
        video.addEventListener('volumechange', sendUpdate);
        video.addEventListener('seeked', sendUpdate);
        video.addEventListener('loadedmetadata', sendUpdate);
    }

    // Watch for DOM changes in the player bar
    function startObserver() {
        const playerBar = document.querySelector(SELECTORS.playerBar);
        if (!playerBar) {
            setTimeout(startObserver, 500);
            return;
        }

        // Player bar MutationObserver (matching kaset's config)
        const observer = new MutationObserver(() => {
            // Debounce at 100ms like kaset
            clearTimeout(observer._debounceTimer);
            observer._debounceTimer = setTimeout(sendUpdate, 100);
        });
        observer.observe(playerBar, {
            subtree: true,
            childList: true,
            characterData: true,
            attributes: true,
            attributeFilter: ['src', 'title', 'aria-label', 'like-status', 'value', 'aria-valuemax'],
        });

        // Video element listeners
        const video = document.querySelector(SELECTORS.video);
        if (video) attachVideoListeners(video);

        // Body-level observer to detect video element replacement (kaset pattern)
        const bodyObserver = new MutationObserver(() => {
            const newVideo = document.querySelector(SELECTORS.video);
            if (newVideo && newVideo !== currentVideoElement) {
                attachVideoListeners(newVideo);
                sendUpdate();
            }
        });
        bodyObserver.observe(document.body, { childList: true, subtree: true });

        // 1Hz polling for time updates during playback
        setInterval(() => {
            const video = document.querySelector(SELECTORS.video);
            if (video && !video.paused) {
                forceSend();
            }
        }, 1000);

        // Initial send
        sendUpdate();
    }

    // Start when DOM is ready
    if (document.readyState === 'complete' || document.readyState === 'interactive') {
        startObserver();
    } else {
        document.addEventListener('DOMContentLoaded', startObserver);
    }
})();

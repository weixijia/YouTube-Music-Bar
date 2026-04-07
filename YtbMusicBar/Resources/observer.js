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
        shuffleButton: '.shuffle.ytmusic-player-bar',
        repeatButton: '.repeat.ytmusic-player-bar',
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
    let lyricsPollId = null;

    function querySelector(primary, fallback) {
        return document.querySelector(primary) || (fallback ? document.querySelector(fallback) : null);
    }

    function collectButtonStrings(element) {
        if (!element) return '';

        const candidates = [
            element,
            element.querySelector('button'),
            element.querySelector('[aria-label]'),
            element.querySelector('[title]'),
        ].filter(Boolean);

        const values = [];
        for (const candidate of candidates) {
            values.push(
                candidate.getAttribute?.('aria-pressed'),
                candidate.getAttribute?.('aria-label'),
                candidate.getAttribute?.('title'),
                candidate.getAttribute?.('repeat-mode'),
                candidate.getAttribute?.('data-repeat-mode'),
                candidate.getAttribute?.('data-tooltip-text'),
                candidate.getAttribute?.('icon'),
                candidate.textContent
            );
        }

        return values
            .filter(Boolean)
            .join(' ')
            .toLowerCase();
    }

    function getShuffleState() {
        const shuffleBtn = document.querySelector(SELECTORS.shuffleButton);
        if (!shuffleBtn) return false;

        const pressed = shuffleBtn.getAttribute('aria-pressed')
            || shuffleBtn.querySelector('button')?.getAttribute('aria-pressed');
        if (pressed === 'true') return true;
        if (pressed === 'false') return false;

        const text = collectButtonStrings(shuffleBtn);
        return text.includes('shuffle on') || text.includes('turn off shuffle') || text.includes('shuffle is on');
    }

    function getRepeatMode() {
        const repeatBtn = document.querySelector(SELECTORS.repeatButton);
        if (!repeatBtn) return 0;

        const text = collectButtonStrings(repeatBtn);
        if (text.includes('repeat one') || text.includes('repeat 1') || text.includes('repeat this song')) {
            return 2;
        }
        if (
            text.includes('repeat all')
            || text.includes('repeat on')
            || text.includes('turn off repeat')
            || text.includes('disable repeat')
        ) {
            return 1;
        }

        return 0;
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

        let playlistId = '';

        if (!videoId) {
            try {
                const url = new URL(window.location.href);
                videoId = url.searchParams.get('v') || '';
                playlistId = url.searchParams.get('list') || '';
            } catch (e) {}
        } else {
            try {
                const url = new URL(window.location.href);
                playlistId = url.searchParams.get('list') || '';
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
        const isShuffle = getShuffleState();
        const repeatMode = getRepeatMode();

        return {
            title, artist, albumArt, videoId, playlistId, albumTitle,
            isPlaying, currentTime, duration, volume, isLiked, isShuffle, repeatMode,
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

    window.startLyricsPoll = function() {
        if (lyricsPollId) return;
        lyricsPollId = setInterval(() => {
            const video = document.querySelector(SELECTORS.video);
            if (!video) return;
            try {
                window.webkit.messageHandlers.lyricsTime.postMessage({ time: video.currentTime });
            } catch (e) {}
        }, 100);
    };

    window.stopLyricsPoll = function() {
        if (!lyricsPollId) return;
        clearInterval(lyricsPollId);
        lyricsPollId = null;
    };

    window.ytmForceSendUpdate = forceSend;

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
            attributeFilter: ['src', 'title', 'aria-label', 'aria-pressed', 'like-status', 'repeat-mode', 'data-repeat-mode', 'value', 'aria-valuemax'],
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

    window.addEventListener('popstate', forceSend);

    const originalPushState = history.pushState;
    history.pushState = function() {
        const result = originalPushState.apply(this, arguments);
        setTimeout(forceSend, 0);
        return result;
    };

    const originalReplaceState = history.replaceState;
    history.replaceState = function() {
        const result = originalReplaceState.apply(this, arguments);
        setTimeout(forceSend, 0);
        return result;
    };

    document.addEventListener('yt-navigate-finish', forceSend);

    // Start when DOM is ready
    if (document.readyState === 'complete' || document.readyState === 'interactive') {
        startObserver();
    } else {
        document.addEventListener('DOMContentLoaded', startObserver);
    }
})();

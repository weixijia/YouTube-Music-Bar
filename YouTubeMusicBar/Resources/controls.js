// controls.js — Playback control functions
// Matching kaset's patterns: DOM button clicks for nav, triple volume enforcement

function ytmPlay() {
    const video = document.querySelector('video');
    if (video && video.paused) video.play();
}

function ytmPause() {
    const video = document.querySelector('video');
    if (video && !video.paused) video.pause();
}

function ytmTogglePlayPause() {
    // Click the play/pause button in the player bar (like kaset)
    const btn = document.querySelector('.play-pause-button.ytmusic-player-bar');
    if (btn) { btn.click(); return; }
    // Fallback to video element
    const video = document.querySelector('video');
    if (!video) return;
    video.paused ? video.play() : video.pause();
}

function ytmNext() {
    // Click DOM button (more reliable than movie_player.nextVideo)
    const btn = document.querySelector('.next-button.ytmusic-player-bar');
    if (btn) { btn.click(); return; }
    // Fallback
    const player = document.getElementById('movie_player');
    if (player && player.nextVideo) player.nextVideo();
}

function ytmPrevious() {
    const btn = document.querySelector('.previous-button.ytmusic-player-bar');
    if (btn) { btn.click(); return; }
    const player = document.getElementById('movie_player');
    if (player && player.previousVideo) player.previousVideo();
}

function ytmSeekTo(seconds) {
    const video = document.querySelector('video');
    if (video) video.currentTime = seconds;
}

function ytmGetState() {
    const video = document.querySelector('video');
    return video ? (video.paused ? 2 : 1) : -1;
}

// --- Volume: Triple enforcement with feedback loop prevention (kaset pattern) ---

window.__ytbTargetVolume = 100;
window.__ytbIsSettingVolume = false;

function ytmSetVolume(value) {
    value = Math.max(0, Math.min(100, Math.round(value)));
    window.__ytbTargetVolume = value;

    // Set flag to prevent our own volumechange listener from reverting
    window.__ytbIsSettingVolume = true;
    _applyVolume(value);
    setTimeout(() => { window.__ytbIsSettingVolume = false; }, 50);

    // Burst enforcement: 15 × 200ms = 3 seconds (kaset pattern)
    let count = 0;
    const interval = setInterval(() => {
        window.__ytbIsSettingVolume = true;
        _applyVolume(value);
        setTimeout(() => { window.__ytbIsSettingVolume = false; }, 50);
        count++;
        if (count >= 15) clearInterval(interval);
    }, 200);
}

function _applyVolume(value) {
    // Method 1: Player API (ytmusic-player)
    try {
        const player = document.querySelector('ytmusic-player');
        if (player && player.playerApi) {
            player.playerApi.setVolume(value);
            if (value > 0) player.playerApi.unMute();
            else player.playerApi.mute();
        }
    } catch (e) {}

    // Method 2: movie_player
    const mp = document.getElementById('movie_player');
    if (mp) {
        if (mp.setVolume) mp.setVolume(value);
        if (mp.unMute && value > 0) mp.unMute();
        if (mp.mute && value === 0) mp.mute();
    }

    // Method 3: HTML5 video element
    const video = document.querySelector('video');
    if (video) {
        video.volume = value / 100;
        video.muted = (value === 0);
    }

    // Method 4: Volume slider (visual sync)
    const volumeSlider = document.querySelector('#volume-slider');
    if (volumeSlider && volumeSlider.value !== undefined) {
        volumeSlider.value = value;
    }
}

// Monitor for YouTube internal volume resets
(function() {
    function setupVolumeMonitor() {
        const video = document.querySelector('video');
        if (!video) { setTimeout(setupVolumeMonitor, 500); return; }

        video.addEventListener('volumechange', () => {
            // Skip if WE initiated the change
            if (window.__ytbIsSettingVolume) return;

            const currentVol = Math.round(video.volume * 100);
            if (Math.abs(currentVol - window.__ytbTargetVolume) > 2) {
                // YouTube reset our volume — re-apply
                window.__ytbIsSettingVolume = true;
                _applyVolume(window.__ytbTargetVolume);
                setTimeout(() => { window.__ytbIsSettingVolume = false; }, 50);
            }
        });

        // Also enforce on new track load events
        ['loadedmetadata', 'loadeddata', 'canplay'].forEach(event => {
            video.addEventListener(event, () => {
                window.__ytbIsSettingVolume = true;
                _applyVolume(window.__ytbTargetVolume);
                setTimeout(() => { window.__ytbIsSettingVolume = false; }, 50);
            });
        });
    }
    setupVolumeMonitor();
})();

// --- Shuffle / Repeat ---

function ytmToggleShuffle() {
    const btn = document.querySelector('.shuffle.ytmusic-player-bar');
    if (btn) {
        btn.click();
        setTimeout(() => {
            if (window.ytmForceSendUpdate) window.ytmForceSendUpdate();
        }, 150);
    }
}

function ytmCycleRepeat() {
    const btn = document.querySelector('.repeat.ytmusic-player-bar');
    if (btn) {
        btn.click();
        setTimeout(() => {
            if (window.ytmForceSendUpdate) window.ytmForceSendUpdate();
        }, 150);
    }
}

// --- Like / Dislike ---

function ytmToggleLike() {
    const likeBtn = document.querySelector('ytmusic-like-button-renderer #button-shape-like button');
    if (likeBtn) {
        likeBtn.click();
        setTimeout(() => {
            if (window.ytmForceSendUpdate) window.ytmForceSendUpdate();
        }, 150);
    }
}

function ytmToggleDislike() {
    const dislikeBtn = document.querySelector('ytmusic-like-button-renderer #button-shape-dislike button');
    if (dislikeBtn) dislikeBtn.click();
}

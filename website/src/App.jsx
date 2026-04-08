import { useEffect, useRef, useState } from 'react'
import './App.css'

function useInView(threshold = 0.15) {
  const ref = useRef(null)
  const [isVisible, setVisible] = useState(false)
  useEffect(() => {
    const el = ref.current
    if (!el) return
    const obs = new IntersectionObserver(
      ([entry]) => { if (entry.isIntersecting) { setVisible(true); obs.disconnect() } },
      { threshold }
    )
    obs.observe(el)
    return () => obs.disconnect()
  }, [threshold])
  return [ref, isVisible]
}

function Nav() {
  const [scrolled, setScrolled] = useState(false)
  useEffect(() => {
    const handler = () => setScrolled(window.scrollY > 40)
    window.addEventListener('scroll', handler, { passive: true })
    return () => window.removeEventListener('scroll', handler)
  }, [])

  return (
    <nav className={`nav ${scrolled ? 'nav--scrolled' : ''}`}>
      <div className="nav__inner">
        <a href="#" className="nav__logo">
          <span className="nav__logo-icon">▶</span>
          YouTube Music Bar
        </a>
        <div className="nav__links">
          <a href="#features">Features</a>
          <a href="#showcase">Showcase</a>
          <a href="#download" className="nav__cta">Download</a>
        </div>
      </div>
    </nav>
  )
}

function Hero() {
  return (
    <section className="hero">
      <div className="hero__bg-orbs">
        <div className="hero__orb hero__orb--1" />
        <div className="hero__orb hero__orb--2" />
        <div className="hero__orb hero__orb--3" />
      </div>

      <div className="hero__content fade-up">
        <div className="hero__badge">
          <span className="hero__badge-dot" />
          Available for macOS 14+
        </div>

        <h1 className="hero__title">
          Your YouTube Music.
          <br />
          <span className="hero__title-accent">On your menu bar.</span>
        </h1>

        <p className="hero__subtitle">
          A tiny, native macOS app that tucks YouTube Music into your menu bar.
          <br />
          No browser tab. No Dock icon. Just music, always nearby.
        </p>

        <div className="hero__actions">
          <a href="https://github.com/weixijia/YouTube-Music-Bar/releases" className="btn btn--primary">
            <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M8 12l-4-4h2.5V4h3v4H12L8 12z"/><path d="M13 13H3v1h10v-1z"/></svg>
            Download
          </a>
          <a href="https://github.com/weixijia/YouTube-Music-Bar" className="btn btn--glass">
            <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path fillRule="evenodd" d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z"/></svg>
            View on GitHub
          </a>
        </div>
      </div>

      <div className="hero__image fade-up fade-up-delay-2">
        <div className="hero__image-glow" />
        <img src="screenshot.png" alt="YouTube Music Bar" />
      </div>

      <div className="hero__scroll-hint">
        <div className="hero__scroll-line" />
      </div>
    </section>
  )
}

const features = [
  { icon: '🎨', title: 'Liquid Glass UI', desc: 'macOS Tahoe Liquid Glass styling with native vibrancy. Feels like it belongs on your Mac.' },
  { icon: '🎤', title: 'Live Lyrics', desc: 'Synced lyrics overlay on album art. Tap any line to seek. LRCLib fallback when YouTube has no timing data.' },
  { icon: '📌', title: 'Menu Bar Native', desc: 'Lives in your menu bar — no Dock icon, no browser tab. Click to open, click away to dismiss.' },
  { icon: '🎛️', title: 'Full Controls', desc: 'Play, pause, skip, seek, shuffle, repeat, like, volume — all from a compact native panel.' },
  { icon: '📚', title: 'Library Sync', desc: 'Your playlists, liked songs, and personalized home feed — all synced through your Google account.' },
  { icon: '📡', title: 'AirPlay', desc: 'Route audio to any AirPlay-compatible speaker or device from the built-in picker.' },
  { icon: '⌨️', title: 'Media Keys', desc: 'Keyboard media keys and Control Center integration work exactly as you would expect on macOS.' },
  { icon: '🔊', title: 'Background Play', desc: 'Close the panel and keep working. Your music never stops until you tell it to.' },
  { icon: '🔐', title: 'Keychain Secured', desc: 'Auth cookies stored in macOS Keychain. No plaintext passwords. No sketchy storage.' },
]

function Features() {
  const [ref, visible] = useInView()
  return (
    <section id="features" className="features" ref={ref}>
      <div className="features__inner">
        <div className={`section-header ${visible ? 'fade-up' : 'pre-fade'}`}>
          <h2 className="section-title">Everything you need.<br /><span className="text-accent">Nothing you don't.</span></h2>
          <p className="section-subtitle">Designed to stay out of your way while keeping your music one click away.</p>
        </div>

        <div className="features__grid">
          {features.map((f, i) => (
            <FeatureCard key={i} {...f} index={i} parentVisible={visible} />
          ))}
        </div>
      </div>
    </section>
  )
}

function FeatureCard({ icon, title, desc, index, parentVisible }) {
  return (
    <div
      className={`feature-card ${parentVisible ? 'fade-up' : 'pre-fade'}`}
      style={{ animationDelay: `${0.05 * index + 0.2}s` }}
    >
      <div className="feature-card__icon">{icon}</div>
      <h3 className="feature-card__title">{title}</h3>
      <p className="feature-card__desc">{desc}</p>
    </div>
  )
}

function Showcase() {
  const [ref, visible] = useInView()
  return (
    <section id="showcase" className="showcase" ref={ref}>
      <div className="showcase__inner">
        <div className={`section-header ${visible ? 'fade-up' : 'pre-fade'}`}>
          <h2 className="section-title">Designed for<br /><span className="text-accent">how you work.</span></h2>
          <p className="section-subtitle">A floating panel that appears when you need it and disappears when you don't.</p>
        </div>

        <div className={`showcase__cards ${visible ? 'fade-up fade-up-delay-2' : 'pre-fade'}`}>
          <div className="showcase-card">
            <div className="showcase-card__icon">💬</div>
            <h3>Menu Bar Lyrics</h3>
            <p>Current lyric line scrolls right in your status bar. Read along without switching apps.</p>
          </div>
          <div className="showcase-card showcase-card--accent">
            <div className="showcase-card__icon">🏠</div>
            <h3>Personalized Feed</h3>
            <p>Your mixes, recommendations, and "Listen Again" — all right from the compact Home tab.</p>
          </div>
          <div className="showcase-card">
            <div className="showcase-card__icon">📃</div>
            <h3>Queue & Up Next</h3>
            <p>See what's playing now and what's coming up next. Tap any track to jump ahead.</p>
          </div>
        </div>
      </div>
    </section>
  )
}

function Download() {
  const [ref, visible] = useInView()
  return (
    <section id="download" className="download" ref={ref}>
      <div className={`download__inner ${visible ? 'fade-up' : 'pre-fade'}`}>
        <div className="download__glow" />
        <h2 className="download__title">Ready to try?</h2>
        <p className="download__subtitle">Free and open-source. Download, unzip, and drop into Applications.</p>

        <div className="download__actions">
          <a href="https://github.com/weixijia/YouTube-Music-Bar/releases" className="btn btn--primary btn--lg">
            <svg width="20" height="20" viewBox="0 0 16 16" fill="currentColor"><path d="M8 12l-4-4h2.5V4h3v4H12L8 12z"/><path d="M13 13H3v1h10v-1z"/></svg>
            Download for macOS
          </a>
        </div>

        <div className="download__note">
          <p>Requires macOS 14 Sonoma or later</p>
          <p>Universal binary — Apple Silicon & Intel</p>
        </div>

        <div className="download__code">
          <code>xattr -cr "/Applications/YouTube Music Bar.app"</code>
          <span className="download__code-hint">Run this if macOS blocks the unsigned app</span>
        </div>
      </div>
    </section>
  )
}

function Footer() {
  return (
    <footer className="footer">
      <div className="footer__inner">
        <p className="footer__disclaimer">
          YouTube Music Bar is an unofficial app and is not affiliated with YouTube or Google.<br />
          "YouTube", "YouTube Music" and the "YouTube Logo" are registered trademarks of Google Inc.
        </p>
        <div className="footer__links">
          <a href="https://github.com/weixijia/YouTube-Music-Bar">GitHub</a>
          <span className="footer__dot">·</span>
          <a href="https://github.com/weixijia/YouTube-Music-Bar/releases">Releases</a>
          <span className="footer__dot">·</span>
          <a href="https://github.com/weixijia/YouTube-Music-Bar/issues">Issues</a>
        </div>
        <p className="footer__copy">© 2025 YouTube Music Bar</p>
      </div>
    </footer>
  )
}

export default function App() {
  return (
    <>
      <Nav />
      <Hero />
      <Features />
      <Showcase />
      <Download />
      <Footer />
    </>
  )
}

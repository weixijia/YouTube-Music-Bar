import { useEffect, useRef, useState, createContext, useContext } from 'react'
import { languages, getTranslation } from './i18n'
import './App.css'

const LangContext = createContext('en')

function useLang() {
  return useContext(LangContext)
}

function useT() {
  const lang = useLang()
  return getTranslation(lang)
}

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

function LangSwitcher({ lang, setLang }) {
  const [open, setOpen] = useState(false)
  const ref = useRef(null)
  const current = languages.find(l => l.code === lang) || languages[0]

  useEffect(() => {
    const handler = (e) => { if (ref.current && !ref.current.contains(e.target)) setOpen(false) }
    document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [])

  return (
    <div className="lang-switcher" ref={ref}>
      <button className="lang-switcher__btn" onClick={() => setOpen(!open)}>
        <span>{current.flag}</span>
        <span className="lang-switcher__label">{current.label}</span>
        <span className="lang-switcher__arrow">{open ? '▲' : '▼'}</span>
      </button>
      {open && (
        <div className="lang-switcher__dropdown">
          {languages.map(l => (
            <button
              key={l.code}
              className={`lang-switcher__item ${l.code === lang ? 'lang-switcher__item--active' : ''}`}
              onClick={() => { setLang(l.code); setOpen(false) }}
            >
              <span>{l.flag}</span> {l.label}
            </button>
          ))}
        </div>
      )}
    </div>
  )
}

function Nav({ lang, setLang }) {
  const [scrolled, setScrolled] = useState(false)
  const t = useT()

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
          <a href="#features">{t.nav.features}</a>
          <a href="#showcase">{t.nav.showcase}</a>
          <LangSwitcher lang={lang} setLang={setLang} />
          <a href="#download" className="nav__cta">{t.nav.download}</a>
        </div>
      </div>
    </nav>
  )
}

function Hero() {
  const t = useT()
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
          {t.hero.badge}
        </div>

        <h1 className="hero__title">
          {t.hero.title1}
          <br />
          <span className="hero__title-accent">{t.hero.title2}</span>
        </h1>

        <p className="hero__subtitle">
          {t.hero.subtitle}
          <br />
          {t.hero.subtitle2}
        </p>

        <div className="hero__actions">
          <a href="https://github.com/weixijia/YouTube-Music-Bar/releases" className="btn btn--primary">
            <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M8 12l-4-4h2.5V4h3v4H12L8 12z"/><path d="M13 13H3v1h10v-1z"/></svg>
            {t.hero.btnDownload}
          </a>
          <a href="https://github.com/weixijia/YouTube-Music-Bar" className="btn btn--glass">
            <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path fillRule="evenodd" d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z"/></svg>
            {t.hero.btnGithub}
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

function Features() {
  const [ref, visible] = useInView()
  const t = useT()
  return (
    <section id="features" className="features" ref={ref}>
      <div className="features__inner">
        <div className={`section-header ${visible ? 'fade-up' : 'pre-fade'}`}>
          <h2 className="section-title">{t.features.title1}<br /><span className="text-accent">{t.features.title2}</span></h2>
          <p className="section-subtitle">{t.features.subtitle}</p>
        </div>

        <div className="features__grid">
          {t.features.items.map((f, i) => (
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
  const t = useT()
  return (
    <section id="showcase" className="showcase" ref={ref}>
      <div className="showcase__inner">
        <div className={`section-header ${visible ? 'fade-up' : 'pre-fade'}`}>
          <h2 className="section-title">{t.showcase.title1}<br /><span className="text-accent">{t.showcase.title2}</span></h2>
          <p className="section-subtitle">{t.showcase.subtitle}</p>
        </div>

        <div className={`showcase__cards ${visible ? 'fade-up fade-up-delay-2' : 'pre-fade'}`}>
          {t.showcase.cards.map((card, i) => (
            <div key={i} className={`showcase-card ${i === 1 ? 'showcase-card--accent' : ''}`}>
              <div className="showcase-card__icon">{card.icon}</div>
              <h3>{card.title}</h3>
              <p>{card.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}

function Download() {
  const [ref, visible] = useInView()
  const t = useT()
  return (
    <section id="download" className="download" ref={ref}>
      <div className={`download__inner ${visible ? 'fade-up' : 'pre-fade'}`}>
        <div className="download__glow" />
        <h2 className="download__title">{t.download.title}</h2>
        <p className="download__subtitle">{t.download.subtitle}</p>

        <div className="download__actions">
          <a href="https://github.com/weixijia/YouTube-Music-Bar/releases" className="btn btn--primary btn--lg">
            <svg width="20" height="20" viewBox="0 0 16 16" fill="currentColor"><path d="M8 12l-4-4h2.5V4h3v4H12L8 12z"/><path d="M13 13H3v1h10v-1z"/></svg>
            {t.download.btn}
          </a>
        </div>

        <div className="download__note">
          <p>{t.download.req}</p>
          <p>{t.download.universal}</p>
        </div>

        <div className="download__code">
          <code>xattr -cr "/Applications/YouTube Music Bar.app"</code>
          <span className="download__code-hint">{t.download.codeHint}</span>
        </div>
      </div>
    </section>
  )
}

function Footer() {
  const t = useT()
  return (
    <footer className="footer">
      <div className="footer__inner">
        <p className="footer__disclaimer">
          {t.footer.disclaimer}<br />
          {t.footer.trademark}
        </p>
        <div className="footer__links">
          <a href="https://github.com/weixijia/YouTube-Music-Bar">GitHub</a>
          <span className="footer__dot">·</span>
          <a href="https://github.com/weixijia/YouTube-Music-Bar/releases">Releases</a>
          <span className="footer__dot">·</span>
          <a href="https://github.com/weixijia/YouTube-Music-Bar/issues">Issues</a>
        </div>
        <p className="footer__copy">© 2026 YouTube Music Bar</p>
      </div>
    </footer>
  )
}

export default function App() {
  const [lang, setLang] = useState(() => {
    const saved = localStorage.getItem('ytmb-lang')
    if (saved && languages.some(l => l.code === saved)) return saved
    const browserLang = navigator.language.toLowerCase()
    if (browserLang.startsWith('zh')) return 'cn'
    if (browserLang.startsWith('ja')) return 'jp'
    if (browserLang.startsWith('ko')) return 'kr'
    if (browserLang.startsWith('fr')) return 'fr'
    if (browserLang.startsWith('de')) return 'de'
    if (browserLang.startsWith('it')) return 'it'
    if (browserLang.startsWith('es')) return 'es'
    return 'en'
  })

  useEffect(() => { localStorage.setItem('ytmb-lang', lang) }, [lang])

  return (
    <LangContext.Provider value={lang}>
      <Nav lang={lang} setLang={setLang} />
      <Hero />
      <Features />
      <Showcase />
      <Download />
      <Footer />
    </LangContext.Provider>
  )
}

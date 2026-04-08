# 🎵 YouTube Music Bar

> YouTube Music, versteckt in deiner Mac-Menüleiste.

🌐 [🇬🇧 English](../README.md) | [🇨🇳 中文](README_CN.md) | [🇯🇵 日本語](README_JP.md) | [🇰🇷 한국어](README_KR.md) | [🇫🇷 Français](README_FR.md) | [🇩🇪 Deutsch](README_DE.md) | [🇮🇹 Italiano](README_IT.md) | [🇪🇸 Español](README_ES.md)

<p align="center">
  <img src="screenshot.png" alt="YouTube Music Bar Screenshot" width="680">
</p>

<p align="center">
  <em>Home-Feed & Aktuelle Wiedergabe — alles in einem kompakten schwebenden Panel</em>
</p>

---

YouTube Music Bar ist eine kleine, native macOS-App für alle, die ihre Musik griffbereit haben möchten — ohne einen Browser-Tab oder einen Dock-Platz dafür zu opfern. Sie lebt in der Menüleiste, öffnet ein kompaktes Panel und steht dir nicht im Weg.

Klicken, Song wählen, weiterarbeiten. ✨

## ✨ Funktionen

- 🎵 **Menüleiste nativ** — Lebt in der macOS-Menüleiste, kein Dock-Symbol, kein Browser-Tab nötig
- 🔍 **Schnelle Suche** — Finde Songs, Alben und Playlists mit Debounce-Suche und Filterchips
- 🏠 **Home-Feed** — Personalisierte Empfehlungen, Mixe und „Nochmal hören"-Bereich von YouTube Music
- 📚 **Bibliothek & Lieblingslieder** — Durchsuche gespeicherte Playlists und gelikte Songs mit Paginierung
- 🎛️ **Volle Wiedergabesteuerung** — Play, Pause, Überspringen, Suchen, Shuffle, Repeat und Like — alles in nativer macOS-UI
- 📃 **Warteschlange / Als Nächstes** — Sieh, was gerade spielt und was als nächstes kommt
- 🎤 **Synchronisierte Lyrics** — Zeilenweise Lyrics-Überlagerung auf dem Album-Cover, tippe auf eine Zeile zum Springen, LRCLib-Fallback
- 💬 **Lyrics in der Menüleiste** — Die aktuelle Textzeile scrollt in der Statusleiste, während du arbeitest
- 🎧 **Medientasten-Support** — Play/Pause, Vor, Zurück und Suchen über Tastatur-Medientasten und Kontrollzentrum
- 📡 **AirPlay** — Leite Audio über den integrierten Picker an AirPlay-Geräte
- 🔔 **Track-Benachrichtigungen** — Werde benachrichtigt, wenn der Track wechselt (optional)
- 🔊 **Hintergrundwiedergabe** — Musik spielt weiter, auch wenn das Panel geschlossen ist
- 🚀 **Start bei Anmeldung** — Automatischer Start beim Login
- 🎨 **Liquid Glass Design** — macOS Tahoe Liquid Glass-Styling mit Vibrancy-Fallback auf älteren Systemen
- 🔐 **Sichere Authentifizierung** — Google-Anmeldung über WebView, Cookies im macOS-Schlüsselbund gespeichert

## 📋 Voraussetzungen

- macOS 14 (Sonoma) oder neuer
- Ein [Google](https://accounts.google.com)-Konto mit Zugang zu YouTube Music

## 📦 Installation

### Download

Lade die neueste `.dmg` von der [**Releases**](https://github.com/user/YouTube-Music-Bar/releases)-Seite herunter.

> **Hinweis:** Die App ist derzeit nicht signiert.
> Falls macOS sie nach dem Verschieben nach `/Applications` blockiert, führe aus:
> ```bash
> xattr -cr "/Applications/YouTube Music Bar.app"
> ```

### Aus dem Quellcode bauen

```bash
# 1. Repository klonen
git clone https://github.com/user/YouTube-Music-Bar.git
cd YouTube-Music-Bar

# 2. Xcode-Projekt generieren (erfordert XcodeGen)
xcodegen

# 3. Öffnen und ausführen
open YouTubeMusicBar.xcodeproj
# YouTubeMusicBar-Schema auswählen → Ausführen (⌘R)
```

Für vollständige Release-Build- und DMG-Paketierungsanweisungen siehe [RELEASE.md](../RELEASE.md).

## 🤝 Mitwirken

Beiträge sind willkommen! Erstelle gerne Issues oder reiche Pull Requests ein.

## ⚠️ Haftungsausschluss

YouTube Music Bar ist eine **inoffizielle** App und steht in **keiner Verbindung** zu YouTube oder Google.
„YouTube", „YouTube Music" und das „YouTube-Logo" sind eingetragene Marken von Google Inc.

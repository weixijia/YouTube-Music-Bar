# 🎵 YouTube Music Bar

> YouTube Music, nascosto nella barra dei menu del tuo Mac.

🌐 [🇬🇧 English](../README.md) | [🇨🇳 中文](README_CN.md) | [🇯🇵 日本語](README_JP.md) | [🇰🇷 한국어](README_KR.md) | [🇫🇷 Français](README_FR.md) | [🇩🇪 Deutsch](README_DE.md) | [🇮🇹 Italiano](README_IT.md) | [🇪🇸 Español](README_ES.md)

<p align="center">
  <img src="screenshot.png" alt="Screenshot di YouTube Music Bar" width="680">
</p>

<p align="center">
  <em>Feed Home & In riproduzione — tutto in un piccolo pannello flottante</em>
</p>

---

YouTube Music Bar è una piccola app macOS nativa per chi vuole la propria musica sempre a portata di mano — senza rinunciare a una scheda del browser o a un posto nel Dock. Vive nella barra dei menu, apre un pannello compatto e non ti disturba.

Clicca, scegli un brano, continua a lavorare. ✨

## ✨ Funzionalità

- 🎵 **Barra dei menu nativa** — Risiede nella barra dei menu di macOS, nessuna icona nel Dock, nessuna scheda del browser necessaria
- 🔍 **Ricerca rapida** — Trova canzoni, album e playlist con ricerca debounce e filtri
- 🏠 **Feed Home** — Raccomandazioni personalizzate, mix e sezione "Riascolta" di YouTube Music
- 📚 **Libreria & Brani preferiti** — Esplora le playlist salvate e i brani preferiti con paginazione
- 🎛️ **Controlli di riproduzione completi** — Play, pausa, salta, cerca, shuffle, ripeti e mi piace — tutto in UI macOS nativa
- 📃 **Coda / Prossimo brano** — Vedi cosa sta suonando e cosa arriva dopo
- 🎤 **Testi sincronizzati** — Sovrapposizione testi riga per riga sulla copertina dell'album, tocca una riga per cercare, fallback LRCLib
- 💬 **Testi nella barra dei menu** — La riga del testo attuale scorre nella barra di stato mentre lavori
- 🎧 **Supporto tasti multimediali** — Play/pausa, successivo, precedente e ricerca tramite tasti multimediali e Centro di Controllo
- 📡 **AirPlay** — Invia l'audio ai dispositivi AirPlay dal selettore integrato
- 🔔 **Notifiche traccia** — Ricevi una notifica quando cambia la traccia (opzionale)
- 🔊 **Riproduzione in background** — La musica continua anche quando il pannello è chiuso
- 🚀 **Avvio al login** — Avvio automatico all'accesso
- 🎨 **Design Liquid Glass** — Stile Liquid Glass di macOS Tahoe con fallback vibrancy sui sistemi precedenti
- 🔐 **Autenticazione sicura** — Accesso Google tramite WebView, cookie salvati nel Portachiavi macOS

## 📋 Requisiti

- macOS 14 (Sonoma) o successivo
- Un account [Google](https://accounts.google.com) con accesso a YouTube Music

## 📦 Installazione

### Download

Scarica l'ultimo `.dmg` dalla pagina [**Releases**](https://github.com/user/YouTube-Music-Bar/releases).

> **Nota:** L'app attualmente non è firmata.
> Se macOS la blocca dopo averla spostata in `/Applications`, esegui:
> ```bash
> xattr -cr "/Applications/YouTube Music Bar.app"
> ```

### Compilare dal codice sorgente

```bash
# 1. Clona il repository
git clone https://github.com/user/YouTube-Music-Bar.git
cd YouTube-Music-Bar

# 2. Genera il progetto Xcode (richiede XcodeGen)
xcodegen

# 3. Apri ed esegui
open YouTubeMusicBar.xcodeproj
# Seleziona lo schema YouTubeMusicBar → Esegui (⌘R)
```

Per le istruzioni complete di build e packaging DMG, vedi [RELEASE.md](../RELEASE.md).

## 🤝 Contribuire

I contributi sono benvenuti! Sentiti libero di aprire issue o inviare pull request.

## ⚠️ Disclaimer

YouTube Music Bar è un'app **non ufficiale** e **non è affiliata** a YouTube o Google.
"YouTube", "YouTube Music" e il "Logo YouTube" sono marchi registrati di Google Inc.

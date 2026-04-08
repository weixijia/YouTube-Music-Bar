# 🎵 YouTube Music Bar

> YouTube Music, niché dans la barre de menus de votre Mac.

🌐 [🇬🇧 English](../README.md) | [🇨🇳 中文](README_CN.md) | [🇯🇵 日本語](README_JP.md) | [🇰🇷 한국어](README_KR.md) | [🇫🇷 Français](README_FR.md) | [🇩🇪 Deutsch](README_DE.md) | [🇮🇹 Italiano](README_IT.md) | [🇪🇸 Español](README_ES.md)

<p align="center">
  <img src="screenshot.png" alt="Capture d'écran YouTube Music Bar" width="680">
</p>

<p align="center">
  <em>Flux d'accueil & Lecture en cours — le tout dans un petit panneau flottant</em>
</p>

---

YouTube Music Bar est une petite application macOS native pour ceux qui veulent garder leur musique à portée de main — sans sacrifier un onglet de navigateur ni une place dans le Dock. Elle vit dans la barre de menus, ouvre un panneau compact et ne vous dérange pas.

Cliquez, choisissez un morceau, continuez à travailler. ✨

## ✨ Fonctionnalités

- 🎵 **Barre de menus native** — Réside dans la barre de menus macOS, pas d'icône dans le Dock, pas d'onglet navigateur nécessaire
- 🔍 **Recherche rapide** — Trouvez des chansons, albums et playlists avec recherche débounce et filtres
- 🏠 **Flux d'accueil** — Recommandations personnalisées, mix et section « Réecouter » de YouTube Music
- 📚 **Bibliothèque & Titres aimés** — Parcourez vos playlists sauvegardées et vos titres aimés avec pagination
- 🎛️ **Contrôles de lecture complets** — Lecture, pause, saut, recherche, aléatoire, répétition et j'aime — le tout en UI macOS native
- 📃 **File d'attente / À suivre** — Voyez ce qui joue et ce qui arrive ensuite
- 🎤 **Paroles synchronisées** — Superposition des paroles ligne par ligne sur la pochette, touchez une ligne pour naviguer, fallback LRCLib
- 💬 **Paroles dans la barre de menus** — La ligne de paroles actuelle défile dans la barre d'état pendant que vous travaillez
- 🎧 **Support des touches média** — Lecture/pause, suivant, précédent et recherche via les touches média et le Centre de contrôle
- 📡 **AirPlay** — Envoyez l'audio vers des appareils AirPlay depuis le sélecteur intégré
- 🔔 **Notifications de piste** — Recevez une notification quand la piste change (optionnel)
- 🔊 **Lecture en arrière-plan** — La musique continue même quand le panneau est fermé
- 🚀 **Lancement au démarrage** — Démarrage automatique à la connexion
- 🎨 **Design Liquid Glass** — Style Liquid Glass de macOS Tahoe avec fallback vibrancy sur les systèmes plus anciens
- 🔐 **Authentification sécurisée** — Connexion Google via WebView, cookies stockés dans le trousseau macOS

## 📋 Prérequis

- macOS 14 (Sonoma) ou ultérieur
- Un compte [Google](https://accounts.google.com) avec accès à YouTube Music

## 📦 Installation

### Téléchargement

Téléchargez le dernier `.dmg` depuis la page [**Releases**](https://github.com/user/YouTube-Music-Bar/releases).

> **Note :** L'application n'est actuellement pas signée.
> Si macOS la bloque après l'avoir déplacée dans `/Applications`, exécutez :
> ```bash
> xattr -cr "/Applications/YouTube Music Bar.app"
> ```

### Compiler depuis les sources

```bash
# 1. Cloner le dépôt
git clone https://github.com/user/YouTube-Music-Bar.git
cd YouTube-Music-Bar

# 2. Générer le projet Xcode (nécessite XcodeGen)
xcodegen

# 3. Ouvrir et exécuter
open YouTubeMusicBar.xcodeproj
# Sélectionner le schéma YouTubeMusicBar → Exécuter (⌘R)
```

Pour les instructions complètes de build et de packaging DMG, voir [RELEASE.md](../RELEASE.md).

## 🤝 Contribuer

Les contributions sont les bienvenues ! N'hésitez pas à ouvrir des issues ou soumettre des pull requests.

## ⚠️ Avertissement

YouTube Music Bar est une application **non officielle** et n'est **pas affiliée** à YouTube ou Google.
« YouTube », « YouTube Music » et le « Logo YouTube » sont des marques déposées de Google Inc.

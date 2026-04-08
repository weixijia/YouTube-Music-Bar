# 🎵 YouTube Music Bar

> YouTube Music, escondido en la barra de menús de tu Mac.

🌐 🇬🇧 [English](../README.md) | 🇨🇳 [中文](README_CN.md) | 🇯🇵 [日本語](README_JP.md) | 🇰🇷 [한국어](README_KR.md) | 🇫🇷 [Français](README_FR.md) | 🇩🇪 [Deutsch](README_DE.md) | 🇮🇹 [Italiano](README_IT.md) | 🇪🇸 [Español](README_ES.md)

<p align="center">
  <img src="screenshot.png" alt="Captura de pantalla de YouTube Music Bar" width="680">
</p>

<p align="center">
  <em>Feed de inicio & Reproduciendo ahora — todo en un pequeño panel flotante</em>
</p>

---

YouTube Music Bar es una pequeña app nativa de macOS para quienes quieren tener su música cerca — sin sacrificar una pestaña del navegador ni un lugar en el Dock. Vive en la barra de menús, abre un panel compacto y no te molesta.

Haz clic, elige una canción, sigue trabajando. ✨

## ✨ Características

- 🎵 **Barra de menús nativa** — Reside en la barra de menús de macOS, sin icono en el Dock, sin pestaña de navegador necesaria
- 🔍 **Búsqueda rápida** — Encuentra canciones, álbumes y playlists con búsqueda debounce y filtros
- 🏠 **Feed de inicio** — Recomendaciones personalizadas, mixes y sección "Volver a escuchar" de YouTube Music
- 📚 **Biblioteca & Canciones favoritas** — Explora tus playlists guardadas y canciones favoritas con paginación
- 🎛️ **Controles de reproducción completos** — Reproducir, pausar, saltar, buscar, aleatorio, repetir y me gusta — todo en UI nativa de macOS
- 📃 **Cola / Siguiente** — Ve qué está sonando ahora y qué viene después
- 🎤 **Letras sincronizadas** — Superposición de letras línea por línea sobre la carátula, toca cualquier línea para buscar, fallback LRCLib
- 💬 **Letras en la barra de menús** — La línea de letra actual se desplaza en la barra de estado mientras trabajas
- 🎧 **Soporte de teclas multimedia** — Reproducir/pausar, siguiente, anterior y buscar mediante teclas multimedia y Centro de Control
- 📡 **AirPlay** — Envía audio a dispositivos AirPlay desde el selector integrado
- 🔔 **Notificaciones de pista** — Recibe una notificación cuando cambia la pista (opcional)
- 🔊 **Reproducción en segundo plano** — La música sigue sonando aunque el panel esté cerrado
- 🚀 **Iniciar al login** — Inicio automático al iniciar sesión
- 🎨 **Diseño Liquid Glass** — Estilo Liquid Glass de macOS Tahoe con fallback de vibrancy en sistemas anteriores
- 🔐 **Autenticación segura** — Inicio de sesión con Google vía WebView, cookies almacenadas en el llavero de macOS

## 📋 Requisitos

- macOS 14 (Sonoma) o posterior
- Una cuenta de [Google](https://accounts.google.com) con acceso a YouTube Music

## 📦 Instalación

### Descarga

Descarga el último `.dmg` desde la página de [**Releases**](https://github.com/user/YouTube-Music-Bar/releases).

> **Nota:** La app actualmente no está firmada.
> Si macOS la bloquea después de moverla a `/Applications`, ejecuta:
> ```bash
> xattr -cr "/Applications/YouTube Music Bar.app"
> ```

### Compilar desde el código fuente

```bash
# 1. Clonar el repositorio
git clone https://github.com/user/YouTube-Music-Bar.git
cd YouTube-Music-Bar

# 2. Generar el proyecto Xcode (requiere XcodeGen)
xcodegen

# 3. Abrir y ejecutar
open YouTubeMusicBar.xcodeproj
# Seleccionar el esquema YouTubeMusicBar → Ejecutar (⌘R)
```

Para instrucciones completas de build y empaquetado DMG, ver [RELEASE.md](../RELEASE.md).

## 🤝 Contribuir

¡Las contribuciones son bienvenidas! No dudes en abrir issues o enviar pull requests.

## ⚠️ Aviso legal

YouTube Music Bar es una app **no oficial** y **no está afiliada** a YouTube ni a Google.
"YouTube", "YouTube Music" y el "Logo de YouTube" son marcas registradas de Google Inc.

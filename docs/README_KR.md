# 🎵 YouTube Music Bar

> YouTube Music을 Mac 메뉴 바에 담다.

🌐 [English](../README.md) | [中文](README_CN.md) | [日本語](README_JP.md) | [한국어](README_KR.md)

<p align="center">
  <img src="screenshot.png" alt="YouTube Music Bar 스크린샷" width="680">
</p>

<p align="center">
  <em>홈 피드 & 지금 재생 중 — 모든 것이 작은 플로팅 패널 안에</em>
</p>

---

YouTube Music Bar는 음악을 가까이에 두고 싶지만 브라우저 탭이나 Dock 자리를 내주고 싶지 않은 사람들을 위한 작고 네이티브한 macOS 앱입니다. 메뉴 바에 상주하며, 컴팩트한 패널을 열고, 작업을 방해하지 않습니다.

클릭하고, 곡을 고르고, 일을 계속하세요. ✨

## ✨ 기능

- 🎵 **메뉴 바 상주** — macOS 메뉴 바에 상주, Dock 아이콘 없음, 브라우저 탭 불필요
- 🔍 **빠른 검색** — 디바운스 검색과 필터 칩으로 곡, 앨범, 플레이리스트를 빠르게 검색
- 🏠 **홈 피드** — YouTube Music의 맞춤 추천, 믹스, "다시 듣기" 섹션
- 📚 **라이브러리 & 좋아요 한 곡** — 저장된 플레이리스트와 좋아요 한 곡을 페이지네이션으로 탐색
- 🎛️ **전체 재생 컨트롤** — 재생, 일시정지, 건너뛰기, 탐색, 셔플, 반복, 좋아요 — 모두 네이티브 macOS UI
- 📃 **대기열 / 다음 곡** — 현재 재생 중인 곡과 다음 곡 확인
- 🎤 **동기화 가사** — 앨범 아트에 줄별 가사 오버레이, 아무 줄이나 탭하면 탐색, LRCLib 폴백
- 💬 **메뉴 바 가사** — 현재 가사 줄이 상태 바에서 스크롤 표시
- 🎧 **미디어 키 지원** — 키보드 미디어 키와 제어 센터로 재생/일시정지, 다음/이전, 탐색
- 📡 **AirPlay** — 내장 피커에서 AirPlay 기기로 오디오 출력
- 🔔 **트랙 알림** — 곡이 바뀌면 알림 (선택사항)
- 🔊 **백그라운드 재생** — 패널을 닫아도 음악이 계속 재생됩니다
- 🚀 **로그인 시 시작** — 로그인 시 자동으로 시작
- 🎨 **Liquid Glass 디자인** — macOS Tahoe Liquid Glass 스타일링, 이전 시스템에서는 vibrancy 폴백
- 🔐 **보안 인증** — WebView를 통한 Google 로그인, 쿠키는 macOS 키체인에 저장

## 📋 요구사항

- macOS 14 (Sonoma) 이상
- YouTube Music에 접근할 수 있는 [Google](https://accounts.google.com) 계정

## 📦 설치

### 다운로드

[**Releases**](https://github.com/user/YouTube-Music-Bar/releases) 페이지에서 최신 `.dmg`를 다운로드하세요.

> **참고:** 현재 서명되지 않은 앱입니다.
> `/Applications`로 이동한 후 macOS가 차단하면 다음을 실행하세요:
> ```bash
> xattr -cr "/Applications/YouTube Music Bar.app"
> ```

### 소스에서 빌드

```bash
# 1. 저장소 클론
git clone https://github.com/user/YouTube-Music-Bar.git
cd YouTube-Music-Bar

# 2. Xcode 프로젝트 생성 (XcodeGen 필요)
xcodegen

# 3. 열고 실행
open YouTubeMusicBar.xcodeproj
# YouTubeMusicBar 스키마 선택 → 실행 (⌘R)
```

릴리스 빌드 및 DMG 패키징에 대한 자세한 내용은 [RELEASE.md](../RELEASE.md)를 참조하세요.

## 🤝 기여하기

기여를 환영합니다! Issue나 Pull Request를 자유롭게 제출해 주세요.

## ⚠️ 면책 조항

YouTube Music Bar는 **비공식** 앱이며 YouTube 또는 Google과 **어떠한 관련도 없습니다**.
"YouTube", "YouTube Music" 및 "YouTube 로고"는 Google Inc.의 등록 상표입니다.

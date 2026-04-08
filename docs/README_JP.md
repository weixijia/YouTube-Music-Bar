# 🎵 YouTube Music Bar

> YouTube Music を、Mac のメニューバーに。

🌐 [English](../README.md) | [中文](README_CN.md) | [日本語](README_JP.md) | [한국어](README_KR.md)

<p align="center">
  <img src="screenshot.png" alt="YouTube Music Bar スクリーンショット" width="680">
</p>

<p align="center">
  <em>ホームフィード & 再生中 — すべてがコンパクトなフローティングパネルに</em>
</p>

---

YouTube Music Bar は、音楽をすぐそばに置きたいけれど、ブラウザのタブや Dock のスペースを犠牲にしたくない人のための、小さなネイティブ macOS アプリです。メニューバーに常駐し、コンパクトなパネルを開き、作業の邪魔をしません。

クリックして、曲を選んで、作業を続けましょう。✨

## ✨ 機能

- 🎵 **メニューバー常駐** — macOS メニューバーに常駐、Dock アイコンなし、ブラウザタブ不要
- 🔍 **クイック検索** — デバウンス検索とフィルターチップで曲、アルバム、プレイリストを素早く検索
- 🏠 **ホームフィード** — YouTube Music のパーソナライズされたおすすめ、ミックス、「もう一度聴く」セクション
- 📚 **ライブラリ & お気に入り** — 保存したプレイリストとお気に入りの曲をページネーション付きで閲覧
- 🎛️ **フル再生コントロール** — 再生、一時停止、スキップ、シーク、シャッフル、リピート、いいね — すべてネイティブ macOS UI
- 📃 **キュー / 次の曲** — 現在再生中と次に再生される曲を確認
- 🎤 **同期歌詞** — アルバムアートに歌詞をオーバーレイ表示、任意の行をタップでシーク、LRCLib フォールバック
- 💬 **メニューバー歌詞** — 現在の歌詞行がステータスバーでスクロール表示
- 🎧 **メディアキー対応** — キーボードのメディアキーとコントロールセンターで再生/一時停止、次/前、シーク
- 📡 **AirPlay** — 内蔵ピッカーから AirPlay デバイスにオーディオを出力
- 🔔 **トラック通知** — 曲が変わったときに通知（オプション）
- 🔊 **バックグラウンド再生** — パネルを閉じても音楽は再生し続けます
- 🚀 **ログイン時に起動** — ログイン時に自動起動
- 🎨 **Liquid Glass デザイン** — macOS Tahoe の Liquid Glass スタイリング、古いシステムでは vibrancy フォールバック
- 🔐 **セキュアな認証** — WebView で Google サインイン、Cookie は macOS キーチェーンに保存

## 📋 必要条件

- macOS 14 (Sonoma) 以降
- YouTube Music にアクセスできる [Google](https://accounts.google.com) アカウント

## 📦 インストール

### ダウンロード

[**Releases**](https://github.com/user/YouTube-Music-Bar/releases) ページから最新の `.dmg` をダウンロードしてください。

> **注意：** 現在、署名されていないアプリです。
> `/Applications` に移動した後に macOS がブロックする場合は、以下を実行してください：
> ```bash
> xattr -cr "/Applications/YouTube Music Bar.app"
> ```

### ソースからビルド

```bash
# 1. リポジトリをクローン
git clone https://github.com/user/YouTube-Music-Bar.git
cd YouTube-Music-Bar

# 2. Xcode プロジェクトを生成（XcodeGen が必要）
xcodegen

# 3. 開いて実行
open YouTubeMusicBar.xcodeproj
# YouTubeMusicBar スキームを選択 → 実行 (⌘R)
```

リリースビルドと DMG パッケージングの詳細は [RELEASE.md](../RELEASE.md) を参照してください。

## 🤝 コントリビュート

コントリビューション歓迎です！Issue や Pull Request をお気軽にどうぞ。

## ⚠️ 免責事項

YouTube Music Bar は**非公式**アプリであり、YouTube や Google とは**一切関係ありません**。
「YouTube」「YouTube Music」および「YouTube ロゴ」は Google Inc. の登録商標です。

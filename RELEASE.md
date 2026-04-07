# Release Guide

This is the practical release workflow for **YouTube Music Bar**. It covers the current universal macOS build, DMG packaging, and GitHub release upload flow.

## Current project facts

- Public name: `YouTube Music Bar`
- Product name in the current Xcode project: `Ytb Music Bar`
- Scheme: `YtbMusicBar`
- Project: `YtbMusicBar.xcodeproj`
- Deployment target: macOS 14.0+
- Current version: `0.2.0`
- Current build number: `2`
- App bundle identifier: `com.ytbmusicbar.app`

The public name is **YouTube Music Bar**. Some internal project files still use the shorter `YtbMusicBar` naming.

## Prerequisites

- Xcode 16 or later
- Command line tools configured for the active Xcode
- A macOS machine that can build both `arm64` and `x86_64` outputs, or separate machines for each architecture if you plan to merge builds manually

## Output paths to expect

Using the commands below, Xcode places products under a custom DerivedData directory inside the repo:

- Derived data root: `build/DerivedData`
- Release app bundle: `build/DerivedData/Build/Products/Release/Ytb Music Bar.app`

If you archive instead of plain building, the archive appears at:

- `build/YtbMusicBar.xcarchive`

## 1. Build a universal release app

The simplest release path is a Release build for macOS with both architectures requested explicitly.

```bash
xcodebuild -project YtbMusicBar.xcodeproj -scheme YtbMusicBar -configuration Release -derivedDataPath build/DerivedData -destination 'generic/platform=macOS' ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO build
```

After a successful build, the app bundle should be here:

```bash
build/DerivedData/Build/Products/Release/Ytb Music Bar.app
```

## 2. Verify that the app is universal

Check the main executable inside the app bundle:

```bash
file "build/DerivedData/Build/Products/Release/Ytb Music Bar.app/Contents/MacOS/Ytb Music Bar"
```

Expected output should include both architectures, for example:

```text
Mach-O universal binary with 2 architectures: [x86_64:...] [arm64:...]
```

You can also inspect the slices more directly:

```bash
lipo -info "build/DerivedData/Build/Products/Release/Ytb Music Bar.app/Contents/MacOS/Ytb Music Bar"
```

Expected result:

```text
Architectures in the fat file: ... are: x86_64 arm64
```

## 3. Optional archive build

If you want an `.xcarchive` as a release artifact before packaging, use:

```bash
xcodebuild -project YtbMusicBar.xcodeproj -scheme YtbMusicBar -configuration Release -archivePath build/YtbMusicBar.xcarchive -destination 'generic/platform=macOS' ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO archive
```

The archived app bundle will then be located at:

```bash
build/YtbMusicBar.xcarchive/Products/Applications/Ytb Music Bar.app
```

## 4. Stage the app for DMG packaging

Create a clean staging folder and copy the built app into it.

```bash
mkdir -p build/dmg-root
```

```bash
ditto "build/DerivedData/Build/Products/Release/Ytb Music Bar.app" "build/dmg-root/Ytb Music Bar.app"
```

If you prefer packaging from the archive, replace the source path with:

```bash
build/YtbMusicBar.xcarchive/Products/Applications/Ytb Music Bar.app
```

## 5. Create a simple DMG with built-in macOS tools

This repo does not set up a third-party DMG tool, so the simplest dependency-free approach is `hdiutil`.

```bash
hdiutil create -volname "Ytb Music Bar" -srcfolder "build/dmg-root" -ov -format UDZO "build/YtbMusicBar-0.2.0.dmg"
```

That produces a compressed DMG at:

```bash
build/YtbMusicBar-0.2.0.dmg
```

## 6. Sanity check the packaged app

Mount the DMG and confirm the app launches on a clean machine if possible.

Useful local checks:

```bash
spctl -a -vv "build/dmg-root/Ytb Music Bar.app"
```

For an unsigned app, Gatekeeper may report that it is not notarized or not accepted. That is expected unless you add signing and notarization outside this guide.

You can also inspect the code signature status:

```bash
codesign -dv --verbose=4 "build/dmg-root/Ytb Music Bar.app"
```

If you are distributing unsigned builds directly, mention that in the release notes.

## 7. Quarantine note for users

If users download an unsigned DMG from the internet, macOS may quarantine the app when they copy it to `/Applications`.

Document this in the release notes or README:

```bash
xattr -cr "/Applications/Ytb Music Bar.app"
```

## 8. Suggested release checklist

1. Update `CFBundleShortVersionString` and `CFBundleVersion` in project metadata before building.
2. Run the universal Release build.
3. Verify the executable includes both `arm64` and `x86_64`.
4. Package the app into a DMG.
5. Mount the DMG and smoke test launch, sign-in, playback, and menu bar behavior.
6. Upload the `.dmg` to the GitHub release.
7. In the release notes, mention that the app is unofficial and that unsigned builds may require clearing quarantine attributes.

## 9. Manual merge workflow, only if one machine cannot produce both slices

If you end up with separate `arm64` and `x86_64` app builds, you can merge the main executable manually with `lipo`. This is more fragile than a direct universal build, so prefer the universal `xcodebuild` command above when possible.

Example executable merge:

```bash
lipo -create \
  "path/to/arm64/Ytb Music Bar.app/Contents/MacOS/Ytb Music Bar" \
  "path/to/x86_64/Ytb Music Bar.app/Contents/MacOS/Ytb Music Bar" \
  -output "path/to/universal/Ytb Music Bar.app/Contents/MacOS/Ytb Music Bar"
```

If frameworks or helper binaries are ever added later, each Mach-O inside the app bundle must also be verified as universal.

## 10. What this repo does not automate yet

This repository currently does not include:

- automated version bumping
- code signing identity configuration
- notarization submission
- stapling
- custom DMG background or drag-to-Applications layout
- CI release pipeline

That means the workflow above is suitable for practical direct distribution, but a polished public macOS release will still need signing and notarization work later.

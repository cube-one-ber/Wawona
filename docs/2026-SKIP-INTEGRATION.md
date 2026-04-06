# 2026 Skip Integration Guide

This document describes how Wawona integrates Skip Fuse into the existing
Nix + XcodeGen build system.

## Project structure

- `Package.swift` defines `WawonaModel`, `WawonaUI`, `WawonaWatch`.
- `Skip.env` contains shared product metadata.
- Module configs:
  - `Sources/WawonaModel/Skip/skip.yml` (`mode: native`, `bridging: true`)
  - `Sources/WawonaUI/Skip/skip.yml` (`mode: native`)
  - `Sources/WawonaWatch/Skip/skip.yml` (`mode: native`)

## Entry points

- Apple: `Darwin/Sources/Main.swift` delegates to `WawonaRootView` and
  `WawonaAppDelegate` (Howdy Skip pattern).
- Android: `android/app/src/main/java/com/aspauldingcode/wawona/Main.kt`
  hosts the compositor surface and Compose overlays.

## Nix integration

- `dependencies/generators/xcodegen.nix` consumes local SwiftPM package
  and links `WawonaUI`.
- `dependencies/wawona/android.nix` optionally runs:

```bash
skip export --project . -d android/Skip --debug
```

before Gradle assemble.

## Local setup

```bash
brew tap skiptools/skip
brew install skip
skip checkup
```

## Compatibility baseline

- iOS 16+, macOS 14+, watchOS 10+, Android API 28+.
- Liquid Glass features gated with `@available(macOS 26, iOS 26, *)`.

## Known constraints

- The compositor surface remains platform-native (`ObjC` + `JNI`), not
  directly Skip-generated.
- watchOS UI is companion/status-only and has no Android analog.

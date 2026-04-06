# 2026 UI Design: SwiftUI + Liquid Glass

This document captures the cross-platform UI redesign rules for Wawona.

## Goals

- One shared SwiftUI interface (`Sources/WawonaUI`) for Apple and Android.
- Dynamic layout that scales from iPhone to iPad to macOS.
- Liquid Glass visuals on macOS 26+/iOS 26+ with safe fallback paths.
- Per-machine launcher UX (Weston, foot, weston-terminal, weston-simple-shm).

## Design tokens

- Corner radius: `20` default for cards.
- Spacing scale: `4 / 8 / 14 / 20`.
- Status colors:
  - Connected: green
  - Connecting: blue
  - Degraded: orange
  - Error: red
  - Disconnected: secondary

## Liquid Glass strategy

```swift
if #available(macOS 26, iOS 26, *) {
    RoundedRectangle(cornerRadius: 20)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
} else {
    RoundedRectangle(cornerRadius: 20)
        .fill(.ultraThinMaterial)
}
```

Rules:

- Avoid deep glass nesting (max depth 2).
- Use `.glassEffect(.clear)` for small chips/badges over a primary glass card.
- Prefer system glass for toolbars/sidebars.

## Layout adaptation

- iPhone: `NavigationStack`, single-column flow.
- iPad/macOS: `NavigationSplitView` + adaptive grid.
- Grid: `GridItem(.adaptive(minimum: 300, maximum: 500))`.

## Multi-window behavior

- iPadOS 17+: session windows via `WindowGroup("Session", id: "session", for: ...)`.
- Android 16+: `SessionActivity` for extra free-form windows.

## Watch companion

- Status-first UI: machine list + quick connect/disconnect.
- No compositor embedding on watchOS.

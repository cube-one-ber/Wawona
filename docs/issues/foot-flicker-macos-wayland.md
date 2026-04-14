# Foot Flicker On macOS Wayland (Wawona)

## Status
- Open
- Severity: high (interactive text rendering regression)
- Affected path: Wayland compositor protocol timing + macOS layer presentation

## Summary
`foot` on Wawona macOS intermittently flickers and appears to jump between previous and new terminal content while typing, scrolling, and resizing. The strongest signal is after `clear`: the terminal appears unchanged until new input, then visibly alternates between old and new UI state.

This issue is currently treated as compositor-side until disproven, because:
- Behavior correlates with frame timing and present/ack sequencing.
- Similar artifacts are consistent with stale-buffer re-presentation.
- Current compositor code flushes frame callbacks before guaranteed presentation.

## Environment
- Host OS: macOS (Retina HiDPI)
- Window host: AppKit `NSWindow` + `CALayer` rendering path
- Client: `foot` (Wayland)
- Repro setup: internal Retina display, no external display required

## Reproduction
1. Launch `foot` under Wawona compositor on macOS.
2. Trigger steady output (`yes | head -n 2000`, `tail -f`, or build logs).
3. Run `clear`.
4. Start typing rapidly.
5. Resize the terminal while output updates.

## Expected
- `clear` immediately reflects cleared frame.
- Typing and scrolling remain stable with no back-buffer flashes.
- Resize keeps current content coherent with no old-frame reappearance.

## Actual
- `clear` sometimes appears delayed visually.
- During subsequent typing, display can alternate between pre-clear and current content.
- Scrolling and resize amplify flicker and transient stale-frame display.

## Technical Evidence To Track

### Protocol sequencing
- `SurfaceCommitted` must not flush `wl_surface.frame` callbacks early.
- `frame_done` should correlate to presentation boundary (`notify_frame_presented`).
- Global callback flushes (`flush_all_frame_callbacks`) should be avoided unless explicitly correct.

### Damage semantics
- `wl_surface.damage` and `wl_surface.damage_buffer` cannot be merged without coordinate normalization.
- On HiDPI, `damage_buffer` must be converted from buffer-local to surface-local coordinates.

### macOS render/cache ordering
- A surface should not be acknowledged as presented before its matching buffer is cached and consumed by layer update.
- Cache misses (`MISS`) should never cause old buffer content to override newer intended state.

## Instrumentation Checklist
- Rust/FFI logs:
  - `SurfaceCommitted` callback counts and flush events.
  - `FramePresented` callback counts, release counts, and timestamps.
  - Damage path logs for local vs buffer damage normalization.
- macOS bridge logs:
  - `MISS` events (`updateLayerForNode`).
  - Buffer pop order (`window_id`, `surface_id`, `buffer_id`).
  - Frame-present notify order vs cache/write/read order.
- Validation snapshots:
  - Timestamped sequence for commit -> cache -> scene -> layer apply -> frame done.

## Hypotheses
1. Premature frame callback flush allows client to submit next frame before true presentation, causing visual oscillation.
2. Incorrect `damage_buffer` handling on HiDPI produces invalid incremental redraw regions.
3. macOS layer/cache sequencing can temporarily expose stale content during rapid updates and resize.

## Risk
- Tightening frame callback semantics may expose client assumptions masked by old behavior.
- Damage normalization changes may initially increase redraw scope if conversion is conservative.
- macOS ordering changes may impact throughput if synchronization is too coarse.

## Rollback Plan
If regressions appear:
1. Feature-flag or revert frame callback sequencing change only.
2. Keep conservative full-redraw fallback while damage conversion is stabilized.
3. Retain added diagnostics to compare old/new event ordering and callback cadence.

## Exit Criteria
- No visible old/new content oscillation after `clear` + typing stress.
- Stable typing/scrolling on Retina without self-erasing characters.
- Resize does not reintroduce old frame content.
- Frame callback and presentation logs show one coherent progression per presented frame.

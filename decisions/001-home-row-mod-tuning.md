# ADR-001: Home Row Mod Tuning

**Date:** 2026-02-19
**Status:** Trial

## Context

Home row mods (CAGS order with positional hold-tap) were producing two classes of misfire:

1. **Repeated Js** — holding `SFT/J` and tapping a same-hand key (e.g. I) would output `ji` instead of `I`. Fixed by making shift non-positional (triggers on either hand). However, after that change, `J` still fired spuriously during normal typing.

2. **"dw" instead of CMD+W** — holding `GUI/D` and tapping `W` (both left hand) outputs `dw` because positional hold-tap resolves same-hand presses as taps.

3. **"kv" instead of CMD+V** — `require-prior-idle-ms` was preventing the hold from activating when a modifier was pressed shortly after typing.

## Analysis

### require-prior-idle-ms behaviour

This parameter creates a **fast-path tap bypass**: if a hold-tap key is pressed within this window of the last keystroke, it resolves as a tap immediately (zero delay). A *higher* value means *more* keystrokes hit the fast path during typing, making typing snappier — not slower.

| Value | Effect during fast typing (~80ms between keys) | Effect on quick mod use after typing |
|-------|------------------------------------------------|--------------------------------------|
| 50ms  | Most keystrokes (80ms+) miss the fast path, enter hold-tap resolution — causes false holds and lag | Mods activate almost always — too eagerly |
| 100ms | Some keystrokes still miss the fast path | Mods mostly activate |
| 150ms | Nearly all typing keystrokes hit the fast path — immediate tap, zero delay | Mods only activate after a 150ms pause — acceptable for deliberate shortcuts |

The `50ms` value on shift was the root cause of repeated-J misfires: at typical typing speeds (80-200ms between keys), J almost always entered hold-tap resolution instead of the fast path.

### Same-hand mod+key (CMD+W, CMD+S, etc.)

This is a fundamental limitation of positional hold-tap. D (pos 15) and W (pos 2) are both left-hand keys. The hold-tap cannot distinguish "I want CMD+W" from "I'm rolling d→w while typing." No timing parameter can fix this — same-hand shortcuts require holding past the tapping-term (~280ms).

### Shift non-positional trade-off

Making shift trigger on either hand (`hold-trigger-key-positions = <KEYS_L KEYS_R THUMBS>`) enables same-hand Shift+key (e.g. hold J, tap I for capital I). This is desirable for typing consecutive capitals on alternating sides without switching shift hands. The risk of false shift activations is mitigated by `require-prior-idle-ms = 150ms`, which bypasses hold-tap entirely during fast typing.

## Decision

### Shift behaviours (`hml_s` / `hmr_s`)
- **Non-positional**: triggers on both hands (`KEYS_L KEYS_R THUMBS`) so same-hand Shift+key works
- **`require-prior-idle-ms = 150`**: raised from 50ms to eliminate false shift activations during typing (the fast-path bypass now covers typical inter-key intervals)
- **`tapping-term-ms = 200`**: lowered from 280ms so same-hand shift resolves faster (following infused-kim's approach for shift-specific tuning)
- **`quick-tap-ms = 175`**: unchanged

### Non-shift behaviours (`hml` / `hmr`)
- **Positional**: cross-hand only (unchanged)
- **`require-prior-idle-ms = 150`**: raised from 100ms back to urob's recommended value (100ms wasn't helping since the CMD+W problem is positional, not timing-based)
- **`tapping-term-ms = 280`**: unchanged
- **`quick-tap-ms = 175`**: unchanged

### Accepted trade-offs
- Same-hand mod+alpha shortcuts (CMD+W, CMD+S, CMD+Z) require a deliberate ~280ms hold before pressing the alpha key
- Same-hand Shift+alpha resolves faster at ~200ms due to the lower tapping-term on shift behaviours

## References

- [urob/zmk-config](https://github.com/urob/zmk-config) — "timeless" HRM config, `require-prior-idle-ms` formula: `10500 / WPM`
- [urob/zmk-config Discussion #71](https://github.com/urob/zmk-config/discussions/71) — shift tuning discussion
- [ZMK hold-tap docs](https://zmk.dev/docs/keymaps/behaviors/hold-tap) — official behaviour reference
- [infused-kim's HRM behaviours](https://github.com/infused-kim/zmk-config/blob/chocofi/main/config/includes/behaviours_homerow_mods.dtsi) — shift-specific tapping-term approach
- [sunaku's home row mods guide](https://sunaku.github.io/home-row-mods.html) — bilateral combinations analysis

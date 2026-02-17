# Kyle's ZMK Configs

## Overview

This is a **multi-board** ZMK firmware configuration repo. It contains keymaps and config for all of Kyle's keyboards. Each board has its own `.keymap` and `.conf` file in `config/`, and all boards are listed in `build.yaml`.

## Repository structure

```
kylejs-zmk-configs/
├── build.yaml              # Build matrix — lists ALL boards to build
├── CLAUDE.md
└── config/
    ├── west.yml            # ZMK source (currently points to ky1ejs/zmk fork)
    ├── tornblue.keymap     # TornBlue: 7-layer keymap with combos and encoder
    ├── tornblue.conf       # TornBlue: Kconfig overrides
    └── <board>.keymap/conf # Future boards go here — one .keymap + .conf per board
```

When adding a new board, add its `.keymap` and `.conf` to `config/` and add an entry to `build.yaml`. If the board needs a custom ZMK fork or module, update `config/west.yml` accordingly. If the board definition is upstream in ZMK, no fork changes are needed.

## Building and flashing

Firmware is built via GitHub Actions. Push to the repo and the workflow builds all boards listed in `build.yaml`, producing UF2 (or bin) artifacts per board.

The build uses the reusable workflow from `zmkfirmware/zmk/.github/workflows/build-user-config.yml@main`.

To flash: plug in the board via USB, enter bootloader mode (usually double-tap reset), and copy the `.uf2` file onto the USB drive that appears. Firmware cannot be loaded wirelessly.

## General build notes

- The `.conf` file is shared across both halves of a split board. Do NOT put half-specific config (like `CONFIG_EC11=y` for a half that has an encoder) in the conf — put it in the board's defconfig instead.
- `build.yaml` must use `artifact-name` if the board qualifier contains `//` (e.g. `tornblue_left//zmk`), otherwise the artifact copy step fails because `//` is interpreted as a path separator.
- `CONFIG_WS2812_STRIP` does not exist in ZMK 4.1 / Zephyr 4.1. Do not reference it.

---

# Board: TornBlue

## Hardware

- Designer: rtitmuss
- MCU: nRF52840 (both halves)
- Layout: 44 physical keys (3×6 + 4 thumb per side), using 36 (3×5 + 3 thumb)
- Encoders: EVQWGD001 (Alps Alpine) — uses Zephyr EC11 driver. Only the LEFT half has an encoder defined in the DTS (GPIO P0.09/P0.10). The right encoder is not wired in the board definition.
- 3 onboard GPIO indicator LEDs per half (active high)
- Optional WS2812 RGB underglow strip (NOT soldered, disabled via Kconfig)
- Bluetooth device name: `kylejs-tornblue`
- UF2 bootloader (double-tap reset to enter bootloader)
- Both halves must be flashed for keymap changes

## ZMK fork

Board definition lives in Kyle's fork: https://github.com/ky1ejs/zmk/tree/tornblue_update_zmk_version

This fork has the TornBlue board migrated to HWMv2 format for Zephyr 4.1. Key files at `app/boards/rtitmuss/tornblue/`:
- `tornblue.dtsi` — shared devicetree (matrix transform, kscan, battery, LED aliases)
- `tornblue_left_nrf52840_zmk.dts` / `tornblue_right_nrf52840_zmk.dts` — per-half DTS (still contains SPI/WS2812 blocks, disabled at Kconfig level)
- `led_driver.c` — GPIO indicator LEDs that light up on NAV (layer 1), NUM (layer 2), SYM (layer 3)
- Defconfigs, Kconfig files, pinctrl files

## Build matrix entry

```yaml
- board: tornblue_left//zmk
  artifact-name: tornblue_left-zmk
- board: tornblue_right//zmk
  artifact-name: tornblue_right-zmk
```

## tornblue.conf

- `CONFIG_ZMK_KEYBOARD_NAME="kylejs-tornblue"` — Bluetooth device name
- `CONFIG_BT_CTLR_TX_PWR_PLUS_8=y` — increased BT TX power for range
- `CONFIG_ZMK_HID_REPORT_TYPE_NKRO=y` — NKRO for reliable Hyper key
- `CONFIG_ZMK_RGB_UNDERGLOW=n` / `CONFIG_LED_STRIP=n` — disable WS2812 RGB (board defconfig enables it by default)
- `CONFIG_ZMK_SLEEP=y` with 15 min timeout (900000 ms)
- EC11 encoder config is in the left defconfig only, NOT in the shared conf

## Key position map (44 keys)

```
 0  1  2  3  4  5  |  6  7  8  9 10 11
12 13 14 15 16 17  | 18 19 20 21 22 23
24 25 26 27 28 29  | 30 31 32 33 34 35
      36 37 38 39  | 40 41 42 43
```

Unused positions (set to `&none`): 0, 12, 24 (left outer col), 11, 23, 35 (right outer col), 36 (left outer thumb), 43 (right outer thumb).

## Keymap design

### Layers

| # | Name  | Activation     | Description |
|---|-------|----------------|-------------|
| 0 | BASE  | default        | QWERTY with home row mods (CAGS) and `'` on right pinky |
| 1 | NAV   | hold ENT       | Arrows on right home row (J=←, K=→, L=↑, ;'=↓), clipboard, page nav |
| 2 | NUM   | hold TAB       | Right-hand numpad (789/456/123) with punctuation |
| 3 | SYM   | hold BSP       | Brackets on middle/index, operators on pinky/ring |
| 4 | FUN   | hold SPC       | F-keys in numpad arrangement on left hand |
| 5 | SYM2  | hold DEL       | Rare symbols (@#$%^) and BT profile switching (bottom row) |
| 6 | MEDIA | hold ESC       | Transport controls (prev/play/next) on right home row |

### Home row mods (CAGS order)

From pinky to index: **CTRL, ALT, GUI, SHIFT**. Hyper (all four mods) on the inner column (G and H).

Left: `CTRL/A  ALT/S  GUI/D  SFT/F  HYP/G`
Right: `HYP/H  SFT/J  GUI/K  ALT/L  CTRL/'`

Hold-tap config: balanced flavor, 200ms tapping-term, 150ms quick-tap, 125ms require-prior-idle.

### Thumb keys (layer-taps)

Left: `ESC/MEDIA  ENT/NAV  TAB/NUM`
Right: `SPC/FUN  BSP/SYM  DEL/SYM2`

### Combos (BASE layer only)

| Keys    | Positions | Output |
|---------|-----------|--------|
| W + E   | 2, 3      | `=`    |
| E + R   | 3, 4      | `_`    |
| U + I   | 7, 8      | `(`    |
| I + O   | 8, 9      | `)`    |
| X + C   | 26, 27    | ESC    |

### Encoder (left only)

| Layer | Rotation |
|-------|----------|
| BASE  | Volume up/down |
| NAV   | Tab cycle (Ctrl+Shift+Tab / Ctrl+Tab) |
| NUM   | +/− |
| SYM   | Undo/Redo (Ctrl+Z / Ctrl+Y) |
| FUN   | Brightness up/down |
| SYM2  | Volume up/down |
| MEDIA | Volume up/down |

### SYM layer layout (left hand)

Brackets are on middle/index fingers (stronger fingers), operators on pinky/ring:
```
pinky  ring   mid    index  inner
<      >      {      }      `
!      =      (      )      +
&      |      [      ]      ~
       _      *      "            (thumb row)
```

### Bluetooth profiles (SYM2 layer, bottom row)

Z=BT0, X=BT1, C=BT2, V=BT3, B=BT_CLR. Switch profiles to connect to different computers.

### Known gaps

- Semicolon (`;`) is not mapped anywhere since `'` replaced it on the home row. Needs a combo (e.g. `.` + `/`).
- Right encoder is not defined in the board DTS — only the left encoder is functional.
- Encoder push/click is not wired in the TornBlue board definition.
- The fork's `led_driver.c` has layer indices that may not match the keymap if layers are reordered.

# Kyle's ZMK Configs

## Overview

This is a **multi-board** ZMK firmware configuration repo. It contains keymaps and config for all of Kyle's keyboards. Each board has its own `.keymap` and `.conf` file in `config/`, and all boards are listed in `build.yaml`.

## Rules of Development
- You MUST ALWAYS review the README.md, CLAUDE.md and code comments and update them as needed when making changes to the repo
- You MUST ALWAYS ensure that keymaps have a easy to ready code comment above them which describes the layout.
- You MUST ALWAYS avoid placing keys on the same hand as the thumb that is pressed to access that layer (e.g. avoid putting keys on the right hand that are only accessible when holding the right thumb layer key).

## Repository structure

```
kylejs-zmk-configs/
├── build.yaml                  # Build matrix — lists ALL boards to build
├── keymap_drawer.config.yaml   # keymap-drawer global config (styling/parsing only, no layouts)
├── CLAUDE.md
├── config/
│   ├── west.yml                # ZMK source (currently points to ky1ejs/zmk fork)
│   ├── tornblue.keymap         # TornBlue: 7-layer keymap with combos and encoder
│   ├── tornblue.conf           # TornBlue: Kconfig overrides
│   ├── tornblue.json           # TornBlue: physical layout for keymap-drawer visualization
│   └── <board>.keymap/conf/json # Future boards go here
├── pages/
│   ├── template.html           # HTML template with {{BOARD_NAV}} / {{BOARD_SECTIONS}} placeholders
│   └── build-site.sh           # CI script: discovers SVGs, generates index.html from template
└── .github/workflows/
    ├── build.yml               # ZMK firmware build
    └── draw-and-deploy.yml     # Keymap visualization: draw SVGs → build HTML → deploy to Pages
```

When adding a new board, add its `.keymap`, `.conf`, and `.json` (physical layout) to `config/` and add an entry to `build.yaml`. If the board needs a custom ZMK fork or module, update `config/west.yml` accordingly. If the board definition is upstream in ZMK, no fork changes are needed. The keymap visualization page auto-discovers new boards — no HTML or workflow changes needed.

## Building and flashing

Firmware is built via GitHub Actions. Push to the repo and the workflow builds all boards listed in `build.yaml`, producing UF2 (or bin) artifacts per board.

The build uses the reusable workflow from `zmkfirmware/zmk/.github/workflows/build-user-config.yml@main`.

To flash: plug in the board via USB, enter bootloader mode (usually double-tap reset), and copy the `.uf2` file onto the USB drive that appears. Firmware cannot be loaded wirelessly.

## General build notes

- The `.conf` file is shared across both halves of a split board. Do NOT put half-specific config (like `CONFIG_EC11=y` for a half that has an encoder) in the conf — put it in the board's defconfig instead.
- `build.yaml` must use `artifact-name` if the board qualifier contains `//` (e.g. `tornblue_left//zmk`), otherwise the artifact copy step fails because `//` is interpreted as a path separator.
- `CONFIG_WS2812_STRIP` does not exist in ZMK 4.1 / Zephyr 4.1. Do not reference it.

## Keymap visualization (GitHub Pages)

Site URL: https://ky1ejs.github.io/kylejs-zmk-configs/

The `draw-and-deploy.yml` workflow runs on every push that changes keymap files, physical layouts, or the visualization config. It:

1. **Draws SVGs** via keymap-drawer's reusable workflow (`caksoylar/keymap-drawer/.github/workflows/draw-zmk.yml`), discovering all `config/*.keymap` files and matching them to `config/<board>.json` physical layouts.
2. **Builds HTML** by running `pages/build-site.sh`, which discovers the generated SVGs and substitutes them into `pages/template.html`.
3. **Deploys to GitHub Pages** via `actions/deploy-pages`.

Generated SVGs are NOT committed to the repo — they exist only as CI artifacts and are deployed directly to Pages.

**Config files:**
- `keymap_drawer.config.yaml` — global styling and parsing config (dark mode, ghost keys for `&none`, HYPER keycode mapping). Does NOT contain physical layouts.
- `config/<board>.json` — per-board physical layout in QMK-style JSON format (x/y coordinates per key). Auto-discovered by the workflow via `json_path: "config"`.

**Repo Settings prerequisite:** Pages → Source must be set to **GitHub Actions** (not "Deploy from a branch").

---

# Board: TornBlue

## Hardware
https://github.com/rtitmuss/tornblue

- Designer: [rtitmuss](https://github.com/rtitmuss)
- MCU: nRF52840 (both halves)
- Layout: 44 physical keys (3×6 + 4 thumb per side), using 36 (3×5 + 3 thumb)
- Encoders: EVQWGD001 (Alps Alpine) — uses Zephyr EC11 driver. Only the LEFT half has an encoder defined in the DTS (GPIO P0.09/P0.10). The right encoder is not wired in the board definition.
- 3 GPIO-controllable indicator LEDs + 1 charging LED per half (active high)
- Optional WS2812 RGB underglow strip (NOT soldered, disabled via Kconfig)
- UF2 bootloader (double-tap reset to enter bootloader)
- Both halves must be flashed for keymap changes

## ZMK fork

Board definition lives in Kyle's fork: https://github.com/ky1ejs/zmk/tree/tornblue_update_zmk_version

This fork has the TornBlue board migrated to HWMv2 format for Zephyr 4.1. Key files at `app/boards/rtitmuss/tornblue/`:
- `tornblue.dtsi` — shared devicetree (matrix transform, kscan, battery, LED aliases)
- `tornblue_left_nrf52840_zmk.dts` / `tornblue_right_nrf52840_zmk.dts` — per-half DTS (still contains SPI/WS2812 blocks, disabled at Kconfig level)
- `led_driver.c` — GPIO indicator LEDs, configurable via `CONFIG_TORNBLUE_LED_BT_PROFILE` for BT profile or layer indication
- Defconfigs, Kconfig files, pinctrl files

## Key position map (44 keys)

```
 0  1  2  3  4  5  |  6  7  8  9 10 11
12 13 14 15 16 17  | 18 19 20 21 22 23
24 25 26 27 28 29  | 30 31 32 33 34 35
      36 37 38 39  | 40 41 42 43
```

Unused positions (set to `&none`): 0, 12, 24 (left outer col), 11, 23, 35 (right outer col), 36 (left outer thumb where an EVQWGD001 encoder is), 43 (right outer thumb where an EVQWGD001 encoder is).

## Keymap design

### Layers

| # | Name  | Activation     |
|---|-------|----------------|
| 0 | BASE  | default        |
| 1 | NAV   | hold ENT       |
| 2 | NUM   | hold TAB       |
| 3 | SYM   | hold BSP       |
| 4 | FUN   | hold SPC       |
| 5 | SYM2  | hold DEL       |
| 6 | MEDIA | hold ESC       |

### Home row mods (CAGS order)

From pinky to index: **CTRL, ALT, GUI, SHIFT**. Hyper (all four mods) on the inner column (G and H).

Left: `CTRL/A  ALT/S  GUI/D  SFT/F  HYP/G`
Right: `HYP/H  SFT/J  GUI/K  ALT/L  CTRL/'`

Hold-tap config: balanced flavor, 200ms tapping-term, 150ms quick-tap, 125ms require-prior-idle. `hm_shift` uses 50ms require-prior-idle (lower threshold so shift registers reliably mid-sentence).

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

Brackets are on middle/index fingers (stronger fingers), operators on pinky/ring.
GRAVE and TILDE are on SYM2 (pos R and T) to make room for semicolon.
```
pinky  ring   mid    index  inner
<      >      {      }      —
!      =      (      )      +
&      |      [      ]      ;
       _      *      "            (thumb row)
```

### LED indicators (left half only)

The 3 onboard GPIO LEDs on the left half are controlled by `led_driver.c` in the
ZMK fork. The mode is selected via Kconfig in `tornblue.conf`:

**`CONFIG_TORNBLUE_LED_BT_PROFILE=y`** (current setting) — one LED per BT profile:

| Profile | LED1 | LED2 | LED3 |
|---------|------|------|------|
| BT0     | ON   | OFF  | OFF  |
| BT1     | OFF  | ON   | OFF  |
| BT2     | OFF  | OFF  | ON   |
| BT3     | ON   | ON   | ON   |

**`CONFIG_TORNBLUE_LED_BT_PROFILE=n`** (default in fork) — layer indicators:
LED1=NAV (layer 1), LED2=NUM (layer 2), LED3=SYM (layer 3).

All LEDs off = system asleep. Right half LEDs are unused (no BT profile data on peripheral).

### Bluetooth profiles (SYM2 layer, bottom row)

Z=BT0, X=BT1, C=BT2, V=BT3, B=BT_CLR. Switch profiles to connect to different computers.

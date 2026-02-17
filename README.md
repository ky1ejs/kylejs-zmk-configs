# kylejs-zmk-configs

Personal [ZMK](https://zmk.dev) firmware configuration for Kyle's keyboards.

## Keymap

Interactive keymap visualization: **https://ky1ejs.github.io/kylejs-zmk-configs/**

Auto-generated from `config/*.keymap` files on every push using [keymap-drawer](https://github.com/caksoylar/keymap-drawer).

## Boards

| Board | Layout | MCU | Notes |
|-------|--------|-----|-------|
| [TornBlue](https://github.com/rtitmuss/tornblue) | 44-key split (3x6 + 4 thumb) | nRF52840 | Rotary encoder on left and right halves at outer thumb positions; 3 LEDs show active BT profile |

## Building

Firmware is built automatically via GitHub Actions on push. The workflow produces UF2 artifacts for each board half.

To flash: plug in via USB, double-tap reset to enter bootloader, and copy the `.uf2` onto the mounted drive.

## Repo structure

```
config/
├── west.yml          # ZMK source reference
├── tornblue.keymap   # Keymap and combos
├── tornblue.conf     # Kconfig overrides
└── tornblue.json     # Physical layout for keymap visualization
pages/
├── template.html     # HTML template for the visualization page
└── build-site.sh     # Generates index.html from SVGs during CI
keymap_drawer.config.yaml  # keymap-drawer styling/parsing config
build.yaml            # Build matrix
```

## Adding a new board

1. Add `<board>.keymap` and `<board>.conf` to `config/`
2. Add `<board>.json` physical layout to `config/` (for keymap visualization)
3. Add an entry to `build.yaml`
4. Update `config/west.yml` if a custom ZMK fork or module is needed

The keymap visualization page auto-discovers new boards — no HTML or workflow changes needed.

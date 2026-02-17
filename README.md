# kylejs-zmk-configs

Personal [ZMK](https://zmk.dev) firmware configuration for Kyle's keyboards.

## Boards

| Board | Layout | MCU | Notes |
|-------|--------|-----|-------|
| [TornBlue](https://github.com/rtitmuss/tornern) | 44-key split (3x6 + 4 thumb) | nRF52840 | Rotary encoder on left half, BLE |

## Building

Firmware is built automatically via GitHub Actions on push. The workflow produces UF2 artifacts for each board half.

To flash: plug in via USB, double-tap reset to enter bootloader, and copy the `.uf2` onto the mounted drive.

## Repo structure

```
config/
├── west.yml          # ZMK source reference
├── tornblue.keymap   # Keymap and combos
└── tornblue.conf     # Kconfig overrides
build.yaml            # Build matrix
```

## Adding a new board

1. Add `<board>.keymap` and `<board>.conf` to `config/`
2. Add an entry to `build.yaml`
3. Update `config/west.yml` if a custom ZMK fork or module is needed

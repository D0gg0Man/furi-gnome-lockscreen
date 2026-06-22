# Furi GNOME Lock Screen

Phone-like lock screen for GNOME Shell on FuriOS, no GDM required.

## Features
- Power button locks screen (black/blank)
- Press power again to show PIN pad
- PAM authentication using phosh PAM config
- Shake animation on wrong PIN
- Brightness save/restore on lock/unlock
- Clock and date display

## Install
    git clone https://github.com/D0gg0man/furi-gnome-lockscreen
    cd furi-gnome-lockscreen
    sudo ./install.sh

## Customization
Edit the constants at the top of `extension/extension.js`. The numpad is sized
relative to the screen width (it spans `NUMPAD_FRAC`, default ~82%, of the stage)
so it fits on any panel/scale, and the rest of the design scales with it:
- `BUTTON_W` / `BUTTON_H` — button **aspect ratio** (and, with `BUTTON_GAP`, the
  gap proportion); absolute size is derived from the screen width
- `NUMPAD_FRAC` (in `buildUI`) — fraction of screen width the numpad spans
- `CLOCK_FONT_SIZE` / `DATE_FONT_SIZE` / `BUTTON_FONT_SIZE` — reference font sizes,
  scaled by the same factor as the buttons
- `NUMPAD_OFFSET` — move numpad up/down from center
- Clock/date vertical position: `GY - 450` / `GY - 200` in `tick()` (also scaled)

## Debug
    G_MESSAGES_DEBUG=all journalctl --user -f

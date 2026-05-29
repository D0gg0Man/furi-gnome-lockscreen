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
Edit the constants at the top of `extension/extension.js`:
- `CLOCK_FONT_SIZE` — clock size (px)
- `DATE_FONT_SIZE` — date size (px)
- `BUTTON_W` / `BUTTON_H` — numpad button dimensions
- `NUMPAD_OFFSET` — move numpad up/down from center
- Clock position: `GY - 450` (clock) and `GY - 200` (date) in `tick()`

## Debug
    G_MESSAGES_DEBUG=all journalctl --user -f

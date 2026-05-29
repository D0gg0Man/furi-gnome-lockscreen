#!/bin/bash
# Install Furi GNOME Lock Screen
set -e
if [ "$(id -u)" -ne 0 ]; then echo "Run as root: sudo $0"; exit 1; fi

FURIOS_USER="${SUDO_USER:-furios}"
USER_UID=$(id -u "$FURIOS_USER")

echo "Installing Furi GNOME Lock Screen..."

# PAM auth helper
cat > /tmp/_pamhelper.c << 'CSRC'
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <security/pam_appl.h>
static const char *_pw;
static int conv(int n, const struct pam_message **msg,
                struct pam_response **resp, void *d) {
    *resp = calloc(n, sizeof(struct pam_response));
    for (int i=0;i<n;i++)
        if (msg[i]->msg_style==PAM_PROMPT_ECHO_OFF||
            msg[i]->msg_style==PAM_PROMPT_ECHO_ON)
            (*resp)[i].resp=strdup(_pw);
    return PAM_SUCCESS;
}
int main(int argc,char*argv[]) {
    if(argc!=3)return 1;
    _pw=argv[2];
    struct pam_conv pc={conv,NULL};
    pam_handle_t *ph=NULL;
    int r=pam_start("phosh",argv[1],&pc,&ph);
    if(r!=PAM_SUCCESS){pam_end(ph,r);return 1;}
    r=pam_authenticate(ph,0);
    if(r!=PAM_SUCCESS){pam_end(ph,r);return 1;}
    r=pam_acct_mgmt(ph,0);
    pam_end(ph,r);
    return r==PAM_SUCCESS?0:1;
}
CSRC
mkdir -p /usr/lib/gnome-mali
gcc -O2 -o /usr/lib/gnome-mali/pam-auth-helper /tmp/_pamhelper.c -lpam
chmod 4755 /usr/lib/gnome-mali/pam-auth-helper
rm /tmp/_pamhelper.c

# Extension
LOCK_DIR="/usr/share/gnome-shell/extensions/gnome-mali-lock@furios"
mkdir -p "$LOCK_DIR"
cp "$(dirname "$0")/extension/extension.js" "$LOCK_DIR/"
cp "$(dirname "$0")/extension/metadata.json" "$LOCK_DIR/"

# Power daemon
cp "$(dirname "$0")/gnome-mali-power-daemon" /usr/local/bin/
cp "$(dirname "$0")/gnome-mali-power-key" /usr/local/bin/
chmod +x /usr/local/bin/gnome-mali-power-daemon
chmod +x /usr/local/bin/gnome-mali-power-key

# Systemd services
cat > /etc/systemd/system/gnome-mali-power.service << 'SVC'
[Unit]
Description=GNOME Mali power key handler
After=graphical.target
[Service]
Type=simple
ExecStart=/usr/local/bin/gnome-mali-power-daemon
Restart=always
RestartSec=2
User=furios
[Install]
WantedBy=graphical.target
SVC

cat > /etc/systemd/system/gnome-mali-brightness-restore.service << 'SVC'
[Unit]
Description=Restore display brightness on boot
After=local-fs.target
Before=graphical.target
[Service]
Type=oneshot
ExecStart=/bin/bash -c 'SAVE=/tmp/gnome-mali-brightness.tmp; BL=/sys/class/leds/lcd-backlight/brightness; if [ -f "$SAVE" ]; then cat "$SAVE" > "$BL" 2>/dev/null; rm -f "$SAVE"; else echo 618 > "$BL" 2>/dev/null; fi'
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
SVC

# logind power key config
mkdir -p /etc/systemd/logind.conf.d
cat > /etc/systemd/logind.conf.d/zz-gnome-mali-power.conf << 'CONF'
[Login]
HandlePowerKey=lock
HandlePowerKeyLongPress=poweroff
CONF

systemctl daemon-reload
systemctl enable gnome-mali-power.service
systemctl enable gnome-mali-brightness-restore.service
systemctl restart systemd-logind

# Enable extension and configure gsettings
ENV_VARS="WAYLAND_DISPLAY=wayland-0 XDG_RUNTIME_DIR=/run/user/${USER_UID} DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${USER_UID}/bus"
sudo -u "$FURIOS_USER" env $ENV_VARS gsettings set \
    org.gnome.settings-daemon.plugins.power power-button-action 'nothing' 2>/dev/null || true
sudo -u "$FURIOS_USER" env $ENV_VARS gsettings set \
    org.gnome.settings-daemon.plugins.media-keys screensaver "[]" 2>/dev/null || true
sudo -u "$FURIOS_USER" env $ENV_VARS gsettings set \
    org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
    "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/power-lock/']" 2>/dev/null || true
sudo -u "$FURIOS_USER" env $ENV_VARS gsettings set \
    org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/power-lock/ \
    name 'Power Key' 2>/dev/null || true
sudo -u "$FURIOS_USER" env $ENV_VARS gsettings set \
    org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/power-lock/ \
    command '/usr/local/bin/gnome-mali-power-key' 2>/dev/null || true
sudo -u "$FURIOS_USER" env $ENV_VARS gsettings set \
    org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/power-lock/ \
    binding 'XF86PowerOff' 2>/dev/null || true

echo "Furi GNOME Lock Screen installed!"
echo "The lock screen extension will be enabled automatically on next GNOME Mali login."

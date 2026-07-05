
# Evitar em PC generico, se o fizer, remova os parametros -steamos3 e -steamdeck, use apenas o -gamepadui que habilita o Big Picture.
 # Sair de volta pro Desktop não funciona. Requer reboot.

# BIOS DO STEAMDECK
 # Mudar a UMA para 256 Mb!
 # Deixe o OS gerenciar e alocar a VRAM dinamicamente.

sudo apt install gamescope mangoapp mangohud -y

curl -sSL https://raw.githubusercontent.com/linuxuniverseofficial/steamdeck/refs/heads/main/CustomOS/Kubuntu%2026.04/steamos-session-select | sudo tee /usr/bin/steamos-session-select; sudo chmod +x /usr/bin/steamos-session-select

curl -sSL https://raw.githubusercontent.com/linuxuniverseofficial/steamdeck/refs/heads/main/CustomOS/Kubuntu%2026.04/steamos-desktop-select | sudo tee /usr/bin/steamos-desktop-select; sudo chmod +x /usr/bin/steamos-desktop-select

curl -sSL https://raw.githubusercontent.com/linuxuniverseofficial/steamdeck/refs/heads/main/CustomOS/Kubuntu%2026.04/steam-sddm-watcher.sh | sudo tee /usr/local/bin/steam-sddm-watcher.sh; sudo chmod +x /usr/local/bin/steam-sddm-watcher.sh

curl -sSL https://raw.githubusercontent.com/linuxuniverseofficial/steamdeck/refs/heads/main/CustomOS/Kubuntu%2026.04/GameMode.sh | sudo tee /home/ztge/GameMode.sh; sudo chmod +x /home/ztge/GameMode.sh

sudo bash -c 'cat > /usr/share/wayland-sessions/steam-gamescope.desktop << EOF
[Desktop Entry]
Name=Steam Game Mode
Comment=Start Steam in Steam Deck Hardware Session
Exec=/usr/local/bin/steam-sddm-watcher.sh
Type=Application
DesktopNames=Gamescope
EOF'

echo "kernel.unprivileged_userns_clone=1" | sudo tee /etc/sysctl.d/99-steam-sandbox.conf

mkdir -p ~/.config/xdg-desktop-portal; nano ~/.config/xdg-desktop-portal/gamescope-portals.conf
[Preferred]
default=kde;gtk;
org.freedesktop.impl.portal.Settings=kde

rm -rf ~/.steam/debian-installation/steamapps/common/SteamLinuxRuntime_sniper/var/
rm -rf ~/.steam/debian-installation/steamapps/common/SteamLinuxRuntime_soldier/var/

sudo nano /etc/sddm.conf.d/20-kubuntu.conf
[Autologin]
Relogin=true
Session=plasma
User=ztge

[General]
HaltCommand=
RebootCommand=

[Theme]
Current=kubuntu
CursorSize=30
CursorTheme=breeze_cursors
Font=Noto Sans,10,-1,0,400,0,0,0,0,0,0,0,0,0,0,1

[Users]
MaximumUid=60000
MinimumUid=1000

echo 'KERNEL=="cpu_dma_latency", PROTECTION="0666"' | sudo tee /etc/udev/rules.d/99-steamdeck-perf.rules
sudo udevadm control --reload-rules && sudo udevadm trigger

sudo nano /etc/default/grub
GRUB_DEFAULT=0
GRUB_TIMEOUT_STYLE=hidden
GRUB_TIMEOUT=1
GRUB_DISTRIBUTOR='Kubuntu'
GRUB_CMDLINE_LINUX_DEFAULT='mitigations=off'
GRUB_CMDLINE_LINUX=""
GRUB_RECORDFAIL_TIMEOUT=1

sudo update-grub2

sudo usermod -a -G video,render,input,disk $USER

mkdir -p ~/.config/mangoapp
mkdir -p ~/.config/MangoHud

nano ~/.config/MangoHud/MangoHud.conf
control=mangoapp
fsr_steam_sharpness=5
nis_steam_sharpness=5

sudo setcap 'CAP_SYS_NICE=eip' $(which gamescope)
sudo setcap 'CAP_SYS_NICE=eip' $(which mangoapp)

sudo ln -sf /usr/bin/mangoapp /usr/bin/srv/mangoapp 2>/dev/null || true

sudo VISUAL=nano visudo
ztge ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart sddm
ztge ALL=(ALL) NOPASSWD: /usr/bin/steamos-session-select
ztge ALL=(ALL) NOPASSWD: /usr/bin/steamos-desktop-select
ztge ALL=(ALL) NOPASSWD: /etc/sddm.conf.d/kde_settings.conf
ztge ALL=(ALL) NOPASSWD: /etc/sddm.conf.d/20-kubuntu.conf

sudo tee /etc/udev/rules.d/90-backlight.rules << 'EOF'
SUBSYSTEM=="backlight", KERNEL=="amdgpu_bl1", ACTION=="add", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
EOF

sudo udevadm control --reload-rules; sudo udevadm trigger --subsystem-match=backlight

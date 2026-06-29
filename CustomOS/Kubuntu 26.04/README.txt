
sudo apt install gamescope mangoapp mangohud -y

curl -sSL https://raw.githubusercontent.com/linuxuniverseofficial/steamdeck/refs/heads/main/CustomOS/Kubuntu%2026.04/steamos-desktop-select | sudo tee /usr/bin/steamos-session-select; sudo chmod +x /usr/bin/steamos-desktop-select

sudo bash -c 'cat > /usr/share/wayland-sessions/steam-gamescope.desktop << EOF
[Desktop Entry]
Name=Steam Game Mode
Comment=Start Steam in Steam Deck Hardware Session
Exec=/usr/local/bin/steam-sddm-watcher.sh
Type=Application
DesktopNames=Gamescope
EOF'

curl -sSL https://raw.githubusercontent.com/linuxuniverseofficial/steamdeck/refs/heads/main/CustomOS/Kubuntu%2026.04/steam-sddm-watcher.sh | sudo tee /usr/local/bin/steam-sddm-watcher.sh; sudo chmod +x /usr/local/bin/steam-sddm-watcher.sh

echo "kernel.unprivileged_userns_clone=1" | sudo tee /etc/sysctl.d/99-steam-sandbox.conf

mkdir -p ~/.config/xdg-desktop-portal; nano ~/.config/xdg-desktop-portal/gamescope-portals.conf
[Preferred]
default=kde;gtk;
org.freedesktop.impl.portal.Settings=kde

rm -rf ~/.steam/debian-installation/steamapps/common/SteamLinuxRuntime_sniper/var/
rm -rf ~/.steam/debian-installation/steamapps/common/SteamLinuxRuntime_soldier/var/

sudo nano /etc/sddm.conf.d/kde_settings.conf
[General]
HaltCommand=/usr/sbin/shutdown -h now
RebootCommand=/usr/sbin/reboot

[Users]
MaximumUid=60000
MinimumUid=1000

[Autologin]
Relogin=false
ReuseSession=false

echo 'KERNEL=="cpu_dma_latency", PROTECTION="0666"' | sudo tee /etc/udev/rules.d/99-steamdeck-perf.rules
sudo udevadm control --reload-rules && sudo udevadm trigger

sudo nano /etc/default/grub
mitigations=off
sudo update-grub2

sudo usermod -a -G video,render,input,disk $USER

mkdir -p ~/.config/mangoapp
mkdir -p ~/.config/MangoHud

nano ~/.config/MangoHud/MangoHud.conf
control=mangoapp
fsr_steam_sharpness=5
nis_steam_sharpness=5

sudo VISUAL=nano visudo
ztge ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart sddm

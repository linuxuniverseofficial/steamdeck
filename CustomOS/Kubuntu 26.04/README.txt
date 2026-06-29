
sudo apt install gamescope mangoapp mangohud -y

GET sudo nano /usr/bin/steamos-session-select
sudo chmod +x /usr/bin/steamos-session-select

sudo bash -c 'cat > /usr/share/wayland-sessions/steam-gamescope.desktop << EOF
[Desktop Entry]
Name=Steam Game Mode
Comment=Start Steam in Steam Deck Hardware Session
Exec=/usr/local/bin/steam-sddm-watcher.sh
Type=Application
DesktopNames=Gamescope
EOF'

GET sudo nano /usr/local/bin/steam-sddm-watcher.sh
sudo chmod +x /usr/local/bin/steam-sddm-watcher.sh

GET sudo nano /usr/bin/steamos-leave-nested.sh
sudo chmod +x /usr/bin/steamos-leave-nested.sh

echo "kernel.unprivileged_userns_clone=1" | sudo tee /etc/sysctl.d/99-steam-sandbox.conf

mkdir -p ~/.config/xdg-desktop-portal
nano ~/.config/xdg-desktop-portal/gamescope-portals.conf
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

sudo usermod -a -G video,render,input,disk $USER

mkdir -p ~/.config/mangoapp
mkdir -p ~/.config/MangoHud

# Cria um link simbólico para enganar o Steam, fazendo ele achar que está no SteamOS
sudo ln -sf /usr/bin/mangoapp /usr/bin/srv/mangoapp 2>/dev/null || true

nano ~/.config/MangoHud/MangoHud.conf
control=mangoapp
fsr_steam_sharpness=5
nis_steam_sharpness=5

sudo VISUAL=nano visudo
ztge ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart sddm

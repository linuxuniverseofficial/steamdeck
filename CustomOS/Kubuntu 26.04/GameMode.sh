#!/bin/bash
# 1. Altera o arquivo para Modo Jogo
sed -i 's/Session=.*/Session=steam-gamescope/' /etc/sddm.conf.d/20-kubuntu.conf
sed -i 's/User=.*/User=ztge/' /etc/sddm.conf.d/20-kubuntu.conf
sed -i 's/Relogin=.*/Relogin=true/' /etc/sddm.conf.d/20-kubuntu.conf
sync

# 2. Reinicia o SDDM de forma limpa
systemctl restart sddm

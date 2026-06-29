#!/bin/bash
set -uo pipefail

export XDG_CURRENT_DESKTOP=Gamescope
export SDL_VIDEODRIVER=wayland

# CORREÇÃO: Aponta para onde o seu script real está (em /usr/bin/)
export STEAM_DESKTOP_RETURN_COMMAND="/usr/bin/steamos-session-select"

LOG="/tmp/steam-sddm-watcher.log"
echo "[$(date)] Iniciando sessão gamescope" > "$LOG"

# 1. Sobe o gamescope
env STEAM_MULTIPLE_XWAYLANDS=1 gamescope \
    -W 1280 -H 800 -r 60 -f -e --xwayland-count 2 \
    -- steam -gamepadui -steamdeck -steamos3 >> "$LOG" 2>&1 &
GAMESCOPE_PID=$!

# 2. Loop de monitoramento
while true; do
    sleep 2
    if ! kill -0 "$GAMESCOPE_PID" 2>/dev/null; then break; fi
    if ! pgrep -f "steam -gamepadui" > /dev/null; then break; fi
done

# 3. Encerramento limpo da GPU e Steam (Mantido original)
kill -TERM "$GAMESCOPE_PID" 2>/dev/null
for i in $(seq 1 10); do
    kill -0 "$GAMESCOPE_PID" 2>/dev/null || break
    sleep 0.5
done
if kill -0 "$GAMESCOPE_PID" 2>/dev/null; then
    kill -9 "$GAMESCOPE_PID" 2>/dev/null
fi

pkill -TERM steamwebhelper 2>/dev/null
pkill -TERM steam 2>/dev/null
pkill -TERM xwayland 2>/dev/null
sleep 2
pkill -9 steamwebhelper steam xwayland 2>/dev/null

# -----------------------------------------------------------------------------
# 4. Devolve a sessão de forma amigável sem dar "crash" no SDDM
# -----------------------------------------------------------------------------
echo "[$(date)] Sessão encerrada de forma limpa. Saindo." >> "$LOG"

# Em vez de passar o trator com o loginctl, apenas encerra o script atual.
# Como este script é o "pai" da sessão xsession/wayland do SDDM,
# quando ele termina com sucesso (exit 0), o SDDM entende que a sessão acabou 
# pacificamente por vontade do usuário, lê o arquivo 20-kubuntu.conf e faz o autologin.
exit 0

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
# 4. Devolve a sessão ao logind/SDDM corretamente
# -----------------------------------------------------------------------------
sleep 1
SESSION_ID=$(loginctl --no-legend list-sessions | awk -v u="$USER" '$3==u {print $1; exit}')
if [ -n "$SESSION_ID" ]; then
    loginctl terminate-session "$SESSION_ID"
else
    sudo systemctl restart sddm
fi

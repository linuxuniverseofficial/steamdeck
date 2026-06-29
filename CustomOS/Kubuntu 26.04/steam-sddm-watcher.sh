#!/bin/bash
# =============================================================================
# steam-sddm-watcher.sh
# Lança o gamescope + Steam em modo Big Picture e monitora o clique em
# "Exit to Desktop" (ou crash do gamescope), encerrando tudo de forma limpa
# e devolvendo a sessão ao SDDM/Plasma sem precisar reiniciar a máquina.
# =============================================================================

set -uo pipefail

# -----------------------------------------------------------------------------
# Variáveis de ambiente da sessão gamescope
# -----------------------------------------------------------------------------
export XDG_CURRENT_DESKTOP=Gamescope
export SDL_VIDEODRIVER=wayland

# Faz o Steam chamar este próprio script quando o usuário clicar em
# "Exit to Desktop" no menu de energia do Big Picture, em vez de depender
# só do polling via pgrep.
export STEAM_DESKTOP_RETURN_COMMAND="/usr/local/bin/steamos-leave-nested"

LOG="/tmp/steam-sddm-watcher.log"
echo "[$(date)] Iniciando sessão gamescope" > "$LOG"

# -----------------------------------------------------------------------------
# 1. Sobe o gamescope com o Steam dentro
# -----------------------------------------------------------------------------
env STEAM_MULTIPLE_XWAYLANDS=1 gamescope \
    -W 1280 -H 800 -r 60 -f -e --xwayland-count 2 \
    -- steam -gamepadui -steamdeck -steamos3 >> "$LOG" 2>&1 &
GAMESCOPE_PID=$!

# -----------------------------------------------------------------------------
# 2. Loop de monitoramento
#    Sai do loop se o gamescope morrer sozinho (crash) ou se o processo de
#    UI do Steam ("steam -gamepadui") desaparecer (sinal de "Exit to Desktop").
# -----------------------------------------------------------------------------
while true; do
    sleep 2

    if ! kill -0 "$GAMESCOPE_PID" 2>/dev/null; then
        echo "[$(date)] gamescope encerrou por conta própria" >> "$LOG"
        break
    fi

    if ! pgrep -f "steam -gamepadui" > /dev/null; then
        echo "[$(date)] Botão 'Exit to Desktop' detectado" >> "$LOG"
        break
    fi
done

# -----------------------------------------------------------------------------
# 3. Encerramento limpo (NUNCA usar -9 de primeira)
#    SIGTERM dá tempo do gamescope liberar o DRM master da GPU.
#    Matar com -9 direto deixa a GPU "presa", que é a causa mais comum
#    do travamento que só sai reiniciando o sistema.
# -----------------------------------------------------------------------------
echo "[$(date)] Enviando SIGTERM para o gamescope (PID $GAMESCOPE_PID)" >> "$LOG"
kill -TERM "$GAMESCOPE_PID" 2>/dev/null

for i in $(seq 1 10); do
    kill -0 "$GAMESCOPE_PID" 2>/dev/null || break
    sleep 0.5
done

# Só força com -9 se depois de ~5s ainda estiver vivo
if kill -0 "$GAMESCOPE_PID" 2>/dev/null; then
    echo "[$(date)] gamescope não respondeu a SIGTERM, forçando -9" >> "$LOG"
    kill -9 "$GAMESCOPE_PID" 2>/dev/null
fi

pkill -TERM steamwebhelper 2>/dev/null
pkill -TERM steam 2>/dev/null
pkill -TERM xwayland 2>/dev/null
sleep 2
pkill -9 steamwebhelper steam xwayland 2>/dev/null

# -----------------------------------------------------------------------------
# 4. Devolve a sessão ao logind/SDDM corretamente
#    Em vez de reiniciar o serviço SDDM (que não necessariamente realoca
#    a sessão antiga), encerramos a sessão atual via loginctl, deixando
#    o logind chamar o SDDM/Plasma de volta sem disputa de GPU.
# -----------------------------------------------------------------------------
SESSION_ID=$(loginctl --no-legend list-sessions | awk -v u="$USER" '$3==u {print $1; exit}')

if [ -n "$SESSION_ID" ]; then
    echo "[$(date)] Encerrando sessão $SESSION_ID via loginctl" >> "$LOG"
    loginctl terminate-session "$SESSION_ID"
else
    echo "[$(date)] Sessão não encontrada via loginctl, fallback para restart do sddm" >> "$LOG"
    sudo systemctl restart sddm
fi

echo "[$(date)] Finalizado" >> "$LOG"

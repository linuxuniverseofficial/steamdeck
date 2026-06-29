#!/bin/bash
# =============================================================================
# steamos-leave-nested.sh
# Chamado pelo steamos-session-select quando o usuário clica em
# "Exit to Desktop". Mata o gamescope de forma limpa ANTES de devolver a
# sessão, senão a GPU fica presa e trava o sistema.
# =============================================================================

set -uo pipefail

LOGDIR="/var/log/gamescope-session"
mkdir -p "$LOGDIR" 2>/dev/null
LOG="$LOGDIR/steamos-leave-nested.log"
echo "[$(date)] steamos-leave-nested acionado" >> "$LOG" 2>/dev/null || LOG="/dev/null"

# -----------------------------------------------------------------------------
# 1. Localiza o PID do gamescope (é ele quem detém o DRM master da GPU)
# -----------------------------------------------------------------------------
GAMESCOPE_PID=$(pgrep -x gamescope | head -n1)

if [ -n "$GAMESCOPE_PID" ]; then
    echo "[$(date)] Encontrado gamescope PID $GAMESCOPE_PID, enviando SIGTERM" >> "$LOG"
    kill -TERM "$GAMESCOPE_PID" 2>/dev/null

    for i in $(seq 1 10); do
        kill -0 "$GAMESCOPE_PID" 2>/dev/null || break
        sleep 0.5
    done

    if kill -0 "$GAMESCOPE_PID" 2>/dev/null; then
        echo "[$(date)] gamescope não respondeu, forçando -9" >> "$LOG"
        kill -9 "$GAMESCOPE_PID" 2>/dev/null
    fi
else
    echo "[$(date)] Nenhum processo gamescope encontrado" >> "$LOG"
fi

# -----------------------------------------------------------------------------
# 2. Limpa o resto da árvore de processos do Steam/Xwayland
# -----------------------------------------------------------------------------
pkill -TERM steamwebhelper 2>/dev/null
pkill -TERM steam 2>/dev/null
pkill -TERM xwayland 2>/dev/null
sleep 2
pkill -9 steamwebhelper steam xwayland 2>/dev/null

# -----------------------------------------------------------------------------
# 3. Devolve o seat ao logind de forma limpa (preferível a restart do sddm)
# -----------------------------------------------------------------------------
SESSION_ID=$(loginctl --no-legend list-sessions | awk -v u="$USER" '$3==u {print $1; exit}')

if [ -n "$SESSION_ID" ]; then
    echo "[$(date)] Encerrando sessão $SESSION_ID via loginctl" >> "$LOG"
    loginctl terminate-session "$SESSION_ID"
else
    echo "[$(date)] Sessão não encontrada, fallback para restart do sddm" >> "$LOG"
    sudo systemctl restart sddm
fi

echo "[$(date)] Finalizado" >> "$LOG"

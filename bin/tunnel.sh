#!/bin/bash
set -euo pipefail

# Generic SSH tunnel manager.
#
# Usage: tunnel.sh <name> <mode> <ssh-host> [ssh-args...]
#   name       - label for log messages and pidfile
#   mode       - start|stop|restart|status|log
#   ssh-host   - SSH host alias or user@host
#   ssh-args   - remaining args passed directly to ssh (e.g. -L 6443:10.0.0.1:6443 or -D 1080)

if ! command -v ssh &>/dev/null; then
    echo "ssh not found" >&2
    exit 1
fi

if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <name> <start|stop|restart|status|log> <ssh-host> [ssh-args...]" >&2
    exit 1
fi

NAME="$1"; shift
CMD="$1"; shift
SSH_HOST="$1"; shift
SSH_ARGS=("$@")

PIDFILE="/tmp/tunnel-${NAME}.pid"
LOGFILE="/tmp/tunnel-${NAME}.log"

forward_ports() {
    local i=0 arg spec port rest
    while (( i < ${#SSH_ARGS[@]} )); do
        arg="${SSH_ARGS[$i]}"
        spec=""

        case "$arg" in
            -D|-L)
                ((i += 1))
                spec="${SSH_ARGS[$i]:-}"
                ;;
            -D*|-L*)
                spec="${arg:2}"
                ;;
            *)
                ((i += 1))
                continue
                ;;
        esac

        if [[ "$arg" == -D* ]]; then
            port="${spec##*:}"
        else
            port="${spec%%:*}"
            if [[ ! "$port" =~ ^[0-9]+$ ]]; then
                rest="${spec#*:}"
                port="${rest%%:*}"
            fi
        fi

        if [[ "$port" =~ ^[0-9]+$ ]]; then
            echo "$port"
        fi
        ((i += 1))
    done
}

ssh_listener_pids_for_port() {
    local port="$1"
    lsof -nP -a -c ssh -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null || true
}

managed_listener_pids() {
    local port
    for port in $(forward_ports); do
        ssh_listener_pids_for_port "$port"
    done | sort -u
}

is_running() {
    [[ -f "$PIDFILE" ]] || return 1
    local pid listener_pid
    pid=$(<"$PIDFILE")
    [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null || return 1
    while IFS= read -r listener_pid; do
        [[ "$listener_pid" == "$pid" ]] && return 0
    done < <(managed_listener_pids)
    return 1
}

wait_for_tunnel() {
    local ports=()
    local port
    local deadline=$((SECONDS + 15))

    while IFS= read -r port; do
        ports+=("$port")
    done < <(forward_ports)

    if (( ${#ports[@]} == 0 )); then
        sleep 1
        [[ -n "$(managed_listener_pids)" ]]
        return
    fi

    while (( SECONDS < deadline )); do
        local all_listening=1
        for port in "${ports[@]}"; do
            if [[ -z "$(ssh_listener_pids_for_port "$port")" ]]; then
                all_listening=0
                break
            fi
        done

        if (( all_listening )); then
            sleep 2
            all_listening=1
            for port in "${ports[@]}"; do
                if [[ -z "$(ssh_listener_pids_for_port "$port")" ]]; then
                    all_listening=0
                    break
                fi
            done

            if (( all_listening )); then
                return 0
            fi
        fi

        sleep 1
    done

    return 1
}

do_stop() {
    if is_running; then
        local pid
        pid=$(cat "$PIDFILE")
        kill "$pid" 2>/dev/null || true
        rm -f "$PIDFILE"
        echo "[${NAME}] Tunnel stopped (was pid $pid)"
    else
        rm -f "$PIDFILE"
    fi
}

do_start() {
    if is_running; then
        echo "[${NAME}] Tunnel already running (pid $(cat "$PIDFILE"))"
        return 0
    fi
    rm -f "$PIDFILE"

    if [[ -n "$(managed_listener_pids)" ]]; then
        echo "[${NAME}] SSH forward already uses the configured port; refusing to stop it" >&2
        return 1
    fi

    : > "$LOGFILE"

    if ! ssh -f -N \
        -S none \
        -o ControlMaster=no \
        -o ForkAfterAuthentication=yes \
        -o ServerAliveInterval=15 \
        -o ServerAliveCountMax=3 \
        -o ExitOnForwardFailure=yes \
        -o ConnectTimeout=10 \
        "${SSH_ARGS[@]}" \
        "$SSH_HOST" >>"$LOGFILE" 2>&1; then
        echo "[${NAME}] Failed to connect to ${SSH_HOST}" >&2
        tail -20 "$LOGFILE" 2>/dev/null | sed "s/^/  /" >&2
        return 1
    fi

    if ! wait_for_tunnel; then
        echo "[${NAME}] Failed to confirm listener for ${SSH_HOST}" >&2
        tail -20 "$LOGFILE" 2>/dev/null | sed "s/^/  /" >&2
        return 1
    fi

    local pid
    pid="$(managed_listener_pids | head -1)"
    if [[ -z "$pid" ]]; then
        echo "[${NAME}] Failed to identify tunnel pid" >&2
        return 1
    fi
    echo "$pid" > "$PIDFILE"

    echo "[${NAME}] Tunnel started (pid $pid)"
    echo "[${NAME}] ssh ${SSH_ARGS[*]} -N ${SSH_HOST}"
}

case "$CMD" in
    start)  do_start ;;
    stop)   do_stop ;;
    restart)
        do_stop
        do_start
        ;;
    status)
        if is_running; then
            echo "[${NAME}] Tunnel running (pid $(cat "$PIDFILE"))"
            for port in $(forward_ports); do
                if [[ -n "$(ssh_listener_pids_for_port "$port")" ]]; then
                    echo "  port ${port}: listening"
                else
                    echo "  port ${port}: not listening"
                fi
            done
            tail -3 "$LOGFILE" 2>/dev/null | sed "s/^/  /"
        else
            echo "[${NAME}] Tunnel not running"
        fi
        ;;
    log)
        if [[ -f "$LOGFILE" ]]; then
            tail -20 "$LOGFILE"
        else
            echo "[${NAME}] No log file"
        fi
        ;;
    *)
        echo "Usage: $0 <name> <start|stop|restart|status|log> <ssh-host> [ssh-args...]" >&2
        exit 1
        ;;
esac

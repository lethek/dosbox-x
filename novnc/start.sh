#!/bin/bash
# Starts Xvnc, noVNC (websockify) and DOSBox-X. With AUTOSLEEP=1, DOSBox-X is
# paused (SIGSTOP) whenever no VNC client is connected.
set -euo pipefail

config=/config
if [ ! -w "$config" ]; then
    echo "$config is not writable, check the volume permissions" >&2
    exit 2
fi
mkdir -p "$config/drive_d" "$config/log" "$HOME/.vnc"

# Optional VeNCrypt (TLS inside the VNC protocol) for native VNC clients. It is
# offered next to the plain type because the built-in noVNC proxy needs plain VNC.
tls_dir="${TLSDIR:-/tls}"
tls_args=()
if [ -r "$tls_dir/tls.crt" ] && [ -r "$tls_dir/tls.key" ]; then
    echo "VeNCrypt enabled using the certificate in $tls_dir"
    tls_args=(-X509Cert "$tls_dir/tls.crt" -X509Key "$tls_dir/tls.key")
    x509=1
fi

if [ "${VNCAUTH:-password}" = "none" ]; then
    echo "VNCAUTH=none: VNC and noVNC require no password"
    auth_args=(-SecurityTypes "${x509:+X509None,}None")
else
    password="${VNCPASSWORD:-${VNCPASS:-}}"
    if [ -z "$password" ]; then
        password="$(head -c 12 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 8)"
        echo "No VNCPASSWORD set. Generated password for this session: $password"
    fi
    # VNC auth only uses the first 8 characters.
    printf '%s' "$password" | vncpasswd -f > "$HOME/.vnc/passwd"
    chmod 600 "$HOME/.vnc/passwd"
    auth_args=(-rfbauth "$HOME/.vnc/passwd" -SecurityTypes "${x509:+X509Vnc,}VncAuth")
fi

Xvnc "$DISPLAY" -rfbport 5901 "${auth_args[@]}" "${tls_args[@]}" \
    -geometry "$VNCGEOMETRY" -depth "$VNCDEPTH" \
    -AlwaysShared -ac &>"$config/log/xvnc.log" &
for _ in $(seq 1 50); do
    [ -S "/tmp/.X11-unix/X${DISPLAY#:}" ] && break
    sleep 0.2
done

websockify --web /usr/share/novnc 8080 127.0.0.1:5901 &>"$config/log/websockify.log" &

conf="$config/dosbox-x.conf"
if [ ! -f "$conf" ]; then
    echo "Creating $conf from defaults"
    timeout 60 dosbox-x -defaultconf -c "config -wc $conf" -c exit >/dev/null 2>&1 || true
    if [ -f "$conf" ]; then
        cat >> "$conf" <<'AUTOEXEC'

[autoexec]
mount d /config/drive_d
d:
if exist start.bat call start.bat
AUTOEXEC
    fi
fi

dosbox-x -conf "$conf" &>"$config/log/dosbox-x.log" &
dosbox_pid=$!

trap 'kill $(jobs -p) 2>/dev/null' TERM INT

if [ "${AUTOSLEEP:-0}" = "1" ]; then
    echo "Auto-sleep on: DOSBox-X pauses while no VNC client is connected"
    sleep 5
    state=run
    while kill -0 "$dosbox_pid" 2>/dev/null; do
        clients=$(ss -Htn state established '( sport = :5901 )' | wc -l)
        if [ "$clients" -eq 0 ] && [ "$state" = run ]; then
            kill -STOP "$dosbox_pid"; state=stop; echo "$(date) no clients: paused"
        elif [ "$clients" -gt 0 ] && [ "$state" = stop ]; then
            kill -CONT "$dosbox_pid"; state=run; echo "$(date) client connected: resumed"
        fi
        sleep 2
    done
else
    wait "$dosbox_pid"
fi
echo "DOSBox-X exited"

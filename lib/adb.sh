#!/usr/bin/env bash
# lib/adb.sh - ADB connection and transport management with automatic fallback tunnel

ADB_BIN=""
ADB_TARGET=""
ADB_PROXY_PID=""
ADB_LOCAL_PORT=""

find_adb() {
  if command -v adb >/dev/null 2>&1; then
    ADB_BIN="$(command -v adb)"
    return 0
  fi

  local candidates=(
    "$HOME/Library/Android/sdk/platform-tools/adb"
    "/Users/$(id -un)/Library/Android/sdk/platform-tools/adb"
    "/Users/michele/Library/Android/sdk/platform-tools/adb"
    "/opt/homebrew/bin/adb"
    "/usr/local/bin/adb"
  )

  for candidate in "${candidates[@]}"; do
    if [[ -x "$candidate" ]]; then
      ADB_BIN="$candidate"
      return 0
    fi
  done

  echo "Error: 'adb' executable not found." >&2
  echo "Please install android-platform-tools (e.g. via 'brew install android-platform-tools')." >&2
  return 1
}

cleanup_adb_tunnel() {
  if [[ -n "$ADB_PROXY_PID" ]]; then
    kill "$ADB_PROXY_PID" >/dev/null 2>&1 || true
    wait "$ADB_PROXY_PID" >/dev/null 2>&1 || true
    ADB_PROXY_PID=""
  fi
  if [[ -n "$ADB_LOCAL_PORT" && -n "$ADB_BIN" ]]; then
    "$ADB_BIN" disconnect "127.0.0.1:$ADB_LOCAL_PORT" >/dev/null 2>&1 || true
  fi
}

start_local_tunnel() {
  local remote_ip="$1"
  local remote_port="${2:-5555}"

  # Pick a random local port between 5556 and 5599
  ADB_LOCAL_PORT=$(( 5556 + RANDOM % 40 ))

  python3 -c "
import socket, threading, sys, time

src_port = $ADB_LOCAL_PORT
dst_ip = '$remote_ip'
dst_port = $remote_port

def forward(src, dst):
    while True:
        try:
            d = src.recv(8192)
            if not d: break
            dst.sendall(d)
        except Exception:
            break
    try: src.close()
    except: pass
    try: dst.close()
    except: pass

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(('127.0.0.1', src_port))
s.listen(5)

while True:
    try:
        c, _ = s.accept()
        r = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        r.connect((dst_ip, dst_port))
        threading.Thread(target=forward, args=(c, r), daemon=True).start()
        threading.Thread(target=forward, args=(remote_sock if False else r, c), daemon=True).start()
    except Exception:
        break
" &
  ADB_PROXY_PID=$!
  sleep 0.4
}

adb_connect() {
  local ip="$1"
  local port="${2:-5555}"

  find_adb || return 1

  echo "Connecting to Fire TV at $ip:$port..."
  local connect_output
  connect_output="$("$ADB_BIN" connect "$ip:$port" 2>&1)"

  if [[ "$connect_output" == *"connected"* && "$connect_output" != *"failed"* && "$connect_output" != *"No route"* ]]; then
    ADB_TARGET="$ip:$port"
    echo "Direct connection established."
    return 0
  fi

  if [[ "$connect_output" == *"No route to host"* ]]; then
    echo "Direct connect hit local network sandbox ('No route to host'). Starting local tunnel fallback..."
    start_local_tunnel "$ip" "$port"

    # Register trap to clean up proxy on exit
    trap cleanup_adb_tunnel EXIT INT TERM

    "$ADB_BIN" disconnect "127.0.0.1:$ADB_LOCAL_PORT" >/dev/null 2>&1 || true
    sleep 0.5
    local tunnel_output
    tunnel_output="$("$ADB_BIN" connect "127.0.0.1:$ADB_LOCAL_PORT" 2>&1)"

    if [[ "$tunnel_output" == *"connected"* || "$tunnel_output" == *"already connected"* ]]; then
      ADB_TARGET="127.0.0.1:$ADB_LOCAL_PORT"
      echo "Connection established via local tunnel ($ADB_TARGET)."
      return 0
    elif [[ "$tunnel_output" == *"unauthorized"* ]]; then
      echo "Device prompt shown: Please authorize USB Debugging on your TV screen."
      ADB_TARGET="127.0.0.1:$ADB_LOCAL_PORT"
      return 0
    else
      echo "Failed to connect via tunnel: $tunnel_output" >&2
      cleanup_adb_tunnel
      return 1
    fi
  fi

  echo "Failed to connect: $connect_output" >&2
  return 1
}

adb_cmd() {
  "$ADB_BIN" -s "$ADB_TARGET" "$@"
}

adb_shell() {
  "$ADB_BIN" -s "$ADB_TARGET" shell "$@"
}

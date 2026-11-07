#!/usr/bin/env bash
# firetv.sh - Main CLI entrypoint for Amazon Fire TV Optimizer

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source discover script
source "$SCRIPT_DIR/bin/discover.sh"
source "$SCRIPT_DIR/bin/optimize.sh"

show_help() {
  cat << EOF
Amazon Fire TV Optimizer CLI

Usage:
  ./firetv.sh [options]

Options:
  -i, --ip <IP>           Target Fire TV IP address (if omitted, auto-discovery is used)
  -p, --profile <name>    Profile name or path from profiles/ (default: auto-detected)
  -d, --discover          Scan local network for Fire TV devices and exit
  --all                   Run all optimizations (Cleanup + Debloat + Tweaks) [DEFAULT]
  --clean                 Run cleanup only (caches, leftover installer APKs, RAM)
  --debloat               Run debloat only (disable background telemetry and bloatware)
  --tweaks                Run tweaks only (animations to 0, limit ad tracking)
  --status                Check status of bloatware packages on device
  --revert                Re-enable bloatware and restore default animation/privacy settings
  -h, --help              Show this help message

Examples:
  ./firetv.sh                           # Auto-discover Fire TV and run full optimization
  ./firetv.sh -i 192.168.1.151          # Optimize specific Fire TV by IP
  ./firetv.sh -i 192.168.1.151 --revert # Restore stock settings on target device
  ./firetv.sh --discover                # Discover Fire TV devices on local Wi-Fi
EOF
}

TARGET_IP=""
TARGET_PROFILE=""
ACTION="all"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--ip)
      TARGET_IP="$2"
      shift 2
      ;;
    -p|--profile)
      TARGET_PROFILE="$2"
      shift 2
      ;;
    -d|--discover)
      discover_firetv
      exit 0
      ;;
    --all)
      ACTION="all"
      shift
      ;;
    --clean)
      ACTION="clean"
      shift
      ;;
    --debloat)
      ACTION="debloat"
      shift
      ;;
    --tweaks)
      ACTION="tweaks"
      shift
      ;;
    --status)
      ACTION="status"
      shift
      ;;
    --revert)
      ACTION="revert"
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      show_help
      exit 1
      ;;
  esac
done

# If no IP was provided, run discovery
if [[ -z "$TARGET_IP" ]]; then
  discover_firetv
  if [[ -f "/tmp/.firetv_last_discovered" ]]; then
    TARGET_IP="$(cat /tmp/.firetv_last_discovered)"
    rm -f "/tmp/.firetv_last_discovered"
    echo "Using discovered IP: $TARGET_IP"
  else
    echo "Error: No Fire TV specified and auto-discovery found no devices." >&2
    echo "Please specify target IP with: ./firetv.sh -i <IP>" >&2
    exit 1
  fi
fi

# Detect device model / OS if no profile specified
if [[ -z "$TARGET_PROFILE" ]]; then
  adb_connect "$TARGET_IP" || exit 1
  MODEL="$(adb_shell getprop ro.product.model 2>/dev/null | tr -d '\r')"
  OS_RELEASE="$(adb_shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')"

  echo "Detected Device Model: '$MODEL' (Android: $OS_RELEASE)"

  if [[ -f "$SCRIPT_DIR/profiles/fireos7-${MODEL:l}.conf" ]]; then
    TARGET_PROFILE="$SCRIPT_DIR/profiles/fireos7-${MODEL:l}.conf"
  elif [[ "$OS_RELEASE" == "9" ]]; then
    TARGET_PROFILE="$SCRIPT_DIR/profiles/fireos7-generic.conf"
  elif [[ "$OS_RELEASE" == "11" ]]; then
    TARGET_PROFILE="$SCRIPT_DIR/profiles/fireos8-generic.conf"
  else
    TARGET_PROFILE="$SCRIPT_DIR/profiles/fireos7-generic.conf"
  fi
else
  # Check if relative to profiles/
  if [[ ! -f "$TARGET_PROFILE" && -f "$SCRIPT_DIR/profiles/$TARGET_PROFILE" ]]; then
    TARGET_PROFILE="$SCRIPT_DIR/profiles/$TARGET_PROFILE"
  elif [[ ! -f "$TARGET_PROFILE" && -f "$SCRIPT_DIR/profiles/${TARGET_PROFILE}.conf" ]]; then
    TARGET_PROFILE="$SCRIPT_DIR/profiles/${TARGET_PROFILE}.conf"
  fi
fi

echo "Selected Profile: $TARGET_PROFILE"
run_optimization "$TARGET_IP" "$TARGET_PROFILE" "$ACTION"

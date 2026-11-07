#!/usr/bin/env bash
# bin/optimize.sh - Optimization execution engine

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source libraries
source "$SCRIPT_DIR/lib/adb.sh"
source "$SCRIPT_DIR/lib/cleanup.sh"
source "$SCRIPT_DIR/lib/debloat.sh"
source "$SCRIPT_DIR/lib/tweaks.sh"

run_optimization() {
  local ip="$1"
  local profile_file="$2"
  local action="${3:-all}"

  if [[ ! -f "$profile_file" ]]; then
    echo "Error: Profile file '$profile_file' not found." >&2
    return 1
  fi

  # Load profile configuration
  source "$profile_file"
  echo "=================================================="
  echo "Applying Profile: ${PROFILE_NAME:-Custom}"
  echo "=================================================="

  adb_connect "$ip" || return 1

  case "$action" in
    all)
      cleanup_all
      debloat_disable
      apply_tweaks
      ;;
    debloat)
      debloat_disable
      ;;
    clean)
      cleanup_all
      ;;
    tweaks)
      apply_tweaks
      ;;
    revert)
      debloat_enable
      revert_tweaks
      ;;
    status)
      debloat_status
      ;;
    *)
      echo "Unknown action: $action" >&2
      return 1
      ;;
  esac

  echo ""
  echo "Done!"
}

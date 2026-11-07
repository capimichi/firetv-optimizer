#!/usr/bin/env bash
# lib/debloat.sh - Manage bloatware packages safely via pm disable-user

debloat_disable() {
  echo "--- Disabling Bloatware Packages ---"
  local count=0
  for pkg in "${BLOAT_PACKAGES[@]}"; do
    local out
    out="$(adb_shell pm disable-user --user 0 "$pkg" 2>&1)"
    if [[ "$out" == *"new state: disabled-user"* ]]; then
      echo "  [DISABLED] $pkg"
      adb_shell am force-stop "$pkg" >/dev/null 2>&1 || true
      ((count++))
    elif [[ "$out" == *"Security exception"* ]]; then
      echo "  [PROTECTED] $pkg (Firmware protected, skipped safely)"
    elif [[ "$out" == *"not found"* || "$out" == *"Unknown package"* ]]; then
      echo "  [NOT INSTALLED] $pkg (Skipped)"
    else
      echo "  [INFO] $pkg: $out"
    fi
  done
  echo "Debloat completed: $count packages disabled."
}

debloat_enable() {
  echo "--- Reverting (Re-enabling) Bloatware Packages ---"
  local count=0
  for pkg in "${BLOAT_PACKAGES[@]}"; do
    local out
    out="$(adb_shell pm enable "$pkg" 2>&1)"
    if [[ "$out" == *"new state: enabled"* ]]; then
      echo "  [ENABLED] $pkg"
      ((count++))
    else
      echo "  [INFO] $pkg: $out"
    fi
  done
  echo "Revert completed: $count packages re-enabled."
}

debloat_status() {
  echo "--- Bloatware Packages Status ---"
  local disabled_list
  disabled_list="$(adb_shell pm list packages -d)"

  for pkg in "${BLOAT_PACKAGES[@]}"; do
    if echo "$disabled_list" | grep -q "$pkg"; then
      echo "  [DISABLED] $pkg"
    else
      echo "  [ACTIVE]   $pkg"
    fi
  done
}

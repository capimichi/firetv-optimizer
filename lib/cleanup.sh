#!/usr/bin/env bash
# lib/cleanup.sh - Cleanup leftover installation files, caches, and reclaim RAM

cleanup_downloads() {
  echo "--- Cleaning Leftover APKs in Downloads ---"
  local files
  files="$(adb_shell "ls /sdcard/Download/Downloader/*.apk 2>/dev/null || true" | tr -d '\r')"
  if [[ -n "$files" && "$files" != *"No such file"* ]]; then
    adb_shell "rm -f /sdcard/Download/Downloader/*.apk"
    echo "  Cleaned leftover APK files from /sdcard/Download/Downloader/."
  else
    echo "  No leftover APK files found in Downloads."
  fi
}

cleanup_caches() {
  echo "--- Trimming App Caches ---"
  local trim_bytes="${CACHE_TRIM_BYTES:-20000000000}"
  adb_shell pm trim-caches "$trim_bytes" >/dev/null 2>&1 || true
  adb_shell "rm -rf /sdcard/Android/data/*/cache/* 2>/dev/null || true"
  echo "  App caches trimmed successfully."
}

cleanup_ram() {
  echo "--- Reclaiming Idle Background Memory ---"
  adb_shell am kill-all >/dev/null 2>&1 || true
  echo "  Background idle processes terminated."
}

cleanup_all() {
  if [[ "${CLEAN_DOWNLOADS:-1}" -eq 1 ]]; then
    cleanup_downloads
  fi
  cleanup_caches
  cleanup_ram
}

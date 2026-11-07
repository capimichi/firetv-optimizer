#!/usr/bin/env bash
# lib/tweaks.sh - System responsiveness and privacy tweaks

apply_tweaks() {
  echo "--- Applying System & Privacy Tweaks ---"

  # Animations
  local win_scale="${WINDOW_ANIMATION_SCALE:-0.0}"
  local trans_scale="${TRANSITION_ANIMATION_SCALE:-0.0}"
  local anim_scale="${ANIMATOR_DURATION_SCALE:-0.0}"

  adb_shell settings put global window_animation_scale "$win_scale"
  adb_shell settings put global transition_animation_scale "$trans_scale"
  adb_shell settings put global animator_duration_scale "$anim_scale"
  echo "  Animations set to: $win_scale (window), $trans_scale (transition), $anim_scale (animator)."

  # Privacy & Telemetry
  if [[ "${LIMIT_AD_TRACKING:-1}" -eq 1 ]]; then
    adb_shell settings put secure limit_ad_tracking 1
    adb_shell settings put secure amz_limit_ad_tracking 1
    adb_shell settings put secure non_amz_limit_ad_tracking 1
    echo "  Ad tracking restricted."
  fi

  if [[ "${DISABLE_METRICS_UPLOAD:-1}" -eq 1 ]]; then
    adb_shell settings put secure USAGE_METRICS_UPLOAD_ENABLED 0
    echo "  Usage metrics upload disabled."
  fi
}

revert_tweaks() {
  echo "--- Reverting System & Privacy Tweaks ---"
  adb_shell settings put global window_animation_scale 1.0
  adb_shell settings put global transition_animation_scale 1.0
  adb_shell settings put global animator_duration_scale 1.0
  adb_shell settings put secure limit_ad_tracking 0
  adb_shell settings put secure amz_limit_ad_tracking 0
  adb_shell settings put secure non_amz_limit_ad_tracking 0
  adb_shell settings put secure USAGE_METRICS_UPLOAD_ENABLED 1
  echo "  System animations and privacy settings restored to factory defaults."
}

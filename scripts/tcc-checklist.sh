#!/usr/bin/env bash
# tcc-checklist.sh — guided macOS TCC grant walkthrough.
#
# Per ADR 13 / MIGRATION.md D19: TCC permissions are out of declarative scope.
# This script opens each Privacy & Security pane in System Settings via the
# `x-apple.systempreferences:` URL scheme and prints the apps from
# .ai/inventory/{applications-manual.txt,mas-apps.txt} that plausibly need
# each grant on AVA. The operator does the toggles by hand. No MDM.
#
# Usage:
#   bash /Users/CASE/manager/scripts/tcc-checklist.sh
#
# Behavior:
#   - Read-only. Opens Settings panes; does not mutate any TCC state.
#   - Idempotent. Re-run anytime to re-check.
#   - Runs as either CASE or testaccount.
#
# Notes:
#   - App lists are conservative — only obvious candidates from the live
#     inventory. Apps not installed are still listed if they would obviously
#     need the grant when present; they just won't appear in the Settings pane
#     until installed.
#   - Some panes (Automation, Files+Folders) populate dynamically as the
#     operator system uses apps. Empty pane is not a bug.

set -eu

pane() {
  local title=$1
  local url=$2
  shift 2
  printf '\n=== %s ===\n' "$title"
  printf '  pane: %s\n' "$url"
  open "$url" >/dev/null 2>&1 || printf '  WARN: failed to open %s\n' "$url" >&2
  printf '  expected apps to review:\n'
  local app
  for app in "$@"; do
    printf '    - %s\n' "$app"
  done
}

opened=0

pane "Files and Folders" \
  "x-apple.systempreferences:com.apple.preference.security?Privacy_FilesAndFolders" \
  "Ghostty" \
  "Alacritty" \
  "Visual Studio Code" \
  "Zed" \
  "BetterTouchTool" \
  "Karabiner-Elements" \
  "Hammerspoon" \
  "Things3" \
  "Day One" \
  "Bartender 6" \
  "logioptionsplus (Logi Options+)" \
  "Yoink"
opened=$((opened + 1))

pane "Full Disk Access" \
  "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles" \
  "Ghostty" \
  "Alacritty" \
  "Backblaze" \
  "BackblazeRestore" \
  "Time Machine (Apple)" \
  "DaisyDisk" \
  "1Password" \
  "Things3 (sync)" \
  "BetterTouchTool"
opened=$((opened + 1))

pane "Accessibility" \
  "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" \
  "BetterTouchTool" \
  "Karabiner-Elements" \
  "Hammerspoon" \
  "logioptionsplus (Logi Options+)" \
  "Raycast" \
  "Bartender 6" \
  "Yoink" \
  "Rectangle" \
  "1Password"
opened=$((opened + 1))

pane "Input Monitoring" \
  "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent" \
  "BetterTouchTool" \
  "Karabiner-Elements" \
  "Hammerspoon" \
  "logioptionsplus (Logi Options+)" \
  "Razer Synapse (if installed)"
opened=$((opened + 1))

pane "Screen Recording" \
  "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture" \
  "Loopback (if installed)" \
  "Ghostty" \
  "BetterTouchTool" \
  "Raycast" \
  "Karabiner-Elements" \
  "CleanShot X" \
  "Cap"
opened=$((opened + 1))

pane "Camera" \
  "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera" \
  "Zoom (if installed)" \
  "Slack" \
  "Discord" \
  "Krisp (if installed)" \
  "Loopback (if installed)" \
  "Photo Booth"
opened=$((opened + 1))

pane "Microphone" \
  "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone" \
  "Zoom (if installed)" \
  "Slack" \
  "Discord" \
  "Krisp (if installed)" \
  "Loopback (if installed)" \
  "Voice Memos" \
  "MacWhisper"
opened=$((opened + 1))

pane "Location Services" \
  "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices" \
  "Maps" \
  "Find My" \
  "Weather" \
  "GeoTagster" \
  "Geotag Photos Pro 2"
opened=$((opened + 1))

pane "Bluetooth" \
  "x-apple.systempreferences:com.apple.preference.security?Privacy_Bluetooth" \
  "AirBuddy (if installed)" \
  "iStat Menus" \
  "Bartender 6"
opened=$((opened + 1))

pane "Automation" \
  "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation" \
  "BetterTouchTool" \
  "Hammerspoon" \
  "Karabiner-Elements" \
  "Raycast" \
  "Things3"
opened=$((opened + 1))

pane "Calendars" \
  "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars" \
  "Cardhop" \
  "Fantastical" \
  "Slack" \
  "Discord" \
  "Notion" \
  "Notion Calendar" \
  "Things3" \
  "Reminders" \
  "Day One"
opened=$((opened + 1))

pane "Contacts" \
  "x-apple.systempreferences:com.apple.preference.security?Privacy_Contacts" \
  "Cardhop" \
  "Slack" \
  "1Password" \
  "Things3"
opened=$((opened + 1))

pane "Reminders" \
  "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders" \
  "Things3" \
  "Day One"
opened=$((opened + 1))

pane "Photos" \
  "x-apple.systempreferences:com.apple.preference.security?Privacy_Photos" \
  "Adobe Lightroom" \
  "iMovie" \
  "Affinity (if installed)" \
  "Photo Booth" \
  "Pixelmator (if installed)"
opened=$((opened + 1))

printf '\nopened %d Privacy panes. Toggle grants in System Settings; this script does not modify any TCC state.\n' "$opened"
printf 'granular control: System Settings > Privacy & Security > <pane> > +/- per app.\n'

#!/usr/bin/env bash
# permissions-walkthrough.sh — interactive, step-by-step macOS permissions setup.
#
# macOS TCC grants cannot be declared in Nix without MDM (MIGRATION.md D19),
# so this walkthrough is the supported path: one step per permission pane,
# opened directly via the x-apple.systempreferences: URL scheme. The operator
# does the toggles by hand; every step is skippable.
#
# The manifest below is the declared permission surface for this setup. It was
# generated 2026-07-28 from AVA's live TCC databases (user + system, allowed
# entries only) cross-checked against installed apps. Update it when an app is
# added that needs a grant.
#
# Usage:
#   scripts/permissions-walkthrough.sh          interactive walkthrough
#   scripts/permissions-walkthrough.sh --list   print the manifest and exit
#
# Read-only with respect to TCC: this script opens Settings panes and never
# mutates any grant. Idempotent; re-run anytime. Runs as any user.
#
# Supersedes scripts/tcc-checklist.sh (non-interactive, opened all panes at once).

set -eu

SETTINGS_SECURITY="x-apple.systempreferences:com.apple.preference.security"

STEPS=()

add() {
  # add <title> <url> <why> <comma-separated apps>
  STEPS+=("$1"$'\x1f'"$2"$'\x1f'"$3"$'\x1f'"$4")
}

# --- Manifest -----------------------------------------------------------------

add "App Management" \
  "$SETTINGS_SECURITY?Privacy_AppBundles" \
  "Lets the terminal update app bundles. Needed so darwin-rebuild / Home Manager activation and brew upgrades can touch /Applications without per-app prompts." \
  "Ghostty, Alacritty (whichever terminal runs the rebuilds)"

add "Full Disk Access" \
  "$SETTINGS_SECURITY?Privacy_AllFiles" \
  "Terminals need this to manage dotfiles under ~/Library and read protected paths during switches; backup and disk tools need it to do their job." \
  "Ghostty, Alacritty, Zed, Claude, Conductor, Backblaze, DaisyDisk, Hazel"

add "Accessibility" \
  "$SETTINGS_SECURITY?Privacy_Accessibility" \
  "Window managers, launchers, and input helpers control the UI through the accessibility API." \
  "1Password, Raycast, Rectangle, Moom, Bartender, Amphetamine, MacWhisper, KeyboardCleanTool, MonitorControl, BetterDisplay, Dropbox, Logi Options+, Rocket, Cap"

add "Input Monitoring" \
  "$SETTINGS_SECURITY?Privacy_ListenEvent" \
  "Device managers watch raw keyboard/mouse events." \
  "Logi Options+"

add "Screen & System Audio Recording" \
  "$SETTINGS_SECURITY?Privacy_ScreenCapture" \
  "Screenshot, recording, and screen-share tools." \
  "CleanShot X, Cap, MacWhisper, Zoom, Slack, Google Chrome, Firefox, Notion, 1Password, Bartender, Gather"

add "Automation (Apple Events)" \
  "$SETTINGS_SECURITY?Privacy_Automation" \
  "Apps scripting other apps. This pane fills in as apps make their first request — approve the prompts when they appear; nothing to pre-enable." \
  "Ghostty, Raycast, Conductor, Things3, Shortery, Fantastical"

add "Files and Folders" \
  "$SETTINGS_SECURITY?Privacy_FilesAndFolders" \
  "Per-folder (Desktop/Documents/Downloads) grants. Populates on first access — approve prompts as they appear." \
  "Zed, Ghostty, Alacritty, Claude Code, Dropbox, Hazel, Raycast, TablePlus, Xcode"

add "Camera" \
  "$SETTINGS_SECURITY?Privacy_Camera" \
  "Video-call and capture apps." \
  "Zoom, Slack, Google Chrome, Firefox, Riverside, Gather, Raycast, Cap"

add "Microphone" \
  "$SETTINGS_SECURITY?Privacy_Microphone" \
  "Call, dictation, and recording apps." \
  "Zoom, Slack, Discord, Google Chrome, Firefox, Signal, Claude, MacWhisper, CleanShot X, Notion, Gather, Cap"

add "Calendars" \
  "$SETTINGS_SECURITY?Privacy_Calendars" \
  "Calendar clients and apps that read events." \
  "Flighty, Craft, Fantastical, Cardhop, Notion Calendar"

add "Contacts" \
  "$SETTINGS_SECURITY?Privacy_Contacts" \
  "Contact clients and tools resolving names/keys." \
  "Cardhop, Fantastical, GPG Keychain, iStat Menus"

add "Reminders" \
  "$SETTINGS_SECURITY?Privacy_Reminders" \
  "Task managers importing from Reminders." \
  "Things3, Fantastical"

add "Photos" \
  "$SETTINGS_SECURITY?Privacy_Photos" \
  "Apps reading the Photos library." \
  "Day One, Darkroom, Google Chrome, Firefox, Notion, Geotag Photos Pro"

add "Bluetooth" \
  "$SETTINGS_SECURITY?Privacy_Bluetooth" \
  "Peripheral managers and monitors." \
  "iStat Menus, Logi Options+, ZMK Studio, Zoom"

add "Location Services" \
  "$SETTINGS_SECURITY?Privacy_LocationServices" \
  "System apps plus geotagging tools." \
  "Maps, Find My, Weather, GeoTagster"

add "Notifications" \
  "x-apple.systempreferences:com.apple.Notifications-Settings.extension" \
  "Not TCC, but worth a pass: allow/deny per app while everything is freshly installed." \
  "Messages, Slack, Signal, Zulip, HEY, Things3, Fantastical, Gitify, 1Password"

add "Login Items & Extensions" \
  "x-apple.systempreferences:com.apple.LoginItems-Settings.extension" \
  "Enable background helpers so menu-bar and sync apps start at login." \
  "1Password, Bartender, Dropbox, Backblaze, Amphetamine, iStat Menus, Rectangle/Moom, Logi Options+"

# --- Runner -------------------------------------------------------------------

total=${#STEPS[@]}

print_step() {
  # print_step <index> <title> <why> <apps>
  printf '\n[%s/%s] %s\n' "$1" "$total" "$2"
  printf '  %s\n' "$3"
  printf '  Review/enable:\n'
  printf '%s\n' "$4" | tr ',' '\n' | sed 's/^ */    - /'
}

list_only=0
[ "${1:-}" = "--list" ] && list_only=1

if [ "$list_only" -eq 1 ] || [ ! -t 0 ]; then
  printf 'Declared macOS permission surface (%s steps):\n' "$total"
  i=0
  for s in "${STEPS[@]}"; do
    i=$((i + 1))
    IFS=$'\x1f' read -r title url why apps <<<"$s"
    print_step "$i" "$title" "$why" "$apps"
    printf '  pane: %s\n' "$url"
  done
  exit 0
fi

printf 'macOS permissions walkthrough — %s steps.\n' "$total"
printf 'Each step opens the right System Settings pane; you flip the switches.\n'
printf 'Keys: [Enter] open pane   [s] skip step   [q] quit\n'

i=0
skipped=0
for s in "${STEPS[@]}"; do
  i=$((i + 1))
  IFS=$'\x1f' read -r title url why apps <<<"$s"
  print_step "$i" "$title" "$why" "$apps"
  printf '  [Enter] open   [s]kip   [q]uit > '
  read -r answer || answer=q
  case "$answer" in
    q|Q)
      printf 'Stopped at step %s/%s. Re-run anytime: scripts/permissions-walkthrough.sh\n' "$i" "$total"
      exit 0
      ;;
    s|S)
      skipped=$((skipped + 1))
      continue
      ;;
    *)
      open "$url" >/dev/null 2>&1 || printf '  WARN: failed to open %s\n' "$url" >&2
      printf '  Toggle the apps above, then press Enter to continue... '
      read -r _ || true
      ;;
  esac
done

printf '\nDone: %s steps reviewed, %s skipped. Re-run anytime to revisit.\n' "$((total - skipped))" "$skipped"

#!/usr/bin/env bash
# server-doctor — verify the always-on server role (modules/darwin/server.nix).
# Read-only. Checks needing root are run via `sudo -n` and reported as SKIP
# when no cached/passwordless sudo is available. Exit 1 if any check FAILs.
set -u

fails=0
pass() { printf '\033[32mPASS\033[0m %s\n' "$*"; }
fail() { printf '\033[31mFAIL\033[0m %s\n' "$*"; fails=$((fails + 1)); }
warn() { printf '\033[33mWARN\033[0m %s\n' "$*"; }
skip() { printf '\033[90mSKIP\033[0m %s\n' "$*"; }
check() { # check <description> <command...>
  local d=$1; shift
  if "$@" >/dev/null 2>&1; then pass "$d"; else fail "$d"; fi
}
root=0; sudo -n true 2>/dev/null && root=1

echo "== Reachability"
check "sshd listening on :22" nc -z -G2 127.0.0.1 22
check "Screen Sharing listening on :5900" nc -z -G2 127.0.0.1 5900
ts=/Applications/Tailscale.app/Contents/MacOS/Tailscale
if [ -x "$ts" ] && ip=$("$ts" ip -4 2>/dev/null) && [ -n "$ip" ]; then
  pass "Tailscale up ($ip)"
  check "sshd reachable via tailnet IP" nc -z -G2 "$ip" 22
else
  fail "Tailscale not connected"
fi
check "Tailscale.app running" pgrep -xq Tailscale

echo "== SSH hardening"
if [ $root = 1 ]; then
  t=$(sudo -n /usr/sbin/sshd -T 2>/dev/null)
  for kv in "passwordauthentication no" "kbdinteractiveauthentication no" "permitrootlogin no" "authenticationmethods publickey" "allowusers $(id -un)"; do
    grep -qix "$kv" <<<"$t" && pass "sshd: $kv" || fail "sshd: expected '$kv'"
  done
else
  skip "sshd -T (needs sudo)"
fi
if [ -s "/etc/ssh/nix_authorized_keys.d/$(id -un)" ]; then
  pass "declared authorized keys present ($(grep -c . "/etc/ssh/nix_authorized_keys.d/$(id -un)") keys)"
else
  fail "no declared authorized keys in /etc/ssh/nix_authorized_keys.d"
fi

echo "== Firewall (pf)"
if [ $root = 1 ]; then
  sudo -n pfctl -s info 2>/dev/null | grep -q 'Status: Enabled' && pass "pf enabled" || fail "pf disabled"
  sudo -n pfctl -a server -sr 2>/dev/null | grep -q 'block return in quick on' && pass "pf 'server' anchor loaded" || fail "pf 'server' anchor missing"
else
  skip "pf state (needs sudo)"
fi

echo "== Power"
pm=$(pmset -g custom)
ac=$(awk '/^AC Power:/{f=1;next} /:$/{f=0} f' <<<"$pm")
awk '$1=="sleep"{exit ($2==0)?0:1}' <<<"$ac" && pass "AC: system sleep disabled" || fail "AC: system sleep enabled"
check "caffeinate daemon running" pgrep -f 'caffeinate -i -s'
pmset -g assertions | grep -q 'PreventUserIdleSystemSleep *1' && pass "idle-sleep prevention asserted" || fail "no idle-sleep assertion"
pmset -g batt | grep -q "AC Power" && pass "on AC power" || warn "running on battery"

echo "== Session & secrets"
check "1Password running" pgrep -xq 1Password
if SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" ssh-add -l >/dev/null 2>&1; then
  pass "1Password SSH agent serving keys (app unlocked)"
else
  fail "1Password SSH agent not serving keys (app locked?)"
fi

echo "== Reboot safety"
fdesetup isactive >/dev/null 2>&1 && warn "FileVault on: unplanned reboot needs local unlock; plan reboots with server-reboot" || pass "FileVault off"
[ "$(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates 2>/dev/null)" = 0 ] \
  && pass "automatic macOS installs off" || fail "automatic macOS installs may reboot the machine"
[ -e /etc/sudoers.d/zz-claude-temp ] && warn "temporary NOPASSWD sudoers file present: /etc/sudoers.d/zz-claude-temp"

echo
[ $fails = 0 ] && echo "server-doctor: all checks passed" || echo "server-doctor: $fails check(s) failed"
exit $((fails > 0))

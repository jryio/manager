export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

# The managed nvim configuration is LazyVim. Do not inherit an editor from a
# parent process: agent harnesses often set these to `true` to disable editing.
export EDITOR="nvim"
export VISUAL="$EDITOR"
export GIT_EDITOR="$EDITOR"
export GIT_SEQUENCE_EDITOR="$EDITOR"

prepend_path_if_dir() {
  local dir="$1"

  [[ -d "$dir" ]] || return 0

  if (( ${path[(Ie)$dir]} == 0 )); then
    path=("$dir" $path)
  fi
}

# Re-assert Home Manager sessionPath dirs: a poisoned parent (guard set, PATH
# rebuilt) otherwise leaves these missing in interactive shells.
prepend_path_if_dir "$HOME/go/bin"
prepend_path_if_dir "$HOME/.local/bin"

export BUN_INSTALL="$HOME/.bun"
prepend_path_if_dir "$BUN_INSTALL/bin"

if [[ -s "$BUN_INSTALL/_bun" ]]; then
  source "$BUN_INSTALL/_bun"
fi

export NVM_DIR="$HOME/.nvm"

if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  source "$NVM_DIR/nvm.sh" --no-use

  if [[ -s "$NVM_DIR/bash_completion" ]]; then
    source "$NVM_DIR/bash_completion"
  fi

  autoload -U add-zsh-hook

  load-nvmrc() {
    local node_version
    local nvmrc_node_version
    local nvmrc_path

    node_version="$(nvm version)"
    nvmrc_path="$(nvm_find_nvmrc)"

    if [[ -n "$nvmrc_path" ]]; then
      nvmrc_node_version="$(nvm version "$(cat "$nvmrc_path")")"

      if [[ "$nvmrc_node_version" != "N/A" && "$nvmrc_node_version" != "$node_version" ]]; then
        nvm use >/dev/null
      fi
    elif [[ "$node_version" != "$(nvm version default)" ]]; then
      nvm use default >/dev/null
    fi
  }

  add-zsh-hook chpwd load-nvmrc
  load-nvmrc
fi

unset MAILCHECK

gpg_tty="$(tty 2>/dev/null || true)"
if [[ "$gpg_tty" == /dev/* ]]; then
  export GPG_TTY="$gpg_tty"
elif [[ "${GPG_TTY-}" != /dev/* ]]; then
  unset GPG_TTY
fi
unset gpg_tty

if [[ -r "$HOME/.config/links/zsh-local" ]]; then
  source "$HOME/.config/links/zsh-local"
fi

unalias fd 2>/dev/null
unalias rd 2>/dev/null
unalias gcm 2>/dev/null
unalias man 2>/dev/null

cs() {
  if [[ $# -eq 0 ]]; then
    cd ~ && ll
  else
    cd "$*" && ll
  fi
}

timezsh() {
  local shell_name
  local i

  shell_name="${1:-$SHELL}"

  for i in $(seq 1 10); do
    /usr/bin/time "$shell_name" -i -c exit
  done
}

jobscount() {
  local total

  total="$(jobs -p | wc -l | tr -d ' ')"
  echo "$total"
}

port-finder() {
  local port="${1:-}"
  local port_number pid line command executable cwd
  local -a pids

  if [[ ! "$port" =~ ^[0-9]{1,5}$ ]]; then
    print -u2 "usage: port-finder <port>"
    return 64
  fi
  port_number=$((10#$port))
  if ((port_number < 1 || port_number > 65535)); then
    print -u2 "usage: port-finder <port>"
    return 64
  fi

  while IFS= read -r pid; do
    [[ -n "$pid" ]] && pids+=("$pid")
  done < <(
    {
      lsof -nP -t -iTCP:"$port_number" -sTCP:LISTEN 2>/dev/null || true
      lsof -nP -t -iUDP:"$port_number" 2>/dev/null || true
    } | sort -nu
  )

  if (( ${#pids[@]} == 0 )); then
    gum style --foreground 240 "No TCP listener or UDP socket uses port $port_number."
    return 0
  fi

  for pid in "${pids[@]}"; do
    command=''
    executable=''
    cwd=''

    while IFS= read -r line; do
      case "$line" in
        c*) command=${line#c} ;;
        n*) executable=${line#n}; break ;;
      esac
    done < <(lsof -n -a -p "$pid" -d txt -Fcn 2>/dev/null || true)

    while IFS= read -r line; do
      [[ "$line" == n* ]] && { cwd=${line#n}; break; }
    done < <(lsof -n -a -p "$pid" -d cwd -Fn 2>/dev/null || true)

    printf '%s\t%s\t%s\t%s\n' "$pid" "${command:--}" "${executable:--}" "${cwd:--}"
  done | gum table --print \
    --separator=$'\t' \
    --columns PID,COMMAND,EXECUTABLE,CWD
}

man() {
  env \
    LESS_TERMCAP_mb=$'\e[1;31m' \
    LESS_TERMCAP_md=$'\e[1;31m' \
    LESS_TERMCAP_me=$'\e[0m' \
    LESS_TERMCAP_se=$'\e[0m' \
    LESS_TERMCAP_so=$'\e[1;44;33m' \
    LESS_TERMCAP_ue=$'\e[0m' \
    LESS_TERMCAP_us=$'\e[1;32m' \
    man "$@"
}

gcm() {
  git commit -m "$*"
}

# git log, signed: tig-style one-line log with each commit's signature status.
# %G? codes: G=good, U=good but untrusted, N=unsigned, B/X/Y/R=bad/expired/
# revoked, E=uncheckable.
gls() {
  git --no-pager log --color=always \
    --pretty=format:'%G?%x1f%GK%x1f%ad%x1f%an%x1f%p%x1f%C(auto)%D%C(reset)%x1f%s' \
    --date=format:'%Y-%m-%d %H:%M %z' "$@" \
    | awk -F '\037' '
        {
          sig  = $1; key = $2; date = $3; auth = $4
          parents = $5; refs = $6; subj = $7

          marker = "o"
          if (parents == "") marker = "I"
          else if (parents ~ / /) marker = "M"

          green   = "\033[32m"
          yellow  = "\033[33m"
          red     = "\033[1;31m"
          magenta = "\033[35m"
          reset   = "\033[0m"

          if (sig == "G")      badge = green   "✓ " key
          else if (sig == "U") badge = yellow  "✓ " key
          else if (sig == "N") badge = red     "✗"
          else if (sig == "B") badge = red     "✗ BAD " key
          else if (sig == "X") badge = yellow  "✓ EXPIRED " key
          else if (sig == "Y") badge = yellow  "✓ EXP-KEY " key
          else if (sig == "R") badge = red     "✓ REVOKED " key
          else if (sig == "E") badge = magenta "? " key
          else                 badge = sig " " key

          # %C(auto)%D%C(reset) leaves stray reset codes when refs are empty.
          plain = refs
          gsub(/\033\[[0-9;]*m/, "", plain)
          if (plain != "") refs = refs " "

          printf "%s %s %s%s %s %s%s\n", date, auth, badge, reset, marker, refs, subj
        }
      ' \
    | if [[ -t 1 ]]; then less -FRX; else cat; fi
}

jjdm() {
  jj describe -m "$*"
}

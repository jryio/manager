export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

if [[ -n ${SSH_CONNECTION-} ]]; then
  export EDITOR="vim"
elif command -v zed >/dev/null 2>&1; then
  export EDITOR="zed --wait"
fi

prepend_path_if_dir() {
  local dir="$1"

  [[ -d "$dir" ]] || return 0

  if (( ${path[(Ie)$dir]} == 0 )); then
    path=("$dir" $path)
  fi
}

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

jjdm() {
  jj describe -m "$*"
}

# Configure Oh My Zsh behavior before its completion setup runs.
DISABLE_AUTO_TITLE="true"
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="false"
DISABLE_UNTRACKED_FILES_DIRTY="true"
skip_global_compinit=1
ZSH_DISABLE_COMPFIX=true

# Preserve the existing fzf-tab completion behavior.
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'if command -v eza >/dev/null 2>&1; then eza -1 --color=always "$realpath"; elif command -v exa >/dev/null 2>&1; then exa -1 --color=always "$realpath"; else command ls -1 "$realpath"; fi'
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:*' fzf-bindings 'right:toggle'

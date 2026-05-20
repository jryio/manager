# fzf-tab completion zstyles. Must run before HM's compinit (mkOrder 570).
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'if command -v eza >/dev/null 2>&1; then eza -1 --color=always "$realpath"; elif command -v exa >/dev/null 2>&1; then exa -1 --color=always "$realpath"; else command ls -1 "$realpath"; fi'
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:*' fzf-bindings 'right:toggle'

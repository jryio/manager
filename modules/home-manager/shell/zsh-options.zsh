# Replaces oh-my-zsh's lib/*.zsh baseline behaviors. Sourced at mkOrder 720
# (between HM's autosuggestion at 700 and HM's setOptions at 950).
#
# Provenance per behavior in comments; verbatim OMZ functions reproduced from
# https://github.com/ohmyzsh/ohmyzsh @ 18d0a63df8ed61aad7b25dc9c6f61a7cb88760dc
# (MIT). HM `programs.zsh.history.*` covers the history flag surface; what
# remains here is setopts + keybinds + magic-space + take/mkcd/etc.

# History setopts not exposed by programs.zsh.history.*
setopt hist_verify

# Directory navigation (OMZ lib/directories.zsh)
setopt auto_cd auto_pushd pushd_ignore_dups pushdminus interactivecomments \
       multios long_list_jobs

# Numbered dir-stack jumps 1..9 (OMZ lib/directories.zsh)
alias 1='cd -1'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'
alias 6='cd -6'
alias 7='cd -7'
alias 8='cd -8'
alias 9='cd -9'
alias -- -='cd -'

# Key bindings (OMZ lib/key-bindings.zsh)
autoload -U up-line-or-beginning-search down-line-or-beginning-search
autoload -Uz edit-command-line
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
zle -N edit-command-line
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^X^E' edit-command-line
bindkey ' '   magic-space

# URL quoting + bracketed paste (OMZ lib/misc.zsh)
autoload -Uz bracketed-paste-magic url-quote-magic
zle -N bracketed-paste bracketed-paste-magic
zle -N self-insert    url-quote-magic

# `take` and friends — verbatim from OMZ lib/functions.zsh (MIT)
function zsh_stats() {
  fc -l 1 \
    | awk '{ CMD[$2]++; count++; } END { for (a in CMD) print CMD[a] " " CMD[a]*100/count "% " a }' \
    | grep -v "./" | sort -nr | head -n 20 | column -c3 -s " " -t | nl
}

function mkcd takedir() {
  mkdir -p $@ && cd ${@:$#}
}

function takeurl() {
  local data thedir
  data="$(mktemp)"
  curl -L "$1" > "$data"
  tar xf "$data"
  thedir="$(tar tf "$data" | head -n 1)"
  rm "$data"
  cd "$thedir"
}

function takezip() {
  local data thedir
  data="$(mktemp)"
  curl -L "$1" > "$data"
  unzip "$data" -d "./"
  thedir="$(unzip -l "$data" | awk 'NR==4 {print $4}' | sed 's/\/.*//')"
  rm "$data"
  cd "$thedir"
}

function takegit() {
  git clone "$1"
  cd "$(basename ${1%%.git})"
}

function take() {
  if [[ $1 =~ ^(https?|ftp).*\.(tar\.(gz|bz2|xz)|tgz)$ ]]; then
    takeurl "$1"
  elif [[ $1 =~ ^(https?|ftp).*\.(zip)$ ]]; then
    takezip "$1"
  elif [[ $1 =~ ^([A-Za-z0-9]\+@|https?|git|ssh|ftps?|rsync).*\.git/?$ ]]; then
    takegit "$1"
  else
    takedir "$@"
  fi
}

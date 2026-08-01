# Completion registrations that need compdef, so this must be sourced
# after HM's compinit stage. Completion *styles* live in
# completion-styles.zsh, which runs before compinit instead.

#compdef codex-security
_incur_complete_codex_security() {
    local completions=("${(@f)$(
        export _COMPLETE_INDEX=$(( CURRENT - 1 ))
        export COMPLETE="zsh"
        "codex-security" -- "${words[@]}" 2>/dev/null
    )}")
    if [[ -n $completions ]]; then
        _describe 'values' completions -S ''
    fi
}
compdef _incur_complete_codex_security codex-security

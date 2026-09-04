
# ---- Clash Verge proxy (port 7897) ----
if (command -v ss >/dev/null 2>&1 && ss -tln 2>/dev/null | grep -q '127.0.0.1:7897') || (nc -z 127.0.0.1 7897 2>/dev/null); then
    export http_proxy=http://127.0.0.1:7897
    export https_proxy=http://127.0.0.1:7897
    export HTTP_PROXY=http://127.0.0.1:7897
    export HTTPS_PROXY=http://127.0.0.1:7897
    export all_proxy=socks5h://127.0.0.1:7897
    export ALL_PROXY=socks5h://127.0.0.1:7897
    export no_proxy=localhost,127.0.0.1,::1,.local,api.github.com
fi

# Paths
typeset -U path PATH
path=(
    "$HOME/.local/bin"
    "$HOME/.bun/bin"
    $path
)
export PATH

# Preferred editor
export EDITOR="nvim"
export VISUAL="nvim"

# History
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=50000
SAVEHIST=50000
mkdir -p -- "${HISTFILE:h}"
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY

# Completion
autoload -Uz compinit
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
mkdir -p -- "$XDG_CACHE_HOME/zsh"
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

# Emacs-style line editing
bindkey -e
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward
bindkey '^R' history-incremental-search-backward

# Inline suggestions from history, with completion as a fallback.
if [[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Directory navigation and readable listings
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
if (( $+commands[eza] )); then
    alias ls='eza --icons=auto --group-directories-first'
    alias ll='eza -lah --icons=auto --group-directories-first --git'
    alias tree='eza --tree --icons=auto'
fi


# Sorin-inspired two-line prompt: framed identity/path with compact Git state.
if (( $+commands[starship] )); then
    eval "$(starship init zsh)"
else
    autoload -Uz colors vcs_info add-zsh-hook
    colors
    setopt PROMPT_SUBST

    zstyle ':vcs_info:git:*' formats ' %F{blue}git%f:%F{red}%b%f'
    function _prompt_vcs_info() {
        vcs_info
    }
    add-zsh-hook precmd _prompt_vcs_info

    PROMPT='%F{cyan}╭─[%F{green}%n%F{cyan}@%F{blue}%m%F{cyan}]─[%F{magenta}%2~%F{cyan}]%f${vcs_info_msg_0_}
%F{cyan}╰─%(?.%F{green}.%F{red})❯%f '
    RPROMPT='%(?..%F{red}[%?]%f )%F{242}%D{%H:%M}%f'
fi

# Must be sourced after widgets and prompt configuration.
if [[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
export PATH="$HOME/.local/bin:$PATH"

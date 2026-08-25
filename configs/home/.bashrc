#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

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

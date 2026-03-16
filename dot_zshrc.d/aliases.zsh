# --- ls/eza ---
if command -v eza &>/dev/null; then
    alias ls='eza -al --color=always --group-directories-first --icons'
    alias la='eza -a --color=always --group-directories-first --icons'
    alias ll='eza -l --color=always --group-directories-first --icons'
    alias lt='eza -aT --color=always --group-directories-first --icons'
    alias l.='eza -a | grep -e "^\."'
    compdef ls=eza
    compdef la=eza
    compdef ll=eza
    compdef lt=eza
else
    alias ls='ls --color=auto'
    alias la='ls -A --color=auto'
    alias ll='ls -l --color=auto'
    alias lt='ls -lA --color=auto'
    alias l.='ls -A | grep -e "^\."'
fi

# --- Navigation ---
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# --- Colorize ---
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# --- Common ---
alias tarnow='tar -acf '
alias untar='tar -zxvf '
alias wget='wget -c '
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'
alias please='sudo'
alias tb='nc termbin.com 9999'
alias jctl="journalctl -p 3 -xb"

# --- Distrobox shortcuts ---
alias worktalos='distrobox enter talos -nw'
alias workprintersrow='distrobox enter printersrow -nw'
alias workflock='distrobox enter flock -nw'

# --- Functions ---
history() {
    builtin fc -li 1
}

backup() {
    cp "$1" "$1.bak"
}

copy() {
    if [[ $# -eq 2 && -d "$1" ]]; then
        local from="${1%/}"
        command cp -r "$from" "$2"
    else
        command cp "$@"
    fi
}

ghcloneall() {
    gh repo list "$1" --limit 4000 | while read -r repo _rest; do
        gh repo clone "$repo" "$repo" < /dev/null
    done
}

runansible() {
    (cd ~/.local/share/ansible-setup && ./bootstrap.sh)
}

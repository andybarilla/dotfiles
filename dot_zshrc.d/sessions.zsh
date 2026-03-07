# --- Tmux shortcuts ---
alias tmuxt='tmux new -c $HOME/dev/titlevision-ai -A -s talos'
alias tmuxs='tmux new -c $HOME/dev/andybarilla/skeetr-app -A -s skeetr'
alias tmuxp='tmux new -A -s printersrow'

# --- Claude/LLM ---
alias qwen='ANTHROPIC_AUTH_TOKEN=ollama ANTHROPIC_API_KEY= ANTHROPIC_BASE_URL=http://apbmini:11434 claude --model qwen3-coder'
alias zlm='ANTHROPIC_AUTH_TOKEN=$ZLM_API_KEY ANTHROPIC_BASE_URL=https://api.z.ai/api/anthropic claude'

# --- Zellij session management ---
# rc = Run Claude: Start new session with auto-generated name
rc() {
    local session_name="agents-$(date +%m%d-%H%M)"
    zellij --session "$session_name" --new-session-with-layout agents
}

# rj = Run Join: Quick attach to session
rj() {
    local session="${1:-$(zellij list-sessions -n | head -1 | awk '{print $1}')}"
    zellij attach "$session"
}

# rl = Run List: Interactive session picker with cleanup
rl() {
    local sessions=()
    while IFS= read -r line; do
        sessions+=("$line")
    done < <(zellij list-sessions -n 2>/dev/null)

    if [[ ${#sessions[@]} -eq 0 ]]; then
        echo "No sessions. Use 'rc' to start one."
        return 1
    fi

    echo "Sessions:"
    local i=1
    for session in "${sessions[@]}"; do
        echo "  $i) $session"
        ((i++))
    done
    echo "  c) Clean EXITED sessions"
    echo "  d) Delete sessions >24h old"

    read -r "choice?Select: "

    case "$choice" in
        c)
            local deleted=0
            for line in "${sessions[@]}"; do
                if [[ "$line" == *"EXITED"* ]]; then
                    local name=$(echo "$line" | awk '{print $1}')
                    zellij delete-session "$name" 2>/dev/null && ((deleted++))
                fi
            done
            echo "Deleted $deleted exited session(s)"
            ;;
        d)
            local deleted=0
            for line in "${sessions[@]}"; do
                if [[ "$line" == *"day"* ]]; then
                    local name=$(echo "$line" | awk '{print $1}')
                    zellij delete-session --force "$name" 2>/dev/null && ((deleted++))
                fi
            done
            echo "Deleted $deleted session(s) older than 24h"
            ;;
        [0-9]*)
            local name=$(echo "${sessions[$choice]}" | awk '{print $1}')
            zellij attach "$name"
            ;;
    esac
}

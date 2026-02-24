# rc = Run Claude: Start new session with auto-generated name
function rc
    set -l session_name "agents-(date +%m%d-%H%M)"
    zellij --session "$session_name" --new-session-with-layout agents
end

# rj = Run Join: Quick attach to session
function rj
    set -l session
    if set -q argv[1]
        set session $argv[1]
    else
        set session (zellij list-sessions -n | head -1 | awk '{print $1}')
    end
    zellij attach "$session"
end

# rl = Run List: Interactive session picker with cleanup
function rl
    set -l sessions (zellij list-sessions -n 2>/dev/null)

    if test (count $sessions) -eq 0
        echo "No sessions. Use 'rc' to start one."
        return 1
    end

    echo "Sessions:"
    set -l i 1
    for session in $sessions
        echo "  $i) $session"
        set i (math $i + 1)
    end
    echo "  c) Clean EXITED sessions"
    echo "  d) Delete sessions >24h old"

    read --prompt-str "Select: " choice

    switch "$choice"
        case c
            set -l deleted 0
            for line in $sessions
                if string match -q "*EXITED*" "$line"
                    set -l name (echo "$line" | awk '{print $1}')
                    zellij delete-session "$name" 2>/dev/null; and set deleted (math $deleted + 1)
                end
            end
            echo "Deleted $deleted exited session(s)"
        case d
            set -l deleted 0
            for line in $sessions
                if string match -q "*day*" "$line"
                    set -l name (echo "$line" | awk '{print $1}')
                    zellij delete-session --force "$name" 2>/dev/null; and set deleted (math $deleted + 1)
                end
            end
            echo "Deleted $deleted session(s) older than 24h"
        case '[0-9]*'
            set -l name (echo "$sessions[$choice]" | awk '{print $1}')
            zellij attach "$name"
    end
end

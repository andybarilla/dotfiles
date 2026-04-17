# --- Harlequin database selector ---
# Requires ~/SynologyDrive/PostInstall/harlequin-connections.bash
# (bash counterpart of the .zsh file — uses bash associative-array syntax:
#   declare -A HQ_DEV_PASSWORDS=([agent]=changeme [benchmark]=changeme ...))
[ -f ~/SynologyDrive/PostInstall/harlequin-connections.bash ] && . ~/SynologyDrive/PostInstall/harlequin-connections.bash

hq() {
    if [ ${#HQ_DATABASES[@]} -eq 0 ]; then
        echo "harlequin-connections.bash not found — check SynologyDrive" >&2
        return 1
    fi

    local env
    if [[ "$1" == "dev" ]]; then
        env=dev
        shift
    fi

    local db
    if [[ -n "$1" ]]; then
        db="$1"
    else
        db=$(printf '%s\n' "${HQ_DATABASES[@]}" | fzf --prompt="${env:-local} database> ")
    fi

    [[ -z "$db" ]] && return 0

    local conn
    if [[ "$env" == "dev" ]]; then
        local host="${HQ_DEV_HOST_PATTERN//\{db\}/$db}"
        local user="${HQ_DEV_USER_PATTERN//\{db\}/$db}"
        local pass="${HQ_DEV_PASSWORDS[$db]:-changeme}"
        conn="postgres://${user}:${pass}@${host}:${HQ_DEV_PORT}/${db}"
    else
        conn="postgres://${HQ_LOCAL_USER}:${HQ_LOCAL_PASSWORD}@${HQ_LOCAL_HOST}:${HQ_LOCAL_PORT}/${db}"
    fi

    harlequin -a postgres "$conn"
}

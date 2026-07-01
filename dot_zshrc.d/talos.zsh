export GOOGLE_CLOUD_PROJECT=talostitle-development
export GOOGLE_CLOUD_LOCATION=us-central1
export GOOGLE_GENAI_USE_VERTEXAI=true 

# alias docker-up="distrobox-host-exec bash -c 'cd /var/home/andy/home/talos/titlevision-ai/devex && DOCKER_HOST=unix:///run/user/1000/podman/podman.sock docker-compose up -d'"

gcpproxy() {
    export GOPROXY=https://us-central1-go.pkg.dev/admin-6c4c/titlevision-go,https://proxy.golang.org,direct
    export GONOSUMDB=titlevision.ai/*
    export GONOPROXY=github.com/GoogleCloudPlatform/artifact-registry-go-tools
}

# >>> operator-agent-onramp >>>
# managed block - regenerate via auth/onramp.sh; do not edit between the markers.
# Active-identity prompt machinery (cross-shell, installed once).
_onramp_role=""
_onramp_color=""   # red (break-glass) | cyan (scoped dev/infra) | yellow (agent)
_onramp_tier=""    # "" (development, default) | "@staging" — the tier overlay (use-staging)

if [ -n "${ZSH_VERSION:-}" ]; then
  : "${_ONRAMP_BASE_PROMPT:=$PROMPT}"
  _onramp_apply_prompt() {
    if [ -z "$_onramp_role" ]; then PROMPT="$_ONRAMP_BASE_PROMPT"; return; fi
    PROMPT="%F{$_onramp_color}[gcp:$_onramp_role$_onramp_tier]%f $_ONRAMP_BASE_PROMPT"
  }
else
  : "${_ONRAMP_BASE_PROMPT:=$PS1}"
  _onramp_apply_prompt() {
    if [ -z "$_onramp_role" ]; then PS1="$_ONRAMP_BASE_PROMPT"; return; fi
    local c=36; [ "$_onramp_color" = red ] && c=31; [ "$_onramp_color" = yellow ] && c=33
    PS1="\[\e[${c}m\][gcp:$_onramp_role$_onramp_tier]\[\e[0m\] $_ONRAMP_BASE_PROMPT"
  }
fi

# Drop the active identity (back to no-identity prompt, unset the ADC env).
use-none() {
  unset CLOUDSDK_CONFIG GOOGLE_APPLICATION_CREDENTIALS KUBECONFIG CLOUDSDK_CORE_PROJECT GCP_IDENTITY
  unset AGENT_WIF_OP_REF AGENT_WIF_PASSWORD AGENT_WIF_USER AGENT_WIF_ENV GOOGLE_EXTERNAL_ACCOUNT_ALLOW_EXECUTABLES
  _onramp_role=""; _onramp_color=""; _onramp_tier=""; _onramp_apply_prompt
  echo "gcp identity: (none)"
}

# Run the daily readiness check from anywhere (no need to cd into the repo). The path
# is baked at onramp time; re-run auth/onramp.sh if you move this clone. Args pass
# through, e.g. `morning-check --role infra` or `morning-check --no-db`.
morning-check() { bash "/Users/andy/Development/titlevision-ai/operator-agent-onramp/auth/morning-check.sh" "$@"; }
use-dev() {
  export CLOUDSDK_CONFIG="$HOME/.config/gcloud-dev"
  export GOOGLE_APPLICATION_CREDENTIALS="$CLOUDSDK_CONFIG/application_default_credentials.json"   # !! F10
  # Per-role kubeconfig so kubectl follows the identity switch. Without it, kubectl
  # uses the shared ~/.kube/config + gke-gcloud-auth-plugin cache (keyed by cluster,
  # NOT CLOUDSDK_CONFIG) and silently acts as whichever identity last authenticated -
  # defeating the blast-radius control (dogfood #11). onramp.sh get-credentials into this.
  export KUBECONFIG="$CLOUDSDK_CONFIG/kube.config"
  export CLOUDSDK_CORE_PROJECT="talostitle-development"
  export GCP_IDENTITY="dev:andy-dev@titlevision.ai"
  # Picking a role defaults to the development tier; clear any staging overlay.
  _onramp_role="dev"; _onramp_color="cyan"; _onramp_tier=""; _onramp_apply_prompt
  echo "gcp identity: dev (andy-dev@titlevision.ai)  project=talostitle-development"
}
# Refresh ADC for dev - the periodic Google reauth that expires (typically
# overnight). Targets dev's OWN config dir, so it works from any active identity,
# and strips GOOGLE_APPLICATION_CREDENTIALS so `gcloud auth application-default login`
# doesn't dead-end on a "continue? (Y/n)" prompt: the switcher exports GAC for the
# proxy/TF (!! F10), but the login command trips on it. dogfood finding.
# F-U19: `gcloud auth application-default login` takes NO account arg, so it rides the
# browser's DEFAULT Google account and can write the WRONG identity into this role's dir
# silently (a privilege footgun for dual-role operators). login_hint was proven
# ineffective under Workspace SSO (F-U19: 8 live attempts all rode the default account),
# so instead we ASSERT the identity that actually landed and FAIL LOUDLY on a mismatch
# (same tokeninfo resolution as morning-check).
reauth-dev() {
  local cfg="$HOME/.config/gcloud-dev" want="andy-dev@titlevision.ai" tok who body
  printf 'reauth dev: in the browser, sign in as %s (NOT another Google account).\n' "$want"
  env -u GOOGLE_APPLICATION_CREDENTIALS CLOUDSDK_CONFIG="$cfg" gcloud auth application-default login || return 1
  tok="$(CLOUDSDK_CONFIG="$cfg" gcloud auth application-default print-access-token 2>/dev/null)"
  if [ -z "$tok" ]; then
    printf 'reauth-dev: logged in but no token mints - re-run and pick %s.\n' "$want" >&2
    return 1
  fi
  if command -v curl >/dev/null 2>&1; then
    body="$(curl -s "https://oauth2.googleapis.com/tokeninfo?access_token=$tok")"
    if command -v jq >/dev/null 2>&1; then who="$(printf '%s' "$body" | jq -r '.email // empty')"
    elif command -v python3 >/dev/null 2>&1; then who="$(printf '%s' "$body" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("email",""))' 2>/dev/null)"; fi
  fi
  if [ -z "$who" ]; then
    printf 'reauth-dev: signed in, but could not verify identity (need curl + jq/python3). Confirm with: morning-check --role dev\n' >&2
    return 0
  fi
  if [ "$who" != "$want" ]; then
    printf 'reauth-dev: WRONG IDENTITY - %s now holds %s, expected %s.\n  Re-run reauth-dev and sign in as %s (sign out of other Google accounts or use the chooser first).\n' "$cfg" "$who" "$want" "$want" >&2
    return 1
  fi
  printf 'reauth-dev: OK - ADC identity = %s\n' "$who"
}
use-infra() {
  export CLOUDSDK_CONFIG="$HOME/.config/gcloud-infra"
  export GOOGLE_APPLICATION_CREDENTIALS="$CLOUDSDK_CONFIG/application_default_credentials.json"   # !! F10
  # Per-role kubeconfig so kubectl follows the identity switch. Without it, kubectl
  # uses the shared ~/.kube/config + gke-gcloud-auth-plugin cache (keyed by cluster,
  # NOT CLOUDSDK_CONFIG) and silently acts as whichever identity last authenticated -
  # defeating the blast-radius control (dogfood #11). onramp.sh get-credentials into this.
  export KUBECONFIG="$CLOUDSDK_CONFIG/kube.config"
  export CLOUDSDK_CORE_PROJECT="talostitle-development"
  export GCP_IDENTITY="infra:andy-infra@titlevision.ai"
  # Picking a role defaults to the development tier; clear any staging overlay.
  _onramp_role="infra"; _onramp_color="cyan"; _onramp_tier=""; _onramp_apply_prompt
  echo "gcp identity: infra (andy-infra@titlevision.ai)  project=talostitle-development"
}
# Refresh ADC for infra - the periodic Google reauth that expires (typically
# overnight). Targets infra's OWN config dir, so it works from any active identity,
# and strips GOOGLE_APPLICATION_CREDENTIALS so `gcloud auth application-default login`
# doesn't dead-end on a "continue? (Y/n)" prompt: the switcher exports GAC for the
# proxy/TF (!! F10), but the login command trips on it. dogfood finding.
# F-U19: `gcloud auth application-default login` takes NO account arg, so it rides the
# browser's DEFAULT Google account and can write the WRONG identity into this role's dir
# silently (a privilege footgun for dual-role operators). login_hint was proven
# ineffective under Workspace SSO (F-U19: 8 live attempts all rode the default account),
# so instead we ASSERT the identity that actually landed and FAIL LOUDLY on a mismatch
# (same tokeninfo resolution as morning-check).
reauth-infra() {
  local cfg="$HOME/.config/gcloud-infra" want="andy-infra@titlevision.ai" tok who body
  printf 'reauth infra: in the browser, sign in as %s (NOT another Google account).\n' "$want"
  env -u GOOGLE_APPLICATION_CREDENTIALS CLOUDSDK_CONFIG="$cfg" gcloud auth application-default login || return 1
  tok="$(CLOUDSDK_CONFIG="$cfg" gcloud auth application-default print-access-token 2>/dev/null)"
  if [ -z "$tok" ]; then
    printf 'reauth-infra: logged in but no token mints - re-run and pick %s.\n' "$want" >&2
    return 1
  fi
  if command -v curl >/dev/null 2>&1; then
    body="$(curl -s "https://oauth2.googleapis.com/tokeninfo?access_token=$tok")"
    if command -v jq >/dev/null 2>&1; then who="$(printf '%s' "$body" | jq -r '.email // empty')"
    elif command -v python3 >/dev/null 2>&1; then who="$(printf '%s' "$body" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("email",""))' 2>/dev/null)"; fi
  fi
  if [ -z "$who" ]; then
    printf 'reauth-infra: signed in, but could not verify identity (need curl + jq/python3). Confirm with: morning-check --role infra\n' >&2
    return 0
  fi
  if [ "$who" != "$want" ]; then
    printf 'reauth-infra: WRONG IDENTITY - %s now holds %s, expected %s.\n  Re-run reauth-infra and sign in as %s (sign out of other Google accounts or use the chooser first).\n' "$cfg" "$who" "$want" "$want" >&2
    return 1
  fi
  printf 'reauth-infra: OK - ADC identity = %s\n' "$who"
}
# Tier overlay (use-staging / use-development) — the SECOND axis, orthogonal to the role
# switchers above. Pick your identity/blast-radius with use-dev/use-infra, then point THAT
# identity at a tier. The same Workspace account is scoped to both tiers (gcp-dev-*@ AND
# gcp-staging-*@), so this re-targets the project/cluster, NOT the identity. Both re-export
# CLOUDSDK_CONFIG + GOOGLE_APPLICATION_CREDENTIALS (‼ F10) so the proxy/TF/ADC follow the
# switch, and a per-tier KUBECONFIG so kubectl points at the right cluster (dogfood #11).
# Prompt: [gcp:infra@staging] (cyan) vs [gcp:infra] for dev.
use-staging() {
  local role="${_onramp_role:-dev}"
  export CLOUDSDK_CONFIG="$HOME/.config/gcloud-$role"
  export GOOGLE_APPLICATION_CREDENTIALS="$CLOUDSDK_CONFIG/application_default_credentials.json"   # !! F10
  export KUBECONFIG="$CLOUDSDK_CONFIG/kube-staging.config"
  export CLOUDSDK_CORE_PROJECT="talostitle-staging"
  _onramp_role="$role"; _onramp_color="${_onramp_color:-cyan}"; _onramp_tier="@staging"; _onramp_apply_prompt
  echo "gcp: $role @ staging  project=talostitle-staging  (same Workspace account; scoped via gcp-staging-*@)"
}
# Flip the current role back to the development tier (the role switchers' default tier).
use-development() {
  local role="${_onramp_role:-dev}"
  export CLOUDSDK_CONFIG="$HOME/.config/gcloud-$role"
  export GOOGLE_APPLICATION_CREDENTIALS="$CLOUDSDK_CONFIG/application_default_credentials.json"   # !! F10
  export KUBECONFIG="$CLOUDSDK_CONFIG/kube.config"
  export CLOUDSDK_CORE_PROJECT="talostitle-development"
  _onramp_role="$role"; _onramp_color="${_onramp_color:-cyan}"; _onramp_tier=""; _onramp_apply_prompt
  echo "gcp: $role @ development  project=talostitle-development"
}
# Agent (federated SA via Keycloak ROPC -> WIF). The cred-config was generated by the
# CANONICAL keycloak agent-wif-setup-adc.sh (F9). GOOGLE_APPLICATION_CREDENTIALS points
# at it; GOOGLE_EXTERNAL_ACCOUNT_ALLOW_EXECUTABLES=1 is Google's opt-in gate.
use-agent() {
  export AGENT_WIF_OP_REF="op://Private/agent-t-1/password"
  export AGENT_WIF_USER="agent-t-1"
  export AGENT_WIF_ENV="development"
  export GOOGLE_EXTERNAL_ACCOUNT_ALLOW_EXECUTABLES=1
  export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/agent-wif/development-agent-t-1-adc.json"
  unset CLOUDSDK_CONFIG CLOUDSDK_CORE_PROJECT KUBECONFIG
  export GCP_IDENTITY="agent:agent-t-1"
  _onramp_role="agent"; _onramp_color="yellow"; _onramp_tier=""; _onramp_apply_prompt
  # The agent identity lives in ADC (GOOGLE_APPLICATION_CREDENTIALS), so verify via ADC -
  # `gcloud auth print-access-token` would read the human default account, not the SA (dogfood #16).
  echo "gcp identity: agent (agent-t-1 -> WIF SA)  - verify: gcloud auth application-default print-access-token | ..."
}
use-dev
# <<< operator-agent-onramp <<<



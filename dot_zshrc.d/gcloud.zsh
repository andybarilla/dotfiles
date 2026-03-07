# --- Google Cloud SDK ---
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi

gcptv() {
    gcloud auth revoke
    gcloud config configurations activate titlevision
    gcloud auth login
    gcloud auth application-default login --impersonate-service-account local-development@admin-6c4c.iam.gserviceaccount.com
    gcloud container clusters get-credentials nonprod-autopilot --region us-central1 --project development-37c5
    gcloud container clusters get-credentials prod-autopilot --region us-central1 --project production-7860
    env GOPROXY=proxy.golang.org go run github.com/googlecloudplatform/artifact-registry-go-tools/cmd/auth@latest refresh
}

gcptvdeploy() {
    gcloud auth revoke
    gcloud config configurations activate tvtf
    gcloud auth login
    gcloud auth application-default login
    gcloud container clusters get-credentials nonprod-autopilot --region us-central1 --project development-37c5
    gcloud container clusters get-credentials prod-autopilot --region us-central1 --project production-7860
    env GOPROXY=proxy.golang.org go run github.com/googlecloudplatform/artifact-registry-go-tools/cmd/auth@latest refresh
}

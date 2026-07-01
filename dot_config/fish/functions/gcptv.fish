function gcptv
    gcloud auth revoke
    gcloud config configurations activate titlevision
    gcloud auth login
    gcloud auth application-default login 
    # gcloud container clusters get-credentials nonprod-autopilot --region us-central1 --project development-37c5
    # gcloud container clusters get-credentials prod-autopilot --region us-central1 --project production-7860
    env GOPROXY=proxy.golang.org go run github.com/GoogleCloudPlatform/artifact-registry-go-tools/cmd/auth@latest refresh
end

export GOOGLE_CLOUD_PROJECT=development-37c5
export GOOGLE_CLOUD_LOCATION=us-central1
export GOOGLE_GENAI_USE_VERTEXAI=true 

# alias docker-up="distrobox-host-exec bash -c 'cd /var/home/andy/home/talos/titlevision-ai/devex && DOCKER_HOST=unix:///run/user/1000/podman/podman.sock docker-compose up -d'"

gcpproxy() {
    export GOPROXY=https://us-central1-go.pkg.dev/admin-6c4c/titlevision-go,https://proxy.golang.org,direct
    export GONOSUMDB=titlevision.ai/*
    export GONOPROXY=github.com/GoogleCloudPlatform/artifact-registry-go-tools
}

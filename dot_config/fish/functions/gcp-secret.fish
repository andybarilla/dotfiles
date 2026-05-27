function gcp-secret
    gcloud secrets versions access latest --secret="$argv[1]-database" --project admin-6c4c | jq .POSTGRES_PASSWORD -r | tr -d '\n' | wl-copy
end

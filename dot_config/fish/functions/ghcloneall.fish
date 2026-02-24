function ghcloneall
    gh repo list $argv[1] --limit 4000 | while read -l repo _rest
        gh repo clone "$repo" "$repo"
    end
end

---
name: update-repos
description: Use when the user wants to pull latest changes across multiple git repositories in subdirectories. Triggers on "update repos", "pull all repos", "sync repos", "get latest for all projects", "update all projects".
---

# Update Repos

## Overview

Walk subdirectories of the current folder, find git repos on their main branch, and pull the latest changes.

**Core principle:** Only touch repos that are on main/master and have a clean working tree. Report everything, break nothing.

## The Process

For each immediate subdirectory of the current working directory:

1. Check if it's a git repo (has `.git`)
2. Check which branch it's on
3. If on `main` or `master` with a clean working tree, run `git pull`
4. Report results

```bash
for dir in */; do
  [ -d "$dir/.git" ] || continue
  branch=$(git -C "$dir" branch --show-current 2>/dev/null)
  if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
    if [ -z "$(git -C "$dir" status --porcelain)" ]; then
      echo ">>> $dir ($branch): pulling..."
      git -C "$dir" pull --ff-only
    else
      echo ">>> $dir ($branch): SKIPPED — dirty working tree"
    fi
  else
    echo ">>> $dir ($branch): SKIPPED — not on main/master"
  fi
done
```

## Key Behaviors

- **Use `--ff-only`** — never create merge commits automatically
- **Skip dirty repos** — don't risk losing uncommitted work
- **Skip non-main branches** — user may have intentional feature work in progress
- **Report all repos** — show what was pulled, skipped, and why

## Common Mistakes

- Running `git pull` without `--ff-only` — can create unwanted merge commits
- Pulling on repos with uncommitted changes — risks conflicts with local work
- Silently skipping repos — always report what was skipped and why

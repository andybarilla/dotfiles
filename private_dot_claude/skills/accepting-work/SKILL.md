---
name: accepting-work
description: Use when the user accepts completed work and wants it merged, committed, and cleaned up. Triggers on phrases like "looks good", "ship it", "merge it", "accepted", or "ready for next task".
---

# Accepting Work

## Overview

Handle the post-acceptance workflow: commit any loose files, merge via PR or locally, clean up worktrees/branches, and leave the repo ready for the next task.

**Core principle:** The user said "looks good" — wrap it up with minimal interruption.

## The Process

```dot
digraph accept {
  rankdir=TB;
  "Detect git state" -> "Dirty working tree?";
  "Dirty working tree?" -> "Stage all, show summary, ask once" [label="yes"];
  "Dirty working tree?" -> "Determine context" [label="no"];
  "Stage all, show summary, ask once" -> "User confirms?" ;
  "User confirms?" -> "Commit + push" [label="yes"];
  "User confirms?" -> "Ask what to exclude" [label="no"];
  "Ask what to exclude" -> "Commit + push";
  "Commit + push" -> "Determine context";
  "Determine context" -> "On feature branch?" ;
  "On feature branch?" -> "Open PR exists?" [label="yes"];
  "On feature branch?" -> "Done" [label="no (on main)"];
  "Open PR exists?" -> "Merge PR via gh" [label="yes"];
  "Open PR exists?" -> "Merge locally" [label="no"];
  "Merge PR via gh" -> "Pull base + delete local branch";
  "Merge locally" -> "Delete branch";
  "Pull base + delete local branch" -> "In worktree?";
  "Delete branch" -> "In worktree?";
  "In worktree?" -> "Exit worktree + remove it" [label="yes"];
  "In worktree?" -> "Done" [label="no"];
  "Exit worktree + remove it" -> "Done";
}
```

### Step 1: Handle Dirty Working Tree

Check for uncommitted or untracked files:

```bash
git status --short
```

**If clean:** Skip to Step 2.

**If dirty:**
1. Stage everything: `git add -A`
2. Show the user a summary of what's staged: `git diff --cached --stat`
3. Ask once: "These files will be committed — OK?"

If the user says no, ask what to exclude, unstage those, then commit the rest.

Commit message: Write a concise message describing what the uncommitted changes are (e.g., "Add auth utility and test coverage for login flow"). Don't use generic messages like "final changes" or "cleanup".

After committing, push the branch: `git push`

### Step 2: Determine Context

Detect which situation we're in:

```bash
# What branch are we on?
current=$(git branch --show-current)

# Are we in a worktree?
is_worktree=$(git rev-parse --git-common-dir 2>/dev/null)
main_gitdir=$(git rev-parse --git-dir 2>/dev/null)
# If git-common-dir != git-dir, we're in a worktree

# What's the base branch?
base=$(git show-ref --verify refs/heads/main >/dev/null 2>&1 && echo main || echo master)

# Is there an open PR for this branch?
pr_number=$(gh pr list --head "$current" --state open --json number --jq '.[0].number' 2>/dev/null)
```

### Step 3: Merge

**If an open PR exists (`pr_number` is set):** Merge via GitHub.

```bash
# Squash merge the PR
gh pr merge "$pr_number" --squash --delete-branch

# Switch to base branch locally and pull
git checkout "$base"
git pull
```

The `--delete-branch` flag deletes the remote branch. The local branch may still exist — clean it up in Step 4.

**If no PR exists:** Merge locally.

```bash
# Get the repo root (for worktree case, this is the main worktree)
repo_root=$(git worktree list | head -1 | awk '{print $1}')

# Switch to base branch in main worktree
cd "$repo_root"
git checkout "$base"
git merge "$current"
```

**If merge conflict:** Stop and tell the user. Don't force it.

### Step 4: Clean Up Branch

After successful merge:

```bash
# Delete local branch (may already be gone if PR --delete-branch handled it)
git branch -d "$current" 2>/dev/null

# Clean up any local branches whose remote tracking branch is gone
git fetch --prune
```

### Step 5: Clean Up Worktree (if applicable)

If we were in a worktree:

```bash
# We already cd'd to repo_root in Step 3
git worktree remove "$worktree_path"
```

Report: "Merged `<branch>` → `<base>`, removed worktree. Ready for next task."

### Step 6: Report

Keep it brief:

- **Was on main:** "Committed. Ready for next task."
- **Feature branch (via PR):** "Merged PR #N (`<branch>` → `<base>`). Ready for next task."
- **Feature branch (local):** "Merged `<branch>` → `<base>`. Ready for next task."
- **Worktree:** "Merged `<branch>` → `<base>`, cleaned up worktree. Ready for next task."

## Common Mistakes

**Merging locally when a PR is open**
Always check for an open PR first. Merging locally leaves the PR dangling and skips CI checks, review comments, and PR history.

**Running tests again**
The user already accepted the work. Don't re-run the test suite unless something went wrong during merge.

**Asking too many questions**
The user said "looks good." The only question is the dirty-file confirmation. Don't re-present merge/PR/discard options — they said merge.

**Forgetting to cd back**
After worktree removal, make sure you're in the main repo root, not a deleted directory.

**Force-deleting branches**
Use `git branch -d` (not `-D`). If it fails, the branch wasn't fully merged — something went wrong. Stop and investigate.

## Red Flags

- Merge conflict → Stop, report, let user decide
- `git branch -d` fails → Branch not fully merged, investigate
- Worktree has changes in other branches → Don't touch them
- User says "no" to staged files → Ask what to exclude, don't abort entirely
- PR merge fails (CI red, review required) → Report the failure, don't force merge

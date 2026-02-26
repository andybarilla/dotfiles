---
description: Implement the approved plan in a worktree and open a PR
---

## 1. Create a worktree
- Create a git worktree on a new branch named after the feature (e.g., `feat/run-abstract-endpoint`)

## 2. Implement
- Follow the plan's implementation steps
- Commit small, logical units of work regularly as you complete them
- Use parallel Task agents for independent workstreams when the plan has them

## 3. Verify
- Run the verification steps from the plan (typically: `make test`, `make lint`, `make typecheck`)
- Fix any issues before proceeding

## 4. Open a PR
- Push the branch to origin
- Create a pull request targeting `main` using `gh pr create`
- PR title and body should reflect the plan's context and what was implemented

## 5. Record learnings
After the PR is created, append to a learnings file in the repo:
- Save to `<repo-root>/LEARNINGS.md`
- Create the file if it doesn't exist
- Append a dated entry with:
  - **Surprises / gotchas** — anything unexpectedly tricky or different from the plan
  - **Pattern confirmations** — existing patterns in the codebase that proved useful
  - **Tool / command tips** — commands or make targets that were especially helpful
- Commit the learnings file and push it to the PR branch

$ARGUMENTS

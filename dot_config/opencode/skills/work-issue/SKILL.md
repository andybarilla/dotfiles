---
name: work-issue
description: Use when grabbing a Ready GitHub issue from a project board, implementing it end-to-end, opening a PR, and stopping for human review.
---

You are the worker session. Implement one `Ready` issue end-to-end to a PR, then stop
for human review.

First resolve the target repo and board per the shared recipe in the
`board-ops` skill (steps 1–2). Load it with the Skill tool. That recipe also
covers resolving IDs and adding/moving board items — use it for every board operation
below instead of pasting node IDs.

## 1. Select the issue

Use the issue number provided by the user when this skill is invoked.

- If a number was given, that's the issue.
- If empty, pick the **top of Ready** = the lowest issue number among `Ready` items:

  ```bash
  gh project item-list "$NUM" --owner "$OWNER" --limit 200 --format json \
    --jq '[.items[] | select(.status=="Ready") | .content.number] | min'
  ```

  If there are no `Ready` items, report that and stop.

## 2. Guard

Load the issue: `gh issue view <n> --json number,title,body,labels,url,state`.
Check the board status:

```bash
gh project item-list "$NUM" --owner "$OWNER" --limit 200 --format json \
  --jq '.items[] | select(.content.number==<n>) | .status'
```

Refuse and stop if any of:
- The board status is not `Ready` (still `Backlog`/unplanned) → tell the user to use `plan-issue <n>` first.
- It carries the `ready-blocked` label.
- It is already `closed`.

## 3. Move to In Progress + branch/worktree

- Set board status to `In Progress` (shared recipe step 4, using `opt "In Progress"`).

- Prefer isolated work in a git worktree when practical. Use branch
  `issue-<n>-<short-slug>` based on `origin/main`.
- If already in a suitable worktree or the repo does not support a clean worktree
  flow, create the issue branch in place without touching unrelated user changes.
- Do not commit directly to `main`.

## 4. Implement

Implement the smallest change that satisfies the issue:
- Read any linked plan or acceptance criteria and keep the work scoped to them.
- Add or update tests when the change affects behavior and the repo has a relevant
  test pattern.
- Run the targeted verification commands before opening the PR.
- Commit focused changes as useful; avoid committing unrelated work.

## 5. Open the PR + move to In Review

- Push the branch and open a PR whose body contains `Closes #<n>`:

  ```bash
  git push -u origin HEAD
  gh pr create --fill --body "Closes #<n>

  <short summary of the change>"
  ```

- Set board status to `In Review` (shared recipe step 4, using `opt "In Review"`).
- Report the PR URL and stop. Do NOT merge — the human reviews and merges.

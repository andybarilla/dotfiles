---
name: groom-followup
description: Use when interactively planning project-board issues labeled groom-followup and moving completed plans to Ready.
---

You are finishing the grooming handoff. The `groom-backlog` skill flagged some issues
with the `groom-followup` label because they need a human decision before they can be
planned. Walk those issues ONE AT A TIME, get the human's answers to the open questions,
finish the plan, and move each to `Ready`. Scope is strictly the flagged set — do not
re-triage the whole Backlog.

First resolve the target repo and board per the shared recipe in the
`board-ops` skill (steps 1–2). Load it with the Skill tool. That recipe also
covers resolving IDs and adding/moving board items — use it for every board operation
below instead of pasting node IDs.

## 1. Select scope

Use the issue numbers provided by the user when this skill is invoked.

- If issue numbers were given, use exactly those.
- If empty, every open issue carrying the label:

  ```bash
  gh issue list --repo "$REPO" --label groom-followup --state open \
    --json number,title --jq 'sort_by(.number) | .[] | "\(.number)\t\(.title)"'
  ```

  If the set is empty, report "Nothing awaiting follow-up." and stop.

## 2. Show the queue first

Before planning anything, print the flagged issues: number, title, and a one-line
"blocking on…" drawn from each issue's Groomer-notes comment (`gh issue view <n>
--comments`). This shows the human the whole queue up front.

## 3. Walk each issue interactively (number order)

For each in-scope issue:

1. Load it and its Groomer-notes comment:
   `gh issue view <n> --repo "$REPO" --comments`. Re-investigate the codebase
   (Grep/Glob/Read) if the comment's file list isn't enough.
2. Surface the open questions the groomer recorded and ASK the human for the decisions.
   Offer two escape hatches:
   - **skip** — leave the `groom-followup` label, take no action, move to the next issue.
   - **defer** — same as skip but note it explicitly in the final report.
   Do not write anything until the human answers.
3. With the answers, run the `plan-issue` procedure:
   - Write the approach paragraph + acceptance-criteria checklist into the body
     (`gh issue edit <n> --body "<body>"`). If the answers reveal real design scope,
      write the full spec + plan sections into the body and label it `full-spec` instead.
    - Add labels: tier (`small` or `full-spec`) + a type (`bug`|`enhancement`):
     `gh issue edit <n> --add-label <tier> --add-label <type>`
   - Add the issue to the board if needed and move it to `Ready` (shared recipe step 4,
     using `opt Ready`).
4. Remove the follow-up label — the human input is done, so it's now an ordinary planned
   issue: `gh issue edit <n> --remove-label groom-followup`. Do NOT add `groomed`
   (`groomed` is reserved for bot-only, unreviewed plans).

## 4. Report

Print a table: issue number, title, outcome (`planned → Ready` / `skipped` / `deferred`).
End with a one-line summary (e.g. "2 planned, 1 skipped").

---
name: plan-feature
description: Use when turning a new feature idea into a Ready, worker-actionable GitHub issue on a project board.
---

You are planning a new feature into an actionable, `Ready` GitHub issue on a project
board. Unlike `plan-issue` (which grooms an existing ticket), this skill **creates** the
issue from a fresh idea — there is no issue number yet.

First resolve the target repo and board per the shared recipe in the
`board-ops` skill (steps 1–2). Load it with the Skill tool. That recipe also
covers how repos and boards relate, resolving IDs, and adding/moving board items —
use it for every board operation below instead of pasting node IDs.

## 1. Capture the idea

Use the feature description provided by the user when this skill is invoked. If none
was given, ask the user what the feature is and do nothing else until they answer.

## 2. Investigate

Explore the codebase for relevant files, existing patterns, and prior art (use
Grep/Glob/Read). Check `docs/superpowers/specs/` and `plans/` for anything related.
Form a concrete understanding of what the change requires.

## 3. Decide tier

The spec/plan lives in the **issue body itself** — do not write separate markdown files.

- **small** — bounded, fits one focused PR, no design ambiguity. → inline plan
  (approach paragraph + acceptance-criteria checklist).
- **full-spec** — multi-file/subsystem, design choices, or >~1 day of work.
  → write the full spec (design, decisions, components) and step-by-step plan as
  sections directly in the issue body. Keep it self-contained so a worker needs
  nothing but the ticket.

## 4. Split out additional issues

If the work uncovers separable units (dependencies, follow-ups, parallel pieces),
propose creating dedicated issues for them. On approval, create each and add it to the
board (shared recipe step 4):

```bash
NEW_URL=$(gh issue create --repo "$REPO" --title "<title>" --body "<body>" --label enhancement | tail -n1)
gh project item-add "$NUM" --owner "$OWNER" --url "$NEW_URL"
```

Reference the new issues from the main feature body (and vice versa) so the split is
traceable. Split-out issues land in `Backlog` for a later `plan-issue` pass unless the
user wants them planned now.

## 5. Propose in-session

Show the user the proposed issue **title** and **body**: the approach +
acceptance-criteria checklist (plus the embedded spec/plan sections if `full-spec`),
and any additional issues to split out. Ask for a yes / edits. Do not create anything
until approved.

## 6. Apply on approval

- Create the issue (the body carries the full spec/plan):

  ```bash
  ISSUE_URL=$(gh issue create --repo "$REPO" --title "<approved title>" --body "<approved body>" | tail -n1)
  ```

- Labels: add the tier (`small` or `full-spec`) and a type (`bug` or `enhancement`):
  `gh issue edit "$ISSUE_URL" --add-label <tier> --add-label enhancement`
- Add the issue to the board and move it to `Ready` (shared recipe step 4, using
  `opt Ready`).

Report: issue number/URL, tier, labels applied, any split-out issues created, and that
it's now `Ready`.

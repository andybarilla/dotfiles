---
name: plan-issue
description: Use when planning a thin GitHub issue into a Ready, worker-actionable issue on a project board.
---

You are planning a GitHub issue into an actionable, `Ready` state on a project board.

First resolve the target repo and board per the shared recipe in the
`board-ops` skill (steps 1–2). Load it with the Skill tool. That recipe also
covers how repos and boards relate, resolving IDs, and adding/moving board items —
use it for every board operation below instead of pasting node IDs.

## 1. Select the issue

Use the issue number provided by the user when this skill is invoked.

- If a number was given, load it from the target repo: `gh issue view <issue-number> --repo "$REPO" --json number,title,body,labels,url`.
- If empty, list Backlog issues and ask the user which to plan (shared recipe step 5,
  filtering to `status == "Backlog"` and the target repo). Print candidates as
  `owner/repo#number` + title and stop for the user to pick one. Load the selected
  issue with `--repo <owner/repo>`; never use a bare project-wide number.

## 2. Investigate

Read the issue. Explore the codebase for relevant files, existing patterns, and
prior art (use Grep/Glob/Read). Check `docs/superpowers/specs/` and `plans/` for
anything related. Form a concrete understanding of what the change requires.

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
propose creating dedicated issues for them. On approval, create each and add it to
the board (shared recipe step 4):

```bash
NEW_URL=$(gh issue create --repo "$REPO" --title "<title>" --body "<body>" --label enhancement | tail -n1)
gh project item-add "$NUM" --owner "$OWNER" --url "$NEW_URL"
```

Reference the new issues from the parent body (and vice versa) so the split is
traceable. New issues land in `Backlog` for a later `plan-issue` pass unless the
user wants them planned now.

## 5. Propose in-session

Show the user the proposed issue body: the approach + acceptance-criteria checklist
(plus the embedded spec/plan sections if `full-spec`), and any additional issues to
split out. Ask for a yes / edits. Do not proceed until approved.

## 6. Apply on approval

- Update the issue body (carries the full spec/plan):
  `gh issue edit <n> --repo "$REPO" --body "<approved body>"`
- Labels: add the tier (`small` or `full-spec`) and a type (`bug` or `enhancement`):
  `gh issue edit <n> --repo "$REPO" --add-label <tier> --add-label enhancement`
- Verify the issue is attached to the target project (`OWNER` + `NUM`), add it
  automatically if missing, and move that target-project item to `Ready` (shared
  recipe step 4, using `opt Ready`).

Report: issue number, tier, labels applied, any split-out issues created, and that
it's now `Ready`.

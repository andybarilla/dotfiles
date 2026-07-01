---
name: groom-backlog
description: Use when grooming a project board's Backlog issues, auto-planning straightforward issues to Ready, and leaving follow-up notes on complex issues.
---

You are grooming a project board's Backlog. Make ONE autonomous sweep: fully plan the
genuinely straightforward issues to `Ready`, leave initial legwork on the complex ones,
skip the rest. Never move anything past `Ready`. Do the whole pass, then report — do not
pause mid-run.

First resolve the target repo and board per the shared recipe in the
`board-ops` skill (steps 1–2). Load it with the Skill tool. That recipe also
covers resolving IDs and adding/moving board items — use it for every board operation
below instead of pasting node IDs.

## 1. Select scope

Use the issue numbers provided by the user when this skill is invoked. Accept
bare numbers only for the resolved target repo; otherwise require
`owner/repo#number`. Derive and preserve `ISSUE_REPO` for every provided issue
before loading, editing, commenting, or checking project attachment.

- If issue numbers were given, groom exactly those.
- Once the target board is known, every considered issue (including skipped ones)
  must be attached to that target project before reporting; auto-add if missing.
  Membership in another project does not count.
- If empty, groom every `Backlog` item (shared recipe step 5):

  ```bash
  gh project item-list "$NUM" --owner "$OWNER" --limit 200 --format json \
    --jq '[.items[] | select(.status=="Backlog" and (.content.url | contains("/issues/"))) | "\(.content.url | sub("^https://github.com/"; "") | sub("/issues/"; "#"))\t\(.content.title)"] | sort[]'
  ```

  Treat each row as `owner/repo#number` + title and load with `--repo <owner/repo>`.

## 2. Ensure the `groomed` and `groom-followup` labels exist

Run once per selected issue repo (creates only if missing):

```bash
gh label list --repo "$ISSUE_REPO" --json name --jq '.[].name' \
  | grep -qx groomed \
  || gh label create groomed --repo "$ISSUE_REPO" \
       --color BFD4F2 --description "Auto-planned to Ready by groom-backlog (not human-reviewed)"
gh label list --repo "$ISSUE_REPO" --json name --jq '.[].name' \
  | grep -qx groom-followup \
  || gh label create groom-followup --repo "$ISSUE_REPO" \
       --color FBCA04 --description "Groomed but needs a human decision before planning (see Groomer notes)"
```

## 3. Triage each issue

For each in-scope issue: preserve its selected `owner/repo` as `ISSUE_REPO`, load it
(`gh issue view <n> --repo "$ISSUE_REPO" --json number,title,body,labels,url`),
and investigate the codebase (Grep/Glob/Read; check `docs/superpowers/specs/` and
`plans/`). Sort into exactly ONE bucket.

### Bucket 1 — Straightforward → auto-plan to Ready

ALL must hold:
- Bounded to one focused PR; plausibly single-file or a few closely-related files.
- Zero design ambiguity; no product/UX decision required.
- Not labeled `full-spec`.
- You are highly confident. **Any doubt → Bucket 2.**

Do the `plan-issue` `small`-tier procedure:
1. Write the approach paragraph + acceptance-criteria checklist into the body:
   `gh issue edit <n> --repo "$ISSUE_REPO" --body "<body>"`. The body carries the whole plan.
2. `gh issue edit <n> --repo "$ISSUE_REPO" --add-label small --add-label <bug|enhancement> --add-label groomed`
3. Verify the issue is attached to the target project (`OWNER` + `NUM`), add it
   automatically if missing, and move that target-project item to `Ready` (shared
   recipe step 4, using `opt Ready`).

### Bucket 2 — Complex / uncertain → legwork, stay in Backlog

Touches architecture, needs a design choice, or demoted from Bucket 1.

1. Once the target board is known, verify the issue is attached to that target
   project (`OWNER` + `NUM`) and add it automatically if missing; membership in
   another project does not count. Leave the target-project item in `Backlog`.
2. Post a COMMENT (not the body) with your legwork:

   ```bash
   gh issue comment <n> --repo "$ISSUE_REPO" --body "🤖 **Groomer notes** (auto-generated, not a final plan)

   **Relevant files:** <paths found>

   **Open questions for a human:**
   - <question>

   **Recommended direction:** <one short paragraph>

   Run the `groom-followup` skill (or `plan-issue <n>`) to finish planning this issue."
   ```

3. Stamp the follow-up label so it's findable later:
   `gh issue edit <n> --repo "$ISSUE_REPO" --add-label groom-followup`. Leave the board item in `Backlog`.
   Do NOT add `small`/`full-spec`/`groomed` — `plan-issue` (or `groom-followup`)
   decides tier later. `groomed` means "auto-planned and in Ready" only.

### Bucket 3 — Out of scope → skip

Labeled `full-spec`, clearly large/multi-subsystem, or a pure product call with no
technical legwork to do. Verify/auto-add target-project attachment, then take no
grooming action; just list it in the report.

## 4. Guardrail

Bias hard toward leaving things alone. A missed auto-plan costs one manual `plan-issue`
later; a weak auto-plan in `Ready` costs a wasted `work-issue` and a bad PR. Unsure
between Bucket 1 and 2 → choose 2.

## 5. Report

Print a table: issue number, title, bucket, action taken
(`planned → Ready` / `legwork comment` / `skipped`). End with a one-line summary
(e.g. "3 planned, 2 legwork, 1 skipped").

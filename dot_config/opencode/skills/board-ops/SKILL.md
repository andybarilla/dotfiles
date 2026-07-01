---
name: board-ops
description: Shared recipe for the GitHub project-board skills (plan-feature, plan-issue, work-issue, groom-backlog, groom-followup). Load when a board skill needs to resolve the target repo/board, resolve project & Status field IDs, or add/move board items at runtime.
---

# Board operations (shared recipe)

Shared runtime resolution for the GitHub project-board skills (`plan-feature`,
`plan-issue`, `work-issue`, `groom-backlog`, `groom-followup`). These skills never
hardcode project/field node IDs — they resolve everything from the current repo and
the chosen board at runtime, so the same skills work on any repo + board.

## The repo ↔ project model (why there are two inputs)

A GitHub **project (board) is owned by a user or org, not by a repo**. Its number is
scoped to that owner (e.g. `andybarilla` #2). One board can hold issues from many
repos; one repo's issues can appear on many boards. An **issue always belongs to one
repo**; adding it to a board creates a *project item* linking the two. So these skills
need two independent things: the **repo** (where issues are created) and the **project**
(`OWNER` + `NUM`, where the board lives).

## 1. Resolve the target repo

Default to the current directory's repo unless the user named another:

```bash
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')   # e.g. andybarilla/exit66jukebox
```

## 2. Resolve the target project (OWNER + NUM)

Discover the boards linked to the repo:

```bash
gh api graphql -f query='{repository(owner:"<owner>",name:"<name>"){projectsV2(first:20){nodes{number title owner{... on User{login} ... on Organization{login}}}}}}' \
  --jq '.data.repository.projectsV2.nodes[] | "\(.number)\t\(.title)\t\(.owner.login)"'
```

- **Exactly one** board → use it.
- **Zero, or more than one** (untitled scratch projects often sit alongside the real
  one) → print number + title and **ask the user which board to use**. Do not guess.

Set `OWNER` and `NUM` from the choice. The user may also pass these explicitly when
invoking a skill, which skips discovery.

## 3. Resolve project + Status field IDs

Never paste `PVT_…` / `PVTSSF_…` node IDs — resolve them from `OWNER`/`NUM`. The board
must use a single-select field named **`Status`** with options
**`Backlog` / `Ready` / `In Progress` / `In Review` / `Done`** (the shared convention):

```bash
PROJECT_ID=$(gh project view "$NUM" --owner "$OWNER" --format json --jq '.id')
FIELD_ID=$(gh project field-list "$NUM" --owner "$OWNER" --format json \
  --jq '.fields[] | select(.name=="Status") | .id')
# option id by name, e.g. opt Ready
opt() { gh project field-list "$NUM" --owner "$OWNER" --format json \
  --jq '.fields[] | select(.name=="Status") | .options[] | select(.name=="'"$1"'") | .id'; }
```

## 4. Add an issue to the board and set its status

Before setting status or reporting success, verify the issue is attached to the
target project (`OWNER` + `NUM`). Membership in another project does not count.
If the issue is missing from the target project, add it automatically, then
resolve its `ITEM_ID` from the target project.

```bash
gh project item-add "$NUM" --owner "$OWNER" --url "$ISSUE_URL"   # skip if already on the board
ITEM_ID=$(gh project item-list "$NUM" --owner "$OWNER" --limit 200 --format json \
  --jq '.items[] | select(.content.url=="'"$ISSUE_URL"'") | .id')
gh project item-edit --id "$ITEM_ID" --project-id "$PROJECT_ID" \
  --field-id "$FIELD_ID" --single-select-option-id "$(opt Ready)"   # or "In Progress" / "In Review" / …
```

`--limit 200` is required everywhere: the default caps at 30 items, and `Done` items
otherwise bury the list.

## 5. List target-repo items by status

```bash
gh project item-list "$NUM" --owner "$OWNER" --limit 200 --format json \
  --jq '[.items[] | select(.status=="Backlog" and (.content.url | startswith("https://github.com/'"$REPO"'/issues/"))) | "\(.content.url | sub("^https://github.com/"; "") | sub("/issues/"; "#"))\t\(.content.title)"] | sort[]'
```

Backlog/Ready selection output must include repo identity (`owner/repo#number` +
title). Load the selected issue with that repo identity (`gh issue view <number>
--repo <owner/repo> ...`), never as a bare project-wide number.

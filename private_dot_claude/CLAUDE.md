# Global CLAUDE.md

## How I Work

- **TDD by default**: Write failing tests first, then implement. This applies across all projects unless the project CLAUDE.md says otherwise.
- **Be concise**: Documentation, comments, commit messages, PR descriptions, and variable names should contain useful information and nothing more. Don't explain obvious things.
- **Don't create documentation files** (README, docs, etc.) unless I explicitly ask for it.
- **Don't add unnecessary abstractions**: No tiny wrapper functions, getters/setters, or premature helpers. Three similar lines is better than a forced abstraction.

## Code Style (Cross-Project)

- **Strict typing**: Always use explicit types for parameters and return values. No untyped code.
- **Imports at the top**: All imports must be at the top of the file, never mid-code.
- **Descriptive names**: `isRegisteredForDiscounts`, not `discount()`. Names should be self-documenting.

## Git Workflow

- **Feature branches**: Never commit directly to `main`. Create a branch before starting work.
- **Worktrees for parallel work**: When spawning parallel agents, each must work in its own git worktree to avoid clobbering. Include worktree setup in every agent prompt.
- **Pre-worktree check**: Before creating a worktree, run `git status` to ensure no uncommitted changes on main. Push any local commits first so the worktree (based on `origin/main`) includes everything.
- **Pre-merge check**: Before squash-merging a PR, `git diff origin/main -- <changed files>` to ensure nothing on main gets silently overwritten.

## Task-Based Development

Several projects use a task-based workflow with `docs/tasks/` and `docs/plans/` directories. When a project has a `docs/ROADMAP.md`, follow its workflow for finding and planning the next task.

## Interaction Preferences

- Lead with the action or answer, not the reasoning.
- Don't summarize what you just did — I can read the diff.
- Ask before making changes to dependencies or creating new top-level directories.

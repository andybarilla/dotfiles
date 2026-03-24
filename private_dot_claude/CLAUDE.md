# Global CLAUDE.md

## Environment

- **mise**: All development tools (node, python, go, etc.) are managed via [mise](https://mise.jdx.dev/). Run `mise install` if a tool is missing. Use `mise exec` or `mise run` instead of assuming tools are globally installed. Don't waste time searching for binaries — if a command isn't found, it's a mise tool.
- **Browser dark mode**: My browser runs in dark mode. When using Playwright/browser tools to display anything, use dark-friendly color schemes (dark backgrounds, light text, appropriate contrast).

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
- **Worktrees for parallel work**: When spawning parallel agents, each must work in its own git worktree to avoid clobbering. Include worktree setup in every agent prompt. Use worktrunk (`wt`) CLI for managing worktrees instead of raw `git worktree` commands.
- **Pre-worktree check**: Before creating a worktree, run `git status` to ensure no uncommitted changes on main. Push any local commits first so the worktree (based on `origin/main`) includes everything.
- **Pre-merge check**: Before squash-merging a PR, `git diff origin/main -- <changed files>` to ensure nothing on main gets silently overwritten.

## Task-Based Development

Several projects use a task-based workflow with `docs/tasks/` and `docs/plans/` directories. When a project has a `docs/ROADMAP.md`, follow its workflow for finding and planning the next task.

## Interaction Preferences

- Lead with the action or answer, not the reasoning.
- Don't summarize what you just did — I can read the diff.
- Ask before making changes to dependencies or creating new top-level directories.
- **Showing markdown for review**: When asking me to review a markdown file, read it with the Read tool and then output the full contents as a markdown code block in your response text so I can see it directly without expanding tool results or opening the file myself.

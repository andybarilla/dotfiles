# Global CLAUDE.md

## Environment

- **mise**: All development tools (node, python, go, etc.) are managed via [mise](https://mise.jdx.dev/). Run `mise install` if a tool is missing. Use `mise exec` or `mise run` instead of assuming tools are globally installed. Don't waste time searching for binaries — if a command isn't found, it's a mise tool.
- **Browser dark mode**: My browser runs in dark mode. When using Playwright/browser tools to display anything, use dark-friendly color schemes (dark backgrounds, light text, appropriate contrast).

## How I Work

- **Be concise**: Documentation, comments, commit messages, PR descriptions, and variable names should contain useful information and nothing more. Don't explain obvious things.
- **Don't create explanatory documentation** (READMEs, guides, design docs, API references — prose written to be read about the code) unless I explicitly ask for it. This does not cover working artifacts that a skill or workflow produces as part of its own process (specs, implementation plans, task files); create those when the workflow calls for them.
- **Don't add unnecessary abstractions**: No tiny wrapper functions, getters/setters, or premature helpers. Three similar lines is better than a forced abstraction.

## Git Workflow

- **Feature branches**: Never commit directly to `main`. Create a branch before starting work.
- **Opening PRs**: When you offer opening a PR as one of the options, assume the answer is yes — just open it.

## Task-Based Development

Several projects use a task-based workflow with `docs/tasks/` and `docs/plans/` directories. When a project has a `docs/ROADMAP.md`, follow its workflow for finding and planning the next task.

## Interaction Preferences

- Lead with the action or answer, not the reasoning.
- Don't summarize what you just did — I can read the diff.
- Ask before making changes to dependencies or creating new top-level directories.
- **Showing markdown for review**: When asking me to review a markdown file, read it with the Read tool and then output the full contents as a markdown code block in your response text so I can see it directly without expanding tool results or opening the file myself.
- **No parallelisms**: Never use the "it's not X, it's Y" structure. Make direct assertions instead. If a claim can't stand on its own as a positive statement, it isn't strong enough to include.

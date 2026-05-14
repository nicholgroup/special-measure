# Prompts workspace

Free-form space for prompt engineering — separate from `.claude/commands/` (which Claude Code executes) and `.claude/agents/` (which Claude Code dispatches). Nothing here is auto-loaded; these are reference material you (and Claude, when pointed at them) read.

## Layout

- `patterns/` — reusable prompt patterns, one per file. Stable, polished. Use `patterns/_template.md` as the starting form.
- `drafts/` — work-in-progress prompts. Anything goes; expect churn.
- `examples/` — concrete worked examples — input + the prompt that handled it + the output you got. Useful for showing what good looks like.

## Promotion flow (suggestion)

`drafts/foo.md` → iterate → once it's earning its keep, polish and move to `patterns/foo.md`. Pair it with a runnable case in `examples/foo-*.md`.

# Archive

This is the pre-migration version of this repo, kept for reference. Not maintained -- don't copy anything from here into a live `~/.claude/` setup.

## What this was

Flat `.md` skill files (`CLAUDE.md` plus `skills/apple.md`, `skills/android.md`, etc.) referenced by hand-written routing lines in `CLAUDE.md` -- "when working on Apple UI, read apple.md before writing any view code." That was the only mechanism available before Anthropic's Agent Skills format existed as a first-class Claude Code feature: a skill was just a file you told Claude to go read, and the model had no way to discover or load it on its own.

## Why it was replaced

Claude Code now discovers and loads skills on its own via `skills/<name>/SKILL.md` directories with a `name` + `description` in the frontmatter. Every skill's metadata sits in context by default at near-zero token cost; the full skill only loads once a task actually matches it. The flat-file approach couldn't do any of that -- everything Rob wanted available had to be either manually routed to in `CLAUDE.md` or loaded in full regardless of relevance.

The full writeup of what changed and why lives in the top-level `README.md`.

## Content status

The design and platform knowledge in these files was accurate as of their last edit (~August 2026) but has not been maintained since the migration -- it's frozen at whatever state it was in when superseded. The current, maintained version of everything here lives under `../skills/`.

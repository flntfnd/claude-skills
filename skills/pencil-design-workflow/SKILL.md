---
name: pencil-design-workflow
description: Use when working in Pencil (pen.dev, formerly pencil.dev), the Git-native, IDE-embedded design tool where .pen files live in the repo and Claude Code reads/writes the canvas via MCP. Covers installation (VS Code/Cursor extension, desktop app) and the separate Claude Code auth dependency; the MCP tool surface (get_app_state, execute, get_guidelines, get_screenshot, export_nodes, export_html, browser); variables and theme columns for light/dark; components, slots, and Design Libraries (.lib.pen); agent-driven and multi-agent workflows including the "use the pencil mcp server" terminal-prompt requirement; Figma-to-Pencil paste; layer naming; the no-empty-frame gate; Git workflow for .pen diffs; the pen CLI; and limitations (early access, hex-only sRGB, auto-save gaps). A mechanics skill, not design-quality — pair with the installed better-* skills for design judgment; this one covers operating Pencil itself. Trigger on Pencil, pen.dev, .pen files, or "use the pencil mcp server."
---

# Pencil Design Workflow

Pencil is a design tool that lives inside your IDE (VS Code, Cursor) or as a standalone desktop app. Design files are `.pen` files, tracked in your Git repo alongside the code they describe. The canvas isn't a separate tool — it's another file in the project.

[Inference] The product's own homepage and docs now read "pen.dev" rather than "pencil.dev," while the docs are still hosted at `docs.pencil.dev`. Treat this as a rebrand in progress, not a different product — the `.pen` file format, MCP mechanics, and CLI (`pen`) are continuous with what shipped as "Pencil."

Key differences from Figma and Paper:
- `.pen` files are tracked in Git, not stored in a cloud account
- The canvas is your IDE (or a lightweight desktop app), not a separate heavyweight tool
- MCP gives Claude Code direct read/write access to the canvas
- Local-first, single-user — no real-time multiplayer (that's Paper's lane)
- AI runs through Claude Code, not Pencil itself — Pencil is free, Claude Code is the actual cost

[Inference] from third-party reviews: multiple agents can work on the same `.pen` file by launching parallel Claude Code sessions scoped to different frames. Docs don't put a firm number on how many concurrent sessions are safe — treat it as "agent parallelism via your shell," not a built-in swarm feature.

## Relationship to the better-* design skills

This machine also has Pencil-vendor-shipped skills at `~/.pencil/skills/` — `better-colors`, `better-ui`, `better-typography`, `better-layout`, `better-accessibility`, `interface-review`, `transitions-dev`, `transitions-polish`, `better-writing`. Those cover **design quality**: OKLCH color choices, type scale, layout judgment, accessibility, motion. This skill covers something different — **Pencil the tool**: installation, `.pen` file conventions, MCP mechanics, Slots, Design Libraries, and Git workflow. A session doing real design work will often need both: reach for a `better-*` skill to decide what the design should look like, and this skill to know how to actually build it in Pencil. They're complementary, not overlapping.

## Hard gates — check every session

1. **No empty frames.** Same rule as Figma, Sketch, and Paper — frames exist when populated. Minimum screen set per platform: Authentication (login, signup, forgot password), Home/main (default + loading + empty + error), Detail view, Settings/profile, Navigation shell.
2. **Light and dark via theme columns.** Add a "dark" column alongside "default"/"light" in the Variables panel. Flip the theme column and bound elements update — this is how light/dark works in Pencil today.
3. **Read before writing.** Call `get_app_state` (schema + canvas state) before any structural change. Agents writing blindly into unknown canvas state produce broken layouts.

## Status (August 2026)

Still early access, still free — the product's own site states "pen.dev is currently free," with a note that paid plans may appear in the future with advance notice. No evidence of a Pencil-side paid tier having launched as of this writing; the real ongoing cost is the Claude Code subscription that drives the AI features. [Inference] third-party trackers cite 100,000+ users since a ~January 2026 public launch — treat the exact figure as approximate.

## Installation

**VS Code / Cursor extension:** Extensions panel → search "Pencil" → Install → create or open a `.pen` file → look for the Pencil icon (top-right of editor, or status bar bottom-left in some builds). If it doesn't appear, Command Palette → "Pencil" to find commands, or restart the IDE.

**Desktop app:** download `.dmg` (macOS), `.deb`/`.AppImage` (Linux), or the Windows installer from pen.dev. macOS may need right-click → Open on first launch. Linux: Wayland/Hyprland has known UI issues — prefer X11.

**Activation:** sign up at pen.dev with email, receive an activation code, enter it in Pencil.

**Claude Code dependency (non-obvious, trips people up):** Pencil's AI features require Claude Code installed and authenticated separately.

```bash
npm install -g @anthropic-ai/claude-code-cli
# or
curl https://claude.ai/cli/install.sh | sh

claude          # follow the browser auth flow
claude --version
```

"Invalid API key" or "Please run /login" inside Pencil traces back to this step. Check for conflicting auth (environment keys, custom providers) if a fresh `claude` login doesn't fix it.

## MCP setup

The Pencil MCP server starts automatically when Pencil is running (extension or desktop) — no manual config. Verify in Cursor via Settings → Tools & MCP; in Claude Code CLI via `claude` then `/mcp`; in Codex, run Pencil first then `/mcp`. If it doesn't appear, restart both Pencil and the host — long-running sessions are the most common failure mode.

See `reference/mcp-tools.md` for the full current tool surface (`get_app_state`, `execute`, `get_guidelines`, `get_screenshot`, `export_nodes`, `export_html`, `browser`), the `execute()` operations language, the legacy tool names it replaced, the `.pen`-encryption discrepancy worth flagging to Rob, and the `pen` CLI reference.

## Create a .pen file

```
New File → name it design.pen
```

**Naming conventions:** `design.pen` for a project's main file; `dashboard.pen`, `landing.pen`, `checkout.pen` per screen/feature; `design-system.lib.pen` for a Design Library (the `.lib.pen` suffix is required for library files). Multiple `.pen` files per repo is correct — one per major section, or one shared library plus per-screen files.

First session: right-click the canvas → Open Welcome File.

## Design style

Before adding elements, pull in the `visual-styles` skill for the project's visual style and the `color-system` skill for the palette, then set up variables first — everything else binds to them.

```
Set up design variables in design.pen:
- primary: #D52B1E
- background: #F5F3EE
- text: #1A1A1A
- spacing-base: 16
- radius-md: 8
```

Pencil colors are hex sRGB only — no native OKLCH or P3, unlike Paper. If `color.md` specifies P3 colors, use the sRGB equivalent and note the gap.

## Variables

Variables work like CSS custom properties: hex for colors, numbers for spacing/radius/sizes, strings for fonts. Change a variable, every binding updates.

**Creating variables** — three paths: manually via the Variables icon in the toolbar; from CSS by asking the agent to read a stylesheet and extract matching variables; from Figma by pasting a screenshot of the variables table and asking the agent to set them up (or copying individual values).

**Theme columns:** add a "dark" column alongside "default"/"light" in the variables panel; switch in the properties panel to preview.

**Token naming** must match the codebase — Swift `Color.Semantic.Background.primary` becomes `--color-semantic-background-primary` in Pencil. Pull in the `apple-platform`, `android-platform`, or `web-platform` skill first for existing token architecture.

**Sync with code** (two-way, run periodically to prevent drift):

```
Read src/styles/tokens.css and sync all custom properties as Pencil variables.
```
```
Export current Pencil variables as a CSS custom properties file at src/styles/tokens.css.
```

## Components

A real component system, not just symbols. Select any element → **Cmd/Ctrl + Option/Alt + K** (or "Create component" in the properties panel) → the element becomes a component origin, marked with a **magenta bounding box** when selected. Nested components work — build atoms first, then compose.

Copy the origin on the canvas to create an instance, marked with a **violet bounding box**. Instances show a "Go to component" button that jumps back to the origin.

## Slots

Slots are designated drop zones inside components. Only empty frames in component origins can become slots (marked with diagonal lines on the canvas).

**Create:** turn a frame into a component (Cmd/Ctrl+Option/Alt+K) → style it → "Make a slot" in the properties panel.

**Suggested slot components:** tell Pencil what belongs in a slot — e.g. a `table` component's slot suggests `table-row`. Select the slot layer in the component origin → `+` on the "Slots" line → pick the components to suggest. This is how you tell the agent "when populating this `table`, use `table-row` instances" without repeating it in every prompt.

**Drop into slots:** create an instance, then drag/drop or paste an element into the slot region.

## Design Libraries

Any `.pen` file can become a reusable component library. Edits to a library component propagate to every consuming file.

**Create:** new `.pen` file → populate with components → Layers panel → Libraries icon → "Turn this file into a library." The file gets renamed with a `.lib.pen` suffix. **This cannot be undone** — be intentional.

**Import:** Layers panel → Libraries icon → pick a library. Built-in libraries (Shadcn UI, Halo, Lunaris, Nitro) are also listed here.

**Use assets:** Layers panel → Assets icon → search or scroll → drag/drop or click to place.

For custom design systems: build in `design-system.lib.pen`, import into per-screen files.

## Workflow: agent-driven design

**Single agent**, from a terminal with Pencil open:

```bash
claude 'Design a pricing section in design.pen with three tiers.
Use the Lunaris design library. Apply primary color to the recommended tier.
use the pencil mcp server'
```

Always end terminal prompts with `use the pencil mcp server` — this signals the agent to route through MCP rather than generating static code standalone. This is the single most common trip-up reported for Pencil sessions started from a shell.

**In-canvas prompting:** **Cmd/Ctrl + K** anywhere in Pencil opens the prompt input — faster than alt-tabbing to a terminal for small changes.

**Multiple agents (informal swarm):** launch parallel Claude Code sessions, each scoped to a different frame, writing to the same `.pen` file independently. Useful for "one section per session" landing-page builds.

```bash
# Terminal 1
claude 'In design.pen, build the hero section. use the pencil mcp server'
# Terminal 2
claude 'In design.pen, build the features grid. use the pencil mcp server'
```

[Inference] Some users report 4-5 agents working concurrently without conflict; the hard upper bound isn't documented and depends on your machine and Claude Code rate limits.

## Workflow: design to code

```
Inspect the 'Dashboard Main' frame in design.pen.
Generate a React component using Tailwind CSS.
Match exact padding, margin, font-weight, and border-radius from the design.
The 'Container' layer should be flex-col on mobile and flex-row on desktop.
Replace vector icons with lucide-react equivalents.
```

MCP gives the agent exact layer names → class names, precise CSS values (not approximations), layout hierarchy, and variable bindings. Code targets: React, Next.js, Vue, Svelte, plain HTML/CSS — all first-class. Native targets (SwiftUI, Compose, WinUI) are not first-class; export design tokens and apply them natively instead. The canvas itself is web-first.

**Pixel-perfect verification:** run the generated code locally → screenshot the rendered output → paste it back into Pencil at 50% opacity over the original frame → drift is immediately visible. 1-2px text drift is normal (browsers render text slightly differently than vector tools); anything larger means the agent missed a value. The `browser` MCP tool (see `reference/mcp-tools.md`) can drive this without leaving the agent session.

## Workflow: Figma to Pencil

Copy from Figma → paste into Pencil. Preserves layers and styles within roughly 1-4px tolerance.

**Transfers:** layer structure/hierarchy, fill colors and strokes, typography (if fonts are installed locally), spacing values, border radius.

**Doesn't transfer:** Figma components (come through as flattened groups), variable bindings (re-apply manually), interactive prototypes; complex Auto Layout may need manual adjustment.

```
Inspect the pasted frames in design.pen.
Apply matching variables from our design library for all fills and spacing.
Rename all layers to semantic names based on their content.
```

For shipping, prefer frames using your own variables and components over detached imported geometry.

## Layer naming rules

Layer names become class and component names in generated code.

**Bad:** Rectangle 4, Frame 12, Group, Layer. **Good:** pricing-card, nav-item-active, hero-headline, feature-icon-container.

```
Rename all layers in the selected frame to semantic names based on their content and purpose.
```

Run before every code export — the quality difference in generated code is significant.

## Git workflow

`.pen` files belong in Git alongside the code they describe.

```bash
git add design.pen src/components/
git commit -m "feat: add pricing section design and implementation"
```

```bash
git checkout -b feature/checkout-flow
# build design in checkout.pen, build code from it
git commit -m "feat: checkout flow design and components"
```

Design history is code history — `git diff design.pen` shows exactly what changed.

**Commit point:** after the agent finishes a frame and you've verified the output. Don't commit mid-agent-session — partial JSON state is hard to interpret in a diff and harder to roll back.

**Auto-save warning:** issues have been reported in early access — save manually and often (`Cmd/Ctrl + S`). [Unverified] whether this has been fixed as of August 2026; no evidence either way turned up in current docs — verify in your own session before relying on auto-save.

**config.toml caveat:** a documented issue where Pencil may modify or duplicate `config.toml` files in the workspace. [Unverified] whether resolved — back up before first use in an existing project until you've confirmed otherwise.

## Pencil CLI

Real and documented as of August 2026 (`docs.pencil.dev/for-developers/pen-cli`) — see `reference/mcp-tools.md` for install, auth, and command reference. Useful for design-system audit pipelines and pre-commit hooks; likely overkill for individual design work.

## Anti-patterns

- **No hardcoded values.** Anything not bound to a variable will drift from the codebase — audit and fix after the agent builds something.
- **Don't start from scratch every session.** Load existing `.pen` files; build on previous work in the same file, committed to Git.
- **Don't skip the read step.** `get_app_state` before changes.
- **Don't use library components without checking tokens.** A Lunaris button using Lunaris tokens in a project with a custom color system is a mismatch — sync variables first, or apply your variables to library components after dropping them in.
- **Don't commit mid-agent-session.** Partial JSON state is hard to diff and roll back.
- **Don't expect Paper-style multiplayer.** Pencil is local and single-user; use Git for async collaboration.

## Limitations

**Early-access rough edges:** auto-save issues (save manually), `config.toml` may be modified/duplicated (back up first), alignment discrepancies of 4-8px reported in complex three-column responsive layouts, Wayland/Hyprland UI issues on Linux (use X11). [Unverified] whether any of these have shipped fixes since being documented — re-check before assuming they're resolved.

**Design scope:** frontend/UI only, no backend logic; responsive requires explicit breakpoint frames; no advanced prototyping/interactions; no native real-time multiplayer; Pencil itself is free, Claude Code cost is on you.

**Code output:** React, Next.js, Vue, Svelte, plain HTML/CSS — Tailwind support is solid. Native (SwiftUI, Compose, WinUI) is not a first-class target — export tokens, build natively.

**Color:** hex sRGB only, no OKLCH, no P3. If `color.md` specifies P3, use sRGB equivalents and note the gap.

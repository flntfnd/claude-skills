# Pencil MCP Tools Reference

## Contents

- [Current tool surface (August 2026)](#current-tool-surface-august-2026)
- [get_app_state — call this first](#get_app_state--call-this-first)
- [execute — the operations language](#execute--the-operations-language)
- [Other tools](#other-tools)
- [.pen file access rule — and an unresolved discrepancy](#pen-file-access-rule--and-an-unresolved-discrepancy)
- [The pen CLI](#the-pen-cli)
- [Legacy / deprecated](#legacy--deprecated)

## Current tool surface (August 2026)

This is confirmed directly against a live Pencil MCP server connection, not just docs — treat it as the ground truth over any third-party skill repo or cached doc page that still references the old names below.

```
get_app_state     Editor/schema/canvas state. Call before any other tool.
get_guidelines     Fetches Pencil's own guidance/style rules for the current file.
execute            Runs an operation (or batch) against the design — insert, update,
                    replace, move, delete nodes; get/set variables and themes; the
                    general-purpose write tool.
get_screenshot     Base64 render of the current design or a node.
export_nodes       Export specific nodes (PNG/JPEG/WEBP/PDF).
export_html        Export a node or file as static HTML.
browser            Opens/drives a browser view — used for live preview and
                    pixel-comparison work alongside the canvas.
```

## get_app_state — call this first

```
get_app_state({
  include_schema: true,
  include_canvas_design: true,
  include_scripts_and_shaders: false
})
```

All three flags are required. If you don't already have the current `.pen` file's schema in context, call this before calling any other Pencil MCP tool — the schema is what makes `execute` calls valid.

## execute — the operations language

`execute` replaced the old standalone `batch_design` / `batch_get` / `get_variables` / `set_variables` tools with a single expression-based interface. Example, from the official docs:

```
execute({ input: 'hero=Insert(document,{type:"frame",name:"Hero",x:0,y:0,width:1440,height:900,fill:"#0A0A0A"})' })
```

Operations available through `execute` include Insert, Update, Replace, Move, Delete, GetVariables, and SetVariables. You generally don't hand-write these — the agent picks the right operation from a natural-language prompt — but recognizing the shape helps when debugging a failed write or reading a session transcript.

## Other tools

`get_guidelines` is worth calling early in a session — it returns Pencil's own current guidance, which is more likely to be accurate than any cached skill file (including this one) if the tool surface has moved again since this was written.

`export_nodes` and `export_html` cover what the old docs described loosely as "batch export" — use `export_html` when you want a static HTML snapshot of a frame (e.g. for the pixel-perfect overlay trick), `export_nodes` for image/PDF assets.

`browser` is new since the tool list documented in April 2026 — it drives an actual browser, which is what makes the screenshot-overlay verification workflow (see main SKILL.md) practical without leaving the agent session.

## .pen file access rule — and an unresolved discrepancy

The live Pencil MCP server instructs agents that `.pen` files are encrypted and must be accessed **only** through Pencil MCP tools — never `Read` or `Grep` directly.

This conflicts with docs.pencil.dev's own `.pen` format reference, which describes the format as plain, human-readable JSON intended to be both hand-edited and MCP-driven. [Unverified] which is current: either the on-disk format changed to something encrypted/obfuscated after that docs page was written, or the MCP server's instruction is a defensive default regardless of the actual file format (e.g. to force all writes through schema validation). Either way, **follow the MCP server's instruction as the hard rule** — don't `cat`, `Read`, or `grep` a `.pen` file even if it looks like plain JSON in a text editor. Flag this discrepancy to Rob; it's the kind of thing worth a five-minute check in his own session (`get_app_state` then try opening the raw file) before relying on it either way.

## The pen CLI

Confirmed via docs.pencil.dev/for-developers/pen-cli — a real, documented feature as of August 2026, not a placeholder.

```bash
# Install (npm package name conflicts between sources — verify before scripting against it)
npm install -g @pencil.dev/cli   # [Unverified] — some docs pages show @pen.dev/cli instead

# Auth
pen login       # interactive: email+password or OTP, stores token in ~/.pencil/session-cli.json
pen status       # check auth status
pen version

# Usage
pen interactive              # headless shell for direct MCP tool calls — scripting/debugging
pen [options]                 # agent mode: run a prompt against an input/output .pen file
# batch mode: process multiple designs from a JSON tasks file
# export: PNG, JPEG, WEBP, PDF
```

For CI/CD, set `PEN_CLI_KEY` (an org-scoped key from the Developer Keys section of the pen.dev web app) instead of interactive login — it takes precedence over any stored session. The CLI runs the same editor engine as the desktop app and IDE extension, fully headless. Useful for design-system audit pipelines and pre-commit hooks; likely overkill for individual design work.

## Legacy / deprecated

<details>
<summary>Tool names from ~April 2026 and earlier — not present on the live MCP server as of August 2026</summary>

```
batch_design       Create, modify, manipulate elements (insert/copy/update/replace/move/delete)
batch_get           Read components and hierarchy, search by pattern
snapshot_layout     Analyze layout, detect overlaps
get_editor_state    Current editor context, selection, active file
get_variables       Read tokens
set_variables       Update tokens, sync with CSS
```

These names still show up in some third-party skill repos and cached docs from early-to-mid 2026 (e.g. GitHub skill packages referencing `batch_design`). If you see a prompt or skill file calling these directly, it's stale — the functionality now lives inside `execute` (for writes and variable get/set) and `get_app_state` (for editor context). Don't port these tool names into new prompts.

</details>

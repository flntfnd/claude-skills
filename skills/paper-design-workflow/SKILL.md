---
name: paper-design-workflow
description: Use when working in Paper (paper.design), the code-native, MCP-connected design canvas built on real HTML and CSS — not Figma, not a proprietary vector model. Covers Paper Desktop MCP setup across Claude Code, Cursor, Codex, Copilot, Antigravity, and OpenCode; the full read/write MCP tool surface (get_jsx, get_tree_summary, write_html, update_styles, export, move_nodes, etc.); the dark-canvas-first and no-empty-artboard hard gates checked every session; design-to-code and code-to-design workflows; Paper Snapshot for copying live websites into editable layers; Figma-to-Paper token sync and its import gotchas; the native shader system (Halftone, Liquid Metal, Mesh Gradient, custom GLSL) and in-canvas AI image generation; CSS custom-property design tokens; pixel-perfect verification via screenshot overlay; and current open-alpha status, pricing (Free vs Pro vs Organizations), and roadmap. Trigger on mentions of Paper, paper.design, Paper Desktop, Paper Snapshot, Paper Shaders, or a Paper MCP tool name.
---

# Paper Design Workflow

Paper is a design canvas built on real HTML and CSS. Elements are HTML elements with real CSS — not Figma vectors, not a proprietary WebGL model. Designs export as code with no translation step; Claude Code reads and writes the canvas directly via MCP; what you see in Paper is what the browser renders.

The whole pitch is the absence of translation. Spacing isn't "looks about 16px," it's `padding: 16px`. Typography isn't approximate, it's the actual font stack. Don't undermine that fidelity by guessing — read the canvas before you write to it.

**Status: open alpha as of August 2026.** Paper ships to production almost daily. Check paper.design/build-log before any complex session — API surface and defaults move fast.

## Hard gates — check every session

1. **Dark canvas first.** Paper defaults to dark. If a canvas is white: click empty canvas area → Background panel → set to `#1A1A1A`.
2. **No empty artboards.** An artboard exists when it's populated. A file with 12 empty artboards labeled "Screen 1"–"Screen 12" is clutter, not a starting point. Minimum artboard set per project: Authentication (login, signup, forgot password), Home/main (default, loading, empty, error states), Detail view, Settings/profile, Navigation shell.
3. **Both light and dark mode** for each artboard before a design is considered complete.

## MCP setup

Paper Desktop must be running. The server starts automatically at `http://127.0.0.1:29979/mcp`, local-only, no cloud dependency. See `reference/editor-setup.md` for exact steps per host (Claude Code, Cursor, Codex, Copilot, Antigravity, OpenCode), connection verification, WSL networking, and the MCP-failure recovery sequence (restart the agent session, then the host — most failures are long-running-session staleness).

## MCP tools

Read/write, bidirectional. Full surface as of August 2026 (paper.design/docs/mcp):

```
# Read
get_basic_info        File name, page, node count, artboards with dimensions
get_selection          Currently selected nodes (IDs, names, types, size, artboard)
get_node_info          Details for a node by ID
get_children           Direct children of a node
get_tree_summary       Compact subtree hierarchy (optional depth limit)
get_screenshot         Base64 screenshot of a node (optional 1x or 2x scale)
get_jsx                JSX for a node (Tailwind or inline-styles)
get_computed_styles    Computed CSS for one or more nodes (batch)
get_fill_image         Image data from an image-fill node (base64 JPEG)
get_font_family_info   Whether a font is available (local or Google Fonts), weights, styles
get_guide              Retrieve guided workflows for topics (e.g. figma-import)
export                 Export nodes as image or video files

# Write
create_artboard        New artboard with optional dimensions/name
write_html              Parse HTML and add or replace nodes (insert-children or replace mode)
set_text_content        Update text content (batch)
rename_nodes            Rename layers (batch)
duplicate_nodes         Deep clone, returns new IDs and descendant ID map
move_nodes              Reposition or reparent nodes
update_styles           Update CSS on nodes (batch)
delete_nodes            Delete nodes and descendants

# Status
finish_working_on_nodes   Clear working indicator
```

`export` and `move_nodes` are new since the March 2026 tool list — `export` covers what used to be screenshot-only, now including video. [Unverified] `find_placement` and `start_working_on_nodes` were documented in March 2026 but didn't surface in an August 2026 docs fetch; they may still exist under a different grouping. If precision matters, check your session's live `/mcp` tool listing rather than trusting either list blindly.

**Always read before writing.** `get_tree_summary` or `get_selection` before structural changes. `get_guide` for built-in workflow recipes.

## Design style

Before building, pull in the `visual-styles` skill for the project's style and the `color-system` skill for the palette. Paper renders CSS natively, so style tokens apply directly — no approximation.

Paper supports OKLCH, Display P3, and sRGB per element, and you can mix `oklch()`, `display-p3`, and hex in the same file — unlike Figma, where color space is a file-wide toggle. For colors flagged P3 in color.md, use them as-is; the picker tab opens automatically based on gamut detection.

## Canvas architecture

- **Artboards** — fixed-size frames. Screen, component canvas, or breakpoint variant.
- **Layers** — HTML elements inside artboards.
- **Variables** — CSS custom properties stored in the file.
- **Components** — reusable elements with slots (still "coming soon" on the roadmap as of August 2026).

Naming matters: the MCP reads layer names and uses them to generate class and component names. `pricing-card-container` generates `.pricing-card-container`. "Rectangle 4" generates nothing useful. Run `rename_nodes` before any code export.

## Workflow: Design to code

```
1. Open Paper Desktop — MCP server starts
2. Create or open a file, set up artboards per screen/component
3. Build visually or via Claude Code through MCP
4. Select the frame to build
5. Ask Claude Code to generate code from the selection
```

Prompt that consistently works:

```
I'd like you to build the selected frame in Paper as a React + Tailwind component.
Use get_jsx to read the design, then generate matching production code.
Name all components semantically from the layer names.
```

Best results come from Flex-layout containers (not absolute positioning), semantic layer names, variables bound to elements rather than hardcoded fills, small focused frames per pass, and a selection-driven workflow (select, then prompt).

For Tailwind specifically: `Alt+T` copies the selection as Tailwind, `Alt+R` copies as React+CSS. Native Tailwind rendering and idiomatic Tailwind import/export are still "in progress" on the roadmap.

## Workflow: Code to design

Push existing tokens/styles into Paper:

```
Read the Tailwind config in this project and create matching
design variables in Paper for colors and spacing.
```

Sync real content from APIs, databases, or any MCP-exposed source (e.g. Notion):

```
Sync the content from the Notion Testimonials database with the
selected testimonial frame.
```

Test layout resilience with translation:

```
Translate the testimonials in the selected frame to German.
Test how the layout holds up at typical German string lengths.
```

## Workflow: Snapshot — copy live websites into Paper

Paper Snapshot is a Chrome extension (Chrome Web Store → "Paper Snapshot" by Lost Coast Labs). It copies sections of any live website and pastes them into Paper as editable HTML/CSS layers — real layers, real CSS, not screenshots.

Usage: select a section on a live site → copy via the extension → paste into Paper → edit as native layers. This is the fastest path for "replicate this competitor's pricing page" — it replaces the html.to.design / screenshot-and-trace workflow entirely. For local dev servers (CORS issues), see paper.design/docs/support/snapshot-local-images.

## Workflow: Figma to Paper

Requires both MCPs connected to the same agent: Paper via `/plugin install paper-desktop@paper`, Figma via Figma's own MCP setup (paid Figma plan required). Both use the currently open file as context — have the right files open in both apps.

```
Sync the color variables and text styles from the open Figma file
into the Paper file as design variables.
```

The Figma MCP is read-only; always-allow is fine. The Paper MCP is read/write — be deliberate about its permissions.

**Figma import gotchas:** code-connected components don't reliably convert; inset borders in Figma don't convert to outlines; spacer elements used for layout gaps get ignored; very deeply nested designs cause timeout errors (break into smaller chunks). As of May 2026, Figma copy/paste gained SVG and image support, and August 2026 added Figma slots support on paste — fidelity has improved, but still verify results rather than assuming a 1:1 conversion, especially for SVG component instances and color overrides.

## Workflow: Building a website from a design

Open the agent in a fresh folder (or existing project) with the target frame selected in Paper:

```
Build a website in this folder using the hero section I have
selected in Paper. Use React and Tailwind.
```

The agent calls read-only MCP tools to inspect the design (always-allow is fine), then writes files. Smaller frames produce more accurate output — start small, build up. Commit after the first working version, then iterate; `git diff` on the generated code shows exactly what changed when you sync designs back.

For responsive: select multiple breakpoint frames in Paper before prompting:

```
Add responsive breakpoints to the website based on the frames
I have selected in Paper. Each frame is a different breakpoint.
```

## Applying styles

Style application is direct CSS via `update_styles`:

```
update_styles on selected nodes with:
  background: var(--color-surface)
  border-radius: var(--radius-md)
  padding: var(--spacing-base)
```

Futuristic/Sci-Fi glow border:
```css
border: 1px solid rgba(0, 245, 212, 0.2);
box-shadow: 0 0 12px rgba(0, 245, 212, 0.4);
```

Neo-Brutalism hard offset shadow:
```css
border: 2px solid #000;
box-shadow: 4px 4px 0 0 #000;
border-radius: 0;
```

Glassmorphism (needs a rich background artboard beneath):
```css
background: rgba(255, 255, 255, 0.12);
backdrop-filter: blur(16px);
border: 1px solid rgba(255, 255, 255, 0.25);
```

Backdrop filters are first-class in the Filters panel, alongside CSS filters (blur, saturation, grayscale, brightness, sepia, invert, hue rotation).

## Shaders and AI image generation

Paper has a native shader system and in-canvas AI image generation. See `reference/shaders.md` for the current shader catalog, style pairings, the eye-dropper workflow, and the current AI image model lineup — this list rotates roughly every quarter, so treat any specific model name as a snapshot, not a guarantee.

## Variables (design tokens)

Paper variables are CSS custom properties, exported as CSS. As of June 2026 you can add tokens via the MCP directly from a codebase's CSS variables, and as of August 2026 you can also create tokens directly in the Paper UI (previously MCP-only).

```
Create design variables in this Paper file:
- color-background: #F5F3EE
- color-text: #1A1A1A
- color-accent: #D52B1E
- spacing-base: 16px
- radius-md: 8px
```

```
Update the background of all card frames to var(--color-background).
Update all headline text to var(--color-text).
```

```
Read CSS custom properties from src/styles/tokens.css and create
matching Paper variables for all color and spacing values.
```

Token names should match the codebase. Swift `Color.Semantic.Background.primary` becomes `--color-semantic-background-primary` in Paper — pull in the `apple-platform` or `android-platform` skill first for existing token names. Native theming (`color-mix()`, `calc()`, blend modes inside the variable system) is still roadmap; today you can use those CSS features directly in the canvas, but native theme switching is the gap. Themes can be copied/pasted between files (June 2026).

## Typography

Variable fonts with custom axis values, automatic optical size, OpenType font features panel (stylistic sets, contextual alternates, ligatures), text gradients via the Fill panel. System fonts and Google Fonts both work; local fonts override Google fallbacks automatically. Use `get_font_family_info` from the MCP to confirm availability before committing to a font choice.

## Pixel-perfect verification

After the agent generates code from a frame, screenshot the rendered output and paste it back into Paper at 50% opacity over the original frame. Misalignments are immediately visible. Browsers render text slightly differently than design tools, so 1-2px text drift is normal — anything larger means the agent missed a value. Use `get_screenshot` at 2x for the comparison capture.

## Design file rules

**Layer naming.** Every layer that will generate a class or component gets a semantic name before code export.

**Responsive.** Multiple artboards as breakpoints: mobile (375px), tablet (768px), desktop (1440px). The Constraints panel controls how elements behave on parent resize.

**Variables over hardcoded values.** No element should have a hardcoded hex fill if a variable exists for it. Use `get_computed_styles` to audit before handoff — `background: #F5F3EE` instead of `background: var(--color-background)` means a binding is missing.

## Status and pricing (August 2026)

**Recently shipped** (paper.design/build-log): threaded comments for team/agent collaboration, desktop tabs (multiple files open with background agent processing), folders/subfolders, a pen tool (`P`) for SVG path creation with node add/delete/move, PDF export, Figma copy/paste with SVG+image support.

**Roadmap — in progress:** using your own code components (no second design system), native Tailwind CSS rendering and idiomatic Tailwind I/O, themes/tokens with `calc`/`color-mix`/blend modes, hosting assets from Paper (CDN-style links), full vector editing, Paper Shaders expansion, full sharing settings.

**Roadmap — coming soon:** components with slots (props and slots, code-aligned), icon packs, shadcn integration.

**Roadmap — planned:** CSS Grid in canvas, a script/prompt engine, right-click → Remix, generated videos, Lottie/Rive/YouTube embeds, particle system, Three.js islands, advanced image filters.

**Pricing** (paper.design/pricing, checked August 2026 — alpha-stage pricing moves, re-verify before quoting a number to anyone):

| | Free | Pro | Organizations |
|---|---|---|---|
| Price | $0 | $20/mo ($16/mo annual) | Custom |
| MCP calls | 100/week | 1M/week | Custom |
| Image gen | Limited | 100x Free | Custom |
| Max image size | 25 MB | 100 MB | Custom |
| Video export | No | Yes | Yes |
| Editors/viewers | Unlimited, free | — | SAML/SSO, admin controls |

Known issue: after upgrading to Pro, MCP limits may not reset — fix is updating Paper Desktop (`About > Check for updates`) and restarting the app.

For client-facing production work with strict delivery, wait for Paper to exit open alpha or accept that APIs change. For internal tooling, prototypes, or solo/small-team AI-first work, it's usable today.

## Limitations (open alpha)

**Can do well:** single screens and focused components, Flex-layout designs, real CSS with variables, design-to-code for React + Tailwind (and increasingly other stacks), shader effects and video export, multiplayer collaboration via URL, token sync and real content via MCP.

**Can't do yet:** CSS Grid in canvas, components with slots, native theme switching (variables work, theme columns don't), full vector editing (basic pen tool shipped June 2026, but the full suite is still in progress), advanced prototyping and interactions, guaranteed API stability.

**Workaround for instability:** version control your Paper files in git. Commit after each working state; `git checkout` back to the last good commit if a session breaks something.

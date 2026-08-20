# paper.md
Paper design system workflow. paper.design — open alpha. Paper Desktop with MCP launched March 10, 2026.
Code-native canvas, two-way MCP, real HTML/CSS foundation. Not Figma. Different assumptions.

Current state: open alpha. APIs change. Paper ships to production almost daily. Check paper.design/build-log for recent changes before starting any complex workflow.

---

# What Paper Is

Paper is a design canvas built on real HTML and CSS. Elements are HTML elements with real CSS, not Figma vectors or a proprietary WebGL model. The consequence:

- Designs export as code with no translation step
- Claude Code reads and writes the canvas directly via MCP
- Real CSS layout (Flexbox today, Grid coming) inside the canvas, not approximations
- Tailwind classes, CSS custom properties, `color-mix()`, `oklch()`, backdrop filters render natively
- Multiplayer: web-native, share via URL, not a single-user desktop tool
- What you see in Paper is what the browser renders

The whole pitch is the absence of translation. Design decisions in Paper *are* code decisions. Spacing isn't "looks about 16px," it is `padding: 16px`. Typography isn't approximate, it is the actual font stack. Don't undermine that fidelity by guessing.

LLMs are good at understanding the DOM. Paper hands them the DOM. That's why this works.

---

# STEP 0 — Dark canvas

Paper defaults to a dark canvas. If it's white:
- Click empty canvas area
- Background panel → set to `#1A1A1A`

---

# STEP 1 — MCP setup

Paper Desktop must be running. The MCP server starts automatically when Paper Desktop opens a file. The server runs locally at `http://127.0.0.1:29979/mcp`. No cloud dependency. Files stay on disk.

## Claude Code

```bash
# Add the Paper plugin marketplace
/plugin marketplace add paper-design/agent-plugins

# Install the Paper Desktop plugin
/plugin install paper-desktop@paper
```

Verify with `/mcp` — Paper should appear in the list.

## Cursor

```
/add-plugin paper-desktop
```

Or install via the Cursor Marketplace. Verify in `Cursor Settings > Tools & MCP`. Reload the window or toggle the MCP off/on if the agent doesn't see it.

## Codex

`Settings > MCP Servers` → Add custom MCP → "Streamable HTTP" tab → name `paper`, URL `http://127.0.0.1:29979/mcp`.

## Copilot (VS Code)

Create `.vscode/mcp.json`:

```json
{
  "servers": {
    "paper": {
      "type": "http",
      "url": "http://127.0.0.1:29979/mcp"
    }
  }
}
```

Click "Start" above the word "paper" in the file.

## Antigravity

Open MCP store → Manage MCP Servers → View raw config → modify `mcp_config.json`:

```json
{
  "mcpServers": {
    "paper": {
      "serverUrl": "http://127.0.0.1:29979/mcp"
    }
  }
}
```

## OpenCode

Add to `opencode.json`:

```json
{
  "mcp": {
    "paper": {
      "type": "remote",
      "url": "http://127.0.0.1:29979/mcp",
      "enabled": true
    }
  }
}
```

## Verifying the connection

Open a chat: "create a red rectangle in Paper." The agent should ask permission, then create the rectangle visibly in the document.

## When MCP fails

Most common cause: long-running agent sessions. Restart the agent session first. If that fails, restart the host (Cursor, Claude Code, Codex, Copilot). LLMs occasionally hallucinate tool parameters even when they have the schema — the fix is the same, restart everything.

WSL users: enable mirrored mode networking (`networkingMode: mirrored` in WSL config) to access `127.0.0.1`.

---

# STEP 2 — Understand the MCP tools

Paper MCP is bidirectional read/write. Full surface as of March 2026:

```
# Read
get_basic_info        File name, page, node count, artboards with dimensions
get_selection         Currently selected nodes (IDs, names, types, size, artboard)
get_node_info         Details for a node by ID
get_children          Direct children of a node
get_tree_summary      Compact subtree hierarchy (optional depth limit)
get_screenshot        Base64 screenshot of a node (optional 1x or 2x scale)
get_jsx               JSX for a node (Tailwind or inline-styles)
get_computed_styles   Computed CSS for one or more nodes (batch)
get_fill_image        Image data from an image-fill node (base64 JPEG)
get_font_family_info  Whether a font is available (local or Google Fonts), weights, styles
get_guide             Retrieve guided workflows for topics (e.g. figma-import)

# Write
find_placement           Suggested x/y to place a new artboard without overlap
create_artboard          New artboard with optional dimensions/name
write_html               Parse HTML and add or replace nodes (insert-children or replace mode)
set_text_content         Update text content (batch)
rename_nodes             Rename layers (batch)
duplicate_nodes          Deep clone, returns new IDs and descendant ID map
update_styles            Update CSS on nodes (batch)
delete_nodes             Delete nodes and descendants

# Status
start_working_on_nodes    Show working indicator in Paper
finish_working_on_nodes   Clear working indicator
```

**Always read before writing.** `get_tree_summary` or `get_selection` before structural changes. `get_guide` for built-in workflow recipes.

---

# STEP 3 — Design style

Before building, read `~/.claude/skills/styles.md` and confirm the style for the project. Read `~/.claude/skills/color.md` for the palette. Paper renders CSS natively so style tokens apply directly. No approximation required.

Paper supports OKLCH, Display P3, sRGB, and hex per element. You can mix `oklch()`, `display-p3`, and hex in the same file — unlike Figma, where the color space is a file-wide toggle. For colors flagged as P3 in color.md, use them as-is. The picker tab opens automatically based on sRGB or P3 gamut detection.

---

# Canvas Architecture

Paper organizes work as:
- **Artboards** — fixed-size frames. Screen, component canvas, or breakpoint variant.
- **Layers** — HTML elements inside artboards.
- **Variables** — CSS custom properties stored in the file.
- **Components** — reusable elements with slots (in progress per roadmap, expected next).

Naming matters. Rename layers from "Rectangle 4" to semantic names. The MCP reads layer names and uses them to generate class names and component names. `pricing-card-container` generates `.pricing-card-container`. "Rectangle 4" generates nothing useful.

---

# Workflow: Design to Code

Canonical flow:

```
1. Open Paper Desktop — MCP server starts
2. Create or open a file
3. Set up artboards for each screen/component
4. Build designs visually or via Claude Code through MCP
5. Select the frame to build
6. Ask Claude Code to generate code from the selection
```

Prompt that consistently works:

```
I'd like you to build the selected frame in Paper as a React + Tailwind component.
Use get_jsx to read the design, then generate matching production code.
Name all components semantically from the layer names.
```

Best results come from:
- Designs using Flex layout containers, not absolute positioning
- Semantic layer names (rename before export)
- Variables bound to elements, not hardcoded fills
- Small, focused frames per pass — not entire pages at once
- Selection-driven workflow: select the frame, then prompt

For Tailwind specifically: `Alt+T` copies the selection as Tailwind. `Alt+R` copies as React+CSS. Native Tailwind rendering and idiomatic Tailwind import/export is on the roadmap (`in progress` as of April 2026).

---

# Workflow: Code to Design

Two-way sync. Push existing tokens/styles into Paper:

```
Read the Tailwind config in this project and create matching
design variables in Paper for colors and spacing.
```

Sync real content from APIs or databases:

```
Pull product names and prices from /api/products
and populate the pricing cards in the selected frame.
```

Import existing components from your codebase as a starting point for design iteration.

---

# Workflow: Snapshot — copy live websites into Paper

Paper Snapshot is a Chrome extension. It copies sections of any live website and pastes them into Paper as editable HTML/CSS layers. Real layers, real CSS — not screenshots.

Install: Chrome Web Store → "Paper Snapshot" by Lost Coast Labs.

Usage: select a section on any live site → copy via the extension → paste into Paper → edit as native layers.

This is the fastest path for "replicate this competitor's pricing page" or "I like how this nav works, let me start there." It replaces the html.to.design / screenshot-and-trace workflow entirely.

For local dev servers (CORS issues), see paper.design/docs/support/snapshot-local-images.

---

# Workflow: Figma to Paper

Paper supports Figma token sync when both MCPs are connected to the same agent.

Setup:
- Paper MCP: via `/plugin install paper-desktop@paper`
- Figma MCP: via Figma's own MCP setup (paid Figma plan required)

Both MCPs use the currently open file as context. Have the right files open in both apps. Ask the agent what it sees if you're unsure.

In Figma, select an element that has a variable or style assigned. Then in your agent:

```
Sync the color variables and text styles from the open Figma file
into the Paper file as design variables.
```

The Figma MCP is read-only. Always-allow is usually fine. The Paper MCP is read/write. Be deliberate about its permissions.

**Figma import gotchas:**
- SVG fills come through as images, not editable vectors
- SVG component instances usually lose color overrides
- Spacer elements used for layout gaps get ignored
- Inset borders in Figma don't convert to outlines
- Code-connected components don't reliably convert
- Very deeply nested designs cause timeout errors — break them into smaller chunks and iterate

---

# Workflow: Real content from Notion (or any MCP source)

Designing with lorem ipsum is bad. With both Paper MCP and Notion MCP connected to the same agent, real data flows in:

```
Sync the content from the Notion Testimonials database with the
selected testimonial frame.
```

Take it further with translation for layout testing:

```
Translate the testimonials in the selected frame to German.
Test how the layout holds up at typical German string lengths.
```

Same pattern works with any MCP-exposed data source. Live API fetch from agent-readable sources is on the roadmap (`in progress`).

---

# Workflow: Building a website from a design

Open the agent in a fresh folder (or existing project). Have the target frame selected in Paper.

```
Build a website in this folder using the hero section I have
selected in Paper. Use React and Tailwind.
```

Agent will call read-only MCP tools to inspect the design (always-allow is fine), then write files. The smaller the frame, the more accurate the output. Start small, build up.

After the first working version: commit. Then iterate. Pencil-style "git as design history" works here too — `git diff` shows exactly what changed when you sync designs back.

For responsive: select multiple breakpoint frames in Paper before prompting:

```
Add responsive breakpoints to the website based on the frames
I have selected in Paper. Each frame is a different breakpoint.
```

---

# Workflow: Applying Styles

Paper renders CSS natively. Style application is direct CSS:

```
update_styles on selected nodes with:
  background: var(--color-surface)
  border-radius: var(--radius-md)
  padding: var(--spacing-base)
```

For Futuristic/Sci-Fi style — glow border:
```css
border: 1px solid rgba(0, 245, 212, 0.2);
box-shadow: 0 0 12px rgba(0, 245, 212, 0.4);
```

For Neo-Brutalism — hard offset shadow:
```css
border: 2px solid #000;
box-shadow: 4px 4px 0 0 #000;
border-radius: 0;
```

For Glassmorphism — requires a rich background artboard beneath, plus the new backdrop-filter support:
```css
background: rgba(255, 255, 255, 0.12);
backdrop-filter: blur(16px);
border: 1px solid rgba(255, 255, 255, 0.25);
```

Backdrop filters are first-class in the Filters panel as of March 2026. CSS filters too: blur, saturation, grayscale, brightness, sepia, invert, hue rotation.

---

# Shaders

Paper has a native shader system at shaders.paper.design. Shaders run in Paper frames as live effects, not static images. They update in real time and export as video (MP4, WebP, AVIF).

**Shipped shaders (incomplete list, growing):**
- Halftone CMYK — print-style effects with extensive color control
- Halftone Dots — vintage pop-art aesthetics
- Fluted Glass — distortion + grain
- Liquid Metal — contour detection, accepts uploaded logo as the shape
- Mesh Gradient (animated and static), Static Radial Gradient
- Image Dithering
- Pulsing Border — useful for "thinking orb" UI
- Paper Texture — fiber and crumple control
- Swirl, Water, Heatmap
- Custom GLSL fragment shaders via the built-in editor

**Apply a shader:** select the frame → Effects panel → Shader → choose from library or write custom GLSL.

**Eye dropper for shaders** (March 2026): sample colors from any image or another shader's output via the Foreground colors panel. `Shift+I` adds gradient colors via eye dropper.

For Futuristic/Sci-Fi: CRT/scanline shader, grid glow shader, Pulsing Border. For Organic/Biomorphic: noise displacement, Fluted Glass. For Editorial Print: Halftone CMYK, Halftone Dots.

---

# AI image generation (in-canvas)

Paper has native image generation in the canvas. As of December 2025:
- Flux 2 — multi-reference, photorealism, higher resolution
- Nano Banana Pro — powered by Gemini 3
- OpenAI Image Edit 1.5 — faster, more precise editing
- Seedream 4.5 — text-to-image

Image edits preserve original aspect ratio when possible. Generated images get placed intelligently on the canvas.

Image fills (the Fill panel accepts images and composes them with other fills). HEIC/HEIF supported.

---

# Variables (Design Tokens)

Paper variables are CSS custom properties. They live in the file and export as CSS.

**Create variables:**

```
Create design variables in this Paper file:
- color-background: #F5F3EE
- color-text: #1A1A1A
- color-accent: #D52B1E
- spacing-base: 16px
- radius-md: 8px
```

**Bind variables to elements:**

```
Update the background of all card frames to var(--color-background).
Update all headline text to var(--color-text).
```

**Sync from codebase:**

```
Read CSS custom properties from src/styles/tokens.css and create
matching Paper variables for all color and spacing values.
```

Token names in Paper should match the codebase. Swift `Color.Semantic.Background.primary` becomes `--color-semantic-background-primary` in Paper. Read `~/.claude/skills/apple.md` or `~/.claude/skills/android.md` first for existing token names.

Native theming and `color-mix()`, `calc()`, blend modes inside the variable system: roadmap, `coming soon`. Today, you can use these CSS features directly in the canvas; native theme switching is the gap.

---

# Typography

Variable fonts with custom axis values (Nov 2025). Automatic optical size in variable fonts (Dec 2025). OpenType font features panel (March 2026) — stylistic sets, contextual alternates, ligatures, all the things you'd reach for in production CSS.

Paper Mono ships in the editor as a preview font (Oct 2025).

Text gradients via the Fill panel.

System fonts and Google Fonts both work. Local fonts override Google fallbacks automatically. `get_font_family_info` from the MCP confirms availability before the agent commits to a font choice.

---

# No Empty Artboards

Same rule as Figma and Sketch. Artboards exist when they're populated. A file with 12 empty artboards labeled "Screen 1" through "Screen 12" is clutter, not a starting point.

**Minimum artboard set per project:**
- Authentication (login, signup, forgot password)
- Home/main (default, loading, empty, error states)
- Detail view
- Settings/profile
- Navigation shell

Each artboard in both light and dark mode before the design is considered complete.

---

# Pixel-perfect verification

The trick the Paper community uses: after the agent generates code from a frame, screenshot the rendered output and paste it back into Paper at 50% opacity over the original frame. Misalignments are immediately visible. Browsers render text slightly differently than design tools, so 1-2px text drift is normal. Anything larger means the agent missed a value.

Use `get_screenshot` from the MCP to capture the original at 2x for comparison work.

---

# Design File Rules

**Layer naming.** Every layer that will generate a class or component gets a semantic name before code export. Run `rename_nodes` on the frame before asking for code output.

**Responsive.** Multiple artboards as breakpoints. Mobile (375px), tablet (768px), desktop (1440px). Constraints panel (March 2026) controls how elements behave on parent resize.

**Variables over hardcoded values.** No element should have a hardcoded hex fill if a variable exists for it. Use `get_computed_styles` to audit before handoff. If you see `background: #F5F3EE` instead of `background: var(--color-background)`, a binding is missing.

---

# Status of features (April 2026)

Per the official roadmap.

**Done:**
- MCP server (Paper Desktop)
- Paper Snapshot browser extension
- Real flexbox in canvas
- Copy as React, Copy as Tailwind
- OKLCH color picker, P3 wide gamut
- Variable fonts and OpenType features
- Backdrop filters, CSS filters
- AI image generation (Flux 2, Nano Banana Pro, etc.)
- Video export (Pro)
- Multiplayer / real-time collaboration
- Vectorize

**In progress:**
- Native Tailwind CSS rendering and idiomatic Tailwind I/O
- Use your code components (no second design system)
- Fetch live data via MCP agents
- Host assets from Paper (CDN-style links)
- Canvas-aware agent assistant
- Paper Shaders expansion

**Coming soon:**
- Components with slots (props and slots, code-aligned)
- Themes and tokens with `calc`, `color-mix`, blend modes
- Full sharing settings
- Pen tool and vector editing
- Icon packs, shadcn integration, Base UI partnership

**Planned:**
- CSS Grid in canvas
- Right click → Remix
- Generate videos
- Lottie, Rive, YouTube embeds
- Particle system
- Three.js islands
- Advanced image filters

For client-facing production work with strict delivery, wait for Paper to exit open alpha or accept that APIs change. For internal tooling, prototypes, or solo/small-team AI-first work, it's usable today.

---

# Limitations (open alpha)

**Can do well:**
- Single screens and focused components
- Flex-layout designs
- Real CSS with variables and custom properties
- Design-to-code for React + Tailwind (and increasingly other stacks)
- Shader effects and video export
- Multiplayer collaboration via URL
- Token sync and real content via MCP

**Can't do yet:**
- CSS Grid in canvas (planned)
- Components with slots (coming soon)
- Native theme switching (variables work, theme columns don't yet)
- Pen tool / true vector editing (coming soon)
- Advanced prototyping and interactions
- Guaranteed API stability (alpha = APIs change)

**Workaround for instability:** version control your Paper files in git. Commit after each working state. If a session breaks something, `git checkout` to the last good commit.

---

# Pricing

[Unverified] Free tier and Pro tier exist. Pro adds video export, higher MCP limits, and unlimited storage. Specific call counts and prices change — check paper.design/pricing before quoting numbers to anyone.

Known pricing-related issue: after upgrading to Pro, MCP limits may not reset. Fix: update Paper Desktop (`About > Check for updates`) and restart the app.

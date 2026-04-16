# paper.md
Paper design system workflow. paper.design -- open alpha as of 2026.
Code-native canvas, two-way MCP, HTML/CSS foundation. Not Figma. Different assumptions.

Current state: open alpha. APIs can change. Daily updates. Check paper.design/build-log for recent changes before starting any complex workflow.

---

# What Paper Is

Paper is a design canvas built on web standards. Elements are HTML/CSS, not Figma vectors. This means:

- Designs export as code without translation loss
- Claude Code can read and write the canvas directly via MCP
- Real CSS layout (Flexbox, Grid) inside the canvas, not approximations
- Tailwind classes, CSS custom properties, and `color-mix()` render natively
- What you see in Paper is what the browser renders

The consequence: design decisions in Paper ARE code decisions. Spacing isn't "looks about 16px" -- it is `padding: 16px`. Typography isn't approximate -- it is the actual font stack. This fidelity is the entire value proposition. Don't undermine it by guessing.

---

# STEP 0 -- Dark canvas

Paper defaults to a dark canvas. If it's white:
- Click empty canvas area
- Background panel → set to `#1A1A1A`

---

# STEP 1 -- MCP setup

Paper Desktop must be running. The MCP server starts automatically when you open a file.

**Connect Claude Code:**
```bash
# Add the Paper plugin marketplace
/plugin marketplace add paper-design/agent-plugins

# Install the Paper Desktop plugin
/plugin install paper-desktop@paper
```

Verify with `/mcp` -- Paper should appear in the list.

MCP runs locally at `http://127.0.0.1:29979/mcp`. No cloud dependency. Design files stay on disk.

**If the connection drops:** restart the Claude Code session. Long-running sessions are the most common cause of MCP issues.

**WSL users:** enable mirrored mode networking (`networkingMode: mirrored` in WSL config) to access `127.0.0.1`.

---

# STEP 2 -- Understand the MCP tools

Paper MCP is bidirectional read/write. These are the tools you'll use most:

```
get_basic_info        File name, page, artboard list with dimensions
get_selection         Details on currently selected nodes
get_node_info         Details for a specific node by ID
get_children          Direct children of a node
get_tree_summary      Compact hierarchy summary (use before writing)
get_screenshot        Base64 screenshot of a node -- use to verify output
get_jsx               JSX output for a node (Tailwind or inline styles)
get_computed_styles   CSS styles for one or more nodes (batch)
get_fill_image        Image data from an image-fill node

create_artboard       New artboard with optional dimensions/name
write_html            Parse HTML and add/replace nodes
set_text_content      Update text content (batch)
rename_nodes          Rename layers (batch)
duplicate_nodes       Deep clone with new IDs
update_styles         Update CSS on nodes (batch)
delete_nodes          Delete nodes and descendants

start_working_on_nodes   Shows working indicator in Paper (visual feedback)
finish_working_on_nodes  Clears working indicator
```

**Always read before writing.** Use `get_tree_summary` or `get_selection` before making changes to understand what's there.

---

# STEP 3 -- Design style

Before building, read `~/.claude/skills/styles.md` and confirm the style for the project. Read `~/.claude/skills/color.md` for palette. Paper renders CSS natively so style tokens apply directly -- no approximation required.

---

# Canvas Architecture

Paper organizes work as:
- **Artboards** -- fixed-size frames, like a screen or component canvas
- **Layers** -- HTML elements inside artboards
- **Variables** -- design tokens (colors, spacing, etc.) stored in the file
- **Components** -- reusable elements (in progress on their roadmap)

Naming matters. Rename layers from "Rectangle 4" to semantic names. The MCP reads layer names and uses them to generate class names and component names. `pricing-card-container` generates `.pricing-card-container`. "Rectangle 4" generates nothing useful.

---

# Workflow: Design to Code

The canonical Paper workflow for Claude Code:

```
1. Open Paper Desktop -- MCP server starts
2. Create or open a .paper file
3. Set up artboards for each screen/component
4. Use Claude Code to build the designs via MCP
5. Select the frame you want to build
6. Ask Claude Code to generate code from the selection
```

Example prompt that works well:
```
I'd like you to build the selected frame in Paper as a React + Tailwind component.
Use the get_jsx tool to read the design, then generate matching production code.
Name all components semantically from the layer names.
```

Best results come from:
- Designs using Flex layout containers (not absolute positioning)
- Semantic layer names
- Variables bound to elements (not hardcoded fills)
- Starting with small, focused frames -- not entire pages at once

---

# Workflow: Code to Design

Two-way sync. Push existing tokens/styles into Paper:

```
Read the Tailwind config in this project and create matching
design variables in Paper for colors and spacing.
```

Sync real content from APIs or databases:
```
Pull the product names and prices from the /api/products endpoint
and populate the pricing cards in the selected frame with real data.
```

---

# Workflow: Figma to Paper

Paper supports Figma token sync when both MCPs are connected.

**Connect both MCPs** in the same Claude Code session:
- Paper MCP: via `/plugin install paper-desktop@paper`
- Figma MCP: via Figma's own MCP setup

Then:
```
Sync the color variables and text styles from the open Figma file
into the Paper file as design variables.
```

**Figma import gotchas:**
- SVG fills come through as images, not editable vectors
- Component overrides in Figma may not transfer
- Spacer elements used for layout gaps are ignored
- Inset borders in Figma don't convert to outlines
- Very deeply nested designs can cause timeout errors -- break them into smaller chunks

---

# Workflow: Applying Styles

Paper renders CSS natively. Style application is direct CSS:

```
update_styles on selected nodes with:
  background: var(--color-surface)
  border-radius: var(--radius-md)
  padding: var(--spacing-base)
```

For Futuristic/Sci-Fi style -- glow border:
```css
border: 1px solid rgba(0, 245, 212, 0.2);
box-shadow: 0 0 12px rgba(0, 245, 212, 0.4);
```

For Neo-Brutalism -- hard offset shadow:
```css
border: 2px solid #000;
box-shadow: 4px 4px 0 0 #000;
border-radius: 0;
```

For Glassmorphism -- requires a rich background artboard beneath:
```css
background: rgba(255, 255, 255, 0.12);
backdrop-filter: blur(16px);
border: 1px solid rgba(255, 255, 255, 0.25);
```

---

# Shaders

Paper has a native shader system for GPU visual effects. Access at shaders.paper.design.

Shaders run in Paper frames as live effects -- not static images. They update in real time, export as video (MP4), and can be applied to specific frames.

**Current shader capabilities:**
- Custom GLSL fragment shaders with a built-in editor
- Motion effects and image filters
- Post-processing effects
- Eye dropper for sampling colors from shader output (added March 2026)

**Applying a shader to a frame:**
Select the frame → Effects panel → Shader → select from library or write custom GLSL.

For the Futuristic/Sci-Fi style, use the CRT/scanline shader or the grid glow shader from the library. For Organic/Biomorphic, use the noise displacement shader.

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
Update the background fill of all card frames to use var(--color-background).
Update all headline text to use var(--color-text).
```

**Sync from codebase:**
```
Read the CSS custom properties from src/styles/tokens.css and create
matching Paper variables for all color and spacing values.
```

Token names in Paper should match the codebase. If Swift code uses `Color.Semantic.Background.primary`, the Paper variable is `--color-semantic-background-primary`. Same naming, same hierarchy. Read `~/.claude/skills/apple.md` or `~/.claude/skills/android.md` first to get existing token names.

---

# No Empty Artboards

Same rule as Figma and Sketch. Artboards are created when they will be populated. A file with 12 empty artboards labeled "Screen 1" through "Screen 12" is not a starting point -- it's clutter.

**Minimum artboard set per project:**
- Authentication screens (login, signup, forgot password)
- Home/main (default, loading, empty, error states)
- Detail view
- Settings/profile
- Navigation shell

Each artboard in both light and dark mode before the design is considered complete.

---

# Design File Rules

**Layer naming:** Every layer that will generate a component or CSS class must have a semantic name before code export. Run `rename_nodes` on any frame before asking for code output.

**Responsive:** Paper supports multiple artboards as breakpoints. Create mobile (375px), tablet (768px), and desktop (1440px) artboards for any screen that will be responsive. When asking for code with breakpoints:
```
Generate responsive React code from the three selected artboards.
The narrowest artboard is mobile, the widest is desktop.
```

**Variables over hardcoded values:** No element should have a hardcoded hex fill if a variable exists for it. Use `get_computed_styles` to audit before handoff -- if you see `background: #F5F3EE` instead of `background: var(--color-background)`, a variable binding is missing.

---

# Limitations (Open Alpha)

Paper is in open alpha. Know what it can and can't do:

**Can do well:**
- Single screens and focused components
- Flex-layout-based designs
- Real CSS with variables and custom properties
- Design-to-code for React + Tailwind
- Shader effects and video export
- Token sync with external systems via MCP

**Can't do yet (check roadmap):**
- Full component library with variants (in progress)
- Complex nested Figma imports reliably
- Advanced prototyping and interactions
- Team permission controls (coming soon)
- Guaranteed API stability (alpha = APIs change)

**Workaround for instability:** version control your .paper files in git. Commit after each working state. If a session breaks something, `git checkout` to the last good commit.

---

# Pricing

Free tier: 100 MCP tool calls/week. Enough to evaluate, not enough for production.
Pro: $20/month ($16 annual) -- 1M MCP calls/week, video export, unlimited storage.

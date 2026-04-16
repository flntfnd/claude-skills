# pencil.md
Pencil design system workflow. pencil.dev -- AI-native, IDE-embedded, Git-native.
Design files (.pen) live in your repo. Claude Code reads the canvas via MCP.

Current state: "Anti-Gravity" early access. Free as of early 2026. Check pencil.dev for current pricing/access.

---

# What Pencil Is

Pencil is a design tool that lives inside your IDE (VS Code, Cursor, or as a standalone desktop app). Design files are `.pen` files that live in your Git repo alongside your code. The canvas is not a separate tool -- it's another file in the project.

Key differences from Figma and Sketch:
- `.pen` files are JSON -- human-readable, diffable, version-controlled
- Design lives in the repo, not in a cloud account
- The canvas is your IDE, not a separate app
- MCP gives Claude Code direct read/write access to the canvas
- Multiple AI agents can build on the canvas simultaneously (swarm mode)

---

# STEP 0 -- Installation

**VS Code / Cursor:** Install the Pencil extension from the marketplace. Search "Pencil" in the extension panel.

**Authentication:**
1. Sign up at pencil.dev to get an activation token
2. Enter the token in the Pencil extension settings

**Claude Code connection:**
1. Have Pencil running (open a `.pen` file)
2. In Claude Code, run `/mcp` to verify the Pencil MCP server appears
3. The server is detected automatically when Pencil is running

Pencil auto-detects Claude Code if it's installed. If MCP doesn't appear, restart both Pencil and Claude Code.

---

# STEP 1 -- Create a .pen file

In your project directory:
```
New File → name it design.pen (or dashboard.pen, components.pen, etc.)
```

The Pencil editor opens inside VS Code/Cursor. The file is JSON that tracks every element on the canvas.

**Naming conventions:**
- `design.pen` -- main design file for a project
- `design-system.pen` -- component library and tokens
- `landing.pen`, `dashboard.pen` -- screen-specific files

Multiple `.pen` files in one repo is correct. One per major section or one shared design system + per-screen files.

---

# STEP 2 -- Design style

Before adding elements, read `~/.claude/skills/styles.md` for the project's visual style and `~/.claude/skills/color.md` for the palette.

In Pencil, set the design style by establishing variables first -- color tokens, spacing, typography. These become the foundation for all elements the agent builds.

```
Set up design variables in design.pen:
- primary: #D52B1E
- background: #F5F3EE
- text: #1A1A1A
- spacing-base: 16
- radius-md: 8
```

---

# MCP Tools Available

When Claude Code connects to Pencil via MCP, these tools are available:

```
batch_design       Create, modify, and manipulate elements
                   Supports: insert, copy, update, replace, move, delete
                   Can generate and place images

batch_get          Read components and hierarchy
                   Search for elements by pattern
                   Inspect component structure

get_screenshot     Render design preview (base64)
                   Use to verify output after changes

snapshot_layout    Analyze layout structure
                   Detect positioning issues and overlaps

get_editor_state   Current editor context, selection, active file

get_variables      Read design tokens and variables
set_variables      Update variables, sync with CSS
```

**Read before writing.** Use `batch_get` and `snapshot_layout` before making structural changes.

---

# Workflow: Agent-Driven Design

The primary Pencil workflow for Claude Code:

**Single agent:**
```bash
claude 'Design a pricing section in design.pen with three tiers.
Use the Lunarus design system. Apply primary color to the recommended tier.
use the pencil mcp server'
```

**Key prompt pattern:** always end with `use the pencil mcp server` when running from terminal. This signals Claude Code to route through MCP rather than generate static code.

**Swarm mode (multiple agents simultaneously):**
Up to six agents can work on the same canvas. Each takes a different frame:
```bash
claude 'Design a complete landing page in design.pen.
Agent 1: hero section
Agent 2: features grid  
Agent 3: pricing section
Agent 4: testimonials
Agent 5: footer
Work in parallel using the pencil mcp server'
```

Each agent works on its assigned frame independently. You'll see them building simultaneously in the canvas. This is the primary speed advantage over single-agent tools.

---

# Workflow: Design to Code

After the canvas is built, generate code from it:

**From Claude Code in VS Code/Cursor:**
```
Inspect the 'Dashboard Main' frame in design.pen.
Generate a React component using Tailwind CSS.
Match exact padding, margin, font-weight, and border-radius from the design.
The 'Container' layer should be flex-col on mobile and flex-row on desktop.
Replace vector icons with lucide-react equivalents.
```

**What MCP provides to Claude Code:**
- Exact layer names (which become class names)
- Precise CSS values (not approximations)
- Layout hierarchy
- Variable bindings (tokens)

The result is pixel-matched output because Claude Code reads the underlying JSON -- not a screenshot.

**Verification step:** Screenshot the rendered code, paste it back into Pencil at 50% opacity over the original frame. Misalignments are immediately visible.

---

# Workflow: Figma to Pencil

Copy from Figma → paste into Pencil. Preserves layers and styles within ~1-4px tolerance. Use this to bring existing Figma work into a code-adjacent workflow.

**What transfers:**
- Layer structure and hierarchy
- Fill colors and strokes
- Typography (if fonts are installed locally)
- Spacing values
- Border radius

**What doesn't:**
- Figma components (come through as flattened groups)
- Variable bindings (need to be re-applied)
- Interactive prototypes

After pasting from Figma, run:
```
Inspect the pasted frames in design.pen.
Apply matching variables from our design system for all fills and spacing.
Rename all layers to semantic names based on their content.
```

---

# Design Libraries

Pencil ships with pre-configured design systems. Use these as the starting point rather than building from scratch for standard UI:

- **Shadcn UI** -- Tailwind-based, component-heavy
- **Lunarus** -- clean, modern, full token system
- **Halo** -- minimal, editorial
- **Nitro** -- bold, high-contrast

Load a library:
```
Load the Lunarus design library and use it for all components in design.pen.
```

When using a library, agent-generated components use the library's existing styles and tokens. "A button" becomes a Lunarus button with the correct tokens, states, and variants -- not a generic rectangle.

**For custom design systems:**
Create `design-system.pen` with your tokens and components. Reference it in agent prompts:
```
Follow the design system defined in design-system.pen for all components.
```

---

# Variables (Design Tokens)

Pencil variables sync with CSS custom properties. They're the bridge between design and code.

**Create tokens matching the codebase:**
Read `~/.claude/skills/apple.md`, `~/.claude/skills/android.md`, or `~/.claude/skills/web.md` first to get existing token names, then:

```
Create Pencil variables matching the token architecture in this project.
Use get_variables to check what exists, then add any missing tokens.
Token names must match exactly: color-semantic-background-primary, not background.
```

**Sync from CSS:**
```
Read src/styles/tokens.css and sync all custom properties as Pencil variables.
```

**Sync back to CSS:**
```
Export the current Pencil variables as a CSS custom properties file at src/styles/tokens.css.
```

---

# Layer Naming Rules

Layer names become class names and component names in generated code. Name everything before exporting.

**Bad names (generate bad code):**
- Rectangle 4
- Frame 12
- Group
- Layer

**Good names (generate good code):**
- pricing-card
- nav-item-active
- hero-headline
- feature-icon-container

```
Rename all layers in the selected frame to semantic names based on their content and purpose.
```

Run this before every code export. The quality difference is significant.

---

# No Empty Frames

Same rule as Figma and Sketch. Create frames when you're ready to populate them.

**Minimum screen set per platform:**
- Authentication (login, signup, forgot password)
- Home/main (default + loading + empty + error)
- Detail view
- Settings/profile
- Navigation shell

Each screen in light and dark mode. Variables make this automatic -- flip the theme variable and all bound elements update.

---

# Git Workflow

`.pen` files are JSON. They belong in Git alongside the code they describe.

```bash
# After design work
git add design.pen src/components/
git commit -m "feat: add pricing section design and implementation"
```

**Branching pattern:**
```bash
# New feature
git checkout -b feature/checkout-flow
# Build designs in checkout.pen
# Build code from designs
git commit -m "feat: checkout flow design and components"
# Merge when ready
```

Design history is code history. `git diff design.pen` shows exactly what changed.

**Practical commit point:** after the agent finishes a frame and you've verified the output. Don't commit mid-agent-session.

---

# Anti-Patterns

**No hardcoded values.** Any fill, spacing, or radius that isn't bound to a variable will drift from the codebase. After an agent builds something, use `get_variables` to audit bindings and fix any hardcoded values.

**Don't start from scratch every session.** Load existing `.pen` files, not blank canvases. All work builds on previous work, in the same file, committed to Git.

**Don't skip the read step.** `batch_get` and `snapshot_layout` before making changes. Agents writing blindly into unknown canvas state produce broken layouts.

**Don't use generic library components without checking tokens.** If the project has its own token system, apply it to library components. A Lunarus button using Lunarus tokens in a project with a custom color system is a mismatch. Sync the variables first.

---

# Limitations

**Early access rough edges:**
- Auto-save issues reported -- save manually frequently (`Cmd/Ctrl + S`)
- Config.toml may be modified or duplicated by Pencil -- backup before first use
- Alignment discrepancies of 4-8px in complex three-column responsive layouts
- `codex config.toml` modification issue is acknowledged and under investigation

**Design scope:**
- Frontend/UI only -- no backend logic
- Responsive requires explicit breakpoint frames
- No advanced prototyping or interactions (yet)
- Pencil itself is free; LLM costs (Claude API) are on you

**Code output:**
- HTML/React/Tailwind -- not SwiftUI, not Compose
- For native platform output from Pencil designs, export the design tokens and use them in the native codebase. The canvas itself is web-first.

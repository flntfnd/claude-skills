# pencil.md
Pencil design workflow. pencil.dev — AI-native, IDE-embedded, Git-native.
Design files (`.pen`) live in your repo. Claude Code reads the canvas via MCP.

Current state: early access. Free as of April 2026 — Pencil itself costs nothing, but AI features depend on Claude Code, which has its own subscription. Check pencil.dev for current access status.

---

# What Pencil Is

Pencil is a design tool that lives inside your IDE (VS Code, Cursor) or as a standalone desktop app. Design files are `.pen` files — JSON, in your Git repo, alongside the code they describe. The canvas isn't a separate tool. It's another file in the project.

Key differences from Figma and Paper:
- `.pen` files are JSON, human-readable, diffable, version-controlled
- Design lives in the repo, not in a cloud account
- The canvas is your IDE, not a separate app (though desktop is also an option)
- MCP gives Claude Code direct read/write access
- Local-first and single-user — no real-time multiplayer (Paper has that lane)
- AI runs through Claude Code, not Pencil itself

[Inference] from third-party reviews, multiple agents can work on the same canvas simultaneously when you launch parallel Claude Code sessions. The official docs don't put a firm number on this; treat it as "agent parallelism via your shell, not a built-in swarm feature."

---

# STEP 0 — Installation

## VS Code / Cursor extension

1. Extensions panel → search "Pencil" → Install
2. Create or open a `.pen` file (e.g. `test.pen`)
3. Look for the Pencil icon in the top-right of the editor (or status bar bottom-left in some builds)
4. If the icon doesn't appear: Command Palette → "Pencil" to find available commands. Restart the IDE if needed.

## Desktop app

Download `.dmg` (macOS), `.deb` or `.AppImage` (Linux), or the Windows installer from pencil.dev. macOS may require right-click → Open on first launch for unsigned-app verification.

Linux note: Wayland/Hyprland environments have known UI issues. X11 is more stable.

## Activation

1. Sign up at pencil.dev with email
2. Receive activation code, enter it in Pencil

## Claude Code dependency

Pencil's AI features depend on Claude Code being installed and authenticated separately. This is non-obvious and trips people up.

```bash
# Install Claude Code CLI (if not already)
npm install -g @anthropic-ai/claude-code-cli
# or
curl https://claude.ai/cli/install.sh | sh

# Authenticate
claude
# Follow the browser auth flow

# Verify
claude --version
```

If you see "Invalid API key" or "Please run /login" inside Pencil, this step is the cause. Check for conflicting auth (environment keys, custom providers) if a fresh `claude` login doesn't fix it.

---

# STEP 1 — MCP setup

The Pencil MCP server starts automatically when Pencil is running (extension or desktop). No manual configuration needed.

**Verify in Cursor:** Settings → Tools & MCP → Pencil should appear in the server list.

**Verify in Claude Code CLI:**
```bash
claude
/mcp
```
Pencil should appear as connected.

**Verify in Codex:** run Pencil first, then `/mcp` in Codex.

If MCP doesn't appear: restart both Pencil and the host. Long-running sessions are the most common failure mode.

---

# STEP 2 — Create a .pen file

In your project directory:
```
New File → name it design.pen
```

The Pencil editor opens inside VS Code/Cursor. The file is JSON tracking every element on the canvas.

**Naming conventions:**
- `design.pen` — main file for a project
- `dashboard.pen`, `landing.pen`, `checkout.pen` — screen or feature-specific files
- `design-system.lib.pen` — see the Design Libraries section below; the `.lib.pen` suffix is required for files marked as libraries

Multiple `.pen` files per repo is correct. One per major section, or one shared design library + per-screen files.

**First session:** right-click the canvas → Open Welcome File. Useful for orientation.

---

# STEP 3 — Design style

Before adding elements, read `~/.claude/skills/styles.md` for the project's visual style and `~/.claude/skills/color.md` for the palette.

In Pencil, set up the design style by establishing variables first — colors, spacing, typography. Variables are the foundation everything else binds to.

```
Set up design variables in design.pen:
- primary: #D52B1E
- background: #F5F3EE
- text: #1A1A1A
- spacing-base: 16
- radius-md: 8
```

Pencil colors are hex sRGB. Unlike Paper, no native OKLCH or P3 support. If color.md specifies P3 colors, use the sRGB equivalent in Pencil and note the gap.

---

# Variables

Variables work like CSS custom properties. Define HEX for colors, numbers for spacing/radius/sizes, strings for fonts. Change a variable, every binding updates.

## Creating variables

Three paths:

1. **Manually** — Variables icon in the toolbar → open the panel → define values.
2. **From CSS** — ask the agent: "Read `src/styles/globals.css` and create matching variables in this Pencil file." It extracts colors, spacing, fonts automatically.
3. **From Figma** — paste a screenshot of the Figma variables table and ask the agent to set them up. Or copy individual token values one at a time.

## Theme columns

The variables panel supports columns. Add a column for "dark" alongside "default" (or "light"). Switch themes in the properties panel to preview how designs adapt. This is how light/dark mode works in Pencil today.

Token names must match the codebase. If Swift uses `Color.Semantic.Background.primary`, the Pencil variable is `--color-semantic-background-primary`. Read `~/.claude/skills/apple.md`, `~/.claude/skills/android.md`, or `~/.claude/skills/web.md` first for existing token architecture.

## Sync with code

```
Read src/styles/tokens.css and sync all custom properties as Pencil variables.
```

```
Export current Pencil variables as a CSS custom properties file at src/styles/tokens.css.
```

Two-way sync. Run periodically to prevent drift between design and code.

---

# Components

Pencil has a real component system, not just symbols.

## Create a component

1. Select the element (frame, shape, text — anything)
2. Press **Cmd/Ctrl + Option/Alt + K**, or click "Create component" at the top of the properties panel
3. The element is now a component origin — marked with a **magenta bounding box** when selected

Nested components work. Build atoms first, then compose.

## Use a component

Copy the component origin on the canvas to create an instance. Instances are marked with a **violet bounding box** when selected.

The properties panel shows a "Go to component" button on instances — jumps back to the origin.

---

# Slots

Slots are designated drop zones inside components. Define a flexible region; let other elements (or AI agents) populate it.

## Create a slot

1. Create a frame and turn it into a component (Cmd/Ctrl + Option/Alt + K)
2. Style it
3. Click "Make a slot" at the top of the properties panel

Only empty frames in component origins can be turned into slots. Slots are marked with diagonal lines on the canvas.

## Suggested slot components

Tell Pencil (and the agent) what belongs in a slot. A `table` component's slot can suggest `table-row` as the intended content.

1. Select the layer with a slot in the component origin
2. Click `+` on the "Slots" line at the top of the properties panel
3. Pick the components you want to suggest

This is critical for AI-driven design. Suggested slot components are how you tell the agent "when populating this `table`, the contents should be `table-row` instances," without having to repeat it in every prompt.

## Drop into slots

Create an instance of the component, then drag/drop or paste an element into the slot region.

---

# Design Libraries

Any `.pen` file can become a reusable component library. Library files are imported into other `.pen` files. Edits to a library component propagate to every file that uses it.

## Create a library

1. Create a new `.pen` file
2. Populate it with components
3. Layers panel (left) → Libraries icon → "Turn this file into a library" at the bottom

The file is renamed with a `.lib.pen` suffix. **Once a file is marked as a library, it cannot be undone.** Be intentional.

## Import a library

1. Layers panel → Libraries icon
2. Pick the library to import — built-in libraries (Shadcn UI, Halo, Lunaris [or Lunarus, name varies in docs], Nitro) are also listed here

## Use library assets

1. Layers panel → Assets icon
2. Scroll the grid or search by name
3. Drag/drop or click to place onto the canvas

For custom design systems: build everything in `design-system.lib.pen`, import into per-screen files. Updates to the library push to every consumer.

---

# MCP Tools (overview)

[Inference] from third-party reviews and DevelopersIO documentation. Pencil doesn't publish a complete tool reference the way Paper does, so treat this list as approximate.

```
batch_design       Create, modify, manipulate elements
                   Operations: insert, copy, update, replace, move, delete
                   Image generation and placement
batch_get          Read components and hierarchy
                   Search by pattern, inspect structure
get_screenshot     Render design preview (base64)
snapshot_layout    Analyze layout, detect overlaps
get_editor_state   Current editor context, selection, active file
get_variables      Read tokens
set_variables      Update tokens, sync with CSS
```

For most agent prompts you don't call these directly. The agent picks them.

**Read before writing.** `batch_get` and `snapshot_layout` before structural changes.

---

# Workflow: Agent-driven design

## Single agent

In Claude Code, with Pencil open:

```bash
claude 'Design a pricing section in design.pen with three tiers.
Use the Lunaris design library. Apply primary color to the recommended tier.
use the pencil mcp server'
```

Always end with `use the pencil mcp server` when running from the terminal. This signals the agent to route through MCP rather than generating static code.

## In-canvas prompting

Press **Cmd/Ctrl + K** anywhere in Pencil to open the prompt input. Faster than alt-tabbing to a terminal for small changes.

## Multiple agents (informal swarm)

Launch parallel Claude Code sessions, each scoped to a different frame. They write to the same `.pen` file independently. Useful for landing pages where the agent budget is "one section per session."

```bash
# Terminal 1
claude 'In design.pen, build the hero section. use the pencil mcp server'

# Terminal 2
claude 'In design.pen, build the features grid. use the pencil mcp server'

# etc.
```

[Inference] Some users report 4-5 agents working concurrently without conflict. The hard upper bound isn't documented — depends on your machine and Claude Code rate limits.

---

# Workflow: Design to code

Once the canvas is built, generate code from it.

```
Inspect the 'Dashboard Main' frame in design.pen.
Generate a React component using Tailwind CSS.
Match exact padding, margin, font-weight, and border-radius from the design.
The 'Container' layer should be flex-col on mobile and flex-row on desktop.
Replace vector icons with lucide-react equivalents.
```

What MCP gives the agent:
- Exact layer names → class names
- Precise CSS values, not approximations
- Layout hierarchy
- Variable bindings (tokens)

Code targets supported via Pencil's design-to-code workflow include React, Next.js, Vue, Svelte, and plain HTML/CSS. Native targets (SwiftUI, Compose, WinUI) are not first-class — for native platforms, export the design tokens and apply them in the native codebase. The canvas itself is web-first.

## Pixel-perfect verification

The trick that works:

1. Run the generated code locally
2. Screenshot the rendered output
3. Paste it back into Pencil at 50% opacity over the original frame
4. Drift becomes immediately visible

Browsers render text slightly differently than vector tools, so 1-2px text drift is normal. Anything larger means the agent missed a value.

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
- Complex Auto Layout configurations may need manual adjustment

After pasting:

```
Inspect the pasted frames in design.pen.
Apply matching variables from our design library for all fills and spacing.
Rename all layers to semantic names based on their content.
```

For shipping, you typically want frames using your own variables and components, not detached imported geometry.

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

Run before every code export. The quality difference is significant.

---

# No Empty Frames

Same rule as Figma, Sketch, and Paper. Frames exist when populated.

**Minimum screen set per platform:**
- Authentication (login, signup, forgot password)
- Home/main (default + loading + empty + error)
- Detail view
- Settings/profile
- Navigation shell

Each screen in light and dark mode. Variable theme columns make this automatic — flip the theme column and bound elements update.

---

# Git workflow

`.pen` files are JSON. They belong in Git alongside the code they describe.

```bash
# After design work
git add design.pen src/components/
git commit -m "feat: add pricing section design and implementation"
```

**Branching:**

```bash
git checkout -b feature/checkout-flow
# Build designs in checkout.pen
# Build code from designs
git commit -m "feat: checkout flow design and components"
# Merge when ready
```

Design history is code history. `git diff design.pen` shows exactly what changed.

**Commit point:** after the agent finishes a frame and you've verified the output. Don't commit mid-agent-session — partial state in JSON can be hard to interpret in a diff.

**Auto-save warning:** auto-save issues have been reported in early access. Save manually frequently (`Cmd/Ctrl + S`).

**Codex/config.toml caveat:** Pencil has a documented issue where it may modify or duplicate `config.toml` files in the workspace. Back up before first use in an existing project.

---

# Pencil CLI

For headless `.pen` operations (CI, batch processing, scripted analysis):

```bash
# [Unverified] specifics — check docs.pencil.dev/for-developers/pencil-cli
```

Useful for design-system audit pipelines and pre-commit hooks. Probably overkill for individual design work.

---

# Anti-patterns

**No hardcoded values.** Any fill, spacing, or radius not bound to a variable will drift from the codebase. After the agent builds something, audit bindings and fix any hardcoded values.

**Don't start from scratch every session.** Load existing `.pen` files. All work builds on previous work, in the same file, committed to Git.

**Don't skip the read step.** `batch_get` and `snapshot_layout` before changes. Agents writing blindly into unknown canvas state produce broken layouts.

**Don't use generic library components without checking tokens.** A Lunaris button using Lunaris tokens in a project with a custom color system is a mismatch. Sync the variables first, or apply your variables to library components after dropping them in.

**Don't commit mid-agent-session.** Partial JSON state is hard to diff and harder to roll back.

**Don't expect Paper-style multiplayer.** Pencil is local and single-user. If you need real-time co-design with another human, that's Paper's lane.

---

# Limitations

**Early-access rough edges:**
- Auto-save issues — save manually
- `config.toml` may be modified or duplicated by Pencil — back up before first use
- Alignment discrepancies of 4-8px in complex three-column responsive layouts
- Wayland/Hyprland UI issues on Linux — use X11 if possible

**Design scope:**
- Frontend/UI only — no backend logic
- Responsive requires explicit breakpoint frames
- No advanced prototyping or interactions yet
- No native real-time multiplayer (use Git for async collaboration)
- Pencil itself is free; LLM costs (Claude Code subscription) are on you

**Code output:**
- Web frameworks: React, Next.js, Vue, Svelte, plain HTML/CSS
- Tailwind support is solid
- Native (SwiftUI, Compose, WinUI) is not a first-class target — export tokens, build natively

**Color:**
- Hex sRGB only. No OKLCH, no P3. If color.md specifies P3, use sRGB equivalents and note the gap.

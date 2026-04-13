# claude-skills

A personal set of Claude Code skill files and a global CLAUDE.md built up over time to stop repeating myself. These files tell Claude Code how I work, what stack I use, what platforms I build for, and what good output looks like for each one.

If you build native apps, design in Figma or Sketch, or work across multiple platforms, you might find something useful here. Fork it, strip out what doesn't apply, and make it yours.

---

## What's in here

### `CLAUDE.md`

The global config file. Goes at `~/.claude/CLAUDE.md` so it applies to every Claude Code session. Covers:

- Stack lane rules (Vercel / Railway / Supabase and what belongs in each)
- Platform targets (iOS/iPadOS/macOS 26+, Android current stable, evergreen web)
- Code generation rules (research before building, no legacy patterns, write it right the first time)
- UI architecture (no hardcoded values, tokens everywhere)
- Custom views and animation philosophy
- Design fidelity (Figma-first, Claude implements not designs)
- Privacy defaults
- Audio thread rules for DSP work
- Rust conventions
- Testing philosophy
- Commit format
- Skills routing (which file to read for which task)
- General behavior rules

### `AUDIT.md`

Checklists for code and UI audits. When asked to audit anything, Claude reads this first. Covers dead code, memory leaks, security, error handling, performance, deprecated APIs, and UI-specific checks including hardcoded values, design system coherence, and custom vs stock components.

### `APPLE.md`

Native Apple platform development. iOS 26 / iPadOS 26 / macOS Tahoe 26. SwiftUI only; no UIKit unless explicitly required.

Covers Liquid Glass (full native implementation with the correct API, parameters, and every known gotcha), SwiftUI semantic colors and custom token patterns, SF Pro variable font, spring animation tokens, NavigationStack / TabView / Sheet patterns, haptics, Reduce Motion, and performance.

### `ANDROID.md`

Native Android development. Jetpack Compose, Material 3 Expressive, current stable release.

Covers the M3E color role system, Roboto Flex variable font with weight animation, the spring-based MotionScheme (standard vs expressive), adaptive navigation that shifts between bottom bar / nav rail / drawer by window size, new M3E components (LoadingIndicator, ButtonGroup, FloatingToolbar), edge-to-edge, haptics, and recomposition performance.

### `WINDOWS.md`

Native Windows development. WinUI 3 via Windows App SDK 1.8+. C# with XAML.

Covers the Mica / Acrylic material system with correct surface assignments (most developers get this backwards), semantic ThemeResource brushes, Segoe UI Variable, Composition API animations, NavigationView adaptive modes, full XAML + C# for every control, x:Bind, AdaptiveTrigger for responsive layout, DPI scaling, Narrator / high contrast accessibility, and the XamlRoot ContentDialog gotcha.

### `FIGMA.md`

Figma design system workflow. Current as of 2026.

Covers the three-tier token architecture (primitive / semantic / component), variable collections and modes, platform token name mapping (Figma names to SwiftUI / Compose / CSS equivalents), typography variables, Auto Layout, component architecture with Slots, interactive components for prototyping, variable-driven prototypes with conditionals, Liquid Glass in Figma (with every failure mode documented), building from scratch vs replicating an existing app, and dev handoff. Uses the Figma MCP server.

### `SKETCH.md`

Sketch design system workflow plus style implementations for all 14 visual styles.

Covers the Sketch MCP server setup, Symbols vs Figma Components (full terminology map), Color Variables, Tokens Studio for non-color tokens, Smart Layout, Libraries, manual glass technique (Sketch has no native glass effect), building and replicating workflows, and dev handoff. The Sketch-specific implementation for every design style in STYLES.md is at the bottom of this file.

### `STYLES.md`

Visual design language specifications for all platforms. 14 styles, each with token values, component rules, and native implementation for iOS/SwiftUI, Android/Compose, and Web/CSS.

Styles covered: Neo-Minimalism, Neo-Brutalism, Brutalism (Pure), Liquid Glass, Glassmorphism/Frosted, Neumorphism/Soft UI, Kinetic Typography, Futuristic/Sci-Fi, Bento Grid, Editorial/Structural, Organic/Biomorphic, Texture/Tactile, Y2K/Retro Computing, Calm/Anti-Distraction.

Cross-style rules at the bottom enforce that no style overrides platform conventions, accessibility requirements, dark mode, or state coverage.

---

## Setup

### Global config

```bash
cp CLAUDE.md ~/.claude/CLAUDE.md
```

### Skill files

```bash
mkdir -p ~/.claude/skills
cp AUDIT.md APPLE.md ANDROID.md WINDOWS.md FIGMA.md SKETCH.md STYLES.md ~/.claude/skills/
```

That's it. Claude Code reads CLAUDE.md automatically for every session. Skill files are loaded on demand based on the task context defined in the Skills section of CLAUDE.md.

---

## How the skills routing works

The Skills section in CLAUDE.md tells Claude Code which file to read before starting each type of task:

```
When working on Apple platform UI → read APPLE.md
When working on Android UI → read ANDROID.md
When working on Windows / WinUI 3 → read WINDOWS.md
When working in Sketch → read SKETCH.md
When building or auditing a Figma design system → read FIGMA.md + STYLES.md
When asked to audit anything → read AUDIT.md
```

Skills are loaded on demand, not all at once, so they don't burn context on irrelevant content.

---

## My stack

- **Frontend**: Vercel (Next.js, SSR, edge middleware)
- **Backend**: Railway (API servers, workers, long-running processes)
- **Data/Auth**: Supabase (Postgres, Auth, RLS, Realtime, Storage)
- **Native**: SwiftUI (iOS/iPadOS/macOS), Jetpack Compose (Android), WinUI 3 (Windows)
- **Design**: Figma (primary), Sketch
- **Languages**: Swift, Kotlin, C#, TypeScript, Rust

If your stack is different, update the Lane Rules section in CLAUDE.md. Everything else transfers without changes.

---

## Things worth noting

**CLAUDE.md is opinionated.** It reflects how I actually work. The "write it correctly the first time" and "don't generate code you'd flag in an audit" rules sound obvious but make a real difference in output quality when stated explicitly.

**Platform targets are pinned.** iOS 26+, Android current stable, WinUI 3 / Windows App SDK 1.8+. If you need to support older versions, update the Platform Targets section.

**Design fidelity rule is firm.** Claude implements designs, it doesn't invent them. If a layout detail isn't specified, it asks rather than guessing. This matters a lot in practice; the default behavior is to fill gaps with whatever looks plausible, which creates inconsistency you then have to clean up.

**Liquid Glass has failure modes.** FIGMA.md documents every way the glass effect fails silently in Figma (fill at 100% opacity, background blur conflict, wrong layer order). Saved me a lot of debugging.

**Sketch and Figma are separate workflows.** They have different concepts and SKETCH.md doesn't assume you know Figma. STYLES.md covers visual styles for all platforms in one place; SKETCH.md adds Sketch-specific implementation notes at the bottom.

---

## Contributing

This is a personal config, not a framework. I'm not looking for PRs that change the opinions in CLAUDE.md; those reflect my specific setup and workflow. But if you find a factual error in the platform specs (wrong API, outdated behavior, missing gotcha), open an issue and I'll look at it.

---

## License

MIT. Use it however you want.

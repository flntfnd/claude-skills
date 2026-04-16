# claude-skills

Claude Code skill files and a global CLAUDE.md. Built to stop re-explaining the same context in every session.

Fork it. Strip what doesn't apply. Make it yours.

---

## Structure

```
~/.claude/CLAUDE.md              global config, loads on every session
~/.claude/skills/apple.md        iOS / iPadOS / macOS  (SwiftUI)
~/.claude/skills/android.md      Android               (Jetpack Compose)
~/.claude/skills/windows.md      Windows               (WinUI 3)
~/.claude/skills/web.md          Web                   (Next.js / Astro)
~/.claude/skills/motion.md       animation             (all platforms)
~/.claude/skills/figma.md        Figma design systems
~/.claude/skills/sketch.md       Sketch design systems
~/.claude/skills/paper.md        Paper                 (paper.design)
~/.claude/skills/pencil.md       Pencil                (pencil.dev)
~/.claude/skills/styles.md       14 visual styles      (all platforms)
~/.claude/skills/color.md        curated color library (Swiss + Bauhaus + modernist)
~/.claude/skills/audit.md        audit checklists
```

---

## Files

### `CLAUDE.md`

Global config. Lives at `~/.claude/CLAUDE.md` and loads automatically on every session. Sets stack lane rules, platform targets, code standards, UI architecture, animation philosophy, design fidelity requirements, privacy defaults, audio thread rules, Rust conventions, and skill routing. Everything else in this repo assumes this file is loaded.

### `apple.md`

iOS 26 / iPadOS 26 / macOS Tahoe. SwiftUI only.

Platform Visual Signature section defines what "looks like Apple built it" -- and what doesn't. Full Liquid Glass implementation: material variants, GlassEffectContainer, morphing, button styles, GPU performance constraints, all three system accessibility adaptations. Custom rendering section: SwiftUI Canvas, TimelineView-driven animation, custom Animatable conformances, AttributedString rich typography, Metal shader modifiers. Spring animation token system, navigation patterns, haptics. Every known gotcha documented.

### `android.md`

Jetpack Compose, Material 3 Expressive, current stable.

Platform Visual Signature section defines what "looks like Google built it." Color role system, Roboto Flex variable font with weight animation, spring-based MotionScheme, adaptive navigation (bottom bar / rail / drawer by window size), M3E components. Custom rendering section: Compose Canvas with organic blob and waveform, AGSL shaders (chromatic aberration, noise/grain), RenderEffect chaining, AnnotatedString. Edge-to-edge, haptics, recomposition performance.

### `windows.md`

WinUI 3 via Windows App SDK 1.8+. C# with XAML.

Platform Visual Signature section defines what "looks like Microsoft built it" -- Mica background, NavigationView on the left, Segoe UI Variable. Mica / Acrylic material system with correct surface assignments (most developers get this backwards), Composition API with ExpressionAnimation for scroll-tied parallax, InteractionTracker for gesture physics. Custom rendering: Win2D canvas drawing, TurbulenceEffect for procedural grain, pointer input differentiation (mouse / touch / pen with pressure and tilt). Full testing checklist (DPI scales, window sizes, High Contrast, Narrator, keyboard-only).

### `web.md`

HTML5, CSS, TypeScript, Next.js App Router, Astro, Supabase integration.

Modern CSS (container queries, cascade layers, nesting, `:has()`, subgrid, scroll-driven animations). Next.js 15 Server/Client Components, Server Actions with typed discriminated union returns, Supabase stack integration with lane rules enforced in code (no `service_role` on Vercel, middleware session refresh, RLS as the security layer). Error handling patterns (error.tsx, not-found.tsx, useActionState, ErrorBoundary). Advanced visual techniques: CSS blend modes, clip-path, SVG animation and inline filters, Canvas 2D, custom cursor. Security headers, CSP, Zod validation, Baseline 2026 targets.

### `motion.md`

Cross-platform animation deep spec. Read before writing animation code on any platform.

Physics foundations, spring vs ease curve decision logic (springs for user-triggered, ease for system-triggered), duration scale (83ms–700ms), when not to animate. Per-platform: iOS/SwiftUI spring API, KeyframeAnimator, PhaseAnimator, `@Animatable`, `matchedGeometryEffect`; Android/Compose AnimationSpec, M3E MotionScheme, variable font animation; Windows SpringNaturalMotionAnimation, ConnectedAnimation; Web: CSS native (compositor thread), scroll-driven animations, GSAP (ScrollTrigger, SplitText, Flip, cleanup requirements), Lenis, Three.js + WebGL (scene construction, PBR materials, lighting, post-processing, style-specific shaders, particle systems). Cross-platform motion token table.

### `figma.md`

Figma design system workflow. Uses the Figma MCP server.

Three-tier token architecture, variable collections and modes, platform token name mapping (Figma to SwiftUI / Compose / CSS), component architecture with Slots, interactive prototype wiring (required -- not optional). Dark canvas, no-empty-pages, platform completeness, and minimum screen set are all enforced as hard prerequisites. Applying a style to existing designs workflow: restructure components first, then apply Figma effects (exact panel values for hard shadow, glass, neumorphism, glow), then update tokens. Building from scratch and replicating an existing app workflows.

### `sketch.md`

Sketch design system workflow. Uses the Sketch MCP server.

Symbols vs Figma Components terminology map, Color Variables, Tokens Studio for non-color tokens, Smart Layout, Libraries, manual glass technique (Sketch has no native glass). Same structural rules as figma.md: dark canvas first, populate pages before moving on, token names must mirror the codebase, all targeted platforms must have screens. Sketch-specific implementations for all 14 visual styles at the bottom.

### `paper.md`

Paper design workflow. paper.design -- open alpha as of 2026.

Paper is different: the canvas is HTML/CSS, not vectors. What you build IS what the browser renders. Two-way MCP -- agents read and write the canvas directly. Sections: MCP setup (Claude Code plugin install, tool reference), dark canvas, design-to-code workflow, code-to-design (token sync, real API content), Figma-to-Paper with specific transfer gotchas, native shader system (GLSL, video export), variables as CSS custom properties, no-empty-artboards rule, open alpha limitations. Style-specific CSS is applied directly -- no translation required.

### `pencil.md`

Pencil design workflow. pencil.dev -- early access as of 2026.

Pencil lives inside VS Code / Cursor. Design files are `.pen` JSON files that version-control alongside your code. MCP gives Claude Code direct read/write access to the canvas. Key feature: swarm mode -- up to six agents building simultaneously on one canvas. Sections: installation, `.pen` file conventions, all MCP tools, single-agent and swarm workflows, design-to-code with the exact terminal prompt pattern, Figma-to-Pencil fidelity notes, design libraries (Lunarus, Halo, Shadcn, Nitro), variable sync to/from CSS, layer naming rules (layer names become class names -- this matters), Git workflow, early access limitations.

### `styles.md`

14 visual design styles. Each has a Visual Signature (structural requirements + "Wrong if" checklist), Token Modifications, Component Rules, and platform implementation for iOS/SwiftUI, Android/Compose, and Web/CSS.

Neo-Minimalism, Neo-Brutalism, Brutalism (Pure), Liquid Glass, Glassmorphism/Frosted, Neumorphism/Soft UI (Claymorphism evolution), Kinetic Typography, Futuristic/Sci-Fi, Bento Grid, Editorial/Structural, Organic/Biomorphic, Texture/Tactile, Y2K/Retro Computing, Calm/Anti-Distraction.

Style-to-Technique Mapping at the bottom: every style mapped to the specific GPU/rendering technique that produces its signature effect on each platform. Futuristic needs `UnrealBloomPass`. Y2K needs the CRT shader. Glassmorphism needs a Three.js background to blur. Calm needs nothing -- deliberately.

### `color.md`

Curated color library. Read before specifying color primitives.

~50 named primitives from two sources: Swiss International Style poster work (Müller-Brockmann, Hofmann, Ballmer, Bill -- as systematized in Fabian Burghardt's Swiss Style Color Picker) and the Bauhaus primary triad (Itten's `#C8302A / #E8C018 / #1E3878`). Extended with mid-century modernist palette and contemporary screen-optimized variants. Full neutral ramps (warm and cool), semantic role mappings for light and dark mode, WCAG contrast table for all primary pairs (yellow on white fails -- documented). Color pairing logic from actual historical poster practice. TASTE.md overrides this once built.

### `audit.md`

Checklists for: code (dead code, memory leaks, security, error handling, performance, deprecated APIs), UI (hardcoded values, design system coherence, responsive logic, animation), audio thread (allocations, blocking calls, ObjC messaging, cross-thread comms), security (key exposure, RLS, JWT, PII in logs), design files (canvas background, empty pages, token population, token naming vs code, component completeness, interactive wiring, platform coverage, screen completeness), Rust (unwrap, error types, clones, unsafe), Rust toolchain (clippy -D warnings, cargo audit, cargo deny, cargo test).

---

## Setup

```bash
cp CLAUDE.md ~/.claude/CLAUDE.md
mkdir -p ~/.claude/skills
cp AUDIT.md   ~/.claude/skills/audit.md
cp APPLE.md   ~/.claude/skills/apple.md
cp ANDROID.md ~/.claude/skills/android.md
cp WINDOWS.md ~/.claude/skills/windows.md
cp FIGMA.md   ~/.claude/skills/figma.md
cp SKETCH.md  ~/.claude/skills/sketch.md
cp STYLES.md  ~/.claude/skills/styles.md
cp MOTION.md  ~/.claude/skills/motion.md
cp WEB.md     ~/.claude/skills/web.md
cp COLOR.md   ~/.claude/skills/color.md
cp paper.md   ~/.claude/skills/paper.md
cp pencil.md  ~/.claude/skills/pencil.md
```

CLAUDE.md loads automatically. Skill files are read on demand -- they don't burn context on irrelevant content.

---

## Routing

```
Apple platform UI            → apple.md
Android UI                   → android.md
Windows / WinUI 3            → windows.md
Web (HTML/CSS/TS/Next/Astro) → web.md
Motion or animation          → motion.md       (any platform)
Figma design system          → figma.md + styles.md
Sketch design system         → sketch.md
Paper (paper.design)         → paper.md
Pencil (pencil.dev)          → pencil.md
Project has a visual style   → styles.md
Color values needed          → color.md
Audit anything               → audit.md
```

---

## Stack

- **Frontend**: Vercel (Next.js, SSR, edge middleware)
- **Backend**: Railway (API servers, workers, long-running processes)
- **Data/Auth**: Supabase (Postgres, Auth, RLS, Realtime, Storage)
- **Native**: SwiftUI (iOS/iPadOS/macOS), Jetpack Compose (Android), WinUI 3 (Windows)
- **Design**: Figma (primary), Sketch, Paper, Pencil
- **Languages**: Swift, Kotlin, C#, TypeScript, Rust

Stack is defined in CLAUDE.md. If yours differs, update the Lane Rules section. Everything else transfers.

---

## Notes

CLAUDE.md is opinionated. "Write it correctly the first time" sounds obvious. Stating it explicitly changes the output.

Platform targets are pinned to current: iOS 26+, Android stable, Windows App SDK 1.8+. Update Platform Targets if you need older support.

Native-first by default. If no visual style is specified, iOS looks like Apple built it, Android looks like Google built it, Windows looks like Microsoft built it. styles.md styles are deliberate overrides of native conventions -- not defaults.

Design fidelity is non-negotiable. Claude implements designs, it doesn't invent them. Without this rule the default is to fill unspecified gaps with whatever looks plausible. That creates drift.

The design tool files all have hard enforcement rules: dark canvas first, no empty pages, tokens before components, components before screens, all targeted platforms populated. Every rule exists because the failure mode happened.

Paper and Pencil are both in early access. Paper (paper.design) is an HTML/CSS canvas with bidirectional MCP -- what you design is what ships. Pencil (pencil.dev) puts .pen files in your Git repo alongside code and supports six concurrent agents on one canvas. Both are worth watching; check their changelogs before any serious session.

The color library (color.md) is a foundation. Once the taste extraction sessions are done, TASTE.md will override it with actual personal preference.

---

## Contributing

Personal config, not a framework. PRs that change the opinions in CLAUDE.md aren't what this is for. If you find a factual error in a platform spec -- wrong API, stale version, missing gotcha -- open an issue.

---

## License

MIT.

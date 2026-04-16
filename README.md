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
~/.claude/skills/rust.md         Rust                  (services, CLIs, audio, FFI)
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

Platform Visual Signature section defines what "looks like Apple built it" and what doesn't. Full Liquid Glass implementation: material variants, GlassEffectContainer, morphing, button styles, GPU performance constraints, all three system accessibility adaptations. Custom rendering section: SwiftUI Canvas, TimelineView-driven animation, custom Animatable conformances, AttributedString rich typography, Metal shader modifiers. Spring animation token system, navigation patterns, haptics. Every known gotcha documented.

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

### `rust.md`

Rust 2024 edition (stable since Rust 1.85). Services, CLIs, libraries, audio, FFI.

Extends the floor rules in CLAUDE.md (no `unwrap()` outside throwaway code, `thiserror` for libraries, `anyhow` for applications, no `clone()` to dodge the borrow checker, `// SAFETY:` comments on every `unsafe`) with operational detail. Edition and toolchain pinning, CI gates (`cargo fmt --check`, `cargo clippy -D warnings`, `cargo audit`, `cargo deny check`, `cargo nextest`). Error handling patterns with proper source chains. Async discipline: Tokio runtime setup, async closures, cancellation safety with Drop guards, send bounds, when to `spawn_blocking`, structured concurrency, bounded channels. Web stack: axum 0.8 with `{id}` path syntax, sqlx with compile-time checks, Tower middleware, `IntoResponse` errors, graceful shutdown. Observability via `tracing` with `#[instrument]` and structured JSON. Concurrency primitives (channels, locks, atomics, `LazyLock`). Audio thread rules (`rtrb`, `ringbuf-basedrop`, `assert_no_alloc`, `basedrop::Shared` over `Arc`). Testing with `#[sqlx::test]`, project structure (single crate vs workspace with `resolver = "3"`), performance discipline (string types, iterator chains, allocation awareness), FFI, WASM, documentation with doctests. Crate selection for ~30 categories with current best-of-class. 15 anti-patterns and a 12-item audit checklist that extends audit.md.

### `figma.md`

Figma design system workflow. Uses the Figma MCP server.

Three-tier token architecture, variable collections and modes, platform token name mapping (Figma to SwiftUI / Compose / CSS), component architecture with Slots, interactive prototype wiring (required -- not optional). Dark canvas, no-empty-pages, platform completeness, and minimum screen set are all enforced as hard prerequisites. Applying a style to existing designs workflow: restructure components first, then apply Figma effects (exact panel values for hard shadow, glass, neumorphism, glow), then update tokens. Building from scratch and replicating an existing app workflows.

### `sketch.md`

Sketch design system workflow. Uses the Sketch MCP server.

Symbols vs Figma Components terminology map, Color Variables, Tokens Studio for non-color tokens, Smart Layout, Libraries, manual glass technique (Sketch has no native glass). Same structural rules as figma.md: dark canvas first, populate pages before moving on, token names must mirror the codebase, all targeted platforms must have screens.

Sketch-specific implementations for all 14 visual styles at the bottom. Each style has a **Visual Signature in Sketch** section with structural requirements in Sketch terminology (Symbol Masters, Layer Styles, Color Variables, Borders panel, Tokens Studio tokens) and a **Wrong if (Sketch check)** checklist of auditable failure conditions. The pattern mirrors figma.md's structural requirements but uses Sketch's actual UI vocabulary.

### `paper.md`

Paper design workflow. paper.design. Paper Desktop with MCP launched March 2026.

Paper is different: the canvas is real HTML/CSS, not vectors. What you build IS what the browser renders. Two-way MCP -- agents read and write the canvas directly. Multiplayer web-native, share via URL. OKLCH and Display P3 color per element. Backdrop filters, CSS filters, variable fonts, OpenType features all first-class.

Sections: MCP setup for all supported IDEs (Claude Code, Cursor, Codex, Copilot, Antigravity, OpenCode) with exact config snippets. Full tool reference including `get_font_family_info`, `get_guide`, `find_placement`. Paper Snapshot browser extension for pasting sections of any live website as editable layers (replaces the screenshot-and-trace workflow). Workflows: design-to-code with React/Tailwind (`Alt+R`, `Alt+T` shortcuts), Figma import with transfer gotchas, Notion content sync, responsive via breakpoint frames. Shader system (Halftone CMYK, Fluted Glass, Liquid Metal, Pulsing Border, custom GLSL, video export). In-canvas AI image generation (Flux 2, Nano Banana Pro via Gemini 3, Seedream 4.5). Variables as CSS custom properties. Pixel-perfect verification via 50% opacity overlay. Roadmap statuses aligned to Paper's actual labels (done / in progress / coming soon / planned).

### `pencil.md`

Pencil design workflow. pencil.dev. Early access as of April 2026, free.

Pencil lives inside VS Code / Cursor or as a desktop app. Design files are `.pen` JSON that version-control alongside your code. MCP gives Claude Code direct read/write access. AI runs through Claude Code, not Pencil itself -- the Claude Code dependency is made explicit because users assume Pencil has its own LLM.

Sections: installation including the Claude Code auth step most people miss, MCP verification per host. Variables with theme columns for light/dark, sync to/from `globals.css`, extract from Figma via screenshot. Real component system: `Cmd/Ctrl + Option/Alt + K` creates a component origin (magenta bounding box); instances get violet boxes; "Go to component" navigates back. **Slots** with diagonal-line indicators and suggested slot components (the AI-relevant feature that tells the agent what belongs where). **Design Libraries** as `.lib.pen` files (irreversible once marked), import via Libraries icon. Design-to-code for React, Next.js, Vue, Svelte, plain HTML/CSS -- not native targets. Figma-to-Pencil paste workflow with transfer tolerances. Git workflow with design files as code. In-canvas `Cmd/Ctrl + K` prompting. Pixel-perfect verification via 50% opacity overlay. Early access caveats (auto-save issues, `config.toml` modification, Wayland UI issues on Linux).

### `styles.md`

14 visual design styles. Each has a Visual Signature (structural requirements + "Wrong if" checklist), Token Modifications, Component Rules, and platform implementation for iOS/SwiftUI, Android/Compose, and Web/CSS.

Neo-Minimalism, Neo-Brutalism, Brutalism (Pure), Liquid Glass, Glassmorphism/Frosted, Neumorphism/Soft UI (Claymorphism evolution), Kinetic Typography, Futuristic/Sci-Fi, Bento Grid, Editorial/Structural, Organic/Biomorphic, Texture/Tactile, Y2K/Retro Computing, Calm/Anti-Distraction.

Style-to-Technique Mapping at the bottom: every style mapped to the specific GPU/rendering technique that produces its signature effect on each platform. Futuristic needs `UnrealBloomPass`. Y2K needs the CRT shader. Glassmorphism needs a Three.js background to blur. Calm needs nothing -- deliberately.

### `color.md`

Curated color library. Read before specifying color primitives.

~50 named primitives from two sources: Swiss International Style poster work (Müller-Brockmann, Hofmann, Ballmer, Bill -- as systematized in Fabian Burghardt's Swiss Style Color Picker) and the Bauhaus primary triad (Itten's `#C8302A / #E8C018 / #1E3878`). Extended with mid-century modernist palette and contemporary screen-optimized variants. Full neutral ramps (warm and cool), semantic role mappings for light and dark mode, WCAG contrast table for all primary pairs (yellow on white fails -- documented). Color pairing logic from actual historical poster practice. TASTE.md overrides this once built.

### `audit.md`

Checklists for: code (dead code, memory leaks, security, error handling, performance, deprecated APIs), UI (hardcoded values, design system coherence, responsive logic, animation), audio thread (allocations, blocking calls, ObjC messaging, cross-thread comms), security (key exposure, RLS, JWT, PII in logs), design files (canvas background, empty pages, token population, token naming vs code, component completeness, interactive wiring, platform coverage, screen completeness), Rust (unwrap, error types, clones, unsafe), Rust toolchain (clippy -D warnings, cargo audit, cargo deny, cargo test).

rust.md adds a deeper, Rust-specific audit section that extends this one (edition, toolchain pinning, async rules, error type discipline, tracing, axum/sqlx hygiene, audio thread allocations, workspace consistency, profile settings).

---

## Setup

```
cp CLAUDE.md ~/.claude/CLAUDE.md
mkdir -p ~/.claude/skills
cp skills/audit.md   ~/.claude/skills/audit.md
cp skills/apple.md   ~/.claude/skills/apple.md
cp skills/android.md ~/.claude/skills/android.md
cp skills/windows.md ~/.claude/skills/windows.md
cp skills/figma.md   ~/.claude/skills/figma.md
cp skills/sketch.md  ~/.claude/skills/sketch.md
cp skills/styles.md  ~/.claude/skills/styles.md
cp skills/motion.md  ~/.claude/skills/motion.md
cp skills/web.md     ~/.claude/skills/web.md
cp skills/rust.md    ~/.claude/skills/rust.md
cp skills/color.md   ~/.claude/skills/color.md
cp skills/paper.md   ~/.claude/skills/paper.md
cp skills/pencil.md  ~/.claude/skills/pencil.md
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
Rust (any context)           → rust.md
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

* **Frontend**: Vercel (Next.js, SSR, edge middleware)
* **Backend**: Railway (API servers, workers, long-running processes)
* **Data/Auth**: Supabase (Postgres, Auth, RLS, Realtime, Storage)
* **Native**: SwiftUI (iOS/iPadOS/macOS), Jetpack Compose (Android), WinUI 3 (Windows)
* **Design**: Figma (primary), Sketch, Paper, Pencil
* **Languages**: Swift, Kotlin, C#, TypeScript, Rust

Stack is defined in CLAUDE.md. If yours differs, update the Lane Rules section. Everything else transfers.

---

## Notes

CLAUDE.md is opinionated. "Write it correctly the first time" sounds obvious. Stating it explicitly changes the output.

Platform targets are pinned to current: iOS 26+, Android stable, Windows App SDK 1.8+, Rust 1.85+ (2024 edition). Update Platform Targets if you need older support.

Native-first by default. If no visual style is specified, iOS looks like Apple built it, Android looks like Google built it, Windows looks like Microsoft built it. styles.md styles are deliberate overrides of native conventions -- not defaults.

Design fidelity is non-negotiable. Claude implements designs, it doesn't invent them. Without this rule the default is to fill unspecified gaps with whatever looks plausible. That creates drift.

The design tool files all have hard enforcement rules: dark canvas first, no empty pages, tokens before components, components before screens, all targeted platforms populated. Every rule exists because the failure mode happened.

Paper and Pencil are both in active development. Paper (paper.design) is an HTML/CSS canvas with bidirectional MCP across six different agent hosts, multiplayer web-native, OKLCH/P3 color, and a growing shader library. Paper Snapshot is a Chrome extension that pastes live site sections as editable layers. Pencil (pencil.dev) puts `.pen` files in your Git repo alongside code, has a real component system with slots, and depends on Claude Code for its AI features. Check their changelogs before any serious session -- both ship frequently.

rust.md is the newest file. It extends the brief Rust conventions in CLAUDE.md with operational detail: current edition, toolchain, CI gates, the default web stack (axum + sqlx + tracing), async cancellation safety, realtime audio discipline, and a 12-item audit checklist. Read it before writing Rust in any context.

The color library (color.md) is a foundation. Once the taste extraction sessions are done, TASTE.md will override it with actual personal preference.

---

## Contributing

Personal config, not a framework. PRs that change the opinions in CLAUDE.md aren't what this is for. If you find a factual error in a platform spec -- wrong API, stale version, missing gotcha -- open an issue.

---

## License

MIT.

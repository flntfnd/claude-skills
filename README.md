# claude-skills

Claude Code skill files and a global CLAUDE.md. Built to stop re-explaining the same context in every session.

Fork it. Strip what doesn't apply. Make it yours.

---

## Structure

- `~/.claude/CLAUDE.md` — global config, loads on every session
- `~/.claude/skills/apple.md` — iOS / iPadOS / macOS (SwiftUI)
- `~/.claude/skills/android.md` — Android (Jetpack Compose)
- `~/.claude/skills/windows.md` — Windows (WinUI 3)
- `~/.claude/skills/web.md` — Web (Next.js / Astro)
- `~/.claude/skills/motion.md` — animation, all platforms
- `~/.claude/skills/figma.md` — Figma design systems
- `~/.claude/skills/sketch.md` — Sketch design systems
- `~/.claude/skills/styles.md` — 14 visual styles, all platforms
- `~/.claude/skills/color.md` — curated color library (Swiss + Bauhaus + modernist)
- `~/.claude/skills/audit.md` — audit checklists

---

## Files

### `CLAUDE.md`

Global config. Lives at `~/.claude/CLAUDE.md` and loads automatically on every session. Sets stack lane rules, platform targets, code standards, UI architecture, animation philosophy, design fidelity requirements, privacy defaults, audio thread rules, Rust conventions, and skill routing. Everything else in this repo assumes this file is loaded.

### `APPLE.md`

iOS 26 / iPadOS 26 / macOS Tahoe. SwiftUI only.

Full Liquid Glass implementation: all material variants, GlassEffectContainer, morphing, button styles, performance constraints (GPU-intensive, don't apply inside lists or scroll areas), accessibility adaptations. SwiftUI semantic color system, spring animation tokens, navigation patterns, haptics. Every known gotcha documented.

### `ANDROID.md`

Jetpack Compose, Material 3 Expressive, current stable.

Color role system, Roboto Flex variable font with weight animation, spring-based MotionScheme, adaptive navigation (bottom bar / rail / drawer by window size), M3E components (LoadingIndicator, ButtonGroup, FloatingToolbar), edge-to-edge, haptics, recomposition performance.

### `WINDOWS.md`

WinUI 3 via Windows App SDK 1.8+. C# with XAML.

Mica / Acrylic material system with correct surface assignments -- most developers get this backwards. Semantic ThemeResource brushes, Segoe UI Variable, Composition API animations, NavigationView adaptive modes, DPI scaling, full accessibility checklist (High Contrast, Narrator, keyboard-only), XamlRoot ContentDialog requirement.

### `WEB.md`

HTML5, CSS, TypeScript, Next.js App Router, Astro, Supabase integration.

Modern CSS (container queries, cascade layers, nesting, `:has()`, subgrid, scroll-driven animations), Next.js 15 Server/Client Components, Server Actions with typed discriminated union returns, Supabase integration with stack lane rules enforced in code (no service_role on Vercel, middleware session refresh, RLS as the security layer), error handling patterns (error.tsx, not-found.tsx, useActionState, ErrorBoundary), security headers, CSP, Zod validation, Baseline 2026 targets.

### `FIGMA.md`

Figma design system workflow. Uses the Figma MCP server.

Three-tier token architecture, variable collections and modes, platform token name mapping (Figma to SwiftUI / Compose / CSS), component architecture with Slots, interactive prototype wiring requirements, Liquid Glass implementation with every failure mode documented, building from scratch vs replicating an existing codebase, dev handoff. Dark canvas setup, no-empty-pages rules, and platform completeness requirements are all enforced as hard prerequisites.

### `SKETCH.md`

Sketch design system workflow. Uses the Sketch MCP server.

Symbols vs Figma Components terminology map, Color Variables, Tokens Studio for non-color tokens, Smart Layout, Libraries, manual glass technique (Sketch has no native glass). Same structural rules as FIGMA.md: dark canvas first, populate pages before moving on, token names must mirror the codebase, all targeted platforms must have screens. Sketch-specific implementations for all 14 visual styles at the bottom.

### `STYLES.md`

14 visual design styles. Each has token modifications, component rules, and native implementation for iOS/SwiftUI, Android/Compose, and Web/CSS.

Neo-Minimalism, Neo-Brutalism, Brutalism (Pure), Liquid Glass, Glassmorphism/Frosted, Neumorphism/Soft UI (with Claymorphism evolution and WCAG failure mode), Kinetic Typography, Futuristic/Sci-Fi, Bento Grid (with CSS subgrid and source-order accessibility), Editorial/Structural, Organic/Biomorphic, Texture/Tactile, Y2K/Retro Computing, Calm/Anti-Distraction. Critical failure modes documented where the style has known accessibility or usability problems.

### `MOTION.md`

Cross-platform animation deep spec. Read before writing animation code on any platform.

Physics foundations, spring vs ease curve decision logic (springs for user-triggered, ease for system-triggered), duration scale (83ms-700ms), when not to animate. Per-platform: iOS/SwiftUI spring API, KeyframeAnimator, PhaseAnimator, `@Animatable`, `matchedGeometryEffect`; Android/Compose AnimationSpec, M3E MotionScheme, variable font animation; Windows SpringNaturalMotionAnimation, ConnectedAnimation; Web: CSS native (compositor thread), scroll-driven animations, GSAP (timeline, ScrollTrigger, SplitText, Flip, cleanup requirements), Lenis, Three.js + WebGL. Cross-platform motion token table.

### `COLOR.md`

Curated color library. Read before specifying any color primitive values -- prevents inventing hex values from nothing.

Two primary sources: the Swiss International Style / International Typographic Style (1950s–70s poster work by Müller-Brockmann, Hofmann, Ballmer, and Bill, as systematized in Fabian Burghardt's Swiss Style Color Picker), and the Bauhaus primary triad (Itten's `#C8302A / #E8C018 / #1E3878`). Extended with mid-century modernist palette and contemporary screen-optimized variants. ~50 named primitives across reds, blues, yellows, greens, neutrals, and accent ramps. Semantic role mappings for light and dark mode. WCAG contrast reference for all primary pairs. Color pairing logic from actual historical poster practice (yellow fails on white -- documented). TASTE.md overrides anything here once built.

### `AUDIT.md`

Audit checklists: code (dead code, memory leaks, security, error handling, performance, deprecated APIs), UI (hardcoded values, design system coherence, responsive logic, animation), audio thread (allocations, blocking calls, ObjC messaging, cross-thread comms), security (key exposure, RLS, JWT, PII in logs), design files (canvas background, empty pages, token population, token naming vs code, component completeness, interactive wiring, platform coverage, screen completeness), Rust (unwrap, error types, clones, unsafe blocks), Rust toolchain (clippy -D warnings, cargo audit, cargo deny, cargo test).

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
```

CLAUDE.md loads automatically. Skill files are read on demand -- they don't all load at once, so they don't burn context on irrelevant content.

---

## Routing

```
Apple platform UI            → APPLE.md
Android UI                   → ANDROID.md
Windows / WinUI 3            → WINDOWS.md
Web (HTML/CSS/TS/Next/Astro) → WEB.md
Motion or animation          → MOTION.md  (any platform)
Sketch                       → SKETCH.md
Figma design system          → FIGMA.md + STYLES.md
Project has a visual style   → STYLES.md
Color values needed          → COLOR.md
Audit anything               → AUDIT.md
```

---

## Stack

- **Frontend**: Vercel (Next.js, SSR, edge middleware)
- **Backend**: Railway (API servers, workers, long-running processes)
- **Data/Auth**: Supabase (Postgres, Auth, RLS, Realtime, Storage)
- **Native**: SwiftUI (iOS/iPadOS/macOS), Jetpack Compose (Android), WinUI 3 (Windows)
- **Design**: Figma (primary), Sketch
- **Languages**: Swift, Kotlin, C#, TypeScript, Rust

Stack is defined in CLAUDE.md. If yours is different, update the Lane Rules section. Everything else transfers.

---

## Notes

CLAUDE.md is opinionated and intentionally so. "Write it correctly the first time" sounds obvious. Stating it explicitly changes the output.

Platform targets are pinned to current: iOS 26+, Android stable, Windows App SDK 1.8+. Update Platform Targets if you need older support.

Design fidelity is non-negotiable. Claude implements designs, it doesn't invent them. Without an explicit rule, the default behavior is to fill unspecified gaps with whatever looks plausible. That creates drift you have to clean up.

The design tool files (FIGMA.md, SKETCH.md) have hard enforcement rules built in: dark canvas before anything else, no empty pages, tokens populate before components, components exist before screens, all targeted platforms must have screens. These rules exist because every one of them reflects a real failure mode from actual usage.

---

## Contributing

Personal config, not a framework. Not looking for PRs that change the opinions in CLAUDE.md. If you find a factual error in a platform spec (wrong API, outdated behavior, missing gotcha), open an issue.

---

## License

MIT.

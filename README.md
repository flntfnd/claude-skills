# claude-skills

Claude Code skills and a global CLAUDE.md. Built to stop re-explaining the same context in every session.

Fork it. Strip what doesn't apply. Make it yours.

> **August 2026: this repo moved off the old flat-file methodology entirely** and onto Anthropic's native Agent Skills format. It's not a refactor of the old approach -- it's a different mechanism for the same goal. The previous version (`CLAUDE.md` plus flat `skills/*.md` files, wired together with hand-written routing lines) is preserved as-is under [`_archive/`](_archive/) for reference. Nothing in `_archive/` is maintained going forward; the live system is everything below.

---

## Structure

```
CLAUDE.md                                    global config, loads on every session
skills/apple-platform/SKILL.md               iOS / iPadOS / macOS      (SwiftUI, Liquid Glass)
skills/android-platform/SKILL.md              Android                   (Jetpack Compose, M3 Expressive)
skills/windows-platform/SKILL.md              Windows                   (WinUI, Mica/Acrylic)
skills/web-platform/SKILL.md                  Web                       (Next.js, Astro, Supabase)
skills/motion-design/SKILL.md                 Animation                 (all platforms, GSAP, Three.js)
skills/rust-conventions/SKILL.md              Rust                      (services, CLIs, audio, FFI)
skills/backend-conventions/SKILL.md           Railway backend services  (bare API servers, workers, cron -- non-Next.js)
skills/figma-design-system/SKILL.md           Figma design systems
skills/sketch-design-system/SKILL.md          Sketch design systems
skills/pencil-design-workflow/SKILL.md        Pencil                    (pen.dev)
skills/design-tool-gates/SKILL.md             Shared design-tool policy (dark canvas, empty-page, token-naming, light/dark gates)
skills/visual-styles/SKILL.md                 14 visual styles          (all platforms)
skills/color-system/SKILL.md                  Curated color library     (Swiss + Bauhaus + modernist)
skills/code-audit/SKILL.md                    Audit checklists

_archive/                                     the pre-migration repo, frozen, not maintained
```

Each skill directory also holds `reference/*.md` files for anything too deep to keep in the top-level `SKILL.md` — API detail, per-style implementations, per-platform code. Claude reads those only when the task actually needs them.

---

## Why this changed shape

This repo used to be flat files (`APPLE.md`, `STYLES.md`, etc.) referenced by hand-written routing lines in `CLAUDE.md` — "when working on Apple UI, read apple.md before writing any view code." That predates Anthropic's Agent Skills format, and it wasn't a stylistic choice — it was the only mechanism that existed at the time. A skill was a file, and the only way Claude knew to read it was being told to, explicitly, every time. As of 2026 Claude Code discovers and loads skills on its own: every skill's `name` and `description` sit in context by default (a few hundred tokens each), and Claude reads the full `SKILL.md` — and whichever `reference/*.md` files it actually needs — only once a task matches. A 2,000-line file that used to cost the same whether you needed one paragraph of it or all of it now costs nothing until the relevant paragraph is read.

This isn't an incremental update to the old system. It's a full migration to a different mechanism, and the two don't coexist cleanly — a flat `skills/apple.md` and a `skills/apple-platform/SKILL.md` describing the same domain would just confuse discovery. So the old version was retired outright rather than patched in place. It's preserved under [`_archive/`](_archive/) exactly as it stood the day the migration started, for anyone who wants to see what the previous approach looked like or diff against it — but it's frozen, not a fallback. Everything actually maintained lives under `skills/` and `CLAUDE.md` at the repo root.

Two consequences that shaped the new structure:

- **The manual routing lines are gone.** They're redundant with the discovery mechanism and can actively fight it — if a skill isn't triggering when it should, the fix is a sharper `description`, not a `CLAUDE.md` line telling Claude to read it. `CLAUDE.md` now holds only what's true on every task regardless of what Claude decides is relevant: stack, lane rules, platform target pins, and floor-level code/UI/motion/privacy rules. That split — CLAUDE.md for facts, skills for procedures — is Anthropic's own stated criterion for when something belongs in a skill instead of CLAUDE.md.
- **Every file over ~500 lines got split.** `SKILL.md` is the table of contents; the detail moved into topic-scoped `reference/` files one level deep (`visual-styles`, for instance, went from one 1,567-line file to a 104-line `SKILL.md` plus 14 per-style reference files). This is the biggest single quality change in this pass, not just a reformat — it's the difference between Claude loading the whole Windows skill to answer a Mica question and loading only `reference/materials.md`.

---

## Skills

### `apple-platform`

iOS 26 / iPadOS 26 / macOS Tahoe 26 baseline, SwiftUI only. Full Liquid Glass API surface (`.glassEffect()`, `GlassEffectContainer`, morphing, button styles, GPU/performance rules), semantic color and typography tokens, HIG motion, navigation patterns, custom rendering (SwiftUI Canvas, `Animatable`, `AttributedString`, Metal shader modifiers), and accessibility. `reference/whats-new-ios27.md` tracks iOS 27's beta status in its own file so forward-looking, less-certain content never contaminates the stable reference.

### `android-platform`

Jetpack Compose, Material 3 Expressive, current stable Android. M3 color roles and dynamic color, Roboto Flex typography, shape morphing, spring-based `MotionScheme`, edge-to-edge (no opt-out as of Android 16), adaptive navigation via `currentWindowAdaptiveInfo()`, custom rendering (Compose Canvas, AGSL shaders, `RenderEffect`).

### `windows-platform`

Windows App SDK 2.x, WinUI (Microsoft dropped the "3" from the name in 2026 — kept as a recognized synonym since it's still near-universal in practice), C#/XAML. Mica/Acrylic material system with the surface-assignment rule most people get backwards, Composition API for scroll-tied parallax and gesture physics, Win2D drawing, and the full pre-ship accessibility testing checklist (High Contrast themes, Narrator, keyboard-only).

### `web-platform`

HTML5, modern CSS, TypeScript, Next.js App Router (Cache Components, `"use cache"`, `proxy.ts`), Astro (Content Layer API, Server Islands), and Supabase SSR integration with the Vercel/Railway lane rules enforced in actual code patterns. Advanced visual techniques (blend modes, clip-path, SVG, Canvas 2D), security headers, Core Web Vitals, WCAG 2.2. The largest skill in the library — split into twelve reference files by subtopic.

### `motion-design`

Cross-platform animation: physics vocabulary and the spring-vs-ease decision inline in `SKILL.md`, then per-platform reference files (SwiftUI, Compose, WinUI, CSS/View Transitions, GSAP, Three.js core, Three.js shaders/particles). GSAP's plugin set (ScrollTrigger, SplitText, Flip, MorphSVG) is fully free now — no license key needed.

### `design-tool-gates`

The four hard gates shared across every design tool — dark canvas first, no empty pages/frames plus the minimum screen set (Auth, Home w/ 4 states, Detail, Settings, Nav shell), token names must match the codebase, both light and dark mode required. Extracted out of `figma-design-system`, `sketch-design-system`, and `pencil-design-workflow`, which used to each carry a near-verbatim copy of this policy — changing the policy meant editing it in multiple places by hand. Now it lives once; the tool skills hold only the tool-specific mechanics for executing it.

### `figma-design-system` / `sketch-design-system`

Rob's opinionated design-system process, not MCP tool mechanics. Pulls in `design-tool-gates` for the shared session-start checklist. `figma-design-system` explicitly defers mechanical `use_figma`/`get_design_context` call syntax to the installed `figma:figma-use` plugin skills rather than duplicating them; `sketch-design-system` stays self-contained since no equivalent plugin exists, and carries the full Sketch execution technique for all 14 visual styles.

### `pencil-design-workflow`

pen.dev ships fast — verify against its own changelog before a serious session, not just this skill. Pulls in `design-tool-gates` for the shared checklist. Covers `.pen` files in Git, the MCP tool surface (which changed completely since this repo's last touch — old tool names are kept in a legacy block), Slots, and the "use the pencil mcp server" terminal-prompt requirement. It's a mechanics skill; pair it with the installed `better-*` Pencil skills (`better-colors`, `better-typography`, `better-layout`, etc.) for design-quality judgment — those are a separate, complementary layer.

### `visual-styles`

14 distinct visual languages (Neo-Minimalism, Neo-Brutalism, Brutalism Pure, Liquid Glass, Glassmorphism, Neumorphism, Kinetic Typography, Futuristic/Sci-Fi, Bento Grid, Editorial/Structural, Organic/Biomorphic, Texture/Tactile, Y2K/Retro Computing, Calm/Anti-Distraction), each with its own reference file: Visual Signature, "Wrong if" checklist, token modifications, component rules, and iOS/Android/Web implementation code. `SKILL.md` carries the cross-cutting Style-to-Technique Mapping and Cross-Style Rules since those apply no matter which single style loads.

### `color-system`

Roughly 50 named primitives from Swiss International Style poster design and the Bauhaus primary triad, plus mid-century and screen-optimized derivatives. Semantic light/dark tokens, historically-verified pairing rules, WCAG contrast table. This is a curated *palette* — for converting or manipulating whatever color you land on in OKLCH/HSL/gamut space, that's the separately-installed `better-colors` skill. TASTE.md, once built, overrides this with Rob's actual personal preference (see below).

### `code-audit`

Seven-category audit checklist: code, UI/design-system coherence, audio thread, security, design-file handoff, and a general Rust pointer. Rust-specific audit depth lives in `rust-conventions` instead of being duplicated here.

### `rust-conventions`

Extends CLAUDE.md's floor rules (no bare `unwrap()`, `thiserror`/`anyhow` split, no `clone()`-to-dodge-the-borrow-checker) with the operational layer: edition/toolchain pinning, CI gates, async/Tokio discipline, the axum/sqlx/tower web stack, `tracing` observability, realtime audio-thread crates, testing, project structure, a ~30-category crate selection guide, and a 12-item audit checklist.

### `backend-conventions`

Standalone Railway backend work that isn't behind a Next.js route — bare API servers, background workers, cron jobs, queue consumers. Covers service structure and health checks, graceful shutdown (SIGTERM/draining), `railway.json`/Railpack/Nixpacks/Dockerfile deployment config, the Supabase `service_role` admin client pattern and why RLS-bypass is safe here per the lane rules, connection pooling via Supavisor, Railway's native cron jobs, background job/queue patterns with retry and idempotency, structured logging, and monorepo layout. Explicitly defers to `rust-conventions` when the language is Rust, and to `web-platform`'s Supabase integration reference for anything inside the Next.js request cycle — this skill exists for everything outside both of those.

---

## Setup

Each skill is a self-contained directory. Personal skills go under `~/.claude/skills/`; project-only skills go under `.claude/skills/` in a given repo.

```bash
cp CLAUDE.md ~/.claude/CLAUDE.md
mkdir -p ~/.claude/skills
cp -r skills/* ~/.claude/skills/
```

CLAUDE.md loads automatically on every session. Skills load automatically when Claude judges them relevant to the current task — no manual routing required. Run `/skills` in Claude Code at any point to see what's currently discoverable.

---

## Stack

* **Frontend**: Vercel (Next.js, SSR, edge middleware)
* **Backend**: Railway (API servers, workers, long-running processes)
* **Data/Auth**: Supabase (Postgres, Auth, RLS, Realtime, Storage)
* **Native**: SwiftUI (iOS/iPadOS/macOS), Jetpack Compose (Android), WinUI (Windows)
* **Design**: Figma (primary), Sketch, Pencil
* **Languages**: Swift, Kotlin, C#, TypeScript, Rust

Stack is defined in CLAUDE.md. If yours differs, update the Lane Rules section. Everything else transfers.

---

## Notes

Native-first by default. If no visual style is specified, iOS looks like Apple built it, Android looks like Google built it, Windows looks like Microsoft built it. `visual-styles` skill styles are deliberate overrides of native conventions — not defaults.

Design fidelity is non-negotiable. Claude implements designs, it doesn't invent them. Without this rule the default is to fill unspecified gaps with whatever looks plausible. That creates drift.

The design-tool skills all have hard enforcement gates: dark canvas first, no empty pages, tokens before components, components before screens, all targeted platforms populated. Every rule exists because the failure mode happened.

This pass verified technical currency against live research, not just training data, and every skill flags genuinely uncertain claims inline as `[Unverified]` or `[Inference]` rather than stating them as fact — per the one rule that governs all work on this repo (see below). A few corrections worth knowing about even if you don't read every file: Next.js jumped 15→16 with breaking async-API changes; Windows App SDK moved off the "1.x" line to 2.x; sqlx jumped 0.8→0.9 with real breaking changes; the Sketch skill's reference to a `get_selection_as_image` MCP tool was wrong and is now `get_screenshot`; and the color-system skill's WCAG table had one mislabeled contrast pair (swiss-red on swiss-black reads as AA-pass at a glance but is actually 4.0:1, below the 4.5:1 floor for body text). Full flag lists live inline in each skill.

The color library (`color-system`) is a foundation. Once a taste-extraction pass is done — analyzing reference sites Rob actually likes and encoding the specific values, not generic ones — `taste` will override it with actual personal preference, the same way it'll override the generic token values in `visual-styles`.

Pencil (now branded pen.dev — the rebrand is confirmed, not inferred, as of this pass) is in active, fast-moving development: its MCP tool surface changed completely since this repo was last touched. Check pen.dev's own changelog before a serious session, not just this skill.

Paper (paper.design) was removed from this repo — it's no longer part of the active toolset here.

---

## Contributing

Personal config, not a framework. PRs that change the opinions in CLAUDE.md aren't what this is for. If you find a factual error in a platform spec — wrong API, stale version, missing gotcha — open an issue.

## The one rule above all others

Never present unverified platform API information as fact. If something is uncertain, say so. If an API might have changed, say so. The whole point of this system is precision — wrong information is worse than no information.

---

## License

MIT.

# Stack
- **Frontend**: Vercel (Next.js, SSR, edge middleware)
- **Backend**: Railway (API servers, workers, long-running processes)
- **Data/Auth**: Supabase (Postgres, Auth, RLS, Realtime, Storage)

# Lane Rules
These lanes don't blur. Each service has one job.

Vercel is frontend only. Anon key, RLS enforced, service_role never touches it.

Railway is for backend compute: API servers, workers, long-running processes, anything heavy. service_role lives here. RLS is intentionally bypassed on Railway because Railway is the trusted backend. service_role never goes near the client.

Supabase Auth is the auth layer, full stop. Use @supabase/ssr for cookie-based sessions. Don't roll custom JWTs when Supabase Auth already handles it.

RLS is the security layer, not a fallback. It's enforced via auth.uid(). Run EXPLAIN ANALYZE on complex policies.

Realtime is WAL-based, browser-to-Supabase direct. It's not for high-frequency writes and it doesn't guarantee exactly-once delivery.

Storage uses RLS-style policies per bucket. Large files upload directly from the client. Railway handles pre-processing if needed. Use presigned URLs for temporary access.

Edge Functions handle auth validation, webhooks, and DB trigger side effects. Nothing heavy. Deno runtime, 150ms soft CPU limit.

Railway verifies Supabase JWTs via public key.

# Platform Targets
iOS, iPadOS, macOS: target 26+. Current Swift and SwiftUI APIs only. No UIKit unless UIKit is the explicit context.

Android: current stable release. Kotlin and Jetpack Compose. No deprecated APIs unless there's genuinely no replacement.

Web: evergreen browsers. No IE, no legacy prefixes, no polyfills for anything with >95% baseline support.

If a modern API exists for something, use it. Don't default to older patterns for compatibility unless a specific minimum target actually requires it.

App Store compliance is non-negotiable. Before implementing any iOS, iPadOS, or macOS feature, verify it doesn't conflict with App Store Review Guidelines, privacy requirements (ATT, data collection disclosures), or platform entitlements. If a proposed approach would likely fail review, say so before building it.

# Writing Code
Get it right the first time. Don't write code you'd flag in an audit.

If you're not sure which pattern is current for the target platform, ask before writing anything. Don't guess. "This works but a better approach would be..." is not acceptable. Pick the right approach and use it.

Native and framework-native solutions come first. Third-party libraries are a last resort, not a default.

Don't pull from Stack Overflow answers, legacy docs, or tutorials that predate the current stable release. If multiple approaches exist, use the idiomatic current one. If a pattern only exists because it solved a problem that no longer exists (old browser targets, deprecated runtimes, pre-modern API gaps), don't use it.

Before building anything non-trivial, research the current recommended approach with web search. Training data is context, not a source of truth for current APIs or best practices.

When choosing between services, libraries, or implementation approaches, pick the fastest, most secure, and most stable option. Not the easiest or quickest to implement. If a chosen approach comes with significant complexity, cost, or implementation time, flag it before building.

# UI Architecture
No hardcoded values for color, spacing, type, radius, shadow, or motion. Everything references tokens or design system variables.

Web: CSS custom properties in a single :root block. No magic numbers inline.

SwiftUI: design tokens and semantic colors only. No hardcoded hex or CGFloat spacing values scattered through views.

Android: Material Design tokens or a defined theme. No hardcoded dp/sp/color values outside the theme layer.

Components are composable and self-contained. A component doesn't reach outside its own scope for layout or style context unless it's explicitly a layout component. Responsive behavior is defined at the token and component level, not patched per-screen with one-off overrides.

# Custom Views and Components
I build custom. Don't fall back to stock components because the custom path is harder.

In SwiftUI, if the native component is hard to customize, build a custom one. UIKit is not the answer. Default system appearances don't get used unless I've specifically asked for them.

# Animation and Motion
Motion is a design decision. Spring parameters, easing curves, and durations don't get filled in arbitrarily.

Every animation has a behavioral purpose. If it doesn't do anything meaningful, it doesn't belong.

No third-party animation libraries when native APIs cover it. CSS animations, Web Animations API, SwiftUI animation modifiers, Jetpack Compose animate* APIs. Use the platform.

Timing functions are named tokens, not magic cubic-bezier values inline. Physics-based motion (spring, inertia) is preferred over generic ease curves for interactive elements.

If motion behavior isn't specified, ask. Don't invent it.

# Design Fidelity
Designs come from Figma. My job is design, Claude's job is implementation.

If a layout, spacing, color, component structure, or animation behavior isn't specified, ask. Don't fill in the blanks with whatever looks reasonable. Don't introduce visual patterns or UI conventions that weren't in the original design. Don't substitute stock components for custom ones because they're close enough. They're not.

# Privacy
No analytics, telemetry, or tracking without explicit opt-in in the spec.

No third-party SDKs phoning home unless it's documented in the codebase. Collect the minimum data needed, nothing else. No PII in logs anywhere, including dev and debug paths. No fingerprinting or behavioral tracking unless it's explicitly required and documented.

# Audio Thread
The audio thread has one rule: don't break it.

No allocations. No locks, mutexes, or blocking calls. No Objective-C messaging. Cross-thread communication goes through lock-free ring buffers. Document buffer size assumptions in code comments.

Write audio thread code for worst-case scheduler jitter, not the happy path. Test under load.

# Rust
No unwrap() outside throwaway code. Propagate errors properly.

thiserror for library errors, anyhow for application-level error handling. Don't clone() your way out of borrow checker problems. Fix the ownership issue. Iterators over manual index loops. No unsafe without a safety comment explaining exactly which invariants are being upheld.

# Testing
Test critical paths and business logic. Skip trivial getters, setters, and pass-throughs.

Integration tests over unit tests for UI flows and API boundaries. Don't mock things just to hit coverage numbers. Mock external dependencies and I/O, that's it.

DSP functions need deterministic unit tests with known input/output pairs. Auth, RLS, and JWT verification paths need explicit test coverage.

# Commits
Conventional commit format: feat:, fix:, chore:, refactor:, docs:, test:, perf:

Subject line describes what changed and why. No mention of Claude, AI, or code generation tools. Keep subject lines under 72 characters. Use the body when context is needed.

# Skills
When working in Sketch: read ~/.claude/skills/sketch.md before touching the document.
When working on Apple platform UI: read ~/.claude/skills/apple.md before writing any view code.
When working on Android UI: read ~/.claude/skills/android.md before writing any view code.
When working on Windows / WinUI 3: read ~/.claude/skills/windows.md before writing any view code.
When building or auditing a Figma design system: read ~/.claude/skills/figma.md and ~/.claude/skills/styles.md before starting.
When working on motion or animation: read ~/.claude/skills/motion.md before writing any animation code.
When asked to audit anything: read ~/.claude/skills/audit.md before starting.

# General
- Comments are for complex code only. Don't narrate the obvious.
- All CSS is custom. No Tailwind, no frameworks.
- No em dashes.
- One question at a time when something is ambiguous.
- For tasks with independent parallel workstreams, propose a multi-agent breakdown before starting rather than executing sequentially.
- When discussing UI layouts, component structure, or visual hierarchy, illustrate it in the terminal using ASCII or Unicode drawing characters. Don't describe what something looks like when you can show it.

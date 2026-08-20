---
name: design-tool-gates
description: The shared hard gates checked at the start of and throughout every design-tool session, regardless of which tool -- Figma, Sketch, Paper, or Pencil. Covers dark canvas/background first, no empty pages/frames/artboards plus the minimum screen set per platform (Authentication, Home/main, Detail, Settings, Navigation shell), token names must match the codebase exactly, and both light and dark mode required before a design is complete. Use alongside figma-design-system, sketch-design-system, paper-design-workflow, or pencil-design-workflow whenever starting, resuming, or auditing a design file in any of those tools -- this skill owns the policy, the tool-specific skill owns the exact commands to execute it.
---

# Design Tool Gates

Four rules apply to every design file in every tool, checked at session start and re-checked throughout, not just at project kickoff. Skipping any one of them is the single most common failure mode across every design-tool session on this system. This skill owns the policy and the reasoning; each tool skill owns the exact mechanics for executing it in that tool.

## 1. Dark canvas first

The canvas or artboard background must be dark before any content -- frame, component, token, Symbol, artboard -- is created. Not optional, not deferred to "polish later." A design built against a white canvas reads completely wrong once placed in an actual dark-first product context, and re-backgrounding after the fact means re-checking every color and shadow value that assumed a white surface.

Do this first, on every page/canvas in the file, before anything else. Verify: the canvas surrounding all content is dark grey (`#1E1E1E` in Figma/Sketch, `#1A1A1A` in Paper), never white. If it's white, stop and fix it before continuing.

Exact commands per tool: `figma-design-system`, `sketch-design-system`, `paper-design-workflow`. Pencil has no freestanding canvas background concept -- its equivalent is the light/dark theme column, covered in gate 4 below.

## 2. No empty pages, frames, or artboards -- plus the minimum screen set

A page, frame, or artboard is never created as a placeholder to fill later. The workflow is create → populate fully → move to the next one. An empty container in a design file is a failure state, not a step in the process. If a Tokens page/collection exists, it's fully populated before the Components page is touched.

**Minimum screen set per platform**, required before a design is considered complete for that platform:

- **Authentication** -- login, signup, forgot password, verification
- **Home / main content** -- default, loading, empty, error states
- **Detail** -- item detail view with all content variants (full, partial, long text, short text)
- **Settings / profile**
- **Navigation** -- the nav shell in each of its states (collapsed, expanded, active tab)

"Key screens" means every targeted platform gets this full representative set, not just one platform and not just a login screen. Every hardcoded value discovered while building these screens means a token is missing -- fix the token, not the instance.

## 3. Token names must match the codebase

If a platform app already exists, the token names in the design file must match the token names in code exactly. Pull in the relevant platform skill first -- `apple-platform`, `android-platform`, `windows-platform`, or `web-platform` -- for the token architecture already shipping in code, and use those names verbatim. Never invent names that diverge from what's already in the codebase.

Mismatched names create a permanent design-to-code gap that has to be manually bridged on every handoff. This is the single highest-cost failure mode of the four gates, because it doesn't fail loudly -- a design file with `purple-500` instead of `color/semantic/interactive/primary` looks fine in the tool and only breaks at implementation time.

If the codebase's token architecture doesn't exist yet, build the design file's tokens first and let them become the source of truth -- but flag that explicitly so engineering treats the design file as canonical rather than assuming code came first.

## 4. Both light and dark mode

Every screen exists in both modes before a design is considered complete, not as a follow-up pass. In Figma and Sketch this means both mode values on every token/Color Variable and every screen actually built against both. In Paper it means each artboard rendered in both. In Pencil it means a theme column (typically labeled "dark") alongside "default"/"light" on every variable, with the properties panel used to preview each mode -- Pencil doesn't yet support native theme switching beyond variable-level column values.

## Why these four and not more

These are the gates that fail silently and expensively -- a white canvas, an empty page, a mismatched token name, or a missing dark-mode pass all look like "still in progress" rather than "broken," so nothing forces a fix until handoff, when the cost of fixing it is highest. Everything else -- component completeness, interactive-state wiring, accessibility annotations, platform-specific execution technique -- is real and required, but it lives in the tool-specific skill because it varies enough by tool that a shared version would either be too vague to enforce or too detailed to stay in sync across four files.

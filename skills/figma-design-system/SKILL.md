---
name: figma-design-system
description: Rob's opinionated process for building Figma design systems (iOS/iPadOS/macOS, Android, Web) on top of the official Figma MCP plugin skills. Covers gates checked every session -- dark canvas before any content exists, no empty pages, Figma token names must match the codebase's token names exactly -- plus three-tier token architecture (primitive/semantic/component), variable collections, light/dark modes, component completeness and interactive-state wiring, Slots, Liquid Glass technique, applying a visual style to an existing design, replicating a live app by auditing it first, minimum screen set per platform, and Dev Mode handoff. Use when building, auditing, or extending a Figma design system; creating Figma components, variables, or tokens; applying or reskinning a visual style in Figma; replicating an app's UI in Figma; or preparing a Figma file for handoff. Does not cover use_figma or get_design_context MCP call syntax -- see the installed figma:figma-use and related plugin skills for that.
---

# Figma Design Systems

Process rules for iOS/iPadOS/macOS, Android, and Web design systems in Figma, layered on top of the official Figma MCP plugin. Figma variables are the standard; static styles are legacy except for gradients and effects.

**For the mechanical MCP tool calls themselves** -- `use_figma`, `get_design_context`, `get_variable_defs`, `create_new_file`, `generate_figma_design`, Code Connect mapping, and so on -- the installed `figma:figma-use`, `figma:figma-generate-library`, `figma:figma-generate-design`, `figma:figma-code-connect`, and sibling plugin skills already cover that in full, current detail, maintained by the plugin itself. Load those alongside this one. This skill does not repeat that layer -- it adds the process rules on top: what must be true before and after a session, the token architecture, the completeness bar for a component, the minimum screen set, and how a visual style gets applied.

## Quick Reference

| Topic | Reference |
| --- | --- |
| Three-tier tokens, variable collections, platform naming maps, light/dark modes, typography variables | [reference/token-architecture.md](reference/token-architecture.md) |
| Auto Layout rules, component properties, variants, Slots, mandatory interactive-state wiring | [reference/component-architecture.md](reference/component-architecture.md) |
| Liquid Glass effect: parameters, variable bindings, anti-patterns, known limitations | [reference/liquid-glass.md](reference/liquid-glass.md) |
| Applying a visual style to an existing design (restructure, not a token swap) | [reference/applying-styles.md](reference/applying-styles.md) |
| Build-from-scratch and replicate-existing-app order of operations, file structure, minimum screen set, Dev Mode handoff, accessibility, anti-patterns | [reference/workflows-and-handoff.md](reference/workflows-and-handoff.md) |

## The three hard gates

These are checked on every single Figma session, not just at project start. They belong here, not in a reference file, because skipping any one of them is the single most common failure mode.

### 1. Dark canvas first

Not optional, not skippable. The canvas background must be dark before any frame, component, or token is created. Do this before anything else, on every page in the file.

```javascript
// Run on every page in the file
figma.currentPage.backgrounds = [{
  type: 'SOLID',
  color: { r: 0.118, g: 0.118, b: 0.118 },  // #1E1E1E
  opacity: 1
}];
```

Manually, if the MCP path doesn't cover it: right-click empty canvas → Background color → `#1E1E1E`, on every page before creating content on that page.

**Verify:** the canvas surrounding all frames is dark grey, never white. If it's white, stop and fix it before continuing.

### 2. No empty pages

A page is never created as a placeholder to fill later. The workflow is create → populate fully → move to the next page. If a 🎨 Tokens page exists, the variable collections are on it before the 🎛 Components page is touched. An empty page in the file is a failure state, not a step in the process.

### 3. Token names must match the codebase

If a platform app already exists, the token names in Figma must match the token names in code exactly -- for Apple platforms, read the `apple-platform` skill for the existing token architecture; for Android, read the Android platform design skill. Use those names. Never invent names that diverge from what's already shipping in code. Mismatched names create a permanent design-to-code gap that gets manually bridged on every handoff.

If the library doesn't exist yet, build it from the token architecture in [reference/token-architecture.md](reference/token-architecture.md).

## Design style

Before building any tokens or components, confirm the visual style for the project with the `visual-styles` skill. That skill owns the full style catalog -- Visual Signature, token modifications, component rules, per-platform implementation, "Wrong if" checklists. This skill's infrastructure (token tiers, component structure, Auto Layout, interactive wiring) stays constant across styles; only the values and structural specifics change based on the style selected. See [reference/applying-styles.md](reference/applying-styles.md) for how a style gets applied inside Figma specifically.

## Philosophy

The design system is a living contract between design and code. Tokens defined in Figma are the same tokens used in SwiftUI, Compose, and CSS -- names, values, and hierarchy match across all three. A design system built in isolation from engineering is a sticker sheet; built with engineering as a first-class audience, it's infrastructure.

Design everything: every screen, every state, every edge case. Empty, loading, error, partial content, overflow, long text, short text, disabled -- all of it. A design that covers only the happy path isn't a design system, it's a mood board -- engineering will invent the missing states in code, and they'll be wrong.

Pixel perfect means exactly that. Bind everything to variables, measure everything. A component that's 17px wide because it "looks about right" is not pixel perfect.

## Two modes of work

**Building from scratch**: design system first, components second, screens last. Token architecture defines everything before a single component is touched.

**Replicating an existing app**: audit first, extract the implicit system, formalize it, then rebuild components on top of the formalized tokens. Never skip the audit.

Both are covered step by step in [reference/workflows-and-handoff.md](reference/workflows-and-handoff.md), along with file structure, the minimum screen set per platform, Dev Mode handoff, accessibility minimums, and anti-patterns.

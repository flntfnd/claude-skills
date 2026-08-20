---
name: sketch-design-system
description: Rob's opinionated process for building Sketch design systems (iOS/iPadOS/macOS, Android, Web) on the local Sketch MCP server (Sketch 2025.2.4+, non-App-Store build; run_code/get_screenshot tools). Covers gates checked every session -- dark canvas before any Artboard or Symbol exists, no empty pages, Sketch token/Color Variable names must match the codebase exactly -- plus Figma-to-Sketch terminology, Color Variables and Tokens Studio sets, Symbols and Symbol Overrides in place of components/variants, Smart Layout, Library setup and sync, manual glassmorphism layering (no native glass in Sketch), building from scratch vs. replicating an existing app, minimum screen set per platform, Dev-Mode-equivalent handoff via Sketch Cloud, and Sketch execution technique for all 14 visual styles. Use when building, auditing, or extending a Sketch design system; creating Symbols, Color Variables, or Tokens Studio sets; applying a visual style in Sketch; replicating an app's UI; or preparing a Sketch file for handoff.
---

# Sketch Design Systems

Process rules for iOS/iPadOS/macOS, Android, and Web design systems in Sketch. Requires Sketch 2025.2.4 or later, downloaded direct from sketch.com -- not the Mac App Store build, which doesn't ship the MCP server. Sketch's own release cadence has moved past this floor (2026.1 "Dublin," 2026.2 "Edinburgh," 2026.2.1) but 2025.2.4 remains the MCP-server minimum as of this writing -- treat it as a floor, not a target version.

Sketch has no equivalent of an official Figma-plugin-style MCP skill installed on this machine, so this skill covers both the process rules and the Sketch MCP conventions needed to execute them.

## Quick Reference

| Topic | Reference |
| --- | --- |
| Figma↔Sketch terminology map, Color Variables, Tokens Studio token sets, typography | [reference/token-architecture.md](reference/token-architecture.md) |
| Symbols, Symbol Overrides, variants via Symbol groups, Smart Layout, Libraries | [reference/symbols-and-libraries.md](reference/symbols-and-libraries.md) |
| Manual glass/glassmorphism layering technique (no native glass in Sketch) | [reference/glassmorphism.md](reference/glassmorphism.md) |
| Build-from-scratch and replicate-existing-app order of operations, file structure, minimum screen set, Dev handoff, accessibility, anti-patterns | [reference/workflows-and-handoff.md](reference/workflows-and-handoff.md) |
| Sketch-specific execution technique for all 14 visual styles (Symbols, Layer Styles, Color Variables per style) | [reference/style-implementations.md](reference/style-implementations.md) |

## The three hard gates

Checked on every single Sketch session, not just at project start. Skipping any one of these is the single most common failure mode.

### 1. Dark canvas first

Not optional, not skippable. The canvas background must be dark before any Artboard, Symbol, or token is created.

**Via MCP (`run_code`):**
```javascript
const document = context.document;
const page = document.currentPage();
const darkGrey = MSColor.colorWithRed_green_blue_alpha(0.118, 0.118, 0.118, 1.0);
page.setCanvasColor(darkGrey);
```

If `setCanvasColor` is unavailable in the running Sketch version, use **File > Document Settings → Canvas Color → `#1E1E1E`** manually. For individual Artboard backgrounds: select the Artboard → Inspector → Background Color → `#1E1E1E` (or transparent if the Artboard background shouldn't appear in exports).

**Verify:** the canvas surrounding all Artboards is dark grey, never white. If it's white, stop and fix it before proceeding.

### 2. No empty pages

A page is never created as a placeholder to fill later. The workflow is create → populate fully → move to the next page. If a 🎨 Tokens page exists, the Color Variables and Tokens Studio sets go on it before the 🎛 Symbols page is touched. An empty page is a failure state, not a step in the process.

### 3. Token names must match the codebase

If a platform app already exists, the Color Variable and token names in Sketch must match the names in code exactly -- for Apple platforms, read the `apple-platform` skill for the existing token architecture; for Android, read the Android platform design skill. Use those names. Never invent names that diverge from what's already shipping. Mismatched names create a permanent design-to-code gap that gets manually bridged on every handoff.

If the library doesn't exist yet, build it from [reference/token-architecture.md](reference/token-architecture.md).

## MCP Server

All Sketch work goes through the local Sketch MCP server -- it must be running before any AI work begins.

**Start:** in Sketch, `⌘K` → type "MCP" → **Start MCP Server** (or Settings → General → MCP Server). Allow local network access when macOS prompts.

**Connect:** `claude mcp add --transport http sketch http://localhost:31126/mcp`

**Tools:** `run_code` (full SketchAPI access -- the workhorse for everything programmatic), `get_screenshot` (visual capture of layers or canvas -- use this, not `get_selection_as_image`, which isn't part of the tool set), `get_document_info`, `get_layer_tree_summary`, `get_design_assets`, `get_libraries`, `get_symbol_overrides`, `get_guide`.

Before creating or editing anything, read the existing document first with `get_document_info` / `get_layer_tree_summary` and inspect the Symbol library and Color Variables with `run_code`. Never create parallel systems next to existing ones.

## Design style

Before building any Symbols or Styles, confirm the visual style for the project with the `visual-styles` skill -- it owns the full style catalog (Visual Signature, token values, component rules, per-platform implementation). [reference/style-implementations.md](reference/style-implementations.md) covers only how each style executes in Sketch specifically.

## Philosophy

Same as the Figma system: design system first, components second, screens last. Tokens define everything before a single Symbol is created.

Design everything -- every screen, every state, every edge case. Empty, loading, error, disabled, partial content, all of it. Sketch designs handed to engineering must be pixel perfect and complete.

## Two modes of work

**Building from scratch**: design system first, Symbols second, screens last.

**Replicating an existing app**: audit first, extract the implicit system, formalize it, then rebuild Symbols on top of the formalized tokens. Never skip the audit.

Both are covered step by step in [reference/workflows-and-handoff.md](reference/workflows-and-handoff.md), along with file structure, the minimum screen set per platform, Dev handoff, accessibility minimums, and anti-patterns.

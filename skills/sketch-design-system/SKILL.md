---
name: sketch-design-system
description: Rob's opinionated process for building Sketch design systems (iOS/iPadOS/macOS, Android, Web) on the local Sketch MCP server (Sketch 2025.2.4+, non-App-Store build; run_code/get_screenshot tools). Covers gates checked every session -- dark canvas before any Frame or Symbol exists, no empty pages, Sketch token/Color Variable names must match the codebase exactly -- plus Figma-to-Sketch terminology, Color Variables and non-color token docs (no Tokens Studio equiv.), Symbols and Symbol Overrides in place of components/variants, Smart Layout, Library setup/sync, native + manual glass/glassmorphism layering, building from scratch vs. replicating an existing app, minimum screen set per platform, Dev-Mode-equivalent handoff via Sketch Cloud, and Sketch execution technique for all 14 visual styles. Use when building, auditing, or extending a Sketch design system; creating Symbols, Color Variables, or token specs; applying a visual style in Sketch; replicating an app's UI; or preparing a Sketch file for handoff.
---

# Sketch Design Systems

Process rules for iOS/iPadOS/macOS, Android, and Web design systems in Sketch. Requires Sketch 2025.2.4 or later, downloaded direct from sketch.com -- not the Mac App Store build, which doesn't ship the MCP server. Sketch's own release cadence has moved past this floor (2026.1 "Dublin," 2026.2 "Edinburgh," 2026.2.1) but 2025.2.4 remains the MCP-server minimum as of this writing -- treat it as a floor, not a target version.

Sketch has no equivalent of an official Figma-plugin-style MCP skill installed on this machine, so this skill covers both the process rules and the Sketch MCP conventions needed to execute them.

## Quick Reference

| Topic | Reference |
| --- | --- |
| Figma↔Sketch terminology map, Color Variables, non-color token docs (no Tokens Studio equivalent), typography | [reference/token-architecture.md](reference/token-architecture.md) |
| Symbols, Symbol Overrides, variants via Symbol groups, Smart Layout, Libraries | [reference/symbols-and-libraries.md](reference/symbols-and-libraries.md) |
| Native Glass effect and manual glass/glassmorphism layering technique | [reference/glassmorphism.md](reference/glassmorphism.md) |
| Build-from-scratch and replicate-existing-app order of operations, file structure, minimum screen set, Dev handoff, accessibility, anti-patterns | [reference/workflows-and-handoff.md](reference/workflows-and-handoff.md) |
| Sketch-specific execution technique for all 14 visual styles (Symbols, Layer Styles, Color Variables per style) | [reference/style-implementations.md](reference/style-implementations.md) |

## The hard gates

Pull in the `design-tool-gates` skill for the shared policy checked every session across all four design tools (dark canvas first, no empty pages plus the minimum screen set, token names must match the codebase, both light and dark mode). What follows is the Sketch-specific execution of those gates.

**Dark canvas, via MCP (`run_code`):**
```javascript
const document = context.document;
const page = document.currentPage();
const darkGrey = MSColor.colorWithRed_green_blue_alpha(0.118, 0.118, 0.118, 1.0);
page.setCanvasColor(darkGrey);
```
If `setCanvasColor` is unavailable in the running Sketch version, use **File > Document Settings → Canvas Color → `#1E1E1E`** manually. For individual Frame backgrounds: select the Frame → Inspector → Background Color → `#1E1E1E` (or transparent if the Frame background shouldn't appear in exports). Verify: the canvas surrounding all Frames is dark grey, never white.

**No empty pages:** if a 🎨 Tokens page exists, the Color Variables and the non-color token spec go on it before the 🎛 Symbols page is touched.

**Token names:** read `apple-platform`, `android-platform`, or `web-platform` for the existing token architecture and use those names verbatim. If the library doesn't exist yet, build it from [reference/token-architecture.md](reference/token-architecture.md).

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

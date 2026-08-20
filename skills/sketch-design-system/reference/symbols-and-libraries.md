# Symbols and Libraries

## Contents
- [Naming Convention](#naming-convention)
- [Symbols](#symbols)
- [Smart Layout](#smart-layout)
- [Pinning and Resizing](#pinning-and-resizing)
- [Libraries](#libraries)

## Naming Convention

Symbol Sources use `/` as the hierarchy separator. Sketch renders this as nested folders in the Insert panel:

```
Button/Primary/Default
Button/Primary/Hover
Button/Primary/Disabled
Button/Secondary/Default
Card/Default
Card/Selected
Icon/16/Arrow/Right
Icon/24/Arrow/Right
```

## Symbols

Symbols are the component system in Sketch. A Symbol Source is the source of truth; Symbol Instances are placed copies that inherit from the Source and can be customized via Overrides.

**Creating a Symbol:**
1. Design the default state of the component
2. Select all layers
3. **Layer > Create Symbol** (`⌘⌥K`)
4. Name using the `/` hierarchy convention
5. Enable "Send to Symbols Page" to keep the Source organized

**Symbol Overrides** are how instances get customized without detaching. They surface in the right-panel Inspector when an instance is selected. Available override types: text content (any text layer inside the Symbol), image fills, nested Symbol swaps (replace a nested Symbol with another from the same group), Color Variable overrides (via the fill override), layer visibility (show/hide layers within the instance), Text Style overrides.

Limit exposed overrides to what designers should actually customize. Lock or hide internal layers that shouldn't change.

**Variants via Symbol groups:** Sketch has no Figma-style variants panel. Handle variants by naming Symbol Sources in the same group:

```
Button/Primary/Default
Button/Primary/Hover
Button/Primary/Pressed
Button/Primary/Disabled
Button/Primary/Loading
```

All Sources in the `Button/Primary/` group appear as swappable options in the Override dropdown when a `Button/Primary/Default` instance is selected.

## Smart Layout

Smart Layout is Sketch's partial equivalent of Auto Layout. Apply it to Symbols to control how they resize:
- **Horizontal (Left to Right / Right to Left)**: elements resize and reflow horizontally
- **Vertical (Top to Bottom / Bottom to Top)**: elements resize vertically
- **Fixed**: the element doesn't resize

Smart Layout is less capable than Auto Layout. For complex responsive behavior, use nested Symbols with fixed dimensions and rely on pinning constraints instead.

## Pinning and Resizing

For responsive behavior within a Symbol, use pin constraints: pin to edges (left, right, top, bottom) to keep elements anchored during resize; fixed width/height for elements that shouldn't stretch; Scale for elements that should resize proportionally.

## Libraries

Libraries share Symbols, Styles, and Color Variables across files.

**Setting up a Library:**
1. Create a dedicated Sketch file for the design system (e.g. `design-system.sketch`)
2. Build all Symbol Sources, Color Variables, and Shared Styles in this file
3. **Sketch > Settings > Libraries**
4. **Add Library** and select the file

Any file that adds this Library gets access to all published Symbols, Styles, and Color Variables.

**Updating Libraries:** when the Library file changes, Sketch prompts connected files to update. Accept updates when the design system changes -- don't defer them; stale library connections cause inconsistency.

**Library sync via MCP:** use `run_code` with the SketchAPI to inspect Library connections and verify all instances in a file are linked to the correct library:

```javascript
// via run_code
const doc = sketch.getSelectedDocument();
const libraries = sketch.getLibraries();
// Check for detached symbols not linked to library
const allLayers = doc.pages.flatMap(p => p.layers);
// Audit and report
```

# Token Architecture in Sketch

## Contents
- [Sketch vs Figma: Terminology Map](#sketch-vs-figma-terminology-map)
- [Color Variables](#color-variables)
- [Beyond Color: No Tokens Studio Equivalent](#beyond-color-no-tokens-studio-equivalent)
- [Typography](#typography)

## Sketch vs Figma: Terminology Map

| Figma | Sketch |
| --- | --- |
| Component | Symbol (defined by a Symbol Source, placed as Symbol Instances) |
| Component set / variants | Symbol group (multiple Symbol Sources organized by folder name) |
| Component properties | Symbol Overrides |
| Instance | Symbol Instance |
| Variable (color) | Color Variable |
| Variable (number/string/boolean) | No native equivalent, and no Tokens Studio equivalent either -- Tokens Studio is Figma/Penpot-only. Document the value on the Tokens page instead. |
| Modes (light/dark) | Color Variables' own Light/Dark value per variable -- covers color only. No mode-switching for non-color values. |
| Auto Layout | Smart Layout (limited) |
| Styles | Shared Styles (Text Styles + Layer Styles) |
| Library | Sketch Library (.sketch file) |
| Frame | Frame -- Sketch retired the "Artboard" name for this in the 2025.1 "Athens" release (May 2025); both tools now call it Frame |
| Slot | No native equivalent -- use nested Symbols with exposed overrides |

## Color Variables

Sketch's Color Variables are the native color token system. They adapt to light/dark mode and export as CSS or JSON via Color Tokens. Defined in **View > Color Variables** (or the Inspector when a color swatch is selected), living at the document or Library level.

Organize with the same three-tier structure as the Figma system, using `/` hierarchy:

```
Primitive/Blue/50
Primitive/Blue/500
Primitive/Blue/900

Semantic/Background/Primary
Semantic/Background/Secondary
Semantic/Text/Primary
Semantic/Text/Secondary
Semantic/Border/Default
Semantic/Interactive/Primary
Semantic/Status/Error
Semantic/Status/Success
```

Semantic variables reference primitive values. Updating a primitive updates every semantic token that references it automatically.

**Light and dark mode:** Color Variables support light and dark appearances natively -- each variable has a Light and Dark value. Toggle in **View > Appearance** to preview. Design in dark mode first; if it holds in dark, it almost always holds in light.

**Exporting Color Tokens:** from the web app (sketch.com), open Color Variables on the document or Library and export as CSS (custom properties) or JSON (Amazon Style Dictionary format). This is the handoff artifact for engineering -- keep it current with every Color Variable change.

## Beyond Color: No Tokens Studio Equivalent

Sketch's native Color Variables only cover color. Don't reach for Tokens Studio to fill the gap -- **Tokens Studio is a Figma (and Penpot) plugin; it does not run inside Sketch at all.** It's absent from Sketch's own extensions directory, and its own docs describe it as Figma/Penpot-only. Nothing in Sketch's plugin ecosystem replicates its live token-set switching across light/dark/platform/density. The closest things that exist are narrower: **Puzzle Tokens** applies token values to layers, and export-only plugins (**Sketch Tokens Exporter**, **Design Tokens**) generate a design-tokens.json (Amazon Style Dictionary-compatible) from values already on the canvas. Neither is a drop-in Tokens Studio replacement, and this skill doesn't assume either is installed. [Inference: coverage and reliability of these smaller plugins is unverified -- treat them as optional export tooling, not as the source of truth.]

**Practical approach:** for spacing, radius, typography scale, and motion, document the token name and value as plain text on the 🎨 Tokens page -- e.g. a text block or labeled reference layers listing `spacing/xs = 4`, `radius/bento = 28`. Apply the numeric value to each layer by hand, and name the layer or leave a description matching the token name so the source is traceable. This page is the single source of truth designers read before typing in any spacing or radius value; there's no plugin enforcing consistency the way Tokens Studio does in Figma, so drift has to be caught by discipline and review, not tooling.

**Token structure** -- organize the documented values into the same three-tier system as color, written out rather than toggled as sets:

```
global/primitives    — raw values
global/semantic      — aliased semantic tokens
modes/light          — light mode overrides (color only -- see Color Variables above)
modes/dark           — dark mode overrides (color only -- see Color Variables above)
platforms/ios        — iOS-specific overrides
platforms/android    — Android-specific overrides
```

There's no "active set stack" resolving these automatically. Design for one mode/platform at a time and cross-check the documented values against what's on the canvas.

**Applying tokens:** read the name and value off the Tokens page and type it into the relevant property (radius, spacing, font size) by hand -- there's no plugin panel step. Never invent a numeric value that isn't on the Tokens page; if one's missing, add it to the spec first, the same discipline as never applying a primitive Color Variable where a semantic one belongs.

## Typography

**Text Styles** correspond to text style variables in Figma. Create one per semantic role:

```
Display/Large
Display/Small
Title/Large
Title/Medium
Title/Small
Headline
Body
Callout
Subheadline
Footnote
Caption
Label/Large
Label/Medium
Label/Small
```

Each Text Style should reference a Color Variable for its text color, not a hardcoded hex value -- `Semantic/Text/Primary` for primary text, etc.

**Platform type scales:** create platform variants by prefixing style names where the scale differs:

```
iOS/Display/Large       — 40pt, SF Pro
iOS/Body                — 17pt, SF Pro
Android/Display/Large   — 40sp, Roboto Flex
Android/Body            — 16sp, Roboto
Web/Display/Large       — 40px, Inter
Web/Body                — 16px, Inter
```

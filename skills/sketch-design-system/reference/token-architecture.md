# Token Architecture in Sketch

## Contents
- [Sketch vs Figma: Terminology Map](#sketch-vs-figma-terminology-map)
- [Color Variables](#color-variables)
- [Beyond Color: Tokens Studio](#beyond-color-tokens-studio)
- [Typography](#typography)

## Sketch vs Figma: Terminology Map

| Figma | Sketch |
| --- | --- |
| Component | Symbol |
| Component set / variants | Symbol group (multiple Symbol Masters organized by folder name) |
| Component properties | Symbol Overrides |
| Instance | Symbol Instance |
| Variable (color) | Color Variable |
| Variable (number/string/boolean) | No native equivalent -- use Tokens Studio plugin |
| Modes (light/dark) | Token Sets in Tokens Studio |
| Auto Layout | Smart Layout (limited) |
| Styles | Shared Styles (Text Styles + Layer Styles) |
| Library | Sketch Library (.sketch file) |
| Frame | Artboard |
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

## Beyond Color: Tokens Studio

Sketch's native Color Variables only cover color. For spacing, radius, typography, and motion tokens, use the **Tokens Studio** plugin (formerly Style Dictionary Studio). It provides full W3C-compliant design token management, token sets for light/dark mode/platforms/density, export to CSS/JSON/Style Dictionary or direct GitHub sync, and applying tokens to layers directly from the plugin panel.

**Token Sets Structure** -- organize into sets that map to the three-tier system:

```
global/primitives    — raw values
global/semantic      — aliased semantic tokens
modes/light          — light mode overrides
modes/dark           — dark mode overrides
platforms/ios        — iOS-specific overrides
platforms/android    — Android-specific overrides
```

Enable multiple sets simultaneously -- the active set stack determines the final resolved values.

**Applying tokens:** select a layer, open Tokens Studio, click the token name next to the relevant property (fill, border, radius, spacing). Applied tokens appear as badges on the layer in the plugin panel. Never apply primitive tokens directly to layers -- always apply semantic tokens.

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

# SKETCH.md
Sketch design systems for iOS, iPadOS, macOS, Android, and Web.
Requires Sketch 2025.2.4 or later. Direct download from sketch.com only -- not Mac App Store.

# Canvas Background
Set the canvas color to dark before building anything. White canvases cause eye strain and make it impossible to accurately evaluate light-mode designs.

In Sketch: go to **View > Canvas > Canvas Color** and set it to #1A1A1A. This applies per document. Set it immediately on opening or creating any file. Individual artboards can also have their background color set in the Inspector -- set those to #1E1E1E or transparent depending on whether the artboard background should appear in exports.

---

# MCP Server

All Sketch work uses the Sketch MCP server. The MCP server must be running in Sketch before any AI work begins.

## Starting the Server

In Sketch: press `⌘K` to open the Command Bar, type "MCP", choose **Start MCP Server**. Allow local network access when macOS prompts. A confirmation appears at the bottom of the document showing the server address and port.

Alternatively: **Settings > General > MCP Server** to toggle.

## Connecting Claude Code

```bash
claude mcp add --transport http sketch http://localhost:31126/mcp
claude mcp get sketch
```

The server runs at `http://localhost:31126/mcp`. It is local-only and cannot be accessed remotely. The server is off by default.

## How the MCP Server Works

Sketch's MCP server exposes two tools:

**`get_selection_as_image`**: captures an image of the current Sketch selection and returns it for analysis. Use this to inspect existing designs, audit component structures, or reference a frame before making changes.

**`run_code`**: executes SketchAPI JavaScript written by the AI to complete tasks. This is the primary tool for creating, modifying, and querying Sketch documents. It has access to the full SketchAPI -- the same API available to Sketch plugins.

Before creating or editing anything in Sketch via MCP, read the existing document first using `get_selection_as_image` on the relevant frames and `run_code` to inspect the Symbol library and Color Variables. Never create parallel systems next to existing ones.

## Canvas Background

Set the canvas to dark before doing anything else. White canvas burns eyes and makes dark mode designs impossible to evaluate accurately.

Go to **File > Document Settings** and set Canvas Color to `#1E1E1E`. This is per-document and persists with the file. Do this on every new Sketch document before placing a single Artboard.

## Design Style

Before building any Symbols or Styles, confirm the design style for the project. Read `~/.claude/skills/SKETCH.md` to get Sketch-specific implementation for each style.

---

# Sketch vs Figma: Terminology Map

| Figma | Sketch |
|---|---|
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

---

# Philosophy

Same as the Figma system: design system first, components second, screens last. Tokens define everything before a single Symbol is created.

Design everything. Every screen, every state, every edge case. Empty, loading, error, disabled, partial content -- all of it. Sketch designs handed to engineering must be pixel perfect and complete.

---

# File Structure

```
Page: 🎨 Tokens          — Color Variables documented, Tokens Studio setup
Page: 🔤 Typography       — Text Styles, type scale specimens
Page: 🎛 Symbols          — all Symbol Masters, organized by category
Page: 📐 Patterns         — composed layouts, navigation shells
Page: 📱 iOS / iPadOS     — platform screens
Page: 🤖 Android          — platform screens
Page: 🌐 Web              — platform screens
Page: 🚢 Handoff          — engineering-ready specs
Page: 🗄 Archive          — deprecated Symbols (never delete, archive)
```

Naming convention for Symbol Masters uses `/` as hierarchy separator. Sketch renders this as nested folders in the Insert panel:

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

---

# Color Variables

Sketch's Color Variables are the native color token system. They adapt to light/dark mode and export as CSS or JSON via Color Tokens.

## Setting Up Color Variables

Color Variables are defined in **View > Color Variables** (or the Inspector when a color swatch is selected). They live at the document or Library level.

Organize with the same three-tier structure as the Figma system, using `/` hierarchy:

```
Primitive/Blue/50
Primitive/Blue/100
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

Semantic variables reference primitive values. When you update a primitive, every semantic token that references it updates automatically.

## Light and Dark Mode

Sketch Color Variables support light and dark appearances natively. Each variable has a Light and Dark value. Toggle appearance in **View > Appearance** to preview.

Design in dark mode first. If it holds in dark, it almost always holds in light.

## Exporting Color Tokens

Color Tokens export from the web app (sketch.com). Go to your document or Library, open Color Variables, and export as:
- CSS: outputs CSS custom properties
- JSON: outputs Amazon Style Dictionary format

This is the handoff artifact for engineering. Keep it up to date with every Color Variable change.

---

# Beyond Color: Tokens Studio

Sketch's native Color Variables only cover color. For spacing, radius, typography, and motion tokens, use the **Tokens Studio** plugin (formerly Style Dictionary Studio).

Tokens Studio allows:
- Full W3C-compliant design token management
- Token sets for light/dark mode, platforms, density
- Export to CSS, JSON, Style Dictionary, or direct sync to GitHub
- Apply tokens to layers directly from the plugin panel

## Token Sets Structure

In Tokens Studio, organize into sets that map to the three-tier system:

```
global/primitives    — raw values
global/semantic      — aliased semantic tokens
modes/light          — light mode overrides
modes/dark           — dark mode overrides
platforms/ios        — iOS-specific overrides
platforms/android    — Android-specific overrides
```

Enable multiple sets simultaneously. The active set stack determines the final resolved values.

## Applying Tokens

Select a layer, open Tokens Studio, and apply tokens by clicking the token name next to the relevant property (fill, border, radius, spacing, etc.). Applied tokens appear as badges on the layer in the plugin panel.

Never apply primitive tokens directly to layers. Always apply semantic tokens.

---

# Typography

## Text Styles

Text Styles in Sketch correspond to text style variables in Figma. Create one Text Style per semantic role:

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

Each Text Style should reference a Color Variable for its text color, not a hardcoded hex value. Set the text color of the style to the appropriate semantic Color Variable (`Semantic/Text/Primary` for primary text, etc.).

## Platform Type Scales

Create platform variants by prefixing style names where the scale differs:

```
iOS/Display/Large       — 40pt, SF Pro
iOS/Body                — 17pt, SF Pro
Android/Display/Large   — 40sp, Roboto Flex
Android/Body            — 16sp, Roboto
Web/Display/Large       — 40px, Inter
Web/Body                — 16px, Inter
```

---

# Symbols

Symbols are the component system in Sketch. A Symbol Master is the source of truth. Symbol Instances are placed copies that inherit from the master and can be customized via Overrides.

## Creating Symbols

1. Design the default state of the component
2. Select all layers
3. **Layer > Create Symbol** (`⌘⌥K`)
4. Name using the `/` hierarchy convention
5. Enable "Send to Symbols Page" to keep the master organized

## Symbol Overrides

Overrides are how Symbol instances are customized without detaching. They appear in the right-panel Inspector when an instance is selected.

Available override types:
- Text content (any text layer inside the Symbol)
- Image fills
- Nested Symbol swaps (replace a nested Symbol with another from the same group)
- Color Variable overrides (via the fill override)
- Layer visibility (show/hide layers within the instance)
- Text Style overrides

Limit exposed overrides to what designers should actually customize. Lock or hide internal layers that shouldn't be changed.

## Variants via Symbol Groups

Sketch doesn't have a Figma-style variants panel. Handle variants by naming Symbol Masters in the same group:

```
Button/Primary/Default
Button/Primary/Hover
Button/Primary/Pressed
Button/Primary/Disabled
Button/Primary/Loading
```

All masters in the `Button/Primary/` group will appear as swappable options in the Override dropdown when a `Button/Primary/Default` instance is selected.

## Smart Layout

Smart Layout is Sketch's partial equivalent of Figma's Auto Layout. Apply it to Symbols to control how they resize:

- **Horizontal (Left to Right / Right to Left)**: elements resize and reflow horizontally
- **Vertical (Top to Bottom / Bottom to Top)**: elements resize vertically
- **Fixed**: element doesn't resize

Smart Layout is less capable than Figma's Auto Layout. For complex responsive behavior, use nested Symbols with fixed dimensions and rely on pinning constraints.

## Pinning and Resizing

For responsive behavior within a Symbol, use pin constraints:
- Pin to edges (left, right, top, bottom) to keep elements anchored during resize
- Fixed width/height for elements that should not stretch
- Scale for elements that should proportionally resize

---

# Libraries

Libraries are the mechanism for sharing Symbols, Styles, and Color Variables across files.

## Setting Up a Library

1. Create a dedicated Sketch file for the design system (e.g., `design-system.sketch`)
2. Build all Symbol Masters, Color Variables, and Shared Styles in this file
3. Go to **Sketch > Settings > Libraries**
4. Click **Add Library** and select the file

Any file that adds this Library gets access to all published Symbols, Styles, and Color Variables.

## Updating Libraries

When the Library file changes, Sketch prompts connected files to update. Accept updates when the design system changes. Don't defer updates -- stale library connections cause inconsistency.

## Library Sync via MCP

Use `run_code` with the SketchAPI to inspect Library connections and verify all instances in a file are linked to the correct library:

```javascript
// via run_code
const doc = sketch.getSelectedDocument();
const libraries = sketch.getLibraries();
// Check for detached symbols not linked to library
const allLayers = doc.pages.flatMap(p => p.layers);
// Audit and report
```

---

# Glassmorphism in Sketch

Sketch does not have a native glass effect. Apple's Liquid Glass as defined in iOS 26 is not replicable natively in Sketch. Use the manual layering technique for navigation elements that require a glass treatment.

## Manual Glass Technique

Layer stack (bottom to top):

1. **Background content**: the image, gradient, or rich content that shows through the glass. Must be present -- glass over a flat white background shows nothing.

2. **Frost layer**: a rectangle the size of the glass element.
   - Fill: white at 0% opacity (transparent)
   - Effect: Background Blur, 12-20px for nav bars, 30-50px for sheets
   - This is the frosted appearance

3. **Fill layer**: same rectangle, above the frost layer.
   - Fill: white at 8-15% opacity for `.regular` glass
   - Fill: white at 4-8% opacity for `.clear` glass
   - Layer opacity: 100% (opacity on the fill only)

4. **Highlight stroke**: same rectangle.
   - No fill
   - Border: inside, 1px, white at 20-25% opacity
   - This is the edge highlight

5. **Content layer**: text, icons, whatever sits on top of the glass

6. **Shadow**: drop shadow on the glass frame rectangle
   - Color: black at 12-18% opacity
   - Offset: 0x, 4-8y
   - Blur: 16-24px

## Light Angle Consistency

Sketched highlight strokes simulate the light source. Keep all glass elements using the same light angle across the file (upper-left: highlights on top-left edges, shadows on bottom-right).

## Glass Component as Symbol

Wrap the full layer stack into a Symbol. Expose overrides for:
- Background image/content (nested Symbol)
- Frost intensity (layer visibility toggle for light/medium/heavy frost variants)
- Content (nested Symbol for the content that sits on the glass)

---

# Building a Design System from Scratch in Sketch

## Order of Operations

1. **Define brand values**: primary color, neutral palette, typeface. These become primitives.

2. **Set up Color Variables**: primitives first, then semantic aliases. Both light and dark values for every semantic variable.

3. **Install Tokens Studio**: set up token sets for spacing, radius, typography sizes, and motion.

4. **Create Text Styles**: one per semantic role, referencing semantic Color Variables for text color.

5. **Create Layer Styles**: for common fills, borders, and shadows that repeat across components.

6. **Build atomic Symbols**: Button, Input, Checkbox, Toggle, Badge, Chip, Icon Button. Every Symbol gets all state variants. Use Color Variables and Text Styles throughout -- no hardcoded values.

7. **Build molecular Symbols**: List Rows, Cards, Nav Bars, Tab Bars, Modals, Sheets. Assembled from atomic Symbols using nested overrides.

8. **Build page patterns**: Navigation shells, screen templates, common layout patterns.

9. **Build screens last**: Using instances of pattern Symbols, which use instances of molecular Symbols, which use instances of atomic Symbols.

---

# Replicating an Existing App in Sketch

## When to Use This Workflow

When the product exists in code but no Sketch file exists, or the existing file is outdated.

## Step 1: Capture via MCP

Use `get_selection_as_image` on live screens (screenshots pasted into Sketch frames). This gives Claude Code visual context to analyze.

Use `run_code` to inspect any existing Sketch document for current Symbol inventory, Color Variables, and Text Styles before creating anything new.

## Step 2: Audit

From screenshots and the existing document, catalog:
- Every unique color (sample with eyedropper)
- Every unique font size and weight
- Every unique spacing value (measure gaps)
- Every unique corner radius
- Every recurring component pattern

Group what you find by role, not by appearance. `#6750A4` on every primary button is `Semantic/Interactive/Primary`, not `purple-500`.

## Step 3: Formalize

Build Color Variables and Tokens Studio token sets from the catalog. Name everything semantically. Populate light and dark mode values.

## Step 4: Build Symbols

Recreate every component correctly: proper naming, Smart Layout, overrides limited to what needs to be customized, Color Variables and Text Styles applied throughout. No hardcoded values.

## Step 5: Rebuild Screens

Recreate key screens using Symbol instances. Every hardcoded value found during this step means a token or Color Variable is missing.

---

# Dev Handoff

## Before Handing Off

Verify every layer uses a Color Variable (not hardcoded hex). Verify every text layer uses a Text Style. Verify every Symbol instance is linked to the Library (not detached). Use `run_code` to audit for detached instances.

## Handoff Methods

**Sketch Cloud**: upload the file, share a web link. Engineers can inspect in the browser without installing Sketch. Inspect mode shows layout, spacing, colors, Text Styles, and exportable assets.

**Export via MCP**: use `run_code` to batch-export assets:
```
Export all symbols prefixed with "icon/" from the current page as SVGs to Desktop
```

**Color Tokens export**: export Color Tokens from the web app as CSS or JSON for engineering.

## Layer Naming

Layer names appear in Inspect mode and in exported asset filenames. Name them as if naming code:

```
Good: button-label, card-thumbnail, nav-tab-home, icon-leading
Bad: Rectangle 47, Group 3, Text 2
```

Same platform naming conventions as the Figma system: camelCase for iOS/Android, kebab-case for Web.

## MCP-Assisted Handoff

Engineers can use Claude Code with the Sketch MCP to query the document directly:
- "List all design tokens used in my Sketch selection"
- "Generate my current Sketch selection in React"
- "Show the full component hierarchy of my Sketch selection as a tree"

For this to produce accurate output, the document must be clean: Color Variables applied, Text Styles applied, Symbols properly named and nested.

---

# Accessibility

Same requirements as the Figma system. WCAG AA contrast (4.5:1 normal text, 3:1 large text and interactive elements). Color cannot be the only differentiator. Touch targets 44pt minimum on iOS, 48dp on Android.

Use the **Stark** plugin for contrast checking directly in Sketch.

---

# Anti-Patterns

**Hardcoded color values in Symbols.** Any hex value in a Symbol fill that isn't a Color Variable is a missing token.

**Detached Symbol instances.** Detaching breaks the Library connection. Never detach unless the component genuinely needs to diverge from the system.

**Overrides exposing everything.** Every exposed override is a potential inconsistency. Only expose what designers should customize.

**Symbols without all states.** A Button Symbol with only the Default state means Hover, Pressed, Disabled, and Loading will be invented differently everywhere they're needed.

**Pages used as artboard dumps.** Pages have semantic purpose. Screens on the Tokens page, or Symbols scattered across the Web page, create unmaintainable files.

**Building screens before Symbols.** Screens built without a Symbol library are a collection of one-offs.

**Skipping dark mode.** Both appearances must be designed with equal intentionality.

---

# Style Implementations in Sketch
See STYLES.md for full style definitions, token values, and iOS/Android/Web implementations.
This section covers Sketch-specific technique for each style.

DESIGN-Styles.md defines what each style is, its token values, component rules, and native iOS/Android/Web implementation. This file covers how to execute those decisions inside Sketch using Symbols, Color Variables, Layer Styles, and the manual techniques Sketch requires in place of Figma's native features.

All Sketch work goes through the MCP server. See SKETCH.md for setup.

---

# 1. Neo-Minimalism in Sketch

Warm neutrals, generous spacing, serif display type, hairline dividers.

## Color Variables
Set up Color Variables using the warm neutral palette from DESIGN-Styles.md. Every semantic role must have both light and dark values.

```
Primitive/Warm/50   → #FAF9F7
Primitive/Warm/200  → #F5F3EE
Primitive/Warm/300  → #E8E4DC
Primitive/Warm/900  → #2A2622

Semantic/Background/Primary   → Light: Primitive/Warm/50,   Dark: Primitive/Warm/900
Semantic/Text/Primary         → Light: Primitive/Warm/900,  Dark: Primitive/Warm/50
Semantic/Border/Default       → Light: rgba(42,38,34,0.12), Dark: rgba(250,249,247,0.12)
```

## Text Styles
Display text uses a system or embedded serif. In Sketch:
- Font: New York (system serif on macOS/iOS targets) or embed Canela/Libre Caslon
- Weight: Light (300) for Display roles
- Line height: 1.2x for headlines, 1.7x for body

## Layer Styles
Hairline dividers as a reusable Layer Style:
- No fill
- Bottom border only: 0.5px, Semantic/Border/Default Color Variable
- Saves as a Layer Style named `Divider/Hairline`

## Symbols
Cards use background color difference (secondary vs primary surface) not borders. Create a Layer Style named `Surface/Secondary` with fill at `Semantic/Background/Secondary`. Apply to card Symbol backgrounds.

---

# 2. Neo-Brutalism in Sketch

Hard shadows, full-border containers, oversized type, high-contrast color.

## Color Variables
```
Primitive/Brand/500  → #F59E0B  (or project-specific bold color)
Semantic/Background/Primary  → #FFFFFF
Semantic/Text/Primary        → #000000
Semantic/Border/Default      → #000000
```

## Hard Shadow Layer Style
Neo-brutalist hard shadows are a Layer Style, not an ad-hoc effect. Create:
- Layer Style named `Shadow/Hard/Small`: drop shadow, black 100%, X 2 Y 2 blur 0 spread 0
- Layer Style named `Shadow/Hard/Medium`: X 4 Y 4 blur 0 spread 0 black 100%
- Layer Style named `Shadow/Hard/Large`: X 6 Y 6 blur 0 spread 0 black 100%

Apply the appropriate style to card and button Symbols.

## Button Symbol with Press State

Neo-brutalist button press behavior (shadow collapses, element shifts) is a two-variant Symbol:

`Button/Primary/Default`:
- Fill: brand color
- Border: 2px solid black
- Layer Style: `Shadow/Hard/Medium`

`Button/Primary/Pressed`:
- Same fill and border
- Layer Style: none (shadow removed)
- Layer position: offset 4px right and 4px down from default (match the shadow offset)

In prototyping, connect Default to Pressed on `Mouse Down`, Pressed back to Default on `Mouse Up`.

## Typography
Text Styles for Neo-Brutalism use ExtraBold or Black weights. Create:
- `Display/Brutalist` — 80pt+ / Black weight / tight line height
- `Headline/Brutalist` — 28pt / ExtraBold
Corner radius: 0px on all containers. Apply to all card and button Symbols.

---

# 3. Brutalism (Pure) in Sketch

Monochrome, monospace, no decoration, structure through type alone.

## Setup
Color Variables: black and white only (plus one optional accent).
Text Styles: monospace font (JetBrains Mono, Courier New).
No Layer Styles for shadows or cards -- structure comes from spacing and dividers.

## Symbols
Buttons are text with a simple 1px border rectangle behind them. No fills, no shadows. Create as a Symbol with a text override for the label.

Dividers: 1px horizontal lines, black, 100% opacity. Layer Style named `Divider/Full`.

---

# 4. Liquid Glass / Glass Treatment in Sketch

Sketch has no native glass effect. See the manual glass technique in SKETCH.md.

For navigation elements requiring glass treatment, the manual stack (Background Blur + semi-transparent fill + highlight border) is the Sketch approach. Wrap the full stack in a Symbol with overrides for the content layer.

For the `.regular` vs `.clear` variants, create two Symbol Masters:
- `Glass/Regular`: Background Blur 16px, fill white 10%
- `Glass/Clear`: Background Blur 6px, fill white 5%

Both use the same highlight border and shadow treatment.

---

# 5. Glassmorphism / Frosted in Sketch

Same manual technique as Liquid Glass. Sketch's Background Blur effect is the primary tool.

Layer stack identical to SKETCH.md glass technique. Frost is Background Blur intensity. Tune per context:
- Nav bar: 12-16px blur, fill white 10%
- Sheet: 24-32px blur, fill white 15%
- Modal: 32-48px blur, fill white 18%

---

# 6. Neumorphism / Soft UI in Sketch

Dual shadows (light upper-left, dark lower-right) on same-color background.

## Layer Style Setup
Create a Layer Style for each shadow pair. Sketch supports multiple shadows on a single layer.

`Surface/Neumorphic/Default`:
- Shadow 1: X -4 Y -4 blur 8 spread 0, white 70%
- Shadow 2: X 4 Y 4 blur 8 spread 0, black 20%
- Fill: base color (e.g. #E4EBF5)
- No border

`Surface/Neumorphic/Pressed`:
- Inner shadow 1: X -2 Y -2 blur 6, white 70%
- Inner shadow 2: X 2 Y 2 blur 6, black 20%
- Fill: same base color
- No border

Create Symbol variants `Default` and `Pressed` using these Layer Styles.

## Color Variables
All surface colors use the same base. Create a Color Variable:
```
Semantic/Background/Neumorphic → Light: #E4EBF5, Dark: #1E1E2E
```

Apply this Color Variable to all layer fills in Neumorphic Symbols so the entire system shifts when the base color changes.

---

# 7. Kinetic Typography in Sketch

Kinetic typography is a screen-in-motion behavior, not a static design property. Sketch designs define the start and end states. Motion is annotated for engineering, not prototyped in full.

## Start State Symbol
The text layer at initial state: opacity 0, position offset 20-30px below final position.

## End State Symbol
The text layer at final state: opacity 100%, final position.

## Annotation Layer Style
Create a Layer Style named `Annotation/Motion` -- a green dashed border. Apply to layers that have defined motion behavior and add a note in the layer description:

```
Motion: translateY(-30px) to 0, opacity 0 to 1
Duration: 0.6s
Easing: expo-out (cubic-bezier(0.16, 1, 0.3, 1))
Stagger: 0.03s per character
```

Variable font weight variation (for platforms that support it): create two Symbol variants showing the collapsed weight (thin) and expanded weight (bold) states. Note the animation spec in the layer description.

---

# 8. Futuristic / Sci-Fi in Sketch

Dark surfaces, neon accents, glow effects, grid backgrounds.

## Color Variables
```
Semantic/Background/Primary   → #0A0A0F
Semantic/Background/Secondary → #12121A
Semantic/Text/Primary         → #E8E8F0
Semantic/Accent/Primary       → #00F5D4  (neon cyan)
Semantic/Accent/Secondary     → #A855F7  (electric purple)
```

## Glow Layer Style
Sketch supports multiple drop shadows -- use them to simulate the glow stack:

`Glow/Small`:
- Shadow 1: X 0 Y 0 blur 8 spread 0, accent color 80%
- Shadow 2: X 0 Y 0 blur 16 spread 0, accent color 40%
- Shadow 3: X 0 Y 0 blur 32 spread 0, accent color 20%

Apply `Glow/Small` to neon-accented elements (active nav items, primary CTAs, status indicators).

## Grid Background Symbol
Create a Symbol named `Background/Grid`:
- Rectangle filled with dark background color
- Two semi-transparent line groups (horizontal and vertical) at 40px intervals
- Line color: accent at 5-8% opacity
- Use as the base artboard background for all Futuristic screens

---

# 9. Bento Grid in Sketch

Modular card grid layout. All cards share the same corner radius.

## Grid Setup in Sketch
Sketch doesn't have CSS Grid. Use a fixed-column grid guide system:
- Go to **View > Canvas > Grid Settings**
- Set column guide matching the bento layout (e.g. 2 or 3 equal columns with 16px gaps)

## Cell Symbol Library
Create Symbol Masters for each span size:
```
BentoCell/1x1  — square card
BentoCell/2x1  — wide card (2 columns, 1 row height)
BentoCell/1x2  — tall card (1 column, 2 row heights)
BentoCell/2x2  — featured card (2 columns, 2 row heights)
```

Each cell Symbol:
- Corner radius: 24-32px (use Tokens Studio to apply a radius token)
- Background fill: Color Variable for appropriate surface level
- Content area: exposed nested Symbol override

---

# 10. Editorial / Structural in Sketch

Grid visible as design element, serif type, hairline rules.

## Column Grid
**View > Canvas > Layout Settings**: set up an explicit column grid (8 or 12 columns) with narrow gutters. Enable **Show Layout** in View menu. The grid should be visible during design as a foreground element.

## Text Styles
```
Display/Editorial   — large serif, light weight, tight leading
Headline/Editorial  — bold condensed or bold serif
Body/Editorial      — regular serif, generous leading (1.7x)
Label/Editorial     — small caps effect (via Text Style: uppercase, 0.08em tracking)
Caption/Editorial   — 12pt regular, secondary text color
```

Tabular numerals: in Text Style inspector, enable Tabular Figures under the OpenType features panel if the font supports it.

## Dividers
Horizontal rule Layer Styles:
- `Divider/Heavy` — 2px, full black or ink color, 100%
- `Divider/Standard` — 1px, 80%
- `Divider/Hairline` — 0.5px, 40%

---

# 11. Organic / Biomorphic in Sketch

Flowing shapes, natural color palette, pill shapes, flowing curves.

## Blob Shapes
Sketch has full vector path editing. Create organic blob shapes using the Pen tool or Vector Network, then save as Symbols for background layers.

Reusable blob Symbols:
- `Shape/Blob/01` through `Shape/Blob/06`: varied irregular organic forms
- Fill via Color Variable, not hardcoded color
- Use as background layers behind content, not as containers

## Pill Shapes
All interactive elements use `radius/pill` (9999px). Set corner radius in the layer to maximum (Sketch rounds down automatically).

## Color Variables
```
Semantic/Accent/Terracotta  → #C4704A
Semantic/Accent/Sage        → #8FAB8A
Semantic/Accent/Sky         → #6B9FBF
Semantic/Accent/Sand        → #D4B896
```

---

# 12. Texture / Tactile in Sketch

Grain overlay as a shared Symbol applied to all screens.

## Noise Overlay Symbol
Create a Symbol named `Effect/Noise/Subtle`:
- Rectangle: 200% width and height of target frame (oversized to fill on scroll)
- Fill: noise pattern (embed a grain PNG or use the Noise effect)
- Layer blend mode: Overlay
- Opacity: 3-5%

Place this Symbol at the top of the layer stack on every screen that needs texture. Use a nested Symbol override for the grain density variant (subtle/medium/heavy).

## Sketch Noise Effect
Sketch has a native Noise fill. In the Fill section, select Noise, set density to 15-25% and opacity to 0.03-0.05. Apply as a fill on the top layer of the artboard.

---

# 13. Y2K / Retro Computing in Sketch

Terminal palettes, monospace type, CRT effects.

## Color Variables
```
Semantic/Background/CRT-Green  → #0A0A0A
Semantic/Text/CRT-Green        → #00FF41
Semantic/Accent/CRT-Green-Dim  → #003B00
```

## CRT Scan Line Symbol
Create a Symbol named `Effect/ScanLine`:
- Repeating horizontal lines (2px gap between each)
- Fill: black at 6-8%
- Blend mode: Multiply
- Place at top of every screen layer stack

## Text Styles
All body text: JetBrains Mono or Courier New, regular weight.
Display text: large bitmap-style font, or manually recreated pixel type as a Symbol using rectangles (for extreme fidelity on display elements).

## Windows 3.1 Bevel
Layer Style named `Border/Bevel`:
- Border top: 2px, white 80%
- Border left: 2px, white 80%
- Border right: 2px, gray 60%
- Border bottom: 2px, gray 60%

Sketch supports independent border sides. Apply to dialog boxes and button Symbols in the Y2K style.

---

# 14. Calm / Anti-Distraction in Sketch

Maximum whitespace, minimal color, type-forward, no decoration.

## Color Variables
Two-color system:
```
Semantic/Background/Primary  → #FAFAF8 / #1A1A18
Semantic/Text/Primary        → #2C2C2A / #E8E8E4
Semantic/Text/Secondary      → #888884 / #6A6A66
Semantic/Interactive/Accent  → #6B9FBF (same both modes, muted)
```

## Spacing
Apply extra-generous spacing tokens via Tokens Studio. All section margins are `spacing/section` (64px+). Content padding is `spacing/xl` (32px).

## Text Styles
Regular weight throughout. The only bold is `Label/Large` at Medium (500). No Black or ExtraBold weights appear in this style.

## Symbol Density
Buttons are minimal: text only with a 1px border, or text with no border and color as the only differentiator. No filled button backgrounds except for the single primary action per screen.

---

# Cross-Style Rules in Sketch

All of DESIGN-Styles.md's cross-style rules apply. Sketch-specific additions:

**Color Variables are mandatory regardless of style.** No hardcoded hex anywhere. The style determines which Color Variables exist and what their values are -- not whether Color Variables are used.

**Every Symbol gets all states.** The style determines what those states look like, not whether they exist.

**Artboard naming matches screen names in code.** `iOS/Home/Default`, not `Screen 47 copy 3`.

**Library connections must be maintained.** Detached Symbols create inconsistency regardless of style.

**Dark mode is required for every style.** Every Color Variable has a dark value. Every screen has been reviewed in dark mode.

# Style Implementations in Sketch

Full style definitions -- what each style is, its token values, component rules, native iOS/Android/Web implementation -- live in the `visual-styles` skill. This file covers only how to execute those decisions inside Sketch: Symbols, Color Variables, Layer Styles, and the substitutions Sketch requires in place of Figma's native features (Auto Layout → Smart Layout, Variants → Symbol groups, Tokens Studio → a documented non-color token spec since Tokens Studio doesn't run in Sketch). Sketch's own Glass effect (native, since 2025.2.1) covers most glass work directly -- see [glassmorphism.md](glassmorphism.md).

All Sketch work goes through the MCP server -- see the main `sketch-design-system` SKILL.md for setup.

## Contents
1. [Neo-Minimalism](#1-neo-minimalism-in-sketch)
2. [Neo-Brutalism](#2-neo-brutalism-in-sketch)
3. [Brutalism (Pure)](#3-brutalism-pure-in-sketch)
4. [Liquid Glass / Glass Treatment](#4-liquid-glass--glass-treatment-in-sketch)
5. [Glassmorphism / Frosted](#5-glassmorphism--frosted-in-sketch)
6. [Neumorphism / Soft UI](#6-neumorphism--soft-ui-in-sketch)
7. [Kinetic Typography](#7-kinetic-typography-in-sketch)
8. [Futuristic / Sci-Fi](#8-futuristic--sci-fi-in-sketch)
9. [Bento Grid](#9-bento-grid-in-sketch)
10. [Editorial / Structural](#10-editorial--structural-in-sketch)
11. [Organic / Biomorphic](#11-organic--biomorphic-in-sketch)
12. [Texture / Tactile](#12-texture--tactile-in-sketch)
13. [Y2K / Retro Computing](#13-y2k--retro-computing-in-sketch)
14. [Calm / Anti-Distraction](#14-calm--anti-distraction-in-sketch)
15. [Cross-Style Rules](#cross-style-rules-in-sketch)

---

## 1. Neo-Minimalism in Sketch

Warm neutrals, generous spacing, serif display type, hairline dividers.

**Structural requirements:**
- **Navigation Symbol**: no fill, no border, no background -- just a Text layer for the brand and link Text layers, sitting at the top of the Frame. The nav Symbol's frame must be transparent.
- **Hero Frame region**: serif display Text Style at Light (300) weight, padded vertically with `spacing/xxl` (64px+) above and below. Subtext in regular sans, comfortable reading size.
- **Content list Symbols**: each item is a row inside a Group, separated by an instance of the `Divider/Hairline` Layer Style or Smart Layout vertical gap. Never wrapped in a card with a border or fill.
- **Section dividers**: Layer Style `Divider/Hairline` (0.5-1px, warm-tinted Color Variable) is the only horizontal rule. No 2px+ rules anywhere.
- **CTA Symbols**: text-only, or 1px outlined Text + Border -- no filled rectangles for secondary actions.
- **Backgrounds**: Color Variable `Semantic/Background/Primary` resolves to warm off-white (#FAF9F7), never pure #FFFFFF.

**Wrong if:** any Symbol has a Border + Fill combination forming a card box; any Layer Style includes a Drop Shadow; `Semantic/Background/Primary` is `#FFFFFF`; spacing tokens are at the default 8pt scale rather than 25%-expanded; any Text Style uses sans-serif for Display roles.

**Color Variables:**
```
Primitive/Warm/50   → #FAF9F7
Primitive/Warm/200  → #F5F3EE
Primitive/Warm/300  → #E8E4DC
Primitive/Warm/900  → #2A2622

Semantic/Background/Primary   → Light: Primitive/Warm/50,   Dark: Primitive/Warm/900
Semantic/Text/Primary         → Light: Primitive/Warm/900,  Dark: Primitive/Warm/50
Semantic/Border/Default       → Light: rgba(42,38,34,0.12), Dark: rgba(250,249,247,0.12)
```

**Text Styles:** Font New York (system serif on macOS/iOS targets) or embed Canela/Libre Caslon. Weight Light (300) for Display roles. Line height 1.2x headlines, 1.7x body.

**Layer Styles:** Hairline divider -- no fill, bottom border only, 0.5px, `Semantic/Border/Default`, saved as Layer Style `Divider/Hairline`.

**Symbols:** Cards use background color difference (secondary vs primary surface), not borders. Create Layer Style `Surface/Secondary`, fill at `Semantic/Background/Secondary`, applied to card Symbol backgrounds.

---

## 2. Neo-Brutalism in Sketch

Hard shadows, full-border containers, oversized type, high-contrast color.

**Structural requirements:**
- **Navigation Symbol**: solid brand-color Fill, Border bottom-only at 2-4px solid black (Top/Left/Right 0px, Bottom 2-4px, #000).
- **Hero Symbol**: full-width, spanning the entire Frame, Fill = brand Color Variable, corner radius 0 on every corner. Display Text Style at ExtraBold (800) or Black (900) weight on top.
- **Content list items**: each row Symbol must be a CARD -- Border 2px solid #000 (Center), Layer Style `Shadow/Hard/Medium` (X:4 Y:4 Blur:0 Spread:0 #000 100%), corner radius 0. Not a divider-separated row -- replace any `Divider/*` list Symbol with the card structure.
- **Interactive Symbols** (Button, Card, Arrow): two variants -- `/Default` (with `Shadow/Hard/*`) and `/Pressed` (Layer Style: none, position offset 4px right and 4px down). Wire Mouse Down → Pressed, Mouse Up → Default.
- **Section background Symbols**: alternate `Semantic/Background/Primary` (white) and brand color. CTA section fills the entire frame with brand color.
- **Section dividers**: 2px solid black, never `Divider/Hairline`.

**Wrong if:** any Drop Shadow Layer Style has Blur > 0; any Symbol has corner radius > 4px; a list item Symbol lacks `Border 2px #000` AND a `Shadow/Hard/*` Layer Style; the Hover variant changes only color, not the shadow + offset behavior; brand color is missing from large background fills.

**Color Variables:**
```
Primitive/Brand/500  → #F59E0B  (or project-specific bold color)
Semantic/Background/Primary  → #FFFFFF
Semantic/Text/Primary        → #000000
Semantic/Border/Default      → #000000
```

**Hard Shadow Layer Style** -- create as Layer Styles, not ad-hoc effects:
- `Shadow/Hard/Small`: X 2 Y 2 blur 0 spread 0, black 100%
- `Shadow/Hard/Medium`: X 4 Y 4 blur 0 spread 0, black 100%
- `Shadow/Hard/Large`: X 6 Y 6 blur 0 spread 0, black 100%

**Button Symbol with press state:**

`Button/Primary/Default`: Fill brand color, Border 2px solid black, Layer Style `Shadow/Hard/Medium`.
`Button/Primary/Pressed`: same fill and border, Layer Style none, position offset 4px right / 4px down from default. Connect Default → Pressed on Mouse Down, Pressed → Default on Mouse Up.

**Typography:** ExtraBold or Black weights. `Display/Brutalist` — 80pt+ / Black / tight line height. `Headline/Brutalist` — 28pt / ExtraBold. Corner radius 0 on all containers.

---

## 3. Brutalism (Pure) in Sketch

Monochrome, monospace, no decoration, structure through type alone.

**Structural requirements:**
- **Navigation**: plain Text layers at the top of the Frame, no Symbol container, no Fill, no Border -- or one Text layer + a single `Divider/Heavy` rule below.
- **Hero**: massive serif or monospace Display Text Style, 80-120pt. Subtext in body Text Style. No background Fill on the Frame region.
- **Content lists**: raw text rows separated by `Divider/Heavy` applications, or a Symbol that's just a Text + bottom Border. No card containers.
- **Section dividers**: `Divider/Heavy` Layer Style (1-2px solid black) is the only structural element -- no background-color section breaks.
- **Buttons**: text with an optional 1px black Border rectangle, no Fill, no Shadow. Save as `Button/Pure/Default`.
- **Color palette**: maximum 3 Color Variables in the entire system -- `Semantic/Paper`, `Semantic/Ink`, optional `Semantic/Accent`.

**Wrong if:** any Layer Style includes a Drop or Inner Shadow; any Symbol has corner radius > 0; more than 3 Color Variables exist; Text Styles include a sans-serif body font at standard sizes; any Symbol uses a Fill that isn't `Semantic/Paper` or `Semantic/Ink`.

**Setup:** Color Variables black and white only (plus one optional accent). Text Styles monospace (JetBrains Mono, Courier New). No Layer Styles for shadows or cards -- structure comes from spacing and dividers.

**Symbols:** buttons are text with a simple 1px border rectangle behind them, no fills, no shadows -- built as a Symbol with a text override for the label. Dividers: 1px horizontal lines, black, 100%, Layer Style `Divider/Full`.

---

## 4. Liquid Glass / Glass Treatment in Sketch

Use Sketch's native **Glass** effect (Inspector → `+` next to Effects → Glass) -- **Auto** mode for a default-accurate Apple-platform look, **Custom** when a specific Blur/Distortion/Depth/Chromatic Aberration/Brightness/Saturation/Specular Highlights combination is required. Glass applies to Shapes, Images, Text, and Frames, not to Groups or Symbol Instances directly -- put it on the Shape or Frame layer inside the Symbol. See [glassmorphism.md](glassmorphism.md) for the manual layering fallback (older Sketch versions, or a Group target).

**Structural requirements:**
- **Background Frame layer**: must contain rich content (gradient Layer Style, image, or photo Fill) before any glass Symbol is placed on top. Glass over a flat white Frame renders as opaque white -- the style is invisible without a rich background.
- **Glass Symbol**: a Shape or Frame layer with the native Glass effect (Custom mode) plus a 1px white inside-position Border and a Drop Shadow for depth, built as a single Symbol Source.
- **Two glass variants** as Symbol Sources: `Glass/Regular` (Custom Blur ~16px equivalent, higher Brightness/Saturation) and `Glass/Clear` (Custom Blur ~6px equivalent, lower Brightness/Saturation) -- tune the Custom parameters until each reads as regular vs. clear; Auto mode doesn't expose this distinction.
- **Navigation use only**: glass Symbols belong on `NavBar/Glass`, `TabBar/Glass`, `Toolbar/Glass` -- never on content Symbols (cards, list rows, images).
- **Content extends behind the glass layer** -- the Frame hierarchy puts scrollable content beneath the navigation glass, edge-to-edge.

**Wrong if:** a Glass Symbol sits over a flat-color Frame (no gradient, image, or photo Fill underneath); glass is applied to content Symbols instead of navigation; the Glass effect is missing from the Symbol (a manually faked blur substituted without reason); the Border on a glass Symbol uses a dark color rather than semi-transparent white; Liquid Glass is attempted on Web or Android Frames (use Glassmorphism / style #5 instead).

Wrap the Shape/Frame carrying the Glass effect in a Symbol with overrides for the content layer. Both `.regular` and `.clear` variants use the same highlight border and shadow treatment.

---

## 5. Glassmorphism / Frosted in Sketch

Same native Glass effect as Liquid Glass (style #4) -- this style uses it more heavily and tunes it looser (more Blur, less Specular Highlights/Chromatic Aberration) for a frosted rather than crystalline look. Fall back to manual layering (see [glassmorphism.md](glassmorphism.md)) only if the file targets pre-2025.2.1 Sketch or the target layer is a Group.

**Structural requirements:**
- **Background Frame layer**: vivid gradient (Linear Gradient Fill on a full-Frame rectangle), hero image, or deep-color field. All glass Symbols sit on top -- without rich content underneath, glass is invisible.
- **Glass Symbol** per Symbol Source: native Glass effect, Custom mode -- Blur tuned to 16px-equivalent standard / 24-32px-equivalent for sheets / 32-48px-equivalent for modals; Brightness/Saturation raised so background color reads through; Specular Highlights low (frosted, not crystalline). Add a 1px white 25%-opacity inside Border and a Drop Shadow X:0 Y:8 Blur:32 #000 12% for depth; optional inner highlight (top-edge 1px white 30% as a separate inset rectangle).
- **Three Symbol variants**: `Glass/Nav` (lighter blur), `Glass/Sheet` (medium), `Glass/Modal` (heaviest) -- tune the Glass effect's Blur parameter per surface depth.
- **Scrim sub-layer** for legibility over unpredictable content: a Linear Gradient Fill rectangle inside the glass Symbol, rgba(0,0,0,0.15) → transparent, for dark text.

**Wrong if:** the Glass effect (or, on the manual fallback, Background Blur) is missing or at 0; the glass Symbol's fill/tint is opaque rather than letting background content through; the Border uses a dark color instead of semi-transparent white; glass sits over a flat solid Color Variable rather than a gradient or image; all glass Symbols use the same Blur value regardless of depth role.

Per-context tuning: nav bar lighter blur / fill white 10% equivalent; sheet medium blur / white 15%; modal heaviest blur / white 18%.

---

## 6. Neumorphism / Soft UI in Sketch

Dual shadows (light upper-left, dark lower-right) on a same-color background.

**Structural requirements:**
- **Single base color across the entire Frame**: page background, every Symbol background, every Card Symbol fill all reference the same Color Variable `Semantic/Background/Neumorphic`. Different fills = wrong style.
- **Raised Symbols** use the dual-shadow Layer Style `Surface/Neumorphic/Default`: Shadow 1 (X:-4 Y:-4 Blur:8, white 70%) + Shadow 2 (X:4 Y:4 Blur:8, black 20%). No Border. Fill = base color.
- **Pressed/active Symbols** use the inset variant `Surface/Neumorphic/Pressed`: Inner Shadow 1 (X:-2 Y:-2 Blur:6, white 70%) + Inner Shadow 2 (X:2 Y:2 Blur:6, black 20%). No Border.
- **Two-variant Symbols**: every interactive Symbol (Button, Toggle, Card-as-Button) needs `/Default` (raised) and `/Pressed` (inset) variants wired in the prototype.
- **No Borders anywhere** -- depth is exclusively shadow-based.
- **Generous corner radius**: 16-24px on interactive Symbols, matching the `radius` value documented on the Tokens page (see [token-architecture.md](token-architecture.md) -- Sketch has no Tokens Studio equivalent, so this is a hand-applied documented value, not a bound token).

**Wrong if:** any Symbol has a Fill different from the base `Semantic/Background/Neumorphic`; any Symbol has a Border > 0 width; any Layer Style uses a single directional Drop Shadow instead of the dual pair; the Pressed state changes color rather than swapping to inset shadows; text contrast against the base falls below WCAG AA 4.5:1 -- neumorphism's biggest failure mode.

**Layer Style setup** (Sketch supports multiple shadows on a single layer):

`Surface/Neumorphic/Default`: Shadow 1 X -4 Y -4 blur 8 spread 0 white 70%; Shadow 2 X 4 Y 4 blur 8 spread 0 black 20%; Fill base color (e.g. #E4EBF5); no border.

`Surface/Neumorphic/Pressed`: Inner shadow 1 X -2 Y -2 blur 6 white 70%; Inner shadow 2 X 2 Y 2 blur 6 black 20%; same base fill; no border.

**Color Variables:**
```
Semantic/Background/Neumorphic → Light: #E4EBF5, Dark: #1E1E2E
```
Apply this to all layer fills in Neumorphic Symbols so the entire system shifts when the base color changes.

---

## 7. Kinetic Typography in Sketch

A screen-in-motion behavior, not a static design property. Sketch designs define start and end states; motion is annotated for engineering, not fully prototyped.

**Structural requirements:**
- **Two-Symbol pattern per kinetic element**: `Hero/Start` (text at opacity 0, position offset 20-30px below final) and `Hero/End` (text at opacity 100%, final position). Same content, different layer states.
- **Display Text Style at extreme size** — 72pt minimum, often 120pt+. Text Style `Display/Kinetic`, separate from standard Display.
- **Variable font weight states** (Roboto Flex / SF Pro): two Symbol variants showing start weight (e.g. Thin 100) and end weight (e.g. Black 900). Annotate the weight transition.
- **Annotation Layer Style** `Annotation/Motion`: green dashed Border, applied to any layer with motion behavior. Layer description holds the motion spec (duration, easing, stagger).
- **Layout reduction**: minimal cards, minimal containers -- type IS the layout. Generous whitespace around kinetic elements.

**Wrong if:** Display text sizes sit at the standard 28-48pt range rather than 72-120pt+; cards and containers dominate the layout instead of typography; motion specs are missing from layer descriptions on annotated layers; `Annotation/Motion` is not applied to motion-bearing elements; no reduce-motion fallback Symbol variant exists.

**Annotation content example:**
```
Motion: translateY(-30px) to 0, opacity 0 to 1
Duration: 0.6s
Easing: expo-out (cubic-bezier(0.16, 1, 0.3, 1))
Stagger: 0.03s per character
```

---

## 8. Futuristic / Sci-Fi in Sketch

Dark surfaces, neon accents, glow effects, grid backgrounds.

**Structural requirements:**
- **Frame background**: deep near-black Color Variable `Semantic/Background/Primary` (#0A0A0F), not generic dark grey. Optional low-opacity radial gradient from center for subtle depth.
- **Glow Layer Style** `Glow/Small` applied to neon-accented Symbols (active nav items, primary CTAs, status indicators): three stacked Drop Shadows, all Blur/Spread 0 spread, accent Color Variable at decreasing opacities (80% → 40% → 20%). Sketch supports multiple shadows on one layer.
- **Grid background Symbol** `Background/Grid`: dark-base rectangle plus two Line Symbol Groups (horizontal, vertical) at 40px intervals, accent color 5-8% opacity. Used as the Frame base for every Futuristic screen.
- **Card Symbols**: 1px Border, accent Color Variable at 15-20% opacity, Fill slightly lighter than the Frame background. Hover variant brightens the Border to full accent + applies `Glow/Small`.
- **Data text** uses monospace Text Style `Mono/Data` for numbers, readouts, status text -- tabular figures enabled in OpenType features.
- **Minimal corner radius** — 0-4px maximum. Futurism is angular.

**Wrong if:** the background resolves to generic `#1A1A1A` or `#222` rather than the near-black blue-tinted `#0A0A0F`; no `Glow/*` Layer Style exists or nothing applies it; Card Symbols use standard Border colors instead of low-opacity accent; all text uses proportional sans-serif with no `Mono/Data` Text Style for readouts; corner radius exceeds 8px on any Symbol.

**Color Variables:**
```
Semantic/Background/Primary   → #0A0A0F
Semantic/Background/Secondary → #12121A
Semantic/Text/Primary         → #E8E8F0
Semantic/Accent/Primary       → #00F5D4  (neon cyan)
Semantic/Accent/Secondary     → #A855F7  (electric purple)
```

**Glow Layer Style** `Glow/Small`: Shadow 1 X0 Y0 blur 8 spread 0 accent 80%; Shadow 2 X0 Y0 blur 16 spread 0 accent 40%; Shadow 3 X0 Y0 blur 32 spread 0 accent 20%.

**Grid Background Symbol** `Background/Grid`: dark rectangle + two semi-transparent line groups (horizontal/vertical) at 40px intervals, accent 5-8% opacity, as the base Frame background for all Futuristic screens.

---

## 9. Bento Grid in Sketch

Modular card grid layout. All cards share the same corner radius.

**Structural requirements:**
- **Explicit column grid** via View > Canvas > Layout Settings -- typically 4 or 6 columns with consistent gutter. Bento cells span 1, 2, or 3 columns. The grid IS the design.
- **At least three distinct cell sizes** as Symbol Sources: `BentoCell/1x1` (square), `BentoCell/2x1` (wide), `BentoCell/2x2` (featured). Equal-size grids are card grids, not Bento.
- **Identical corner radius across every cell Symbol**: 24-32px, matching the documented `radius/bento` value on the Tokens page, shared by all cells.
- **Visible gap between cells**: 12-20px, the Frame background showing through -- set via Smart Layout gap on the parent Group.
- **Featured cell** (largest, usually 2x2) uses the brand or accent Color Variable as Fill; other cells use `Semantic/Background/Secondary`.
- **One concept per cell** -- a single content slot via nested Symbol override, not mixed content like headline + chart + button + image in one cell.

**Wrong if:** all cell Symbols are the same size (no `2x1`/`2x2` variants exist); corner radius differs between cell Symbols; the featured cell uses the same Fill as other cells; content flows in a vertical stack outside the bento grid; the gap between cells is missing.

**Grid setup:** View > Canvas > Grid Settings -- column guide matching the bento layout (e.g. 2 or 3 equal columns, 16px gaps).

**Cell Symbol library:**
```
BentoCell/1x1  — square card
BentoCell/2x1  — wide card (2 columns, 1 row height)
BentoCell/1x2  — tall card (1 column, 2 row heights)
BentoCell/2x2  — featured card (2 columns, 2 row heights)
```
Each cell: corner radius 24-32px (matching the documented Tokens page value), background fill via Color Variable, content area as an exposed nested Symbol override.

---

## 10. Editorial / Structural in Sketch

Grid visible as a design element, serif type, hairline rules.

**Structural requirements:**
- **Explicit Layout Settings column grid** (8 or 12 columns) with narrow gutters. Enable Show Layout in the View menu so the grid is visible as a foreground element during work.
- **Multiple Text Styles coexist** on every screen: `Display/Editorial`, `Headline/Editorial`, `Body/Editorial`, `Label/Editorial` (small caps, tracked), `Caption/Editorial`. Density comes from hierarchy, not one-size body text.
- **Hairline rule Layer Styles**: `Divider/Heavy` (2px), `Divider/Standard` (1px, 80%), `Divider/Hairline` (0.5px, 40%) -- the primary structural element between sections, not background-color blocks.
- **No card containers.** Content sits in column-aligned Groups separated by rules and Smart Layout spacing.
- **Tabular figures** enabled in Text Styles for numeric data, via the OpenType features panel in the Text Style inspector.
- **Section labels**: `Label/Editorial` Text Style, uppercase, tracked 0.08-0.15em, small (11-12pt).

**Wrong if:** the Layout Settings column grid isn't configured or visible; only one Body Text Style is in use across screens; card containers wrap content lists instead of column-aligned groups with rule dividers; sections are separated by background-color blocks rather than `Divider/*` Layer Styles; numeric Text Styles lack OpenType tabular figures.

**Column grid:** View > Canvas > Layout Settings -- 8 or 12 columns, narrow gutters, Show Layout enabled.

**Text Styles:**
```
Display/Editorial   — large serif, light weight, tight leading
Headline/Editorial  — bold condensed or bold serif
Body/Editorial      — regular serif, generous leading (1.7x)
Label/Editorial     — small caps effect (uppercase, 0.08em tracking)
Caption/Editorial   — 12pt regular, secondary text color
```

**Dividers:** `Divider/Heavy` 2px full ink 100%; `Divider/Standard` 1px 80%; `Divider/Hairline` 0.5px 40%.

---

## 11. Organic / Biomorphic in Sketch

Flowing shapes, natural color palette, pill shapes, flowing curves.

**Structural requirements:**
- **Container Symbols are blob shapes**, not rectangles. Use the Pen tool or Vector Network to create irregular organic forms, saved as `Shape/Blob/01` through `Shape/Blob/06` Symbol Sources. Standard rounded rectangles, even with large radius, are not Organic.
- **Background blob layer on every Frame**: instances of `Shape/Blob/*` positioned behind content, filled with gradient Color Variables (`Gradient/Sunrise`, `Gradient/Forest`) -- decorative depth, not containers.
- **Pill shapes on interactive elements**: corner radius set to maximum (Sketch caps at 50%, producing a pill). Document this as `radius/pill` on the Tokens page and apply it by hand on Button Symbols.
- **Color Variables from a nature palette**: `Semantic/Accent/Terracotta`, `Semantic/Accent/Sage`, `Semantic/Accent/Sky`, `Semantic/Accent/Sand`. No corporate blue, no pure black, no pure white.
- **Asymmetric layout**: text columns offset rather than centered, Symbols that don't snap to a strict grid. Smart Layout spacing uses irregular values (18, 28, 44) rather than 16, 24, 40.

**Wrong if:** container Symbols are rectangles even with large radius applied; Frame backgrounds are a flat Color Variable Fill with no `Shape/Blob/*` instances behind content; the color palette includes corporate blues, pure black, or pure white; the layout is symmetrically centered on a strict grid; spacing tokens are exact 8pt multiples rather than the irregular organic values.

**Blob shapes:** full vector path editing via the Pen tool or Vector Network, saved as Symbols for background layers -- fill via Color Variable, used as background layers, not containers.

**Color Variables:**
```
Semantic/Accent/Terracotta  → #C4704A
Semantic/Accent/Sage        → #8FAB8A
Semantic/Accent/Sky         → #6B9FBF
Semantic/Accent/Sand        → #D4B896
```

---

## 12. Texture / Tactile in Sketch

Grain overlay as a shared Symbol applied to all screens.

**Structural requirements:**
- **Global noise overlay Symbol** `Effect/Noise/Subtle`, placed at the TOP of the layer stack on every Frame -- without this, the style isn't applied. A rectangle sized 200% of the Frame, with noise Fill, blend mode Overlay, opacity 3-5%.
- **Per-surface intensity variants** as Symbol Sources: `Effect/Noise/Subtle` (3%), `Effect/Noise/Medium` (5-7%), `Effect/Noise/Heavy` (12-15%) -- pick per surface, Frames subtle, hero elements heavier.
- **Color Variables warm or earthy, slightly desaturated.** Flat saturated colors fight the texture -- the palette should read as "printed," not "emitted."
- **Sketch native Noise fill** as an alternative to the Symbol approach: any Fill, switch to Noise type, density 15-25%, opacity 0.03-0.05, applied as a top-layer Fill on the Frame.
- **Typography**: humanist sans or warm serif Text Styles -- crisp but not sterile.

**Wrong if:** no `Effect/Noise/*` Symbol or Noise Fill exists at the top of the Frame layer stack; Color Variables resolve to high-saturation flat colors that fight the grain; overlay opacity is at default 100% (must be 3-15%); the blend mode is Normal rather than Overlay.

**Noise Overlay Symbol** `Effect/Noise/Subtle`: rectangle 200% width/height of target frame (oversized to fill on scroll), noise-pattern fill (grain PNG or Noise effect), blend mode Overlay, opacity 3-5%. Place at the top of the layer stack on every screen needing texture; nest a Symbol override for density variant.

**Sketch native Noise:** in the Fill section, select Noise, density 15-25%, opacity 0.03-0.05, applied as a fill on the top layer of the Frame.

---

## 13. Y2K / Retro Computing in Sketch

Terminal palettes, monospace type, CRT effects.

**Structural requirements:**
- **Color scheme committed to one era** via Color Variables -- pick one, don't mix:
  - Terminal: `Semantic/Background/CRT-Green` (#0A0A0A) + `Semantic/Text/CRT-Green` (#00FF41)
  - Amber CRT: bg #0F0A00 + text #FF9900
  - Windows 3.1: grey #C0C0C0 + blue title `#000080` + bevel borders
  - Early web: primary colors, Times New Roman, inline borders
- **CRT Scan Line Symbol** `Effect/ScanLine`, placed at the top of every Frame: repeating 2px-gap horizontal lines, Fill black 6-8%, blend mode Multiply. The most recognizable element -- it must be present.
- **Text Styles use monospace**: `Mono/Body` (JetBrains Mono or Courier New, regular). Display text either bitmap-style, or pixel type recreated as a Symbol from rectangles.
- **Bevel border Layer Style** `Border/Bevel` (Windows 3.1 era): per-side Borders -- Top/Left 2px white 80%, Right/Bottom 2px gray 60%. Applied to dialog box and button Symbols.
- **At least one overtly retro structural element** per screen: bevel chrome, blinking cursor (animated annotation), terminal prompt `>` indicator, or pixelated decorative element.

**Wrong if:** no `Effect/ScanLine` Symbol exists on the Frame; Text Styles use proportional sans-serif rather than monospace; the color palette mixes eras on the same screen; no structural retro element exists -- the design just looks like a dark theme with a green accent; borders are uniform on all sides instead of using `Border/Bevel` per-side asymmetry for the Windows 3.1 era.

**Color Variables:**
```
Semantic/Background/CRT-Green  → #0A0A0A
Semantic/Text/CRT-Green        → #00FF41
Semantic/Accent/CRT-Green-Dim  → #003B00
```

**CRT Scan Line Symbol** `Effect/ScanLine`: repeating horizontal lines (2px gap), Fill black 6-8%, blend mode Multiply, placed at the top of every screen layer stack.

**Windows 3.1 Bevel** `Border/Bevel`: Border top 2px white 80%; left 2px white 80%; right 2px gray 60%; bottom 2px gray 60%. Sketch supports independent border sides -- apply to dialog boxes and button Symbols.

---

## 14. Calm / Anti-Distraction in Sketch

Maximum whitespace, minimal color, type-forward, no decoration.

**Structural requirements:**
- **Spacing tokens at 1.5-2x the default scale**, documented on the Tokens page. Section spacing `spacing/section` = 64px+, content padding `spacing/xl` = 32px. Whitespace IS the design.
- **Color palette of maximum 3 Color Variables**: `Semantic/Background/Primary` (warm off-white or deep warm grey), `Semantic/Text/Primary` (near-black or near-white, never pure), `Semantic/Interactive/Accent` (single muted color, used only for the single most important interactive element). Nothing else.
- **Body Text Style at large size** (18-20pt), generous line-height (1.7-1.9), moderate tracking -- reading should feel unhurried.
- **Navigation Symbol minimal to invisible**: small logo or title Text + one or two link Texts. No background Fill, no Border.
- **Buttons text-only or 1px outline**, except for the single primary action per screen -- no filled rectangles for secondary actions.
- **No badges, no notification dots, no unread counts, no progress bars** for non-essential tasks, no tooltip Symbols implying unprompted appearance.
- **Motion annotation**: any animated Symbol limited to opacity fade 200-300ms ease -- no spring, no transform. Annotated in the layer description.

**Wrong if:** more than 3 Color Variables are in active use; the Body Text Style is at standard 14-16pt rather than 18-20pt; the Navigation Symbol carries visual weight (Background Fill, Border, prominent contrast); multiple filled-button Symbols appear per screen (only one primary CTA gets a Fill); any badge/notification dot/unread count Symbol exists; spacing tokens are at the default 8pt scale rather than 1.5-2x expanded; motion specs reference spring physics or transforms.

**Color Variables:**
```
Semantic/Background/Primary  → #FAFAF8 / #1A1A18
Semantic/Text/Primary        → #2C2C2A / #E8E8E4
Semantic/Text/Secondary      → #888884 / #6A6A66
Semantic/Interactive/Accent  → #6B9FBF (same both modes, muted)
```

**Spacing:** extra-generous, documented on the Tokens page -- all section margins `spacing/section` (64px+), content padding `spacing/xl` (32px).

**Text Styles:** regular weight throughout; the only bold is `Label/Large` at Medium (500). No Black or ExtraBold weights.

**Symbol density:** buttons minimal -- text only with a 1px border, or text with no border and color as the only differentiator. No filled button backgrounds except the single primary action per screen.

---

## Cross-Style Rules in Sketch

All of the `visual-styles` skill's cross-style rules apply. Sketch-specific additions:

**Color Variables are mandatory regardless of style.** No hardcoded hex anywhere. The style determines which Color Variables exist and what their values are, not whether Color Variables are used.

**Every Symbol gets all states.** The style determines what those states look like, not whether they exist.

**Frame naming matches screen names in code.** `iOS/Home/Default`, not `Screen 47 copy 3`.

**Library connections must be maintained.** Detached Symbols create inconsistency regardless of style.

**Dark mode is required for every style.** Every Color Variable has a dark value; every screen has been reviewed in dark mode.

**Visual Signature check before handoff.** Every style above has a "Wrong if" list. Run through it before considering a screen complete. If any condition applies, the style is not implemented correctly -- fix the Sketch document before exporting tokens or going to engineering.

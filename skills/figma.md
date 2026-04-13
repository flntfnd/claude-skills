# DESIGN-systems.md
Figma design systems for iOS, iPadOS, macOS, Android, and Web.
Current as of 2026. Figma variables are the standard. Static styles are legacy.

# Canvas Background
Set the page canvas color to dark before building anything. White canvases cause eye strain and make light-mode designs impossible to evaluate accurately against the canvas.

In Figma: click an empty area of the canvas so nothing is selected. In the right panel, find the Background color swatch and set it to #1A1A1A. Do this on every page in the file before starting work.

# MCP
All Figma work uses the Figma MCP server. Before creating or editing anything in Figma, connect to the MCP server and read the existing library. Use the actual components, variables, and tokens already published. Don't approximate, guess, or recreate things that already exist. If the library doesn't exist yet, build it via MCP from the token architecture defined below.

# Canvas Background
Set the Figma canvas to dark before doing anything else. A white canvas burns eyes and makes dark mode designs impossible to evaluate accurately.

Right-click on an empty area of the canvas and select **Background color**. Set it to `#1E1E1E`. This is per-file and persists. Do this on every new Figma file before placing a single frame.

# Design Style
Before building any tokens or components, read `~/.claude/skills/STYLES.md` and confirm the style for the project. The style determines how tokens are populated. The infrastructure in this file stays constant across styles -- the values change based on style selection.

---

# Philosophy

The design system is a living contract between design and code. Tokens defined in Figma are the same tokens used in SwiftUI, Compose, and CSS. Names, values, and hierarchy must match across all three.

A design system built in isolation from engineering is a sticker sheet. A design system built with engineering as a first-class audience is infrastructure.

Design everything. Every screen. Every state. Every edge case. Empty states, loading states, error states, partial content, overflow content, long text, short text, disabled states -- all of it. A design that covers only the happy path is not a design system, it's a mood board. Engineering needs every state specified before they build. If it's not in the file, it will be invented in code, and it will be wrong.

Pixel perfect means exactly that. Spacing, alignment, typography, and color must be precise. Use tokens, not approximations. A component that's 17px wide because it "looks about right" is not pixel perfect. Bind everything to variables. Measure everything. If it doesn't match the token, fix it.

Two modes of work covered here:

**Building from scratch**: design system first, components second, screens last. Token architecture defines everything before a single component is touched.

**Replicating an existing app**: audit first, extract the implicit system, formalize it, then rebuild components on top of the formalized tokens. Never skip the audit.

---

# File Structure

One file per system. Organized by pages, not by separate files, unless the system is truly multi-brand at enterprise scale.

```
Page: 🎨 Tokens          — all variable collections documented visually
Page: 🔤 Typography       — type scale, specimens, usage examples
Page: 🎛 Components       — all components, organized by category
Page: 📐 Patterns         — composed layouts, navigation patterns
Page: 📱 iOS / iPadOS     — platform screens
Page: 🤖 Android          — platform screens
Page: 🌐 Web              — platform screens
Page: 🚢 Handoff          — engineering-ready specs
Page: 🗄 Archive          — deprecated components (don't delete, archive)
```

Keep components and tokens in the same file. Splitting into separate libraries is for enterprise multi-brand systems only. Over-splitting creates maintenance overhead that kills adoption.

---

# Variable Architecture

## Three-Tier Token System

Never apply primitive tokens directly to components. Always alias through semantic tokens.

**Tier 1: Primitive** (raw values, never applied directly)

```
color/primitive/blue/50
color/primitive/blue/100
color/primitive/blue/500
color/primitive/blue/900
color/primitive/gray/50
...
spacing/primitive/2
spacing/primitive/4
spacing/primitive/8
spacing/primitive/16
...
radius/primitive/4
radius/primitive/8
radius/primitive/12
radius/primitive/16
radius/primitive/9999
```

**Tier 2: Semantic** (meaning and intent, applied in most cases)

```
color/semantic/background/primary
color/semantic/background/secondary
color/semantic/background/elevated
color/semantic/text/primary
color/semantic/text/secondary
color/semantic/text/disabled
color/semantic/border/default
color/semantic/border/focus
color/semantic/status/success
color/semantic/status/warning
color/semantic/status/error
color/semantic/interactive/primary
color/semantic/interactive/primary-hover
color/semantic/interactive/primary-pressed
```

**Tier 3: Component** (only needed at enterprise scale)

```
button/primary/background/default
button/primary/background/hover
button/primary/text/default
card/background
card/border
```

For most projects, semantic tokens are the endpoint. Component tokens add overhead that only pays off if you have multiple teams and strict governance requirements.

## Variable Collections in Figma

Organize into four collections. Keep them separate.

**Collection 1: Primitives**
All raw values. One mode only. No light/dark here.

**Collection 2: Semantic — Color**
Modes: Light, Dark
Every semantic color token aliases a primitive. Switching modes swaps the alias target, not the token name. Components using semantic tokens automatically adapt to mode switches.

**Collection 3: Semantic — Spacing, Radius, Motion**
Number variables. Modes: Default (no theming needed here unless building density variants).

**Collection 4: Typography**
String variables for font family, weight. Number variables for size and line height.
As of 2026 you can bind font family and weight to string variables, and font size/line height to number variables. This lets a single `brand-font` variable update the entire system's typeface instantly.

## Naming Convention

Use forward slashes as hierarchy separators in Figma. They map to dot notation or kebab-case depending on the target platform.

In Figma: `color/semantic/background/primary`
In CSS: `--color-semantic-background-primary`
In Swift: `Color.Semantic.Background.primary`
In Kotlin: `MaterialTheme.colorScheme.background` (mapped via theme)

Align names with platform conventions where they exist. Don't fight the platform naming system.

## Platform Token Name Mapping

### iOS / iPadOS / macOS (SwiftUI)

| Figma Token | SwiftUI Equivalent |
|---|---|
| `color/semantic/background/primary` | `Color(.systemBackground)` |
| `color/semantic/background/secondary` | `Color(.secondarySystemBackground)` |
| `color/semantic/text/primary` | `Color(.label)` |
| `color/semantic/text/secondary` | `Color(.secondaryLabel)` |
| `color/semantic/border/default` | `Color(.separator)` |
| `color/semantic/interactive/primary` | `Color.accentColor` |
| `spacing/base` | `Spacing.base` (custom token, 16pt) |
| `radius/medium` | `GlassTokens.Radius.card` |

When a SwiftUI system color covers the use case, use the system color. Custom tokens fill the gaps -- brand-specific colors, product-specific surfaces, and anything the system palette doesn't cover.

### Android (Material 3 Expressive)

| Figma Token | Compose Equivalent |
|---|---|
| `color/semantic/background/primary` | `MaterialTheme.colorScheme.surface` |
| `color/semantic/background/secondary` | `MaterialTheme.colorScheme.surfaceContainer` |
| `color/semantic/text/primary` | `MaterialTheme.colorScheme.onSurface` |
| `color/semantic/text/secondary` | `MaterialTheme.colorScheme.onSurfaceVariant` |
| `color/semantic/interactive/primary` | `MaterialTheme.colorScheme.primary` |
| `color/semantic/status/error` | `MaterialTheme.colorScheme.error` |
| `color/semantic/border/default` | `MaterialTheme.colorScheme.outline` |

### Web (CSS)

| Figma Token | CSS Custom Property |
|---|---|
| `color/semantic/background/primary` | `--color-bg-primary` |
| `color/semantic/text/primary` | `--color-text-primary` |
| `color/semantic/interactive/primary` | `--color-interactive-primary` |
| `spacing/base` | `--spacing-base` |
| `radius/medium` | `--radius-md` |

## Light and Dark Modes

Both modes live in the same semantic color collection. Every token has a Light mode value and a Dark mode value. Switching the mode variable in Figma switches every component simultaneously.

Design in dark mode first. If it works in dark, it almost always works in light. The reverse is not always true.

For each semantic color, the light and dark values both alias primitives. Never put raw hex values into semantic tokens.

```
color/semantic/background/primary
  Light: → color/primitive/gray/50  (#F5F3EE)
  Dark:  → color/primitive/gray/950 (#1A1A1E)
```

Expose a mode switcher at the frame level during design. Any frame can be toggled between light and dark instantly using variable modes. Every screen should be reviewed in both before handoff.

---

# Typography

## Variable-Driven Type System

As of 2026, bind all type properties to variables.

```
typography/family/sans     → "SF Pro" (iOS), "Roboto Flex" (Android), "Inter" (Web)
typography/family/mono     → "SF Mono", "Roboto Mono", "JetBrains Mono"

typography/size/display-lg  → 40 (number variable)
typography/size/display-sm  → 32
typography/size/title-lg    → 28
typography/size/title-md    → 22
typography/size/title-sm    → 20
typography/size/headline    → 17
typography/size/body        → 16
typography/size/callout     → 15
typography/size/subhead     → 14
typography/size/footnote    → 13
typography/size/caption     → 12

typography/weight/regular   → "Regular"  (400)
typography/weight/medium    → "Medium"   (500)
typography/weight/semibold  → "Semibold" (600)
typography/weight/bold      → "Bold"     (700)

typography/leading/tight    → 1.2
typography/leading/normal   → 1.5
typography/leading/relaxed  → 1.7
```

Text styles in Figma reference these variables. Changing the `typography/family/sans` variable updates every text style in the system simultaneously.

## Platform Type Scales

Create one text style per semantic role, not per size. Roles carry meaning. Sizes carry numbers.

```
Display Large     — hero content, marketing surfaces
Display Small     — section headers, feature intros
Title Large       — screen titles, modal headers
Title Medium      — card headers, list section titles
Title Small       — subheaders, labeled groups
Headline          — emphasized body, call-outs
Body              — primary reading content
Callout           — secondary reading, supporting text
Subheadline       — metadata, secondary info
Footnote          — timestamps, attribution, legal
Caption           — image captions, form help text
Label Large       — button labels, active states
Label Medium      — secondary button labels, tags
Label Small       — badges, chips, minimal labels
```

---

# Spacing and Layout

## Spacing Scale

8pt grid. All spacing tokens are multiples of 4, with a preference for multiples of 8.

```
spacing/1    → 2
spacing/2    → 4
spacing/3    → 8
spacing/4    → 12
spacing/5    → 16   (base)
spacing/6    → 20
spacing/7    → 24
spacing/8    → 32
spacing/9    → 40
spacing/10   → 48
spacing/11   → 64
spacing/12   → 80
```

Apply these as number variables to padding and gap in Auto Layout frames. No hardcoded values.

## Radius Scale

```
radius/none       → 0
radius/xs         → 4
radius/sm         → 8
radius/md         → 12
radius/lg         → 16
radius/xl         → 24
radius/2xl        → 28
radius/sheet      → 34
radius/pill       → 9999
```

On iOS, use `radius/2xl` for cards (maps to `GlassTokens.Radius.card = 28`), `radius/sheet` for sheets (maps to 34), and `radius/pill` for capsule shapes.

On Android, `radius/md` maps to M3's medium shape (12dp), `radius/xl` to extraLarge (24dp).

---

# Auto Layout

Every component uses Auto Layout. No exceptions. A component without Auto Layout will break when content changes.

## Key Properties

**Direction**: Horizontal for row-based layouts (nav bars, button groups, list rows). Vertical for column-based layouts (cards, forms, modals).

**Spacing**: Fixed between specific elements. Space-between for elements that should push apart.

**Padding**: Reference spacing tokens. Never hardcode padding values.

**Resizing**: Hug content when the component should wrap tightly. Fill container when the component should expand to available space.

**Min/max dimensions**: Set min-width and max-width where content could overflow or the component could become unusably small or large.

**Wrap**: For grid-like layouts where items should wrap to new rows when the container shrinks.

## Responsive Components

For components that behave differently across breakpoints, create variant properties matching the breakpoint names. Figma Sites uses these automatically, but the same pattern applies for documentation and handoff.

Standard breakpoints:
```
Mobile:  375 — 767
Tablet:  768 — 1023
Desktop: 1024+
```

Name variant properties to match: `Platform` with values `Mobile`, `Tablet`, `Desktop` — or `Size` with `Compact`, `Regular`, `Large` for iOS/iPadOS.

## Absolute Positioning

Use sparingly and only for elements that intentionally overlay others: badges on icons, decorative elements, glass overlays. Set the frame clip content when using absolute positioned children that should not affect the Auto Layout flow.

---

# Component Architecture

## Structure Rules

Every component follows this structure:
- Outer frame: Auto Layout, defines padding and overall sizing
- Inner groups: organized by content zone
- All colors: semantic color variables
- All spacing: spacing number variables
- All type: text style referencing typography variables
- Layer names: match code component and prop names exactly

## Component Properties

Use component properties for every customizable aspect. Don't rely on override-hacking.

```
Property types:
Boolean    — show/hide elements (icon, label, badge)
Text       — editable content (label, placeholder, count)
Instance swap — replace nested components (leading icon, avatar, status indicator)
Variant    — switch component states and sizes
```

Expose only what needs to be customized. Hiding properties that designers shouldn't touch keeps the system clean.

## Variants

Every component needs all states designed before any state is built. Map them first:

```
Button states:
  Default, Hover, Pressed, Focused, Disabled, Loading

Input states:
  Empty, Filled, Focused, Error, Disabled, Read-only

Card states:
  Default, Hover, Pressed, Selected, Disabled
```

Name variants with consistent property names across the system. `State` with values `Default/Hover/Pressed/Disabled`. `Size` with values `Small/Medium/Large`. `Style` with values `Primary/Secondary/Ghost/Destructive`.

## Slots (2026)

Slots are now the correct pattern for flexible composition. Instead of building 20 card variants for every content combination, build one card with slots.

A slot is a named container inside a component that accepts component instances. It behaves like a frame with Auto Layout, but its contents can be swapped without detaching the parent component.

Use slots for:
- Content regions inside cards (header slot, body slot, footer slot, media slot)
- Icon positions in buttons and list rows
- Custom empty states
- Interchangeable lead and trail elements

Set preferred instances on slots to guide designers toward the correct components without locking them in.

## Interactive Components

Every stateful component must be interactive. This means prototype interactions built into the component set, not linked between separate frames.

Setup pattern for a button:

1. Create component set with all state variants
2. In the Default variant: add prototype connection to Hover variant on `Mouse enter`, `Change to`
3. In the Hover variant: add `Mouse leave` back to Default, `Mouse down` to Pressed
4. In the Pressed variant: add `Mouse up` back to Hover
5. Any instance placed in a prototype inherits these interactions automatically

Result: you never wire button states frame-to-frame again. One interactive component, every prototype.

Same pattern for:
- Toggles and checkboxes (On click, Change to)
- Accordions (On click, expand/collapse variants)
- Dropdown menus (On click, show/hide overlay)
- Form inputs (On focus, On blur)
- Navigation tabs (On click, active state variant)

## Variables in Prototypes

For prototypes that need logic beyond state transitions, use variables with prototype actions.

**Boolean variables**: show/hide elements conditionally
**Number variables**: counters, quantity selectors, progress values
**String variables**: dynamic labels, selected values, form content

```
Example: cart item counter
- Create number variable: cartCount (default: 0)
- Bind to text layer showing count
- On "Add" button click: Set variable cartCount to cartCount + 1
- On "Remove" click: Set variable cartCount to cartCount - 1
- Conditional: if cartCount == 0, hide checkout button
```

This replaces dozens of duplicate frames with a single frame and a few variable actions.

---

# Liquid Glass in Figma

## Native Glass Effect

Figma's Glass effect is GA as of January 2026 and applies to any layer type: frames, shapes, text, components. One glass effect per layer maximum.

Glass belongs on navigation-layer elements only: toolbars, tab bars, floating controls, sheets. Never on content.

## Critical Rules Before Starting

These are the most common failure points:

**Fill opacity must be below 100%.** Glass will not render on a layer whose fill is set to 100% opacity. Reduce fill opacity or switch the fill to a semi-transparent color before adding the glass effect.

**Glass and background blur cannot coexist on the same layer.** If both are applied, only the first effect in the stack renders. Remove any background blur from a layer before applying glass. If you need both, layer them: glass object on top, background blur object beneath -- a glass layer on top of a background blur layer renders correctly. A background blur layer on top of a glass layer breaks the glass.

**Glass needs content underneath to refract.** A glass element over a flat white or solid background shows nothing. The design must have imagery, gradients, or rich color content beneath the glass layer for the effect to be visible.

**Stack order matters.** Glass renders what is directly behind the layer in the Figma layer stack. If the content you want to show through glass is not behind the glass layer in the canvas and layer panel, it won't appear.

## Step-by-Step

1. Set up the background: place a rich image, gradient, or layered content beneath where the glass element will sit. The glass needs something to refract.

2. Create a frame, shape, or component that will receive the glass effect.

3. Set the fill to a semi-transparent value. For `.regular` glass: white fill at 8-15% opacity. For `.clear` glass: white fill at 4-8% opacity. Do not leave fill at 100% -- glass will not render.

4. In the Effects panel, click `+` and select Glass from the dropdown.

5. Open the effect settings and dial in the seven parameters:

   - **Light angle**: direction of the light source. Use 135-145° (upper-left) as the system default. Keep consistent across all glass elements in the file.
   - **Light intensity**: brightness of the projected light. 70-80%.
   - **Refraction**: optical distortion along the curved edge. 70-90%. Above 90% text becomes unreadable fast. Start at 75 and adjust.
   - **Depth**: how far the curved edge extends inward. Creates the domed appearance. 10-30%. Higher = thicker glass. Start at 15.
   - **Dispersion**: chromatic splitting (rainbow fringe) at the edge. 30-50%. Subtle is better. Start at 35.
   - **Frost**: integrated background blur amount. 5-15% for nav bars and toolbars. 30-50% for sheets. 50-70% for modals.
   - **Splay**: how far the projected light spreads across the surface. 20-40%.

6. Add a 1px inside stroke at white 20-25% opacity for the highlight border.

7. Add a drop shadow: black, 0 blur, 8-16px radius, 12-18% opacity for depth.

## Variable Bindings

Apply number variables to glass properties so the system is token-driven.

```
glass/light/angle           → 140 (number)
glass/light/intensity       → 75  (number)

glass/refraction/regular    → 78  (number)
glass/refraction/clear      → 88  (number)

glass/depth/default         → 15  (number)
glass/dispersion/default    → 35  (number)
glass/splay/default         → 30  (number)

glass/frost/navigation      → 10  (number)
glass/frost/toolbar         → 8   (number)
glass/frost/sheet           → 40  (number)
glass/frost/modal           → 60  (number)
```

Create a Glass variable collection with two modes: Regular and Clear. Switch modes to preview the difference across all glass elements simultaneously.

## Glass Variants in Figma

To model Apple's `.regular` and `.clear` glass variants:

**Regular** (default, most UI surfaces):
- Fill: white 10-15% opacity
- Frost: 8-15
- Refraction: 75-80
- Depth: 12-18

**Clear** (over media-rich backgrounds, strong foreground content):
- Fill: white 4-8% opacity
- Frost: 0-5
- Refraction: 85-90
- Depth: 8-12

**Identity** (conditionally disabled):
- Remove glass effect entirely, or set isEnabled to false in the component property

## Building Glass Components

Glass elements should be built as components with a `Variant` property (`Regular` / `Clear`) that switches between the two glass configurations via mode switch, not manual re-application.

Inside the component:
- Background layer: slot (accepts any content behind the glass)
- Glass frame: Auto Layout, semi-transparent fill, glass effect applied
- Highlight stroke: 1px inside stroke, white 20%
- Shadow: drop shadow for depth

The component must sit over actual content in the prototype/screen frame for the glass to render visibly. In an isolated component state on a white canvas it will appear flat -- this is expected behavior, not a bug.

## Known Limitations

- One glass effect per layer. Cannot stack multiple glass effects on a single layer.
- No environmental reflections. The specular device-motion highlight from native iOS 26 cannot be replicated in Figma -- it is a rendering engine behavior, not a static effect.
- No SVG export support. Glass effects are stripped on SVG export.
- Not supported in Figma Sites.
- Background blur and glass conflict on the same layer -- remove background blur before adding glass.
- Glass won't render over solid fills at 100% opacity.

## Glass Anti-Patterns

Glass applied to list rows, cards, or body text. Navigation layer only.

Frost set too high on nav bars. The glass becomes opaque and content legibility drops.

Refraction above 90. Text and icons become distorted and unreadable.

Background blur left on the same layer before adding glass. One cancels the other.

Inconsistent light angle across components. Pick one angle for the file (135-145°) and never deviate.

---

# Building a Design System from Scratch

## Order of Operations

Build in this order. Do not skip steps or reorder.

**1. Extract brand values**
Before opening Figma, answer: primary color, neutral palette, brand typeface, voice and tone. These become the primitives.

**2. Build primitive tokens**
Create the Primitives variable collection. Define the full color ramp (50-950 for each hue), spacing scale, radius scale, and shadow values. No components yet. No screens.

**3. Build semantic tokens**
Create the Semantic Color collection with Light and Dark modes. Alias every semantic token to a primitive. Every background, surface, text, border, and interactive color role gets defined here.

**4. Define typography**
Create the Typography variable collection. Build text styles that reference the typography variables.

**5. Define spacing and radius**
Number variables. Text styles and components reference these.

**6. Build atomic components**
Button, input, checkbox, toggle, radio, badge, chip, avatar, icon button. These are the atoms. Every atom gets all states and uses only semantic tokens.

**7. Build molecular components**
List rows, cards, nav bars, tab bars, modals, sheets, tooltips. Assembled from atoms.

**8. Build page patterns**
Navigation shells, screen templates, common layout patterns.

**9. Build screens last**
Actual product screens use instances of patterns, which use instances of molecules, which use instances of atoms. Nothing is drawn freehand on a screen.

## Platform Variants

Each platform-specific component is a variant of the base component, not a separate component. A Card component has iOS, Android, and Web variants that share token bindings but adapt their visual treatment to platform conventions.

Use a `Platform` component property with values `iOS`, `Android`, `Web`. Bind the relevant variant to the correct platform's visual spec.

---

# Replicating an Existing App

## When to Use This Workflow

When the product already exists in code but design files are missing, outdated, or never existed. The goal is to extract the implicit design system from the live product and formalize it.

## Step 1: Audit the Product

Screenshot every unique screen state. Capture: default, empty, error, loading, full, partial, and edge-case states. Do not skip states.

Organize screenshots on a Figma page. Group by feature area, not by screen type.

## Step 2: Extract the Implicit System

From the screenshots, identify and catalog:

**Colors**: Use the eyedropper to sample every unique color. List them. You will find:
- Colors used once (noise)
- Colors used 3-5 times (likely semantic roles)
- Colors used everywhere (definitely semantic roles)

Group by role. This is your primitive palette and semantic roles.

**Spacing**: Measure gaps and padding on recurring patterns. Most well-built products use a consistent grid. Find it. Common grids: 4pt, 8pt, 12pt.

**Typography**: List every unique font size and weight. Most products use 8-12 distinct type styles even if they were never documented.

**Radius**: Measure corner radii on cards, buttons, and inputs. Look for a consistent set (usually 4-6 values).

**Elevation/shadows**: Catalog every unique shadow.

## Step 3: Formalize the System

Map what you found to a structured token system. Name things semantically, not by their visual appearance.

If you found `#6750A4` on every primary button, that's not `purple-500`, that's `color/semantic/interactive/primary`.

Build the variable collections in this order: primitives, then semantic tokens aliasing those primitives.

## Step 4: Build Components Against the Tokens

Recreate every component you found, but build it correctly this time: Auto Layout, variable bindings, all states, interactive.

Start with atoms. Don't touch screens until atoms are done.

## Step 5: Rebuild Screens Using Components

Recreate key screens using instances of your new components. This tests the system. Every hardcoded value you find means a token is missing.

## Useful Plugins for Auditing

**html.to.design**: Imports live websites into editable Figma frames. Best starting point for web apps.

**Design System Auditor**: Analyzes frames and scores adherence to the design system. Use after building the system to find where components aren't being used.

**Check Designs** (native Figma, 2026): Spots hardcoded values and suggests the correct variable. Run this before every handoff.

---

# Dev Handoff

## Before Handing Off

Run Check Designs. Every hardcoded value flagged needs to be replaced with the correct variable before the frame goes to engineering.

Every component in the handoff frame must be a library instance, not a detached copy. Use the Design System Auditor plugin to catch detached components.

Every text layer must reference a text style. Every color must reference a variable. Every spacing value in Auto Layout must reference a number variable.

## Handoff Page Structure

Keep the handoff page separate from the design page. Engineers should never have to scroll through design iterations.

```
Section: Navigation flows (annotated with transition types and triggers)
Section: Screen specs (key screens, annotated)
Section: Component specs (edge cases, interaction notes)
Section: Token reference (which collection to use for which platform)
```

## Layer Naming

Layer names become property names in Dev Mode. Name layers as if naming code.

```
Good: button-label, card-thumbnail, nav-tab-home, icon-leading
Bad: Rectangle 47, Group 3, Frame copy
```

Platform-specific names where they help:
- iOS: use Swift naming conventions (camelCase)
- Android: use Kotlin naming conventions (camelCase)
- Web: use kebab-case

## Code Connect

If using Code Connect (Org/Enterprise plans), map Figma components to their code counterparts. Once connected, Dev Mode shows the actual import and usage code from your codebase, not generated approximations.

## MCP Integration (2026)

Figma's MCP server lets AI tools like Claude Code read your design system directly. This means Claude Code can reference your actual tokens, component names, and variables rather than guessing.

For Claude Code to use the design system via MCP:
1. The Figma MCP server must be connected (it is, for this setup)
2. Components and variables must be published to a team library
3. Layer and variable names must match code names

When asking Claude Code to implement a component, it will read the library first and build with what already exists.

---

# Accessibility

Contrast minimums (WCAG AA):
- Normal text: 4.5:1
- Large text (18pt+ regular, 14pt+ bold): 3:1
- Interactive elements against adjacent colors: 3:1

Use the Stark plugin to check contrast during design. Don't defer this to handoff.

Build for Dynamic Type and large text sizes. Test your layouts with text at 150% and 200% scale. If things break, the layout is wrong, not the text size.

Color cannot be the only way information is conveyed. Every status indicator (error, success, warning) needs an icon or text label in addition to color.

Touch targets: 44pt minimum on iOS, 48dp on Android. If a component looks smaller, use padding to expand the tappable area without changing the visual size.

---

# Anti-Patterns

**Building components without Auto Layout**. They break when content changes. Always.

**Hardcoding color values in components**. Any hex value in a component is a token that doesn't exist yet. Create the token.

**Using static color styles instead of variables**. Variables are the 2026 standard. Styles are legacy for gradients and effects only.

**Creating a separate component for every minor variation**. Use variants, component properties, and slots. A library with 800 components that could be 80 is unmaintainable.

**Designing screens first**. Screens built without a component library are a collection of one-offs. They're not a design system. They're screenshots with layers.

**Skipping dark mode**. Dark mode is a first-class target, not a bonus feature.

**Not naming layers**. Unnamed layers make Dev Mode useless and code generation unreliable.

**Over-nesting tokens**. Three tiers (primitive, semantic, component) is the max for most projects. Two tiers is often enough.

**Building the whole system before testing it**. Build the token layer, then two or three components, then one real screen. If the tokens break, fix them before building 40 more components on top of broken foundations.

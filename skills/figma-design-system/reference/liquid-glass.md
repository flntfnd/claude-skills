# Liquid Glass in Figma

## Contents
- [Native Glass Effect](#native-glass-effect)
- [Critical Rules Before Starting](#critical-rules-before-starting)
- [Step-by-Step](#step-by-step)
- [Variable Bindings](#variable-bindings)
- [Glass Variants in Figma](#glass-variants-in-figma)
- [Building Glass Components](#building-glass-components)
- [Known Limitations](#known-limitations)
- [Glass Anti-Patterns](#glass-anti-patterns)

## Native Glass Effect

Figma's Glass effect exited beta on January 27, 2026 and applies to any layer type: frames, shapes, text, components. As of that release, Glass can also be applied to non-uniform corners with precise per-corner radius control, and the Splay parameter (how far the projected light spreads across the surface) and variable bindings on Glass properties shipped alongside GA. One glass effect per layer maximum.

Glass belongs on navigation-layer elements only: toolbars, tab bars, floating controls, sheets. Never on content.

## Critical Rules Before Starting

These are the most common failure points:

**Fill opacity must be below 100%.** Glass will not render on a layer whose fill is at 100% opacity. Reduce fill opacity or switch to a semi-transparent color before applying the glass effect.

**Glass and background blur cannot coexist on the same layer.** If both are applied, only the first effect in the stack renders. Remove any background blur from a layer before applying glass. If both are needed, layer them: glass object on top, background blur object beneath -- glass over background-blur renders correctly, the reverse breaks the glass.

**Glass needs content underneath to refract.** A glass element over a flat white or solid background shows nothing. The design needs imagery, gradients, or rich color content beneath the glass layer.

**Stack order matters.** Glass renders what is directly behind it in the layer stack. If the content meant to show through isn't behind the glass layer in canvas and layer panel, it won't appear.

## Step-by-Step

1. Set up the background: place a rich image, gradient, or layered content beneath where the glass element will sit.

2. Create a frame, shape, or component to receive the glass effect.

3. Set the fill to a semi-transparent value. `.regular` glass: white fill at 8-15% opacity. `.clear` glass: white fill at 4-8% opacity. Never leave fill at 100%.

4. In the Effects panel, click `+` and select Glass from the dropdown.

5. Open the effect settings and dial in the parameters:
   - **Light angle**: direction of the light source. 135-145° (upper-left) as the system default; keep consistent across every glass element in the file.
   - **Light intensity**: brightness of the projected light. 70-80%.
   - **Refraction**: optical distortion along the curved edge. 70-90%; above 90 text becomes unreadable fast. Start at 75.
   - **Depth**: how far the curved edge extends inward, creating the domed appearance. 10-30%; higher = thicker glass. Start at 15.
   - **Dispersion**: chromatic splitting (rainbow fringe) at the edge. 30-50%, subtle is better. Start at 35.
   - **Frost**: integrated background blur amount. 5-15% for nav bars and toolbars, 30-50% for sheets, 50-70% for modals.
   - **Splay**: how far the projected light spreads across the surface. 20-40%.

6. Add a 1px inside stroke, white 20-25% opacity, for the highlight border.

7. Add a drop shadow: black, 0 blur, 8-16px radius, 12-18% opacity, for depth.

## Variable Bindings

Glass properties bind to number variables directly, so the system stays token-driven:

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

Create a Glass variable collection with two modes, Regular and Clear, to preview the difference across all glass elements simultaneously.

## Glass Variants in Figma

To model Apple's `.regular` and `.clear` glass variants:

**Regular** (default, most UI surfaces): fill white 10-15% opacity, frost 8-15, refraction 75-80, depth 12-18.

**Clear** (over media-rich backgrounds, strong foreground content): fill white 4-8% opacity, frost 0-5, refraction 85-90, depth 8-12.

**Identity** (conditionally disabled): remove the glass effect entirely, or set `isEnabled` to false in the component property.

## Building Glass Components

Build glass elements as components with a `Variant` property (`Regular` / `Clear`) that switches between the two configurations via mode switch, not manual re-application.

Inside the component:
- Background layer: slot (accepts any content behind the glass)
- Glass frame: Auto Layout, semi-transparent fill, glass effect applied
- Highlight stroke: 1px inside stroke, white 20%
- Shadow: drop shadow for depth

The component must sit over actual content in the prototype/screen frame for the glass to render visibly. In an isolated component state on a white canvas it appears flat -- expected, not a bug.

## Known Limitations

- One glass effect per layer -- cannot stack multiple glass effects on a single layer.
- No environmental reflections. The specular device-motion highlight from native iOS 26 Liquid Glass isn't replicable in Figma -- it's a rendering-engine behavior, not a static effect.
- No SVG export support. Glass effects are stripped on SVG export.
- Not supported in Figma Sites.
- Background blur and glass conflict on the same layer -- remove background blur before adding glass.
- Glass won't render over solid fills at 100% opacity.

## Glass Anti-Patterns

Glass applied to list rows, cards, or body text -- navigation layer only.

Frost set too high on nav bars -- the glass becomes opaque and content legibility drops.

Refraction above 90 -- text and icons become distorted and unreadable.

Background blur left on the same layer before adding glass -- one cancels the other.

Inconsistent light angle across components -- pick one angle for the file (135-145°) and never deviate.

# Applying a Visual Style to an Existing Design

## Contents
- [When to Use This Workflow](#when-to-use-this-workflow)
- [This Is Not a Token Swap](#this-is-not-a-token-swap)
- [Order of Operations](#order-of-operations)
- [Figma Effect Recipes by Style](#figma-effect-recipes-by-style)
- [Style-Specific Component Changes](#style-specific-component-changes)

## When to Use This Workflow

When a design already exists and needs to be reskinned to a specific visual style. This is distinct from building from scratch or replicating an app -- the layout and content are known, but the visual language must change fundamentally.

Full style definitions -- Visual Signature, token modifications, component rules, per-platform implementation, "Wrong if" checklists -- live in the `visual-styles` skill, one file per style. Read the target style's file there before touching Figma. This file covers only how that gets executed inside Figma; it doesn't duplicate the style catalog.

## This Is Not a Token Swap

Applying a style in Figma means restructuring components, not just changing fill colors and font weights. If the Neo-Brutalism version looks like the Neo-Minimalism version with a yellow background, the style wasn't applied -- only the color variables were changed.

The test: open both versions side by side. If the component structures are identical (same Auto Layout, same layer organization, same shadow/border treatment), the style was not applied.

## Order of Operations

**1. Read the Visual Signature first.** Before touching Figma, read the Visual Signature section of the target style in the `visual-styles` skill. Identify every structural requirement and note the "Wrong if" checklist -- that's what success looks like.

**2. Audit existing components against the target style.** For each major component (navigation, hero, content list items, cards, buttons, CTA sections): does the current structure meet the Visual Signature requirements? List what must change structurally before any token changes.

**3. Restructure components first.** Make all structural changes before touching token values:
- Changing list items to cards (adding stroke and drop shadow layers)
- Adding or removing Auto Layout padding to shift spacing rhythm
- Changing corner radius on all frames (0 for Neo-Brutalism, large for Bento, blob shapes for Organic)
- Adding drop shadows with the correct properties for the style, or removing shadows entirely (Brutalism Pure, Calm)
- Changing section backgrounds (brand-color fills for Neo-Brutalism sections, single base color for Neumorphism)
- Restructuring navigation (solid colored bar for Neo-Brutalism, nearly invisible for Calm, glass for Liquid Glass -- see [liquid-glass.md](liquid-glass.md))

**4. Apply the Figma effects for the target style.** See recipes below.

**5. Update token values.** After the structure is correct, update the variable collections to match the target style's token specifications from the `visual-styles` skill. Switching the mode on a frame should now show the full style treatment, not just a color change.

**6. Verify against the Visual Signature checklist.** Run the "Wrong if" checklist from the `visual-styles` skill. If any condition applies, fix it before marking the style as applied.

## Figma Effect Recipes by Style

**Hard offset shadow (Neo-Brutalism):** Drop Shadow effect → X: 4, Y: 4, Blur: 0, Spread: 0, Color: #000000, Opacity: 100%. Blur must be 0 -- this is not a standard drop shadow, and blur above 0 is the single most common way this style gets implemented wrong.

**Glassmorphism / glass card:** Fill white at 12% opacity, Background Blur effect 16px, stroke 1px white at 25% opacity (inside). The frame must sit over rich content -- glass over a flat white background is invisible.

**Neumorphism dual shadow:** Drop Shadow 1: X -4, Y -4, Blur 8, Color #FFFFFF, Opacity 70%. Drop Shadow 2: X 4, Y 4, Blur 8, Color #000000, Opacity 20%. No stroke. No fill color different from the background -- every surface matches the page background exactly.

**Futuristic glow border:** Stroke 1px, accent color at 20% opacity. Drop Shadow X: 0, Y: 0, Blur: 12, Color: accent, Opacity: 60%.

**Grain texture (Texture/Tactile):** Noise fill rectangle at 3-5% opacity as the top layer of every surface frame, Blend Mode: Overlay.

## Style-Specific Component Changes

The most commonly wrong components, and what must change for each:

**Neo-Brutalism -- content list items must become cards.** Select the list item component. Add a stroke layer: 2px, #000000, Center. Add a drop shadow: X 4, Y 4, Blur 0, Color #000, 100%. Set corner radius to 0. Add 12-16px Auto Layout padding on all sides. Do this for every item in every list.

**Neo-Minimalism -- remove all card borders and shadows.** Remove strokes and all drop shadows from every component. Separation between items comes from Auto Layout spacing (20-32px gap) only, never borders.

**Brutalism Pure -- remove all decorative styling.** Remove all drop shadows system-wide. Remove all strokes except explicit 1px dividers. Set all corner radii to 0. Reduce all fills to the two-color palette. No fills on section backgrounds -- all sections share the same paper background.

**Neumorphism -- all surfaces must match one base color.** Set the page background, all card fills, and all button fills to the exact same base color (#E4EBF5 light, #1E1E2E dark). Any surface that differs in color breaks the style -- depth comes only from the dual shadow pair.

**Organic/Biomorphic -- rectangles must become blobs.** For each card or container, set asymmetric corner radius values (e.g. top-left 60%, top-right 40%, bottom-right 70%, bottom-left 30%), or use a vector blob shape as the container frame instead of a rectangle. Standard rounded rectangles are not Organic.

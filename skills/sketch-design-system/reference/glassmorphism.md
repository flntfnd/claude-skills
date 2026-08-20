# Glassmorphism in Sketch

Sketch has no native glass effect. Apple's Liquid Glass as defined in iOS 26 is not replicable natively in Sketch -- Figma's Glass effect (exited beta January 2026) has no Sketch equivalent. Use the manual layering technique below for navigation elements that need a glass treatment.

## Contents
- [Manual Glass Technique](#manual-glass-technique)
- [Light Angle Consistency](#light-angle-consistency)
- [Glass Component as Symbol](#glass-component-as-symbol)
- [Per-Context Tuning](#per-context-tuning)

## Manual Glass Technique

Layer stack, bottom to top:

1. **Background content** -- the image, gradient, or rich content that shows through the glass. Must be present; glass over a flat white background shows nothing.

2. **Frost layer** -- a rectangle the size of the glass element.
   - Fill: white at 0% opacity (transparent)
   - Effect: Background Blur, 12-20px for nav bars, 30-50px for sheets
   - This produces the frosted appearance

3. **Fill layer** -- same rectangle, above the frost layer.
   - Fill: white at 8-15% opacity for `.regular` glass
   - Fill: white at 4-8% opacity for `.clear` glass
   - Layer opacity: 100% (opacity lives on the fill only)

4. **Highlight stroke** -- same rectangle.
   - No fill
   - Border: inside, 1px, white at 20-25% opacity
   - This is the edge highlight

5. **Content layer** -- text, icons, whatever sits on top of the glass

6. **Shadow** -- drop shadow on the glass frame rectangle
   - Color: black at 12-18% opacity
   - Offset: 0x, 4-8y
   - Blur: 16-24px

## Light Angle Consistency

Highlight strokes simulate the light source. Keep all glass elements using the same light angle across the file -- upper-left is the system default: highlights on top-left edges, shadows on bottom-right.

## Glass Component as Symbol

Wrap the full layer stack into a Symbol. Expose overrides for:
- Background image/content (nested Symbol)
- Frost intensity (layer visibility toggle for light/medium/heavy frost variants)
- Content (nested Symbol for whatever sits on the glass)

## Per-Context Tuning

Frost is Background Blur intensity -- tune per context, same as the Figma system's Frost parameter:

- Nav bar: 12-16px blur, fill white 10%
- Sheet: 24-32px blur, fill white 15%
- Modal: 32-48px blur, fill white 18%

Three Symbol variants map to this: `Glass/Nav`, `Glass/Sheet`, `Glass/Modal`. Don't reuse one blur value across all three -- depth role should be visually legible from blur alone.

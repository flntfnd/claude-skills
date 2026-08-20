# Glassmorphism in Sketch

Sketch has a native **Glass** effect (shipped in the 2025.2.1 "Barcelona" release, August 2025) -- it is not manual-only. Apply it via the `+` next to **Effects** in the Inspector → **Glass**. Two modes: **Auto** (a standard frosted-glass appearance matching Apple's platform default -- use this for iOS/iPadOS/macOS work) and **Custom**, which exposes seven parameters: Blur, Distortion (surface waviness), Depth (blur edge behavior simulating glass thickness), Chromatic Aberration, Brightness, Saturation, and Specular Highlights.

Glass applies to Shapes, Images, Text, Frames, and Graphics. It does **not** apply to Groups or Symbol Instances directly -- put the effect on a Shape or Frame layer inside the Symbol, not on a Group wrapping the stack.

Use native Glass by default. Fall back to the manual layering technique below only when: matching this system's explicit Figma glassmorphism token architecture (separate Frost/Fill/Border/Shadow layers, each independently tunable and each mapped to its own token) matters more than using the native effect; the glass needs to sit on a Group; or the file targets a Sketch version older than 2025.2.1.

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

Wrap the full layer stack (manual technique) or the single Glass-effect layer (native technique) into a Symbol. Expose overrides for:
- Background image/content (nested Symbol)
- Frost intensity (layer visibility toggle for light/medium/heavy frost variants, or a Custom-mode Blur override on the native effect)
- Content (nested Symbol for whatever sits on the glass)

## Per-Context Tuning

Frost is Background Blur intensity (manual) or the Custom Blur parameter (native) -- tune per context, same as the Figma system's Frost parameter:

- Nav bar: 12-16px blur, fill white 10%
- Sheet: 24-32px blur, fill white 15%
- Modal: 32-48px blur, fill white 18%

Three Symbol variants map to this: `Glass/Nav`, `Glass/Sheet`, `Glass/Modal`. Don't reuse one blur value across all three -- depth role should be visually legible from blur alone.

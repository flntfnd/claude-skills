# Texture / Tactile

Grain, noise, paper, fabric. Surfaces that feel like they have physical material underneath them. A reaction to the sterile perfection of flat design and AI-generated imagery. Texture signals human-made. Used with restraint -- a 3-5% grain overlay transforms a flat gradient into something dimensional.

**When to use**: Any style can incorporate texture as a layer. Works especially well with Neo-Minimalism, Organic, Editorial, and Neo-Brutalism. Least compatible with Futuristic and pure Glassmorphism.

## Visual Signature

Identifiable at a glance by: surfaces that visually feel like they have physical material -- paper, linen, grain, concrete. Not photorealistic, but clearly not flat digital. A grain/noise overlay at 3-6% opacity over gradients or solid backgrounds is the minimum. More intense textures (paper grain, fabric weave patterns via CSS) for specific surfaces.

**Structural requirements:**
- Global grain: SVG `feTurbulence` filter or CSS noise overlay at 3-5% opacity applied to the page background. Without this, the style isn't applied.
- Surface differentiation: different texture intensities for different surfaces. Page background: subtle (3%). Cards: slightly more visible (5-7%). Hero elements: most pronounced.
- Color: warm or earthy. Flat, pure colors fight the texture. Slightly desaturated, slightly warm palette that reads as "printed" rather than "emitted".
- Typography: warm-weight, humanist sans or serif. Crisp but not sterile.

**Wrong if:** backgrounds and surfaces are flat solid colors or clean gradients with no grain overlay, the design looks like any other clean flat-design execution with slightly warm colors.

## Token Modifications

```
texture/grain/opacity/light:  0.03 - 0.05 (subtle)
texture/grain/opacity/medium: 0.06 - 0.10
texture/grain/opacity/heavy:  0.12 - 0.18  (use rarely)

texture types:
  grain:   SVG feTurbulence noise filter
  paper:   subtle fiber pattern at low opacity
  canvas:  woven texture, slightly more prominent
  linen:   fine diagonal weave
```

## Implementation

**Web (primary platform for texture)**
```css
/* SVG noise filter as a CSS pseudo-element */
.textured::after {
  content: '';
  position: absolute;
  inset: 0;
  background-image: url("data:image/svg+xml,..."); /* SVG noise */
  opacity: 0.04;
  pointer-events: none;
  mix-blend-mode: overlay;
}

/* Or via CSS filter on a ::before */
.grain-bg::before {
  content: '';
  position: fixed;
  inset: -50%;
  width: 200%;
  height: 200%;
  background: url('/noise.png') repeat;
  opacity: 0.04;
  pointer-events: none;
}
```

**iOS / SwiftUI**
Apply grain as a `ZStack` overlay with a noise image at low opacity, using `.blendMode(.overlay)`. Don't bake texture into screenshots -- use a view modifier so it renders correctly at all display scales.

**Android / Compose**
Canvas-drawn Perlin noise overlay on `drawBehind`. Use `BlendMode.Overlay` for correct blending. Keep opacity low -- Android's canvas blend modes can look heavier than web.

Signature GPU technique (SVG `feTurbulence` / AGSL turbulence / Win2D `TurbulenceEffect` -- the grain IS the style): see `SKILL.md` → Style-to-Technique Mapping, item 12.

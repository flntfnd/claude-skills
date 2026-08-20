# Organic / Biomorphic

Flowing, irregular shapes. Nature-inspired curves. No hard corners or rigid geometry. Asymmetric balance. Gradient washes that suggest light on organic surfaces. Illustrations and shapes feel hand-crafted or grown. Color palettes from nature: earth tones, botanical greens, sky blues, terracotta, sage.

**When to use**: Wellness, meditation, health, food, sustainability, any product that benefits from a non-digital, living-world feeling.

## Contents
- [Visual Signature](#visual-signature)
- [Token Modifications](#token-modifications)
- [Component Rules](#component-rules)
- [Platform Implementation](#platform-implementation)

## Visual Signature

Identifiable at a glance by: blob-shaped background elements and card containers (CSS `border-radius` values above 40%, or SVG clip-paths), soft gradient fills that shift between nature-derived colors, asymmetric layouts where elements don't align to a strict grid, and an overall sense of warmth and imperfection.

**Structural requirements:**
- Cards and containers: irregular border-radius (e.g., `border-radius: 60% 40% 70% 30% / 40% 60% 30% 70%`) or SVG clip-path blobs. NOT standard rectangles with soft corners.
- Background: gradient blobs or organic shapes as decorative background layers. Multiple layered `radial-gradient` at low opacity, or SVG blob elements positioned behind content.
- Color: nature palette. No pure black, no pure white, no corporate blues. Warm earth tones, botanical greens, soft terracotta.
- Layout: intentionally asymmetric. Text columns offset rather than centered, elements that don't snap to a strict grid.

**Wrong if:** containers are rectangles (even with large radius), layout is symmetrically grid-aligned, colors are standard corporate/tech palette, background is a flat solid color with no gradient or organic shapes.

## Token Modifications

```
radius: irregular and large
  container: 40-60% of smallest dimension (approaching circle)
  blob shapes: CSS clip-path or SVG path, not border-radius

color:
  primary palette: muted natural tones
    terracotta: #C4704A
    sage:       #8FAB8A
    sky:        #6B9FBF
    sand:       #D4B896
    earth:      #7B5C3E

  gradients: soft, two-stop, low contrast
    "sunrise": #FFD4A3 → #FFA07A
    "forest":  #A8C5A0 → #5A7A5C
    "ocean":   #B3D4E8 → #6A9CB8

spacing: gentle — avoid hard multiples-of-8 rhythm, let it breathe
  prefer: 18, 28, 44 over 16, 24, 40

typography: rounded sans or humanist serif
  variable weight axis, warm not mechanical
```

Pending Rob's own personal taste extraction (TASTE.md, not yet built): the nature-palette hex values above are generic defaults. Once TASTE.md exists, it overrides the specific values here.

## Component Rules

Shapes are the primary design element. Use SVG blobs and irregular containers instead of rectangles. Buttons have pill shapes. Cards use high radius. Background shapes add depth without hard edges. Animations are slow and gentle -- easing curves that decelerate softly. No jarring cuts or snappy springs.

## Platform Implementation

**iOS / SwiftUI**
Use `.clipShape(Capsule())` for pill elements. Custom `Shape` implementations for blob backgrounds. `Path` for irregular organic forms. Gradients via `LinearGradient` and `RadialGradient`. Spring animations with high damping ratio (slow, no bounce).

**Android / Compose**
Use `GenericShape` from Compose for organic clip paths. `Brush.linearGradient` for organic color washes. `RoundedCornerShape(50%)` for pill shapes.

**Web**
```css
:root {
  --radius-blob: 30% 70% 70% 30% / 30% 30% 70% 70%;
  --gradient-sunrise: linear-gradient(135deg, #FFD4A3, #FFA07A);
  --gradient-forest:  linear-gradient(135deg, #A8C5A0, #5A7A5C);
  --easing-organic: cubic-bezier(0.4, 0, 0.2, 1);
}

.organic-card {
  border-radius: var(--radius-blob);
  padding: 2rem;
  transition: border-radius 0.8s var(--easing-organic);
}
.organic-card:hover {
  border-radius: 60% 40% 30% 70% / 60% 30% 70% 40%;
}

.blob-section {
  clip-path: ellipse(80% 70% at 50% 50%);
  background: var(--gradient-forest);
}

/* Pill buttons */
.btn-organic {
  border-radius: 9999px;
  padding: 0.75rem 2rem;
  border: none;
  background: var(--gradient-sunrise);
  transition: transform 0.4s var(--easing-organic),
              box-shadow 0.4s var(--easing-organic);
}
.btn-organic:hover {
  transform: scale(1.03) translateY(-2px);
  box-shadow: 0 12px 24px rgba(0,0,0,0.12);
}
```
SVG blob shapes generated programmatically or from a blob generator (blobmaker.app). Animate blob `d` attributes with GSAP MorphSVG or CSS `offset-path` for organic motion. `scroll-behavior: smooth` at the root.

Signature GPU technique (SVG `feTurbulence` + `feDisplacementMap` liquid distortion, Canvas 2D / Three.js noise-displaced blob forms): see `SKILL.md` → Style-to-Technique Mapping, item 11.

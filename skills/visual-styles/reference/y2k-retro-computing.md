# Y2K / Retro Computing

Nostalgia for early internet aesthetics: pixelation, CRT scan lines, terminal green, dot-matrix type, Windows 3.1 UI chrome, early web brutalism. Filtered through contemporary sensibilities -- high resolution, performant, intentional. The aesthetic is nostalgic but the craft is contemporary.

**When to use**: Niche apps, gaming-adjacent products, developer tools targeting a specific generational audience, music apps, creative tools where the retro feel is on-brand.

## Contents
- [Visual Signature](#visual-signature)
- [Token Modifications](#token-modifications)
- [Platform Implementation](#platform-implementation)

## Visual Signature

Identifiable at a glance by: CRT-green or amber monochrome terminal palette (or Windows 3.1 bevel-border chrome), scanline overlay, monospace type throughout, and at least one overtly retro structural element (beveled borders, blinking cursor, terminal-style text rendering, pixelated elements). Should make someone who lived through the early internet immediately feel nostalgia.

**Structural requirements:**
- Color scheme: commit to one era. Terminal (near-black + phosphor green or amber). OR Windows 3.1 (grey chrome + blue title bars + bevel borders). OR early web (primary colors, Times New Roman, inline borders).
- Scanlines: CSS `repeating-linear-gradient` overlay at 5-8% opacity on the page background. Must be present -- it's the most recognizable element.
- Typography: `font-family: 'JetBrains Mono', 'Courier New', monospace` everywhere. No proportional sans-serif.
- Structural element: at least one of -- bevel-border UI chrome (box-shadow for raised/sunken effect), blinking text cursor, terminal prompt indicator (`>`), or pixelated/dithered decorative element.

**Wrong if:** the type is a proportional sans-serif, there are no scanlines, the color palette is contemporary tech (dark grey, blue accent), nothing reads as explicitly retro-computational.

## Token Modifications

```
typography:
  primary family: monospace (JetBrains Mono, Courier New, IBM Plex Mono)
  display: bitmap font or pixel font (as image/SVG, not web font where possible)

color schemes (pick one):
  terminal green: #0A0A0A bg, #00FF41 text, #003B00 dim
  amber CRT:      #0F0A00 bg, #FF9900 text, #3D2400 dim
  blue screen:    #0000AA bg, #AAAAAA text, #FFFFFF accent
  grayscale CRT:  #1A1A1A bg, #D4D4D4 text, #888888 dim

effects:
  scanline: repeating horizontal lines at 2px, 3-8% opacity
  crt-curve: subtle vignette and slight barrel distortion on outer edges
  pixel-grid: 1px grid overlay on image surfaces
  noise: heavier grain (10-15%) than standard texture style

radius: 0 (everything square) or large (rounded screens simulating CRT)
borders: 2-4px solid, Windows-style bevel effects
```

## Platform Implementation

**iOS / SwiftUI**
Apply the color palette and monospace typography. Pixel fonts don't render cleanly at all sizes -- use them display-only (large sizes) or as image assets. CRT scan lines via a `Canvas` overlay view with `drawRect` drawing horizontal lines at 2px intervals, 5-8% opacity. Rounded screen effect via outer vignette applied as a `RadialGradient` overlay. Keep system interactions intact.

**Android / Compose**
`FontFamily.Monospace` for body. Canvas-drawn scan line overlay on the root scaffold via `drawBehind`. Lock to dark theme. System navigation unchanged.

**Web**
Web is the most natural home for this style -- the full range of CSS effects is available here.
```css
:root {
  --crt-green: #00FF41;
  --crt-bg: #0A0A0A;
  --crt-dim: #003B00;
  --font-mono: 'JetBrains Mono', 'Courier New', monospace;
}

body {
  background: var(--crt-bg);
  color: var(--crt-green);
  font-family: var(--font-mono);
}

/* Scan lines */
body::after {
  content: '';
  position: fixed;
  inset: 0;
  background: repeating-linear-gradient(
    0deg,
    transparent,
    transparent 2px,
    rgba(0,0,0,0.08) 2px,
    rgba(0,0,0,0.08) 4px
  );
  pointer-events: none;
  z-index: 9999;
}

/* CRT screen flicker (subtle) */
@keyframes flicker {
  0%, 100% { opacity: 1; }
  92%       { opacity: 0.97; }
  94%       { opacity: 1; }
}
.crt-screen { animation: flicker 8s infinite; }

/* Pixel-style border (Windows 3.1 bevel) */
.win31-box {
  border-top:    2px solid #DFDFDF;
  border-left:   2px solid #DFDFDF;
  border-right:  2px solid #808080;
  border-bottom: 2px solid #808080;
  padding: 4px;
}

/* Terminal cursor blink */
.cursor::after {
  content: '▋';
  animation: blink 1s step-end infinite;
}
@keyframes blink {
  50% { opacity: 0; }
}
```
Keep effects subtle enough that content remains readable. Scan lines at above 10% opacity destroy text legibility.

Signature GPU technique (full CRT post-processing shader: barrel distortion + chromatic aberration + scanlines + phosphor tint, `FilmPass`/`ShaderPass` in Three.js): see `SKILL.md` → Style-to-Technique Mapping, item 13.

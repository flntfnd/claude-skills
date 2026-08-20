# Brutalism (Pure)

Stripped to structure. No decorative layer. Monochrome or near-monochrome. Raw HTML aesthetic with contemporary performance standards. Type is the primary visual element. Functional hierarchy through spacing and weight alone, not color or decoration. Confrontational and honest.

**When to use**: Developer tools, technical documentation interfaces, niche platforms where the audience reads raw aesthetic as credibility. Not for consumer products.

## Visual Signature

Identifiable at a glance by: extreme typographic scale contrast (display text at 6-8rem next to body text at 1rem, nothing in between), heavy horizontal rules as the only structural dividers, monospace or raw grotesque type, no shadows anywhere, no rounded corners, no color beyond black/white and at most one stark accent. The layout looks like a well-designed HTML document -- functional, intentional, no chrome. It should feel slightly confrontational.

**Structural requirements for common patterns:**
- Navigation: plain text, no background, no border, no padding -- just the name and links at the top of the document flow. Could be a simple flex row with a `border-bottom: 1px solid #000` or nothing at all.
- Hero: massive display type (`clamp(3rem, 10vw, 8rem)`), light or regular weight, running across the full column. Subtext in small body size. No background fill. Heavy `<hr>` below.
- Content lists: either a raw table (column headers, data rows, no styling), or items separated only by a 1-2px `border-bottom: 1px solid #000`. No card containers, no shadows, no backgrounds on rows.
- Sections: separated exclusively by `<hr>` (1-2px solid black) with generous vertical margin. No background color changes. No cards or containers.
- Links/CTAs: underlined text. On hover: background/color invert (`background: #000; color: #fff`). No buttons with fills.

**Wrong if:** any element has a box-shadow, any corner has border-radius, colors beyond black/white/one-accent appear, the typography scale feels moderate (no extreme contrast between large and small sizes), any section has a background fill.

## Token Modifications

```
color palette: two colors maximum
  primary background: #FFFFFF or #F0EDE8
  primary text: #000000
  accent (use sparingly): one saturated color or none

radius: all 0
border: 1px solid #000 or no border
shadow: none
spacing: large and irregular-feeling, not mathematically perfect
typography: monospace or grotesque sans
  size: extremes -- either very large or very small, little in between
```

Pending Rob's own personal taste extraction (TASTE.md, not yet built): the accent color choice, if any, is a generic placeholder. Once TASTE.md exists, it overrides the specific value here.

## Component Rules

No cards as visual containers -- use whitespace and type hierarchy to create zones. No icons except where functional. No illustrations. Tables are the primary data layout. Buttons are underlined text or minimal bordered rectangles. Interactive states are text decoration changes and cursor changes, not color fills.

## Platform Implementation

**iOS / SwiftUI**
`.background(Color.clear)`, custom drawn borders via `.overlay(Rectangle().stroke(Color.black, lineWidth: 1))`, aggressive typography scale. Keep system haptics and animations -- brutalism is a visual language, not a behavioral one. System components should be minimally restyled, not replaced.

**Android / Compose**
`RectangleShape` everywhere. `Border(1.dp, Color.Black)`. `FontFamily.Monospace` for body text. Suppress elevation on all components (`elevation = 0.dp`). Keep system navigation and gesture behavior unchanged.

**Web**
```css
:root {
  --font-mono: 'JetBrains Mono', 'Courier New', monospace;
  --color-ink: #000000;
  --color-paper: #FFFFFF;
}

body {
  font-family: var(--font-mono);
  color: var(--color-ink);
  background: var(--color-paper);
  max-width: 900px;
  margin: 0 auto;
  padding: 2rem;
}

h1 { font-size: clamp(2rem, 8vw, 6rem); line-height: 1; }
h2 { font-size: clamp(1.2rem, 4vw, 2.5rem); }
p  { font-size: 1rem; line-height: 1.6; max-width: 65ch; }

a { color: inherit; text-decoration: underline; text-underline-offset: 3px; }
a:hover { background: var(--color-ink); color: var(--color-paper); }

hr { border: none; border-top: 1px solid var(--color-ink); margin: 2rem 0; }

button, .btn {
  font-family: inherit;
  font-size: 0.875rem;
  background: none;
  border: 1px solid var(--color-ink);
  padding: 0.5rem 1rem;
  cursor: pointer;
}
button:hover { background: var(--color-ink); color: var(--color-paper); }
```
No border-radius. No shadows. No colors beyond black and white unless a single accent is specified. Layout is document-flow with explicit column structure via CSS Grid.

Signature GPU technique (none, intentionally) and the sole permitted animation (link hover inversion): see `SKILL.md` → Style-to-Technique Mapping, item 3.

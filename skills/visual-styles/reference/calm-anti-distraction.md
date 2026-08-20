# Calm / Anti-Distraction

Deliberate restraint. Extreme whitespace. Limited color. No notifications aesthetic. Designed for extended use without fatigue. Every visual element serves a purpose -- decoration is a cost, not a default. Motion is almost absent. Type is generous and unhurried. The experience has the feel of a well-designed physical object.

**When to use**: Reading apps, writing tools, meditation, journaling, any context where the user benefits from the interface receding completely. Also a sound default for enterprise and professional tools.

## Contents
- [Visual Signature](#visual-signature)
- [Token Modifications](#token-modifications)
- [Component Rules](#component-rules)
- [Platform Implementation](#platform-implementation)

## Visual Signature

Identifiable at a glance by: extreme whitespace (padding and margins 1.5-2x what you'd use in any other style), a single muted accent color used extremely sparingly (one or two places maximum), generous line-height and letter-spacing that makes reading feel unhurried, and a near-total absence of UI chrome. Navigation almost disappears. There are no badges, indicators, unread counts, or notification-style elements. The content is everything; the interface is almost nothing.

**Structural requirements:**
- Spacing: double the base spacing scale. If the default is 24px between sections, this is 48px. The whitespace IS the design.
- Typography: large base size (18-20px body), generous line-height (1.7-1.9), moderate tracking. Type should invite extended reading.
- Color: maximum two colors in use at any time -- near-black text, near-white background, and one muted accent used only for the single most important interactive element. Nothing else.
- Navigation: minimal to invisible. A small logo or title, one or two links. No background, no border, no weight. Should feel like it might not be there.
- Interactive elements: single underline or color change on hover. No filled buttons for secondary actions. No icons unless they're the only possible representation.
- Motion: near-zero. If anything animates, it's a slow opacity fade (300-500ms ease). No spring physics, no transforms, no scroll animations.
- No: badges, unread counts, notification dots, progress bars for non-essential tasks, tooltips that appear unprompted, any element that bids for attention.

**Wrong if:** anything bids for the user's attention beyond the primary content, there is more than one accent color, spacing feels "normal" rather than exceptionally generous, navigation has visual weight, any element animates with spring physics or transforms.

## Token Modifications

```
color:
  palette: maximum three values
  background: very soft warm white or very dark warm gray
  text: near-black or near-white (never pure black or pure white)
  accent: single muted color, used only for interactive elements

  light palette: #FAFAF8 (bg), #2C2C2A (text), #6B9FBF (accent, used sparingly)
  dark palette:  #1A1A18 (bg), #E8E8E4 (text), #A0B8C8 (accent)

spacing: everything gets 25-50% more space than you think it needs
  section spacing → xxxl (64px+)
  content padding → xl (24-32px)
  line height     → 1.7-1.9 for body

radius: mid-range (8-16px) — not sharp, not pill
typography: regular weight for body (400), medium for emphasis (500), nothing heavier
motion: none as default
  transitions that exist: 200-300ms ease-in-out opacity only
  no sliding, no bouncing, no spring
```

Pending Rob's own personal taste extraction (TASTE.md, not yet built): the accent hex values above are generic defaults. Once TASTE.md exists, it overrides the specific values here.

## Component Rules

One action per screen region. Navigation is hidden or minimal until needed. No badges on content items. No empty-state illustrations -- use text only. No decorative dividers -- use spacing. Buttons are text or minimal outline -- no filled containers except for the single most important action. Focus indicators are the only bright interactive signal.

## Platform Implementation

**iOS / SwiftUI**
`.navigationBarHidden(true)` or custom minimal nav. Tab bar hidden during reading. `.scrollContentBackground(.hidden)`. `.preferredColorScheme` respects system setting. `Text` line height via `.lineSpacing(6)`. Motion off by default -- check `accessibilityReduceMotion` and skip even the minimal transitions if it's on.

**Android / Compose**
Full edge-to-edge with `enableEdgeToEdge()`. Hide system bars during content reading with `WindowInsetsController`. `lineHeight` set to 1.7x font size in `TextStyle`. `MotionScheme.standard()` with very slow specs for the rare transitions that exist.

**Web**
```css
:root {
  --color-bg:      #FAFAF8;
  --color-text:    #2C2C2A;
  --color-accent:  #6B9FBF;
  --color-muted:   #888884;
  --font-reading:  'Inter', system-ui, sans-serif;
  --measure:       65ch;
  --leading:       1.8;
}

body {
  font-family: var(--font-reading);
  font-size: 1.125rem;
  line-height: var(--leading);
  color: var(--color-text);
  background: var(--color-bg);
  font-optical-sizing: auto;
}

/* Content column: never wider than comfortable reading width */
.content {
  max-width: var(--measure);
  margin-inline: auto;
  padding-inline: 1.5rem;
}

/* No transitions by default */
* { transition: none; }

/* Only transition opacity, only when motion is acceptable */
@media (prefers-reduced-motion: no-preference) {
  .fade-in {
    transition: opacity 250ms ease-in-out;
  }
}

/* Generous section spacing */
section + section { margin-top: 5rem; }
h1, h2, h3 { line-height: 1.25; font-weight: 500; }
h1 { font-size: clamp(1.75rem, 4vw, 2.5rem); }

/* Minimal button */
.btn-calm {
  background: none;
  border: 1px solid currentColor;
  padding: 0.5rem 1.25rem;
  border-radius: 6px;
  font-size: 0.875rem;
  color: var(--color-accent);
  cursor: pointer;
  transition: background 200ms ease-in-out;
}
.btn-calm:hover { background: color-mix(in srgb, var(--color-accent) 10%, transparent); }

/* Dark mode */
@media (prefers-color-scheme: dark) {
  :root {
    --color-bg:   #1A1A18;
    --color-text: #E8E8E4;
    --color-muted: #6A6A66;
  }
}
```

Signature GPU technique (none, deliberately -- opacity-only transitions, no spring physics anywhere): see `SKILL.md` → Style-to-Technique Mapping, item 14.

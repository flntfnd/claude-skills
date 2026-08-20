# Neo-Minimalism

Minimalism with warmth. Not the cold, sterile white-on-white minimalism of 2018 -- this has texture, personality, and emotional weight. Organic spacing rhythms replace rigid 8pt grids. Serif type pairs with restrained sans. The interface feels considered, not empty.

**When to use**: Productivity apps, lifestyle, health, finance, anything that needs clarity without feeling clinical.

## Visual Signature

Identifiable at a glance by: large areas of warm off-white breathing room, serif display type at light weight, zero card borders, content separated by space alone or hairline rules (never full borders or shadows). Navigation is nearly invisible -- no background fill, no border, just a name and minimal links against the warm white. Lists of items sit on the page with space between them, not boxed into cards.

**Structural requirements for common patterns:**
- Navigation: text-only, no background, no border, floats above content
- Hero: oversized serif display type at light (300) weight, significant vertical padding above and below, subtext in regular-weight sans at comfortable reading size
- Content lists (work, features, etc.): items separated by a single 0.5-1px warm-tinted hairline divider or by space only -- no borders wrapping items, no card backgrounds
- Sections: delineated by whitespace and a hairline rule if needed, not by background color changes or cards
- CTAs: text links or minimal outlined buttons -- never filled contained buttons for secondary actions

**Wrong if:** any component has a visible box/card border, shadows appear anywhere, the spacing feels tight, typography is all sans-serif, backgrounds are pure white (#FFFFFF) rather than warm off-white.

## Token Modifications

```
color/primitive/neutral   — warm-tinted neutrals, not pure gray
  100: #FAF9F7
  200: #F5F3EE
  300: #E8E4DC
  500: #B5AFA4
  700: #6B6560
  900: #2A2622

color/semantic/background/primary  → warm white (#FAF9F7)
color/semantic/background/secondary → #F5F3EE
color/semantic/text/primary         → #2A2622 (warm near-black)
color/semantic/border/default       → rgba(42,38,34,0.12)

radius/sm   → 6
radius/md   → 10
radius/lg   → 18
radius/xl   → 28

spacing — expand base by 25%:
  base → 20
  lg   → 28
  xl   → 40

typography/weight/heading   → Light (300) for display, Regular (400) for body
typography/family/heading   → Serif (NYT Cheltenham, Canela, or platform serif)
typography/family/body      → SF Pro / Roboto / Inter at Regular
```

Pending Rob's own personal taste extraction (TASTE.md, not yet built): these hex/token values are generic defaults, not verified brand preference. Once TASTE.md exists, it overrides the specific values here.

## Component Rules

Single-pixel hairline dividers, not full borders. Generous whitespace. No card borders -- elevation through spacing and subtle background tint difference, not outlines. Icons are line-weight, not filled. Interactive elements have minimal visual footprint: text buttons preferred over contained buttons for secondary actions.

## Platform Implementation

**iOS / SwiftUI**
Use `.font(.system(.body, design: .serif))` for editorial content. Secondary backgrounds use `Color(.secondarySystemBackground)` with opacity modifier for warmth. Spacing uses `Spacing.xl` between sections. Avoid `List` row separators -- use custom spacing instead.

**Android / Compose**
Use `MaterialTheme.typography` with Roboto Flex at low weight for headlines. Surface colors reference the warm neutral palette. `Divider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f))` for hairline separators.

**Web**
`--font-heading: 'Canela', Georgia, serif` in `:root`. Line heights 1.6-1.8 for body. `letter-spacing: 0.02em` on display type. Borders at 0.5-1px, warm neutral color.

Signature GPU technique, cross-platform code samples, and Windows notes: see `SKILL.md` → Style-to-Technique Mapping, item 1.

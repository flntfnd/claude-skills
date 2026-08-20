# Bento Grid

Modular card-based layout. Content organized into a grid of variably-sized rectangular cells. Some cells span multiple columns or rows. The grid is the design -- the bento structure is explicit and intentional, not just a layout tool. Popularized by Apple's product pages and widely adopted in dashboards and landing pages.

**When to use**: Dashboards, home screens, marketing surfaces, any context where varied content types need to coexist at the same visual level. Strong fit for iPad and large-screen layouts.

## Contents
- [Visual Signature](#visual-signature)
- [Token Modifications](#token-modifications)
- [Component Rules](#component-rules)
- [Platform Implementation](#platform-implementation)

## Visual Signature

Identifiable at a glance by: the entire page content organized into a grid of variably-sized rounded-corner tiles. The grid IS the layout -- there is no traditional linear section flow. One or two large tiles dominate, surrounded by smaller tiles. Size communicates hierarchy. The background between tiles shows through as negative space.

**Structural requirements:**
- Layout: CSS Grid with explicit column/row template. ALL content lives inside tiles. No free-flowing content outside the grid.
- Tile sizes: at minimum three distinct sizes (large 2x2, medium 2x1, small 1x1). Equal-size grids are not Bento -- they're card grids.
- Radius: generous and consistent. 20-32px on all tiles. Same radius on every tile.
- Gap: 12-20px between tiles, visually evident, matching the background color.
- Featured tile: the largest cell uses a brand or accent color background and contains the highest-priority content.
- Content per tile: one concept per tile. A tile with a metric, a tile with a stat, a tile with an action. Not mixed content.

**Wrong if:** tiles are all the same size, content flows in a linear column outside the grid, there's no clear size hierarchy between tiles, radius is inconsistent between tiles.

## Token Modifications

```
radius: 16-32px "organic modularity" range
  card: 20-24px for standard cells
  featured: 28-32px for large hero cells
  All cards must share the same radius family -- mixing tight and generous radius
  within the same grid breaks visual cohesion.

spacing/grid-gap:  16-20px between cells
spacing/cell-pad:  24-32px inner card padding

color/semantic/surface — mild variation between cells for visual rhythm:
  cell/primary:   background/secondary
  cell/featured:  brand color or strong accent (1-2 cells max)
  cell/muted:     background/tertiary
```

## Component Rules

Every cell is a card. All cards share the same border radius. Cards contain a single content type: one metric, one visual, one action. Never mix content types inside one cell. The featured cell (the large one) gets the brand color. Support for spanning: 1x1, 2x1, 1x2, 2x2, 3x1. Grid is always consistent -- cells align to the same column tracks.

Visual hierarchy is encoded in size: larger cells signal more important content. If every cell is the same size, you've built a regular grid with rounded corners -- not a bento. The largest cell should contain the highest-value information for the context.

**Accessibility -- source order matters.** CSS Grid allows placing a box anywhere visually, which makes it easy to create layouts where the DOM order is totally disconnected from the visual reading order. Screen readers follow DOM order, not visual order. Write HTML in the logical hierarchy the information requires, then use `grid-column`/`grid-row` to position cells visually. Never reorder cells purely for visual reasons if it inverts the logical reading sequence. Every cell should be wrapped in appropriate semantic elements: `<article>` for self-contained content, `<section aria-labelledby="...">` for functional regions. Every interactive cell needs a visible, high-contrast focus indicator.

**Limit visible cells.** More than 12-15 cells visible simultaneously destroys the organizational benefit. When everything competes for attention, nothing wins. Paginate, collapse, or truncate rather than cramming.

## Platform Implementation

**iOS / SwiftUI**
Use `LazyVGrid` with custom column definitions. `GridItem(.flexible())` for equal columns, `GridItem(.fixed(n))` for explicit sizing.

```swift
LazyVGrid(
    columns: [
        GridItem(.flexible()),
        GridItem(.flexible())
    ],
    spacing: 16
) {
    BentoCell(span: .double) { FeaturedContent() }
    BentoCell(span: .single) { MetricA() }
    BentoCell(span: .single) { MetricB() }
}
```

**Android / Compose**
`LazyVerticalGrid` with `GridCells.Fixed(2)`. For spanning, use `item(span = { GridItemSpan(maxLineSpan) })`.

**Web**
CSS subgrid is the correct tool for aligned content across cells. **[Verified]** Subgrid reached Baseline Widely Available in March 2026 (Chrome/Edge 117+, Firefox 71+, Safari 16+, Opera 103+, Samsung Internet 24+, over 92% global support) -- it's safe to use without a fallback:

```css
.bento-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  grid-template-rows: auto;
  gap: 16px;
}

/* Featured cell spanning */
.bento-featured {
  grid-column: span 2;
  grid-row: span 2;
}

/* Subgrid for internal alignment across cards */
.bento-cell {
  display: grid;
  grid-template-rows: subgrid;
  grid-row: span 2; /* inherit parent tracks */
}

/* Responsive: collapse to single column on narrow screens */
@media (max-width: 640px) {
  .bento-grid {
    grid-template-columns: 1fr;
  }
  .bento-featured {
    grid-column: span 1;
    grid-row: span 1;
  }
}

/* Micro-interaction: lift on hover */
.bento-cell {
  transition: transform 0.2s ease-out;
}
.bento-cell:hover {
  transform: translateY(-4px);
}
```

**Mobile responsive note**: size hierarchy that communicates importance on wide screens collapses on mobile. Decide explicitly which cells maintain prominence at smaller breakpoints -- don't let the grid degrade to identically-sized blocks by accident.

Signature GPU technique (none heavy; CSS Grid precision plus `matchedGeometryEffect` / shared-element transitions for tile-to-detail) and View Transitions API notes: see `SKILL.md` → Style-to-Technique Mapping, item 9.

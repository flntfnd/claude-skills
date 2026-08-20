# Editorial / Structural

Grids as foreground design elements. Typography leads. Influenced by print design: newspapers, magazines, annual reports. Blueprint aesthetic. Serif headlines. Visible structure. Dense information architecture made readable through precise typographic hierarchy. Wireframe logic brought into production.

**When to use**: News and editorial apps, financial reporting tools, research tools, professional services. Signals: sophisticated, trustworthy, precise.

## Visual Signature

Identifiable at a glance by: an explicit column grid that's visible and respected, serif headline type paired with dense body text, horizontal rules as structural dividers, information density that reads like a newspaper or magazine spread. Multiple typographic sizes coexisting on the same screen without feeling chaotic because the hierarchy is rigorous.

**Structural requirements:**
- Layout: explicit CSS Grid with visible column logic. At least a two-column content area. Grid structure is apparent.
- Typography: serif display type (Canela, Libre Caslon, Playfair, or system serif). Body text at 16-18px with 1.6-1.8 line height. Caption text at 11-12px with letter-spacing. Multiple type sizes visible simultaneously.
- Dividers: hairline horizontal rules (`border-top: 1px solid`) as the primary structural element between sections and content groups.
- No card containers: content sits in columns, separated by rules and whitespace, not boxed into cards.
- Section labels: small-caps or uppercase, tracked out (`letter-spacing: 0.08-0.15em`), 11-12px.

**Wrong if:** typography is all one size or all sans-serif, layout is a single centered column with no visible grid logic, sections are separated by background-color blocks rather than rules and whitespace, the design lacks information density.

## Token Modifications

```
typography:
  display: large, serif, light weight (Canela, Libre Caslon, or platform serif)
  headline: bold serif or condensed grotesque
  body: regular serif or comfortable sans at 16-18sp with generous leading
  label: caps-spaced sans at small size (tracking: 0.08-0.15em)
  numerals: tabular figures, monospace-width

color:
  ink: near-black (#1A1A1A, not pure black)
  paper: warm off-white (#FAF8F5)
  rule: light gray (#E8E4DC) for hairline dividers
  accent: one strong color, used sparingly for emphasis

spacing:
  column-gutter: explicit and visible through dividing rules
  leading: generous (1.6-1.8x for body, 1.2x for headlines)

radius: 0 or very minimal (2-4px at most)
```

Pending Rob's own personal taste extraction (TASTE.md, not yet built): the ink/paper/accent hex values above are generic defaults. Once TASTE.md exists, it overrides the specific values here.

## Component Rules

Horizontal rules are primary structural elements. Sections are delineated by rules and whitespace, not by cards or boxes. Column grid is explicit -- content aligns to it precisely. Numbers get tabular figures to align in lists and tables. Image captions are caption size, always. No decorative elements -- every visual element carries information.

## Platform Implementation

**iOS / SwiftUI**
`.font(.system(.largeTitle, design: .serif))` for display. Custom `Divider()` with `.background(Color(.separator).opacity(0.4))` and `.frame(height: 0.5)` for hairlines. `Text` with `.kerning(1.5)` and `.textCase(.uppercase)` for small caps labels.

**Android / Compose**
`fontFamily = FontFamily.Serif` for editorial text. `Divider(thickness = 0.5.dp)` for hairlines. Custom `TextStyle` with `letterSpacing = 0.08.sp` for label text.

**Web**
```css
:root {
  --font-editorial: 'Canela', 'Georgia', serif;
  --leading-editorial: 1.75;
  --tracking-label: 0.08em;
}
.rule { border-top: 0.5px solid #E8E4DC; }
.label {
  font-size: 11px;
  letter-spacing: var(--tracking-label);
  text-transform: uppercase;
  font-weight: 600;
}
```

Signature GPU technique (none beyond restraint; CSS `clip-path` wipe reveals timed to scroll, line-by-line -- not character-by-character -- text reveals): see `SKILL.md` → Style-to-Technique Mapping, item 10.

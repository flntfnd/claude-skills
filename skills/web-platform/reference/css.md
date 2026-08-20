## Contents

- [Architecture with cascade layers](#architecture-with-cascade-layers)
- [Custom properties and oklch](#custom-properties-and-oklch)
- [Native nesting](#native-nesting)
- [Container queries](#container-queries)
- [:has() selector](#has-selector)
- [Fluid typography and spacing](#fluid-typography-and-spacing)
- [Viewport units](#viewport-units)
- [Subgrid](#subgrid)
- [@property (typed custom properties)](#property-typed-custom-properties)
- [@starting-style](#starting-style)
- [Anchor positioning](#anchor-positioning)
- [Scroll-driven animations](#scroll-driven-animations)
- [Performance](#performance)

## Architecture with cascade layers

```css
@layer reset, base, tokens, components, utilities, overrides;
```

- **reset**: normalize browser defaults
- **base**: global element styles (body, typography, links)
- **tokens**: custom properties (design tokens)
- **components**: UI component styles
- **utilities**: single-purpose helpers
- **overrides**: page-specific adjustments, theme overrides

Each layer overrides the one before it regardless of specificity. This eliminates specificity wars — no more `!important` for specificity issues, only for genuinely forcing a value.

```css
@layer reset {
    *, *::before, *::after {
        box-sizing: border-box;
        margin: 0;
        padding: 0;
    }
    img, video { max-width: 100%; display: block; }
}

@layer tokens {
    :root {
        --color-primary: oklch(55% 0.2 260);
        --color-surface: oklch(98% 0 0);
        --color-text: oklch(15% 0 0);
        --space-base: 1rem;
        --radius-sm: 0.25rem;
        --radius-md: 0.5rem;
        --font-body: 'Inter', system-ui, sans-serif;
    }
}
```

## Custom properties and oklch

Design tokens live as custom properties. Never hardcode colors, spacing, or typography values.

```css
/* Token architecture: primitive → semantic → component */
:root {
    --color-blue-500: oklch(60% 0.2 260);
    --space-4: 1rem;
    --font-size-base: 1rem;
}

:root {
    --color-interactive: var(--color-blue-500);
    --space-content: var(--space-4);
    --font-size-body: var(--font-size-base);
}

@media (prefers-color-scheme: dark) {
    :root {
        --color-surface: oklch(15% 0 0);
        --color-text: oklch(95% 0 0);
    }
}

.button {
    background: var(--color-interactive);
    padding: var(--space-content);
}
```

Use `oklch()` for colors: `oklch(lightness chroma hue)`, lightness 0–100%, chroma 0–0.4, hue 0–360. It's perceptually uniform, supports wide-gamut P3 displays, and produces predictable results when adjusting lightness and chroma — HSL lightness shifts hue perception, oklch lightness doesn't.

```css
:root {
    --color-primary:      oklch(55% 0.20 260);
    --color-primary-dark: oklch(40% 0.20 260);
    --color-primary-pale: oklch(92% 0.05 260);

    /* Relative color syntax */
    --color-hover: oklch(from var(--color-primary) calc(l - 0.1) c h);
}
```

For conversion tables, contrast math, palette generation, and gamut clamping, use a dedicated color skill if one is available rather than hand-deriving oklch values.

## Native nesting

```css
.card {
    background: var(--color-surface);
    border-radius: var(--radius-md);
    padding: 1.5rem;

    & .card-title {
        font-size: 1.25rem;
        font-weight: 600;
    }

    &:hover {
        outline: 2px solid var(--color-interactive);
    }

    &.card--featured {
        border-left: 4px solid var(--color-primary);
    }

    @media (width > 768px) {
        padding: 2rem;
    }
}
```

Baseline widely available. No preprocessor needed for nesting alone — reach for Sass only when the project needs its non-CSS features (mixins, loops, `@use` module math).

## Container queries

Container queries are the correct tool for component-level responsiveness. Media queries govern the viewport. Container queries govern the component.

```css
.card-wrapper {
    container-type: inline-size;
    container-name: card;
}

@container card (width < 400px) {
    .card { flex-direction: column; }
    .card-image { width: 100%; height: 200px; }
}

@container card (width >= 400px) {
    .card { display: flex; flex-direction: row; gap: 1.5rem; }
    .card-image { width: 200px; flex-shrink: 0; }
}
```

Container query units: `cqw`, `cqh`, `cqi` (inline), `cqb` (block) — use inside `@container` blocks for sizing relative to the container.

Style queries (querying a container's custom property values, not just size) reached Baseline newly available via Firefox in 2026 — check current browser support before relying on `@container style(...)` in a broad-support project.

## :has() selector

`:has()` is a relationship selector — style a parent based on its children's state.

```css
.field:has(input:invalid:not(:focus)) {
    color: var(--color-error);
}

.card:has(img) {
    display: grid;
    grid-template-columns: 200px 1fr;
}

.nav-item:has(a[aria-current="page"]) {
    font-weight: 700;
    border-bottom: 2px solid currentColor;
}

.product-grid:has(.product-item:nth-child(5)) {
    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
}
```

Baseline widely available. No polyfill needed.

## Fluid typography and spacing

```css
:root {
    --font-size-sm:   clamp(0.8rem,  0.75rem + 0.25vw,  0.9rem);
    --font-size-base: clamp(1rem,    0.9rem  + 0.5vw,   1.125rem);
    --font-size-lg:   clamp(1.125rem, 1rem   + 0.75vw,  1.375rem);
    --font-size-xl:   clamp(1.375rem, 1.1rem + 1.5vw,   2rem);
    --font-size-2xl:  clamp(1.75rem,  1.3rem + 2.5vw,   3rem);
    --font-size-3xl:  clamp(2.25rem,  1.5rem + 4vw,     5rem);

    --space-section:  clamp(3rem, 5vw, 6rem);
    --space-gap:      clamp(1rem, 2vw, 2rem);
}

h1 { font-size: var(--font-size-3xl); }
h2 { font-size: var(--font-size-2xl); }
```

Never use fixed `px` values for font sizes on headings.

## Viewport units

Mobile browsers introduced `dvh`, `svh`, and `lvh` to solve the dynamic-viewport problem (the browser toolbar shifts visible height):

```css
/* dvh: adjusts as browser chrome shows/hides. Full-height sections. */
.hero { min-height: 100dvh; }

/* svh: accounts for maximum chrome. Safe minimum heights. */
.modal { max-height: 85svh; }

/* lvh: ignores chrome. Decorative full-bleed backgrounds. */
.bg-section { height: 100lvh; }
```

## Subgrid

Subgrid lets nested elements align to the parent grid's tracks:

```css
.grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 1.5rem;
}

.card {
    display: grid;
    grid-row: span 3;
    grid-template-rows: subgrid;
}

.card-header { grid-row: 1; }
.card-body   { grid-row: 2; }
.card-footer { grid-row: 3; }
```

All cards in a row align their headers, bodies, and footers to the same baseline regardless of content length. No JavaScript needed.

## @property (typed custom properties)

Declare typed custom properties to enable animating CSS variables:

```css
@property --gradient-angle {
    syntax: '<angle>';
    inherits: false;
    initial-value: 0deg;
}

.animated-gradient {
    background: conic-gradient(from var(--gradient-angle), blue, purple, blue);
    transition: --gradient-angle 1s;
}
.animated-gradient:hover {
    --gradient-angle: 360deg;
}
```

## @starting-style

Animate elements from their initial state on insertion into the DOM:

```css
dialog {
    opacity: 1;
    transform: translateY(0);
    transition: opacity 0.3s, transform 0.3s, display 0.3s allow-discrete;

    @starting-style {
        opacity: 0;
        transform: translateY(12px);
    }
}

dialog[open] {
    display: block;
}
```

Works with `display` transitions via `allow-discrete`. Enables enter animations without JavaScript.

## Anchor positioning

Tethers one element to another — the native replacement for JS positioning libraries (Popper, Floating UI) in most tooltip/dropdown/popover cases. Reached Baseline in 2026.

```css
.trigger {
    anchor-name: --trigger;
}

.tooltip {
    position: absolute;
    position-anchor: --trigger;
    top: anchor(bottom);
    left: anchor(left);
    position-try-fallbacks: flip-block, flip-inline;
}
```

Pair with the `popover` attribute (see `html.md`) for a fully native, zero-JS anchored overlay with built-in light-dismiss and focus handling.

Progressive enhancement for anything not yet universal:

```css
.element { position: relative; }

@supports (anchor-name: --foo) {
    .tooltip {
        position: absolute;
        anchor-name: --trigger;
    }
}
```

## Scroll-driven animations

Map animation progress to scroll progress, entirely on the compositor thread — no `scroll` event listener, no main-thread jank.

```css
@keyframes fade-in {
    from { opacity: 0; transform: translateY(20px); }
    to   { opacity: 1; transform: translateY(0); }
}

.reveal-on-scroll {
    animation: fade-in linear both;
    animation-timeline: view();
    animation-range: entry 0% cover 40%;
}

/* Progress bar tied to overall page scroll */
.scroll-progress {
    animation: grow linear;
    animation-timeline: scroll(root);
}
@keyframes grow {
    from { transform: scaleX(0); }
    to   { transform: scaleX(1); }
}
```

Use this instead of an `IntersectionObserver` + class-toggle pattern for scroll-linked reveals and progress indicators.

## Performance

Only animate `transform` and `opacity` — they run on the compositor thread. Animating `width`, `height`, `top`, `left`, `margin`, `padding` triggers layout on every frame.

```css
/* Correct: compositor-accelerated */
.card:hover {
    transform: translateY(-4px);
    opacity: 0.95;
    transition: transform 0.2s, opacity 0.2s;
}

/* Wrong: triggers layout every frame */
.card:hover {
    margin-top: -4px;
    height: 104%;
}

/* will-change sparingly, only while actively animating */
.persistent-animation {
    will-change: transform;
}
```

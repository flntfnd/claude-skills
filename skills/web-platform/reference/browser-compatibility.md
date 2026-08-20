## Baseline targets

Target the "Baseline" feature set: features available across Chrome, Firefox, Safari, and Edge, generally for at least ~30 months for "widely available" status.

Baseline widely available as of 2026:
- CSS: container queries, cascade layers, native nesting, `:has()`, `oklch()`, `color-mix()`, subgrid, `@starting-style`, `@property`, `dvh`/`svh`/`lvh`, `clamp()`
- HTML: `<dialog>`, `popover` attribute, `inert` attribute, `fetchpriority`
- JS: import attributes, `Promise.withResolvers`, `Set` methods, `structuredClone`, `crypto.randomUUID`
- APIs: Web Animations API, ResizeObserver, MutationObserver, View Transitions API

Newer, reached Baseline more recently in 2026 — verify current support before treating as universal on a broad-support project:
- CSS anchor positioning (Chrome 125+, Firefox 132+, Safari 18.2+ per 2026 coverage figures)
- CSS scroll-driven animations (`animation-timeline`, `scroll()`, `view()`)
- `contrast-color()` function
- `:active-view-transition` pseudo-class
- Style queries (`@container style(...)`) — landed in Firefox in 2026, check the other two engines

[Unverified]: exact browser version numbers and "widely available" dates drift constantly — confirm current status at web.dev/baseline or caniuse before shipping a feature to production without a fallback, rather than trusting this list as permanently current.

CSS Temporal API and other very recent JS proposals are not yet universal — see `javascript-typescript.md` for current per-engine status.

Progressive enhancement for anything not yet universal:

```css
.element {
    position: relative;
}

@supports (anchor-name: --foo) {
    .tooltip {
        position: absolute;
        anchor-name: --trigger;
    }
}
```

## Cross-browser testing checklist

- Chrome (latest, latest-1)
- Firefox (latest, latest-1)
- Safari (latest on macOS, iOS Safari latest)
- Edge (latest)
- Samsung Internet (significant Android share globally)
- At least one mid-range Android device on a real device or BrowserStack

Safari has historically lagged on certain features and has its own WebKit quirks. Always test on real iOS Safari — the DevTools emulator misses rendering differences and touch behavior issues.

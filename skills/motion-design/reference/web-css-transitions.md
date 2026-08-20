# Web: CSS & View Transitions

Native CSS is the first choice for web motion. It's the most performant option available -- animating `transform` and `opacity` runs entirely on the compositor thread and never touches the main thread. Reach for GSAP (see [gsap.md](gsap.md)) only once you need timeline choreography, scroll scrubbing, or kinetic typography that CSS can't express.

## Contents

- [Layer Zero: CSS](#layer-zero-css)
- [CSS Spring Simulation](#css-spring-simulation)
- [CSS Scroll-Driven Animations](#css-scroll-driven-animations-native)
- [View Transitions API](#view-transitions-api)
- [Reduce Motion (Web)](#reduce-motion-web)

## Layer Zero: CSS

```css
/* Animate only these two properties for compositor-thread performance */
.reveal {
    transform: translateY(20px);
    opacity: 0;
    transition:
        transform 0.35s cubic-bezier(0.0, 0.0, 0.2, 1),
        opacity 0.25s ease-out;
}
.reveal.visible {
    transform: translateY(0);
    opacity: 1;
}

/* Never animate these -- they trigger layout on every frame */
/* height, width, top, left, margin, padding, border-width */
```

## CSS Spring Simulation

CSS has no native spring physics function. `linear()` (Baseline-supported across current Chrome, Edge, Firefox, and Safari) can approximate a spring curve by sampling a physics simulation into stops, but the simplest and most portable approach is still keyframes with a slight overshoot:

```css
@keyframes spring-in {
    0%   { transform: scale(0.85) translateY(12px); opacity: 0; }
    60%  { transform: scale(1.03) translateY(-2px); opacity: 1; }
    80%  { transform: scale(0.99) translateY(0.5px); }
    100% { transform: scale(1) translateY(0); }
}

.card-enter {
    animation: spring-in 0.45s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}
```

## CSS Scroll-Driven Animations (native)

No JavaScript. Runs on the compositor thread. Supported across current Chrome, Edge, Firefox, and Safari -- this is now baseline-safe for production use, not an enhancement layered behind a feature check for most audiences. Keep the `@supports` fallback below only if you need to support older browser versions still in your analytics.

```css
/* Scroll progress timeline -- tied to scroll container position */
.progress-bar {
    animation: grow linear;
    animation-timeline: scroll(root block);
}
@keyframes grow {
    from { transform: scaleX(0); }
    to   { transform: scaleX(1); }
}

/* View timeline -- tied to element visibility in viewport */
.section-reveal {
    animation: reveal linear both;
    animation-timeline: view();
    animation-range: entry 0% cover 40%;
    /* Starts animating when element enters viewport,
       finishes when it covers 40% of the viewport */
}
@keyframes reveal {
    from { opacity: 0; transform: translateY(24px); }
    to   { opacity: 1; transform: translateY(0); }
}

/* Named scroll timeline for syncing multiple elements */
.scroll-container {
    scroll-timeline: --hero-scroll block;
}
.hero-text {
    animation: fade-out linear;
    animation-timeline: --hero-scroll;
    animation-range: 0% 30%;
}
.hero-image {
    animation: scale-down linear;
    animation-timeline: --hero-scroll;
    animation-range: 0% 50%;
}
```

Progressive enhancement pattern (still worth keeping for the long tail of older browser versions):

```css
/* Base state -- works everywhere */
.animated-element {
    opacity: 0;
    transform: translateY(20px);
    transition: opacity 0.4s ease-out, transform 0.4s ease-out;
}
.animated-element.visible {
    opacity: 1;
    transform: translateY(0);
}

/* Enhanced -- when scroll-driven is supported */
@supports (animation-timeline: view()) {
    .animated-element {
        opacity: 1;
        transform: none;
        transition: none;
        animation: reveal linear both;
        animation-timeline: view();
        animation-range: entry 0% entry 60%;
    }
    @keyframes reveal {
        from { opacity: 0; transform: translateY(20px); }
        to   { opacity: 1; transform: none; }
    }
}
```

## View Transitions API

Two distinct capabilities live under this name: same-document (SPA) transitions driven by JavaScript, and cross-document (MPA) transitions driven entirely by CSS with zero script. Both are now broadly supported in current Chrome, Edge, and Safari; Firefox has been rolling out support but treat it as a progressive enhancement until you've confirmed unflagged support in the Firefox version you need to target -- `document.startViewTransition` and the CSS below degrade harmlessly when unsupported.

### Same-document (SPA)

```javascript
// SPA navigation transition
async function navigateTo(url) {
    if (!document.startViewTransition) {
        // Fallback for unsupported browsers
        await loadPage(url);
        return;
    }

    await document.startViewTransition(async () => {
        await loadPage(url);
    });
}
```

```css
/* Default cross-fade is automatic */
/* Named transitions for specific element morphing */
.hero-image {
    view-transition-name: hero;
}

/* Style the transition */
::view-transition-old(hero) {
    animation: scale-out 0.4s cubic-bezier(0.4, 0, 1, 1);
}
::view-transition-new(hero) {
    animation: scale-in 0.4s cubic-bezier(0.0, 0.0, 0.2, 1);
}

@keyframes scale-out {
    to { transform: scale(0.9); opacity: 0; }
}
@keyframes scale-in {
    from { transform: scale(1.1); opacity: 0; }
}
```

### Cross-document (MPA) -- CSS only, no JavaScript

For traditional multi-page sites, opt both the outgoing and incoming document into a transition with a single at-rule. No `document.startViewTransition` call is needed or possible here -- the browser triggers the transition on navigation itself.

```css
/* Add to every page that should participate */
@view-transition {
    navigation: auto;
}
```

The transition only fires when the navigation is same-origin, has no cross-origin redirects, and is a `traverse`, `push`, or `replace` navigation initiated by the user (not by browser chrome like the back button's long-press menu). Named `view-transition-name` regions and `::view-transition-old/new()` pseudo-elements work the same way as the same-document case above. Optionally scope different transitions to different navigation types:

```css
@view-transition {
    navigation: auto;
    types: slide, fade;
}
```

## Reduce Motion (Web)

```css
/* Disable all custom animations */
@media (prefers-reduced-motion: reduce) {
    *,
    *::before,
    *::after {
        animation-duration: 0.01ms !important;
        animation-iteration-count: 1 !important;
        transition-duration: 0.01ms !important;
        animation-timeline: auto !important;
        scroll-behavior: auto !important;
    }
}

/* Or target specific patterns */
@media (prefers-reduced-motion: reduce) {
    .parallax { transform: none !important; }
    .scroll-reveal { opacity: 1 !important; transform: none !important; }
}
```

```javascript
// GSAP respects this automatically only if you check it yourself
const prefersReduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
if (!prefersReduced) {
    gsap.from(".element", { y: 40, opacity: 0, duration: 0.6 });
}
```

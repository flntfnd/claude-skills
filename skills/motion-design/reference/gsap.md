# GSAP & Smooth Scroll

GSAP is the production standard for complex animation timelines, scroll-driven experiences, and anything requiring precise multi-element choreography that CSS can't express. Current major version is GSAP 3 (v3.15 line). As of GSAP's April 2025 licensing change, the entire library -- including plugins that used to require a paid Club GreenSock membership (ScrollTrigger, ScrollSmoother, SplitText, Flip, MorphSVG, DrawSVG) -- is free for commercial use via the standard npm package. There is no license key to register and no private plugin repository to authenticate against; `npm install gsap` gets everything.

## Contents

- [Setup](#setup)
- [Timeline Choreography](#timeline-choreography)
- [ScrollTrigger](#scrolltrigger)
- [SplitText for Kinetic Typography](#splittext-for-kinetic-typography)
- [FLIP Animations](#flip-animations)
- [Cleanup](#cleanup)
- [Lenis (Smooth Scrolling)](#lenis-smooth-scrolling)

## Setup

```javascript
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { ScrollSmoother } from "gsap/ScrollSmoother";
import { SplitText } from "gsap/SplitText";
import { Flip } from "gsap/Flip";
import { CustomEase } from "gsap/CustomEase";

gsap.registerPlugin(ScrollTrigger, ScrollSmoother, SplitText, Flip, CustomEase);

// Custom easing curves (name them, never write cubic-bezier inline)
CustomEase.create("exponential", "0.16, 1, 0.3, 1");    // Fast start, long tail
CustomEase.create("material", "0.2, 0, 0, 1");          // Material standard
CustomEase.create("cinematic", "0.45, 0.05, 0.55, 0.95");
CustomEase.create("snap", "0.4, 0, 1, 1");              // Ease in only
```

## Timeline Choreography

```javascript
// Staggered entrance sequence
const tl = gsap.timeline({ defaults: { ease: "exponential" } });

tl.from(".hero-title", { y: 40, opacity: 0, duration: 0.7 })
  .from(".hero-subtitle", { y: 24, opacity: 0, duration: 0.5 }, "-=0.4")
  .from(".hero-cta", { y: 16, opacity: 0, duration: 0.4 }, "-=0.3")
  .from(".hero-image", {
      scale: 0.92,
      opacity: 0,
      duration: 0.8,
      ease: "cinematic"
  }, 0.1); // Starts 0.1s after timeline start, overlaps with title

// Position labels reference
tl.add("reveal")  // Named position
  .from(".card", { y: 32, opacity: 0, stagger: 0.06 }, "reveal")
  .from(".tag", { scale: 0, opacity: 0, stagger: 0.04 }, "reveal+=0.2");
```

## ScrollTrigger

```javascript
// Basic scroll-triggered animation
gsap.from(".section-content", {
    scrollTrigger: {
        trigger: ".section",
        start: "top 75%",    // When top of trigger hits 75% down viewport
        end: "bottom 25%",
        toggleActions: "play none none reverse",
        // play on enter, none on enter-back, none on leave, reverse on leave-back
    },
    y: 40,
    opacity: 0,
    duration: 0.6,
    ease: "exponential"
});

// Scrubbed (progress-linked) animation
const tl = gsap.timeline({
    scrollTrigger: {
        trigger: ".pinned-section",
        start: "top top",
        end: "+=2000",      // Pin for 2000px of scrolling
        pin: true,
        scrub: 1,           // Lag behind scroll by 1 second for smoothness
        anticipatePin: 1
    }
});
tl.to(".text", { opacity: 0, y: -40, duration: 0.3 })
  .to(".background", { scale: 1.2, duration: 1 }, 0);

// ScrollSmoother (virtual scrolling with physics-based feel)
const smoother = ScrollSmoother.create({
    wrapper: "#smooth-wrapper",
    content: "#smooth-content",
    smooth: 1.5,         // Lag in seconds -- 1-2 is natural
    effects: true,       // Enable data-speed/lag attributes on child elements
    normalizeScroll: true
});

// Smooth parallax via data attributes (no JS needed per element)
// <div data-speed="0.6">   — moves at 60% of scroll speed
// <div data-lag="0.3">     — lags 0.3s behind scroll
```

## SplitText for Kinetic Typography

```javascript
// Character-by-character reveal
const split = new SplitText(".headline", { type: "chars,words" });
gsap.from(split.chars, {
    opacity: 0,
    y: 20,
    rotationX: -90,
    stagger: 0.025,
    duration: 0.5,
    ease: "exponential",
    transformOrigin: "0% 50% -50px"
});

// Line-by-line reveal with mask (no FOUC)
const split = new SplitText(".body-copy", {
    type: "lines",
    linesClass: "line-mask"   // Each line wrapped in overflow:hidden container
});
gsap.from(split.lines, {
    y: "100%",
    opacity: 0,
    stagger: 0.08,
    duration: 0.6,
    ease: "exponential",
    scrollTrigger: { trigger: ".body-copy", start: "top 80%" }
});

// Critical: always revert SplitText on page transition
split.revert();
```

## FLIP Animations

FLIP (First, Last, Invert, Play) is the correct technique for animating layout changes. Never animate `width`, `height`, or `position` directly.

```javascript
// Record initial state
const state = Flip.getState(".card, .container");

// Make DOM change (reorder, add/remove, resize)
container.appendChild(card);
card.classList.toggle("expanded");

// Animate from old to new state
Flip.from(state, {
    duration: 0.5,
    ease: "exponential",
    stagger: 0.05,
    absolute: true,    // Use absolute positioning during animation
    onLeave: (elements) => gsap.to(elements, { opacity: 0, scale: 0.8 }),
    onEnter: (elements) => gsap.from(elements, { opacity: 0, scale: 0.8 })
});
```

## Cleanup

Always clean up GSAP instances before page transitions. Memory leaks are the most common GSAP production failure.

```javascript
// On page leave (Barba.js, React unmount, etc.)
ScrollTrigger.getAll().forEach(t => t.kill());
gsap.globalTimeline.clear();
split.revert();

// React specific
useEffect(() => {
    const ctx = gsap.context(() => {
        // All GSAP code here
        gsap.from(".element", { ... });
        ScrollTrigger.create({ ... });
    }, containerRef);

    return () => ctx.revert(); // Clean up on unmount
}, []);
```

## Lenis (Smooth Scrolling)

Replace native browser scroll for physics-based momentum. Pair with GSAP's ticker for sync. The package was renamed from the old `@studio-freight/lenis` scope to a plain `lenis` package after Studio Freight became Darkroom Engineering -- use the new name; the scoped package is no longer maintained.

```javascript
import Lenis from "lenis";

const lenis = new Lenis({
    duration: 1.2,
    easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),  // Expo out
    orientation: "vertical",
    smoothWheel: true,
    touchMultiplier: 2
});

// Sync with GSAP ticker
lenis.on("scroll", ScrollTrigger.update);
gsap.ticker.add((time) => {
    lenis.raf(time * 1000);
});
gsap.ticker.lagSmoothing(0);

// For React Three Fiber / render loop sync
function App() {
    useFrame((state) => {
        lenis.raf(state.clock.elapsedTime * 1000);
    });
}
```

React usage imports from the `lenis/react` subpath rather than a separate package.

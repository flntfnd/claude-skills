---
name: motion-design
description: Cross-platform animation reference for iOS/SwiftUI, Android/Jetpack Compose, Windows/WinUI 3, and web. Covers spring/easing API syntax, duration scales, the spring-vs-ease decision, Disney principles applied to UI, SwiftUI spring/keyframe/PhaseAnimator/matchedGeometryEffect, Compose AnimationSpec/MotionScheme, WinUI Composition and connected animations, CSS transitions/scroll-driven animations/View Transitions, GSAP timelines/ScrollTrigger/ScrollSmoother/SplitText/Flip, Lenis smooth scrolling, Three.js/WebGL scenes, PBR materials, lighting, post-processing (bloom, film grain, depth of field), style-specific GLSL shaders, particle systems, cross-platform token tables, reduced-motion accessibility per platform, and animation anti-patterns. Use when implementing, reviewing, or specifying UI motion, transitions, springs, easing curves, scroll animations, shared-element or hero transitions, page transitions, kinetic typography, or WebGL/shader effects.
---

# Motion Design

Motion is the only design property that exists in time. A bad animation isn't reliably wrong the way a bad color is -- it can look fine in isolation and fail only when a user interrupts it mid-flight, drags against it, or triggers it twice in a row. This skill covers the API-level detail needed to implement motion correctly on each platform: exact spring/easing syntax, duration values, and the GPU/performance gotchas that separate a smooth 60fps interaction from a janky one.

For the underlying floor rules this skill operationalizes (springs for user-triggered motion, ease for system-triggered, no arbitrary values, native APIs first) see the project's own motion guidelines -- they are not repeated here.

## Quick Reference

| Topic | Covers | Reference |
| --- | --- | --- |
| Foundations | Physics properties (stiffness/damping), Disney's 12 principles applied to UI, easing curve reference, reduced-motion rationale | [reference/foundations.md](reference/foundations.md) |
| iOS / SwiftUI | `.spring()`/`.bouncy`/`.smooth`/`.snappy`, implicit vs explicit animation, `KeyframeAnimator`, `PhaseAnimator`, `matchedGeometryEffect`, `@Animatable`, performance, reduce motion | [reference/ios-swiftui.md](reference/ios-swiftui.md) |
| Android / Jetpack Compose | `spring()`/`tween()`, M3 Expressive `MotionScheme`, `animateFloatAsState`, `updateTransition`, `Animatable`, fling/decay, variable fonts, reduce motion | [reference/android-compose.md](reference/android-compose.md) |
| Windows / WinUI 3 | Composition spring animations, implicit show/hide, connected (shared-element) animations, `AnimatedIcon`/Lottie, Community Toolkit, reduce motion | [reference/windows-winui.md](reference/windows-winui.md) |
| Web: CSS & View Transitions | Compositor-thread transitions, CSS spring simulation via keyframes, native scroll-driven animations, same- and cross-document View Transitions, `prefers-reduced-motion` | [reference/web-css-transitions.md](reference/web-css-transitions.md) |
| GSAP & smooth scroll | Timeline choreography, ScrollTrigger, ScrollSmoother, SplitText kinetic typography, FLIP, cleanup patterns, Lenis | [reference/gsap.md](reference/gsap.md) |
| Three.js / WebGL core | Renderer setup (WebGL vs WebGPU), DOM-canvas sync, scroll-driven camera, PBR materials, lighting, environment maps, memory management | [reference/threejs-core.md](reference/threejs-core.md) |
| Three.js shaders & particles | Post-processing pipeline (bloom, film grain, FXAA, depth of field), style-specific GLSL shaders, GPU particle systems | [reference/threejs-shaders-particles.md](reference/threejs-shaders-particles.md) |
| Cross-platform tokens & anti-patterns | Duration/spring/easing tokens expressed in all four platform APIs side by side, plus the recurring mistakes to check for | [reference/cross-platform-tokens.md](reference/cross-platform-tokens.md) |

## Spring vs. Ease: The Only Decision That Matters

A duration-based curve (ease, tween, linear) is mapped to a fixed time window: it starts at t=0 and ends at t=duration. Interrupt it at t=0.5 and the next animation starts from a resting state -- there's a discontinuity in velocity, and the motion visibly jerks.

A spring is defined by physical properties (how fast it moves toward the target, how quickly oscillation decays) and has no fixed duration -- it resolves when it reaches the target within a threshold. Interrupted mid-flight, it picks up the current velocity and continues with no discontinuity. This is why springs feel natural and durations don't: springs behave like objects that carry momentum.

**Use a spring for anything triggered by user interaction**: taps, drags, swipes, press states, gesture release. **Use an ease curve for anything automated or non-interactive**: loading spinners, progress indicators, ambient animation, anything that plays without user input. This single rule resolves nearly every "spring or ease" question. Full physics parameters (stiffness/response, damping ratio) and platform-by-platform spring cheat sheets are in the per-platform reference files.

## Duration Scale

```
Instant:     0ms      State updates with no spatial change. Color or opacity flip.
Micro:      83ms      Button press state, immediate feedback. Barely perceptible.
Fast:      150ms      Small UI state changes. Toggles, chips, icon swaps.
Standard:  250ms      Most transitions. Card expand, modal appear, dropdown open.
Slow:      350ms      Large layout shifts, navigation, full-screen transitions.
Cinematic: 500-700ms  Deliberate, immersive transitions for editorial moments.
```

Nothing above 700ms in product UI. If an animation needs longer than that to feel right, the design problem isn't solved by more motion.

## When Not to Animate

If the answer to "what does this animation help the user understand or accomplish?" isn't immediately obvious, remove it. Every animation should answer one of: *Where did that go? What just happened? What can I do next?*

Skip animation when it adds latency to task completion (a 300ms transition on a frequent action is a regression, not a polish pass), when it's purely decorative, when it creates visual noise competing with content, or when the user is in a flow state and doesn't need orientation feedback. Reduced-motion support is not optional on any platform -- see [reference/foundations.md](reference/foundations.md) for why, and each platform reference file for the implementation.

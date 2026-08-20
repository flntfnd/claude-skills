# Motion Foundations

Physics vocabulary, animation principles, easing curves, and the accessibility case for reduced motion. This is the material that's true regardless of platform -- read it once, apply it everywhere. See the main [SKILL.md](../SKILL.md) for the spring-vs-ease decision and the duration scale.

## Contents

- [The Physics Properties](#the-physics-properties)
- [The Disney Principles Applied to UI](#the-disney-principles-applied-to-ui)
- [Easing Reference](#easing-reference)
- [Accessibility: Reduce Motion](#accessibility-reduce-motion)

## The Physics Properties

Every spring, regardless of platform, is defined by two core values:

**Stiffness (or Response)**: how quickly the element moves toward its target. Higher stiffness = faster, snappier. Lower stiffness = slower, more elastic.

**Damping Ratio (or Damping Fraction)**: how much the oscillation is suppressed. At 1.0 (critically damped), the element moves to its target with no overshoot and no bounce. At 0.0 (undamped), it oscillates forever. Values between 0.6-0.85 are most common for UI. Below 0.5 produces visible, intentional bounce.

An overdamped spring (damping > 1.0 on some platforms, or negative bounce in SwiftUI) produces a flatter-than-normal deceleration curve. iOS uses this for sheet presentations and navigation transitions -- not bouncy, but not a cubic bezier either. The motion has physical weight.

Every platform section in this skill expresses these same two numbers through different names: SwiftUI calls them `response`/`dampingFraction` or bundles them into `bounce`; Compose calls them `stiffness`/`dampingRatio`; WinUI calls them `Period`/`DampingRatio`.

## The Disney Principles Applied to UI

Frank Thomas and Ollie Johnston's 12 principles from 1981 directly map to interface motion:

**Squash and stretch**: a button press compresses slightly, releases slightly larger. Not cartoonish -- 1-3% scale change is enough to convey tactility.

**Anticipation**: a drawer begins its opening motion before it reaches full velocity. A menu about to dismiss shows a brief hesitation before leaving.

**Follow-through and overlapping action**: when an element settles, trailing properties continue. Text inside a card arrives slightly after the card itself. Different properties finish at different times.

**Staging**: the most important element animates first. Supporting elements follow with slight delay. Never animate everything simultaneously.

**Ease in and ease out**: nothing in the physical world starts or stops at constant velocity. Every UI animation should accelerate into motion and decelerate out of it. The only exception is elements that loop continuously (spinners, progress bars).

**Secondary action**: the primary action (expanding a card) drives a secondary response (a shadow growing, icons fading in). Secondary actions reinforce the primary without competing with it.

**Timing**: the same easing curve at 100ms feels snappy, at 400ms feels cinematic. Timing controls perceived weight and personality.

**Offset and delay (stagger)**: elements that belong together should move in sequence, not all at once. A 30-60ms stagger between items in a list communicates grouping and creates visual rhythm.

## Easing Reference

```
Ease out:   cubic-bezier(0.0, 0.0, 0.2, 1.0)   Entrances. Element decelerates as it arrives.
Ease in:    cubic-bezier(0.4, 0.0, 1.0, 1.0)   Exits. Element accelerates as it leaves.
Ease in/out: cubic-bezier(0.4, 0.0, 0.2, 1.0)  State changes that don't enter/exit the screen.
Linear:     cubic-bezier(0.0, 0.0, 1.0, 1.0)   Repeating loops only. Never for UI transitions.

Expressive: cubic-bezier(0.45, 0.05, 0.55, 0.95)  Cinematic, deliberate.
Cinematic:  cubic-bezier(0.16, 1.0, 0.3, 1.0)     Fast start, long tail. For reveals.
Material:   cubic-bezier(0.2, 0.0, 0, 1.0)         Standard Material Design curve.
```

## Accessibility: Reduce Motion

This is not optional on any platform.

Vestibular disorders affect approximately 35% of adults over 40. Certain animation types (parallax, rapid scaling, spinning, large translation distances) trigger genuine physical symptoms: nausea, vertigo, disorientation. Beyond vestibular sensitivity, some users with ADHD or epilepsy are affected by fast or flashing motion.

The correct response to reduced motion is not to remove all animation. It's to provide an alternative that communicates the same information without large-scale spatial motion. Crossfades work. Instant state changes work. Subtle opacity shifts work.

Platform-specific implementation (the actual API to check the setting and the fallback pattern) is in each platform's reference file: [ios-swiftui.md](ios-swiftui.md#reduce-motion), [android-compose.md](android-compose.md#reduce-motion), [windows-winui.md](windows-winui.md#reduce-motion), [web-css-transitions.md](web-css-transitions.md#reduce-motion-web).

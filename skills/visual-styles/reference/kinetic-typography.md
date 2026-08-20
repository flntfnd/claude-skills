# Kinetic Typography

Type is the primary visual element and it moves. Text animates in response to scroll, time, interaction, or state changes. Not marquees and not carousels -- purposeful motion that communicates meaning through how text arrives, transforms, or exits. Text stretches, rotates, reveals character by character, reacts to input.

**When to use**: Onboarding flows, empty states, marketing surfaces within apps, loading experiences, editorial content. Not for data tables or utility UI.

## Contents
- [Visual Signature](#visual-signature)
- [Token Modifications](#token-modifications)
- [Component Rules](#component-rules)
- [Platform Implementation](#platform-implementation)

## Visual Signature

Identifiable at a glance by: oversized display type that animates on entry or scroll, with supporting content revealed progressively. Type is the layout -- there are no traditional card containers or image heroes. On scroll, words or characters reveal themselves. The page feels alive through typographic motion, not graphic elements.

**Structural requirements:**
- Hero: oversized display text (72-120px) that animates in. Characters reveal via clip/translateY animation or weight-axis transition. No static hero image as the primary element.
- Content reveals: scroll-triggered character/word/line stagger animations. Text arrives with purpose -- ease-out or spring, not linear.
- Layout: type-first. Cards and containers are minimal or absent. White space is generous specifically to give moving type room.
- Reduce motion fallback: all animations replaced with opacity fade. Content must be fully readable and functional without any motion.

**Wrong if:** the page looks identical with animations disabled (motion is decoration, not structure), text is static at all scroll positions, layout relies on traditional image/card structure with type as a secondary element.

## Token Modifications

```
typography/size/display → push extremes: 72-120sp for hero text
typography/weight → variable where platform supports (Roboto Flex, SF Pro)
  weight-min: 100
  weight-max: 900
  width-min:  75 (condensed)
  width-max:  125 (expanded)

motion/kinetic/char-stagger:  0.03s per character
motion/kinetic/word-stagger:  0.06s per word
motion/kinetic/line-stagger:  0.12s per line
motion/kinetic/reveal-duration: 0.6s
motion/kinetic/easing: cubic-bezier(0.16, 1, 0.3, 1)  (expo out)
```

## Component Rules

Each animated text element has a single, defined behavior. Mix-and-match animation types create chaos. Pick one reveal pattern per context: character stagger for hero moments, line reveal for body content, weight animation for emphasis feedback. Motion must respect `reduceMotion` -- provide a static fallback that still reads correctly.

## Platform Implementation

**iOS / SwiftUI**

Variable font weight animation (SF Pro supports this via weight axis):
```swift
@State private var fontWeight: CGFloat = 100

Text("Design")
    .font(.system(size: 80, weight: .init(rawValue: fontWeight)))
    .onAppear {
        withAnimation(
            .spring(response: 0.8, dampingFraction: 0.6).delay(0.1)
        ) {
            fontWeight = 900
        }
    }
```

Character-by-character reveal using `AttributedString` and staggered animations. Use `TimelineView` for scroll-driven effects.

**Android / Compose**

Roboto Flex supports weight and width axes:
```kotlin
val fontWeight by animateFloatAsState(
    targetValue = if (isVisible) 700f else 100f,
    animationSpec = spring(
        dampingRatio = Spring.DampingRatioMediumBouncy,
        stiffness = Spring.StiffnessLow
    )
)

Text(
    text = "Design",
    style = TextStyle(
        fontVariationSettings = FontVariation.Settings(
            FontVariation.weight(fontWeight.toInt())
        )
    )
)
```

**Web**
```css
@keyframes textReveal {
  from { 
    transform: translateY(100%);
    opacity: 0;
  }
  to { 
    transform: translateY(0);
    opacity: 1;
  }
}

.kinetic-char {
  display: inline-block;
  animation: textReveal 0.6s cubic-bezier(0.16, 1, 0.3, 1) both;
}
/* Stagger via JS: element.style.animationDelay = index * 0.03 + 's' */
```

For scroll-driven animation, `animation-timeline: scroll()` links `@keyframes` to scroll position without JavaScript on Chromium and Safari 18+. **[Unverified, check before relying on it]** As of mid-2026 this is not yet Baseline: Firefox stable still ships it behind the `layout.css.scroll-driven-animations.enabled` flag (on by default only in Nightly), even though it's a named Interop 2026 priority. Wrap the CSS in `@supports (animation-timeline: scroll())` and author the finished, readable state as the default, layering the scroll animation on top only where supported. Where Firefox coverage matters, keep GSAP `ScrollTrigger` as the fallback path (see `SKILL.md` → Style-to-Technique Mapping, item 7) rather than treating the pure-CSS approach as sufficient on its own.

Signature GPU technique (GSAP SplitText + stagger, variable font axis animation) and Three.js `TextGeometry` notes: see `SKILL.md` → Style-to-Technique Mapping, item 7.

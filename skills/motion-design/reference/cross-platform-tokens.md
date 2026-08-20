# Cross-Platform Motion Tokens & Anti-Patterns

The same motion intent expressed in each platform's native API, plus the mistakes that keep recurring across all of them. Use the token tables as the shared vocabulary when porting an animation across platforms or writing a spec that engineers on multiple platforms will implement.

## Contents

- [Duration Tokens](#duration-tokens)
- [Spring Tokens](#spring-tokens)
- [Easing Tokens](#easing-tokens)
- [Anti-Patterns](#anti-patterns)

## Duration Tokens

**micro — 83ms**
Immediate feedback. Press states, toggle flips, icon swaps. Barely perceptible but its absence is felt.
```swift
// SwiftUI
.snappy
```
```kotlin
// Compose
spring(stiffness = Spring.StiffnessHigh, dampingRatio = Spring.DampingRatioNoBouncy)
```
```csharp
// WinUI — Composition
springAnimation.Period = TimeSpan.FromMilliseconds(30);
springAnimation.DampingRatio = 1.0f;
```
```css
/* CSS */
transition-duration: 83ms;
```

---

**fast — 150ms**
Small UI state changes. Chip selection, checkbox, small badge appear.
```swift
.smooth(duration: 0.15)
```
```kotlin
tween(durationMillis = 150, easing = FastOutSlowInEasing)
```
```csharp
springAnimation.Period = TimeSpan.FromMilliseconds(60);
springAnimation.DampingRatio = 1.0f;
```
```css
transition-duration: 150ms;
```

---

**standard — 250ms**
Most transitions. Card expand, modal appear, dropdown open, navigation.
```swift
.spring(duration: 0.3, bounce: 0)
```
```kotlin
tween(durationMillis = 250, easing = FastOutSlowInEasing)
```
```csharp
springAnimation.Period = TimeSpan.FromMilliseconds(80);
springAnimation.DampingRatio = 0.9f;
```
```css
transition-duration: 250ms;
```

---

**slow — 350ms**
Large layout shifts, immersive reveals, full-screen transitions.
```swift
.spring(duration: 0.4, bounce: 0)
```
```kotlin
tween(durationMillis = 350, easing = FastOutSlowInEasing)
```
```csharp
springAnimation.Period = TimeSpan.FromMilliseconds(120);
springAnimation.DampingRatio = 0.85f;
```
```css
transition-duration: 350ms;
```

## Spring Tokens

**snappy** — Fast, no bounce. Controls, nav, anything that needs to feel crisp.
```swift
.snappy
```
```kotlin
spring(stiffness = Spring.StiffnessMedium, dampingRatio = Spring.DampingRatioNoBouncy)
```
```csharp
DampingRatio = 1.0f, Period = TimeSpan.FromMilliseconds(50)
```
```css
/* No native spring. Use keyframes with slight overshoot at 60% mark,
   or linear() sampled from a spring simulation. */
animation-timing-function: cubic-bezier(0.0, 0.0, 0.2, 1);
```

---

**standard** — Balanced physics. The default for most interactive elements.
```swift
.smooth
```
```kotlin
spring(stiffness = Spring.StiffnessMediumLow, dampingRatio = Spring.DampingRatioLowBouncy)
```
```csharp
DampingRatio = 0.85f, Period = TimeSpan.FromMilliseconds(80)
```
```css
/* No native spring. Approximate with custom ease. */
animation-timing-function: cubic-bezier(0.16, 1, 0.3, 1);
```

---

**expressive** — Visible bounce. FABs, notifications, moments that should delight.
```swift
.bouncy(duration: 0.3, extraBounce: 0.15)
```
```kotlin
spring(stiffness = Spring.StiffnessLow, dampingRatio = Spring.DampingRatioMediumBouncy)
```
```csharp
DampingRatio = 0.6f, Period = TimeSpan.FromMilliseconds(90)
```
```css
/* Keyframe-simulated spring with visible overshoot */
@keyframes spring-expressive {
    0%   { transform: scale(0.85); }
    60%  { transform: scale(1.06); }
    80%  { transform: scale(0.98); }
    100% { transform: scale(1.0); }
}
```

## Easing Tokens

**enter** — Ease out. Element decelerates as it arrives. Use for entrances.
```swift
.easeOut
```
```kotlin
LinearOutSlowInEasing
```
```csharp
CubicEasingFunction(0, 0, 0.2, 1, CompositionEasingFunctionMode.Out)
```
```css
cubic-bezier(0.0, 0.0, 0.2, 1)
```

---

**exit** — Ease in. Element accelerates as it leaves. Use for exits.
```swift
.easeIn
```
```kotlin
FastOutLinearInEasing
```
```csharp
CubicEasingFunction(0.4, 0, 1, 1, CompositionEasingFunctionMode.In)
```
```css
cubic-bezier(0.4, 0.0, 1.0, 1.0)
```

---

**standard** — Ease in/out. State changes that don't enter or exit the screen.
```swift
.easeInOut
```
```kotlin
FastOutSlowInEasing
```
```csharp
CubicEasingFunction(0.4, 0, 0.2, 1, CompositionEasingFunctionMode.InOut)
```
```css
cubic-bezier(0.4, 0.0, 0.2, 1)
```

## Anti-Patterns

**Linear motion on interactive elements.** Nothing in the physical world moves at constant velocity. Use spring or ease.

**Identical timing for all properties.** Follow-through means different properties finish at different times. Opacity arriving with the element reads as a unit. Opacity arriving 80ms before the element reveals the destination before the journey is complete.

**Animating layout properties.** Animating `width`, `height`, `top`, `left`, `margin`, or `padding` triggers layout on every frame. On web: animate `transform` and `opacity` only. On native: the same principle applies -- animate visual properties, not layout properties.

**Interrupting animations without velocity handoff.** When a user interrupts an animation (reversing direction mid-flight), the new animation must pick up the current velocity. Springs handle this automatically. Duration-based animations don't. This is the single most important reason to use springs on interactive elements.

**Staggering too much.** A 30-60ms stagger creates rhythm. A 150ms stagger makes the UI feel slow and impatient. The stagger is the gap between related elements, not a timeout.

**Decorative animation on high-frequency paths.** A 250ms transition that runs on every button press costs 250ms of perceived latency on the most common user action. Keep press states micro (83ms or less).

**Parallax on critical content.** Parallax is a visual effect. It cannot be the primary positioning mechanism for content a user needs to read.

**Not testing interruption.** Tap, release, tap again rapidly. Swipe, reverse, swipe again. If the animation breaks under rapid interruption, the spring parameters are wrong or the implementation is using ease curves where springs belong.

**Skipping reduced motion.** Always. On every platform.

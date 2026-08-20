# iOS / SwiftUI Motion

Baseline: iOS 17+ for the named spring presets and keyframe APIs, iOS 26+ for `@Animatable`. As of August 2026, iOS 26 is the current shipping stable release; iOS 27 is in public beta with no confirmed animation-API changes beyond what iOS 26 already shipped -- treat everything below as current, not iOS-27-only.

## Contents

- [Spring API](#spring-api)
- [SwiftUI Spring Cheat Sheet](#swiftui-spring-cheat-sheet)
- [Implicit vs Explicit Animations](#implicit-vs-explicit-animations)
- [Keyframe Animations](#keyframe-animations-ios-17)
- [PhaseAnimator](#phaseanimator-ios-17)
- [matchedGeometryEffect](#matchedgeometryeffect-shared-element-transitions)
- [@Animatable Macro](#animatable-macro-ios-26)
- [Performance](#performance)
- [Reduce Motion](#reduce-motion)

## Spring API

```swift
// Named presets (iOS 17+)
.bouncy                              // Visible bounce, playful
.bouncy(duration: 0.4)
.bouncy(duration: 0.4, extraBounce: 0.2)  // More bounce, max 0.5
.smooth                              // Critically damped, no bounce, medium speed
.smooth(duration: 0.3)
.snappy                              // Critically damped, faster
.snappy(duration: 0.2)

// Parametric spring (iOS 17+)
.spring(duration: 0.3, bounce: 0.2)  // bounce: 0 = no bounce, 1 = max
                                      // negative bounce = overdamped (flatter)

// Legacy parametric (iOS 13+, still valid and still common in older codebases)
.spring(response: 0.35, dampingFraction: 0.7)
// response: how fast it moves (lower = faster)
// dampingFraction: 1.0 = no bounce, <1 = bounce
```

## SwiftUI Spring Cheat Sheet

```swift
// Press state feedback (micro)
.snappy(duration: 0.15)

// Button bounce (playful, small element)
.bouncy(duration: 0.3, extraBounce: 0.15)

// Sheet / modal appear
.spring(duration: 0.4, bounce: 0)    // Non-bouncy, natural deceleration

// Expanding card / container
.spring(response: 0.4, dampingFraction: 0.82)

// Navigation push/pop
.spring(duration: 0.35, bounce: 0)

// List item delete / insert
.smooth(duration: 0.3)

// Drag release / fling
.spring(response: 0.3, dampingFraction: 0.72)

// Notification badge pop
.bouncy(duration: 0.25, extraBounce: 0.25)
```

## Implicit vs Explicit Animations

```swift
// Implicit: animation applied to view, triggers when bound value changes
// Good for: view-property-driven animations
RoundedRectangle(cornerRadius: 12)
    .scaleEffect(isActive ? 1.05 : 1.0)
    .animation(.spring(duration: 0.3, bounce: 0.2), value: isActive)

// Explicit: animation wrapped around state change
// Good for: event-triggered, multi-property choreography
Button("Expand") {
    withAnimation(.spring(duration: 0.4, bounce: 0)) {
        isExpanded.toggle()
    }
}
```

## Keyframe Animations (iOS 17+)

For complex multi-step choreography that can't be described by a single spring:

```swift
// Multiple properties, multiple keyframes, different curves per segment
KeyframeAnimator(
    initialValue: AnimationValues(),
    trigger: isActive
) { values in
    CardView()
        .scaleEffect(values.scale)
        .opacity(values.opacity)
        .offset(y: values.offsetY)
} keyframes: { _ in
    KeyframeTrack(\.scale) {
        CubicKeyframe(0.95, duration: 0.1)   // Quick compress
        SpringKeyframe(1.02, duration: 0.2)  // Spring to slightly over
        SpringKeyframe(1.0, duration: 0.15)  // Settle
    }
    KeyframeTrack(\.opacity) {
        LinearKeyframe(1.0, duration: 0.0)   // Instantly visible
    }
    KeyframeTrack(\.offsetY) {
        CubicKeyframe(-8, duration: 0.15)
        SpringKeyframe(0, duration: 0.3)
    }
}

struct AnimationValues {
    var scale: Double = 1.0
    var opacity: Double = 1.0
    var offsetY: Double = 0.0
}
```

Keyframe types:
- `LinearKeyframe`: constant velocity. For structural moves.
- `CubicKeyframe`: smooth acceleration. For physically accurate movement. Takes optional start/end velocities.
- `SpringKeyframe`: playful spring at a segment. Use for "boing" moments.
- `MoveKeyframe`: instant teleport, no interpolation. Rarely needed.

## PhaseAnimator (iOS 17+)

For repeating, sequenced animation phases (loading states, ambient motion):

```swift
PhaseAnimator([false, true]) { isActive in
    LoadingDot()
        .scaleEffect(isActive ? 1.3 : 1.0)
        .opacity(isActive ? 0.6 : 1.0)
} animation: { phase in
    .spring(duration: 0.4, bounce: 0.3)
}
```

## matchedGeometryEffect (Shared Element Transitions)

```swift
@Namespace private var heroNamespace

// Source view
Image("thumbnail")
    .matchedGeometryEffect(id: "hero", in: heroNamespace)
    .onTapGesture {
        withAnimation(.spring(duration: 0.45, bounce: 0)) {
            isExpanded = true
        }
    }

// Destination view
if isExpanded {
    Image("thumbnail")
        .matchedGeometryEffect(id: "hero", in: heroNamespace)
}
```

## @Animatable Macro (iOS 26)

Eliminates `VectorArithmetic` boilerplate for custom animatable types:

```swift
@Animatable
struct WaveShape: Shape {
    var amplitude: Double
    var frequency: Double
    var phase: Double
    // Previously required manual AnimatablePair nesting.
    // @Animatable handles all of this automatically.
}
```

## Performance

Custom `Animatable` conformance calls `body` on every frame on the main thread. For performance-critical animations, use built-in view modifiers (`.scaleEffect()`, `.opacity()`, `.rotationEffect()`, `.offset()`) which run off-main-thread via the render server.

Never put complex layout calculations or data fetching inside a view body that's being animated.

## Reduce Motion

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

// Replace spatial motion with crossfade
var transition: AnyTransition {
    if reduceMotion {
        return .opacity
    }
    return .move(edge: .trailing).combined(with: .opacity)
}

// Skip animation entirely
func animate(_ action: () -> Void) {
    if reduceMotion {
        action()
    } else {
        withAnimation(.spring(duration: 0.35, bounce: 0)) {
            action()
        }
    }
}
```

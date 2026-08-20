# Animation, Motion, and Interaction

## Contents

- [Core Principle](#core-principle)
- [Animation Tokens](#animation-tokens)
- [HIG Motion Rules](#hig-motion-rules)
- [Liquid Glass Motion](#liquid-glass-motion)
- [Symbol Effects](#symbol-effects)
- [Materialization](#materialization)
- [Gestures](#gestures)
- [Haptics](#haptics)
- [State Changes](#state-changes)

## Core Principle

Motion communicates. It orients, confirms, and guides. It doesn't decorate.

Every animation answers one of these questions:
- Where did that go?
- What just happened?
- What can I do next?

If it doesn't answer any of those, cut it.

## Animation Tokens

Define all timing as tokens. No magic values in views.

```swift
enum Motion {
    // Durations
    enum Duration {
        static let instant: Double = 0.10
        static let fast: Double = 0.20
        static let standard: Double = 0.30
        static let slow: Double = 0.45
        static let deliberate: Double = 0.60
    }

    // Spring presets (physics-based, preferred over ease curves for interactive elements)
    enum Spring {
        static let snappy = SwiftUI.Animation.spring(response: 0.25, dampingFraction: 0.8)
        static let bouncy = SwiftUI.Animation.bouncy(duration: 0.35)
        static let smooth = SwiftUI.Animation.spring(response: 0.45, dampingFraction: 0.9)
        static let gentle = SwiftUI.Animation.spring(response: 0.60, dampingFraction: 0.95)
    }

    // Ease curves (for non-interactive transitions)
    enum Ease {
        static let enter = SwiftUI.Animation.easeOut(duration: Duration.standard)
        static let exit = SwiftUI.Animation.easeIn(duration: Duration.fast)
        static let inOut = SwiftUI.Animation.easeInOut(duration: Duration.standard)
    }
}
```

## HIG Motion Rules

Use spring animations for interactive elements. Users expect physics on things they touch.

Use ease-out for elements entering the screen. Ease-in for elements leaving. This matches real-world physics: things slow as they arrive, accelerate as they leave.

Ideal duration range for most UI: 100ms to 500ms. Anything slower than 500ms starts to feel sluggish. Anything under 100ms is imperceptible.

Animation speed matters. Match direction to spatial relationships: if a view slides in from the right, it dismisses to the right.

Always respect `accessibilityReduceMotion`. Replace motion with opacity when the setting is on.

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var transition: AnyTransition {
    reduceMotion ? .opacity : .move(edge: .trailing).combined(with: .opacity)
}
```

## Liquid Glass Motion

Liquid Glass has its own physics built in. `.glassEffect(.regular.interactive())` adds: scale on press, bounce animation, shimmer, and touch-point illumination. Don't fight or override these behaviors with custom animations layered on top.

For morphing transitions, `.bouncy` is Apple's recommended animation:

```swift
withAnimation(.bouncy(duration: 0.35)) {
    isExpanded.toggle()
}
```

See `liquid-glass.md` for the full glass API.

## Symbol Effects

```swift
// State toggle
.contentTransition(.symbolEffect(.replace))

// Number changes
.contentTransition(.numericText())

// Automatic
.contentTransition(.symbolEffect(.automatic))
```

## Materialization

Elements appear and disappear by modulating light bending, not by popping in from nowhere. Match this behavior in custom transitions: use opacity combined with scale, not hard cuts.

## Gestures

Swipe to go back is a system behavior. Never remove or interfere with it.

Drag gestures on interactive glass elements should use spring return:

```swift
.gesture(
    DragGesture()
        .onChanged { value in offset = value.translation }
        .onEnded { _ in
            withAnimation(Motion.Spring.snappy) { offset = .zero }
        }
)
```

## Haptics

Use system haptic feedback for confirmations, errors, and selection changes. Never custom-implement haptics when a system pattern exists.

```swift
// Selection
let selectionFeedback = UISelectionFeedbackGenerator()
selectionFeedback.selectionChanged()

// Impact
let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
impactFeedback.impactOccurred()

// Notification
let notificationFeedback = UINotificationFeedbackGenerator()
notificationFeedback.notificationOccurred(.success)
```

## State Changes

Never cut between states. Every state transition is animated. The animation style matches the weight of the change: snappy for small state toggles, smooth for significant layout changes, bouncy for expanding/collapsing glass elements.

# MOTION.md
Motion and animation specifications for iOS/SwiftUI, Android/Compose, Windows/WinUI 3, and Web.
Current as of 2026. Physics-based motion is the standard across all platforms.

---

# Why Motion Is Hard

Motion is the only design property that exists in time. Color, spacing, and typography are states. Motion is the transition between states, and it has to be right at every possible speed, in every possible direction, under every possible interruption condition. A bad color choice is always wrong. A bad animation is sometimes wrong -- it might look fine in isolation and fail the moment a user interrupts it mid-flight.

The other problem is that motion is evaluated against twenty years of muscle memory. Users have felt springs and glass and magnetic snap on their phones every day since 2007. When something moves slightly wrong -- too fast, too linear, no physics -- they feel it before they can name it. The standard isn't "does this animate?" It's "does this feel like it belongs on this platform?"

---

# Foundations

## Why Springs, Not Durations

A duration-based animation (ease, tween, linear) is a curve mapped to a fixed time window. It starts at t=0 and ends at t=duration. If a user interrupts it at t=0.5, the next animation starts from a resting state, and there's a discontinuity in velocity. The motion jerks.

A spring is defined by physical properties: stiffness (how fast it moves toward the target) and damping (how quickly oscillation decays). It has no fixed duration. It resolves when it reaches the target within a threshold. When interrupted, it picks up the current velocity and continues -- there's no discontinuity. This is why springs feel natural: they behave like objects in the physical world that carry momentum.

Use springs for: everything triggered by user interaction (taps, drags, swipes, press states). Use ease curves for: automated, non-interactive animations (loading spinners, progress indicators, ambient animations, anything that plays without user input).

## The Physics Properties

Every spring, regardless of platform, is defined by two core values:

**Stiffness (or Response)**: how quickly the element moves toward its target. Higher stiffness = faster, snappier. Lower stiffness = slower, more elastic.

**Damping Ratio (or Damping Fraction)**: how much the oscillation is suppressed. At 1.0 (critically damped), the element moves to its target with no overshoot and no bounce. At 0.0 (undamped), it oscillates forever. Values between 0.6-0.85 are most common for UI. Below 0.5 produces visible, intentional bounce.

An overdamped spring (damping > 1.0 on some platforms, or negative bounce in SwiftUI) produces a flatter-than-normal deceleration curve. iOS uses this for sheet presentations and navigation transitions -- it's not bouncy, but it's not a cubic bezier either. The motion has physical weight.

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

## Duration Scale

```
Instant:     0ms      State updates that have no spatial change. Color, opacity flip.
Micro:      83ms      Button press state, immediate feedback. Barely perceptible.
Fast:      150ms      Small UI state changes. Toggles, chips, icon swaps.
Standard:  250ms      Most transitions. Card expand, modal appear, dropdown open.
Slow:      350ms      Large layout shifts, navigation, full-screen transitions.
Cinematic: 500-700ms  Deliberate, immersive transitions for editorial moments.
```

Nothing above 700ms in product UI. If an animation takes longer than that to feel right, the design problem isn't solved by more motion.

## When Not to Animate

If you cannot answer "what does this animation help the user understand or accomplish?", remove it.

Animations should be skipped when: they add latency to task completion (a 300ms page transition is a regression for frequent actions), when they're purely decorative, when they create visual noise competing with content, when the user is in a flow state and doesn't need orientation feedback.

Every animation should answer one of:
- Where did that go?
- What just happened?
- What can I do next?

## Accessibility: Reduce Motion

This is not optional on any platform.

Vestibular disorders affect approximately 35% of adults over 40. Certain animation types (parallax, rapid scaling, spinning, large translation distances) trigger genuine physical symptoms: nausea, vertigo, disorientation. Beyond vestibular sensitivity, some users with ADHD or epilepsy are affected by fast or flashing motion.

The correct response to reduced motion is not to remove all animation. It's to provide an alternative that communicates the same information without large-scale spatial motion. Crossfades work. Instant state changes work. Subtle opacity shifts work.

Platform-specific implementation is covered in each section below.

---

# iOS / SwiftUI

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

// Legacy parametric (iOS 13+, still valid)
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

---

# Android / Jetpack Compose

## AnimationSpec Types

```kotlin
// Spring (default for all Compose animations)
spring<Float>(
    dampingRatio = Spring.DampingRatioMediumBouncy,  // 0.5
    stiffness = Spring.StiffnessMedium,              // 400f
    visibilityThreshold = 0.01f
)

// Damping ratio constants
Spring.DampingRatioHighBouncy    // 0.2  — very bouncy
Spring.DampingRatioMediumBouncy  // 0.5  — playful
Spring.DampingRatioLowBouncy     // 0.75 — slight bounce
Spring.DampingRatioNoBouncy      // 1.0  — critically damped, no overshoot

// Stiffness constants (higher = faster)
Spring.StiffnessVeryLow    // 50f
Spring.StiffnessLow        // 200f
Spring.StiffnessMediumLow  // 400f
Spring.StiffnessMedium     // 400f (same as above, aliased)
Spring.StiffnessHigh       // 10_000f
```

```kotlin
// Duration-based (for non-interactive, automated animations)
tween<Float>(
    durationMillis = 250,
    delayMillis = 0,
    easing = FastOutSlowInEasing    // standard Material ease
)

// Easing constants
FastOutSlowInEasing   // Ease in/out — state changes
LinearOutSlowInEasing // Ease out — entrances
FastOutLinearInEasing // Ease in  — exits
LinearEasing          // Constant speed — loops only
```

## M3E MotionScheme

M3 Expressive moves away from hardcoded durations toward a scheme-based system that codifies motion personality:

```kotlin
// Access via MaterialTheme
val motionScheme = MaterialTheme.motionScheme

// Standard: functional, efficient, predictable
// Use for: navigation, layout shifts, state transitions
motionScheme.defaultSpatialSpec<Dp>()    // position/size
motionScheme.defaultEffectsSpec<Float>() // opacity, color, scale
motionScheme.fastSpatialSpec<Dp>()
motionScheme.fastEffectsSpec<Float>()
motionScheme.slowSpatialSpec<Dp>()
motionScheme.slowEffectsSpec<Float>()

// Expressive: physics-based, delightful, emotional
// Use for: FABs, expansion, interactive moments
MotionScheme.expressive().defaultSpatialSpec<Dp>()
MotionScheme.expressive().defaultEffectsSpec<Float>()
```

## Compose Spring Cheat Sheet

```kotlin
// Press state / touch feedback
spring(dampingRatio = Spring.DampingRatioNoBouncy, stiffness = Spring.StiffnessHigh)

// FAB expand / expressive action
spring(dampingRatio = Spring.DampingRatioLowBouncy, stiffness = Spring.StiffnessLow)

// Card / container expand
spring(dampingRatio = Spring.DampingRatioNoBouncy, stiffness = Spring.StiffnessMedium)

// Navigation transition
tween(durationMillis = 300, easing = FastOutSlowInEasing)

// List insert / delete
spring(dampingRatio = Spring.DampingRatioMediumBouncy, stiffness = Spring.StiffnessMediumLow)

// Tooltip / snackbar appear
tween(durationMillis = 150, easing = FastOutSlowInEasing)
```

## Animation APIs

```kotlin
// animateFloatAsState — single animated value
val scale by animateFloatAsState(
    targetValue = if (isPressed) 0.95f else 1.0f,
    animationSpec = spring(
        dampingRatio = Spring.DampingRatioNoBouncy,
        stiffness = Spring.StiffnessHigh
    ),
    label = "button_scale"
)
Box(Modifier.scale(scale)) { ... }

// updateTransition — multiple coordinated properties
val transition = updateTransition(
    targetState = isExpanded,
    label = "expansion"
)
val width by transition.animateDp(
    transitionSpec = { spring(stiffness = Spring.StiffnessMedium) },
    label = "width"
) { if (it) 300.dp else 56.dp }
val alpha by transition.animateFloat(
    transitionSpec = { tween(150) },
    label = "alpha"
) { if (it) 1f else 0f }

// Animatable — fine-grained coroutine control
val offset = remember { Animatable(0f) }
LaunchedEffect(Unit) {
    offset.animateTo(
        targetValue = 100f,
        animationSpec = spring(stiffness = Spring.StiffnessMediumLow)
    )
}
```

## Variable Font Animation (Roboto Flex)

M3E supports animating font weight via FontVariation:

```kotlin
val fontWeight by animateFloatAsState(
    targetValue = if (isActive) 700f else 400f,
    animationSpec = MotionScheme.expressive().defaultEffectsSpec()
)

Text(
    text = label,
    style = TextStyle(
        fontVariationSettings = FontVariation.Settings(
            FontVariation.weight(fontWeight.toInt())
        )
    )
)
```

## Fling / Decay Animations

For gesture release with natural deceleration (flinging a list, throwing a card):

```kotlin
val decay = rememberSplineBasedDecay<Float>()
val offset = remember { Animatable(0f) }

// After gesture ends with velocity
scope.launch {
    offset.animateDecay(
        initialVelocity = velocity,
        animationSpec = decay
    )
}
```

## Reduce Motion

```kotlin
val reduceMotion = LocalAccessibilityManager.current
    ?.isEnabled(AccessibilityServiceInfo.FEEDBACK_VISUAL) == true

// Or check system setting directly
val reduceMotion = remember {
    Settings.Global.getInt(
        context.contentResolver,
        Settings.Global.TRANSITION_ANIMATION_SCALE, 1
    ) == 0
}

val animSpec: AnimationSpec<Float> = if (reduceMotion) {
    snap()   // Instant, no animation
} else {
    MotionScheme.standard().defaultEffectsSpec()
}
```

---

# Windows / WinUI 3

## Composition Spring Animations

WinUI 3's animation engine runs on the Windows Composition layer at 60fps, independent of the UI thread.

```csharp
// SpringNaturalMotionAnimation
var compositor = ElementCompositionPreview
    .GetElementVisual(MyElement).Compositor;

var springAnimation = compositor.CreateSpringScalarAnimation();
springAnimation.Target = "Opacity";
springAnimation.FinalValue = 1.0f;
springAnimation.DampingRatio = 0.8f;   // 0 = no damping, 1 = critically damped
springAnimation.Period = TimeSpan.FromMilliseconds(50); // Oscillation period

var visual = ElementCompositionPreview.GetElementVisual(MyElement);
visual.StartAnimation("Opacity", springAnimation);

// Vector3 spring for position
var positionSpring = compositor.CreateSpringVector3Animation();
positionSpring.Target = "Offset";
positionSpring.FinalValue = new Vector3(0, 0, 0);
positionSpring.DampingRatio = 0.7f;
positionSpring.Period = TimeSpan.FromMilliseconds(80);
positionSpring.InitialVelocity = new Vector3(0, 500, 0); // px/s from gesture
visual.StartAnimation("Offset", positionSpring);
```

## WinUI Spring Cheat Sheet

```csharp
// Press state feedback
DampingRatio = 1.0f, Period = 30ms   // Instant, no bounce

// Button bounce
DampingRatio = 0.6f, Period = 60ms

// Panel slide in
DampingRatio = 0.85f, Period = 80ms

// Dialog appear
DampingRatio = 0.9f, Period = 100ms

// FAB expand
DampingRatio = 0.55f, Period = 90ms
```

## Implicit Animations

Implicit show/hide animations fire automatically when elements are added or removed:

```csharp
private void SetupImplicitAnimations(UIElement element)
{
    var visual = ElementCompositionPreview.GetElementVisual(element);
    var compositor = visual.Compositor;

    // Fade + translate on show
    var fadeIn = compositor.CreateScalarKeyFrameAnimation();
    fadeIn.InsertKeyFrame(0f, 0f);
    fadeIn.InsertKeyFrame(1f, 1f);
    fadeIn.Duration = TimeSpan.FromMilliseconds(250);
    fadeIn.Target = "Opacity";

    var slideIn = compositor.CreateVector3KeyFrameAnimation();
    slideIn.InsertKeyFrame(0f, new Vector3(0, 16, 0));
    slideIn.InsertKeyFrame(1f, new Vector3(0, 0, 0));
    slideIn.Duration = TimeSpan.FromMilliseconds(250);
    slideIn.Target = "Offset";

    var showGroup = compositor.CreateAnimationGroup();
    showGroup.Add(fadeIn);
    showGroup.Add(slideIn);

    ElementCompositionPreview.SetImplicitShowAnimation(element, showGroup);

    // Fade on hide
    var fadeOut = compositor.CreateScalarKeyFrameAnimation();
    fadeOut.InsertKeyFrame(0f, 1f);
    fadeOut.InsertKeyFrame(1f, 0f);
    fadeOut.Duration = TimeSpan.FromMilliseconds(167);
    fadeOut.Target = "Opacity";

    ElementCompositionPreview.SetImplicitHideAnimation(element, fadeOut);
}
```

## Connected Animations (Shared Element)

```csharp
// Source page: prepare before navigation
ConnectedAnimationService.GetForCurrentView()
    .PrepareToAnimate("itemHero", SourceImage);

Frame.Navigate(typeof(DetailPage), item);

// Destination page: start after navigation
protected override void OnNavigatedTo(NavigationEventArgs e)
{
    base.OnNavigatedTo(e);
    var animation = ConnectedAnimationService.GetForCurrentView()
        .GetAnimation("itemHero");

    if (animation != null)
    {
        // Optionally coordinate with other elements
        animation.TryStart(TargetImage, new UIElement[] { TitleText, MetaText });
    }
}
```

## AnimatedIcon with Lottie

State-driven icon animations via After Effects + LottieGen:

```xml
<AnimatedIcon>
    <AnimatedIcon.Source>
        <animatedvisuals:MyIconAnimation />  <!-- Generated by LottieGen -->
    </AnimatedIcon.Source>
    <AnimatedIcon.FallbackIconSource>
        <FontIconSource Glyph="&#xE713;" />  <!-- Static fallback -->
    </AnimatedIcon.FallbackIconSource>
</AnimatedIcon>
```

Set animation state via visual states (maps to Lottie markers):
```csharp
AnimatedIcon.SetState(MyIcon, "Normal");
AnimatedIcon.SetState(MyIcon, "PointerOver");
AnimatedIcon.SetState(MyIcon, "Pressed");
```

## Community Toolkit Animations

`CommunityToolkit.WinUI.Animations` provides fluent builders over the Composition API:

```csharp
using CommunityToolkit.WinUI.Animations;

// Declarative animation in XAML
<animations:Implicit.ShowAnimations>
    <animations:OpacityAnimation From="0" To="1" Duration="0:0:0.250" />
    <animations:TranslationAnimation From="0,16,0" To="0,0,0" Duration="0:0:0.250" />
</animations:Implicit.ShowAnimations>

// Or in code
await MyElement.StartAnimationAsync(
    new OpacityAnimation { To = 1.0, Duration = TimeSpan.FromMilliseconds(250) },
    new TranslationAnimation
    {
        To = new Vector3(0, 0, 0),
        Duration = TimeSpan.FromMilliseconds(250)
    }
);
```

## Reduce Motion

```csharp
var uiSettings = new UISettings();

if (!uiSettings.AnimationsEnabled)
{
    // Skip custom animations entirely
    // WinUI built-in controls automatically adapt
    return;
}

// Also listen for setting changes
uiSettings.AnimationsEnabledChanged += (s, e) =>
{
    // Re-evaluate animation strategy
};
```

---

# Web

## Layer Zero: CSS

Native CSS animation is always the first choice. It's the most performant option available -- when animating `transform` and `opacity`, it runs entirely on the compositor thread and never touches the main thread.

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

CSS doesn't have native spring physics. Approximate spring behavior with custom easing and slight overshoot via keyframes:

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

## CSS Scroll-Driven Animations (Native, 2026)

No JavaScript. Runs on compositor thread. Supported in Chrome 115+, Edge 115+, Safari 26+, Firefox partial.

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

Progressive enhancement pattern:

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

## GSAP

GSAP is the production standard for complex animation timelines, scroll-driven experiences, and anything requiring precise multi-element choreography.

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

### Timeline Choreography

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

### ScrollTrigger

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

### SplitText for Kinetic Typography

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

### FLIP Animations

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

### Cleanup

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

Replace native browser scroll for physics-based momentum. Pair with GSAP ticker for sync:

```javascript
import Lenis from "@studio-freight/lenis";

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

## Three.js + WebGL

For immersive, GPU-accelerated visual experiences: 3D product showcases, scroll-driven camera journeys, shader-based image reveals, particle systems.

### Canvas Architecture

```javascript
import * as THREE from "three";

// Fixed canvas behind DOM content
// <div style="position:fixed; inset:0; z-index:0"><canvas /></div>
// DOM content scrolls above canvas at z-index:1+

const renderer = new THREE.WebGLRenderer({
    canvas: document.querySelector("canvas"),
    antialias: true,
    alpha: true   // Transparent background to show DOM content
});
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2)); // Cap at 2 for performance

const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    100
);

// Render loop -- do not start until all assets are loaded
function animate() {
    requestAnimationFrame(animate);
    renderer.render(scene, camera);
}
```

### DOM-WebGL Sync

Synchronize Three.js elements with DOM element bounds for seamless hybrid layouts:

```javascript
function syncMeshToDOMElement(mesh, element) {
    const rect = element.getBoundingClientRect();
    const viewportHeight = window.innerHeight;
    const viewportWidth = window.innerWidth;

    // Convert DOM coordinates to Three.js NDC space
    mesh.position.x = (rect.left + rect.width / 2 - viewportWidth / 2) / viewportWidth * 2;
    mesh.position.y = -(rect.top + rect.height / 2 - viewportHeight / 2) / viewportHeight * 2;

    // Scale to match element dimensions
    mesh.scale.x = rect.width;
    mesh.scale.y = rect.height;
}

// Update on scroll (via Lenis or ScrollTrigger)
lenis.on("scroll", () => {
    syncMeshToDOMElement(imagePlane, imageElement);
});
```

### Scroll-Driven Camera with GSAP

```javascript
const cameraAnim = { x: 0, y: 2, z: 8 };

gsap.timeline({
    scrollTrigger: {
        trigger: ".scene-container",
        start: "top top",
        end: "bottom bottom",
        scrub: 1
    }
})
.to(cameraAnim, { z: 4, duration: 1, ease: "none" })
.to(cameraAnim, { y: 0, x: 1.5, z: 2, duration: 1.5, ease: "none" })
.to(cameraAnim, { x: 0, y: -1, z: 6, duration: 1, ease: "none" });

// Apply in render loop
function animate() {
    requestAnimationFrame(animate);
    camera.position.set(cameraAnim.x, cameraAnim.y, cameraAnim.z);
    camera.lookAt(0, 0, 0);
    renderer.render(scene, camera);
}
```

### GLSL Shaders for Image Effects

```glsl
// Fragment shader: scroll-triggered image reveal with distortion
uniform sampler2D uTexture;
uniform float uProgress;    // 0 = hidden, 1 = revealed (driven by scroll)
uniform float uTime;

varying vec2 vUv;

void main() {
    vec2 uv = vUv;

    // Distortion wave that sweeps across on reveal
    float wave = sin(uv.y * 12.0 + uTime * 2.0) * 0.05 * (1.0 - uProgress);
    uv.x += wave;

    // Reveal mask from left to right
    float reveal = smoothstep(uProgress - 0.1, uProgress + 0.1, uv.x);

    vec4 color = texture2D(uTexture, uv);
    gl_FragColor = vec4(color.rgb, color.a * reveal);
}
```

```javascript
// Animate uniform with GSAP
gsap.to(material.uniforms.uProgress, {
    value: 1.0,
    duration: 1.2,
    ease: "exponential",
    scrollTrigger: {
        trigger: imageElement,
        start: "top 70%",
        once: true
    }
});
```

### Memory Management

GPU memory leaks are the #1 Three.js production problem in SPAs:

```javascript
// Dispose everything when the component or page unmounts
function disposeScene(scene) {
    scene.traverse((object) => {
        if (object.geometry) object.geometry.dispose();
        if (object.material) {
            if (Array.isArray(object.material)) {
                object.material.forEach(m => {
                    disposeMaterial(m);
                });
            } else {
                disposeMaterial(object.material);
            }
        }
    });
}

function disposeMaterial(material) {
    material.dispose();
    Object.keys(material).forEach(key => {
        if (material[key] && typeof material[key].dispose === "function") {
            material[key].dispose(); // Disposes textures
        }
    });
}

renderer.dispose();
```

### Materials and Physically-Based Rendering

```javascript
// MeshStandardMaterial: PBR, responds to lights -- correct for most use cases
const material = new THREE.MeshStandardMaterial({
    color: 0x2a2a3a,
    roughness: 0.4,      // 0 = mirror, 1 = fully diffuse
    metalness: 0.8,      // 0 = dielectric, 1 = metallic
    envMapIntensity: 1.0 // how much the environment map affects the surface
});

// ShaderMaterial: full custom GLSL vertex + fragment shaders
const shaderMaterial = new THREE.ShaderMaterial({
    vertexShader: /* glsl */ `
        varying vec2 vUv;
        varying vec3 vNormal;

        void main() {
            vUv = uv;
            vNormal = normalize(normalMatrix * normal);
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
    `,
    fragmentShader: /* glsl */ `
        uniform float uTime;
        varying vec2 vUv;
        varying vec3 vNormal;

        void main() {
            vec3 color = vec3(vUv, 0.5 + 0.5 * sin(uTime));
            gl_FragColor = vec4(color, 1.0);
        }
    `,
    uniforms: {
        uTime: { value: 0 }
    }
});

// Update uniforms in render loop
shaderMaterial.uniforms.uTime.value = clock.getElapsedTime();
```

### Lighting Setup

```javascript
// Three-point lighting setup for most scenes
const ambientLight = new THREE.AmbientLight(0xffffff, 0.4);  // Soft fill
scene.add(ambientLight);

const keyLight = new THREE.DirectionalLight(0xffffff, 1.0);  // Main light
keyLight.position.set(5, 8, 5);
keyLight.castShadow = true;
scene.add(keyLight);

const fillLight = new THREE.DirectionalLight(0x4488ff, 0.3); // Cool fill
fillLight.position.set(-5, 0, -5);
scene.add(fillLight);

// Environment map: most realistic reflections for metallic/shiny materials
import { RGBELoader } from 'three/addons/loaders/RGBELoader.js';
const pmremGenerator = new THREE.PMREMGenerator(renderer);

new RGBELoader().load('/studio.hdr', (texture) => {
    const envMap = pmremGenerator.fromEquirectangular(texture).texture;
    scene.environment = envMap;     // affects all PBR materials
    scene.background = envMap;      // shows as background (optional)
    texture.dispose();
    pmremGenerator.dispose();
});
```

### Post-Processing

Requires `three/addons/postprocessing`. Full visual upgrade for Futuristic, Glassmorphism, and Y2K styles.

```javascript
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';
import { OutputPass } from 'three/addons/postprocessing/OutputPass.js';

const composer = new EffectComposer(renderer);
composer.addPass(new RenderPass(scene, camera));

// Bloom (Futuristic/Sci-Fi: makes glowing elements actually glow)
const bloomPass = new UnrealBloomPass(
    new THREE.Vector2(window.innerWidth, window.innerHeight),
    0.8,    // strength
    0.4,    // radius
    0.85    // threshold -- only pixels above this luminance bloom
);
composer.addPass(bloomPass);

// Film grain and scanlines (Y2K)
import { FilmPass } from 'three/addons/postprocessing/FilmPass.js';
const filmPass = new FilmPass(
    0.35,   // noise intensity
    0.025,  // scanline intensity
    648,    // scanline count
    false   // grayscale
);
composer.addPass(filmPass);

// FXAA anti-aliasing (always add as last pass before OutputPass)
import { ShaderPass } from 'three/addons/postprocessing/ShaderPass.js';
import { FXAAShader } from 'three/addons/shaders/FXAAShader.js';
const fxaaPass = new ShaderPass(FXAAShader);
fxaaPass.uniforms['resolution'].value.set(
    1 / window.innerWidth,
    1 / window.innerHeight
);
composer.addPass(fxaaPass);
composer.addPass(new OutputPass());

// Use composer.render() instead of renderer.render() in the loop
function animate() {
    requestAnimationFrame(animate);
    composer.render();
}
```

### Style-Specific Shaders

Each visual style has a corresponding shader or post-processing approach. Use these as the GPU layer for the style.

**Futuristic / Sci-Fi -- grid + neon glow:**
```glsl
/* Fragment shader for glowing grid plane */
uniform float uTime;
uniform vec3 uAccentColor;
varying vec2 vUv;

void main() {
    // Grid lines
    vec2 grid = abs(fract(vUv * 20.0 - 0.5) - 0.5) / fwidth(vUv * 20.0);
    float gridLine = 1.0 - min(min(grid.x, grid.y), 1.0);

    // Animated glow pulse
    float pulse = 0.5 + 0.5 * sin(uTime * 0.5);
    float glow = gridLine * (0.6 + pulse * 0.4);

    // Fade to edges (vignette)
    float dist = length(vUv - 0.5) * 2.0;
    float fade = 1.0 - smoothstep(0.6, 1.0, dist);

    vec3 color = uAccentColor * glow * fade;
    float alpha = glow * fade;

    gl_FragColor = vec4(color, alpha);
}
```

**Organic / Biomorphic -- noise displacement:**
```glsl
/* Vertex shader: noise-displaced geometry */
uniform float uTime;
varying vec2 vUv;

// Classic 3D simplex noise (include via glsl-noise package or inline)
// float snoise(vec3 v) { ... }

void main() {
    vUv = uv;
    vec3 pos = position;

    // Displace vertices along normals using noise
    float noiseVal = snoise(pos * 1.5 + uTime * 0.2) * 0.3;
    pos += normal * noiseVal;

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}
```

**Y2K / Retro -- CRT post-processing:**
```glsl
/* Full-screen CRT effect as ShaderPass */
uniform sampler2D tDiffuse;
uniform float uTime;
varying vec2 vUv;

void main() {
    // Slight barrel distortion
    vec2 uv = vUv - 0.5;
    float dist = length(uv);
    uv *= 1.0 + dist * dist * 0.1;
    uv += 0.5;

    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // Chromatic aberration
    float aberration = 0.002;
    vec4 color;
    color.r = texture2D(tDiffuse, uv + vec2(aberration, 0.0)).r;
    color.g = texture2D(tDiffuse, uv).g;
    color.b = texture2D(tDiffuse, uv - vec2(aberration, 0.0)).b;
    color.a = 1.0;

    // Scanlines
    float scanline = sin(uv.y * 800.0) * 0.04;
    color.rgb -= scanline;

    // Phosphor glow / green tint
    color.g *= 1.1;

    // Flicker
    float flicker = 0.97 + 0.03 * sin(uTime * 60.0);
    color.rgb *= flicker;

    // Vignette
    float vig = (0.5 - dist * 0.8);
    color.rgb *= clamp(vig * 2.0, 0.0, 1.0);

    gl_FragColor = color;
}
```

**Glassmorphism -- depth-of-field blur:**
```javascript
import { BokehPass } from 'three/addons/postprocessing/BokehPass.js';

const bokehPass = new BokehPass(scene, camera, {
    focus: 5.0,      // focal distance
    aperture: 0.002, // f/stop -- higher = more blur
    maxblur: 0.01    // clamp
});
composer.addPass(bokehPass);

// Animate focus pull with GSAP
gsap.to(bokehPass.uniforms['focus'], {
    value: 2.0,
    duration: 1.5,
    ease: 'power2.inOut',
    scrollTrigger: { trigger: '.glass-section', start: 'top center' }
});
```

### Particle Systems

```javascript
// GPU particle system using Points geometry
const count = 3000;
const positions = new Float32Array(count * 3);
const scales = new Float32Array(count);

for (let i = 0; i < count; i++) {
    positions[i * 3]     = (Math.random() - 0.5) * 20;  // x
    positions[i * 3 + 1] = (Math.random() - 0.5) * 20;  // y
    positions[i * 3 + 2] = (Math.random() - 0.5) * 20;  // z
    scales[i] = Math.random();
}

const geometry = new THREE.BufferGeometry();
geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
geometry.setAttribute('aScale', new THREE.BufferAttribute(scales, 1));

const particleMaterial = new THREE.ShaderMaterial({
    vertexShader: /* glsl */ `
        attribute float aScale;
        uniform float uTime;
        varying float vScale;

        void main() {
            vScale = aScale;
            vec4 modelPosition = modelMatrix * vec4(position, 1.0);

            // Gentle float animation
            modelPosition.y += sin(uTime + position.x * 0.5) * 0.1;

            gl_Position = projectionMatrix * viewMatrix * modelPosition;
            gl_PointSize = aScale * 3.0 * (300.0 / -gl_Position.z);
        }
    `,
    fragmentShader: /* glsl */ `
        varying float vScale;

        void main() {
            // Circular point with soft edges
            float dist = distance(gl_PointCoord, vec2(0.5));
            float alpha = 1.0 - smoothstep(0.4, 0.5, dist);
            gl_FragColor = vec4(1.0, 1.0, 1.0, alpha * vScale * 0.6);
        }
    `,
    uniforms: { uTime: { value: 0 } },
    transparent: true,
    depthWrite: false,
    blending: THREE.AdditiveBlending  // Additive: particles brighten overlaps
});

const particles = new THREE.Points(geometry, particleMaterial);
scene.add(particles);
```

## View Transitions API


For page-level and component-level transitions with DOM morphing:

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
// GSAP respects this automatically if you check it
const prefersReduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
if (!prefersReduced) {
    gsap.from(".element", { y: 40, opacity: 0, duration: 0.6 });
}
```

---

# Cross-Platform Motion Tokens

The same motion intent expressed in each platform's native API. Use these as the shared vocabulary when porting animations across platforms or when writing a spec that engineers on multiple platforms will implement.

---

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

---

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
/* No native spring. Use keyframes with slight overshoot at 60% mark. */
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

---

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

---

# Anti-Patterns

**Linear motion on interactive elements.** Nothing in the physical world moves at constant velocity. Use spring or ease.

**Identical timing for all properties.** Follow-through means different properties finish at different times. Opacity arriving with the element reads as a unit. Opacity arriving 80ms before the element reveals the destination before the journey is complete.

**Animating layout properties.** Animating `width`, `height`, `top`, `left`, `margin`, or `padding` triggers layout on every frame. On web: animate `transform` and `opacity` only. On native: the same principle applies -- animate visual properties, not layout properties.

**Interrupting animations without velocity handoff.** When a user interrupts an animation (reversing direction mid-flight), the new animation must pick up the current velocity. Springs handle this automatically. Duration-based animations don't. This is the single most important reason to use springs on interactive elements.

**Staggering too much.** A 30-60ms stagger creates rhythm. A 150ms stagger makes the UI feel slow and impatient. The stagger is the gap between related elements, not a timeout.

**Decorative animation on high-frequency paths.** A 250ms transition that runs on every button press costs 250ms of perceived latency on the most common user action. Keep press states micro (83ms or less).

**Parallax on critical content.** Parallax is a visual effect. It cannot be the primary positioning mechanism for content a user needs to read.

**Not testing interruption.** Tap, release, tap again rapidly. Swipe, reverse, swipe again. If the animation breaks under rapid interruption, the spring parameters are wrong or the implementation is using ease curves where springs belong.

**Skipping reduced motion.** Always. On every platform.

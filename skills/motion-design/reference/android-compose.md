# Android / Jetpack Compose Motion

Covers the core `AnimationSpec` system plus Material 3 Expressive (M3E) `MotionScheme`, which is the current recommended way to source motion values in a Compose app rather than hand-picking spring constants per call site.

## Contents

- [AnimationSpec Types](#animationspec-types)
- [M3E MotionScheme](#m3e-motionscheme)
- [Compose Spring Cheat Sheet](#compose-spring-cheat-sheet)
- [Animation APIs](#animation-apis)
- [Variable Font Animation](#variable-font-animation-roboto-flex)
- [Fling / Decay Animations](#fling--decay-animations)
- [Reduce Motion](#reduce-motion)

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

Material 3 Expressive moved motion off hardcoded per-call-site durations and onto a scheme-based system that codifies motion personality. The built-in schemes live on the `MotionScheme` companion object as `MotionScheme.standard()` and `MotionScheme.expressive()`; earlier top-level `standardMotionScheme()`/`expressiveMotionScheme()` function names were consolidated into this companion object as the API matured.

```kotlin
// Access via MaterialTheme (set by MaterialExpressiveTheme at the theme root)
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

Set the scheme once at the theme root (`MaterialExpressiveTheme(motionScheme = MotionScheme.expressive()) { ... }`) rather than threading a scheme through every call site -- that's the point of the system.

FAB, FAB Menu, and expressive-menu APIs have graduated out of `@ExperimentalMaterial3ExpressiveApi` -- but that graduation landed in the `material3` 1.5.0-alpha line, not yet in a stable release (stable is 1.4.0 as of August 2026). If your project pins `material3` stable, expect the experimental opt-in annotation on these components until 1.5.0 ships stable; on the 1.5.0 alpha train, the annotation is already gone.

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

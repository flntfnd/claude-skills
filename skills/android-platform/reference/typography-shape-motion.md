# Typography, Shape & Motion

## Contents
- [Typography Scale](#typography-scale)
- [Variable Fonts](#variable-fonts)
- [Shape Scale](#shape-scale)
- [Shape Morphing](#shape-morphing)
- [Motion Schemes](#motion-schemes)
- [Motion Tokens](#motion-tokens)
- [Reduce Motion](#reduce-motion)
- [System Motion Examples](#system-motion-examples)

## Typography Scale

M3 Expressive introduces a dual-track type scale: baseline and emphasized. Emphasized styles use higher font weight and subtle size/spacing adjustments to pull focus. The values below are the M3 baseline scale — treat them as defaults, not hardcoded law.

```kotlin
val AppTypography = Typography(
    // Display
    displayLarge = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Normal,
        fontSize = 57.sp,
        lineHeight = 64.sp,
        letterSpacing = (-0.25).sp
    ),
    displayMedium = TextStyle(
        fontWeight = FontWeight.Normal,
        fontSize = 45.sp,
        lineHeight = 52.sp,
        letterSpacing = 0.sp
    ),
    displaySmall = TextStyle(
        fontWeight = FontWeight.Normal,
        fontSize = 36.sp,
        lineHeight = 44.sp,
        letterSpacing = 0.sp
    ),
    // Headline
    headlineLarge = TextStyle(
        fontWeight = FontWeight.Normal,
        fontSize = 32.sp,
        lineHeight = 40.sp,
        letterSpacing = 0.sp
    ),
    headlineMedium = TextStyle(
        fontWeight = FontWeight.Normal,
        fontSize = 28.sp,
        lineHeight = 36.sp,
        letterSpacing = 0.sp
    ),
    headlineSmall = TextStyle(
        fontWeight = FontWeight.Normal,
        fontSize = 24.sp,
        lineHeight = 32.sp,
        letterSpacing = 0.sp
    ),
    // Title
    titleLarge = TextStyle(
        fontWeight = FontWeight.Normal,
        fontSize = 22.sp,
        lineHeight = 28.sp,
        letterSpacing = 0.sp
    ),
    titleMedium = TextStyle(
        fontWeight = FontWeight.Medium,
        fontSize = 16.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.15.sp
    ),
    titleSmall = TextStyle(
        fontWeight = FontWeight.Medium,
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.1.sp
    ),
    // Body
    bodyLarge = TextStyle(
        fontWeight = FontWeight.Normal,
        fontSize = 16.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.15.sp
    ),
    bodyMedium = TextStyle(
        fontWeight = FontWeight.Normal,
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.25.sp
    ),
    bodySmall = TextStyle(
        fontWeight = FontWeight.Normal,
        fontSize = 12.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.4.sp
    ),
    // Label
    labelLarge = TextStyle(
        fontWeight = FontWeight.Medium,
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.1.sp
    ),
    labelMedium = TextStyle(
        fontWeight = FontWeight.Medium,
        fontSize = 12.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.5.sp
    ),
    labelSmall = TextStyle(
        fontWeight = FontWeight.Medium,
        fontSize = 11.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.5.sp
    )
)
```

All text must be defined in `sp`, not `dp`, and must scale with the system font size setting — don't hardcode `sp` values that ignore user preferences.

## Variable Fonts

M3 Expressive supports variable font axes (weight, width, slant) for dynamic typographic feedback. Use Roboto Flex for animated weight changes on interaction. Define axis changes as tokens, not ad hoc values.

```kotlin
// Animating font weight on press (Roboto Flex)
val fontWeight by animateFloatAsState(
    targetValue = if (isPressed) 700f else 400f,
    animationSpec = MotionScheme.expressive().defaultEffectsSpec()
)
```

## Shape Scale

Five levels of roundedness. Each maps to a semantic use case.

```kotlin
val AppShapes = Shapes(
    extraSmall = RoundedCornerShape(4.dp),   // chips, small badges
    small = RoundedCornerShape(8.dp),         // text fields, small cards
    medium = RoundedCornerShape(12.dp),       // cards, dialogs
    large = RoundedCornerShape(16.dp),        // FAB, bottom sheets
    extraLarge = RoundedCornerShape(24.dp)    // large cards, containers
)
```

M3E expanded the shape library to 35+ shapes in the Material Shapes Library (available in both Figma and Compose). Shape morphing is a first-class capability: components can animate between shapes in response to state changes.

## Shape Morphing

```kotlin
// Button that morphs from rounded rect to circle on press
val shape by animateValueAsState(
    targetValue = if (isPressed) CircleShape else MaterialTheme.shapes.medium,
    typeConverter = /* shape converter */,
    animationSpec = MotionScheme.expressive().defaultEffectsSpec()
)
```

Use shape morphing for: selected states, pressed states, loading indicators, FAB expansion. Not for decorative purposes.

## Motion Schemes

M3 Expressive replaces duration-based animation with a physics-based spring engine. Springs are defined by stiffness and damping ratio, not duration. Two schemes are available through `MotionScheme`:

`MotionScheme.standard()` is for functional transitions: navigation, state changes, elements entering or leaving the screen. Purposeful and efficient.

`MotionScheme.expressive()` is for interactive, emotionally resonant moments: springy, physical, delightful. Use on FABs, buttons, interactive elements.

```kotlin
// Access via MaterialTheme (works with both MaterialTheme and MaterialExpressiveTheme)
val motionScheme = MaterialTheme.motionScheme

// Standard specs
motionScheme.defaultSpatialSpec<Float>()     // position/size changes
motionScheme.defaultEffectsSpec<Float>()     // color, opacity, scale changes
motionScheme.fastSpatialSpec<Float>()
motionScheme.fastEffectsSpec<Float>()
motionScheme.slowSpatialSpec<Float>()
motionScheme.slowEffectsSpec<Float>()

// Or directly
MotionScheme.standard().defaultSpatialSpec<Dp>()
MotionScheme.expressive().defaultEffectsSpec<Float>()
```

## Motion Tokens

Define custom spring configurations as named tokens. No raw spring values scattered through composables.

```kotlin
object Motion {
    // Snappy: small UI elements, toggles, chips
    val snappy = spring<Float>(
        dampingRatio = Spring.DampingRatioMediumBouncy,
        stiffness = Spring.StiffnessMediumLow
    )

    // Bouncy: FABs, expanding containers, expressive moments
    val bouncy = spring<Float>(
        dampingRatio = Spring.DampingRatioLowBouncy,
        stiffness = Spring.StiffnessLow
    )

    // Smooth: navigation transitions, large layout shifts
    val smooth = spring<Float>(
        dampingRatio = Spring.DampingRatioNoBouncy,
        stiffness = Spring.StiffnessMedium
    )

    // Gentle: subtle state changes, opacity, color
    val gentle = spring<Float>(
        dampingRatio = Spring.DampingRatioNoBouncy,
        stiffness = Spring.StiffnessLow
    )

    // Duration reference (M3 guideline range)
    // 100ms: instant feedback
    // 200-300ms: standard transitions
    // 400-500ms: deliberate transitions
    // 500ms+: avoid
}
```

## Reduce Motion

Always check and respect it.

```kotlin
val reduceMotion = LocalAccessibilityManager.current
    ?.isEnabled(AccessibilityServiceInfo.FEEDBACK_VISUAL) == true

val transition: EnterTransition = if (reduceMotion) {
    fadeIn()
} else {
    slideInHorizontally() + fadeIn(animationSpec = Motion.smooth)
}
```

## System Motion Examples

Real M3E motion behaviors from system UI. Match this quality in custom components.

- **Notification dismiss**: surrounding notifications subtly react to the drag. When snapped off, haptic rumble fires.
- **Volume slider**: physics-based fidget behavior on drag.
- **Recents screen**: card dismiss has spring-back on partial swipe.
- **Pull-to-refresh**: shape-morphing loading indicator.

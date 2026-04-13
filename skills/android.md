# Design System (Android)
Material 3 Expressive / Jetpack Compose
Target: current stable Android release. Compose-only. No XML layouts.

---

# Philosophy
Material 3 Expressive (M3E) is an evolution of Material You, not a replacement. It layers on top of M3 with a stronger emphasis on physics-based motion, expressive typography, shape morphing, and emotional clarity. It doesn't abandon the token system -- it extends it.

Three things drive M3 Expressive: motion that feels physical, typography that creates hierarchy through weight and scale, and shapes that respond to state. All three work together. Designing one without the others produces something that looks like M3E but doesn't feel like it.

Dynamic color (Material You) derives tones from the user's wallpaper. Support it. Design with it enabled and fallback brand palettes for devices that don't support it.

---

# Setup

```kotlin
// build.gradle
// Always use the latest stable BOM -- check https://developer.android.com/jetpack/compose/bom/bom-mapping
// Current stable as of early 2026: 2025.10.00 or later
implementation(platform("androidx.compose:compose-bom:2025.10.00"))
implementation("androidx.compose.material3:material3")

// For M3E experimental APIs
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
```

M3 Expressive stable APIs don't require opt-in. Experimental ones (newer components, shape morphing, some motion APIs) require `@OptIn(ExperimentalMaterial3ExpressiveApi::class)`.

---

# Theme Setup

Everything flows through `MaterialTheme`. Color, typography, and shapes are defined once and consumed everywhere via `MaterialTheme.colorScheme`, `MaterialTheme.typography`, and `MaterialTheme.shapes`.

```kotlin
@Composable
fun AppTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context)
            else dynamicLightColorScheme(context)
        }
        darkTheme -> darkColorScheme(
            primary = AppColors.primaryDark,
            onPrimary = AppColors.onPrimaryDark,
            primaryContainer = AppColors.primaryContainerDark,
            // ... full scheme
        )
        else -> lightColorScheme(
            primary = AppColors.primaryLight,
            onPrimary = AppColors.onPrimaryLight,
            primaryContainer = AppColors.primaryContainerLight,
            // ... full scheme
        )
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = AppTypography,
        shapes = AppShapes,
        content = content
    )
}
```

Always call `enableEdgeToEdge()` in your Activity. Non-negotiable on modern Android.

```kotlin
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent { AppTheme { /* content */ } }
    }
}
```

---

# Color

## System

M3 color is role-based, not name-based. Never reference a raw color by hue. Reference it by role.

```kotlin
// Primary roles
MaterialTheme.colorScheme.primary           // main brand action
MaterialTheme.colorScheme.onPrimary         // content on primary
MaterialTheme.colorScheme.primaryContainer  // lower-emphasis primary surfaces
MaterialTheme.colorScheme.onPrimaryContainer

// Secondary roles
MaterialTheme.colorScheme.secondary
MaterialTheme.colorScheme.onSecondary
MaterialTheme.colorScheme.secondaryContainer
MaterialTheme.colorScheme.onSecondaryContainer

// Tertiary roles (accent, contrast balance)
MaterialTheme.colorScheme.tertiary
MaterialTheme.colorScheme.onTertiary
MaterialTheme.colorScheme.tertiaryContainer
MaterialTheme.colorScheme.onTertiaryContainer

// Surface roles
MaterialTheme.colorScheme.surface
MaterialTheme.colorScheme.onSurface
MaterialTheme.colorScheme.surfaceVariant
MaterialTheme.colorScheme.onSurfaceVariant
MaterialTheme.colorScheme.surfaceContainerLowest
MaterialTheme.colorScheme.surfaceContainerLow
MaterialTheme.colorScheme.surfaceContainer
MaterialTheme.colorScheme.surfaceContainerHigh
MaterialTheme.colorScheme.surfaceContainerHighest

// Error roles
MaterialTheme.colorScheme.error
MaterialTheme.colorScheme.onError
MaterialTheme.colorScheme.errorContainer
MaterialTheme.colorScheme.onErrorContainer

// Utility
MaterialTheme.colorScheme.outline
MaterialTheme.colorScheme.outlineVariant
MaterialTheme.colorScheme.scrim
MaterialTheme.colorScheme.inverseSurface
MaterialTheme.colorScheme.inverseOnSurface
MaterialTheme.colorScheme.inversePrimary
```

## Custom Brand Colors

Define app-specific colors as a separate object. Never hardcode hex values in composables.

```kotlin
object AppColors {
    // Light theme
    val primaryLight = Color(0xFF6750A4)
    val onPrimaryLight = Color(0xFFFFFFFF)
    val primaryContainerLight = Color(0xFFE9DDFF)
    val onPrimaryContainerLight = Color(0xFF22005D)

    // Dark theme
    val primaryDark = Color(0xFFCFBCFF)
    val onPrimaryDark = Color(0xFF381E72)
    val primaryContainerDark = Color(0xFF4F378B)
    val onPrimaryContainerDark = Color(0xFFE9DDFF)
}
```

## AMOLED / Pure Black

Always provide a pure black option for OLED screens. Users expect it.

```kotlin
fun ColorScheme.pureBlack(apply: Boolean): ColorScheme =
    if (apply) copy(
        surface = Color.Black,
        background = Color.Black,
        surfaceContainer = Color(0xFF0A0A0A),
        surfaceContainerLow = Color(0xFF050505)
    ) else this
```

## Dynamic Color

Support dynamic color on Android 12+. Provide a fallback scheme for older devices and for users who prefer a fixed brand palette.

## Contrast Levels

M3 supports standard, medium, and high contrast. Design and test for all three. The theme generator's `contrastLevel` parameter ranges from -1.0 to 1.0.

---

# Typography

## Scale

M3 Expressive introduces a dual-track type scale: baseline and emphasized. Emphasized styles use higher font weight and subtle adjustments to pull focus.

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

## Variable Fonts

M3 Expressive supports variable font axes (weight, width, slant) for dynamic typographic feedback. Use Roboto Flex for animated weight changes on interaction. Define axis changes as tokens, not ad hoc values.

```kotlin
// Animating font weight on press (Roboto Flex)
val fontWeight by animateFloatAsState(
    targetValue = if (isPressed) 700f else 400f,
    animationSpec = MotionScheme.expressive().defaultEffectsSpec()
)
```

---

# Shape

## Scale

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

M3E expanded the shape library with 35 new shapes. Shape morphing is now a first-class capability: components can animate between shapes in response to state changes.

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

---

# Motion

M3 Expressive replaces duration-based animation with a physics-based spring engine. Springs are defined by stiffness and damping ratio, not duration.

## Motion Schemes

Two schemes available through `MotionScheme`:

`MotionScheme.standard()` is for functional transitions. Navigation, state changes, elements entering or leaving the screen. Purposeful and efficient.

`MotionScheme.expressive()` is for interactive, emotionally resonant moments. Springy, physical, delightful. Use on FABs, buttons, interactive elements.

```kotlin
// Access via MaterialTheme
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

These are real M3E motion behaviors from system UI. Match this quality in custom components.

Notification dismiss: surrounding notifications subtly react to the drag. When snapped off, haptic rumble fires.

Volume slider: physics-based fidget behavior on drag.

Recents screen: card dismiss has spring-back on partial swipe.

Pull-to-refresh: shape-morphing loading indicator.

---

# Spacing Tokens

```kotlin
object Spacing {
    val xxs = 2.dp
    val xs = 4.dp
    val sm = 8.dp
    val md = 12.dp
    val base = 16.dp
    val lg = 20.dp
    val xl = 24.dp
    val xxl = 32.dp
    val xxxl = 48.dp
    val section = 64.dp
}
```

Minimum touch target: 48dp. M3 components enforce this automatically. Custom components must too.

---

# New and Updated Components

All expressive components use `@OptIn(ExperimentalMaterial3ExpressiveApi::class)`.

## Loading Indicators

Replace `CircularProgressIndicator` for waits under 5 seconds.

```kotlin
// Shape-morphing loading indicator
LoadingIndicator()

// Contained variant with colored background
ContainedLoadingIndicator()

// Wavy progress (indeterminate)
LinearWavyProgressIndicator()
CircularWavyProgressIndicator()
```

## Button Groups

Connected and standard groups for related actions.

```kotlin
// Connected button group (shapes merge at boundaries)
ButtonGroup {
    Button(onClick = { }) { Text("Day") }
    Button(onClick = { }) { Text("Week") }
    Button(onClick = { }) { Text("Month") }
}

// Split button
SplitButtonLayout(
    leadingButton = { Button(onClick = { }) { Text("Save") } },
    trailingButton = { /* dropdown */ }
)
```

## Floating Toolbar

Contextual toolbar that appears dynamically. Floats above content.

```kotlin
FloatingToolbar(
    expanded = isExpanded,
    floatingActionButton = {
        FloatingActionButton(onClick = { isExpanded = !isExpanded }) {
            Icon(Icons.Default.Edit, contentDescription = "Edit")
        }
    }
) {
    IconButton(onClick = { }) { Icon(Icons.Default.FormatBold, null) }
    IconButton(onClick = { }) { Icon(Icons.Default.FormatItalic, null) }
    IconButton(onClick = { }) { Icon(Icons.Default.FormatUnderlined, null) }
}
```

## FAB with Spring Animation

```kotlin
// Animate FAB visibility on scroll
val fabVisible by remember {
    derivedStateOf { scrollState.value == 0 }
}

FloatingActionButton(
    onClick = { },
    modifier = Modifier.animateFloatingActionButton(
        visible = fabVisible,
        alignment = Alignment.BottomEnd
    )
) {
    Icon(Icons.Default.Add, contentDescription = "Add")
}
```

---

# Navigation

## Adaptive Navigation

M3 supports adaptive navigation that shifts between bottom bar (compact), navigation rail (medium), and navigation drawer (expanded) based on window size class.

```kotlin
@Composable
fun AdaptiveNav(
    windowSizeClass: WindowSizeClass,
    currentDestination: NavDestination?,
    onDestinationChange: (Destination) -> Unit
) {
    when (windowSizeClass.widthSizeClass) {
        WindowWidthSizeClass.Compact -> {
            NavigationBar {
                destinations.forEach { dest ->
                    NavigationBarItem(
                        selected = currentDestination?.route == dest.route,
                        onClick = { onDestinationChange(dest) },
                        icon = { Icon(dest.icon, null) },
                        label = { Text(dest.label) }
                    )
                }
            }
        }
        WindowWidthSizeClass.Medium -> {
            NavigationRail {
                destinations.forEach { dest ->
                    NavigationRailItem(
                        selected = currentDestination?.route == dest.route,
                        onClick = { onDestinationChange(dest) },
                        icon = { Icon(dest.icon, null) },
                        label = { Text(dest.label) }
                    )
                }
            }
        }
        WindowWidthSizeClass.Expanded -> {
            PermanentNavigationDrawer(
                drawerContent = { /* drawer items */ }
            ) { /* content */ }
        }
    }
}
```

Foldables and tablets are real use cases. Don't design phone-only. Use `WindowSizeClass` from the start.

---

# Interaction and Haptics

## Indication

Use M3's ripple indication. Don't remove or replace it with custom touch indicators unless the design explicitly requires something different.

```kotlin
// Custom ripple color if needed
CompositionLocalProvider(
    LocalIndication provides rememberRipple(color = MaterialTheme.colorScheme.primary)
) {
    /* content */
}
```

## Haptics

Mirror M3E system behavior: fire haptics for confirmations, errors, and meaningful drag completions.

```kotlin
val haptic = LocalHapticFeedback.current

// Selection
haptic.performHapticFeedback(HapticFeedbackType.LongPress)

// Confirmation / success
haptic.performHapticFeedback(HapticFeedbackType.Confirm)
```

---

# Dark Mode

## Light Mode Token Reference
- Surface: #FFFBFE
- Surface container: #F3EDF7
- Surface container high: #ECE6F0
- Primary: #6750A4
- On-surface: #1C1B1F
- Outline: #79747E

## Dark Mode Token Reference
- Surface: #141218
- Surface container: #211F26
- Surface container high: #2B2930
- Primary: #CFBCFF
- On-surface: #E6E1E5
- Outline: #938F99

Dark mode is not optional. Design for it from the start, not as an afterthought. Test both appearances with all states: default, pressed, focused, disabled, error.

Pure black (AMOLED) mode should be a user preference, not the default dark theme.

---

# Accessibility

M3 components enforce minimum touch targets (48dp) automatically. Custom components must do the same.

Color contrast: 4.5:1 for normal text, 3:1 for large text and interactive elements. M3's semantic color roles are designed to meet WCAG AA out of the box when used correctly. Hardcoding hex values bypasses this.

Semantic roles: add `contentDescription` to all icons and interactive elements that don't have visible text labels.

```kotlin
// Minimum touch target on custom components
Modifier.minimumInteractiveComponentSize()

// Semantic role
Modifier.semantics {
    role = Role.Button
    contentDescription = "Add item"
}
```

Scale text with system font size. Don't hardcode `sp` values that ignore user preferences. All text must be defined in `sp`, not `dp`.

---

# Anti-Patterns

Using XML layouts alongside Compose in new code. Pick one per screen. Don't mix for new work.

Hardcoding colors outside the theme. Any `Color(0xFF...)` in a composable that isn't in the theme object is a problem.

Using `CircularProgressIndicator` for short waits. `LoadingIndicator` exists for this.

Ignoring window size class. Phone-only layout assumptions break on tablets, foldables, and Chrome OS.

No edge-to-edge. Every modern Android app uses `enableEdgeToEdge()`. Not calling it is a visual regression.

Duration-based animations instead of springs. M3E moved away from this. Match the system.

Removing ripple indication. Ripple is the interaction contract on Android. Removing it creates cognitive dissonance.

---

# Performance

Recomposition is the biggest compose performance issue. Minimize it.

Use `remember` and `derivedStateOf` to avoid unnecessary recomposition. Don't read state inside composables that don't need it.

`LazyColumn` and `LazyRow` for long lists. Never a regular `Column` with a loop.

Avoid allocation during composition (no `mutableListOf()` inline). Move it to `remember` blocks.

Test on low-end devices. Qualcomm 600-series equivalents are the real-world baseline for most Android users, not Pixel 10.

Profile with Android Studio's Layout Inspector and the Composition tab in the profiler. Recomposition count is your primary signal.

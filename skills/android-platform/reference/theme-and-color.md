# Theme & Color

## Contents
- [Theme Setup](#theme-setup)
- [Color System](#color-system)
- [Custom Brand Colors](#custom-brand-colors)
- [AMOLED / Pure Black](#amoled--pure-black)
- [Dynamic Color](#dynamic-color)
- [Contrast Levels](#contrast-levels)
- [Dark Mode Token Reference](#dark-mode-token-reference)

## Theme Setup

Everything flows through `MaterialTheme` (or `MaterialExpressiveTheme` — the M3E variant that also accepts a `motionScheme`). Color, typography, and shapes are defined once and consumed everywhere via `MaterialTheme.colorScheme`, `MaterialTheme.typography`, and `MaterialTheme.shapes`.

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

Always call `enableEdgeToEdge()` in your Activity. On Android 16 (API 36)+ the system enforces this regardless — there is no opt-out flag left — so treat it as required infrastructure, not a nice-to-have.

```kotlin
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent { AppTheme { /* content */ } }
    }
}
```

## Color System

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

M3E also exposes `expressiveLightColorScheme()` / `expressiveDarkColorScheme()` as generator functions with the same role surface, tuned for M3E's more saturated defaults — use them as the baseline instead of `lightColorScheme()`/`darkColorScheme()` when the app is explicitly opting into the Expressive look. Both are stable as of `material3` 1.4.0.

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

Always provide a pure black option for OLED screens. Users expect it. Make it a user preference, not the default dark theme.

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

Support dynamic color on Android 12 (API 31)+. Provide a fallback scheme for older devices and for users who prefer a fixed brand palette. Design with dynamic color enabled by default — it's the expected Android experience, not an edge case.

## Contrast Levels

M3 supports standard, medium, and high contrast. Design and test for all three. The theme generator's `contrastLevel` parameter ranges from -1.0 to 1.0.

## Dark Mode Token Reference

Dark mode is not optional. Design for it from the start, not as an afterthought. Test both appearances with all states: default, pressed, focused, disabled, error.

**Light mode (M3 baseline palette):**
- Surface: `#FFFBFE`
- Surface container: `#F3EDF7`
- Surface container high: `#ECE6F0`
- Primary: `#6750A4`
- On-surface: `#1C1B1F`
- Outline: `#79747E`

**Dark mode (M3 baseline palette):**
- Surface: `#141218`
- Surface container: `#211F26`
- Surface container high: `#2B2930`
- Primary: `#CFBCFF`
- On-surface: `#E6E1E5`
- Outline: `#938F99`

These are the default M3 baseline tokens (no dynamic color applied) — use them as a fallback scheme, not as the primary experience.

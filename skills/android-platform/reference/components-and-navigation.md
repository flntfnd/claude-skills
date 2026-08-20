# Components & Navigation

## Contents
- [Spacing Tokens](#spacing-tokens)
- [New and Updated Components](#new-and-updated-components)
- [Adaptive Navigation](#adaptive-navigation)

## Spacing Tokens

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

## New and Updated Components

These are M3E additions on top of the classic M3 component set. Most still ship behind `@OptIn(ExperimentalMaterial3ExpressiveApi::class)` in current stable `material3` — see the opt-in caveat in the main SKILL.md before assuming any one of these is opt-in-free.

### Loading Indicators

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

### Button Groups

Connected and standard groups for related actions.

```kotlin
// Connected button group (shapes merge at boundaries)
ButtonGroup {
    Button(onClick = { }) { Text("Day") }
    Button(onClick = { }) { Text("Week") }
    Button(onClick = { }) { Text("Month") }
}
```

Use `Modifier.animateWidth()` in `ButtonGroupScope` on a group's children so they animate correctly when the group's contents change.

### Split Button

```kotlin
// SplitButton is the current name — SplitButtonLayout was deprecated in its favor
// as early as the 1.4.0 alpha train, before 1.4.0 shipped stable. Both still need
// @OptIn(ExperimentalMaterial3ExpressiveApi::class) on stable material3 1.4.0.
SplitButton(
    leadingButton = { Button(onClick = { }) { Text("Save") } },
    trailingButton = { /* dropdown */ }
)
```

### Floating Toolbar

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

### FAB with Spring Animation

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

## Adaptive Navigation

M3 supports adaptive navigation that shifts between bottom bar (compact), navigation rail (medium), and navigation drawer (expanded) based on window size class. Foldables and tablets are real use cases — don't design phone-only, and compute size class from the start rather than retrofitting it.

The current recommended way to read window size class is `currentWindowAdaptiveInfo()` from `androidx.compose.material3.adaptive`, which returns a `WindowAdaptiveInfo` wrapping a `androidx.window.core.layout.WindowSizeClass`. The older `androidx.compose.material3.windowsizeclass.WindowSizeClass` (`calculateWindowSizeClass()`) API is legacy — new code should use the adaptive-library path.

```kotlin
import androidx.compose.material3.adaptive.currentWindowAdaptiveInfo
import androidx.window.core.layout.WindowSizeClass
import androidx.window.core.layout.WindowWidthSizeClass

@Composable
fun AdaptiveNav(
    currentDestination: NavDestination?,
    onDestinationChange: (Destination) -> Unit
) {
    val windowSizeClass = currentWindowAdaptiveInfo().windowSizeClass

    when {
        windowSizeClass.isWidthAtLeastBreakpoint(WindowSizeClass.WIDTH_DP_EXPANDED_LOWER_BOUND) -> {
            PermanentNavigationDrawer(
                drawerContent = { /* drawer items */ }
            ) { /* content */ }
        }
        windowSizeClass.isWidthAtLeastBreakpoint(WindowSizeClass.WIDTH_DP_MEDIUM_LOWER_BOUND) -> {
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
        else -> {
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
    }
}
```

<details>
<summary>Legacy / deprecated</summary>

The pre-adaptive-library pattern, still common in older codebases and tutorials:

```kotlin
import androidx.compose.material3.windowsizeclass.WindowWidthSizeClass
import androidx.compose.material3.windowsizeclass.calculateWindowSizeClass

@Composable
fun AdaptiveNavLegacy(windowSizeClass: WindowSizeClass, /* ... */) {
    when (windowSizeClass.widthSizeClass) {
        WindowWidthSizeClass.Compact -> { /* NavigationBar */ }
        WindowWidthSizeClass.Medium -> { /* NavigationRail */ }
        WindowWidthSizeClass.Expanded -> { /* PermanentNavigationDrawer */ }
    }
}
```

Migrate to `currentWindowAdaptiveInfo()` + `androidx.window.core.layout.WindowSizeClass` when touching this code.
</details>

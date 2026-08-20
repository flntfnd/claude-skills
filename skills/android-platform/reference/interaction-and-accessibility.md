# Interaction & Accessibility

## Ripple Indication

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

Mirror M3E system behavior: fire haptics for confirmations, errors, and meaningful drag completions. `HapticFeedbackType.Confirm` and `.Reject` (along with `GestureEnd`, `ToggleOn`/`ToggleOff`, `SegmentTick`, and others) have been stable since Compose 1.8 — use the semantic type that matches the interaction rather than a generic tick.

```kotlin
val haptic = LocalHapticFeedback.current

// Selection
haptic.performHapticFeedback(HapticFeedbackType.LongPress)

// Confirmation / success
haptic.performHapticFeedback(HapticFeedbackType.Confirm)

// Failure / rejection
haptic.performHapticFeedback(HapticFeedbackType.Reject)
```

## Accessibility

M3 components enforce minimum touch targets (48dp) automatically. Custom components must do the same.

```kotlin
// Minimum touch target on custom components
Modifier.minimumInteractiveComponentSize()

// Semantic role
Modifier.semantics {
    role = Role.Button
    contentDescription = "Add item"
}
```

Color contrast: 4.5:1 for normal text, 3:1 for large text and interactive elements (WCAG AA). M3's semantic color roles are designed to meet this out of the box when used correctly — hardcoding hex values bypasses it.

Semantic roles: add `contentDescription` to all icons and interactive elements that don't have visible text labels.

Scale text with system font size. Don't hardcode `sp` values that ignore user preferences. All text must be defined in `sp`, not `dp`.

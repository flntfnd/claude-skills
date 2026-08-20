---
name: android-platform
description: Android platform design and implementation with Jetpack Compose and Material 3 Expressive (M3E). Covers M3 color roles and dynamic color (Material You), typography scale, shape system and shape morphing, physics-based motion (MotionScheme, springs), new M3E components (LoadingIndicator, ButtonGroup, SplitButton, FloatingToolbar), adaptive navigation (NavigationBar/Rail/Drawer, WindowSizeClass), haptics, accessibility, and custom rendering with Compose Canvas, AGSL shaders, and RenderEffect. Use when building, reviewing, or designing Android UI in Compose, implementing or auditing Material 3 / M3E theming, matching Android's platform visual signature (edge-to-edge, NavigationBar, FAB, Roboto, dynamic color), writing custom Canvas or shader-based rendering, or setting up spacing/shape/typography/motion tokens for an Android app or Figma file targeting Android.
---

# Android Platform (Jetpack Compose / Material 3 Expressive)

Target: current stable Android release, Compose-only, no XML layouts. Material 3 Expressive (M3E) is an evolution of Material You, not a replacement — it layers physics-based motion, expressive typography, shape morphing, and emotional clarity on top of the existing M3 token system. Motion, typography, and shape work together; designing one without the others produces something that looks like M3E but doesn't feel like it. Dynamic color (Material You) derives tones from the user's wallpaper — support it, with a fallback brand palette for devices or users that opt out.

This file covers what's checked constantly (the platform visual signature) inline. Everything else is split into reference files by subtopic.

## Quick Reference

| Topic | Covers | Reference |
| --- | --- | --- |
| Theme & color | BOM/setup, `AppTheme` wiring, M3 color roles, custom brand colors, AMOLED, dynamic color, contrast levels, dark mode tokens | [reference/theme-and-color.md](reference/theme-and-color.md) |
| Typography, shape, motion | Type scale, variable fonts (Roboto Flex), shape scale, shape morphing, `MotionScheme`, spring tokens, reduce-motion | [reference/typography-shape-motion.md](reference/typography-shape-motion.md) |
| Components & navigation | Spacing tokens, `LoadingIndicator`, `ButtonGroup`, `SplitButton`, `FloatingToolbar`, animated FAB, adaptive nav (bar/rail/drawer) | [reference/components-and-navigation.md](reference/components-and-navigation.md) |
| Interaction & accessibility | Ripple indication, haptics, touch targets, contrast, semantic roles, text scaling | [reference/interaction-and-accessibility.md](reference/interaction-and-accessibility.md) |
| Custom rendering | Compose `Canvas`, AGSL shaders, `RenderEffect`, `AnnotatedString` rich text | [reference/custom-rendering.md](reference/custom-rendering.md) |

## Platform Visual Signature

A correctly implemented Android / M3E design is immediately recognizable as Google-made. If it reads as "this looks like iOS" or "this looks like a website," the implementation is wrong.

**What makes it immediately look like Android:**
- Bottom navigation bar (`NavigationBar`) with 3-5 icon+label destinations
- Content fills edge-to-edge: status bar and system navigation bar are transparent, content shows behind them. This is not optional polish — apps targeting Android 16 (API 36)+ cannot opt out of edge-to-edge enforcement at all (Android 15/API 35 allowed a temporary opt-out flag; that flag is ignored on API 36+)
- Material You dynamic color — the app's color palette is derived from the user's wallpaper. The primary color changes per device
- Roboto Flex or Roboto throughout. Not SF Pro. Not Inter
- Floating Action Button (FAB) for the primary action on a screen, positioned lower-right above the NavigationBar
- `LargeTopAppBar` (or `LargeFlexibleTopAppBar`) that collapses as the user scrolls, not a static fixed header
- M3 shape system: slightly rounded (ExtraSmall = 4dp, Small = 8dp, Medium = 12dp). Not sharp. Not excessively rounded
- Ripple indication on all interactive surfaces

**Figma frame structure for phone (412 × 915, compact-width phone class):**
```
Frame: 412 × 915
  ├── Status Bar (32px, transparent — content shows through)
  ├── LargeTopAppBar (152px, collapses to 64px on scroll)
  ├── Content Area (fills remaining height, extends behind status bar)
  ├── NavigationBar (80px)
  └── System Navigation (gesture bar or 3-button, 24-48px)
```

Content extends edge-to-edge full width. Status bar and NavigationBar float over content with transparency — they do not push content down. Interactive content should be padded away from the system gesture zone.

**Figma frame structure for tablet / foldable (840 × 1080, medium width):**
```
Frame: 840 × 1080
  ├── Status Bar (32px)
  ├── NavigationRail (80px wide, left edge, full height) — replaces NavigationBar at this width
  └── Content Area (760px wide, full height)
```

**Wrong if:**
- The primary navigation is at the top (tabs at top read as iOS/web, not Android)
- Content does not extend behind the status bar and system navigation (no edge-to-edge)
- Colors are hardcoded instead of using M3 color roles (primary, onPrimary, surface, etc.)
- The font is SF Pro or a generic web sans-serif
- There is no FAB for primary actions
- Shape is all sharp corners (radius 0) or all pill shapes — M3 uses moderate, consistent radius
- Navigation is push-based like iOS rather than using `NavigationBar` destination switching

## Setup

```kotlin
// build.gradle — always use the latest stable BOM, check
// https://developer.android.com/develop/ui/compose/bom/bom-mapping for the current value
implementation(platform("androidx.compose:compose-bom:2026.08.00"))
implementation("androidx.compose.material3:material3")
```

That BOM (2026.08.00) maps to `material3` 1.4.0 stable. `material3` 1.5.0 is on the alpha track as of August 2026 (latest is 1.5.0-alpha26) and is where the M3E component surface is being promoted out of experimental, piece by piece; check the BOM mapping page before pinning a version.

The whole M3E surface — `MaterialExpressiveTheme`, `expressiveLightColorScheme`/`expressiveDarkColorScheme`, `MotionScheme`, and the newer components below — still requires `@OptIn(ExperimentalMaterial3ExpressiveApi::class)` in stable `material3` 1.4.0. Google's own Compose release notes confirm this: the 1.4.0 stable graduation list covers `WideNavigationRail`, `ShortNavigationBar`, and top app bar APIs, not the Expressive theme surface, and the December 2025 Jetpack Compose release post states plainly that "Material 3 Expressive APIs continue to be developed in the alpha releases of the material3 library." Graduation is happening inside the 1.5.0 alpha train instead — `MotionScheme` at 1.5.0-alpha15, `SplitButton` at 1.5.0-alpha20, `ButtonGroup` and `FloatingToolbar` at 1.5.0-alpha22 — but none of it has shipped in a stable release as of August 2026. `LoadingIndicator`'s stable promotion was merged and then reverted (1.5.0-alpha19); **`[Unverified]`: whether it has since re-landed in a later alpha.** Keep `@OptIn(ExperimentalMaterial3ExpressiveApi::class)` on all of this until pinning to a 1.5.0 alpha that has actually graduated the specific API in use.

## Anti-Patterns

- Using XML layouts alongside Compose in new code. Pick one per screen; don't mix for new work.
- Hardcoding colors outside the theme. Any `Color(0xFF...)` in a composable that isn't in the theme object is a problem.
- Using `CircularProgressIndicator` for short waits. `LoadingIndicator` exists for this.
- Ignoring window size class. Phone-only layout assumptions break on tablets, foldables, and ChromeOS.
- No edge-to-edge. Not calling `enableEdgeToEdge()` is a visual regression, and on Android 16+ it's also not something the system will forgive with an opt-out flag.
- Duration-based animations instead of springs. M3E moved away from this — match the system.
- Removing ripple indication. Ripple is the interaction contract on Android; removing it creates cognitive dissonance.

## Performance

- Recomposition is the biggest Compose performance issue. Minimize it.
- Use `remember` and `derivedStateOf` to avoid unnecessary recomposition. Don't read state inside composables that don't need it.
- `LazyColumn`/`LazyRow` for long lists. Never a regular `Column` with a loop.
- Avoid allocation during composition (no `mutableListOf()` inline). Move it into `remember` blocks.
- Test on low-end devices. Mid-tier Qualcomm equivalents are the real-world baseline for most Android users, not the newest flagship.
- Profile with Android Studio's Layout Inspector and the Composition tab in the profiler. Recomposition count is the primary signal.

---
name: apple-platform
description: Apple platform design system reference for SwiftUI targeting iOS 26+, iPadOS 26+, and macOS Tahoe 26+. Covers Liquid Glass APIs (.glassEffect, GlassEffectContainer, glass button styles, morphing, glass tokens), semantic color and typography tokens, Display P3, spacing scales, HIG animation/motion tokens (spring vs ease, symbol effects), navigation patterns (tab bars, NavigationSplitView, sheets, toolbars), component patterns (floating actions, sheet morphing), accessibility (reduced transparency, reduced motion, VoiceOver, contrast, touch targets), and custom rendering (SwiftUI Canvas, Animatable shapes, AttributedString, Metal/shader modifiers). Use when building or reviewing native Apple UI in SwiftUI, implementing or auditing Liquid Glass, checking whether a design reads as authentically iOS/iPadOS/macOS, choosing SwiftUI APIs for glass/motion/typography, or verifying HIG compliance. Tracks iOS 27 beta status for forward-looking work.
---

# Apple Platform Design System

SwiftUI only. No UIKit unless explicitly required. Baseline is iOS 26 / iPadOS 26 / macOS Tahoe 26 (Xcode 26 SDK) -- this is the current shipping stable version as of August 2026. iOS 27 / iPadOS 27 / macOS 27 "Golden Gate" are in public beta with GA expected September 2026; don't target them as the baseline yet. See [whats-new-ios27.md](reference/whats-new-ios27.md) for what's changing and what's still unconfirmed.

## Quick Reference

| Topic | Covers | Reference |
| --- | --- | --- |
| Liquid Glass | Material variants, `.glassEffect()` API, `GlassEffectContainer`, morphing, glass button styles, glass tokens, layering anti-patterns, GPU/performance rules | [reference/liquid-glass.md](reference/liquid-glass.md) |
| Color & typography | Semantic system colors, custom color tokens, contrast requirements, Display P3, type scale, spacing tokens, light/dark hex values | [reference/color-typography.md](reference/color-typography.md) |
| Motion & interaction | Animation duration/spring/ease tokens, HIG motion rules, symbol effects, gestures, haptics | [reference/motion-interaction.md](reference/motion-interaction.md) |
| Navigation & components | iOS/iPadOS/macOS navigation patterns, toolbar, floating action, sheets and sheet morphing | [reference/navigation-components.md](reference/navigation-components.md) |
| Accessibility | Reduced transparency/motion, Dynamic Type, VoiceOver, contrast ratios against glass blur, touch targets | [reference/accessibility.md](reference/accessibility.md) |
| Custom rendering | SwiftUI Canvas, `Animatable` shapes, `AttributedString` typography, Metal and `colorEffect`/`distortionEffect` shaders | [reference/custom-rendering.md](reference/custom-rendering.md) |
| iOS 27 status | WWDC 2026 recap, beta status, Liquid Glass and SwiftUI changes reported for iOS 27 -- flagged unverified where unconfirmed | [reference/whats-new-ios27.md](reference/whats-new-ios27.md) |

## Philosophy

Liquid Glass is a navigation-layer material. It floats above content. It does not touch content.

Three layers, in order:
1. Content (bottom): lists, media, text, cards. No glass.
2. Navigation (middle): toolbars, tab bars, sidebars, floating controls. Liquid Glass lives here.
3. Overlay (top): vibrancy, fills, and text rendered on glass surfaces.

If you're applying glass to content, you're doing it wrong.

## Platform Visual Signature

A correctly implemented iOS 26 / iPadOS 26 / macOS design is immediately recognizable as Apple-made. If someone sees the design and thinks "this looks like a web app" or "this looks like Android," the implementation is wrong. Check this on nearly every task in this domain.

**What makes it immediately look like iOS:**
- Tab bar sits at the bottom of the screen with glass treatment, floating above content
- Content scrolls behind both the status bar at top and the tab bar at bottom (edge-to-edge)
- Navigation is push-based: screens slide left/right. Back button in the upper-left.
- Large title at the top of a navigation stack collapses as the user scrolls
- Sheets are inset (not full-screen), float with rounded corners and glass background
- SF Pro font throughout. No third-party fonts unless deliberately part of a brand decision.
- SF Symbols for all iconography. No custom icon libraries.
- System semantic colors. The background shifts automatically between light and dark.

**Figma frame structure for iPhone (393 x 852, iPhone 15 Pro):**
```
Frame: 393 x 852
  +-- Status Bar (59px, transparent -- content shows through)
  +-- Navigation / Large Title (inline, collapses on scroll)
  +-- ScrollView Content (fills edge-to-edge, extends behind status bar and tab bar)
  +-- Tab Bar (83px from bottom, glass material, above safe area)
      +-- Home Indicator Safe Area (34px)
```

Content frames extend the full 852px height. The glass chrome floats on top -- it doesn't push content down. If content starts below the navigation bar and ends above the tab bar, the frame structure is wrong.

**Figma frame structure for iPad (1024 x 1366, iPad Pro 13"):**
```
Frame: 1024 x 1366
  +-- Status Bar (24px)
  +-- Sidebar NavigationSplitView (320px wide, glass treatment)
  +-- Detail / Content Area (704px wide, full height)
```

**What makes it immediately look like macOS:**
- Standard window chrome (traffic light buttons top-left, window title centered or leading)
- Mica-equivalent: the window background adapts to the desktop behind it
- Sidebar on the left with icon + label navigation
- Toolbar at the top with glass treatment
- Concentric corner radius: window corners align with contained elements

**Wrong if:**
- Tab bar is at the top (that's web or Android)
- Navigation bar has a solid opaque background (content should extend behind it)
- The design uses custom colors instead of system semantic colors
- Icons are not SF Symbols
- Text fields, buttons, or lists look like generic HTML form controls
- There is no glass treatment on the navigation layer
- Sheets are full-screen with no inset rounding
- Safe areas are ignored (content or interactive elements in the 59px top or 34px bottom zones)

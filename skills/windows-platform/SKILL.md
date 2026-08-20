---
name: windows-platform
description: Windows 11 / Fluent Design 2 / WinUI (formerly WinUI 3) design system reference for C#/XAML apps on the Windows App SDK. Covers Mica and Desktop Acrylic materials (MicaBackdrop, DesktopAcrylicBackdrop, SystemBackdropElement), semantic color brushes, Segoe UI Variable typography, spacing/corner-radius tokens, NavigationView, standard controls (buttons, text input, lists, cards, ContentDialog, flyouts, InfoBar), motion and Composition API animation, Win2D drawing, x:Bind/MVVM binding, DPI/responsive layout, accessibility (Narrator, High Contrast, AutomationProperties, touch targets), and the pre-ship testing checklist. Use when building or reviewing native Windows desktop UI in WinUI, auditing Mica/Acrylic usage, checking if a design reads as authentically Windows 11 vs. web/iOS/cross-platform, choosing WinUI APIs, or verifying Fluent Design compliance. Baseline: Windows App SDK 2.4 (stable, August 2026).
---

# Windows Platform Design System

Windows 11, Fluent Design 2, WinUI (Microsoft's official docs dropped the "3" suffix in 2026 -- "WinUI 3" and "WinUI" refer to the same thing; both remain in common use). Windows App SDK 2.4 is current stable as of August 2026. Target Windows 10 1809+ minimum, Windows 11 for full Mica/Acrylic support. Language: C# with XAML. Not WPF, UWP, or WinForms for new work.

## Quick Reference

| Topic | Covers | Reference |
| --- | --- | --- |
| Project architecture | Package references, TargetFramework, App.xaml bootstrap, `dotnet new winui`, x:Bind, MVVM Toolkit | [reference/project-architecture.md](reference/project-architecture.md) |
| Materials & color | Mica, Desktop Acrylic, `SystemBackdropElement`, fallback conditions, layer hierarchy, semantic brushes, accent color, theming | [reference/materials.md](reference/materials.md) |
| Typography & layout | Segoe UI Variable text styles, spacing tokens, corner radius, adaptive triggers, DPI scaling | [reference/typography-layout.md](reference/typography-layout.md) |
| Navigation & controls | NavigationView, title bar, TabView, buttons, text input, selection controls, lists, cards, dialogs, flyouts, InfoBar | [reference/navigation-controls.md](reference/navigation-controls.md) |
| Motion | Timing tokens, page transitions, connected animations, implicit Composition animations, reduced motion | [reference/motion.md](reference/motion.md) |
| Accessibility & testing | Touch targets, AutomationProperties, Narrator, High Contrast themes, Accessibility Insights, the pre-ship checklist | [reference/accessibility-testing.md](reference/accessibility-testing.md) |
| Custom rendering | Composition API expression animations, InteractionTracker, Win2D drawing/effects, pointer input differentiation | [reference/custom-rendering.md](reference/custom-rendering.md) |
| Performance & anti-patterns | Virtualized lists, async loading, `x:Load`, deferred init, the hardcoded-color/Acrylic-misuse/blocking-thread mistakes to catch in review | [reference/performance-and-anti-patterns.md](reference/performance-and-anti-patterns.md) |

## Philosophy

Fluent Design for Windows 11 is built around three foundations: materials that absorb and adapt to the user's environment, geometry that signals hierarchy through roundness and elevation, and motion that is brief and purposeful.

Windows apps run in resizable windows across variable DPI, scaling, and input methods. Design and build for all of them. Write code that doesn't assume a resolution, DPI, or input method.

Get it right the first time. Don't write code you'd flag in an audit. If a pattern's current API is unclear, research before building.

## Platform Visual Signature

A correctly implemented Windows / Fluent Design app is immediately recognizable as Microsoft-made. If the design looks like a web app, an iOS app, or a generic cross-platform app running on Windows, the implementation is wrong.

**What makes it immediately look like Windows:**
- Mica background: the app window has a subtle, desaturated, blurred version of the desktop wallpaper visible through the background. This is not a solid flat color.
- NavigationView on the left side with icon + optional label navigation items. Adapts from icon-only (compact, 641-1007px wide) to icon + label (expanded, 1008px+) automatically.
- Standard window chrome: title bar at the top, close/minimize/maximize buttons in the top-right corner. The title bar extends the Mica surface.
- Segoe UI Variable font throughout. Not SF Pro, not Inter, not system sans.
- Windows 11 corner radius: 8px everywhere by default. Cards, buttons, inputs all use 8px. Not 0, not 12+.
- Acrylic (frosted glass with colored tint) for menus, flyouts, and context menus -- transient surfaces. Not for the persistent window background (that's Mica).
- System accent color: one user-defined color that flows through interactive states (selected, focused, primary button). It changes based on Windows personalization settings.

**Figma frame structure for desktop (1440 x 900, standard window):**
```
Frame: 1440 x 900
  +-- Title Bar (40px, Mica surface, traffic-light buttons right-aligned)
  +-- NavigationView Pane (320px wide, left edge, Mica surface)
  |     +-- Nav items (48px tall each, icon + label)
  |     +-- Footer nav items (Settings, etc.)
  +-- Content Area (1120px wide, full height minus title bar)
        +-- Page content with 24-32px margin
```

**Figma frame structure for compact window (700 x 600):**
```
Frame: 700 x 600
  +-- Title Bar (40px)
  +-- NavigationView Pane (48px wide -- icon only, no labels)
  +-- Content Area (652px wide)
```

**Figma: simulating Mica in Figma**
Place a desaturated, blurred (30-50px) desktop wallpaper image behind the app frame at 40-60% opacity. On top of that, a white-to-transparent gradient at 60-70% opacity. The result approximates Mica's luminosity-based material. Do not use a flat solid color for the window background.

**The Mica/Acrylic surface-assignment rule (checked constantly, commonly gotten backwards):**
- **Mica** -> persistent, long-lived surfaces: the main window background, title bar, NavigationView pane. Communicates window focus state. Windows 11 only; falls back to a solid theme color on Windows 10.
- **Desktop Acrylic** -> also a `Window.SystemBackdrop` option, but shows a live see-through blur of the desktop and content behind the window. Windows 10 1809+.
- **In-app `AcrylicBrush`** and **transient-surface Acrylic** -> flyouts, context menus, tooltips, `MenuFlyoutPresenter`, `CommandBarFlyoutCommandBar` -- surfaces that appear and dismiss. Never as the base layer of a persistent window.
- Getting this backwards (Acrylic as the window background, Mica on a flyout) is the single most common Windows-platform material mistake. See [reference/materials.md](reference/materials.md) for the full decision table and fallback conditions (RDP, low-end GPU, Battery Saver, transparency setting, High Contrast).

**Wrong if:**
- The window background is a flat solid color with no Mica treatment
- Navigation is at the top (tab bar) instead of the left (NavigationView) for primary destinations
- Window chrome is missing or the close/minimize/maximize controls are on the wrong side (they must be top-right)
- The font is not Segoe UI Variable
- Corner radius is 0 or greater than 12px on standard controls
- The app does not resize adaptively (fixed layout that doesn't respond to window width changes)
- Menus and flyouts use the same solid background as the page instead of Acrylic
- Acrylic is used as the persistent window background, or Mica is used on a flyout/context menu

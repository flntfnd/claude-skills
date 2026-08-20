# Materials & Color

## Contents

- [Which Material Should I Use](#which-material-should-i-use)
- [Automatic Fallback Conditions](#automatic-fallback-conditions)
- [Mica](#mica)
- [Desktop Acrylic (window background)](#desktop-acrylic-window-background)
- [SystemBackdropElement (per-element material)](#systembackdropelement-per-element-material)
- [In-App Acrylic (AcrylicBrush)](#in-app-acrylic-acrylicbrush)
- [Layer Hierarchy](#layer-hierarchy)
- [Semantic Brushes](#semantic-brushes)
- [Accent Color](#accent-color)
- [Theme Support](#theme-support)

## Which Material Should I Use

| Scenario | Material | API |
| --- | --- | --- |
| App window with a Mica background (wallpaper-tinted) | Mica | `Window.SystemBackdrop = new MicaBackdrop()` |
| App window with a see-through frosted-glass background | Desktop Acrylic | `Window.SystemBackdrop = new DesktopAcrylicBackdrop()` |
| Flyout, popup, or context menu with an Acrylic background | System backdrop on a surface | Set `SystemBackdrop` on `FlyoutBase`, `Popup`, etc. |
| Sidebar, panel, or element with Mica or Acrylic (not the whole window) | `SystemBackdropElement` | `<SystemBackdropElement>` control |
| Navigation pane or content panel with an in-app blur effect | In-app Acrylic | `{ThemeResource AcrylicInAppFillColorDefaultBrush}` |

`AcrylicBrush` (in-app Acrylic) only blurs XAML content within the app window -- it never shows the desktop or other windows behind it. For a desktop-see-through effect, use `Window.SystemBackdrop` or `SystemBackdropElement`. Confusing these two is the second most common material mistake after swapping Mica and Acrylic's roles entirely.

When no material is applied, the window falls back to a solid color drawn from the active light/dark theme -- no blur, no translucency.

## Automatic Fallback Conditions

WinUI falls back to a solid theme color automatically in these cases. Don't write detection code for them -- just make sure your configured `FallbackColor` / theme background reads fine as a flat color:

- **Remote Desktop or a VM**: the compositor can't blend with desktop content over RDP.
- **Insufficient graphics hardware**: Mica and Desktop Acrylic need DirectX 11 and adequate GPU memory.
- **Transparency effects disabled**: Settings > Personalization > Colors > Transparency effects off disables all `SystemBackdrop` materials and `AcrylicBrush`.
- **Battery Saver active**: disables both materials -- Acrylic (`DesktopAcrylicBackdrop`, `AcrylicBrush`) and Mica (`MicaBackdrop`) all fall back to solid color. Mica is not exempt from this one.
- **High Contrast mode**: all materials are suppressed; high-contrast theme colors apply instead.

## Mica

Mica is the foundation layer. It samples the user's desktop wallpaper to create a personalized, muted tint. Use it on long-lived primary surfaces: main window background, title bar, NavigationView pane. It communicates window focus state. Windows 11 only -- falls back to a solid theme color on Windows 10.

```csharp
// MainWindow.xaml.cs
public MainWindow()
{
    InitializeComponent();
    SystemBackdrop = new MicaBackdrop();
    ExtendsContentIntoTitleBar = true;
    SetTitleBar(AppTitleBar);
}
```

Check OS capability explicitly if you need custom fallback behavior; otherwise the default background is already the correct fallback and no branching is needed:

```csharp
if (MicaBackdrop.IsSupported())
{
    SystemBackdrop = new MicaBackdrop();
}
// No else needed -- default background is correct fallback
```

Variants: `MicaKind.Base` (default) or `MicaKind.BaseAlt` (lighter tint, for secondary/tabbed-window surfaces).

```csharp
SystemBackdrop = new MicaBackdrop { Kind = MicaKind.BaseAlt };
```

## Desktop Acrylic (window background)

Desktop Acrylic is also a `Window.SystemBackdrop` option -- it shows a live, blurred view of the desktop and content behind the window, producing a frosted-glass look for the whole window (distinct from Acrylic-on-transient-surfaces, below). Windows 10 (build 17763) and later.

```csharp
SystemBackdrop = new DesktopAcrylicBackdrop();
```

Variants: `DesktopAcrylicKind.Base` (more opaque) or `DesktopAcrylicKind.Thin` (more transparent).

## SystemBackdropElement (per-element material)

`SystemBackdropElement` applies a Mica or Desktop Acrylic material from the OS compositor to one XAML element -- not the whole window. Use it when a sidebar, panel, or card needs its own material independently of the rest of the window. Requires Windows App SDK 2.0+.

```xml
<SystemBackdropElement>
    <CommandBar Background="Transparent" />
</SystemBackdropElement>
```

Acrylic can also be applied directly to transient surfaces by setting `SystemBackdrop` on `FlyoutBase`, `Popup`, `MenuFlyoutPresenter`, or `CommandBarFlyoutCommandBar`.

## In-App Acrylic (AcrylicBrush)

`AcrylicBrush` blurs XAML content *within* the app window only -- no desktop or other-window content shows through. Use it for navigation panes, sidebars, or content panels where you want a translucent in-app effect without a full system backdrop.

```xml
<Border Background="{ThemeResource AcrylicInAppFillColorDefaultBrush}">
    <!-- content -->
</Border>
```

Or a custom brush with `TintColor`, `TintOpacity`, and `TintLuminosityOpacity`. The UWP `BackgroundSource = HostBackdrop` property does not exist in WinUI.

## Layer Hierarchy

Three content layers above Mica:

```
Mica base        -> window background, title bar
LayerOnMicaBaseAltFillColorDefaultBrush -> NavigationView pane, command areas
LayerFillColorDefaultBrush              -> cards, grids, content containers
Acrylic          -> flyouts, context menus, tooltips
Smoke overlay    -> ContentDialog backdrop (automatic)
```

In XAML, set container backgrounds to the correct semantic brush:

```xml
<Grid Background="{ThemeResource LayerFillColorDefaultBrush}">
    <!-- Content -->
</Grid>
```

## Semantic Brushes

Never hardcode colors. All brushes below handle light/dark, high contrast, and accent color automatically.

```xml
<!-- Backgrounds -->
{ThemeResource ApplicationPageBackgroundThemeBrush}
{ThemeResource LayerFillColorDefaultBrush}
{ThemeResource LayerOnMicaBaseAltFillColorDefaultBrush}
{ThemeResource SubtleFillColorSecondaryBrush}       <!-- hover -->
{ThemeResource SubtleFillColorTertiaryBrush}        <!-- pressed -->

<!-- Text -->
{ThemeResource TextFillColorPrimaryBrush}
{ThemeResource TextFillColorSecondaryBrush}
{ThemeResource TextFillColorTertiaryBrush}          <!-- hints, placeholders -->
{ThemeResource TextFillColorDisabledBrush}

<!-- Controls -->
{ThemeResource ControlFillColorDefaultBrush}        <!-- button bg -->
{ThemeResource ControlFillColorSecondaryBrush}      <!-- hover -->
{ThemeResource ControlFillColorTertiaryBrush}       <!-- pressed -->
{ThemeResource ControlFillColorDisabledBrush}

<!-- Strokes -->
{ThemeResource ControlStrokeColorDefaultBrush}
{ThemeResource ControlStrokeColorSecondaryBrush}    <!-- bottom border accent -->
{ThemeResource DividerStrokeColorDefaultBrush}

<!-- Accent -->
{ThemeResource AccentFillColorDefaultBrush}
{ThemeResource AccentFillColorSecondaryBrush}
{ThemeResource AccentFillColorTertiaryBrush}
{ThemeResource TextOnAccentFillColorPrimaryBrush}

<!-- Status -->
{ThemeResource SystemFillColorSuccessBrush}
{ThemeResource SystemFillColorCautionBrush}
{ThemeResource SystemFillColorCriticalBrush}
{ThemeResource SystemFillColorAttentionBrush}
```

## Accent Color

The system accent is user-chosen. Never hardcode it. Access programmatically when needed:

```csharp
var accentColor = (Color)Application.Current.Resources["SystemAccentColor"];
```

## Theme Support

Light and dark mode are automatic with WinUI. To force a theme per element:

```xml
<FrameworkElement RequestedTheme="Dark" />
```

To respond to system theme changes:

```csharp
UISettings uiSettings = new();
uiSettings.ColorValuesChanged += OnColorValuesChanged;
```

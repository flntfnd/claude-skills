# Accessibility & Testing

## Contents

- [Minimum Requirements](#minimum-requirements)
- [Accessibility Insights (current recommended tool)](#accessibility-insights-current-recommended-tool)
- [Display and Scaling](#display-and-scaling)
- [Window Size](#window-size)
- [The Pre-Ship Accessibility Checklist](#the-pre-ship-accessibility-checklist)
- [ContentDialog XamlRoot](#contentdialog-xamlroot)
- [Narrator Announcement Spot Check](#narrator-announcement-spot-check)

## Minimum Requirements

Touch targets: 40x40px minimum on all interactive elements (confirmed current guidance -- effective pixels at the 7.5mm/135 PPI reference plateau, scales with system-level DPI).

Every icon-only button needs `AutomationProperties.Name`:

```xml
<Button AutomationProperties.Name="Close window">
    <FontIcon Glyph="&#xE711;" />
</Button>

<Image Source="logo.png"
       AutomationProperties.Name="App logo" />
```

Keyboard navigation is automatic for WinUI controls. Don't break it. Every interactive element must be reachable by Tab and operable by Enter or Space.

Focus visuals are system-correct in WinUI. Don't remove them.

High Contrast mode: all semantic brushes adapt automatically. Test with a contrast theme enabled (Settings > Accessibility > Contrast themes -- the four built-in themes are named Aquatic, Desert, Dusk, and Night sky). If any element becomes unreadable, a hardcoded color is the cause.

Screen reader (Narrator) live regions for dynamic content:

```xml
<TextBlock
    AutomationProperties.LiveSetting="Polite"
    Text="{x:Bind StatusMessage}" />
```

## Accessibility Insights (current recommended tool)

Microsoft's current guidance leads with [Accessibility Insights](https://accessibilityinsights.io/) rather than the older standalone SDK tools:

- **Live Inspect**: hover or focus an element to verify its UI Automation properties on the spot.
- **FastPass**: a two-step check that surfaces common, high-impact issues in under five minutes.
- **Troubleshooting**: deeper diagnosis for a specific flagged issue.

<details>
<summary>Legacy / deprecated</summary>

The older Windows SDK tools -- **AccScope**, **Inspect**, **UI Accessibility Checker (AccChecker)**, **UI Automation Verify**, **Accessible Event Watcher (AccEvent)** -- still ship in the Windows SDK `bin` folder and remain useful for deep UI Automation tree/property/event inspection (e.g. verifying a custom control's control patterns). Microsoft's docs now explicitly recommend transitioning to Accessibility Insights first, and reaching for the legacy tools only when you need lower-level UIA inspection than Accessibility Insights provides.

</details>

## Display and Scaling

- Windows 10 (1809+): Mica falls back to solid color. Verify the fallback looks intentional, not broken.
- Windows 11: full Mica/Acrylic support. Verify material hierarchy is correct.
- 100% DPI: baseline
- 125% DPI: most common on laptop displays
- 150% DPI: common on high-DPI displays
- 175% and 200% DPI: common on Surface and 4K displays
- Multi-monitor setups with mixed DPI: drag the window between monitors and verify it re-renders cleanly

## Window Size

- Compact (~641px wide): NavigationView collapses to Minimal mode. Hamburger menu must work. Content must not clip.
- Compact with compact window height: verify vertical layout doesn't overflow
- Normal width (641-1007px): NavigationView Compact (icon-only) mode
- Expanded (1008px+): NavigationView Expanded (full sidebar) mode
- Maximized on large display: verify nothing stretches incorrectly

## The Pre-Ship Accessibility Checklist

Every one of these must pass before shipping:

- **High Contrast themes**: Settings > Accessibility > Contrast themes. Enable each (Aquatic, Desert, Dusk, Night sky). All text must be readable. Interactive elements must be identifiable. Nothing should disappear.
- **Narrator**: Enable and navigate the entire app with keyboard + Narrator only. Every interactive element must be reachable and have a meaningful announcement. Icon-only buttons must have `AutomationProperties.Name`.
- **Keyboard-only navigation**: Disconnect the mouse. Tab through every interactive element. Focus visuals must be visible at all times. Nothing should be reachable only by mouse.
- **Increase text size**: Settings > Accessibility > Text size. Drag to maximum. Text must scale without truncation or overlap.

## ContentDialog XamlRoot

`ContentDialog` requires `XamlRoot = this.XamlRoot`. Test every dialog is set correctly -- missing XamlRoot throws at runtime, not compile time.

## Narrator Announcement Spot Check

```csharp
// Every icon-only button must have this
<Button AutomationProperties.Name="Close window">
    <FontIcon Glyph="&#xE711;" />
</Button>
```

Verify with Narrator: focus the button, Narrator must announce the name. If it announces nothing or announces the glyph character, the `AutomationProperties.Name` is missing.

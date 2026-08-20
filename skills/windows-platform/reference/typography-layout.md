# Typography & Layout

## Contents

- [Segoe UI Variable](#segoe-ui-variable)
- [Spacing Tokens](#spacing-tokens)
- [Corner Radius](#corner-radius)
- [Adaptive Triggers](#adaptive-triggers)
- [DPI Scaling](#dpi-scaling)

## Segoe UI Variable

The system typeface. Use WinUI's semantic text styles -- never set `FontFamily` manually.

```xml
<TextBlock Style="{StaticResource DisplayTextBlockStyle}" Text="Display" />
<TextBlock Style="{StaticResource TitleLargeTextBlockStyle}" Text="Title Large" />
<TextBlock Style="{StaticResource TitleTextBlockStyle}" Text="Title" />
<TextBlock Style="{StaticResource SubtitleTextBlockStyle}" Text="Subtitle" />
<TextBlock Style="{StaticResource BodyLargeTextBlockStyle}" Text="Body Large" />
<TextBlock Style="{StaticResource BodyStrongTextBlockStyle}" Text="Body Strong" />
<TextBlock Style="{StaticResource BodyTextBlockStyle}" Text="Body" />
<TextBlock Style="{StaticResource CaptionTextBlockStyle}" Text="Caption" />
```

Segoe UI Variable is a variable font with optical sizing built in. Large text uses Display optical sizing, small text uses Text optical sizing -- automatic, no code needed.

Never hardcode `FontSize`, `FontWeight`, or `FontFamily` on production text layers. Always reference a text style.

## Spacing Tokens

Define spacing as constants, not magic numbers:

```csharp
public static class Spacing
{
    public const double XXS   =  4;
    public const double XS    =  8;
    public const double SM    = 12;
    public const double Base  = 16;
    public const double MD    = 20;
    public const double LG    = 24;
    public const double XL    = 32;
    public const double XXL   = 40;   // standard content margin
    public const double XXXL  = 64;
}
```

Or as XAML resources:

```xml
<x:Double x:Key="SpacingBase">16</x:Double>
<x:Double x:Key="SpacingXXL">40</x:Double>
<Thickness x:Key="ContentPageMargin">40,24,40,24</Thickness>
<Thickness x:Key="CardPadding">16,12,16,12</Thickness>
```

## Corner Radius

Use system corner radius resources:

```xml
<CornerRadius x:Key="OverlayCornerRadius">8</CornerRadius>
<CornerRadius x:Key="ControlCornerRadius">4</CornerRadius>
<CornerRadius x:Key="SmallControlCornerRadius">2</CornerRadius>
```

Apply via resource, not hardcoded values:

```xml
<Border CornerRadius="{StaticResource OverlayCornerRadius}"
        Background="{ThemeResource LayerFillColorDefaultBrush}">
    <!-- card content -->
</Border>
```

## Adaptive Triggers

```xml
<Grid x:Name="RootGrid" Margin="{StaticResource ContentPageMargin}">
    <VisualStateManager.VisualStateGroups>
        <VisualStateGroup x:Name="WindowStates">
            <VisualState x:Name="Compact">
                <VisualState.StateTriggers>
                    <AdaptiveTrigger MinWindowWidth="0" />
                </VisualState.StateTriggers>
                <VisualState.Setters>
                    <Setter Target="RootGrid.Margin" Value="12,12,12,12" />
                    <Setter Target="SidePanel.Visibility" Value="Collapsed" />
                </VisualState.Setters>
            </VisualState>
            <VisualState x:Name="Normal">
                <VisualState.StateTriggers>
                    <AdaptiveTrigger MinWindowWidth="641" />
                </VisualState.StateTriggers>
            </VisualState>
            <VisualState x:Name="Wide">
                <VisualState.StateTriggers>
                    <AdaptiveTrigger MinWindowWidth="1008" />
                </VisualState.StateTriggers>
                <VisualState.Setters>
                    <Setter Target="SidePanel.Visibility" Value="Visible" />
                </VisualState.Setters>
            </VisualState>
        </VisualStateGroup>
    </VisualStateManager.VisualStateGroups>
</Grid>
```

641px and 1008px match `NavigationView`'s own default `CompactModeThresholdWidth` / `ExpandedModeThresholdWidth` -- keep custom adaptive breakpoints aligned with those unless you've deliberately customized NavigationView's thresholds too (see [navigation-controls.md](navigation-controls.md)).

## DPI Scaling

WinUI scales automatically. All XAML values are device-independent pixels. Never hardcode pixel values assuming 96 DPI. Test at 100%, 125%, 150%, 175%, and 200% scaling.

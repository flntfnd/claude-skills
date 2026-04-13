# WINDOWS.md
Windows 11 / Fluent Design 2 / WinUI 3
Windows App SDK 1.8+ (stable, September 2025). Target: Windows 10 1809+ minimum, Windows 11 for Mica.
Language: C# with XAML. Framework: WinUI 3 via Windows App SDK. Not WPF, UWP, or WinForms for new work.

---

# Philosophy

Fluent Design for Windows 11 is built around three foundations: materials that absorb and adapt to the user's environment, geometry that signals hierarchy through roundness and elevation, and motion that is brief and purposeful.

Windows apps run in resizable windows across variable DPI, scaling, and input methods. Design and build for all of them. Write code that doesn't assume a resolution, DPI, or input method.

Get it right the first time. Don't write code you'd flag in an audit. If a pattern's current API is unclear, research before building.

---

# Project Setup

## Package References

```xml
<!-- .csproj -->
<ItemGroup>
    <PackageReference Include="Microsoft.WindowsAppSDK" Version="1.8.*" />
    <PackageReference Include="Microsoft.Windows.SDK.BuildTools" Version="10.0.26100.*" />
</ItemGroup>

<PropertyGroup>
    <TargetFramework>net8.0-windows10.0.19041.0</TargetFramework>
    <TargetPlatformMinVersion>10.0.17763.0</TargetPlatformMinVersion>
    <RuntimeIdentifiers>win-x86;win-x64;win-arm64</RuntimeIdentifiers>
</PropertyGroup>
```

## App.xaml Bootstrap

```xml
<!-- App.xaml -->
<Application
    x:Class="YourApp.App"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
    <Application.Resources>
        <ResourceDictionary>
            <ResourceDictionary.MergedDictionaries>
                <XamlControlsResources xmlns="using:Microsoft.UI.Xaml.Controls" />
            </ResourceDictionary.MergedDictionaries>
        </ResourceDictionary>
    </Application.Resources>
</Application>
```

`XamlControlsResources` is required. Without it, WinUI controls won't render correctly.

---

# Material System

## Mica

Mica is the foundation layer. It samples the user's desktop wallpaper once at launch to create a personalized tint. Use it on long-lived primary surfaces. It communicates window focus state.

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

Windows 10 fallback: Mica falls back to `ApplicationPageBackgroundThemeBrush`. Handle gracefully.

```csharp
// Check OS capability before applying Mica
if (MicaBackdrop.IsSupported())
{
    SystemBackdrop = new MicaBackdrop();
}
// No else needed -- default background is correct fallback
```

Mica Alt (stronger tinting, tabbed windows):

```csharp
SystemBackdrop = new MicaBackdrop { Kind = MicaKind.BaseAlt };
```

## Acrylic

Acrylic is for transient surfaces only: flyouts, context menus, tooltips, side panels that appear and dismiss. Never as the base layer of a persistent window.

```csharp
// For a transient window
SystemBackdrop = new DesktopAcrylicBackdrop();
```

Applying Acrylic selectively via `SystemBackdropHost` (available in recent Windows App SDK):

```xml
<SystemBackdropHost>
    <CommandBar Background="Transparent" />
</SystemBackdropHost>
```

## Layer Hierarchy

Three content layers above Mica:

```
Mica base        → window background, title bar
LayerOnMicaBaseAltFillColorDefaultBrush → NavigationView pane, command areas
LayerFillColorDefaultBrush              → cards, grids, content containers
Acrylic          → flyouts, context menus, tooltips
Smoke overlay    → ContentDialog backdrop (automatic)
```

In XAML, set container backgrounds to the correct semantic brush:

```xml
<Grid Background="{ThemeResource LayerFillColorDefaultBrush}">
    <!-- Content -->
</Grid>
```

---

# Color

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

---

# Typography

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

---

# Spacing Tokens

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

---

# Corner Radius

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

---

# Navigation

## NavigationView

The primary navigation pattern. Adaptive across three modes automatically based on window width:
- Expanded (>1008px): full sidebar with labels
- Compact (641-1007px): icon-only sidebar
- Minimal (<641px): hamburger overlay

```xml
<NavigationView
    x:Name="NavView"
    IsSettingsVisible="True"
    IsBackButtonVisible="Visible"
    BackRequested="NavView_BackRequested"
    ItemInvoked="NavView_ItemInvoked"
    SelectionFollowsFocus="Enabled">

    <NavigationView.MenuItems>
        <NavigationViewItem
            Content="Home"
            Tag="home"
            Icon="Home" />
        <NavigationViewItem
            Content="Browse"
            Tag="browse"
            Icon="Library" />
        <NavigationViewItemSeparator />
        <NavigationViewItem
            Content="Settings"
            Tag="settings"
            Icon="Setting" />
    </NavigationView.MenuItems>

    <Frame x:Name="ContentFrame" />
</NavigationView>
```

```csharp
private void NavView_ItemInvoked(NavigationView sender,
    NavigationViewItemInvokedEventArgs args)
{
    if (args.IsSettingsInvoked)
    {
        ContentFrame.Navigate(typeof(SettingsPage));
        return;
    }
    var tag = args.InvokedItemContainer?.Tag?.ToString();
    var pageType = tag switch
    {
        "home"    => typeof(HomePage),
        "browse"  => typeof(BrowsePage),
        _         => null
    };
    if (pageType != null)
        ContentFrame.Navigate(pageType,
            null,
            new EntranceNavigationTransitionInfo());
}

private void NavView_BackRequested(NavigationView sender,
    NavigationViewBackRequestedEventArgs args)
{
    if (ContentFrame.CanGoBack)
        ContentFrame.GoBack();
}
```

## Title Bar

Extend into title bar for seamless Mica:

```csharp
ExtendsContentIntoTitleBar = true;
SetTitleBar(AppTitleBar); // UIElement in XAML

// Adjust left inset for caption buttons
AppTitleBar.Loaded += (s, e) =>
{
    AppTitleBarText.Margin = new Thickness(
        AppWindow.TitleBar.LeftInset + 16, 0, 0, 0);
};
AppTitleBar.SizeChanged += (s, e) =>
{
    AppTitleBarText.Margin = new Thickness(
        AppWindow.TitleBar.LeftInset + 16, 0, 0, 0);
};
```

## TabView

For multi-document or multi-instance content:

```xml
<TabView
    TabWidthMode="Equal"
    CanTearOutTabs="True"
    AddTabButtonClick="TabView_AddTabButtonClick"
    TabCloseRequested="TabView_TabCloseRequested">
</TabView>
```

---

# Controls

## Buttons

```xml
<!-- Primary action (one per surface) -->
<Button Style="{StaticResource AccentButtonStyle}"
        Content="Save"
        Click="Save_Click" />

<!-- Standard action -->
<Button Content="Cancel" Click="Cancel_Click" />

<!-- Destructive action -->
<Button Content="Delete"
        Foreground="{ThemeResource SystemFillColorCriticalBrush}"
        Click="Delete_Click" />

<!-- Icon-only -->
<Button ToolTipService.ToolTip="Settings">
    <FontIcon Glyph="&#xE713;" FontSize="16" />
</Button>

<!-- Split button -->
<SplitButton Content="Save" Click="SaveDefault_Click">
    <SplitButton.Flyout>
        <MenuFlyout>
            <MenuFlyoutItem Text="Save as..." />
            <MenuFlyoutItem Text="Export..." />
        </MenuFlyout>
    </SplitButton.Flyout>
</SplitButton>
```

## Text Input

```xml
<TextBox
    Header="Display name"
    PlaceholderText="Enter your name"
    MaxLength="100"
    TextChanged="Name_TextChanged" />

<PasswordBox
    Header="Password"
    PlaceholderText="Enter password"
    PasswordRevealMode="Peek"
    PasswordChanged="Password_Changed" />

<NumberBox
    Header="Quantity"
    Value="{x:Bind Quantity, Mode=TwoWay}"
    Minimum="1"
    Maximum="99"
    SpinButtonPlacementMode="Compact"
    ValidationMode="InvalidInputOverwritten" />

<AutoSuggestBox
    PlaceholderText="Search"
    QueryIcon="Find"
    TextChanged="Search_TextChanged"
    QuerySubmitted="Search_QuerySubmitted" />
```

## Selection Controls

```xml
<ToggleSwitch
    Header="Enable notifications"
    IsOn="{x:Bind NotificationsEnabled, Mode=TwoWay}" />

<CheckBox
    Content="Remember me"
    IsChecked="{x:Bind RememberMe, Mode=TwoWay}" />

<RadioButton Content="Option A"
             GroupName="myGroup"
             IsChecked="{x:Bind IsOptionA, Mode=TwoWay}" />

<ComboBox
    Header="Theme"
    SelectedItem="{x:Bind SelectedTheme, Mode=TwoWay}"
    ItemsSource="{x:Bind Themes}" />

<Slider
    Header="Volume"
    Minimum="0"
    Maximum="100"
    Value="{x:Bind Volume, Mode=TwoWay}"
    TickFrequency="10"
    TickPlacement="Outside" />
```

## Lists

```xml
<!-- Virtualized list (always use for >50 items) -->
<ListView
    ItemsSource="{x:Bind Items}"
    SelectionMode="Single"
    IsItemClickEnabled="True"
    ItemClick="Item_Click">
    <ListView.ItemTemplate>
        <DataTemplate x:DataType="local:MyItem">
            <StackPanel Orientation="Horizontal" Spacing="12" Padding="0,8,0,8">
                <PersonPicture
                    ProfilePicture="{x:Bind Avatar}"
                    Width="36" Height="36" />
                <StackPanel>
                    <TextBlock
                        Text="{x:Bind Name}"
                        Style="{StaticResource BodyStrongTextBlockStyle}" />
                    <TextBlock
                        Text="{x:Bind Description}"
                        Style="{StaticResource CaptionTextBlockStyle}"
                        Foreground="{ThemeResource TextFillColorSecondaryBrush}" />
                </StackPanel>
            </StackPanel>
        </DataTemplate>
    </ListView.ItemTemplate>
</ListView>
```

## Cards

WinUI doesn't have a `Card` control. Build from `Border`:

```xml
<Border
    CornerRadius="{StaticResource OverlayCornerRadius}"
    Background="{ThemeResource LayerFillColorDefaultBrush}"
    BorderBrush="{ThemeResource DividerStrokeColorDefaultBrush}"
    BorderThickness="1"
    Padding="{StaticResource CardPadding}">
    <!-- Card content -->
</Border>
```

## Dialogs and Flyouts

```xml
<!-- Modal dialog (Smoke overlay applied automatically) -->
<ContentDialog
    Title="Delete item?"
    PrimaryButtonText="Delete"
    CloseButtonText="Cancel"
    DefaultButton="Close"
    IsPrimaryButtonEnabled="True">
    <TextBlock TextWrapping="Wrap">
        This action cannot be undone.
    </TextBlock>
</ContentDialog>
```

```csharp
// Show dialog
var dialog = new ContentDialog
{
    Title = "Delete item?",
    Content = "This action cannot be undone.",
    PrimaryButtonText = "Delete",
    CloseButtonText = "Cancel",
    DefaultButton = ContentDialogButton.Close,
    XamlRoot = this.XamlRoot  // Required in WinUI 3
};
var result = await dialog.ShowAsync();
if (result == ContentDialogResult.Primary)
    DeleteItem();
```

```xml
<!-- Non-modal flyout -->
<Button Content="More options">
    <Button.Flyout>
        <MenuFlyout>
            <MenuFlyoutItem Text="Edit" Icon="Edit" Click="Edit_Click" />
            <MenuFlyoutItem Text="Share" Icon="Share" Click="Share_Click" />
            <MenuFlyoutSeparator />
            <MenuFlyoutItem
                Text="Delete"
                Foreground="{ThemeResource SystemFillColorCriticalBrush}"
                Click="Delete_Click" />
        </MenuFlyout>
    </Button.Flyout>
</Button>
```

## InfoBar

For persistent status messages (not toasts):

```xml
<InfoBar
    IsOpen="{x:Bind HasError}"
    Severity="Error"
    Title="Connection failed"
    Message="Check your network and try again."
    IsClosable="True" />
```

Severity values: `Informational`, `Success`, `Warning`, `Error`.

---

# Animation and Motion

## Timing Tokens

```csharp
public static class MotionDuration
{
    public static readonly TimeSpan Fast   = TimeSpan.FromMilliseconds(83);
    public static readonly TimeSpan Normal = TimeSpan.FromMilliseconds(167);
    public static readonly TimeSpan Slow   = TimeSpan.FromMilliseconds(333);
}
```

## Page Transitions

```xml
<!-- EntranceNavigationTransitionInfo for standard forward navigation -->
ContentFrame.Navigate(typeof(HomePage),
    null,
    new EntranceNavigationTransitionInfo());

<!-- DrillInNavigationTransitionInfo for drill-down -->
ContentFrame.Navigate(typeof(DetailPage),
    item,
    new DrillInNavigationTransitionInfo());

<!-- SlideNavigationTransitionInfo for lateral navigation -->
ContentFrame.Navigate(typeof(NextPage),
    null,
    new SlideNavigationTransitionInfo
    {
        Effect = SlideNavigationTransitionEffect.FromRight
    });
```

## Connected Animations (Shared Element Transitions)

```csharp
// Source: prepare the animation before navigation
ConnectedAnimationService.GetForCurrentView()
    .PrepareToAnimate("itemThumbnail", SourceImage);

ContentFrame.Navigate(typeof(DetailPage), item);

// Destination: start the animation after navigation
protected override void OnNavigatedTo(NavigationEventArgs e)
{
    base.OnNavigatedTo(e);
    var animation = ConnectedAnimationService.GetForCurrentView()
        .GetAnimation("itemThumbnail");
    animation?.TryStart(TargetImage);
}
```

## Implicit Animations

```csharp
// Fade + slide in on element load
var visual = ElementCompositionPreview.GetElementVisual(MyElement);
var compositor = visual.Compositor;

var fadeIn = compositor.CreateScalarKeyFrameAnimation();
fadeIn.InsertKeyFrame(0f, 0f);
fadeIn.InsertKeyFrame(1f, 1f);
fadeIn.Duration = MotionDuration.Normal;
fadeIn.Target = "Opacity";

var slideIn = compositor.CreateVector3KeyFrameAnimation();
slideIn.InsertKeyFrame(0f, new Vector3(0, 20, 0));
slideIn.InsertKeyFrame(1f, new Vector3(0, 0, 0));
slideIn.Duration = MotionDuration.Normal;
slideIn.Target = "Offset";

var group = compositor.CreateAnimationGroup();
group.Add(fadeIn);
group.Add(slideIn);

ElementCompositionPreview.SetImplicitShowAnimation(MyElement, group);
```

## Respect Reduced Motion

```csharp
var uiSettings = new UISettings();
if (!uiSettings.AnimationsEnabled)
{
    // Skip animations, use instant state changes
    return;
}
```

---

# Layout and Responsive Design

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

## DPI Scaling

WinUI 3 scales automatically. All XAML values are device-independent pixels. Never hardcode pixel values assuming 96 DPI. Test at 100%, 125%, 150%, 175%, and 200% scaling.

---

# Data Binding

Use compiled bindings (`x:Bind`) over classic bindings (`Binding`) for all new code. They're type-safe, faster, and caught at compile time.

```xml
<!-- x:Bind (preferred) -->
<TextBlock Text="{x:Bind ViewModel.Title}" />
<TextBlock Text="{x:Bind ViewModel.Title, Mode=OneWay}" />
<Button Command="{x:Bind ViewModel.SaveCommand}" />

<!-- Binding (legacy, avoid for new code) -->
<TextBlock Text="{Binding Title}" />
```

## INotifyPropertyChanged

```csharp
// Use CommunityToolkit.Mvvm for clean MVVM
using CommunityToolkit.Mvvm.ComponentModel;

public partial class MainViewModel : ObservableObject
{
    [ObservableProperty]
    private string title = string.Empty;

    [ObservableProperty]
    private bool isLoading;

    [RelayCommand]
    private async Task LoadDataAsync()
    {
        IsLoading = true;
        try
        {
            Title = await _service.GetTitleAsync();
        }
        finally
        {
            IsLoading = false;
        }
    }
}
```

---

# Accessibility

## Minimum Requirements

Touch targets: 40x40px minimum on all interactive elements.

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

High Contrast mode: all semantic brushes adapt automatically. Test with a contrast theme enabled (Settings > Accessibility > Contrast themes). If any element becomes unreadable, a hardcoded color is the cause.

Screen reader (Narrator) live regions for dynamic content:

```xml
<TextBlock
    AutomationProperties.LiveSetting="Polite"
    Text="{x:Bind StatusMessage}" />
```

---

# Testing

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

## Accessibility

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

---

# Performance

Use `ListView` or `GridView` for any list with more than a handful of items. Never a `StackPanel` with a loop for data-bound lists. WinUI's `ItemsRepeater` is the most flexible option for custom layouts.

Load data asynchronously. Never block the UI thread.

```csharp
// Correct async pattern
private async void Page_Loaded(object sender, RoutedEventArgs e)
{
    await ViewModel.LoadDataAsync();
}
```

Use `x:Load` for heavy UI that isn't always visible:

```xml
<!-- Only loaded when IsVisible becomes true -->
<Grid x:Load="{x:Bind IsDetailVisible, Mode=OneWay}">
    <HeavyDetailView />
</Grid>
```

Defer non-critical initialization:

```csharp
_ = Task.Run(async () =>
{
    await Task.Delay(500); // Let the window render first
    await DispatcherQueue.EnqueueAsync(InitializeSecondaryContent);
});
```

---

# Anti-Patterns

**Hardcoded colors.** `Colors.White`, `Colors.Black`, any hex value in XAML. Use semantic brushes.

**Acrylic on persistent surfaces.** Mica is for windows. Acrylic is for menus and flyouts. Swapping them produces wrong visual hierarchy and a performance hit.

**Classic `Binding` on new code.** Use `x:Bind`. Type-safe, faster, compile-time errors.

**StackPanel for data-bound lists.** Use ListView/GridView/ItemsRepeater. StackPanel with a loop creates all items immediately with no virtualization.

**Ignoring DPI scaling.** Any hardcoded pixel math that bakes in 96 DPI is broken on HiDPI displays.

**Not testing at compact window size.** A Windows 11 app is resizable. NavigationView's compact mode must work. Test below 800px wide.

**Missing XamlRoot on dialogs.** ContentDialog requires `XamlRoot = this.XamlRoot` in WinUI 3. Omitting it throws at runtime.

**Blocking the UI thread.** Never `Task.Wait()`, `.Result`, or synchronous I/O on the UI thread. Always `await`.

**Skipping Narrator testing.** High Contrast and Narrator testing catch accessibility failures that visual review misses entirely.

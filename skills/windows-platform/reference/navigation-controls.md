# Navigation & Controls

## Contents

- [NavigationView](#navigationview)
- [Title Bar](#title-bar)
- [TabView](#tabview)
- [Buttons](#buttons)
- [Text Input](#text-input)
- [Selection Controls](#selection-controls)
- [Lists](#lists)
- [Cards](#cards)
- [Dialogs and Flyouts](#dialogs-and-flyouts)
- [InfoBar](#infobar)

## NavigationView

The primary navigation pattern. Adaptive across three modes automatically based on window width (default thresholds, confirmed current):
- Expanded (1008px+): full sidebar with labels
- Compact (641-1007px): icon-only sidebar
- Minimal (below 641px): hamburger overlay

These are `NavigationView.ExpandedModeThresholdWidth` (default 1008) and `CompactModeThresholdWidth` (default 641) -- customizable, but keep any custom `AdaptiveTrigger` breakpoints elsewhere in the app aligned with whatever you set here.

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
    XamlRoot = this.XamlRoot  // Required in WinUI
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

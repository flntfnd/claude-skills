# Performance & Anti-Patterns

## Performance

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

## Anti-Patterns

**Hardcoded colors.** `Colors.White`, `Colors.Black`, any hex value in XAML. Use semantic brushes.

**Acrylic on persistent surfaces.** Mica is for windows. Acrylic is for menus and flyouts. Swapping them produces wrong visual hierarchy and a performance hit.

**Classic `Binding` on new code.** Use `x:Bind`. Type-safe, faster, compile-time errors.

**StackPanel for data-bound lists.** Use ListView/GridView/ItemsRepeater. StackPanel with a loop creates all items immediately with no virtualization.

**Ignoring DPI scaling.** Any hardcoded pixel math that bakes in 96 DPI is broken on HiDPI displays.

**Not testing at compact window size.** A Windows 11 app is resizable. NavigationView's compact mode must work. Test below 800px wide.

**Missing XamlRoot on dialogs.** ContentDialog requires `XamlRoot = this.XamlRoot`. Omitting it throws at runtime.

**Blocking the UI thread.** Never `Task.Wait()`, `.Result`, or synchronous I/O on the UI thread. Always `await`.

**Skipping Narrator testing.** High Contrast and Narrator testing catch accessibility failures that visual review misses entirely.

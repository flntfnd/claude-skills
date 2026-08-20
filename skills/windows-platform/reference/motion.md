# Motion

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

```csharp
// EntranceNavigationTransitionInfo for standard forward navigation
ContentFrame.Navigate(typeof(HomePage),
    null,
    new EntranceNavigationTransitionInfo());

// DrillInNavigationTransitionInfo for drill-down
ContentFrame.Navigate(typeof(DetailPage),
    item,
    new DrillInNavigationTransitionInfo());

// SlideNavigationTransitionInfo for lateral navigation
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

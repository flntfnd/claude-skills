# Custom Rendering

Advanced visual techniques for WinUI that go beyond standard controls.

## Contents

- [Composition API (Advanced)](#composition-api-advanced)
- [Win2D (Custom 2D Drawing)](#win2d-custom-2d-drawing)
- [Pointer Input Differentiation](#pointer-input-differentiation)

## Composition API (Advanced)

The Composition API runs directly on the compositor thread -- zero XAML layout involvement, maximum smoothness.

```csharp
// Expression animations: animate a property as a mathematical function of another
var visual = ElementCompositionPreview.GetElementVisual(element);
var compositor = visual.Compositor;

// Parallax: element moves at 0.3x the scroll speed
var scrollViewer = MyScrollViewer;
var scrollProps = ElementCompositionPreview.GetScrollViewerManipulationPropertySet(scrollViewer);

var parallaxExpression = compositor.CreateExpressionAnimation(
    "ScrollProps.Translation.Y * -0.3"
);
parallaxExpression.SetReferenceParameter("ScrollProps", scrollProps);
visual.StartAnimation("Offset.Y", parallaxExpression);

// Opacity tied to scroll position (fade on scroll)
var fadeExpression = compositor.CreateExpressionAnimation(
    "Clamp(1.0 - ScrollProps.Translation.Y / -200.0, 0.0, 1.0)"
);
fadeExpression.SetReferenceParameter("ScrollProps", scrollProps);
visual.StartAnimation("Opacity", fadeExpression);
```

InteractionTracker for custom gesture-driven animations:

```csharp
// Custom swipe gesture with physics
var tracker = InteractionTracker.CreateWithOwner(compositor, this);
var source = VisualInteractionSource.Create(rootVisual);
source.PositionXSourceMode = InteractionSourceMode.EnabledWithInertia;
tracker.InteractionSources.Add(source);

// Bind element position to tracker
var expression = compositor.CreateExpressionAnimation("tracker.Position.X * -1");
expression.SetReferenceParameter("tracker", tracker);
contentVisual.StartAnimation("Offset.X", expression);
```

Spring physics on release:

```csharp
var springConfig = compositor.CreateSpringScalarAnimation();
springConfig.Period = TimeSpan.FromMilliseconds(300);
springConfig.DampingRatio = 0.6f;
springConfig.FinalValue = 0f;

// Trigger after gesture ends (IInteractionTrackerOwner.RequestIgnored callback)
contentVisual.StartAnimation("Offset.X", springConfig);
```

`[Unverified]` A Limited Access Feature called the CompositionEngine API shipped in Windows App SDK 2.3.1 (July 2026), letting an app hand Composition API execution to the OS compositor engine directly. It's gated behind Microsoft approval for production use, so it doesn't change the `ElementCompositionPreview`-based patterns above for typical app code -- confirm against current Windows App SDK docs before assuming it applies to a given project.

## Win2D (Custom 2D Drawing)

Win2D is the Windows equivalent of Canvas/Core Graphics -- hardware-accelerated 2D drawing that integrates with the Composition API. Package: `Microsoft.Graphics.Win2D`.

```xml
<!-- XAML -->
<canvas:CanvasControl
    x:Name="DrawingCanvas"
    Draw="DrawingCanvas_Draw"
    CreateResources="DrawingCanvas_CreateResources" />
```

```csharp
// Code-behind
using Microsoft.Graphics.Canvas;
using Microsoft.Graphics.Canvas.Effects;
using Microsoft.Graphics.Canvas.Geometry;
using Windows.UI;

private void DrawingCanvas_Draw(CanvasControl sender, CanvasDrawEventArgs args) {
    var ds = args.DrawingSession;

    // Animated waveform
    var path = new CanvasPathBuilder(sender);
    path.BeginFigure(0, (float)sender.ActualHeight / 2);

    for (int x = 0; x < sender.ActualWidth; x += 2) {
        float t = (float)x / (float)sender.ActualWidth;
        float y = (float)sender.ActualHeight / 2
                  + (float)(Math.Sin(t * Math.PI * 6 + animPhase) * 30);
        path.AddLine(x, y);
    }
    path.EndFigure(CanvasFigureLoop.Open);

    ds.DrawGeometry(
        CanvasGeometry.CreatePath(path),
        Colors.Cyan,
        strokeWidth: 2f
    );
}

// Custom blur effect for glass surfaces
private void DrawGlassEffect(CanvasDrawingSession ds, CanvasRenderTarget content) {
    var blurEffect = new GaussianBlurEffect {
        Source = content,
        BlurAmount = 16f,
        BorderMode = EffectBorderMode.Hard
    };

    var saturationEffect = new SaturationEffect {
        Source = blurEffect,
        Saturation = 1.4f
    };

    ds.DrawImage(saturationEffect);
}
```

Procedural noise texture (for Texture/Tactile style):

```csharp
var turbulence = new TurbulenceEffect {
    Frequency = new Vector2(0.025f, 0.025f),
    Octaves = 4,
    Lacunarity = 2.0f,
    Size = new Vector2((float)sender.ActualWidth, (float)sender.ActualHeight)
};

var colorMatrix = new ColorMatrixEffect {
    Source = turbulence,
    ColorMatrix = new Matrix5x4 {
        // Map to monochrome noise at low opacity
        M11 = 0, M12 = 0, M13 = 0, M14 = 0.04f,
        M21 = 0, M22 = 0, M23 = 0, M24 = 0.04f,
        M31 = 0, M32 = 0, M33 = 0, M34 = 0.04f,
        M41 = 0, M42 = 0, M43 = 0, M44 = 0,
        M51 = 0, M52 = 0, M53 = 0, M54 = 1
    }
};

ds.DrawImage(colorMatrix, CanvasImageInterpolation.Linear);
```

## Pointer Input Differentiation

Windows has three distinct input modalities. A well-crafted app handles each correctly.

```csharp
element.PointerEntered += (s, e) => {
    var point = e.GetCurrentPoint(s as UIElement);

    switch (point.PointerDevice.PointerDeviceType) {
        case PointerDeviceType.Mouse:
            // Hover states, fine cursor control
            ShowHoverState();
            break;
        case PointerDeviceType.Touch:
            // Larger touch targets, no hover state
            // Touch doesn't have hover -- skip hover effects
            break;
        case PointerDeviceType.Pen:
            // Pen may have pressure/tilt data
            var pressure = point.Properties.Pressure;  // 0.0 to 1.0
            var tiltX = point.Properties.XTilt;
            var tiltY = point.Properties.YTilt;
            ShowPenState(pressure);
            break;
    }
};
```

Custom cursor per context:

```csharp
// Change cursor based on context
element.PointerEntered += (s, e) => {
    if (e.Pointer.PointerDeviceType == PointerDeviceType.Mouse) {
        Window.Current.CoreWindow.PointerCursor =
            new CoreCursor(CoreCursorType.Hand, 0);
    }
};
element.PointerExited += (s, e) => {
    Window.Current.CoreWindow.PointerCursor =
        new CoreCursor(CoreCursorType.Arrow, 0);
};
```

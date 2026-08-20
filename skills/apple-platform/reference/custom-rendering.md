# Custom Rendering

What separates native iOS apps that feel hand-crafted from ones that feel assembled from stock components. Use these APIs when standard SwiftUI views can't achieve the visual result needed.

## Contents

- [SwiftUI Canvas](#swiftui-canvas)
- [Custom Animatable Conformances](#custom-animatable-conformances)
- [Advanced AttributedString Typography](#advanced-attributedstring-typography)
- [Metal for Custom Effects](#metal-for-custom-effects)

## SwiftUI Canvas

Direct 2D drawing within the SwiftUI layout system. Same performance as `drawRect` without the UIKit overhead.

```swift
// Generative waveform (audio player, visualizer)
Canvas { context, size in
    let midY = size.height / 2
    let samples: [Float] = audioEngine.currentSamples  // [0...1]

    var path = Path()
    path.move(to: CGPoint(x: 0, y: midY))

    for (i, sample) in samples.enumerated() {
        let x = size.width * CGFloat(i) / CGFloat(samples.count)
        let y = midY - CGFloat(sample) * midY * 0.9
        path.addLine(to: CGPoint(x: x, y: y))
    }

    context.stroke(
        path,
        with: .linearGradient(
            Gradient(colors: [.cyan, .purple]),
            startPoint: .zero,
            endPoint: CGPoint(x: size.width, y: 0)
        ),
        lineWidth: 1.5
    )
}
.frame(height: 80)

// Animated noise / organic background
Canvas { context, size in
    // Use TimelineView for animated Canvas
    // (wrap Canvas in TimelineView for time-driven updates)
}.drawingGroup()  // Rasterizes to a single layer -- use for complex paths
```

TimelineView drives Canvas animation:

```swift
TimelineView(.animation) { timeline in
    let time = timeline.date.timeIntervalSinceReferenceDate
    Canvas { context, size in
        // Use `time` to drive animated shapes
        let phase = time * 2.0
        let cx = size.width / 2
        let cy = size.height / 2

        for i in 0..<6 {
            let angle = Double(i) / 6 * .pi * 2 + phase * 0.3
            let r = 40.0 + sin(phase + Double(i)) * 15
            let x = cx + cos(angle) * r
            let y = cy + sin(angle) * r

            var circle = Path()
            circle.addEllipse(in: CGRect(x: x - 6, y: y - 6, width: 12, height: 12))
            context.fill(circle, with: .color(.cyan.opacity(0.7)))
        }
    }
}
```

## Custom Animatable Conformances

Make any value type animatable to drive custom visual states:

```swift
struct WaveShape: Shape, Animatable {
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase: CGFloat

    // Animatable requires a single animatableData value
    // Use AnimatablePair for multiple values
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(amplitude, phase) }
        set {
            amplitude = newValue.first
            phase = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step: CGFloat = 2

        path.move(to: CGPoint(x: 0, y: rect.midY))
        for x in stride(from: 0, to: rect.width, by: step) {
            let relativeX = x / rect.width
            let y = rect.midY + sin(relativeX * frequency * .pi * 2 + phase) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        return path
    }
}

// Usage
WaveShape(amplitude: isActive ? 20 : 0, frequency: 3, phase: currentPhase)
    .stroke(Color.cyan, lineWidth: 2)
    .animation(.spring(response: 0.5), value: isActive)
```

## Advanced AttributedString Typography

Rich inline typography without UIKit:

```swift
// Mixed weight / color inline text
var attributed = AttributedString("Design")
attributed.font = .system(size: 48, weight: .bold)

var accent = AttributedString(" system.")
accent.font = .system(size: 48, weight: .light, design: .serif)
accent.foregroundColor = .secondary

let combined = attributed + accent

Text(combined)
    .tracking(1.2)

// Animated text with per-character styling
extension String {
    func staggeredAttributedString(colors: [Color]) -> AttributedString {
        var result = AttributedString()
        for (i, char) in self.enumerated() {
            var segment = AttributedString(String(char))
            segment.foregroundColor = colors[i % colors.count]
            result.append(segment)
        }
        return result
    }
}
```

## Metal for Custom Effects

Use when SwiftUI filters and Canvas aren't enough -- custom blur algorithms, color effects, particle systems at scale. The SwiftUI bridge via `MetalView` (iOS 17+):

```swift
// Minimal Metal setup for custom fragment shader effect
import MetalKit

struct MetalShaderView: UIViewRepresentable {
    var fragmentShaderName: String
    var uniforms: ShaderUniforms  // Your custom struct

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.delegate = context.coordinator
        view.clearColor = MTLClearColorMake(0, 0, 0, 0)
        view.isOpaque = false
        return view
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
```

For most visual effects, prefer SwiftUI's built-in `.colorEffect()`, `.layerEffect()`, and `.distortionEffect()` modifiers over raw Metal -- they're safe, sandboxed, and far less code:

```swift
// Custom color transformation via shader (iOS 17+)
// Write a .metal file with the matching function signature
.colorEffect(ShaderLibrary.myColorShader(
    .float(time),
    .float(intensity)
))

// Custom geometry distortion
.distortionEffect(ShaderLibrary.waveDistortion(
    .float(time),
    .float(amplitude)
), maxSampleOffset: CGSize(width: 20, height: 20))
```

Performance notes for Canvas, Metal, and shader-driven views live in `liquid-glass.md` under Performance -- the same GPU/thermal budget concerns apply to any continuous custom rendering, not just glass.

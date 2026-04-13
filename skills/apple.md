# Design System
iOS 26 / iPadOS 26 / macOS Tahoe 26+
SwiftUI only. No UIKit unless explicitly required.

---

# Philosophy
Liquid Glass is a navigation-layer material. It floats above content. It does not touch content.

Three layers, in order:
1. Content (bottom): lists, media, text, cards. No glass.
2. Navigation (middle): toolbars, tab bars, sidebars, floating controls. Liquid Glass lives here.
3. Overlay (top): vibrancy, fills, and text rendered on glass surfaces.

If you're applying glass to content, you're doing it wrong.

---

# Liquid Glass

## Material Variants

`.regular` is the default. Use it for all navigation-layer controls. Medium transparency, fully adaptive to whatever is behind it.

`.clear` is for floating controls over media-rich backgrounds only. High transparency with limited adaptivity. Three conditions must all be true before using it: the element sits over media-rich content, the content won't be harmed by a dimming layer, and the foreground content is bold and bright. If any condition fails, use `.regular`.

`.identity` disables the effect entirely. Use it for conditional toggling without triggering layout recalculation.

## Core API

```swift
// Default
.glassEffect()

// Explicit
.glassEffect(.regular, in: .capsule, isEnabled: true)

// Tinted (semantic meaning only, not decoration)
.glassEffect(.regular.tint(.blue))

// Interactive (iOS only: scales, bounces, shimmers, illuminates on touch)
.glassEffect(.regular.interactive())

// Chain them
.glassEffect(.regular.tint(.orange).interactive())
```

## Glass Types

```swift
struct Glass {
    static var regular: Glass
    static var clear: Glass
    static var identity: Glass

    func tint(_ color: Color) -> Glass
    func interactive() -> Glass
}
```

Tinting is for semantic meaning (primary action, active state). Not decoration. Use it selectively.

## Shapes

```swift
.glassEffect(.regular, in: .capsule)                              // default
.glassEffect(.regular, in: .circle)
.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
.glassEffect(.regular, in: .rect(cornerRadius: .containerConcentric))
```

Use `.containerConcentric` when a glass element needs to align with its container or window corners. It adjusts automatically across device sizes.

## GlassEffectContainer

Multiple glass elements must live inside a `GlassEffectContainer`. Without it, each element samples the background independently, which is both visually inconsistent and a performance hit.

```swift
GlassEffectContainer(spacing: 20) {
    // Glass elements here blend together when within 20pt of each other
    Button("Edit") { }.glassEffect()
    Button("Delete") { }.glassEffect()
}
```

The `spacing` parameter controls morphing threshold. Elements within that distance visually merge.

## Glass Levels

```swift
enum GlassLevel {
    case chrome   // toolbars, floating controls
    case surface  // cards, panels
    case element  // buttons, chips, pills
}
```

Define these in your token system and apply consistently. Don't mix chrome-level glass with element-level glass in the same container without intentional reason.

## Token Reference

```swift
enum GlassTokens {
    enum Radius {
        static let card: CGFloat = 28
        static let pill: CGFloat = 999
        static let sheet: CGFloat = 34
    }
    enum Padding {
        static let card = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let pill = EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)
        static let iconButton: CGFloat = 12
    }
    enum Stroke {
        static let width: CGFloat = 1
        static let subtleOpacity: Double = 0.22
        static let strongOpacity: Double = 0.35
    }
    enum Shadow {
        static let radius: CGFloat = 18
        static let y: CGFloat = 8
        static let opacity: Double = 0.18
    }
}
```

## Morphing

Morphing requires: elements in the same `GlassEffectContainer`, unique `glassEffectID` per element in a shared namespace, and an animation applied to state changes.

```swift
@Namespace private var namespace

GlassEffectContainer(spacing: 30) {
    Button(isExpanded ? "Collapse" : "Expand") {
        withAnimation(.bouncy) { isExpanded.toggle() }
    }
    .glassEffect()
    .glassEffectID("toggle", in: namespace)

    if isExpanded {
        Button("Action") { }
            .glassEffect()
            .glassEffectID("action", in: namespace)
    }
}
```

## Button Styles

```swift
Button("Secondary") { }.buttonStyle(.glass)
Button("Primary") { }.buttonStyle(.glassProminent).tint(.blue)
```

`.glass` is translucent. `.glassProminent` is opaque with no background show-through. Use `.glassProminent` for one primary action per screen. Not multiple.

```swift
// Known rendering artifact workaround
Button("Circle Action") { }
    .buttonStyle(.glassProminent)
    .buttonBorderShape(.circle)
    .clipShape(Circle())
```

## Dynamic Adaptation

Glass adapts automatically between light and dark based on what's behind it. Small elements (nav bars, tab bars) flip. Large elements (sidebars) adapt without flipping. Don't override this behavior.

---

# Color Tokens

## Semantic System Colors

Use these everywhere. They adapt automatically to light, dark, high contrast, and increased contrast modes.

```swift
// Backgrounds
Color(.systemBackground)           // primary surface
Color(.secondarySystemBackground)  // secondary surface
Color(.tertiarySystemBackground)   // tertiary surface
Color(.systemGroupedBackground)    // grouped list backgrounds

// Labels
Color(.label)                      // primary text
Color(.secondaryLabel)             // secondary text
Color(.tertiaryLabel)              // placeholder, hints
Color(.quaternaryLabel)            // disabled

// Fills
Color(.systemFill)
Color(.secondarySystemFill)
Color(.tertiarySystemFill)
Color(.quaternarySystemFill)

// Separators
Color(.separator)
Color(.opaqueSeparator)
```

## Custom Semantic Tokens

Define all custom colors as semantic tokens. Never hardcode hex values in views.

```swift
extension DesignSystem {
    enum Color {
        enum Background {
            case primary, secondary, elevated

            var color: SwiftUI.Color {
                switch self {
                case .primary:
                    SwiftUI.Color(
                        dark: SwiftUI.Color(uiColor: UIColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1)),  // #1A1A1E
                        light: SwiftUI.Color(uiColor: UIColor(red: 0.96, green: 0.95, blue: 0.93, alpha: 1))  // #F5F3EE
                    )
                case .secondary:
                    SwiftUI.Color(
                        dark: SwiftUI.Color(uiColor: UIColor(red: 0.15, green: 0.15, blue: 0.17, alpha: 1)),  // #26262B
                        light: SwiftUI.Color(uiColor: UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 1))  // #FFFFFF
                    )
                case .elevated:
                    SwiftUI.Color(
                        dark: SwiftUI.Color(uiColor: UIColor(red: 0.18, green: 0.18, blue: 0.20, alpha: 1)),  // #2E2E33
                        light: SwiftUI.Color(uiColor: UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1))  // #F7F7FA
                    )
                }
            }
        }
    }
}
```

## Contrast Requirements

- Normal text: 4.5:1 minimum contrast ratio (WCAG AA)
- Large text (18pt+ regular, 14pt+ bold): 3:1 minimum
- Interactive elements: 3:1 against adjacent colors

Test in both appearances. Test with Increased Contrast enabled. Test with color blindness simulators.

## Display P3

Use Display P3 color space for richer colors on capable devices. Test on sRGB devices too since P3 colors can look muted there.

---

# Typography

## Scale

All type uses the system font (SF Pro on iOS/iPadOS/macOS) unless a custom typeface is explicitly designed in. Dynamic Type must be supported.

```swift
// Semantic scale
.font(.largeTitle)   // 34pt regular
.font(.title)        // 28pt regular
.font(.title2)       // 22pt regular
.font(.title3)       // 20pt regular
.font(.headline)     // 17pt semibold
.font(.body)         // 17pt regular (base)
.font(.callout)      // 16pt regular
.font(.subheadline)  // 15pt regular
.font(.footnote)     // 13pt regular
.font(.caption)      // 12pt regular
.font(.caption2)     // 11pt regular
```

Use semantic sizes. Never hardcode point values. If you need a custom size, define it as a token.

```swift
enum Typography {
    static let displayLarge = Font.system(size: 40, weight: .bold, design: .default)
    static let displaySmall = Font.system(size: 32, weight: .semibold, design: .default)
    // etc.
}
```

## Rendering on Glass

Text on glass gets automatic vibrant treatment from the system. Don't fight it. Use `.foregroundStyle(.primary)` or `.foregroundStyle(.white)` depending on the context. Let vibrancy handle the legibility adjustment.

---

# Spacing Tokens

Define spacing as a finite set. Nothing outside the scale.

```swift
enum Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let base: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
    static let section: CGFloat = 64
}
```

Touch targets: minimum 44x44pt per HIG. Non-negotiable.

---

# Animation and Motion

## Core Principle

Motion communicates. It orients, confirms, and guides. It doesn't decorate.

Every animation answers one of these questions:
- Where did that go?
- What just happened?
- What can I do next?

If it doesn't answer any of those, cut it.

## Animation Tokens

Define all timing as tokens. No magic values in views.

```swift
enum Motion {
    // Durations
    enum Duration {
        static let instant: Double = 0.10
        static let fast: Double = 0.20
        static let standard: Double = 0.30
        static let slow: Double = 0.45
        static let deliberate: Double = 0.60
    }

    // Spring presets (physics-based, preferred over ease curves for interactive elements)
    enum Spring {
        static let snappy = SwiftUI.Animation.spring(response: 0.25, dampingFraction: 0.8)
        static let bouncy = SwiftUI.Animation.bouncy(duration: 0.35)
        static let smooth = SwiftUI.Animation.spring(response: 0.45, dampingFraction: 0.9)
        static let gentle = SwiftUI.Animation.spring(response: 0.60, dampingFraction: 0.95)
    }

    // Ease curves (for non-interactive transitions)
    enum Ease {
        static let enter = SwiftUI.Animation.easeOut(duration: Duration.standard)
        static let exit = SwiftUI.Animation.easeIn(duration: Duration.fast)
        static let inOut = SwiftUI.Animation.easeInOut(duration: Duration.standard)
    }
}
```

## HIG Motion Rules

Use spring animations for interactive elements. Users expect physics on things they touch.

Use ease-out for elements entering the screen. Ease-in for elements leaving. This matches real-world physics: things slow as they arrive, accelerate as they leave.

Ideal duration range for most UI: 100ms to 500ms. Anything slower than 500ms starts to feel sluggish. Anything under 100ms is imperceptible.

Animation speed matters. Match direction to spatial relationships: if a view slides in from the right, it dismisses to the right.

Always respect `accessibilityReduceMotion`. Replace motion with opacity when the setting is on.

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var transition: AnyTransition {
    reduceMotion ? .opacity : .move(edge: .trailing).combined(with: .opacity)
}
```

## Liquid Glass Motion

Liquid Glass has its own physics built in. `.glassEffect(.regular.interactive())` adds: scale on press, bounce animation, shimmer, and touch-point illumination. Don't fight or override these behaviors with custom animations layered on top.

For morphing transitions, `.bouncy` is Apple's recommended animation:

```swift
withAnimation(.bouncy(duration: 0.35)) {
    isExpanded.toggle()
}
```

## Symbol Effects

```swift
// State toggle
.contentTransition(.symbolEffect(.replace))

// Number changes
.contentTransition(.numericText())

// Automatic
.contentTransition(.symbolEffect(.automatic))
```

## Materialization

Elements appear and disappear by modulating light bending, not by popping in from nowhere. Match this behavior in custom transitions: use opacity combined with scale, not hard cuts.

---

# Navigation

## iOS

Tab bar collapses on scroll down, expands on scroll up. This is automatic with `.tabBarMinimizeBehavior(.onScrollDown)`.

Search gets a dedicated tab role that places a floating button at bottom-right for reachability:

```swift
Tab("Search", systemImage: "magnifyingglass", role: .search) {
    SearchView()
}
```

Navigation is push-based. Sheets are modal and inset in iOS 26 with automatic glass backgrounds. Don't apply custom `presentationBackground` -- let the system handle it.

## iPadOS

Sidebar navigation. Floating glass sidebar with ambient reflection. Use `NavigationSplitView` and let the system apply the sidebar glass treatment.

```swift
NavigationSplitView {
    List(items) { item in
        NavigationLink(item.name, value: item)
    }
    .backgroundExtensionEffect()
} detail: {
    DetailView()
}
```

Stage Manager is a real use case on iPad. Don't assume full-screen layout.

## macOS

Concentric corner radius: window corners and contained elements must align. Use `.rect(cornerRadius: .containerConcentric)`.

Sidebar is persistent and ambient-reflective. Menu bar is transparent in macOS Tahoe 26. Design the toolbar for the new floating toolbar pattern, not the old attached toolbar.

---

# Interaction

## Gestures

Swipe to go back is a system behavior. Never remove or interfere with it.

Drag gestures on interactive glass elements should use spring return:

```swift
.gesture(
    DragGesture()
        .onChanged { value in offset = value.translation }
        .onEnded { _ in
            withAnimation(Motion.Spring.snappy) { offset = .zero }
        }
)
```

## Haptics

Use system haptic feedback for confirmations, errors, and selection changes. Never custom-implement haptics when a system pattern exists.

```swift
// Selection
let selectionFeedback = UISelectionFeedbackGenerator()
selectionFeedback.selectionChanged()

// Impact
let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
impactFeedback.impactOccurred()

// Notification
let notificationFeedback = UINotificationFeedbackGenerator()
notificationFeedback.notificationOccurred(.success)
```

## State Changes

Never cut between states. Every state transition is animated. The animation style matches the weight of the change: snappy for small state toggles, smooth for significant layout changes, bouncy for expanding/collapsing glass elements.

---

# Layering Anti-Patterns

These are common mistakes. Don't make them.

Glass on glass: applying glass to elements that already sit on a glass surface. Creates visual noise and breaks depth hierarchy.

Glass on content: applying glass effects to list rows, cards, media. Glass belongs on the navigation layer.

Overuse: applying glass to every surface because it looks cool. It stops looking like depth and starts looking like a mess.

Tinting everything: tint is for semantic meaning. If everything is tinted, nothing is.

Hardcoded animation values: magic numbers in `.animation(.spring(response: 0.3, dampingFraction: 0.6))` scattered throughout views. All values go in `Motion` tokens.

Text on top of other text: floating glass controls positioned over content text create a legibility collision. iOS 26's native apps have been criticised for this. If a glass control overlaps readable content, either move the control or add a scrim layer between them.

Motion overload: the glass material has its own built-in physics. Adding further scroll animations, parallax, and shimmer effects on top creates an interface that feels restless and competes for attention with the content it's supposed to serve.

---

# Accessibility

The system handles a lot automatically. Don't fight it.

Reduced Transparency: system increases frosting for clarity. Glass falls back gracefully.
Increased Contrast: system adds stark colors, borders, and higher-contrast backgrounds to glass elements.
Reduced Motion: minimize or eliminate animations. Use opacity transitions. Liquid Glass disables elastic interactions automatically.
Dynamic Type: all text must scale. No fixed-height containers that truncate text.
VoiceOver: all interactive elements need accessibility labels. Glass buttons need explicit labels.
Touch targets: 44x44pt minimum. Always. Do not reduce tap areas to fit a visually tighter glass composition.

The three system adaptations above fire automatically when users enable them. Always test with each one active. The reduced transparency fallback is the most commonly missed -- your glass UI must still communicate hierarchy and depth without the translucency effect.

```swift
@Environment(\.accessibilityReduceTransparency) var reduceTransparency

.glassEffect(reduceTransparency ? .identity : .regular)
```

Contrast ratios:
- Normal text: 4.5:1
- Large text: 3:1
- Interactive elements: 3:1

These ratios must be verified **with the glass blur applied** against the actual content behind the glass, not against the glass fill color alone. The blur can significantly reduce effective contrast depending on what's beneath it -- test against the worst-case background your content will appear over.

---

# Appearance Modes

## Light Mode
- Background primary: #F5F3EE (warm off-white)
- Background secondary: #FFFFFF
- Background elevated: #F7F7FA
- Label primary: #000000
- Label secondary: rgba(0,0,0,0.55)
- Separator: rgba(0,0,0,0.20)

## Dark Mode
- Background primary: #1A1A1E (warm near-black)
- Background secondary: #26262B
- Background elevated: #2E2E33
- Label primary: #FFFFFF
- Label secondary: rgba(255,255,255,0.55)
- Separator: rgba(255,255,255,0.15)

Both modes must be tested and designed for. Dark mode is not an afterthought.

Design for true dark first. If it works in dark, it almost always works in light. The reverse isn't always true.

---

# Component Patterns

## Toolbar

Toolbars get Liquid Glass automatically when compiled with Xcode 26. `.confirmationAction` placement gets `.glassProminent` automatically. Don't override it.

```swift
.toolbar {
    ToolbarItem(placement: .cancellationAction) {
        Button("Cancel", systemImage: "xmark") { }
    }
    ToolbarItem(placement: .confirmationAction) {
        Button("Done", systemImage: "checkmark") { }
    }
}
```

## Floating Action

```swift
GlassEffectContainer(spacing: 16) {
    VStack(spacing: 12) {
        if isExpanded {
            ForEach(actions, id: \.id) { action in
                Button { } label: {
                    Image(systemName: action.icon)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .tint(action.color)
                .glassEffectID(action.id, in: namespace)
            }
        }
        Button {
            withAnimation(.bouncy(duration: 0.35)) { isExpanded.toggle() }
        } label: {
            Image(systemName: isExpanded ? "xmark" : "plus")
                .font(.title2.bold())
                .frame(width: 56, height: 56)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.circle)
        .tint(.blue)
        .glassEffectID("toggle", in: namespace)
    }
}
```

## Sheet

Sheets in iOS 26 get automatic inset glass backgrounds. Don't fight this.

```swift
.sheet(isPresented: $showSheet) {
    SheetContent()
        .presentationDetents([.medium, .large])
        .scrollContentBackground(.hidden)
}
```

## Sheet Morphing from Toolbar

```swift
Button("Info") { showInfo = true }
    .matchedTransitionSource(id: "info", in: transition)

.sheet(isPresented: $showInfo) {
    InfoSheet()
        .navigationTransition(.zoom(sourceID: "info", in: transition))
}
```

---

---

# Performance

Always use `GlassEffectContainer` for multiple glass elements. Shared sampling region. Better performance.

Use `.identity` for conditional glass toggling, not conditional view existence. No layout recalculation.

Don't run continuous animations on glass surfaces. Real-time lensing plus continuous animation is a thermal and battery problem on older hardware.

**Liquid Glass is GPU-intensive.** Apple's own developer guidance flags this explicitly. Do not apply the effect inside:
- Nested views (glass inside glass containers)
- High-frequency scrollable areas
- `List` or `LazyVStack` rows

Reserve Liquid Glass for static, top-level components: tab bars, toolbars, floating controls, sheets. Anything that's always visible and rarely redrawn. This is Apple's architectural intent -- Liquid Glass is a layout-layer decision, not a surface decoration applied everywhere. Apps in Apple's developer gallery that succeeded were the ones that moved navigation to the bottom, extended content behind glass chrome, and used standard system controls rather than custom-painted replacements.

Test on iPhone 11-13. If it runs well there, it runs well everywhere. Older devices fall back to frosted glass when the full lensing effect exceeds thermal budget -- this is expected behavior, not a bug to fix.

Profile with Instruments. Watch GPU usage and thermal state.

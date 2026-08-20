# Liquid Glass

Liquid Glass is a navigation-layer material introduced with iOS 26 / iPadOS 26 / macOS Tahoe 26. It floats above content and does not touch it. All API below targets that baseline (Xcode 26+). For what changes under the iOS 27 / macOS 27 "Golden Gate" SDK (currently in beta, see `whats-new-ios27.md`), including the removal of the compatibility opt-out, see the note at the bottom of this file.

## Contents

- [Material Variants](#material-variants)
- [Core API](#core-api)
- [Glass Types](#glass-types)
- [Shapes](#shapes)
- [GlassEffectContainer](#glasseffectcontainer)
- [Glass Levels](#glass-levels)
- [Token Reference](#token-reference)
- [Morphing](#morphing)
- [Button Styles](#button-styles)
- [Dynamic Adaptation](#dynamic-adaptation)
- [Layering Anti-Patterns](#layering-anti-patterns)
- [Performance](#performance)
- [iOS 27 note](#ios-27-note)

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

## Layering Anti-Patterns

These are common mistakes. Don't make them.

Glass on glass: applying glass to elements that already sit on a glass surface. Creates visual noise and breaks depth hierarchy.

Glass on content: applying glass effects to list rows, cards, media. Glass belongs on the navigation layer.

Overuse: applying glass to every surface because it looks cool. It stops looking like depth and starts looking like a mess.

Tinting everything: tint is for semantic meaning. If everything is tinted, nothing is.

Hardcoded animation values: magic numbers in `.animation(.spring(response: 0.3, dampingFraction: 0.6))` scattered throughout views. All values go in `Motion` tokens (see `motion-interaction.md`).

Text on top of other text: floating glass controls positioned over content text create a legibility collision. iOS 26's native apps have been criticised for this. If a glass control overlaps readable content, either move the control or add a scrim layer between them.

Motion overload: the glass material has its own built-in physics. Adding further scroll animations, parallax, and shimmer effects on top creates an interface that feels restless and competes for attention with the content it's supposed to serve.

## Performance

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

## iOS 27 note

Apps could opt out of Liquid Glass entirely on iOS 26 with the `UIDesignRequiresCompatibility` Info.plist key (set to `YES` to render the legacy pre-Liquid-Glass design). Apple always described this as temporary. `[Unverified]` Multiple developer-facing sources report that recompiling against the iOS 27 SDK makes Liquid Glass mandatory and the compatibility key stops working -- confirm against Apple's actual iOS 27 release notes before relying on this for a migration deadline. See `whats-new-ios27.md` for the full beta-status picture as of August 2026.

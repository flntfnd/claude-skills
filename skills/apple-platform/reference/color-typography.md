# Color, Typography, and Spacing

## Contents

- [Semantic System Colors](#semantic-system-colors)
- [Custom Semantic Tokens](#custom-semantic-tokens)
- [Contrast Requirements](#contrast-requirements)
- [Display P3](#display-p3)
- [Typography Scale](#typography-scale)
- [Rendering on Glass](#rendering-on-glass)
- [Spacing Tokens](#spacing-tokens)
- [Appearance Modes](#appearance-modes)

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

## Typography Scale

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

## Spacing Tokens

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

## Appearance Modes

### Light Mode
- Background primary: #F5F3EE (warm off-white)
- Background secondary: #FFFFFF
- Background elevated: #F7F7FA
- Label primary: #000000
- Label secondary: rgba(0,0,0,0.55)
- Separator: rgba(0,0,0,0.20)

### Dark Mode
- Background primary: #1A1A1E (warm near-black)
- Background secondary: #26262B
- Background elevated: #2E2E33
- Label primary: #FFFFFF
- Label secondary: rgba(255,255,255,0.55)
- Separator: rgba(255,255,255,0.15)

Both modes must be tested and designed for. Dark mode is not an afterthought.

Design for true dark first. If it works in dark, it almost always works in light. The reverse isn't always true.

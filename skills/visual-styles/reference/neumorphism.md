# Neumorphism / Soft UI

Soft extruded surfaces. Elements appear to emerge from or press into the background. Achieved through dual shadows: one light from upper-left, one dark from lower-right. Background and element colors match closely. The result is tactile and dimensional without explicit borders.

Pure neumorphism has evolved into **Claymorphism** -- the same dual-shadow approach but with an added inner glow that makes elements appear slightly inflated, like soft clay or silicone. This subtle addition improves perceived affordance without meaningfully impacting accessibility. Apply it selectively to high-touch interactive elements (buttons, toggles, knobs) rather than background surfaces.

**When to use**: Health and wellness, audio and music apps, any UI where a tactile, physical feel serves the content. Use sparingly -- it does not scale to information-dense layouts. Accessible neumorphism (Soft UI) maintains contrast standards; classic neumorphism does not.

## Contents
- [Visual Signature](#visual-signature)
- [Token Modifications](#token-modifications)
- [Component Rules](#component-rules)
- [Platform Implementation](#platform-implementation)

## Visual Signature

Identifiable at a glance by: everything is the SAME background color -- there are no borders, no background changes between sections, no surface hierarchy through color. Depth is created exclusively through dual shadows. Buttons look physically raised. Pressed/active states look physically pushed in (inset shadow). The whole interface is one tone, modulated only by shadow.

**Structural requirements:**
- Background: a single base color everywhere. Every surface -- page, cards, buttons -- uses this same color. In Figma: set the page background and every frame fill to the exact same color variable. No surface should use a different fill value.
- Raised elements: In Figma: Drop Shadow 1 (X:-4, Y:-4, Blur:8, Color:#FFFFFF, Opacity:70%) + Drop Shadow 2 (X:4, Y:4, Blur:8, Color:#000000, Opacity:20%). No stroke. No fill different from the base color.
- Pressed/active: In Figma prototype: on press, swap to an Inner Shadow variant (Inner Shadow X:2, Y:2, Blur:6, #000 20% + Inner Shadow X:-2, Y:-2, Blur:6, #FFF 70%). Elements push in on interaction.
- No borders anywhere. No color fills on buttons. The dual shadow IS the affordance.

**Wrong if:** any surface uses a different fill color from the base, any element has a visible stroke, any shadow is a single directional shadow rather than the dual light/dark pair.

## Token Modifications

```
color/semantic/background — single base color, all surfaces match
  light: #E4EBF5 or warm equivalent
  dark:  #1E1E2E

shadow/neumorphic-raised-light:   -4px -4px 8px rgba(255,255,255,0.6)
shadow/neumorphic-raised-dark:     4px  4px 8px rgba(0,0,0,0.25)
shadow/neumorphic-inset-light:  inset -2px -2px 6px rgba(255,255,255,0.7)
shadow/neumorphic-inset-dark:   inset  2px  2px 6px rgba(0,0,0,0.2)

// Claymorphism addition
shadow/clay-glow: inset 0 1px 4px rgba(255,255,255,0.5)

radius: generous — 16-24px on interactive elements
border: none
typography: medium weight, same-color or slightly lighter/darker than bg
```

Pending Rob's own personal taste extraction (TASTE.md, not yet built): base color values above are generic defaults. Once TASTE.md exists, it overrides the specific values here.

## Component Rules

Buttons are raised by default, inset on press. Sliders use inset track with raised thumb. Icons are subtle, same-hue as background. No borders -- depth is all shadow. Active/selected states use inset shadow to show the element being pressed in. Color must be used carefully for contrast given the tight background-to-element color relationship: text must pass 4.5:1 against the background.

WCAG contrast is the primary failure mode for this style. Run every text/background combination through a contrast checker before shipping. The monochromatic palette that makes neumorphism look good is the same thing that makes it fail accessibility checks.

## Platform Implementation

**iOS / SwiftUI**
```swift
struct NeumorphicSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(hex: "E4EBF5"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.white.opacity(0.7), radius: 8, x: -4, y: -4)
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 4, y: 4)
    }
}

// Claymorphism variant with inner glow
struct ClayButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(hex: "E4EBF5"))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.white.opacity(0.7), radius: 8, x: -4, y: -4)
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 4, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.5), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}
```

**Android / Compose**
Compose's `shadow()` modifier supports a single elevation shadow only -- dual shadows require custom `Canvas` drawing via `drawBehind`:

```kotlin
fun Modifier.neumorphic(
    backgroundColor: Color = Color(0xFFE4EBF5),
    cornerRadius: Dp = 16.dp
): Modifier = this.drawBehind {
    val radiusPx = cornerRadius.toPx()

    // Dark shadow (lower-right)
    drawRoundRect(
        color = Color.Black.copy(alpha = 0.2f),
        topLeft = Offset(4.dp.toPx(), 4.dp.toPx()),
        size = size,
        cornerRadius = CornerRadius(radiusPx),
        blendMode = BlendMode.Multiply
    )
    // Light shadow (upper-left)
    drawRoundRect(
        color = Color.White.copy(alpha = 0.7f),
        topLeft = Offset(-4.dp.toPx(), -4.dp.toPx()),
        size = size,
        cornerRadius = CornerRadius(radiusPx),
        blendMode = BlendMode.Screen
    )
    // Base fill
    drawRoundRect(
        color = backgroundColor,
        size = size,
        cornerRadius = CornerRadius(radiusPx)
    )
}
```

**Web**
```css
.neumorphic {
  background: #E4EBF5;
  border-radius: 16px;
  box-shadow:
    -4px -4px 8px rgba(255,255,255,0.7),
     4px  4px 8px rgba(0,0,0,0.2);
}
.neumorphic:active {
  box-shadow:
    inset -2px -2px 6px rgba(255,255,255,0.7),
    inset  2px  2px 6px rgba(0,0,0,0.2);
}

/* Claymorphism variant */
.clay {
  background: #E4EBF5;
  border-radius: 20px;
  box-shadow:
    -4px -4px 8px rgba(255,255,255,0.7),
     4px  4px 8px rgba(0,0,0,0.2),
    inset 0 1px 4px rgba(255,255,255,0.5); /* inner glow */
}
```

Signature GPU technique (none -- pure CSS box-shadow) and `.drawingGroup()` rendering-artifact guidance: see `SKILL.md` → Style-to-Technique Mapping, item 6.

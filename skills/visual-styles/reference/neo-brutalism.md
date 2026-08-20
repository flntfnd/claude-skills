# Neo-Brutalism

Bold, flat, direct. Hard offset shadows. High-contrast color pairs. Thick borders. Oversized type. Geometric shapes with sharp corners. Influenced by brutalist architecture's honest-materials philosophy -- what you see is what it is. No decorative layer pretending to be something it isn't. More polished and colorful than pure Brutalism.

**When to use**: Fintech (non-enterprise), crypto, startups, creative tools, developer tools, anything targeting an audience that reads design intent as a signal.

## Contents
- [Visual Signature](#visual-signature)
- [Token Modifications](#token-modifications)
- [Component Rules](#component-rules)
- [Platform Implementation](#platform-implementation)

## Visual Signature

Identifiable at a glance by: hard flat drop shadows on cards and interactive elements (`box-shadow: 4px 4px 0 0 #000`), thick black borders on every container, brand-color fills on large sections (hero, CTA, footer), oversized ExtraBold/Black weight display type. The press-collapse interaction on buttons -- shadow shrinks to zero and element shifts to fill the offset on click -- is the defining Neo-Brutalist behavior and must be implemented. If you hover over any interactive element and it doesn't visually react in a loud, physical way, the style is wrong.

**Structural requirements for common patterns:**
- Navigation: solid brand-color bar with thick black bottom border (2-4px), full-width, white or black text. In Figma: stroke on bottom edge only, 2-4px, #000.
- Hero: full-width brand-color background section with ExtraBold display type on it, sharp edges, no radius. In Figma: frame fill = brand color, corner radius = 0.
- Content lists (work, features, etc.): each item is a CARD -- a bordered rectangle with a hard offset shadow. NOT a divider-separated list. In Figma: 2px stroke (#000, center), Drop Shadow (X:4, Y:4, Blur:0, Color:#000, Opacity:100%), corner radius 0. Items that are just separated by hairlines are Neo-Minimalist.
- Interactive elements (arrows, buttons, links): have the press-collapse shadow behavior. In prototype: on Press, change shadow offset from 4,4 to 0,0 and shift element by 4px down-right.
- Section backgrounds: alternate between white and brand color. CTA section fills entirely with brand color.
- Dividers between sections: 2px solid black, not hairlines.

**Wrong if:** content items are divider-separated list rows rather than boxed cards with hard offset drop shadows (blur:0), any shadow has a blur radius above 0 (that makes it soft, not Neo-Brutalist), hover states are subtle color tints, any corner has radius above 4px.

## Token Modifications

```
color/primitive/brand     — bold, saturated primary
  50:  #FFFBEB
  500: #F59E0B  (or substitute: electric blue, coral, lime)
  900: #78350F

color/primitive/accent    — high-contrast secondary
  500: #000000  or #1A1A1A

color/semantic/background/primary  → #FFFFFF or #F5F500 (brand)
color/semantic/background/surface  → brand color (heavy use)
color/semantic/text/primary        → #000000
color/semantic/border/default      → #000000 at 100% (full black)
color/semantic/shadow/hard         → #000000 at 100%

radius/xs  → 0
radius/sm  → 0
radius/md  → 0
radius/lg  → 4  (only on explicitly rounded elements)
radius/pill → 9999

shadow/hard-sm: 2px 2px 0 0 #000000
shadow/hard-md: 4px 4px 0 0 #000000
shadow/hard-lg: 6px 6px 0 0 #000000
shadow/hard-xl: 8px 8px 0 0 #000000

typography/weight/headline → ExtraBold (800) or Black (900)
typography/weight/body     → Medium (500)
typography/size/display    → 64-96sp (push it large)
typography/family          → grotesque sans or display sans
                             (Space Grotesk, Syne, Cabinet Grotesk)
```

Pending Rob's own personal taste extraction (TASTE.md, not yet built): the brand color and hex values here are generic defaults, not verified brand preference. Once TASTE.md exists, it overrides the specific values here.

## Component Rules

Buttons: solid fill, full black 2-4px border, hard offset shadow. On press: shadow collapses (offset goes to 0,0), element shifts to fill the shadow offset. This is the defining neo-brutalist interaction. Cards: full black border, hard shadow, zero radius. No subtle hover states -- interactions are loud and physical. Dividers are heavy (2px+), not hairlines. Layout uses visible grid logic: columns are evident, not hidden.

## Platform Implementation

**iOS / SwiftUI**
```swift
// Neo-brutalist button modifier
struct NeoBrutalButton: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .background(Color.yellow)
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.black, lineWidth: 2)
            )
            .offset(
                x: isPressed ? 3 : 0,
                y: isPressed ? 3 : 0
            )
            .shadow(
                color: .black,
                radius: 0,
                x: isPressed ? 0 : -4,
                y: isPressed ? 0 : 4
            )
            .animation(.spring(response: 0.15, dampingFraction: 0.6), value: isPressed)
            .onTapGesture { isPressed.toggle() }
    }
}
```

Use `RoundedRectangle(cornerRadius: 0)` for all card and container shapes. `Font.system(.largeTitle, weight: .black)` for display type.

**Android / Compose**
```kotlin
// Hard shadow via drawBehind
Modifier.drawBehind {
    translate(left = 6f, top = 6f) {
        drawRoundRect(
            color = Color.Black,
            cornerRadius = CornerRadius.Zero
        )
    }
}
.border(2.dp, Color.Black, RectangleShape)
```

`FontWeight.Black` for headlines. `RectangleShape` on all buttons and cards.

**Web**
```css
.neo-brutal-card {
  border: 2px solid #000;
  box-shadow: 4px 4px 0 0 #000;
  border-radius: 0;
  transition: box-shadow 0.1s, transform 0.1s;
}
.neo-brutal-card:hover {
  box-shadow: 6px 6px 0 0 #000;
  transform: translate(-2px, -2px);
}
.neo-brutal-card:active {
  box-shadow: 0 0 0 0 #000;
  transform: translate(4px, 4px);
}
```

Signature GPU technique (none -- deliberate), press-collapse interaction timing, and Windows notes: see `SKILL.md` → Style-to-Technique Mapping, item 2.

# Futuristic / Sci-Fi

Dark surfaces. Neon accent colors. Glowing UI elements. Grid systems as foreground design elements. Data visualization aesthetics applied to UI. Feels like the product belongs to a system with intelligence behind it. References HUD interfaces, terminal UIs, and science fiction visual language -- but refined and usable.

**When to use**: Developer tools, security/monitoring dashboards, fintech (high-end), AI products, gaming-adjacent apps, anything where projecting technical sophistication is on-brand.

## Contents
- [Visual Signature](#visual-signature)
- [Token Modifications](#token-modifications)
- [Component Rules](#component-rules)
- [Platform Implementation](#platform-implementation)

## Visual Signature

Identifiable at a glance by: near-black background (#0A0A0F), neon accent colors with glow (`box-shadow: 0 0 16px var(--accent)`), visible grid lines or geometric border patterns at low opacity, monospace type for data readouts, angular/minimal UI chrome. Should feel like a command center.

**Structural requirements:**
- Background: deep near-black, not generic dark grey. Subtle noise or gradient (radial from center at low opacity) acceptable.
- Accent elements: borders and active states glow. Use `box-shadow: 0 0 8px var(--accent-color)` on focused/active states.
- Cards: 1px accent-color border at 15-20% opacity, background slightly lighter than page. On hover: border brightens to full accent, subtle glow appears.
- Data elements: monospace type. Numbers and readouts use tabular figures, the monospace aesthetic is intentional.
- Grid: optional but characteristic -- a subtle CSS grid pattern at 5-8% opacity as a background texture (`background-image: linear-gradient` technique).
- Primary buttons: glow on hover. Accent fill with `box-shadow` glow.

**Wrong if:** the background is generic dark grey, there are no glowing elements or the glow is absent, the typography is all proportional sans-serif with no monospace data treatment, cards look like standard rounded-corner cards with no border treatment.

## Token Modifications

```
color — dark base, neon accents:
  background/primary:   #0A0A0F  (near black, slight blue)
  background/secondary: #12121A
  background/elevated:  #1A1A28
  text/primary:         #E8E8F0
  text/secondary:       #8888A8
  text/dim:             #4A4A6A

  accent/primary:   #00F5D4  (cyan-teal neon)
  accent/secondary: #A855F7  (electric purple)
  accent/warning:   #F59E0B
  accent/error:     #EF4444
  accent/glow:      accent color at 30-40% opacity as shadow

glow/sm:  0 0 8px  {accent}
glow/md:  0 0 16px {accent}
glow/lg:  0 0 32px {accent}
glow/xl:  0 0 64px {accent}

border/grid:    rgba(0,245,212,0.15)  (accent at low opacity)
border/focus:   accent/primary at full opacity
border/default: rgba(255,255,255,0.08)

radius: minimal — 0 to 4px. Futurism is angular.
```

Pending Rob's own personal taste extraction (TASTE.md, not yet built): the neon accent hues above are generic defaults. Once TASTE.md exists, it overrides the specific values here.

## Component Rules

Primary buttons glow: box-shadow with accent color. Active states pulse or shimmer -- subtle, not obnoxious. Progress bars use gradient fill from transparent to accent. Data readouts use monospace type. Grid lines are visible design elements, not hidden guides. Borders on cards are 1px, low opacity, with a faint glow on hover. Backgrounds can use subtle CSS grid patterns or noise at very low opacity.

## Platform Implementation

**iOS / SwiftUI**
```swift
// Glowing accent modifier
struct GlowEffect: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.8), radius: radius / 2)
            .shadow(color: color.opacity(0.4), radius: radius)
            .shadow(color: color.opacity(0.2), radius: radius * 2)
    }
}

// Usage
Text("SYSTEM ACTIVE")
    .foregroundStyle(Color(hex: "00F5D4"))
    .modifier(GlowEffect(color: Color(hex: "00F5D4"), radius: 8))
```

Use `Color(.systemBackground)` overridden with dark theme locked (`.preferredColorScheme(.dark)`). Apply `TimelineView` for pulsing glow animations.

**Android / Compose**
Lock to dark theme: `darkTheme = true` in `AppTheme`. Achieve glow with layered shadows using `drawBehind`. Canvas-based grid backgrounds.

**Web**
```css
.glow-text {
  color: #00F5D4;
  text-shadow:
    0 0 8px rgba(0,245,212,0.8),
    0 0 16px rgba(0,245,212,0.4),
    0 0 32px rgba(0,245,212,0.2);
}

.grid-bg {
  background-image:
    linear-gradient(rgba(0,245,212,0.05) 1px, transparent 1px),
    linear-gradient(90deg, rgba(0,245,212,0.05) 1px, transparent 1px);
  background-size: 40px 40px;
}
```

Signature GPU technique (`UnrealBloomPass` post-processing, grid fragment shader, additive-blend particles): see `SKILL.md` → Style-to-Technique Mapping, item 8. **[Verified]** `UnrealBloomPass` remains an actively maintained, current example in the three.js post-processing suite as of mid-2026 -- no deprecation or recommended replacement found.

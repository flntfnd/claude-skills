# Design Styles
Visual design language specifications for iOS, iPadOS, macOS, Android, and Web.
Each style defines token modifications, component rules, and native implementation per platform.

---

# How to Use This File

A project has one design style. Pick it before touching tokens. The style determines how the token system is weighted and what the component visual language looks like. The underlying token architecture from DESIGN-systems.md stays constant -- this file tells you how to populate it.

Every style listed here applies equally to iOS, Android, and Web. All three are first-class targets. Each style section contains implementation details for all three platforms.

On native platforms: implement with platform-native APIs. No web-views, no visual approximations. If the style calls for a hard shadow, that's a SwiftUI `shadow()` modifier or a Compose `drawBehind` -- not a dropped PNG.

On Web: implement with CSS custom properties, modern layout (Grid, Flexbox), and native browser APIs. No canvas hacks for effects CSS handles natively. No JavaScript for animations that CSS handles natively. Performance and accessibility are not optional on any platform.

---

# Style Index

1. Neo-Minimalism
2. Neo-Brutalism
3. Brutalism (Pure)
4. Liquid Glass (Navigation Layer)
5. Glassmorphism / Frosted
6. Neumorphism / Soft UI
7. Kinetic Typography
8. Futuristic / Sci-Fi
9. Bento Grid
10. Editorial / Structural
11. Organic / Biomorphic
12. Texture / Tactile
13. Y2K / Retro Computing
14. Calm / Anti-Distraction

---

# 1. Neo-Minimalism

Minimalism with warmth. Not the cold, sterile white-on-white minimalism of 2018 -- this has texture, personality, and emotional weight. Organic spacing rhythms replace rigid 8pt grids. Serif type pairs with restrained sans. The interface feels considered, not empty.

**When to use**: Productivity apps, lifestyle, health, finance, anything that needs clarity without feeling clinical.

## Token Modifications

```
color/primitive/neutral   — warm-tinted neutrals, not pure gray
  100: #FAF9F7
  200: #F5F3EE
  300: #E8E4DC
  500: #B5AFA4
  700: #6B6560
  900: #2A2622

color/semantic/background/primary  → warm white (#FAF9F7)
color/semantic/background/secondary → #F5F3EE
color/semantic/text/primary         → #2A2622 (warm near-black)
color/semantic/border/default       → rgba(42,38,34,0.12)

radius/sm   → 6
radius/md   → 10
radius/lg   → 18
radius/xl   → 28

spacing — expand base by 25%:
  base → 20
  lg   → 28
  xl   → 40

typography/weight/heading   → Light (300) for display, Regular (400) for body
typography/family/heading   → Serif (NYT Cheltenham, Canela, or platform serif)
typography/family/body      → SF Pro / Roboto / Inter at Regular
```

## Component Rules

Single-pixel hairline dividers, not full borders. Generous whitespace. No card borders -- elevation through spacing and subtle background tint difference, not outlines. Icons are line-weight, not filled. Interactive elements have minimal visual footprint: text buttons preferred over contained buttons for secondary actions.

## Platform Implementation

**iOS / SwiftUI**
Use `.font(.system(.body, design: .serif))` for editorial content. Secondary backgrounds use `Color(.secondarySystemBackground)` with opacity modifier for warmth. Spacing uses `Spacing.xl` between sections. Avoid `List` row separators -- use custom spacing instead.

**Android / Compose**
Use `MaterialTheme.typography` with Roboto Flex at low weight for headlines. Surface colors reference the warm neutral palette. `Divider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f))` for hairline separators.

**Web**
`--font-heading: 'Canela', Georgia, serif` in `:root`. Line heights 1.6-1.8 for body. `letter-spacing: 0.02em` on display type. Borders at 0.5-1px, warm neutral color.

---

# 2. Neo-Brutalism

Bold, flat, direct. Hard offset shadows. High-contrast color pairs. Thick borders. Oversized type. Geometric shapes with sharp corners. Influenced by brutalist architecture's honest-materials philosophy -- what you see is what it is. No decorative layer pretending to be something it isn't. More polished and colorful than pure Brutalism.

**When to use**: Fintech (non-enterprise), crypto, startups, creative tools, developer tools, anything targeting an audience that reads design intent as a signal.

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

---

# 3. Brutalism (Pure)

Stripped to structure. No decorative layer. Monochrome or near-monochrome. Raw HTML aesthetic with contemporary performance standards. Type is the primary visual element. Functional hierarchy through spacing and weight alone, not color or decoration. Confrontational and honest.

**When to use**: Developer tools, technical documentation interfaces, niche platforms where the audience reads raw aesthetic as credibility. Not for consumer products.

## Token Modifications

```
color palette: two colors maximum
  primary background: #FFFFFF or #F0EDE8
  primary text: #000000
  accent (use sparingly): one saturated color or none

radius: all 0
border: 1px solid #000 or no border
shadow: none
spacing: large and irregular-feeling, not mathematically perfect
typography: monospace or grotesque sans
  size: extremes -- either very large or very small, little in between
```

## Component Rules

No cards as visual containers -- use whitespace and type hierarchy to create zones. No icons except where functional. No illustrations. Tables are the primary data layout. Buttons are underlined text or minimal bordered rectangles. Interactive states are text decoration changes and cursor changes, not color fills.

## Platform Implementation

**iOS / SwiftUI**
`.background(Color.clear)`, custom drawn borders via `.overlay(Rectangle().stroke(Color.black, lineWidth: 1))`, aggressive typography scale. Keep system haptics and animations -- brutalism is a visual language, not a behavioral one. System components should be minimally restyled, not replaced.

**Android / Compose**
`RectangleShape` everywhere. `Border(1.dp, Color.Black)`. `FontFamily.Monospace` for body text. Suppress elevation on all components (`elevation = 0.dp`). Keep system navigation and gesture behavior unchanged.

**Web**
```css
:root {
  --font-mono: 'JetBrains Mono', 'Courier New', monospace;
  --color-ink: #000000;
  --color-paper: #FFFFFF;
}

body {
  font-family: var(--font-mono);
  color: var(--color-ink);
  background: var(--color-paper);
  max-width: 900px;
  margin: 0 auto;
  padding: 2rem;
}

h1 { font-size: clamp(2rem, 8vw, 6rem); line-height: 1; }
h2 { font-size: clamp(1.2rem, 4vw, 2.5rem); }
p  { font-size: 1rem; line-height: 1.6; max-width: 65ch; }

a { color: inherit; text-decoration: underline; text-underline-offset: 3px; }
a:hover { background: var(--color-ink); color: var(--color-paper); }

hr { border: none; border-top: 1px solid var(--color-ink); margin: 2rem 0; }

button, .btn {
  font-family: inherit;
  font-size: 0.875rem;
  background: none;
  border: 1px solid var(--color-ink);
  padding: 0.5rem 1rem;
  cursor: pointer;
}
button:hover { background: var(--color-ink); color: var(--color-paper); }
```
No border-radius. No shadows. No colors beyond black and white unless a single accent is specified. Layout is document-flow with explicit column structure via CSS Grid.

---

# 4. Liquid Glass (Navigation Layer)

Covered in detail in APPLE.md (Apple platforms). Summary for cross-platform reference:

Glass belongs on the navigation layer. Content sits below it. The material adapts to what's behind it. Liquid Glass is a layout decision, not a surface texture applied after the fact.

**When to use**: iOS 26+, iPadOS 26+, macOS Tahoe 26+ apps that follow Apple's HIG.

**On Web**: Liquid Glass as Apple defines it (real-time lensing, specular response to device motion) is not achievable in a browser. Use the Glassmorphism / Frosted style (style #5) for web surfaces that need the same depth and translucency intent. The Figma Glass effect with Refraction and Frost parameters approximates the visual for mockups, but the web implementation falls back to `backdrop-filter: blur()` with appropriate fill opacity and inner highlight stroke.

**Known usability failure modes** (documented by NN/g and others in iOS 26's release): text placed over glass controls that sits on top of other text becomes unreadable; glass navigation bars that blend into complex wallpapers become invisible; overuse of motion and physics in the glass layer creates an interface that competes with content for attention rather than supporting it. These are failure modes to avoid, not examples to follow.

Token and implementation details for native: `~/.claude/skills/APPLE.md`.

---

# 5. Glassmorphism / Frosted

The static, web-native sibling of Liquid Glass. Translucent surfaces with background blur, inner highlight strokes, and subtle depth. Unlike Liquid Glass, there's no real-time lensing -- the effect is achieved through blur and opacity. Still contemporary and premium when not overused.

**When to use**: Web dashboards, marketing sites, landing pages, Android apps where a premium translucent aesthetic is called for. On iOS, use Liquid Glass instead.

## Token Modifications

```
glass/fill:            rgba(255,255,255,0.12)  light mode
                       rgba(255,255,255,0.08)  dark mode
glass/fill-strong:     rgba(255,255,255,0.20)  light
                       rgba(255,255,255,0.15)  dark
glass/border:          rgba(255,255,255,0.25)
glass/blur:            16px (standard), 32px (heavy)
glass/shadow:          0 8px 32px rgba(0,0,0,0.12)
glass/highlight:       inset 0 1px 0 rgba(255,255,255,0.3)

backgrounds must have content to blur -- solid backgrounds kill the effect
dark, rich backgrounds work best (gradients, imagery, deep color fields)
```

## Component Rules

Apply to floating elements only: nav bars, cards over imagery, modals, tooltips. Never to the page background itself. Never to content-dense areas where text readability is critical without adjustment. Text on glass needs either a shadow or sufficient frost to remain legible.

**Scrim technique for legibility**: when glass sits over unpredictable backgrounds (user-generated imagery, video, dynamic content), add a semi-opaque gradient inside the glass component to guarantee text contrast regardless of what's behind it. A subtle dark scrim (rgba(0,0,0,0.15) to transparent, bottom-to-top) for dark text, or a light scrim for light text on dark glass. This is how streaming apps (Spotify, Apple Music) keep their glass album art overlays consistently readable.

**Text color shifting**: for interfaces where the background is brand-specific or highly chromatic, the glass blur desaturates and shifts colors behind it. Account for this in brand reviews -- run the glass effect over the full range of content it will actually appear over, not just placeholder imagery.

## Platform Implementation

**iOS / SwiftUI**
Use `.ultraThinMaterial`, `.thinMaterial`, `.regularMaterial`. These are system-correct and adapt to dark mode automatically. Don't manually replicate the effect -- the system materials are optimized for performance and accessibility.

**Android / Compose**
```kotlin
Box(
    modifier = Modifier
        .blur(16.dp)
        .background(Color.White.copy(alpha = 0.12f))
        .border(
            1.dp,
            Color.White.copy(alpha = 0.25f),
            RoundedCornerShape(16.dp)
        )
)
```

**Web**
```css
.glass {
  background: rgba(255, 255, 255, 0.12);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  border: 1px solid rgba(255, 255, 255, 0.25);
  box-shadow:
    0 8px 32px rgba(0,0,0,0.12),
    inset 0 1px 0 rgba(255,255,255,0.3);
}
```

---

# 6. Neumorphism / Soft UI

Soft extruded surfaces. Elements appear to emerge from or press into the background. Achieved through dual shadows: one light from upper-left, one dark from lower-right. Background and element colors match closely. The result is tactile and dimensional without explicit borders.

In 2026, pure neumorphism has evolved into **Claymorphism** -- the same dual-shadow approach but with an added inner glow that makes elements appear slightly inflated, like soft clay or silicone. This subtle addition improves perceived affordance without meaningfully impacting accessibility. Apply it selectively to high-touch interactive elements (buttons, toggles, knobs) rather than background surfaces.

**When to use**: Health and wellness, audio and music apps, any UI where a tactile, physical feel serves the content. Use sparingly -- it does not scale to information-dense layouts. Accessible neumorphism (Soft UI) maintains contrast standards; classic neumorphism does not.

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

---

# 7. Kinetic Typography

Type is the primary visual element and it moves. Text animates in response to scroll, time, interaction, or state changes. Not marquees and not carousels -- purposeful motion that communicates meaning through how text arrives, transforms, or exits. Text stretches, rotates, reveals character by character, reacts to input.

**When to use**: Onboarding flows, empty states, marketing surfaces within apps, loading experiences, editorial content. Not for data tables or utility UI.

## Token Modifications

```
typography/size/display → push extremes: 72-120sp for hero text
typography/weight → variable where platform supports (Roboto Flex, SF Pro)
  weight-min: 100
  weight-max: 900
  width-min:  75 (condensed)
  width-max:  125 (expanded)

motion/kinetic/char-stagger:  0.03s per character
motion/kinetic/word-stagger:  0.06s per word
motion/kinetic/line-stagger:  0.12s per line
motion/kinetic/reveal-duration: 0.6s
motion/kinetic/easing: cubic-bezier(0.16, 1, 0.3, 1)  (expo out)
```

## Component Rules

Each animated text element has a single, defined behavior. Mix-and-match animation types create chaos. Pick one reveal pattern per context: character stagger for hero moments, line reveal for body content, weight animation for emphasis feedback. Motion must respect `reduceMotion` -- provide a static fallback that still reads correctly.

## Platform Implementation

**iOS / SwiftUI**

Variable font weight animation (SF Pro supports this via weight axis):
```swift
@State private var fontWeight: CGFloat = 100

Text("Design")
    .font(.system(size: 80, weight: .init(rawValue: fontWeight)))
    .onAppear {
        withAnimation(
            .spring(response: 0.8, dampingFraction: 0.6).delay(0.1)
        ) {
            fontWeight = 900
        }
    }
```

Character-by-character reveal using `AttributedString` and staggered animations. Use `TimelineView` for scroll-driven effects.

**Android / Compose**

Roboto Flex supports weight and width axes:
```kotlin
val fontWeight by animateFloatAsState(
    targetValue = if (isVisible) 700f else 100f,
    animationSpec = spring(
        dampingRatio = Spring.DampingRatioMediumBouncy,
        stiffness = Spring.StiffnessLow
    )
)

Text(
    text = "Design",
    style = TextStyle(
        fontVariationSettings = FontVariation.Settings(
            FontVariation.weight(fontWeight.toInt())
        )
    )
)
```

**Web**
```css
@keyframes textReveal {
  from { 
    transform: translateY(100%);
    opacity: 0;
  }
  to { 
    transform: translateY(0);
    opacity: 1;
  }
}

.kinetic-char {
  display: inline-block;
  animation: textReveal 0.6s cubic-bezier(0.16, 1, 0.3, 1) both;
}
/* Stagger via JS: element.style.animationDelay = index * 0.03 + 's' */
```

For scroll-driven animation use the CSS `animation-timeline: scroll()` property with `@keyframes` linked to scroll position. No JavaScript required for scroll-triggered type on modern browsers.

---

# 8. Futuristic / Sci-Fi

Dark surfaces. Neon accent colors. Glowing UI elements. Grid systems as foreground design elements. Data visualization aesthetics applied to UI. Feels like the product belongs to a system with intelligence behind it. References HUD interfaces, terminal UIs, and science fiction visual language -- but refined and usable.

**When to use**: Developer tools, security/monitoring dashboards, fintech (high-end), AI products, gaming-adjacent apps, anything where projecting technical sophistication is on-brand.

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

---

# 9. Bento Grid

Modular card-based layout. Content organized into a grid of variably-sized rectangular cells. Some cells span multiple columns or rows. The grid is the design -- the bento structure is explicit and intentional, not just a layout tool. Popularized by Apple's product pages and widely adopted in dashboards and landing pages.

**When to use**: Dashboards, home screens, marketing surfaces, any context where varied content types need to coexist at the same visual level. Strong fit for iPad and large-screen layouts.

## Token Modifications

```
radius: 16-32px is the 2026 standard -- "organic modularity"
  card: 20-24px for standard cells
  featured: 28-32px for large hero cells
  All cards must share the same radius family -- mixing tight and generous radius
  within the same grid breaks visual cohesion.

spacing/grid-gap:  16-20px between cells
spacing/cell-pad:  24-32px inner card padding

color/semantic/surface — mild variation between cells for visual rhythm:
  cell/primary:   background/secondary
  cell/featured:  brand color or strong accent (1-2 cells max)
  cell/muted:     background/tertiary
```

## Component Rules

Every cell is a card. All cards share the same border radius. Cards contain a single content type: one metric, one visual, one action. Never mix content types inside one cell. The featured cell (the large one) gets the brand color. Support for spanning: 1x1, 2x1, 1x2, 2x2, 3x1. Grid is always consistent -- cells align to the same column tracks.

Visual hierarchy is encoded in size: larger cells signal more important content. If every cell is the same size, you've built a regular grid with rounded corners -- not a bento. The largest cell should contain the highest-value information for the context.

**Accessibility -- source order matters.** CSS Grid allows placing a box anywhere visually, which makes it easy to create layouts where the DOM order is totally disconnected from the visual reading order. Screen readers follow DOM order, not visual order. Write HTML in the logical hierarchy the information requires, then use `grid-column`/`grid-row` to position cells visually. Never reorder cells purely for visual reasons if it inverts the logical reading sequence. Every cell should be wrapped in appropriate semantic elements: `<article>` for self-contained content, `<section aria-labelledby="...">` for functional regions. Every interactive cell needs a visible, high-contrast focus indicator.

**Limit visible cells.** More than 12-15 cells visible simultaneously destroys the organizational benefit. When everything competes for attention, nothing wins. Paginate, collapse, or truncate rather than cramming.

## Platform Implementation

**iOS / SwiftUI**
Use `LazyVGrid` with custom column definitions. `GridItem(.flexible())` for equal columns, `GridItem(.fixed(n))` for explicit sizing.

```swift
LazyVGrid(
    columns: [
        GridItem(.flexible()),
        GridItem(.flexible())
    ],
    spacing: 16
) {
    BentoCell(span: .double) { FeaturedContent() }
    BentoCell(span: .single) { MetricA() }
    BentoCell(span: .single) { MetricB() }
}
```

**Android / Compose**
`LazyVerticalGrid` with `GridCells.Fixed(2)`. For spanning, use `item(span = { GridItemSpan(maxLineSpan) })`.

**Web**
CSS subgrid (widely supported 2024+) is the correct tool for aligned content across cells:

```css
.bento-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  grid-template-rows: auto;
  gap: 16px;
}

/* Featured cell spanning */
.bento-featured {
  grid-column: span 2;
  grid-row: span 2;
}

/* Subgrid for internal alignment across cards */
.bento-cell {
  display: grid;
  grid-template-rows: subgrid;
  grid-row: span 2; /* inherit parent tracks */
}

/* Responsive: collapse to single column on narrow screens */
@media (max-width: 640px) {
  .bento-grid {
    grid-template-columns: 1fr;
  }
  .bento-featured {
    grid-column: span 1;
    grid-row: span 1;
  }
}

/* Micro-interaction: lift on hover */
.bento-cell {
  transition: transform 0.2s ease-out;
}
.bento-cell:hover {
  transform: translateY(-4px);
}
```

**Mobile responsive note**: size hierarchy that communicates importance on wide screens collapses on mobile. Decide explicitly which cells maintain prominence at smaller breakpoints -- don't let the grid degrade to identically-sized blocks by accident.

---

# 10. Editorial / Structural

Grids as foreground design elements. Typography leads. Influenced by print design: newspapers, magazines, annual reports. Blueprint aesthetic. Serif headlines. Visible structure. Dense information architecture made readable through precise typographic hierarchy. Wireframe logic brought into production.

**When to use**: News and editorial apps, financial reporting tools, research tools, professional services. Signals: sophisticated, trustworthy, precise.

## Token Modifications

```
typography:
  display: large, serif, light weight (Canela, Libre Caslon, or platform serif)
  headline: bold serif or condensed grotesque
  body: regular serif or comfortable sans at 16-18sp with generous leading
  label: caps-spaced sans at small size (tracking: 0.08-0.15em)
  numerals: tabular figures, monospace-width

color:
  ink: near-black (#1A1A1A, not pure black)
  paper: warm off-white (#FAF8F5)
  rule: light gray (#E8E4DC) for hairline dividers
  accent: one strong color, used sparingly for emphasis

spacing:
  column-gutter: explicit and visible through dividing rules
  leading: generous (1.6-1.8x for body, 1.2x for headlines)

radius: 0 or very minimal (2-4px at most)
```

## Component Rules

Horizontal rules are primary structural elements. Sections are delineated by rules and whitespace, not by cards or boxes. Column grid is explicit -- content aligns to it precisely. Numbers get tabular figures to align in lists and tables. Image captions are caption size, always. No decorative elements -- every visual element carries information.

## Platform Implementation

**iOS / SwiftUI**
`.font(.system(.largeTitle, design: .serif))` for display. Custom `Divider()` with `.background(Color(.separator).opacity(0.4))` and `.frame(height: 0.5)` for hairlines. `Text` with `.kerning(1.5)` and `.textCase(.uppercase)` for small caps labels.

**Android / Compose**
`fontFamily = FontFamily.Serif` for editorial text. `Divider(thickness = 0.5.dp)` for hairlines. Custom `TextStyle` with `letterSpacing = 0.08.sp` for label text.

**Web**
```css
:root {
  --font-editorial: 'Canela', 'Georgia', serif;
  --leading-editorial: 1.75;
  --tracking-label: 0.08em;
}
.rule { border-top: 0.5px solid #E8E4DC; }
.label {
  font-size: 11px;
  letter-spacing: var(--tracking-label);
  text-transform: uppercase;
  font-weight: 600;
}
```

---

# 11. Organic / Biomorphic

Flowing, irregular shapes. Nature-inspired curves. No hard corners or rigid geometry. Asymmetric balance. Gradient washes that suggest light on organic surfaces. Illustrations and shapes feel hand-crafted or grown. Color palettes from nature: earth tones, botanical greens, sky blues, terracotta, sage.

**When to use**: Wellness, meditation, health, food, sustainability, any product that benefits from a non-digital, living-world feeling.

## Token Modifications

```
radius: irregular and large
  container: 40-60% of smallest dimension (approaching circle)
  blob shapes: CSS clip-path or SVG path, not border-radius

color:
  primary palette: muted natural tones
    terracotta: #C4704A
    sage:       #8FAB8A
    sky:        #6B9FBF
    sand:       #D4B896
    earth:      #7B5C3E

  gradients: soft, two-stop, low contrast
    "sunrise": #FFD4A3 → #FFA07A
    "forest":  #A8C5A0 → #5A7A5C
    "ocean":   #B3D4E8 → #6A9CB8

spacing: gentle — avoid hard multiples-of-8 rhythm, let it breathe
  prefer: 18, 28, 44 over 16, 24, 40

typography: rounded sans or humanist serif
  variable weight axis, warm not mechanical
```

## Component Rules

Shapes are the primary design element. Use SVG blobs and irregular containers instead of rectangles. Buttons have pill shapes. Cards use high radius. Background shapes add depth without hard edges. Animations are slow and gentle -- easing curves that decelerate softly. No jarring cuts or snappy springs.

## Platform Implementation

**iOS / SwiftUI**
Use `.clipShape(Capsule())` for pill elements. Custom `Shape` implementations for blob backgrounds. `Path` for irregular organic forms. Gradients via `LinearGradient` and `RadialGradient`. Spring animations with high damping ratio (slow, no bounce).

**Android / Compose**
Use `GenericShape` from Compose for organic clip paths. `Brush.linearGradient` for organic color washes. `RoundedCornerShape(50%)` for pill shapes.

**Web**
```css
:root {
  --radius-blob: 30% 70% 70% 30% / 30% 30% 70% 70%;
  --gradient-sunrise: linear-gradient(135deg, #FFD4A3, #FFA07A);
  --gradient-forest:  linear-gradient(135deg, #A8C5A0, #5A7A5C);
  --easing-organic: cubic-bezier(0.4, 0, 0.2, 1);
}

.organic-card {
  border-radius: var(--radius-blob);
  padding: 2rem;
  transition: border-radius 0.8s var(--easing-organic);
}
.organic-card:hover {
  border-radius: 60% 40% 30% 70% / 60% 30% 70% 40%;
}

.blob-section {
  clip-path: ellipse(80% 70% at 50% 50%);
  background: var(--gradient-forest);
}

/* Pill buttons */
.btn-organic {
  border-radius: 9999px;
  padding: 0.75rem 2rem;
  border: none;
  background: var(--gradient-sunrise);
  transition: transform 0.4s var(--easing-organic),
              box-shadow 0.4s var(--easing-organic);
}
.btn-organic:hover {
  transform: scale(1.03) translateY(-2px);
  box-shadow: 0 12px 24px rgba(0,0,0,0.12);
}
```
SVG blob shapes generated programmatically or from a blob generator (blobmaker.app). Animate blob `d` attributes with GSAP MorphSVG or CSS offset-path for organic motion. `scroll-behavior: smooth` at the root.

---

# 12. Texture / Tactile

Grain, noise, paper, fabric. Surfaces that feel like they have physical material underneath them. A reaction to the sterile perfection of flat design and AI-generated imagery. Texture signals human-made. Used with restraint -- a 3-5% grain overlay transforms a flat gradient into something dimensional.

**When to use**: Any style can incorporate texture as a layer. Works especially well with Neo-Minimalism, Organic, Editorial, and Neo-Brutalism. Least compatible with Futuristic and pure Glassmorphism.

## Token Modifications

```
texture/grain/opacity/light:  0.03 - 0.05 (subtle)
texture/grain/opacity/medium: 0.06 - 0.10
texture/grain/opacity/heavy:  0.12 - 0.18  (use rarely)

texture types:
  grain:   SVG feTurbulence noise filter
  paper:   subtle fiber pattern at low opacity
  canvas:  woven texture, slightly more prominent
  linen:   fine diagonal weave
```

## Implementation

**Web (primary platform for texture)**
```css
/* SVG noise filter as a CSS pseudo-element */
.textured::after {
  content: '';
  position: absolute;
  inset: 0;
  background-image: url("data:image/svg+xml,..."); /* SVG noise */
  opacity: 0.04;
  pointer-events: none;
  mix-blend-mode: overlay;
}

/* Or via CSS filter on a ::before */
.grain-bg::before {
  content: '';
  position: fixed;
  inset: -50%;
  width: 200%;
  height: 200%;
  background: url('/noise.png') repeat;
  opacity: 0.04;
  pointer-events: none;
}
```

**iOS / SwiftUI**
Apply grain as a `ZStack` overlay with a noise image at low opacity, using `.blendMode(.overlay)`. Don't bake texture into screenshots -- use a view modifier so it renders correctly at all display scales.

**Android / Compose**
Canvas-drawn Perlin noise overlay on `drawBehind`. Use `BlendMode.Overlay` for correct blending. Keep opacity low -- Android's canvas blend modes can look heavier than web.

---

# 13. Y2K / Retro Computing

Nostalgia for early internet aesthetics: pixelation, CRT scan lines, terminal green, dot-matrix type, Windows 3.1 UI chrome, early web brutalism. But filtered through 2026 sensibilities -- high resolution, performant, intentional. The aesthetic is nostalgic but the craft is contemporary.

**When to use**: Niche apps, gaming-adjacent products, developer tools targeting a specific generational audience, music apps, creative tools where the retro feel is on-brand.

## Token Modifications

```
typography:
  primary family: monospace (JetBrains Mono, Courier New, IBM Plex Mono)
  display: bitmap font or pixel font (as image/SVG, not web font where possible)

color schemes (pick one):
  terminal green: #0A0A0A bg, #00FF41 text, #003B00 dim
  amber CRT:      #0F0A00 bg, #FF9900 text, #3D2400 dim
  blue screen:    #0000AA bg, #AAAAAA text, #FFFFFF accent
  grayscale CRT:  #1A1A1A bg, #D4D4D4 text, #888888 dim

effects:
  scanline: repeating horizontal lines at 2px, 3-8% opacity
  crt-curve: subtle vignette and slight barrel distortion on outer edges
  pixel-grid: 1px grid overlay on image surfaces
  noise: heavier grain (10-15%) than standard texture style

radius: 0 (everything square) or large (rounded screens simulating CRT)
borders: 2-4px solid, Windows-style bevel effects
```

## Platform Implementation

**iOS / SwiftUI**
Apply the color palette and monospace typography. Pixel fonts don't render cleanly at all sizes -- use them display-only (large sizes) or as image assets. CRT scan lines via a `Canvas` overlay view with `drawRect` drawing horizontal lines at 2px intervals, 5-8% opacity. Rounded screen effect via outer vignette applied as a `RadialGradient` overlay. Keep system interactions intact.

**Android / Compose**
`FontFamily.Monospace` for body. Canvas-drawn scan line overlay on the root scaffold via `drawBehind`. Lock to dark theme. System navigation unchanged.

**Web**
Web is the most natural home for this style -- the full range of CSS effects is available here.
```css
:root {
  --crt-green: #00FF41;
  --crt-bg: #0A0A0A;
  --crt-dim: #003B00;
  --font-mono: 'JetBrains Mono', 'Courier New', monospace;
}

body {
  background: var(--crt-bg);
  color: var(--crt-green);
  font-family: var(--font-mono);
}

/* Scan lines */
body::after {
  content: '';
  position: fixed;
  inset: 0;
  background: repeating-linear-gradient(
    0deg,
    transparent,
    transparent 2px,
    rgba(0,0,0,0.08) 2px,
    rgba(0,0,0,0.08) 4px
  );
  pointer-events: none;
  z-index: 9999;
}

/* CRT screen flicker (subtle) */
@keyframes flicker {
  0%, 100% { opacity: 1; }
  92%       { opacity: 0.97; }
  94%       { opacity: 1; }
}
.crt-screen { animation: flicker 8s infinite; }

/* Pixel-style border (Windows 3.1 bevel) */
.win31-box {
  border-top:    2px solid #DFDFDF;
  border-left:   2px solid #DFDFDF;
  border-right:  2px solid #808080;
  border-bottom: 2px solid #808080;
  padding: 4px;
}

/* Terminal cursor blink */
.cursor::after {
  content: '▋';
  animation: blink 1s step-end infinite;
}
@keyframes blink {
  50% { opacity: 0; }
}
```
Keep effects subtle enough that content remains readable. Scan lines at above 10% opacity destroy text legibility.

---

# 14. Calm / Anti-Distraction

Deliberate restraint. Extreme whitespace. Limited color. No notifications aesthetic. Designed for extended use without fatigue. Every visual element serves a purpose -- decoration is a cost, not a default. Motion is almost absent. Type is generous and unhurried. The experience has the feel of a well-designed physical object.

**When to use**: Reading apps, writing tools, meditation, journaling, any context where the user benefits from the interface receding completely. Also a sound default for enterprise and professional tools.

## Token Modifications

```
color:
  palette: maximum three values
  background: very soft warm white or very dark warm gray
  text: near-black or near-white (never pure black or pure white)
  accent: single muted color, used only for interactive elements

  light palette: #FAFAF8 (bg), #2C2C2A (text), #6B9FBF (accent, used sparingly)
  dark palette:  #1A1A18 (bg), #E8E8E4 (text), #A0B8C8 (accent)

spacing: everything gets 25-50% more space than you think it needs
  section spacing → xxxl (64px+)
  content padding → xl (24-32px)
  line height     → 1.7-1.9 for body

radius: mid-range (8-16px) — not sharp, not pill
typography: regular weight for body (400), medium for emphasis (500), nothing heavier
motion: none as default
  transitions that exist: 200-300ms ease-in-out opacity only
  no sliding, no bouncing, no spring
```

## Component Rules

One action per screen region. Navigation is hidden or minimal until needed. No badges on content items. No empty-state illustrations -- use text only. No decorative dividers -- use spacing. Buttons are text or minimal outline -- no filled containers except for the single most important action. Focus indicators are the only bright interactive signal.

## Platform Implementation

**iOS / SwiftUI**
`.navigationBarHidden(true)` or custom minimal nav. Tab bar hidden during reading. `.scrollContentBackground(.hidden)`. `.preferredColorScheme` respects system setting. `Text` line height via `.lineSpacing(6)`. Motion off by default -- check `accessibilityReduceMotion` and skip even the minimal transitions if it's on.

**Android / Compose**
Full edge-to-edge with `enableEdgeToEdge()`. Hide system bars during content reading with `WindowInsetsController`. `lineHeight` set to 1.7x font size in `TextStyle`. `MotionScheme.standard()` with very slow specs for the rare transitions that exist.

**Web**
```css
:root {
  --color-bg:      #FAFAF8;
  --color-text:    #2C2C2A;
  --color-accent:  #6B9FBF;
  --color-muted:   #888884;
  --font-reading:  'Inter', system-ui, sans-serif;
  --measure:       65ch;
  --leading:       1.8;
}

body {
  font-family: var(--font-reading);
  font-size: 1.125rem;
  line-height: var(--leading);
  color: var(--color-text);
  background: var(--color-bg);
  font-optical-sizing: auto;
}

/* Content column: never wider than comfortable reading width */
.content {
  max-width: var(--measure);
  margin-inline: auto;
  padding-inline: 1.5rem;
}

/* No transitions by default */
* { transition: none; }

/* Only transition opacity, only when motion is acceptable */
@media (prefers-reduced-motion: no-preference) {
  .fade-in {
    transition: opacity 250ms ease-in-out;
  }
}

/* Generous section spacing */
section + section { margin-top: 5rem; }
h1, h2, h3 { line-height: 1.25; font-weight: 500; }
h1 { font-size: clamp(1.75rem, 4vw, 2.5rem); }

/* Minimal button */
.btn-calm {
  background: none;
  border: 1px solid currentColor;
  padding: 0.5rem 1.25rem;
  border-radius: 6px;
  font-size: 0.875rem;
  color: var(--color-accent);
  cursor: pointer;
  transition: background 200ms ease-in-out;
}
.btn-calm:hover { background: color-mix(in srgb, var(--color-accent) 10%, transparent); }

/* Dark mode */
@media (prefers-color-scheme: dark) {
  :root {
    --color-bg:   #1A1A18;
    --color-text: #E8E8E4;
    --color-muted: #6A6A66;
  }
}
```

---

# Cross-Style Rules

These apply regardless of which style is selected, on all three platforms.

**Platform conventions are non-negotiable on every platform.** Style is a visual language applied over correct platform behavior. A neo-brutalist iOS app still uses swipe-to-go-back. A futuristic Android app still uses the Material navigation pattern. A kinetic typography web app still respects `prefers-reduced-motion`. A calm web app still has visible focus indicators for keyboard navigation. Style changes appearance, not behavior.

**Web gets the same design completeness as native.** Every screen, every state, every breakpoint. Responsive behavior at Mobile (375-767), Tablet (768-1023), and Desktop (1024+) is not optional. Web designs are not "simplified versions" of the native design -- they are platform-specific implementations of the same design system.

**Accessibility doesn't negotiate on any platform.** Every style must meet 4.5:1 contrast for normal text and 3:1 for large text and interactive elements on iOS, Android, and Web. Hard shadows can fail contrast -- text on a neo-brutalist button must pass against its fill color, not against the shadow. Glassmorphism needs sufficient frost or a CSS `@supports` fallback for environments where `backdrop-filter` isn't supported. Web additionally requires keyboard navigation, visible focus rings, and semantic HTML structure regardless of the visual style.

**Dark mode is required on every platform.** iOS and Android via system preference. Web via `@media (prefers-color-scheme: dark)` and optionally a manual toggle. Design the dark version with the same intentionality as the light version -- it's not an inversion, it's a separate palette.

**Motion respects user preferences everywhere.** iOS/Android: check `accessibilityReduceMotion`. Web: `@media (prefers-reduced-motion: reduce)`. Every animated element needs a non-animated fallback that communicates the same information.

**States are complete on every platform.** Default, hover, pressed/active, focused, disabled, loading, error, empty. Web adds `:hover` and `:focus-visible` as distinct states. Native adds the platform-specific pressed animation (spring collapse on neo-brutalism, etc.). The style doesn't change what states need to exist -- only what they look like.

**Motion tokens match the style across all platforms.** Neo-brutalism: snappy springs (response 0.15-0.2, moderate bounce) or CSS `transition: 100ms` with cubic-bezier that snaps. Organic: gentle easing (0.6s+, no bounce). Futuristic: fast ease-out. Calm: opacity transitions only, 200-250ms. Define motion tokens consistently and reference them on every platform.

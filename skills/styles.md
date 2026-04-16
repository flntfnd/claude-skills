# Design Styles
Visual design language specifications for iOS, iPadOS, macOS, Android, and Web.
Each style defines token modifications, component rules, and native implementation per platform.

---

# How to Use This File

The styles in this file are explicit overrides. They are chosen deliberately and applied intentionally. They are not defaults.

**When no style is specified, the correct answer is native.** iOS apps look like Apple built them. Android apps look like Google built them. Windows apps look like Microsoft built them. That means Liquid Glass, SF Pro, and Apple HIG on iOS; Material 3 Expressive, dynamic color, and Roboto Flex on Android; Fluent Design, Mica, and Segoe UI Variable on Windows. Native is not a style -- it's the baseline that every style in this file intentionally departs from.

When a style IS specified, a project has exactly one. Pick it before touching tokens. The style determines how the token system is weighted and what the component visual language looks like. The underlying token architecture stays constant -- this file tells you how to populate it.

**Applying a style is not a token swap.** Changing colors and font weights while keeping the same component structure, layout rhythm, and spacing logic is not applying a style -- it's repainting the same design. Each style in this file requires structural changes: different component patterns (cards vs lists vs raw type), different layout logic (tight grid vs generous breathing room vs confrontational density), different interaction behaviors (hard-shadow press-collapse vs hairline hover vs none). If your Neo-Brutalism and Neo-Minimalism implementations share the same component structure and you've only changed CSS variables, you haven't applied Neo-Brutalism.

The test: if someone sees a thumbnail of the design and can't immediately identify the style, the implementation is wrong. Each style has a visual signature that should be recognizable at a glance. Read the Visual Signature section of the chosen style first -- if your implementation doesn't match it, fix the structure before touching tokens.

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

## Visual Signature

Identifiable at a glance by: large areas of warm off-white breathing room, serif display type at light weight, zero card borders, content separated by space alone or hairline rules (never full borders or shadows). Navigation is nearly invisible -- no background fill, no border, just a name and minimal links against the warm white. Lists of items sit on the page with space between them, not boxed into cards.

**Structural requirements for common patterns:**
- Navigation: text-only, no background, no border, floats above content
- Hero: oversized serif display type at light (300) weight, significant vertical padding above and below, subtext in regular-weight sans at comfortable reading size
- Content lists (work, features, etc.): items separated by a single 0.5-1px warm-tinted hairline divider or by space only -- no borders wrapping items, no card backgrounds
- Sections: delineated by whitespace and a hairline rule if needed, not by background color changes or cards
- CTAs: text links or minimal outlined buttons -- never filled contained buttons for secondary actions

**Wrong if:** any component has a visible box/card border, shadows appear anywhere, the spacing feels tight, typography is all sans-serif, backgrounds are pure white (#FFFFFF) rather than warm off-white.

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

## Visual Signature

Identifiable at a glance by: extreme typographic scale contrast (display text at 6-8rem next to body text at 1rem, nothing in between), heavy horizontal rules as the only structural dividers, monospace or raw grotesque type, no shadows anywhere, no rounded corners, no color beyond black/white and at most one stark accent. The layout looks like a well-designed HTML document -- functional, intentional, no chrome. It should feel slightly confrontational.

**Structural requirements for common patterns:**
- Navigation: plain text, no background, no border, no padding -- just the name and links at the top of the document flow. Could be a simple flex row with a `border-bottom: 1px solid #000` or nothing at all.
- Hero: massive display type (clamp(3rem, 10vw, 8rem)), light or regular weight, running across the full column. Subtext in small body size. No background fill. Heavy `<hr>` below.
- Content lists: either a raw table (column headers, data rows, no styling), or items separated only by a 1-2px `border-bottom: 1px solid #000`. No card containers, no shadows, no backgrounds on rows.
- Sections: separated exclusively by `<hr>` (1-2px solid black) with generous vertical margin. No background color changes. No cards or containers.
- Links/CTAs: underlined text. On hover: background/color invert (`background: #000; color: #fff`). No buttons with fills.

**Wrong if:** any element has a box-shadow, any corner has border-radius, colors beyond black/white/one-accent appear, the typography scale feels moderate (no extreme contrast between large and small sizes), any section has a background fill.

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

## Visual Signature

Identifiable at a glance by: navigation bars, tab bars, and toolbars that are translucent -- you can see content scrolling beneath them. The glass material bends and refracts what's behind it. Content is rich and colorful, with the navigation chrome floating above it rather than sitting on a separate opaque surface. Everything below the navigation layer fills edge-to-edge.

**Wrong if:** the navigation bar has a solid opaque background fill, content doesn't extend behind the glass layer, or glass treatment is applied to content-level elements (list rows, cards, images). Glass is navigation-layer only. On web, this style is not achievable -- use Glassmorphism (style #5) instead. Full implementation details in `~/.claude/skills/APPLE.md`.

**On Web**: Liquid Glass as Apple defines it (real-time lensing, specular response to device motion) is not achievable in a browser. Use the Glassmorphism / Frosted style (style #5) for web surfaces that need the same depth and translucency intent. The Figma Glass effect with Refraction and Frost parameters approximates the visual for mockups, but the web implementation falls back to `backdrop-filter: blur()` with appropriate fill opacity and inner highlight stroke.

**Known usability failure modes** (documented by NN/g and others in iOS 26's release): text placed over glass controls that sits on top of other text becomes unreadable; glass navigation bars that blend into complex wallpapers become invisible; overuse of motion and physics in the glass layer creates an interface that competes with content for attention rather than supporting it. These are failure modes to avoid, not examples to follow.

Token and implementation details for native: `~/.claude/skills/APPLE.md`.

---

# 5. Glassmorphism / Frosted

The static, web-native sibling of Liquid Glass. Translucent surfaces with background blur, inner highlight strokes, and subtle depth. Unlike Liquid Glass, there's no real-time lensing -- the effect is achieved through blur and opacity. Still contemporary and premium when not overused.

**When to use**: Web dashboards, marketing sites, landing pages, Android apps where a premium translucent aesthetic is called for. On iOS, use Liquid Glass instead.

## Visual Signature

Identifiable at a glance by: cards and panels that show blurred content through them (`backdrop-filter: blur(16px)`), thin inner-highlight border (1px white at 25% opacity on top edge), a rich layered background (gradient, imagery, or deep color) showing through every glass surface. The page background is always rich -- solid white or grey kills the effect entirely. Everything floats.

**Structural requirements:**
- Background: a vivid gradient, hero image, or deep-color field behind ALL content. Glass over flat white renders as plain opaque white. This is not optional. In Figma: place a rich gradient or image frame behind all glass surfaces.
- Cards/panels: In Figma: Fill = white at 12% opacity. Background Blur effect = 16px. Stroke = 1px white at 25% opacity, inside position. Drop Shadow for depth. The frame MUST sit over the rich background layer, not over a flat surface.
- Navigation: glass bar floating above the hero image/gradient. In Figma: nav frame uses same glass fill/blur treatment, positioned over the hero.
- Sections: layered depth -- items closer to the viewer are more opaque, background items more transparent.

**Wrong if:** there is no rich background content for glass to blur (glass over flat white is invisible), any card fill is 100% opaque, the Background Blur effect is missing, there are hard dark strokes instead of semi-transparent white ones.

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

## Visual Signature

Identifiable at a glance by: everything is the SAME background color -- there are no borders, no background changes between sections, no surface hierarchy through color. Depth is created exclusively through dual shadows. Buttons look physically raised. Pressed/active states look physically pushed in (inset shadow). The whole interface is one tone, modulated only by shadow.

**Structural requirements:**
- Background: a single base color everywhere. Every surface -- page, cards, buttons -- uses this same color. In Figma: set the page background and every frame fill to the exact same color variable. No surface should use a different fill value.
- Raised elements: In Figma: Drop Shadow 1 (X:-4, Y:-4, Blur:8, Color:#FFFFFF, Opacity:70%) + Drop Shadow 2 (X:4, Y:4, Blur:8, Color:#000000, Opacity:20%). No stroke. No fill different from the base color.
- Pressed/active: In Figma prototype: on press, swap to an Inner Shadow variant (Inner Shadow X:2, Y:2, Blur:6, #000 20% + Inner Shadow X:-2, Y:-2, Blur:6, #FFF 70%). Elements push in on interaction.
- No borders anywhere. No color fills on buttons. The dual shadow IS the affordance.

**Wrong if:** any surface uses a different fill color from the base, any element has a visible stroke, any shadow is a single directional shadow rather than the dual light/dark pair.

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

## Visual Signature

Identifiable at a glance by: oversized display type that animates on entry or scroll, with supporting content revealed progressively. Type is the layout -- there are no traditional card containers or image heroes. On scroll, words or characters reveal themselves. The page feels alive through typographic motion, not graphic elements.

**Structural requirements:**
- Hero: oversized display text (72-120px) that animates in. Characters reveal via clip/translateY animation or weight-axis transition. No static hero image as the primary element.
- Content reveals: scroll-triggered character/word/line stagger animations. Text arrives with purpose -- ease-out or spring, not linear.
- Layout: type-first. Cards and containers are minimal or absent. White space is generous specifically to give moving type room.
- Reduce motion fallback: all animations replaced with opacity fade. Content must be fully readable and functional without any motion.

**Wrong if:** the page looks identical with animations disabled (motion is decoration, not structure), text is static at all scroll positions, layout relies on traditional image/card structure with type as a secondary element.

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

## Visual Signature

Identifiable at a glance by: the entire page content organized into a grid of variably-sized rounded-corner tiles. The grid IS the layout -- there is no traditional linear section flow. One or two large tiles dominate, surrounded by smaller tiles. Size communicates hierarchy. The background between tiles shows through as negative space.

**Structural requirements:**
- Layout: CSS Grid with explicit column/row template. ALL content lives inside tiles. No free-flowing content outside the grid.
- Tile sizes: at minimum three distinct sizes (large 2x2, medium 2x1, small 1x1). Equal-size grids are not Bento -- they're card grids.
- Radius: generous and consistent. 20-32px on all tiles. Same radius on every tile.
- Gap: 12-20px between tiles, visually evident, matching the background color.
- Featured tile: the largest cell uses a brand or accent color background and contains the highest-priority content.
- Content per tile: one concept per tile. A tile with a metric, a tile with a stat, a tile with an action. Not mixed content.

**Wrong if:** tiles are all the same size, content flows in a linear column outside the grid, there's no clear size hierarchy between tiles, radius is inconsistent between tiles.

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

## Visual Signature

Identifiable at a glance by: an explicit column grid that's visible and respected, serif headline type paired with dense body text, horizontal rules as structural dividers, information density that reads like a newspaper or magazine spread. Multiple typographic sizes coexisting on the same screen without feeling chaotic because the hierarchy is rigorous.

**Structural requirements:**
- Layout: explicit CSS Grid with visible column logic. At least a two-column content area. Grid structure is apparent.
- Typography: serif display type (Canela, Libre Caslon, Playfair, or system serif). Body text at 16-18px with 1.6-1.8 line height. Caption text at 11-12px with letter-spacing. Multiple type sizes visible simultaneously.
- Dividers: hairline horizontal rules (`border-top: 1px solid`) as the primary structural element between sections and content groups.
- No card containers: content sits in columns, separated by rules and whitespace, not boxed into cards.
- Section labels: small-caps or uppercase, tracked out (`letter-spacing: 0.08-0.15em`), 11-12px.

**Wrong if:** typography is all one size or all sans-serif, layout is a single centered column with no visible grid logic, sections are separated by background-color blocks rather than rules and whitespace, the design lacks information density.

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

## Visual Signature

Identifiable at a glance by: blob-shaped background elements and card containers (CSS `border-radius` values above 40%, or SVG clip-paths), soft gradient fills that shift between nature-derived colors, asymmetric layouts where elements don't align to a strict grid, and an overall sense of warmth and imperfection.

**Structural requirements:**
- Cards and containers: irregular border-radius (e.g., `border-radius: 60% 40% 70% 30% / 40% 60% 30% 70%`) or SVG clip-path blobs. NOT standard rectangles with soft corners.
- Background: gradient blobs or organic shapes as decorative background layers. Multiple layered `radial-gradient` at low opacity, or SVG blob elements positioned behind content.
- Color: nature palette. No pure black, no pure white, no corporate blues. Warm earth tones, botanical greens, soft terracotta.
- Layout: intentionally asymmetric. Text columns offset rather than centered, elements that don't snap to a strict grid.

**Wrong if:** containers are rectangles (even with large radius), layout is symmetrically grid-aligned, colors are standard corporate/tech palette, background is a flat solid color with no gradient or organic shapes.

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

## Visual Signature

Identifiable at a glance by: surfaces that visually feel like they have physical material -- paper, linen, grain, concrete. Not photorealistic, but clearly not flat digital. A grain/noise overlay at 3-6% opacity over gradients or solid backgrounds is the minimum. More intense textures (paper grain, fabric weave patterns via CSS) for specific surfaces.

**Structural requirements:**
- Global grain: SVG `feTurbulence` filter or CSS noise overlay at 3-5% opacity applied to the page background. Without this, the style isn't applied.
- Surface differentiation: different texture intensities for different surfaces. Page background: subtle (3%). Cards: slightly more visible (5-7%). Hero elements: most pronounced.
- Color: warm or earthy. Flat, pure colors fight the texture. Slightly desaturated, slightly warm palette that reads as "printed" rather than "emitted".
- Typography: warm-weight, humanist sans or serif. Crisp but not sterile.

**Wrong if:** backgrounds and surfaces are flat solid colors or clean gradients with no grain overlay, the design looks like any other clean flat-design execution with slightly warm colors.

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

## Visual Signature

Identifiable at a glance by: CRT-green or amber monochrome terminal palette (or Windows 3.1 bevel-border chrome), scanline overlay, monospace type throughout, and at least one overtly retro structural element (beveled borders, blinking cursor, terminal-style text rendering, pixelated elements). Should make someone who lived through the early internet immediately feel nostalgia.

**Structural requirements:**
- Color scheme: commit to one era. Terminal (near-black + phosphor green or amber). OR Windows 3.1 (grey chrome + blue title bars + bevel borders). OR early web (primary colors, Times New Roman, inline borders).
- Scanlines: CSS `repeating-linear-gradient` overlay at 5-8% opacity on the page background. Must be present -- it's the most recognizable element.
- Typography: `font-family: 'JetBrains Mono', 'Courier New', monospace` everywhere. No proportional sans-serif.
- Structural element: at least one of -- bevel-border UI chrome (box-shadow for raised/sunken effect), blinking text cursor, terminal prompt indicator (`>`), or pixelated/dithered decorative element.

**Wrong if:** the type is a proportional sans-serif, there are no scanlines, the color palette is contemporary tech (dark grey, blue accent), nothing reads as explicitly retro-computational.

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

## Visual Signature

Identifiable at a glance by: extreme whitespace (padding and margins 1.5-2x what you'd use in any other style), a single muted accent color used extremely sparingly (one or two places maximum), generous line-height and letter-spacing that makes reading feel unhurried, and a near-total absence of UI chrome. Navigation almost disappears. There are no badges, indicators, unread counts, or notification-style elements. The content is everything; the interface is almost nothing.

**Structural requirements:**
- Spacing: double the base spacing scale. If the default is 24px between sections, this is 48px. The whitespace IS the design.
- Typography: large base size (18-20px body), generous line-height (1.7-1.9), moderate tracking. Type should invite extended reading.
- Color: maximum two colors in use at any time -- near-black text, near-white background, and one muted accent used only for the single most important interactive element. Nothing else.
- Navigation: minimal to invisible. A small logo or title, one or two links. No background, no border, no weight. Should feel like it might not be there.
- Interactive elements: single underline or color change on hover. No filled buttons for secondary actions. No icons unless they're the only possible representation.
- Motion: near-zero. If anything animates, it's a slow opacity fade (300-500ms ease). No spring physics, no transforms, no scroll animations.
- No: badges, unread counts, notification dots, progress bars for non-essential tasks, tooltips that appear unprompted, any element that bids for attention.

**Wrong if:** anything bids for the user's attention beyond the primary content, there is more than one accent color, spacing feels "normal" rather than exceptionally generous, navigation has visual weight, any element animates with spring physics or transforms.

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

# Style-to-Technique Mapping

Each style has specific rendering techniques that produce its signature visual effects. These are not optional embellishments -- they are what makes the style recognizable. Standard CSS and stock components are insufficient for most of these. The techniques below are what separate a hand-crafted implementation from a token swap.

Implementation details for all techniques are in:
- `~/.claude/skills/MOTION.md` -- Three.js, WebGL, shaders, GSAP, post-processing
- `~/.claude/skills/WEB.md` -- blend modes, clip-path, Canvas 2D, SVG filters, custom cursor
- `~/.claude/skills/APPLE.md` -- SwiftUI Canvas, Metal shaders, custom Animatable
- `~/.claude/skills/ANDROID.md` -- Compose Canvas, AGSL, RenderEffect
- `~/.claude/skills/WINDOWS.md` -- Win2D, CompositionAPI, ExpressionAnimation

---

## 1. Neo-Minimalism
**Web**: CSS `mix-blend-mode: multiply` on a grain texture overlay (3-4% opacity) over warm gradients. SVG `feTurbulence` filter for the noise. `backdrop-filter: blur(1px)` on navigation. View Transitions API for page changes -- slow, opacity-based.

**iOS**: SwiftUI Canvas for any decorative background elements. `.animation(.easeInOut(duration: 0.5))` everywhere -- nothing snappy.

**Android**: Compose Canvas for grain overlays. `graphicsLayer { alpha = ... }` for fade-in reveals. No spring animations.

**Windows**: Mica background. Win2D for any procedural texture. `ScalarKeyFrameAnimation` with `EasingFunctionFactory.CreateCubicBezierEasingFunction` for slow, deliberate transitions.

**Signature GPU technique**: SVG `feTurbulence` noise at low opacity blended via `multiply`. Everything else is restraint -- fewer effects, not more.

---

## 2. Neo-Brutalism
**Web**: CSS `box-shadow: 4px 4px 0 0 #000` with blur: 0 on every interactive element. GSAP `to(element, { boxShadow: '0px 0px 0 0 #000', x: 4, y: 4, duration: 0.08 })` on press. No blurs, no gradients, no WebGL -- the style is about restraint in a different direction: everything is flat and physical.

**iOS**: SwiftUI `shadow(color: .black, radius: 0, x: 4, y: 4)`. On press: `offset(x: 4, y: 4)` with `.animation(.spring(response: 0.12, dampingFraction: 0.5))` -- snap to the shadow position.

**Android**: `drawBehind` for the offset fill shadow (blur=0, solid black). `Animatable` or `animateFloatAsState` for the press-translate.

**Windows**: `DropShadowEffect` with `ShadowDepth: 0, Direction: 135, BlurRadius: 0`. Win2D for the offset shadow on canvas elements.

**Signature GPU technique**: None -- the style deliberately avoids GPU effects. The physical press-collapse interaction is the signature. Implement it correctly on every platform.

---

## 3. Brutalism (Pure)
**Web**: No GPU effects. The entire style runs on document flow and typography. GSAP is overkill here -- CSS `transition: background-color 0.1s` on links (invert on hover) is correct. If any animation exists, it's a link hover inversion.

**Signature GPU technique**: None intentionally. Any GPU effect immediately breaks the style.

---

## 4. Liquid Glass
**Web**: Not achievable. See style #5.

**iOS**: `.glassEffect()` modifier. All native -- no custom Metal needed. Post-processing in Three.js would be wrong here.

**Signature GPU technique**: Apple's own Liquid Glass rendering engine. Don't replicate it -- use the native API.

---

## 5. Glassmorphism / Frosted
**Web**: `backdrop-filter: blur(16px) saturate(1.4)`. Requires a rich background -- use a Three.js canvas behind the DOM (fixed, z-index: 0) with a slow-moving gradient or particle field for maximum depth. GSAP ScrollTrigger to evolve the background as the user scrolls. CSS `mix-blend-mode: overlay` on highlight strokes.

**Three.js background for glass**: Slow-moving color gradient mesh. `MeshStandardMaterial` with a dark color, point lights that pulse gently. The background needs to be interesting enough that the glass effect reads.

**iOS**: `.ultraThinMaterial` / `.regularMaterial`. System-provided.

**Android**: `RenderEffect.createBlurEffect(16f, 16f)` + `graphicsLayer { renderEffect = ... }`.

**Windows**: Acrylic backdrop brush via `DesktopAcrylicBackdrop`.

**Signature GPU technique (Web)**: Three.js or Canvas 2D animated background that the CSS glass layers blur over. Without a dynamic background, glass is invisible.

---

## 6. Neumorphism / Soft UI
**Web**: CSS dual `box-shadow` (no WebGL needed). `box-shadow: -4px -4px 8px rgba(255,255,255,0.7), 4px 4px 8px rgba(0,0,0,0.2)`. All same base color. `filter: drop-shadow` on SVG icons for consistent rendering. No GPU effects -- the style is pure CSS shadow work.

**iOS**: Dual SwiftUI `.shadow()` modifiers (light upper-left, dark lower-right). `.drawingGroup()` on complex nested shadows to prevent rendering artifacts.

**Android**: `drawBehind` with two `drawRoundRect` calls (offset for each shadow direction).

**Signature GPU technique**: None -- CSS box-shadow only. Complexity comes from the dual shadow system and consistent base color discipline.

---

## 7. Kinetic Typography
**Web**: GSAP SplitText for character/word/line decomposition. `ScrollTrigger` for scroll-driven reveals. `stagger` values from MOTION.md. CSS `animation-timeline: scroll()` for simple cases. Variable font weight animation: `font-variation-settings: 'wght' ${value}` animated via GSAP or CSS.

**Three.js text**: `TextGeometry` (requires FontLoader) for 3D text that responds to scroll or mouse. Use sparingly -- 3D text in Three.js is complex and has significant performance cost.

**iOS**: `TimelineView` + `withAnimation` for scroll-triggered character reveals. SwiftUI's `contentTransition(.numericText())` for number transitions.

**Android**: Roboto Flex `FontVariation.weight()` animation via `animateFloatAsState`. Character stagger via `LaunchedEffect` with `delay`.

**Signature GPU technique (Web)**: GSAP SplitText + stagger. Variable font axis animation. The motion IS the style -- without it there is no style.

---

## 8. Futuristic / Sci-Fi
**Web**: Three.js with post-processing is the correct implementation. `UnrealBloomPass` for glowing elements. Grid fragment shader (see MOTION.md). Particle system with `AdditiveBlending`. CSS `text-shadow` for 2D glow on text -- `0 0 8px var(--accent), 0 0 20px var(--accent)`. Custom cursor with `mix-blend-mode: difference`.

**Three.js full setup**: Scene + grid shader plane + bloom post-processing + particle field + GSAP ScrollTrigger for camera movement. This is the only style where Three.js WebGL is essentially required to achieve the correct visual.

**iOS**: Metal `.colorEffect()` shader for scanline/glow on specific surfaces. SwiftUI Canvas for particle fields. `TimelineView(.animation)` for continuous animation.

**Android**: AGSL shader for glow and grid effects. `RenderEffect` chain (blur + color matrix) for bloom approximation.

**Windows**: Win2D for the grid plane and particle system. `CompositionColorBrush` with animated `Color` for pulsing accent elements.

**Signature GPU technique**: `UnrealBloomPass` (web) or equivalent glow shader (native). Without the bloom, neon elements look flat. Particles with `AdditiveBlending` for the energy field feel.

---

## 9. Bento Grid
**Web**: CSS Grid for layout (no WebGL). GSAP for tile hover lift (`y: -4, boxShadow: '...'`). View Transitions API for smooth tile expand/collapse if tiles open into detail views. `clip-path` animations on featured tile if it expands.

**iOS**: SwiftUI `LazyVGrid` + `matchedGeometryEffect` for tile expand transitions. `.spring(response: 0.35, dampingFraction: 0.7)` on hover/tap.

**Android**: `LazyVerticalGrid` + `AnimatedContent` for tile state changes.

**Signature GPU technique**: None heavy. The focus is CSS Grid layout precision and spring animations on interactions. `matchedGeometryEffect` (iOS) and shared element transitions (Android) for tile-to-detail.

---

## 10. Editorial / Structural
**Web**: SVG for decorative rule elements. GSAP for scroll-triggered text reveals (line by line, not character by character -- this is editorial, not kinetic). CSS `clip-path` wipe reveals for section entry. No Three.js.

**iOS**: SwiftUI Canvas for custom rule/divider elements. `.transition(.opacity.combined(with: .move(edge: .bottom)))` for content reveals.

**Signature GPU technique**: CSS clip-path wipe reveals timed to scroll (ScrollTrigger, scrub). Decorative SVG ruled elements. No GPU effects beyond these -- editorial aesthetic means restraint.

---

## 11. Organic / Biomorphic
**Web**: SVG `feTurbulence` + `feDisplacementMap` for liquid distortion on images/hover. Canvas 2D for animated blob backgrounds (noise-based organic shapes -- see WEB.md). `clip-path` with animated polygon for organic container shapes. CSS `mix-blend-mode: multiply` for color blending on layered organic shapes.

**Three.js (optional)**: Noise-displaced geometry (see MOTION.md vertex shader). `SimplexNoise` applied to sphere/plane geometry for organic 3D forms.

**iOS**: SwiftUI Canvas with noise-based animated blob shapes. `TimelineView` for continuous animation. Custom `Shape` conformance with organic bezier curves.

**Android**: Compose Canvas with noise-displaced path drawing. AGSL turbulence shader for background texture.

**Signature GPU technique**: SVG `feTurbulence` + `feDisplacementMap` for the liquid/organic distortion feel (web). Canvas 2D or Three.js noise-displaced shapes for animated organic forms.

---

## 12. Texture / Tactile
**Web**: SVG `feTurbulence` filter referenced via CSS `filter: url(#noise)`. Applied as `::after` pseudo-element at 3-5% opacity with `mix-blend-mode: multiply` or `overlay`. This is the minimum required implementation -- without it the style is not applied. Canvas 2D for more complex procedural textures.

**iOS**: SwiftUI Canvas drawing a noise pattern as background. Or: use a pre-rendered noise PNG at low opacity. `.drawingGroup()` for performance.

**Android**: AGSL turbulence shader. Or pre-rendered noise texture as `Painter` at low alpha.

**Windows**: Win2D `TurbulenceEffect` -- see WINDOWS.md for the exact implementation.

**Signature GPU technique**: SVG `feTurbulence` (web) / AGSL turbulence (Android) / Win2D `TurbulenceEffect` (Windows). The grain texture IS the style -- without it there is no Texture/Tactile.

---

## 13. Y2K / Retro Computing
**Web**: Three.js `FilmPass` for scanlines if using WebGL. CSS `repeating-linear-gradient` for pure-CSS scanlines. Custom fragment shader for the full CRT effect (barrel distortion, chromatic aberration, phosphor glow) -- see MOTION.md for the complete shader. CSS `filter: contrast(1.1) brightness(0.9)` as a minimal approximation. Monospace font throughout.

**Three.js**: The CRT shader as a `ShaderPass` in post-processing gives the most authentic result. The barrel distortion alone is enough to signal CRT without heavy performance cost.

**iOS**: Custom Metal fragment shader via `.colorEffect()` for CRT-style color treatment. SwiftUI Canvas for scanline overlays.

**Android**: AGSL shader for chromatic aberration and scanlines.

**Signature GPU technique**: CRT post-processing shader (barrel distortion + chromatic aberration + scanlines + phosphor tint). At minimum: CSS scanlines + monospace typography. Full implementation requires a custom GLSL/AGSL/Metal shader.

---

## 14. Calm / Anti-Distraction
**Web**: No GPU effects. CSS `opacity` transitions only (200-300ms). `prefers-reduced-motion` respected by default since there's barely any motion to begin with. No Three.js, no GSAP (or minimal GSAP for slow fade sequences only). The absence of technique is the technique.

**iOS**: `.animation(.easeInOut(duration: 0.3))` on opacity only. No spring physics. No Canvas or Metal.

**Android**: `fadeIn()` + `fadeOut()` transitions only. No `spring()`.

**Signature GPU technique**: None -- deliberately. Any GPU effect or complex animation is a failure of the style.

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

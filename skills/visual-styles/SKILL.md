---
name: visual-styles
description: Reference for 14 distinct visual design languages for iOS, iPadOS, macOS, Android, and Web — Neo-Minimalism, Neo-Brutalism, Brutalism Pure, Liquid Glass, Glassmorphism/Frosted, Neumorphism/Soft UI/Claymorphism, Kinetic Typography, Futuristic/Sci-Fi, Bento Grid, Editorial/Structural, Organic/Biomorphic, Texture/Tactile, Y2K/Retro Computing, and Calm/Anti-Distraction. Use whenever a UI, screen, mockup, component, or design system needs an explicit, deliberate style applied instead of native platform defaults — e.g. "make this neo-brutalist," "add a glassmorphism card," "give this a bento grid layout," "retro CRT terminal look," "claymorphism button," "kinetic type hero," "make this feel calm/distraction-free." Each style has its own reference file with token modifications, component rules, "wrong if" checklists, and native iOS/Android/Web implementation code (SwiftUI, Compose, CSS). Load the specific style's reference file, not the whole set, once the target style is known.
---

# Visual Styles

Visual design language specifications for iOS, iPadOS, macOS, Android, and Web. Each style defines token modifications, component rules, and native implementation per platform.

## How to Use This File

The styles here are explicit overrides. They are chosen deliberately and applied intentionally. They are not defaults.

**When no style is specified, the correct answer is native.** iOS apps look like Apple built them. Android apps look like Google built them. Windows apps look like Microsoft built them. That means Liquid Glass, SF Pro, and Apple HIG on iOS; Material 3 Expressive, dynamic color, and Roboto Flex on Android; Fluent Design, Mica, and Segoe UI Variable on Windows. Native is not a style -- it's the baseline that every style in this file intentionally departs from.

When a style IS specified, a project has exactly one. Pick it before touching tokens. The style determines how the token system is weighted and what the component visual language looks like. The underlying token architecture stays constant -- the chosen style's reference file tells you how to populate it.

**Applying a style is not a token swap.** Changing colors and font weights while keeping the same component structure, layout rhythm, and spacing logic is not applying a style -- it's repainting the same design. Each style requires structural changes: different component patterns (cards vs lists vs raw type), different layout logic (tight grid vs generous breathing room vs confrontational density), different interaction behaviors (hard-shadow press-collapse vs hairline hover vs none). If a Neo-Brutalism and a Neo-Minimalism implementation share the same component structure and only the CSS variables changed, Neo-Brutalism hasn't actually been applied.

The test: if someone sees a thumbnail of the design and can't immediately identify the style, the implementation is wrong. Each style has a visual signature that should be recognizable at a glance. Read the Visual Signature section of the chosen style's reference file first -- if the implementation doesn't match it, fix the structure before touching tokens.

Every style listed here applies equally to iOS, Android, and Web. All three are first-class targets. Each reference file contains implementation details for all three platforms.

On native platforms: implement with platform-native APIs. No web-views, no visual approximations. If the style calls for a hard shadow, that's a SwiftUI `shadow()` modifier or a Compose `drawBehind` -- not a dropped PNG.

On Web: implement with CSS custom properties, modern layout (Grid, Flexbox), and native browser APIs. No canvas hacks for effects CSS handles natively. No JavaScript for animations that CSS handles natively. Performance and accessibility are not optional on any platform.

**Color values are generic placeholders.** Every hex/token value in every reference file is a reasonable generic default for that style, not a verified personal preference. A dedicated personal-taste extraction (`TASTE.md`) has not been built yet; once it exists, it overrides the specific color values in these files.

## Quick Reference

| Style | Visual signature (one line) | Reference |
| --- | --- | --- |
| 1. Neo-Minimalism | Warm off-white breathing room, light-weight serif display type, zero borders, hairline dividers | [neo-minimalism.md](reference/neo-minimalism.md) |
| 2. Neo-Brutalism | Hard offset flat shadows, thick black borders, brand-color fills, press-collapse interaction | [neo-brutalism.md](reference/neo-brutalism.md) |
| 3. Brutalism (Pure) | Extreme type-scale contrast, heavy horizontal rules, no shadows, no radius, near-monochrome | [brutalism-pure.md](reference/brutalism-pure.md) |
| 4. Liquid Glass | Apple-native translucent navigation layer that refracts scrolling content beneath it (iOS/iPadOS/macOS only) | [liquid-glass.md](reference/liquid-glass.md) |
| 5. Glassmorphism / Frosted | Blurred translucent cards over a rich background, thin white highlight stroke, web-native glass | [glassmorphism.md](reference/glassmorphism.md) |
| 6. Neumorphism / Soft UI | Single background color everywhere, depth from dual light/dark shadows only, no borders; Claymorphism adds inner glow | [neumorphism.md](reference/neumorphism.md) |
| 7. Kinetic Typography | Oversized display type as the layout itself, character/word/line stagger reveals on scroll or entry | [kinetic-typography.md](reference/kinetic-typography.md) |
| 8. Futuristic / Sci-Fi | Near-black background, neon glow accents, monospace data readouts, visible low-opacity grid | [futuristic-scifi.md](reference/futuristic-scifi.md) |
| 9. Bento Grid | Variably-sized rounded tiles in an explicit grid, one or two featured cells carry brand color | [bento-grid.md](reference/bento-grid.md) |
| 10. Editorial / Structural | Visible column grid, serif headlines with dense body text, hairline rules as structure, no cards | [editorial-structural.md](reference/editorial-structural.md) |
| 11. Organic / Biomorphic | Blob-shaped containers, irregular border-radius or SVG clip-paths, asymmetric layout, nature palette | [organic-biomorphic.md](reference/organic-biomorphic.md) |
| 12. Texture / Tactile | Grain/noise overlay (3-6% opacity minimum) over every surface, warm desaturated "printed" palette | [texture-tactile.md](reference/texture-tactile.md) |
| 13. Y2K / Retro Computing | CRT scanlines, monospace throughout, terminal-green/amber or Windows 3.1 bevel chrome | [y2k-retro-computing.md](reference/y2k-retro-computing.md) |
| 14. Calm / Anti-Distraction | Extreme whitespace (1.5-2x normal), single muted accent, near-invisible navigation, near-zero motion | [calm-anti-distraction.md](reference/calm-anti-distraction.md) |

## Style-to-Technique Mapping

Each style has specific rendering techniques that produce its signature visual effects. These are not optional embellishments -- they are what makes the style recognizable. Standard CSS and stock components are insufficient for most of these. The techniques below are what separate a hand-crafted implementation from a token swap.

Implementation details for all techniques referenced below live in this skill library's sibling files:
- `motion.md` -- Three.js, WebGL, shaders, GSAP, post-processing
- `web.md` -- blend modes, clip-path, Canvas 2D, SVG filters, custom cursor
- `apple.md` / `apple-platform` -- SwiftUI Canvas, Metal shaders, custom Animatable
- `android.md` -- Compose Canvas, AGSL, RenderEffect
- `windows.md` / `windows-platform` -- Win2D, CompositionAPI, ExpressionAnimation

**1. Neo-Minimalism** -- Web: `mix-blend-mode: multiply` on a grain overlay (3-4% opacity) over warm gradients, SVG `feTurbulence` for the noise, `backdrop-filter: blur(1px)` on nav, View Transitions API for slow opacity-based page changes. iOS: SwiftUI Canvas for decorative elements, `.animation(.easeInOut(duration: 0.5))` everywhere -- nothing snappy. Android: Compose Canvas for grain, `graphicsLayer { alpha = ... }` fades, no springs. Windows: Mica background, Win2D for procedural texture, cubic-bezier `ScalarKeyFrameAnimation` for slow transitions. **Signature technique**: low-opacity `feTurbulence` noise blended via `multiply` -- otherwise, restraint, not more effects.

**2. Neo-Brutalism** -- Web: `box-shadow: 4px 4px 0 0 #000` (blur: 0) on every interactive element; GSAP collapses it to `0px 0px 0 0` with a 4px translate on press, 0.08s. No blurs, no gradients, no WebGL. iOS: `shadow(color: .black, radius: 0, x: 4, y: 4)`, snap to shadow position on press via `.spring(response: 0.12, dampingFraction: 0.5)`. Android: `drawBehind` for the offset solid-black fill shadow, `animateFloatAsState` for the press-translate. Windows: `DropShadowEffect` with `BlurRadius: 0`. **Signature technique**: none -- the style deliberately avoids GPU effects. The physical press-collapse interaction is the signature; implement it correctly on every platform.

**3. Brutalism (Pure)** -- Web: no GPU effects at all; the style runs on document flow and typography. `transition: background-color 0.1s` on link hover-invert is the only motion that belongs here. **Signature technique**: none, intentionally. Any GPU effect immediately breaks the style.

**4. Liquid Glass** -- Web: not achievable; use Glassmorphism instead. iOS: `.glassEffect()` modifier, fully native -- no custom Metal needed, and Three.js-style post-processing would be wrong here. **Signature technique**: Apple's own Liquid Glass rendering engine. Don't replicate it -- use the native API.

**5. Glassmorphism / Frosted** -- Web: `backdrop-filter: blur(16px) saturate(1.4)` needs a rich background; use a Three.js canvas behind the DOM (fixed, `z-index: 0`) with a slow-moving gradient or particle field, GSAP ScrollTrigger to evolve it on scroll, `mix-blend-mode: overlay` on highlight strokes. A `MeshStandardMaterial` gradient mesh with gently pulsing point lights is a good default background. iOS: `.ultraThinMaterial` / `.regularMaterial` (system-provided). Android: `RenderEffect.createBlurEffect(16f, 16f)` + `graphicsLayer { renderEffect = ... }`. Windows: Acrylic backdrop brush via `DesktopAcrylicBackdrop`. **Signature technique (Web)**: an animated Three.js/Canvas 2D background for the CSS glass layer to blur over -- without a dynamic background, glass is invisible.

**6. Neumorphism / Soft UI** -- Web: dual CSS `box-shadow` only, no WebGL needed; `filter: drop-shadow` on SVG icons for consistent rendering. iOS: dual SwiftUI `.shadow()` modifiers (light upper-left, dark lower-right), `.drawingGroup()` on complex nested shadows to prevent rendering artifacts. Android: `drawBehind` with two offset `drawRoundRect` calls. **Signature technique**: none -- pure CSS box-shadow work. Complexity is in the dual-shadow system and consistent base-color discipline.

**7. Kinetic Typography** -- Web: GSAP SplitText for character/word/line decomposition, `ScrollTrigger` for scroll-driven reveals, `stagger` values as documented in `motion.md`; CSS `animation-timeline: scroll()` for simple cases (**[Unverified]** not yet Baseline as of mid-2026 -- Firefox stable still ships it behind a flag, so wrap it in `@supports` and keep a GSAP ScrollTrigger fallback where Firefox coverage matters). Variable font-weight animation via `font-variation-settings: 'wght' ${value}`. Three.js `TextGeometry` for 3D text is available but expensive -- use sparingly. iOS: `TimelineView` + `withAnimation` for scroll-triggered reveals, `contentTransition(.numericText())` for number transitions. Android: Roboto Flex `FontVariation.weight()` via `animateFloatAsState`, stagger via `LaunchedEffect` + `delay`. **Signature technique (Web)**: GSAP SplitText + stagger, plus variable font-axis animation -- the motion IS the style; without it there is no style.

**8. Futuristic / Sci-Fi** -- Web: Three.js with post-processing is essentially required -- `UnrealBloomPass` for glow (**[Verified]** still an actively maintained, current three.js example as of mid-2026, no deprecation found), a grid fragment shader, a particle system with `AdditiveBlending`; CSS `text-shadow` for 2D text glow, custom cursor via `mix-blend-mode: difference`. Full setup: scene + grid shader plane + bloom post-processing + particle field + GSAP ScrollTrigger camera movement. iOS: Metal `.colorEffect()` shader for scanline/glow, SwiftUI Canvas for particles, `TimelineView(.animation)`. Android: AGSL shader for glow/grid, `RenderEffect` chain (blur + color matrix) approximating bloom. Windows: Win2D for the grid plane/particles, `CompositionColorBrush` for pulsing accents. **Signature technique**: `UnrealBloomPass` (web) or an equivalent glow shader (native) -- without bloom, neon elements look flat.

**9. Bento Grid** -- Web: CSS Grid for layout, no WebGL; GSAP for tile hover-lift (`y: -4`), View Transitions API for tile expand/collapse, `clip-path` animation if the featured tile expands. iOS: `LazyVGrid` + `matchedGeometryEffect` for tile-to-detail transitions, `.spring(response: 0.35, dampingFraction: 0.7)` on hover/tap. Android: `LazyVerticalGrid` + `AnimatedContent` for tile state changes. **Signature technique**: none heavy -- CSS Grid layout precision plus spring/shared-element transitions for tile-to-detail.

**10. Editorial / Structural** -- Web: SVG for decorative rule elements, GSAP for scroll-triggered text reveals line by line (not character by character -- that's Kinetic Typography), CSS `clip-path` wipe reveals for section entry, no Three.js. iOS: SwiftUI Canvas for custom rules/dividers, `.transition(.opacity.combined(with: .move(edge: .bottom)))` for reveals. **Signature technique**: CSS clip-path wipe reveals timed to scroll (scrub), decorative SVG rule elements -- restraint is the aesthetic; no GPU effects beyond these.

**11. Organic / Biomorphic** -- Web: SVG `feTurbulence` + `feDisplacementMap` for liquid distortion on images/hover, Canvas 2D for noise-based animated blob backgrounds, animated-polygon `clip-path` for organic containers, `mix-blend-mode: multiply` for layered organic color blending. Three.js (optional): `SimplexNoise`-displaced sphere/plane geometry for organic 3D forms. iOS: SwiftUI Canvas with noise-based animated blobs, `TimelineView`, custom `Shape` with organic bezier curves. Android: Compose Canvas with noise-displaced path drawing, AGSL turbulence shader. **Signature technique**: SVG `feTurbulence` + `feDisplacementMap` for the liquid/organic feel (web); Canvas 2D or Three.js noise-displaced shapes for animated organic forms.

**12. Texture / Tactile** -- Web: SVG `feTurbulence` referenced via CSS `filter: url(#noise)`, applied as a `::after` pseudo-element at 3-5% opacity with `mix-blend-mode: multiply` or `overlay` -- this is the minimum required implementation; without it the style isn't applied. Canvas 2D for more complex procedural textures. iOS: SwiftUI Canvas noise pattern, or a pre-rendered noise PNG at low opacity with `.drawingGroup()`. Android: AGSL turbulence shader, or a pre-rendered noise `Painter` at low alpha. Windows: Win2D `TurbulenceEffect`. **Signature technique**: `feTurbulence` (web) / AGSL turbulence (Android) / `TurbulenceEffect` (Windows) -- the grain texture IS the style.

**13. Y2K / Retro Computing** -- Web: Three.js `FilmPass` for scanlines if using WebGL, or pure-CSS `repeating-linear-gradient` scanlines; a custom fragment shader gives the full CRT effect (barrel distortion, chromatic aberration, phosphor glow, detailed in `motion.md`); `filter: contrast(1.1) brightness(0.9)` as a minimal CSS-only approximation. Monospace font throughout, always. iOS: Metal `.colorEffect()` for CRT color treatment, SwiftUI Canvas for scanlines. Android: AGSL shader for chromatic aberration/scanlines. **Signature technique**: full CRT post-processing shader (barrel distortion + chromatic aberration + scanlines + phosphor tint). Minimum viable version: CSS scanlines + monospace type; full version needs a custom GLSL/AGSL/Metal shader.

**14. Calm / Anti-Distraction** -- Web: no GPU effects; CSS `opacity` transitions only (200-300ms), `prefers-reduced-motion` respected by default since there's barely any motion to begin with, no Three.js, no GSAP beyond an occasional slow fade. iOS: `.animation(.easeInOut(duration: 0.3))` on opacity only, no spring physics, no Canvas/Metal. Android: `fadeIn()`/`fadeOut()` only, no `spring()`. **Signature technique**: none, deliberately -- any GPU effect or complex animation is a failure of the style.

## Cross-Style Rules

These apply regardless of which style is selected, on all three platforms.

**Platform conventions are non-negotiable on every platform.** Style is a visual language applied over correct platform behavior. A neo-brutalist iOS app still uses swipe-to-go-back. A futuristic Android app still uses the Material navigation pattern. A kinetic typography web app still respects `prefers-reduced-motion`. A calm web app still has visible focus indicators for keyboard navigation. Style changes appearance, not behavior.

**Web gets the same design completeness as native.** Every screen, every state, every breakpoint. Responsive behavior at Mobile (375-767), Tablet (768-1023), and Desktop (1024+) is not optional. Web designs are not "simplified versions" of the native design -- they are platform-specific implementations of the same design system.

**Accessibility doesn't negotiate on any platform.** Every style must meet 4.5:1 contrast for normal text and 3:1 for large text and interactive elements on iOS, Android, and Web. Hard shadows can fail contrast -- text on a neo-brutalist button must pass against its fill color, not against the shadow. Glassmorphism needs sufficient frost or a CSS `@supports` fallback for environments where `backdrop-filter` isn't supported. Web additionally requires keyboard navigation, visible focus rings, and semantic HTML structure regardless of the visual style.

**Dark mode is required on every platform.** iOS and Android via system preference. Web via `@media (prefers-color-scheme: dark)` and optionally a manual toggle. Design the dark version with the same intentionality as the light version -- it's not an inversion, it's a separate palette.

**Motion respects user preferences everywhere.** iOS/Android: check `accessibilityReduceMotion`. Web: `@media (prefers-reduced-motion: reduce)`. Every animated element needs a non-animated fallback that communicates the same information.

**States are complete on every platform.** Default, hover, pressed/active, focused, disabled, loading, error, empty. Web adds `:hover` and `:focus-visible` as distinct states. Native adds the platform-specific pressed animation (spring collapse on neo-brutalism, etc.). The style doesn't change what states need to exist -- only what they look like.

**Motion tokens match the style across all platforms.** Neo-brutalism: snappy springs (response 0.15-0.2, moderate bounce) or CSS `transition: 100ms` with cubic-bezier that snaps. Organic: gentle easing (0.6s+, no bounce). Futuristic: fast ease-out. Calm: opacity transitions only, 200-250ms. Define motion tokens consistently and reference them on every platform.

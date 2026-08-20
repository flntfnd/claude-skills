# Glassmorphism / Frosted

The static, web-native sibling of Liquid Glass (`liquid-glass.md`). Translucent surfaces with background blur, inner highlight strokes, and subtle depth. Unlike Liquid Glass, there's no real-time lensing -- the effect is achieved through blur and opacity. Still contemporary and premium when not overused.

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

Signature GPU technique -- the animated background a glass layer needs to blur over -- and Windows Acrylic notes: see `SKILL.md` → Style-to-Technique Mapping, item 5.

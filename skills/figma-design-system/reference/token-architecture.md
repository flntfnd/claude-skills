# Token Architecture

## Contents
- [Three-Tier Token System](#three-tier-token-system)
- [Variable Collections in Figma](#variable-collections-in-figma)
- [Naming Convention](#naming-convention)
- [Platform Token Name Mapping](#platform-token-name-mapping)
- [Light and Dark Modes](#light-and-dark-modes)
- [Typography](#typography)
- [Spacing and Radius](#spacing-and-radius)

## Three-Tier Token System

Never apply primitive tokens directly to components. Always alias through semantic tokens.

**Tier 1: Primitive** (raw values, never applied directly)

```
color/primitive/blue/50
color/primitive/blue/500
color/primitive/blue/900
color/primitive/gray/50
...
spacing/primitive/2
spacing/primitive/8
spacing/primitive/16
...
radius/primitive/4
radius/primitive/8
radius/primitive/9999
```

**Tier 2: Semantic** (meaning and intent, applied in most cases)

```
color/semantic/background/primary
color/semantic/background/secondary
color/semantic/background/elevated
color/semantic/text/primary
color/semantic/text/secondary
color/semantic/text/disabled
color/semantic/border/default
color/semantic/border/focus
color/semantic/status/success
color/semantic/status/warning
color/semantic/status/error
color/semantic/interactive/primary
color/semantic/interactive/primary-hover
color/semantic/interactive/primary-pressed
```

**Tier 3: Component** (only needed at enterprise scale)

```
button/primary/background/default
button/primary/background/hover
button/primary/text/default
card/background
card/border
```

For most projects, semantic tokens are the endpoint. Component tokens add overhead that only pays off with multiple teams and strict governance requirements. Three tiers is the max for most projects -- two tiers is often enough.

## Variable Collections in Figma

Organize into four collections, kept separate:

**Collection 1: Primitives** -- all raw values. One mode only. No light/dark here.

**Collection 2: Semantic — Color** -- modes: Light, Dark. Every semantic color token aliases a primitive. Switching modes swaps the alias target, not the token name. Components using semantic tokens adapt to mode switches automatically.

**Collection 3: Semantic — Spacing, Radius, Motion** -- number variables. Mode: Default (no theming needed unless building density variants).

**Collection 4: Typography** -- string variables for font family and weight; number variables for size and line height. Font family and weight bind to string variables, size and line height to number variables -- a single `brand-font` variable updates the entire system's typeface instantly.

## Naming Convention

Forward slashes as hierarchy separators in Figma. They map to dot notation or kebab-case depending on the target platform.

In Figma: `color/semantic/background/primary`
In CSS: `--color-semantic-background-primary`
In Swift: `Color.Semantic.Background.primary`
In Kotlin: `MaterialTheme.colorScheme.background` (mapped via theme)

Align names with platform conventions where they exist. Don't fight the platform naming system.

## Platform Token Name Mapping

### iOS / iPadOS / macOS (SwiftUI)

| Figma Token | SwiftUI Equivalent |
| --- | --- |
| `color/semantic/background/primary` | `Color(.systemBackground)` |
| `color/semantic/background/secondary` | `Color(.secondarySystemBackground)` |
| `color/semantic/text/primary` | `Color(.label)` |
| `color/semantic/text/secondary` | `Color(.secondaryLabel)` |
| `color/semantic/border/default` | `Color(.separator)` |
| `color/semantic/interactive/primary` | `Color.accentColor` |
| `spacing/base` | `Spacing.base` (custom token, 16pt) |
| `radius/medium` | `GlassTokens.Radius.card` |

When a SwiftUI system color covers the use case, use it. Custom tokens fill the gaps: brand-specific colors, product-specific surfaces, anything the system palette doesn't cover.

### Android (Material 3 Expressive)

| Figma Token | Compose Equivalent |
| --- | --- |
| `color/semantic/background/primary` | `MaterialTheme.colorScheme.surface` |
| `color/semantic/background/secondary` | `MaterialTheme.colorScheme.surfaceContainer` |
| `color/semantic/text/primary` | `MaterialTheme.colorScheme.onSurface` |
| `color/semantic/text/secondary` | `MaterialTheme.colorScheme.onSurfaceVariant` |
| `color/semantic/interactive/primary` | `MaterialTheme.colorScheme.primary` |
| `color/semantic/status/error` | `MaterialTheme.colorScheme.error` |
| `color/semantic/border/default` | `MaterialTheme.colorScheme.outline` |

### Web (CSS)

| Figma Token | CSS Custom Property |
| --- | --- |
| `color/semantic/background/primary` | `--color-bg-primary` |
| `color/semantic/text/primary` | `--color-text-primary` |
| `color/semantic/interactive/primary` | `--color-interactive-primary` |
| `spacing/base` | `--spacing-base` |
| `radius/medium` | `--radius-md` |

## Light and Dark Modes

Both modes live in the same semantic color collection. Every token has a Light value and a Dark value. Switching the mode variable in Figma switches every component simultaneously.

Design in dark mode first -- if it works in dark, it almost always works in light; the reverse doesn't hold.

Both light and dark values alias primitives. Never put raw hex values into semantic tokens.

```
color/semantic/background/primary
  Light: → color/primitive/gray/50  (#F5F3EE)
  Dark:  → color/primitive/gray/950 (#1A1A1E)
```

Expose a mode switcher at the frame level during design. Any frame toggles between light and dark instantly via variable modes. Review every screen in both before handoff.

## Typography

Bind all type properties to variables:

```
typography/family/sans     → "SF Pro" (iOS), "Roboto Flex" (Android), "Inter" (Web)
typography/family/mono     → "SF Mono", "Roboto Mono", "JetBrains Mono"

typography/size/display-lg  → 40
typography/size/display-sm  → 32
typography/size/title-lg    → 28
typography/size/title-md    → 22
typography/size/title-sm    → 20
typography/size/headline    → 17
typography/size/body        → 16
typography/size/callout     → 15
typography/size/subhead     → 14
typography/size/footnote    → 13
typography/size/caption     → 12

typography/weight/regular   → "Regular"  (400)
typography/weight/medium    → "Medium"   (500)
typography/weight/semibold  → "Semibold" (600)
typography/weight/bold      → "Bold"     (700)

typography/leading/tight    → 1.2
typography/leading/normal   → 1.5
typography/leading/relaxed  → 1.7
```

Text styles reference these variables. Changing `typography/family/sans` updates every text style in the system simultaneously.

Create one text style per semantic role, not per size -- roles carry meaning, sizes carry numbers:

```
Display Large     — hero content, marketing surfaces
Display Small     — section headers, feature intros
Title Large       — screen titles, modal headers
Title Medium      — card headers, list section titles
Title Small       — subheaders, labeled groups
Headline          — emphasized body, call-outs
Body              — primary reading content
Callout           — secondary reading, supporting text
Subheadline       — metadata, secondary info
Footnote          — timestamps, attribution, legal
Caption           — image captions, form help text
Label Large       — button labels, active states
Label Medium      — secondary button labels, tags
Label Small       — badges, chips, minimal labels
```

## Spacing and Radius

8pt grid. All spacing tokens are multiples of 4, preferring multiples of 8. Apply as number variables to padding and gap in Auto Layout frames -- no hardcoded values.

```
spacing/1    → 2
spacing/2    → 4
spacing/3    → 8
spacing/4    → 12
spacing/5    → 16   (base)
spacing/6    → 20
spacing/7    → 24
spacing/8    → 32
spacing/9    → 40
spacing/10   → 48
spacing/11   → 64
spacing/12   → 80
```

```
radius/none       → 0
radius/xs         → 4
radius/sm         → 8
radius/md         → 12
radius/lg         → 16
radius/xl         → 24
radius/2xl        → 28
radius/sheet      → 34
radius/pill       → 9999
```

On iOS, `radius/2xl` maps to card radius (`GlassTokens.Radius.card = 28`), `radius/sheet` to sheets (34), `radius/pill` to capsule shapes. On Android, `radius/md` maps to M3's medium shape (12dp), `radius/xl` to extraLarge (24dp).

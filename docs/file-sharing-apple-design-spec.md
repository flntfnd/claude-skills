# Apple design spec: iOS and macOS

Status: v0.1, September 2026. The Figma file is https://www.figma.com/design/jy7owb9BIQ1x0B4yIW9iZJ (blank at time of writing). This spec is the build order and the values that go into it, so the Figma work is execution, not invention.

Visual direction: native Apple HIG, Liquid Glass on the navigation layer, SF Pro, system semantic colors. No `visual-styles` override. A user should not be able to tell this wasn't shipped by Apple, and it should still read as unmistakably this product through restraint, typography, and the one accent.

## Gates (checked every session)

1. Every page canvas is `#1E1E1E` before anything is placed on it.
2. No empty page. Tokens are populated before Components is touched; Components before screens.
3. Token names below are the source of truth for the SwiftUI code that does not exist yet. Engineering treats this file as canonical. Names follow the repo's `figma-design-system` token architecture and map to `apple-platform` names.
4. Every screen exists in Light and Dark before it counts.

## File structure

```
🎨 Tokens        primitives, semantic color (Light/Dark), spacing, radius, glass, motion
🔤 Typography    SF Pro ramp rendered as specimens
🎛 Components    atoms, then molecules, each with all states
📐 Patterns      iOS tab shell, macOS window shell, sheet, drop zone
📱 iOS           minimum screen set, Light and Dark
💻 macOS         minimum screen set, Light and Dark
🚢 Handoff       flows, annotated specs, token reference
```

## Tokens

### Primitives (one mode, hidden from pickers)

Warm neutrals from `apple-platform`, plus one accent and the status set.

```
color/primitive/neutral/0      #FFFFFF
color/primitive/neutral/50     #F5F3EE
color/primitive/neutral/100    #F7F7FA
color/primitive/neutral/200    #E6E4DF
color/primitive/neutral/300    #C9C7C2
color/primitive/neutral/500    #8A8A8E
color/primitive/neutral/700    #3A3A3F
color/primitive/neutral/800    #2E2E33
color/primitive/neutral/900    #26262B
color/primitive/neutral/950    #1A1A1E
color/primitive/neutral/1000   #000000
color/primitive/accent/400     #5AA9FF
color/primitive/accent/500     #0A84FF
color/primitive/accent/600     #0066D6
color/primitive/green/500      #30D158
color/primitive/orange/500     #FF9F0A
color/primitive/red/500        #FF453A
```

### Semantic color (modes: Light, Dark), aliased to primitives

| Token | Light | Dark | SwiftUI |
| --- | --- | --- | --- |
| color/semantic/background/primary | neutral/50 | neutral/950 | `Color(.systemBackground)` |
| color/semantic/background/secondary | neutral/0 | neutral/900 | `Color(.secondarySystemBackground)` |
| color/semantic/background/elevated | neutral/100 | neutral/800 | custom `Background.elevated` |
| color/semantic/text/primary | neutral/1000 | neutral/0 | `Color(.label)` |
| color/semantic/text/secondary | neutral/1000 @ 55% | neutral/0 @ 55% | `Color(.secondaryLabel)` |
| color/semantic/text/tertiary | neutral/1000 @ 30% | neutral/0 @ 30% | `Color(.tertiaryLabel)` |
| color/semantic/border/default | neutral/1000 @ 20% | neutral/0 @ 15% | `Color(.separator)` |
| color/semantic/fill/default | neutral/1000 @ 8% | neutral/0 @ 10% | `Color(.systemFill)` |
| color/semantic/interactive/primary | accent/500 | accent/400 | `Color.accentColor` |
| color/semantic/interactive/primary-pressed | accent/600 | accent/500 | |
| color/semantic/status/success | green/500 | green/500 | |
| color/semantic/status/warning | orange/500 | orange/500 | |
| color/semantic/status/error | red/500 | red/500 | |
| color/semantic/glass/fill | neutral/0 @ 12% | neutral/0 @ 10% | glass fill |
| color/semantic/glass/stroke | neutral/0 @ 22% | neutral/0 @ 22% | `GlassTokens.Stroke` |

Scopes: backgrounds `FRAME_FILL, SHAPE_FILL`; text `TEXT_FILL`; border and glass stroke `STROKE_COLOR`; fill and glass fill `FRAME_FILL, SHAPE_FILL`; status `ALL_FILLS`. Primitives `[]`.

### Spacing (`Spacing` in code)

```
spacing/xxs 2   spacing/xs 4   spacing/sm 8   spacing/md 12   spacing/base 16
spacing/lg 20   spacing/xl 24  spacing/xxl 32 spacing/xxxl 48 spacing/section 64
```

### Radius (`GlassTokens.Radius` in code)

```
radius/xs 4   radius/sm 8   radius/md 12   radius/lg 16   radius/xl 24
radius/card 28   radius/sheet 34   radius/pill 9999
```

### Glass (number variables, modes: Regular, Clear)

```
glass/light/angle 140      glass/light/intensity 75
glass/refraction  Regular 78 / Clear 88
glass/depth 15             glass/dispersion 35      glass/splay 30
glass/frost/navigation 10  glass/frost/toolbar 8    glass/frost/sheet 40   glass/frost/modal 60
```

Shadow effect style `Shadow/Glass`: black, y 8, blur 18, 18% opacity. Highlight stroke 1 px inside, `color/semantic/glass/stroke`.

### Motion

```
motion/spring/interactive   response 0.35, damping 0.80   (taps, drags, toggles)
motion/spring/bouncy        response 0.40, damping 0.65   (glass morph, sheet present)
motion/ease/state           cubic 0.2 0 0 1, 240 ms       (progress, count changes)
```

## Typography

SF Pro throughout. Text styles named by role, sizes from the HIG scale, one style per role:

```
Large Title   34 / Bold        screen titles on iOS, first-run
Title         28 / Bold        macOS window title area, sheet titles
Title 2       22 / Semibold    section heads
Title 3       20 / Semibold    card heads
Headline      17 / Semibold    row titles, button labels
Body          17 / Regular     primary content
Callout       16 / Regular     supporting text
Subheadline   15 / Regular     metadata
Footnote      13 / Regular     countdowns, byte counts
Caption       12 / Regular     hints, legal
Caption 2     11 / Regular     badges
Mono          13 / SF Mono     link slugs, recovery key
```

If SF Pro is not installed in the Figma environment, Inter is the stand-in with a note on the Typography page. Never ship Inter in a handoff labeled as SF Pro.

## Components

Atoms, each with every state, all values bound to tokens, layer names in Swift camelCase:

- `Button` — Style: glassProminent (one per screen), glass, plain. Size: regular, large. State: default, pressed, disabled. Prominent uses `interactive/primary` tint.
- `IconButton` — 44 pt hit area, glass circle, states as Button.
- `SegmentedControl` — the transport picker. Two segments, glass track, sliding selection.
- `TextField` — default, focused, error, disabled. Used for password and custom expiry.
- `Toggle` — on, off, disabled.
- `Badge` — transport (P2P / Cloud), status (live, sealed, expired, revoked), plan (Paid).
- `ProgressBar` — determinate, indeterminate, with byte label.
- `Countdown` — remaining time chip, warning state under 1 hour.
- `Avatar` — anonymous session glyph only; there are no user photos anywhere.

Molecules:

- `DropZone` — idle, drag-over, populated, error. The single most important surface in the product. Dashed 1.5 px border on `border/default`, `radius/card`, generous `spacing/xxxl` padding, an SF Symbol `arrow.down.doc` at 44 pt, two lines of text.
- `TransportPicker` — SegmentedControl plus a one-line explainer that changes with selection: "Sender stays online, nothing stored" / "Stored encrypted until it expires".
- `ExpiryPicker` — preset chips (1h, 1d, 7d, 30d, custom, never on paid) plus download cap stepper.
- `LinkCard` — the produced link in Mono, Copy, QR, and Share actions, glass surface. This is the hero moment after a drop is created.
- `FileRow` — icon, name, size, per-file download. Folder variant with disclosure.
- `RecipientRow` — anonymous session glyph, progress, speed. P2P only.
- `DropRow` — dashboard list row: title, transport badge, size, countdown, counts, revoke.
- `Toolbar` (glass) — iOS top bar and macOS floating toolbar.
- `TabBar` (glass) — iOS: Send, Receive, Drops, Settings. Collapses on scroll.
- `Sidebar` — macOS: Send, Drops, Drive (paid), Settings.
- `Sheet` — inset glass sheet, medium and large detents.
- `EmptyState` — symbol, one line, one action.

## iOS screens (minimum set, each in Light and Dark)

Device frame iPhone 17 Pro class, 402 by 874 pt.

**Authentication.** Optional, so the first screen is not a login. "Sign in" lives in Settings and as a soft prompt on the Drops tab: magic link entry, passkey button, and a line that says anonymous use is fully featured. States: entry, sent, error.

**Home (Send).** The tab the app opens to.

```
┌──────────────────────────────┐
│ ▓ Send                    ⓘ  │  glass top bar
│                              │
│  ┌────────────────────────┐  │
│  │      ⬇ arrow.down.doc  │  │  DropZone, idle
│  │  Drop a file or folder │  │
│  │  or tap to browse      │  │
│  └────────────────────────┘  │
│                              │
│  Transport                   │
│  [ Peer-to-peer | Cloud ]    │  glass segmented
│  Sender stays online,        │
│  nothing stored              │
│                              │
│  Expires   while tab open ▾  │
│  Downloads 1 ▾               │
│  Password  off               │
│                              │
│                              │
│ ▓ Send  Receive  Drops  ⚙   │  glass tab bar
└──────────────────────────────┘
```

States: idle (above), populated (file list replaces the zone, size and count, Create link becomes glassProminent), uploading (progress with bytes, link already shown), live P2P (recipient rows with progress), error (network, size over plan ceiling with the upgrade line), empty is the idle state.

**Detail (Drop).** The created link and its life.

```
┌──────────────────────────────┐
│ ‹ Drops        Q3 assets  ⋯  │
│                              │
│  ┌────────────────────────┐  │
│  │ /d/8kq2ma#…    [Copy]  │  │  LinkCard, glass
│  │ [QR] [Share] [Manage]  │  │
│  └────────────────────────┘  │
│  P2P · 3.4 GB · 42 files     │
│  ⏱ expires in 6d 3h  ↓ 0/1   │
│                              │
│  ▸ logos/           18 MB    │
│  ▸ photography/    3.2 GB    │
│    guidelines.pdf    4 MB    │
│                              │
│  [ End this drop ]           │  destructive, plain
└──────────────────────────────┘
```

Content variants: full, partial upload, long title, short title, single file, expired (tombstone state), revoked.

**Receive.** The recipient view when a link opens in the app. Same file browser, password gate first when set, "the sender isn't here right now" state for P2P, decrypt-and-save progress.

**Drops (list).** DropRows newest first. States: default, loading skeleton, empty ("Nothing shared yet"), error, anonymous prompt to sign in to keep history.

**Settings.** Account (anonymous or signed in), Plan (free with upgrade, paid with drive quota meter), Defaults (transport, expiry, download cap), Privacy (the non-promises, in plain words), About.

**Navigation shell.** Tab bar expanded, collapsed on scroll, and with the Receive tab in search role at bottom right.

## macOS screens (minimum set, each in Light and Dark)

Window 1080 by 720 pt, concentric corners, floating glass toolbar, persistent sidebar. Menu bar transparent.

**Main window (Send).**

```
┌──────────────────────────────────────────────────────────────┐
│ ● ● ●    ▓ Send                              [ + New drop ]  │  floating glass toolbar
├──────────┬───────────────────────────────────────────────────┤
│ Send     │                                                   │
│ Drops    │   ┌───────────────────────────────────────────┐   │
│ Drive ●  │   │           ⬇ arrow.down.doc                │   │
│          │   │   Drop a file or folder, or press ⌘O      │   │  DropZone
│          │   └───────────────────────────────────────────┘   │
│          │                                                   │
│          │   Transport  [ Peer-to-peer | Cloud ]             │
│          │   Expires    [ 7 days ▾ ]   Downloads [ ∞ ▾ ]     │
│          │   Password   [ off ]                              │
│ ⚙ Settings│                                                  │
└──────────┴───────────────────────────────────────────────────┘
```

Sidebar glass is ambient, does not flip with mode. States match iOS: idle, populated, uploading, live P2P, error.

**Detail.** Drops list in the sidebar's content column, detail on the right: LinkCard, file tree, recipient panel, countdown, revoke. Same content variants as iOS.

**Drive (paid).** Encrypted tree in a two-column browser, quota meter in the toolbar, share-from-drive as a sheet. Free plan shows the upgrade state, not an empty folder.

**Settings.** Standard macOS settings window, tabs: General, Account, Plan, Privacy.

**Menu bar item.** The glass popover: drop zone, last three drops, one-line countdowns. This is the fast path and gets its own frame.

**Navigation shell.** Sidebar expanded and collapsed, toolbar with and without selection actions.

**Authentication.** Magic link and passkey as a sheet over the main window, same states as iOS.

## Build order in Figma

1. Set every page background before creating content on it.
2. Tokens page: collections and variables above, then swatch and scale specimens.
3. Typography page: the ramp rendered.
4. Components: atoms in the order listed, validate each with a screenshot, then molecules.
5. Patterns: the two shells and the sheet.
6. iOS screens, Dark first, then switch mode for Light. Then macOS the same way.
7. Handoff page last.

Nothing on a screen is drawn freehand. Every screen is instances of patterns, which are instances of molecules, which are instances of atoms.

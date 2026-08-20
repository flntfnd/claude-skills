# Component Architecture

## Contents
- [Structure Rules](#structure-rules)
- [Auto Layout](#auto-layout)
- [Responsive Components](#responsive-components)
- [Component Properties](#component-properties)
- [Variants](#variants)
- [Slots](#slots)
- [Interactive Components](#interactive-components)
- [Variables in Prototypes](#variables-in-prototypes)
- [Platform Variants](#platform-variants)

## Structure Rules

Every component follows this structure:
- Outer frame: Auto Layout, defines padding and overall sizing
- Inner groups: organized by content zone
- All colors: semantic color variables
- All spacing: spacing number variables
- All type: text style referencing typography variables
- Layer names: match code component and prop names exactly

<details>
<summary>Legacy / deprecated</summary>

Static color and text styles are legacy for anything variables now cover. Variables are the standard as of 2026; keep static Styles for gradients and effects only, since those still aren't variable-bindable.
</details>

## Auto Layout

Every component uses Auto Layout, no exceptions -- a component without it breaks when content changes.

**Direction**: horizontal for row-based layouts (nav bars, button groups, list rows); vertical for column-based layouts (cards, forms, modals).

**Spacing**: fixed between specific elements; space-between for elements that should push apart.

**Padding**: reference spacing tokens, never hardcode.

**Resizing**: hug content when the component should wrap tightly; fill container when it should expand to available space.

**Min/max dimensions**: set where content could overflow or the component could become unusably small or large.

**Wrap**: for grid-like layouts where items should wrap to new rows when the container shrinks.

**Absolute positioning**: sparingly, only for elements that intentionally overlay others -- badges on icons, decorative elements, glass overlays. Set the frame to clip content when using absolute-positioned children that shouldn't affect the Auto Layout flow.

## Responsive Components

For components that behave differently across breakpoints, create variant properties matching the breakpoint names. Figma Sites consumes these automatically; the same pattern applies for documentation and handoff either way.

Standard breakpoints:
```
Mobile:  375 — 767
Tablet:  768 — 1023
Desktop: 1024+
```

Name variant properties to match: `Platform` with values `Mobile`, `Tablet`, `Desktop` -- or `Size` with `Compact`, `Regular`, `Large` for iOS/iPadOS.

## Component Properties

Use component properties for every customizable aspect. Don't rely on override-hacking.

```
Property types:
Boolean       — show/hide elements (icon, label, badge)
Text          — editable content (label, placeholder, count)
Instance swap — replace nested components (leading icon, avatar, status indicator)
Variant       — switch component states and sizes
```

Expose only what needs customizing. Hiding properties designers shouldn't touch keeps the system clean.

## Variants

Every component needs all states designed before any state is built. Map them first:

```
Button states:  Default, Hover, Pressed, Focused, Disabled, Loading
Input states:   Empty, Filled, Focused, Error, Disabled, Read-only
Card states:    Default, Hover, Pressed, Selected, Disabled
```

Name variants with consistent property names across the system: `State` with values `Default/Hover/Pressed/Disabled`; `Size` with `Small/Medium/Large`; `Style` with `Primary/Secondary/Ghost/Destructive`.

## Slots

Slots are the correct pattern for flexible composition, replacing the old approach of building twenty card variants for every content combination with one card that has slots. A slot is a named container inside a component that accepts component instances -- it behaves like an Auto Layout frame, but its contents can be swapped without detaching the parent component.

Slots shipped to open beta in March 2026 and the developer API expanded in June 2026 (stretch behavior on insertion, empty-state display, min/max child limits, preferred-value restrictions). Confirm the feature is enabled for the file's plan before relying on it as the default pattern -- fall back to instance-swap component properties if it isn't available.

Use slots for:
- Content regions inside cards (header, body, footer, media)
- Icon positions in buttons and list rows
- Custom empty states
- Interchangeable lead and trail elements

Set preferred instances on slots to guide designers toward the correct components without locking them in.

## Interactive Components

Every stateful component is interactive -- not "should be," is. A component page with static variants and no prototype connections is incomplete. Build interactions while building the component, not after.

**Every component with more than one state must have these prototype connections wired before it's considered done.** Button, wired in every file:

1. Create the component set with all state variants (Default, Hover, Pressed, Disabled, Focus)
2. Default → `Mouse enter` → Change to Hover
3. Hover → `Mouse leave` → Change to Default
4. Hover → `Mouse down` → Change to Pressed
5. Pressed → `Mouse up` → Change to Hover
6. Any instance placed in any prototype frame inherits all of this automatically

Same mandatory wiring for:
- **Toggles / checkboxes**: `On click` → change to opposite checked state
- **Accordions**: `On click` → expanded variant, `On click` again → collapsed
- **Dropdown / select**: `On click` → open state variant
- **Form inputs**: `On focus` → focused variant, `On blur` → default
- **Navigation tabs**: `On click` → active variant

A component set with variants but no prototype connections is not complete. Do not move to the next component until interactions are wired.

## Variables in Prototypes

For prototypes needing logic beyond state transitions, use variables with prototype actions.

**Boolean variables**: show/hide elements conditionally
**Number variables**: counters, quantity selectors, progress values
**String variables**: dynamic labels, selected values, form content

```
Example: cart item counter
- Create number variable: cartCount (default: 0)
- Bind to text layer showing count
- On "Add" button click: Set variable cartCount to cartCount + 1
- On "Remove" click: Set variable cartCount to cartCount - 1
- Conditional: if cartCount == 0, hide checkout button
```

This replaces dozens of duplicate frames with a single frame and a few variable actions.

## Platform Variants

Each platform-specific component is a variant of the base component, not a separate component. A Card component has iOS, Android, and Web variants that share token bindings but adapt their visual treatment to platform conventions. Use a `Platform` component property with values `iOS`, `Android`, `Web`, and bind the relevant variant to the correct platform's visual spec.

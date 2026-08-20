# Workflows and Handoff

## Contents
- [File Structure](#file-structure)
- [Building a Design System from Scratch](#building-a-design-system-from-scratch)
- [Replicating an Existing App](#replicating-an-existing-app)
- [Dev Handoff](#dev-handoff)
- [Accessibility](#accessibility)
- [Anti-Patterns](#anti-patterns)

## File Structure

One file per system, organized by pages, not separate files, unless the system is truly multi-brand at enterprise scale.

```
Page: 🎨 Tokens          — all variable collections documented visually
Page: 🔤 Typography       — type scale, specimens, usage examples
Page: 🎛 Components       — all components, organized by category
Page: 📐 Patterns         — composed layouts, navigation patterns
Page: 📱 iOS / iPadOS     — platform screens
Page: 🤖 Android          — platform screens
Page: 🌐 Web              — platform screens
Page: 🚢 Handoff          — engineering-ready specs
Page: 🗄 Archive          — deprecated components (don't delete, archive)
```

Only create platform pages for platforms the project actually targets -- an iOS-only project gets no Android page. If the project targets iOS and Android, both platform pages must be populated, not just one. A platform page that exists must have content.

Keep components and tokens in the same file. Splitting into separate libraries is for enterprise multi-brand systems only -- over-splitting creates maintenance overhead that kills adoption.

## Building a Design System from Scratch

Build in this order. Each step is complete when the content exists in Figma, not when the page has been created.

**1. Extract brand values.** Before opening Figma: primary color, neutral palette, brand typeface, voice and tone. If an iOS/Android app already exists, read the `apple-platform` skill or the Android platform skill and extract the existing token names. Use those names exactly.

**2. Build primitive tokens -- populate now.** Full color ramp (50-950 per hue), spacing scale, radius scale, shadow values. The 🎨 Tokens page isn't done until these values are visible in Figma. No components until this is complete.

**3. Build semantic tokens -- populate now.** Semantic Color collection with Light and Dark modes. Alias every semantic token to a primitive. If code uses `Color.Semantic.Background.primary`, the Figma token is `color/semantic/background/primary` -- same hierarchy, same name.

**4. Define typography -- populate now.** Typography variable collection, text styles referencing it. The Typography page shows all text styles rendered, not just variable names.

**5. Define spacing and radius -- populate now.** Number variables, documented visually on the Tokens page.

**6. Build atomic components -- populate now, interactive on creation.** Button, input, checkbox, toggle, radio, badge, chip, avatar, icon button. Every atom: all states, semantic token bindings, interactive prototype connections wired. If the Components page exists and is empty, this step isn't done.

**7. Build molecular components -- populate now, interactive on creation.** List rows, cards, nav bars, tab bars, modals, sheets, tooltips, assembled from atoms. Every molecule with interactive states gets prototype connections wired on creation.

**8. Build page patterns.** Navigation shells, screen templates, common layout patterns.

**9. Build screens -- all platforms, minimum screen set per platform.** Actual product screens use instances of patterns, which use instances of molecules, which use instances of atoms. Nothing is drawn freehand on a screen.

Every platform specified in the project must have screens. A page containing only one screen type (e.g. login only) is not a complete platform page. Minimum per platform: authentication screens, home/main content (default + empty + error + loading), detail view, settings/profile, navigation shell. Every screen in both light and dark mode before the step is complete.

## Replicating an Existing App

When the product exists in code but design files are missing, outdated, or never existed. Extract the implicit design system from the live product and formalize it -- never skip the audit.

**Step 1: Audit the product.** Screenshot every unique screen state: default, empty, error, loading, full, partial, edge cases. Organize screenshots on a Figma page, grouped by feature area, not screen type.

**Step 2: Extract the implicit system.**
- **Colors**: eyedropper every unique color. Colors used once are noise; used 3-5 times are likely semantic roles; used everywhere are definitely semantic roles.
- **Spacing**: measure gaps and padding on recurring patterns. Common grids: 4pt, 8pt, 12pt.
- **Typography**: list every unique font size and weight -- most products use 8-12 distinct type styles even undocumented.
- **Radius**: measure corner radii on cards, buttons, inputs -- usually 4-6 consistent values.
- **Elevation/shadows**: catalog every unique shadow.

**Step 3: Formalize the system.** Map findings to a structured token system, named semantically, not by appearance -- `#6750A4` on every primary button is `color/semantic/interactive/primary`, not `purple-500`. If an existing codebase exists, read the `apple-platform` or Android platform skill for the token names already in use and match them exactly. Build primitives, then semantic tokens aliasing them. Populate the 🎨 Tokens page completely before moving to components.

**Step 4: Build components against the tokens.** Recreate every component found, correctly this time: Auto Layout, variable bindings, all states, interactive prototype connections wired. Start with atoms -- don't touch screens until atoms are done.

**Step 5: Rebuild screens -- all platforms, minimum screen set.** "Key screens" means every platform in the project gets a representative screen set, not just one platform, not just login. Every platform page in the file must have screens before this step is complete.

Minimum screen set per platform:
- **Authentication** — login, signup, forgot password, verification
- **Home / main content** — default, loading, empty, error states
- **Detail** — item detail view with all content variants (full, partial, long text, short text)
- **Settings / profile**
- **Navigation** — the nav shell in each of its states

Every screen in both light and dark mode, using component instances, not freehand drawing. Every hardcoded value found during this step means a token is missing.

**Useful plugins for auditing:** `html.to.design` imports live websites into editable Figma frames -- best starting point for web apps. **Design System Auditor** analyzes frames and scores adherence to the design system -- use after building the system to find where components aren't being used. **Check Designs** (native Figma) flags hardcoded values and suggests the correct variable; run it before every handoff -- it's an Organization/Enterprise-plan feature.

## Dev Handoff

**Before handing off:** run Check Designs -- every hardcoded value flagged needs the correct variable before the frame goes to engineering. Every component in the handoff frame must be a library instance, not a detached copy (Design System Auditor catches detached components). Every text layer references a text style; every color references a variable; every spacing value in Auto Layout references a number variable.

**Handoff page structure**, kept separate from the design page so engineers never scroll through iterations:
```
Section: Navigation flows (annotated with transition types and triggers)
Section: Screen specs (key screens, annotated)
Section: Component specs (edge cases, interaction notes)
Section: Token reference (which collection to use for which platform)
```

**Layer naming:** layer names become property names in Dev Mode. Name layers as if naming code.
```
Good: button-label, card-thumbnail, nav-tab-home, icon-leading
Bad: Rectangle 47, Group 3, Frame copy
```
iOS: Swift camelCase. Android: Kotlin camelCase. Web: kebab-case.

**Code Connect:** requires an Organization or Enterprise plan and a full Design or Dev Mode seat. Once components are mapped, Dev Mode shows the actual import and usage code from the codebase, not a generated approximation.

<details>
<summary>Legacy / deprecated</summary>

Framework-specific parsers (React, SwiftUI, Compose parser CLIs) stopped receiving updates and support on August 17, 2026. Template files -- framework-agnostic, full control over how a component appears in Dev Mode -- are now the only actively maintained way to use Code Connect. If a project still has parser-based Code Connect config, migrate it to template files rather than extending it. Setup happens either through Code Connect UI (runs entirely inside Figma, language-agnostic) or the Code Connect CLI.
</details>

**MCP integration:** the Figma MCP server lets Claude Code read the design system directly -- actual tokens, component names, and variables, not guesses. For this to work: the MCP server is connected, components and variables are published to a team library, and layer/variable names match code names. When asked to implement a component, read the library first and build with what already exists -- see the installed `figma:figma-use` and related plugin skills for the tool-call mechanics.

## Accessibility

Contrast minimums (WCAG AA):
- Normal text: 4.5:1
- Large text (18pt+ regular, 14pt+ bold): 3:1
- Interactive elements against adjacent colors: 3:1

Use the **Stark** plugin to check contrast during design, not deferred to handoff.

Build for Dynamic Type and large text sizes -- test layouts at 150% and 200% scale. If things break, the layout is wrong, not the text size.

Color cannot be the only way information is conveyed. Every status indicator (error, success, warning) needs an icon or text label alongside color.

Touch targets: 44pt minimum on iOS, 48dp on Android. If a component looks smaller, use padding to expand the tappable area without changing the visual size.

## Anti-Patterns

**Building components without Auto Layout.** They break when content changes. Always.

**Hardcoding color values in components.** Any hex value in a component is a token that doesn't exist yet -- create it.

**Using static color styles instead of variables.** Variables are the standard; styles are legacy for gradients and effects only.

**A separate component for every minor variation.** Use variants, component properties, and slots. A library with 800 components that could be 80 is unmaintainable.

**Designing screens first.** Screens built without a component library are a collection of one-offs, not a design system.

**Skipping dark mode.** A first-class target, not a bonus feature.

**Not naming layers.** Unnamed layers make Dev Mode useless and code generation unreliable.

**Over-nesting tokens.** Three tiers (primitive, semantic, component) is the max for most projects; two is often enough.

**Building the whole system before testing it.** Build the token layer, then two or three components, then one real screen. If the tokens break, fix them before building forty more components on broken foundations.

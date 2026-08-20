# Workflows and Handoff

## Contents
- [File Structure](#file-structure)
- [Building a Design System from Scratch](#building-a-design-system-from-scratch)
- [Replicating an Existing App](#replicating-an-existing-app)
- [Dev Handoff](#dev-handoff)
- [Accessibility](#accessibility)
- [Anti-Patterns](#anti-patterns)

## File Structure

```
Page: 🎨 Tokens          — Color Variables documented, Tokens Studio setup
Page: 🔤 Typography       — Text Styles, type scale specimens
Page: 🎛 Symbols          — all Symbol Masters, organized by category
Page: 📐 Patterns         — composed layouts, navigation shells
Page: 📱 iOS / iPadOS     — platform screens
Page: 🤖 Android          — platform screens
Page: 🌐 Web              — platform screens
Page: 🚢 Handoff          — engineering-ready specs
Page: 🗄 Archive          — deprecated Symbols (never delete, archive)
```

Only create platform pages for platforms the project actually targets -- an iOS-only project gets no Android page. If the project targets iOS and Android, both platform pages must be populated, not just one.

## Building a Design System from Scratch

Each step is complete when the content exists in Sketch, not when the page has been created. Don't move to the next step until the current one is done.

**1. Define brand values** -- primary color, neutral palette, typeface. If an iOS or Android app already exists, read the `apple-platform` skill or the Android platform skill and extract the existing token names. Use those names exactly in Sketch.

**2. Set up Color Variables -- populate now.** Primitives first, then semantic aliases. Both light and dark values for every semantic variable. The 🎨 Tokens page isn't done until these variables exist and are documented. No Symbols until this step is complete.

**3. Install Tokens Studio -- populate now.** Set up token sets for spacing, radius, typography sizes, and motion; apply the values. An empty Tokens Studio panel is not a completed step.

**4. Create Text Styles -- populate now.** One per semantic role, referencing semantic Color Variables for text color.

**5. Create Layer Styles** for common fills, borders, and shadows that repeat across components.

**6. Build atomic Symbols -- populate now, all states on creation.** Button, Input, Checkbox, Toggle, Badge, Chip, Icon Button. Every Symbol gets all state variants created immediately, using Color Variables and Text Styles throughout -- no hardcoded values. If the 🎛 Symbols page is empty, this step isn't finished.

**7. Build molecular Symbols -- populate now.** List Rows, Cards, Nav Bars, Tab Bars, Modals, Sheets -- assembled from atomic Symbols using nested overrides.

**8. Build page patterns** -- navigation shells, screen templates, common layout patterns.

**9. Build screens -- all platforms, minimum screen set per platform.** Using instances of pattern Symbols, which use instances of molecular Symbols, which use instances of atomic Symbols. Nothing is drawn freehand on a screen.

Every platform specified in the project must have screens; a page containing only one screen type (e.g. login only) is not a complete platform page. Minimum per platform: authentication screens, home/main content (default + empty + error + loading), detail view, settings/profile, navigation shell. Every screen in both light and dark mode before the step is considered complete.

## Replicating an Existing App

When the product exists in code but no Sketch file exists, or the existing file is outdated.

**Step 1: Capture via MCP.** Use `get_screenshot` on live screens (pasted into Sketch frames) for visual context. Use `run_code` to inspect any existing Sketch document for current Symbol inventory, Color Variables, and Text Styles before creating anything new.

**Step 2: Audit.** From screenshots and the existing document, catalog every unique color (eyedropper), font size/weight, spacing value (measure gaps), corner radius, and recurring component pattern. Group by role, not appearance -- `#6750A4` on every primary button is `Semantic/Interactive/Primary`, not `purple-500`.

**Step 3: Formalize.** Build Color Variables and Tokens Studio token sets from the catalog. Name everything semantically. Populate light and dark mode values. If an existing iOS or Android codebase exists, read the `apple-platform` or Android platform skill for the token names already in use and match them exactly -- `Semantic/Interactive/Primary` in Sketch must correspond to `Color.Semantic.Interactive.primary` in Swift, or whatever the codebase's naming convention is. The 🎨 Tokens page must be fully populated before moving to Symbols.

**Step 4: Build Symbols -- populate now, all states on creation.** Recreate every component correctly: proper naming, Smart Layout, overrides limited to what needs customizing, Color Variables and Text Styles applied throughout, no hardcoded values. Start with atoms; the 🎛 Symbols page must contain actual Symbols before moving to screens.

**Step 5: Rebuild screens -- all platforms, minimum screen set.** Every platform in the project gets a representative screen set -- covering one platform, or only login screens, is not acceptable. See the `design-tool-gates` skill for the minimum screen set per platform and the light/dark requirement.

Every screen in both light and dark mode, using Symbol instances, not freehand drawing. Every hardcoded value found during this step means a token or Color Variable is missing.

## Dev Handoff

**Before handing off:** verify every layer uses a Color Variable (not hardcoded hex), every text layer uses a Text Style, every Symbol instance is linked to the Library (not detached). Use `run_code` to audit for detached instances.

**Handoff methods:**
- **Sketch Cloud** -- upload the file, share a web link. Engineers inspect in the browser without installing Sketch; Inspect mode shows layout, spacing, colors, Text Styles, and exportable assets.
- **Export via MCP** -- use `run_code` to batch-export assets, e.g. "export all symbols prefixed with `icon/` from the current page as SVGs to Desktop."
- **Color Tokens export** -- export from the web app as CSS or JSON for engineering.

**Layer naming:** appears in Inspect mode and exported asset filenames. Name as if naming code.
```
Good: button-label, card-thumbnail, nav-tab-home, icon-leading
Bad: Rectangle 47, Group 3, Text 2
```
Same platform conventions as the Figma system: camelCase for iOS/Android, kebab-case for Web.

**MCP-assisted handoff:** engineers can query the document directly through Claude Code and the Sketch MCP -- "list all design tokens used in my Sketch selection," "generate my current Sketch selection in React," "show the full component hierarchy of my Sketch selection as a tree." For accurate output, the document must be clean: Color Variables applied, Text Styles applied, Symbols properly named and nested.

## Accessibility

Same requirements as the Figma system. WCAG AA contrast: 4.5:1 normal text, 3:1 large text and interactive elements. Color cannot be the only differentiator. Touch targets: 44pt minimum on iOS, 48dp on Android.

Use the **Stark** plugin for contrast checking directly in Sketch.

## Anti-Patterns

**Hardcoded color values in Symbols.** Any hex value in a Symbol fill that isn't a Color Variable is a missing token.

**Detached Symbol instances.** Detaching breaks the Library connection. Never detach unless the component genuinely needs to diverge from the system.

**Overrides exposing everything.** Every exposed override is a potential inconsistency -- only expose what designers should customize.

**Symbols without all states.** A Button Symbol with only the Default state means Hover, Pressed, Disabled, and Loading will be invented differently everywhere they're needed.

**Pages used as artboard dumps.** Pages have semantic purpose -- screens on the Tokens page, or Symbols scattered across the Web page, create unmaintainable files.

**Building screens before Symbols.** Screens built without a Symbol library are a collection of one-offs.

**Skipping dark mode.** Both appearances designed with equal intentionality.

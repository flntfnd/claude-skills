# iOS 27 / iPadOS 27 / macOS 27 "Golden Gate" Status

Everything else in this skill targets iOS 26 / iPadOS 26 / macOS Tahoe 26 (Xcode 26 SDK) as the stable baseline. This file tracks the next major version, announced at WWDC 2026 (June 8, 2026). Treat this whole file as time-sensitive and re-verify before depending on specifics -- betas move.

## Version and release status

As of September 7, 2026: iOS 27, iPadOS 27, and macOS 27 "Golden Gate" are in public and developer beta (developer beta 8 / public beta 6, August 31, 2026, per MacRumors' roundup; macOS 27 public beta 5 per The Mac Observer). Apple's fall event is September 9, 2026, so GA is days away, not weeks. Apple's own naming for macOS 27 is "Golden Gate." Expected general release is September 2026, alongside new iPhone hardware, per the normal fall cadence. **iOS 26 / iPadOS 26 / macOS Tahoe 26 remain the correct stable pin for any app shipping before that release.** Don't target iOS 27 APIs as the baseline until it's GA.

## Liquid Glass changes

Apple responded to public criticism of iOS 26's Liquid Glass with user-facing and developer-facing adjustments in iOS 27. These are now confirmed against the shipping betas (developer beta 6 / public beta 4, August 17, 2026) and Apple's own WWDC 2026 "What's New in SwiftUI" session, not just outlet coverage of the keynote:

- Confirmed: a system-wide Liquid Glass intensity slider at Settings > Appearance > Liquid Glass, letting users dial the material anywhere from "ultra clear" to "fully tinted." This is separate from the existing Reduced Transparency accessibility toggle, which still strips translucency down to flat backgrounds. `.glassEffect()` elements pick up the slider automatically -- no new SwiftUI API is required to support it.
- Confirmed: Apple also refined the material itself -- a darkened edge around glass elements and brighter specular highlights to improve legibility over complex content, plus edge-to-edge sidebars with colored icons for the active app. `[Unverified]` No new `Glass` case names (beyond `.regular` / `.clear` / `.identity`) have been confirmed from a primary source -- these read as refinements to the existing material, not new API surface.
- Confirmed: the `UIDesignRequiresCompatibility` Info.plist key, which let apps opt out of Liquid Glass entirely on iOS 26, is dead in iOS 27. Apple's own `UIDesignRequiresCompatibility` documentation, updated with the iOS 27 Beta release notes (June 9, 2026), states the system ignores the key once an app builds against iOS 27, iPadOS 27, Mac Catalyst 27, macOS 27, or tvOS 27 or later. There is no compatibility mode in Xcode 27.

## Design-language changes to design against (verified across MacStories, MacRumors, 9to5Mac, Cult of Mac, September 2026)

These are visual and structural, not API, and they change what a correct iOS 27 / macOS 27 screen looks like. Design files started now should follow them, since GA is imminent and Xcode 27 has no compatibility opt-out.

**macOS 27**

- **Uniform frosted toolbar.** Tahoe let each app choose between very transparent and frosted toolbars, so buttons in Photos were hard to see while Reminders looked fine. Golden Gate standardizes on one frosted treatment across every app, so scrolled content no longer competes with toolbar controls. Design the toolbar as frosted glass (higher frost, lower refraction), not clear glass, and expect the system to apply it to standard toolbars automatically.
- **Edge-to-edge sidebars.** Tahoe's sidebar read as a glass sheet floating on top of the window with its own inset corners. In 27 the sidebar extends to the window edges and reads as built into the window. Still translucent and still ambient-reflective of the desktop, but no inset, no floating corner radius on the sidebar itself.
- **Colored sidebar icons, active window only.** Sidebar icons regain color, but only in the frontmost window; inactive windows show monochrome sidebar icons. Design both states. Pair with `@Environment(\.appearsActive)` in SwiftUI.
- **Standardized window corner radius.** One radius for every app window, applied by the system, including third-party apps that never updated. Deeper window shadows to separate stacked windows. Don't design a custom window radius.
- **Sparser menu icons.** Tahoe put an icon next to nearly every menu item; 27 goes back to selective icons. A new API surfaces app action icons in menus but they're hidden by default.
- **Reduced icon glass distortion** so app icons read crisper. Squircle unchanged.

**iOS 27 / iPadOS 27**

- **Reduced default transparency** plus darkened edges and brighter specular highlights on glass elements. Glass diffuses complex content more, so text over busy scrolling content stays legible. The floating tab bar, sheets, and toolbars remain glass; they're less see-through by default than iOS 26.
- **Unified top toolbar when content scrolls under floating bars.** The system swaps to a uniform toolbar treatment in that situation automatically for standard toolbars, adjustable through the existing scroll-edge-effect APIs.
- **Sidebars edge-to-edge on iPadOS** with the same colored-icon-when-active behavior as macOS.
- **Tab bar** stays the floating glass capsule from iOS 26 (inset from the screen edges, minimizes on scroll). The search tab role still places a separate floating search button at the trailing edge; outlet coverage describes search being "re-integrated with navigation" but no primary-source detail has surfaced, so design search as the iOS 26 floating trailing button until a beta shows otherwise `[Unverified]`.
- **App icons** carry extra glass layers with refraction between them; Icon Composer supports multi-layer glass with per-layer refraction annotation.
- **System-wide Liquid Glass slider** (also on iPadOS and macOS): ultra clear at one end, fully tinted at the other, default centered. `.glassEffect()` picks it up with no code. Design at the default midpoint; the ultra-clear end is what iOS 26 shipped with.

**Not changed, and still the baseline**: SF Pro, SF Symbols, system semantic colors, push navigation, inset sheets with glass backgrounds, large titles that collapse, glass on the navigation layer only and never on content.

**Practical read for a design file in September 2026**: build to iOS 27 / macOS 27. The changes are all in the direction of legibility and restraint (frost over clear, structure over floating), and none of them require a new API. A file built to Tahoe's floating sidebar and clear toolbars will look dated the week GA ships.

## SwiftUI additions in iOS 27 / Xcode 27

Confirmed against Apple's own WWDC 2026 "What's New in SwiftUI" session transcript, not just secondhand coverage:

- New Document API: `WritableDocument` / `ReadableDocument` protocols replace the older document protocols, with `nonisolated`/`async` disk writes, snapshot diffing, and progress reporting via Foundation's `Subprogress`. `DocumentCreationSource` plus `NewDocumentButton` support multiple document-creation flows.
- Reorderable containers: `.reorderable()` on `ForEach` plus `.reorderContainer(for:)` on the container gives drag-to-reorder in `List`, `LazyVGrid`, and custom layouts without hand-rolled `onMove` plumbing. New to watchOS for the first time. `.swipeActionsContainer()` extends swipe actions outside `List` to any `ScrollView`.
- `@State` is now a macro. `@Observable` classes stored in `@State` initialize lazily, once per view lifetime, and survive if the parent view reinitializes. Backported to iOS 17, macOS 14, and aligned OS releases. Breaking change: a `@State` property can no longer carry a declaration-site default value if it's also assigned in `init` -- remove the default.
- `AsyncImage` supports standard HTTP caching by default, respecting server cache headers with no code changes. A `URLRequest`-based initializer gives explicit cache-policy control, and `.asyncImageURLSession()` supplies a custom `URLSession`/`URLCache`.
- Toolbar changes: `.visibilityPriority()` controls which items stay visible under space pressure, `ToolbarOverflowMenu` groups lower-priority items into an overflow menu, `.topBarPinnedTrailing` pins critical actions (e.g. share) to the trailing edge, and `.toolbarMinimizeBehavior()` auto-collapses the navigation bar on scroll. `labelStyle(.titleAndIcon)` shows icons in menu items; tabs gain a `.prominent` role for a highlighted tab (e.g. a cart).
- On macOS, Liquid Glass elements marked `.interactive()` track the mouse pointer more fluidly (optimized for mouse, not trackpad/touch). A new `appearsActive` environment value (`@Environment(\.appearsActive)`) replaces the deprecated `controlActiveState` for detecting window focus -- useful for dimming custom UI (sidebar labels, account buttons) when the window isn't active.

## What to do with this file

Don't treat anything above as an API contract. Before writing code against an iOS-27-specific API: check Apple's official SwiftUI release notes and API diffs for the SDK version actually installed, not this file. This file exists so a design/implementation task started in August 2026 doesn't silently assume the iOS 26 API surface is the final word -- it's a pointer to go verify, not a substitute for verification.

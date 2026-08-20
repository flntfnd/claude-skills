# iOS 27 / iPadOS 27 / macOS 27 "Golden Gate" Status

Everything else in this skill targets iOS 26 / iPadOS 26 / macOS Tahoe 26 (Xcode 26 SDK) as the stable baseline. This file tracks the next major version, announced at WWDC 2026 (June 8, 2026). Treat this whole file as time-sensitive and re-verify before depending on specifics -- betas move.

## Version and release status

As of mid-August 2026: iOS 27, iPadOS 27, and macOS 27 "Golden Gate" are in public and developer beta (developer beta 6 / public beta 4 shipped August 17, 2026). Apple's own naming for macOS 27 is "Golden Gate." Expected general release is September 2026, alongside new iPhone hardware, per the normal fall cadence. **iOS 26 / iPadOS 26 / macOS Tahoe 26 remain the correct stable pin for any app shipping before that release.** Don't target iOS 27 APIs as the baseline until it's GA.

## Liquid Glass changes (confirmed direction, unverified specifics)

Apple responded to public criticism of iOS 26's Liquid Glass with user-facing and developer-facing adjustments in iOS 27, corroborated across multiple outlets covering the WWDC 2026 keynote and Platforms State of the Union:

- A user-facing option to reduce or "dial back" Liquid Glass's visual intensity, separate from the existing Reduced Transparency accessibility setting. `[Unverified]` The exact API surface (a new environment value, a system setting only, or both) is not confirmed -- check Apple's iOS 27 release notes / SwiftUI changelog before writing code against it.
- A "layered approach" to Liquid Glass shown in Apple's own apps, described as a refinement of the same material system rather than a replacement. `[Unverified]` No new `Glass` case names (beyond `.regular` / `.clear` / `.identity`) have been confirmed from a primary source.
- The `UIDesignRequiresCompatibility` Info.plist key, which let apps opt out of Liquid Glass entirely on iOS 26, is widely reported to stop working once an app recompiles against the iOS 27 SDK. This matches Apple's own WWDC25 Platforms State of the Union guidance that the flag was temporary and intended for removal "in the next major release." Treat this as high-confidence but still verify against the shipping iOS 27 release notes before telling a team their compatibility window is closed.

## SwiftUI additions reported for iOS 27 / Xcode 27

These are corroborated by developer-focused coverage of WWDC 2026 sessions (not just user-facing tech press), so confidence is higher than the Liquid Glass intensity item above, but still unverified against Apple's primary documentation:

- `[Unverified]` New SwiftUI Document API.
- `[Unverified]` Reorderable containers -- drag-to-reorder support built into `List` and `LazyVStack` without hand-rolled `onMove` plumbing.
- `[Unverified]` `@State` becomes a macro, so observable classes captured in `@State` are only initialized once; reported as backported to iOS 17.
- `[Unverified]` `AsyncImage` gains HTTP caching.
- `[Unverified]` Toolbar changes: minimal menu icons by default, plus new overflow-menu and pinned-trailing placement options.
- `[Unverified]` On macOS, custom interactive Liquid Glass elements track the mouse pointer more fluidly, with an `appearsActive` environment value mentioned for tighter opt-in control.

## What to do with this file

Don't treat anything above as an API contract. Before writing code against an iOS-27-specific API: check Apple's official SwiftUI release notes and API diffs for the SDK version actually installed, not this file. This file exists so a design/implementation task started in August 2026 doesn't silently assume the iOS 26 API surface is the final word -- it's a pointer to go verify, not a substitute for verification.

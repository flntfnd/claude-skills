# Tributary for iOS

The iOS 27 app from `concepts/rss-reader/CONCEPT.md`, built to the Figma file linked there. SwiftUI only, SwiftData with CloudKit for local mode, a pure-Swift core package for parsing and the archive format.

Status: written without a compiler. This directory was authored in a Linux container that has no Xcode and no Swift toolchain, so nothing here has been built yet. The first thing to do on the Mac is open it in Xcode 27 beta, build, and work through the verification list below.

## Layout

```
Tributary.xcodeproj            Xcode 27 project. Synchronized folder groups, so adding a file is adding a file.
Tributary/
  App/                         @main, settings store
  Models/                      SwiftData models (CloudKit-compatible: defaults everywhere, optional relationships)
  Design/                      DesignSystem tokens matching the Figma variables, shared components
  Services/                    Refresh (ModelActor), fetcher, subscriber, background refresh, archive, importers, intelligence
  Features/                    Onboarding, Root tabs, Today, Timeline, Feeds, Saved, Search, Settings, Reader
  Intents/                     App Intents: Save Link, Refresh Feeds
  Assets.xcassets              Color sets, one per semantic token, light and dark
  Info.plist / entitlements / PrivacyInfo.xcprivacy
Packages/TributaryCore/        SwiftPM, no dependencies, builds on Linux
  FeedParser (RSS 2.0, RDF, Atom, JSON Feed), HTMLTokenizer, HTMLBlocks (HTML -> ContentBlock),
  ArticleExtractor, FeedDiscovery, CanonicalURL, StoryClusterer, OPML, FetchScheduler
  Tests/                       Swift Testing suites for every one of those
```

The core package is where the shared Rust core (CONCEPT.md section 9) will eventually plug in. Its public types are the contract; the implementations behind them are the ones that get replaced.

## Building

1. Open `Tributary.xcodeproj` in Xcode 27 beta.
2. Set your team under Signing. The bundle id is `com.flntfnd.tributary`; the iCloud container is `iCloud.com.flntfnd.tributary`. Both need to exist in your developer account, or change them.
3. Build for an iOS 27 simulator. Background refresh and CloudKit sync need a device.
4. Run the package tests: select the `TributaryCore` scheme and press Test, or `swift test` inside `Packages/TributaryCore` on any Mac with Swift 6.2.

## Verify against the iOS 27 SDK

These are the places where the code leans on APIs I could not check against the beta SDK. Grep for the marker and confirm each against the `.swiftinterface` files in `Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/`.

| Where | What to confirm |
| --- | --- |
| `SavedView.swift`, `UpNextView` | `TODO(iOS 27)`: replace `.onMove` with `.reorderable()` on the ForEach plus `.reorderContainer(for:)` on the container. Signatures unverified. |
| `RootView.swift` | `Tab(_:systemImage:value:role:)` with `.search`, `.tabBarMinimizeBehavior(.onScrollDown)`, `.tabViewStyle(.sidebarAdaptable)`. All iOS 26; confirm nothing was renamed. |
| `ReaderView.swift`, `Components.swift`, `OnboardingView.swift` | `.glassEffect(_:in:)`, `GlassEffectContainer(spacing:)`, `.buttonStyle(.glass)`, `.buttonStyle(.glassProminent)`. iOS 26 Liquid Glass; the 27 material changes need no code. |
| `Intelligence.swift` | `SystemLanguageModel.default.availability` cases and `LanguageModelSession(instructions:)` / `respond(to:)` from FoundationModels. |
| `TributaryApp.swift` | `.backgroundTask(.appRefresh(_:))` on the scene, and `ModelConfiguration(_:schema:cloudKitDatabase:)`. |
| Project settings | `SWIFT_APPROACHABLE_CONCURRENCY`, `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY`, `objectVersion = 77` synchronized groups. If Xcode 27 changed defaults, accept its migration. |
| `AppIntents.swift` | `AppShortcutsProvider` builder syntax and `ProvidesDialog`. |

Toolbar additions from the WWDC 2026 session (`.visibilityPriority()`, `ToolbarOverflowMenu`, `.topBarPinnedTrailing`) are not used yet. The reader's trailing toolbar is the natural place for them once verified.

## What works in this milestone

- Onboarding with the storage choice. Account mode is a real screen with disabled sign-in buttons, because the service does not exist yet.
- Local mode: on-device fetching with conditional GET and an adaptive scheduler, SwiftData with CloudKit private-database sync, background refresh.
- Today with lanes, deterministic story clustering, daily caps, snooze, resurfacing, Ambient as a count, mark-all-read, loading, empty, and error states.
- Timeline, Feeds with health and hygiene, Add Feed with discovery and preview, OPML import with preview, Saved with grid, list, stacks and Up Next, Search with `feed:` and `author:` operators, Settings.
- Reader: structured blocks (headings, quotes, figures with captions, code, lists), on-device extraction for truncated feeds, honest paywall notice, typography controls, read-aloud with the paragraph being spoken highlighted, Handoff activity, on-device summaries through Foundation Models when enabled.
- Archive export as a folder (OPML, JSON Lines state, JSON Feed plus Markdown plus HTML per saved article, highlights), and a continuous mirror into iCloud Drive.
- App Intents for Save Link and Refresh.

## Not in this milestone

- Share extension and widgets (separate targets). Save Link via the App Intent covers the share-sheet path for now.
- Highlight creation UI. The model, export, and Markdown are in place; text selection in SwiftUI `Text` needs the reader to move to a selectable representation first.
- Notifications. The setting exists; scheduling local notifications for Priority-lane items is the next service.
- Rules engine, comment feeds, follow-the-author, related-from-your-feeds, article diffs (the update count is tracked and shown; the diff view is not built).
- The shared Rust core. Parsing and extraction are Swift here, behind the same public types.

## App Store notes

- `NSAllowsArbitraryLoads` is set because users subscribe to arbitrary feeds and a meaningful share of them are plain HTTP. Justify it in review notes; it is the standard RSS-reader exception.
- No analytics, no tracking, no third-party SDKs. `PrivacyInfo.xcprivacy` declares no collected data and the two required-reason APIs in use.
- Sign in with Apple will be mandatory the moment Google sign-in ships (guideline 4.8). The onboarding already shows it first.

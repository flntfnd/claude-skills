# Tributary: a modern RSS reader and aggregator

Working name only. "Tributary" is the placeholder because the product is many streams feeding one river. Rename freely.

Targets: iOS, iPadOS, macOS, Android, web. Windows is out of scope for the first release; the web app covers it. Status: concept, September 2026. Nothing here is built.

---

## 1. Why now

The three incumbents are failing in three different ways, and the gaps don't overlap with each other.

| Product | State in 2026 | What that leaves open |
| --- | --- | --- |
| Feedly | Pivoted to cyber threat intelligence. Homepage sells CTI, not reading. Week-long consumer outage in August 2026, classic iOS app shut down without notice, support tickets ignored. Third-party clients get rate-limited and banned (NetNewsWire had to rewrite its Feedly sync in 7.1.3 to stop users being locked out). | A consumer-first sync service that treats readers as the product, not a funnel. |
| NetNewsWire | Healthy, free, fast, honest. Apple-only, client-only, no web, no Android. Design is stock SwiftUI lists with no reading-experience layer. 7.x work has gone into sync diagnostics and iCloud storage trimming, not the reading surface. | Native quality on Apple with the same quality everywhere else, plus a reading experience worth opening the app for. |
| Inoreader | The most capable filtering engine in the category. 2026 roadmap is Teams dashboards, Teams sidebars, shared Team resources, enterprise OAuth. Consumer UI dates from the 2024 refresh and mobile apps trail the web by years. Filters are metered (50 per Pro account). | Powerful rules with a modern interface and no quotas that feel like punishment. |

The newer entrants each solve part of it and leave the rest:

- **Reeder (2024 rewrite)** is a beautiful Apple-only timeline with iCloud sync and no server. It dropped third-party sync services, so it can't be your hub if you also use Android or a browser.
- **Folo** is the most-starred open-source reader ever and is cross-platform, but it's a web-tech shell (Electron on desktop, Expo on mobile), leads with AI, and layers a social "follow" graph and gamification on top of RSS. It looks the same on every platform, which means it looks native on none.
- **Readwise Reader** is a knowledge-capture workflow at $8.99 a month. Excellent if highlighting into Obsidian is the job. Heavy if the job is reading the morning's feeds.
- **Miniflux and FreshRSS** are the self-hosted backbone for people who run servers. They are why the Google Reader API is still the lingua franca of native clients.

Nobody is shipping: native-quality apps on all four platforms, backed by a first-party sync service that is open to third-party clients, with a reading experience that's the point rather than an afterthought, and a business model that doesn't require an enterprise pivot to survive.

That's the product.

---

## 2. Positioning

**One line:** the reader you'd build if reading were the whole business.

**Principles, in priority order:**

1. **Native on every platform.** SwiftUI on Apple, Jetpack Compose on Android, Next.js on the web. Each app looks like the platform owner made it. Shared design tokens and information architecture, platform-specific chrome and behavior. No shared UI runtime.
2. **The account is optional.** Two modes, chosen on first launch, switchable later without loss. Local mode keeps everything on the device and syncs through iCloud, no account at all. Account mode signs in with Google or Apple and moves fetching to the server, which is what unlocks the web app, newsletters, and third-party clients. Section 3 is the whole design.
3. **Own the sync layer, keep it open.** In account mode: server-side fetching, one fetch per feed for every subscriber, delta sync to clients. Expose the Google Reader API dialect so NetNewsWire, Reeder Classic, Unread, Lire, and every self-hosted-compatible client work on day one. The lock-in is that it's good, not that it's closed.
4. **Reading is the feature.** Full-text extraction, real typography, read position that follows you, offline by default. The reader pane is where the design budget goes.
5. **Triage without an algorithm.** No engagement ranking, ever. Deterministic tools instead: rules, mutes, volume caps, priority lanes, digest grouping. The user can always explain why an item is where it is.
6. **AI is opt-in, bring-your-own or on-device, and never the default.** Summaries and translation through the user's own API key or the platform's on-device model. Nothing leaves the device or account without the user turning it on. Nothing is used for training.
7. **Everything is a feed.** RSS, Atom, JSON Feed, newsletters via a private ingest address, YouTube channels, podcasts, Bluesky and Mastodon accounts, Reddit, and generated feeds for sites that don't publish one.
8. **If it's in the app, it's in the export.** Every byte of user data round-trips through one open archive format: OPML, JSON Feed, Markdown, and JSON. Importers for every reader people are leaving. Round-trip is an integration test, not a promise. Section 4 is the spec.
9. **No tracking.** No analytics SDKs, no fingerprinting, no reading-behavior telemetry. Fetching happens server-side so publishers see one crawler, not each reader's IP. Images go through a referrer-stripping proxy.

---

## 3. Where your data lives

The first screen after install asks one question. The answer can change later and nothing is lost either way.

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│   Where should Tributary keep your feeds?                        │
│                                                                  │
│   ┌──────────────────────────┐   ┌──────────────────────────┐    │
│   │  On this device          │   │  Tributary account       │    │
│   │                          │   │                          │    │
│   │  No account. Feeds are   │   │  Sign in with Google or  │    │
│   │  fetched here and stored │   │  Apple. Feeds are        │    │
│   │  here. Synced between    │   │  fetched by the service  │    │
│   │  your Apple devices      │   │  and synced everywhere,  │    │
│   │  through iCloud.         │   │  including the web.      │    │
│   │                          │   │  Adds newsletters,       │    │
│   │  Free, no limits.        │   │  generated feeds, and    │    │
│   │                          │   │  other reader apps.      │    │
│   └──────────────────────────┘   └──────────────────────────┘    │
│                                                                  │
│   You can switch later. Everything moves with you.               │
└──────────────────────────────────────────────────────────────────┘
```

| | Local mode | Account mode |
| --- | --- | --- |
| Identity | None. No email, no sign-up. | Google, Apple, or passkey through Supabase Auth. No passwords. |
| Fetching | On the device, using the shared Rust core. | On Railway, once per feed for every subscriber. |
| Storage | SwiftData on Apple, Room on Android. | Postgres on Supabase, with the same on-device store as an offline cache. |
| Sync | iCloud on Apple devices. Google Drive app data on Android. The two don't cross. | The service. Every platform, including web. |
| Backup you can read | A continuously maintained archive folder in iCloud Drive (or a chosen folder on Android). | Scheduled archive export to iCloud Drive, Google Drive, or download. |
| Platforms | iOS, iPadOS, macOS, Android. | All of those plus web. |
| Newsletters, generated feeds | No. Both need a server. | Yes. |
| Third-party clients | No. There's no endpoint. | Yes, Google Reader API. |
| Search | On-device, everything cached. | Server-side, everything ever received. |
| Refresh timing | When the OS allows background work. Less timely; the OS decides. | Continuous, with push for WebSub feeds. |
| Publisher sees | Your device's IP, once per feed per refresh. | One crawler. |
| AI | On-device and bring-your-own-key. | Those plus hosted. |
| Price | Free, no feed limit. There's no server cost to recover. | Free tier and paid tier, section 12. |

### Local mode

The user's words for this are "local only" and "iCloud Drive". Under the hood that's two different iCloud mechanisms doing two different jobs, and the split matters.

**Live state syncs through CloudKit**, the private database, via SwiftData's CloudKit integration. It shows up to the user as "iCloud" in Settings, exactly like Notes or NetNewsWire's iCloud account. CloudKit merges per record. Two devices marking different items read at the same time both win.

**iCloud Drive holds the archive, not the database.** A `Tributary` folder in iCloud Drive that the app keeps current with the full export format from section 4: OPML, JSON Feed, Markdown, JSON. Visible in Finder and Files, readable without the app, and the thing you'd grab if the app disappeared tomorrow. It is never read back by the app on its own; it is written to.

Why not sync the database itself through iCloud Drive: iCloud Drive doesn't merge, it forks. Two devices writing the same file produces two files. Putting a live SQLite store in a ubiquity container is how readers corrupt their stores, and it's the reason every serious Apple app that says "iCloud sync" means CloudKit. The user gets what they asked for, a local-only reader whose data lives in iCloud Drive as their own files, without the failure mode.

**Android local mode** has no CloudKit. Sync goes through the Google Drive app-data folder as a change journal plus periodic snapshot: coarser than CloudKit, good enough for read state and subscriptions across a phone and a tablet. The archive mirror writes to a user-chosen folder through the Storage Access Framework, which can itself be a Drive folder. Local mode on Android is decision 8 in section 11; shipping it without cross-device sync in the first release is a legitimate option.

**Fetching on the device** uses the same Rust core the server uses (section 9), so a feed parses identically in both modes. Background refresh is `BGAppRefreshTask` on iOS and iPadOS, a timer while the app is running on macOS, and `WorkManager` periodic work on Android with its 15-minute floor. Full-text extraction runs on-device through the same core. There's no image proxy, so images load direct; the mode picker says so.

**Web is account-only.** A browser can't fetch arbitrary feeds cross-origin, so there is nothing for local mode to run on. The web app is the account mode's fifth client, not a sixth mode.

### Account mode

Supabase Auth with three providers and no password option:

- **Google.** Credential Manager on Android, the Supabase OAuth flow through `ASWebAuthenticationSession` on Apple, standard OAuth on web.
- **Apple.** Required by App Store guideline 4.8 the moment Google is offered on iOS or macOS. Offered on Android and web too, so an account created on an iPhone works everywhere.
- **Passkey.** For people who want neither. Email magic link as the recovery path.

Everything in section 9's architecture is account mode. Local mode never touches Railway or Supabase.

### Switching

The archive format is the bridge, in both directions.

```
Local ──▶ Account     Sign in. The app writes a full archive, uploads it,
                      the service adopts each feed by canonical URL and
                      replays state. The on-device store is re-pointed at
                      the service and becomes the offline cache. CloudKit
                      records are left in place until the user clears them
                      from Settings, so a second device can still finish
                      its own migration.

Account ──▶ Local     The app downloads the full archive, seeds the local
                      store from it, and turns on CloudKit. Then it offers
                      account deletion on the same screen. Deletion is
                      immediate and complete on the server side. The
                      archive the user was just handed is the copy.
```

Mode is a per-device choice. Apple devices in local mode sync with each other through iCloud; devices signed into an account sync through the service. A Mac in local mode and a phone on an account don't sync, and the app says so rather than pretending.

---

## 4. Import and export

If it's in the app, it's in the export. Every export is a full copy, every import is idempotent, and export-wipe-import producing identical state is an integration test that runs in CI against every client.

### The archive

One format, used for manual exports, scheduled backups, the iCloud Drive mirror in local mode, and mode switching. A folder in the mirror, a zip everywhere else.

```
Tributary Export 2026-09-07/
├── manifest.json            format version, app version, mode, created_at, counts
├── subscriptions.opml       OPML 2.0. Folders as nested outlines. Lane, muted,
│                            custom title, and per-feed reader preference as
│                            attributes in a tributary: namespace, ignored by
│                            every other reader and round-tripped by this one.
├── rules.json               every rule, match and action
├── settings.json            typography, theme, density, keyboard, notification prefs
├── state/
│   ├── items.jsonl          one line per item you have state on:
│   │                        { feed_url, guid, url, read, saved, read_position,
│   │                          snoozed_until, tags, note, updated_at }
│   ├── queues.json          Up Next and Weekend, as ordered lists of (feed_url, guid)
│   └── stacks.json          each stack as an unordered set of (feed_url, guid),
│                            with its optional name and created_at
├── saved/                   a vault. Open this folder in Obsidian and it just works.
│   └── <feed-slug>/
│       ├── feed.json        JSON Feed 1.1 holding every saved item from that
│       │                    feed with its extracted content
│       ├── <item-slug>.md   the article as Markdown with YAML front matter
│       │                    (title, url, feed, author, published, saved_at,
│       │                    tags, stacks) and the user's highlights as
│       │                    blockquotes at the end
│       ├── <item-slug>.html the same article as a self-contained page,
│       │                    images inlined, so it opens in any browser
│       └── <item-slug>/     the article's images, referenced relatively
│                            from the Markdown
├── highlights/
│   ├── highlights.json      { feed_url, guid, quote, note, position, created_at }
│   └── <source>.md          one Markdown file per source, in the shape Obsidian
│                            and Readwise already accept
└── newsletters/             account mode only
    └── senders.json         sender, ingest address, folder
```

**Item identity is (canonical feed URL, guid), with the item URL as fallback.** That's the same key the Google Reader API uses, so read and saved state survives not just a move between modes but a move to a different reader entirely.

**Why these formats.** OPML because every reader in existence imports it. JSON Feed because it's the standard for items and it makes the saved folder something you can point any reader at and subscribe to. Markdown for highlights because that's what note apps eat. JSON only for what has no standard: rules, settings, per-item state.

### Export

- **Anytime, from Settings.** Share sheet and Files on Apple, Storage Access Framework on Android, download on web. Full archive or a partial one: OPML only, saved only, highlights only.
- **Scheduled.** Weekly by default in account mode, to iCloud Drive, Google Drive, or a chosen folder. Local mode doesn't need this; the mirror is continuous.
- **Before anything destructive.** Switching mode, deleting the account, or dropping to the free tier with more feeds than it allows: the app writes the archive first and shows where it put it.
- **Account deletion hands you the archive first.** The delete button is disabled until the export has completed or the user explicitly declines it.
- **The Reader API is an export.** In account mode any compatible client can pull full state at any time. No special path needed.

### Import

| Source | What comes across | How |
| --- | --- | --- |
| Tributary archive | Everything | Pick the folder or zip. |
| Any OPML | Feeds and folders | Every reader exports one. |
| Feedly | Feeds, folders, Read Later, read state | OPML upload, plus a one-time Feedly sign-in for saved and read state through their API. The token is used once and discarded. |
| Inoreader | Feeds, folders, tags, starred | OPML plus their JSON export. |
| Feedbin | Feeds, tags, starred, read state | Their API, one-time. |
| NetNewsWire | Feeds and folders | OPML. Read and starred state lives in its iCloud account and isn't exportable, and the importer says so up front rather than implying it came across. |
| Miniflux, FreshRSS, any Google Reader API server | Feeds, folders, starred, read state | Reader API pull with the user's credentials for that server. |
| Instapaper, Readwise Reader, Pocket export | Saved articles | Their CSV or JSON, imported as saved items and re-extracted. |
| Readwise | Highlights | Their export, matched to items by URL. |

Import behaviors that hold for every source:

- **Preview before commit.** "412 feeds in 14 folders, 88 saved, 1,203 highlights. 31 feeds are already subscribed and will be skipped." Then a single confirm.
- **Dedupe by canonical URL.** Feed URLs are normalized before comparison (scheme, trailing slash, tracking parameters, known redirect hosts).
- **State merges by max.** Read beats unread, saved beats unsaved, the later read position wins. An import never un-reads anything.
- **Resumable and idempotent.** Running the same import twice produces the same result as running it once. A failed import halfway through can be re-run.
- **Same code in both modes.** The importer lives in the Rust core, so local mode and account mode import identically, and the server-side importer for account mode is the same crate.

### Testing

Three test classes, all integration, all in CI:

1. **Round-trip.** Seed a client with a fixture state, export, wipe, import, diff. Any difference fails the build.
2. **Cross-mode.** Export from a local-mode fixture, import into an account-mode fixture, and back. Diff.
3. **Competitor fixtures.** Real OPML and export files from each source in the table, kept as fixtures, with expected results. When Feedly changes its export shape, the test says so before a user does.

---

## 5. Information architecture

Five top-level destinations, identical across platforms, surfaced through each platform's own navigation pattern.

```
Today        Triage inbox. Unread, grouped by priority lane, then folder.
             High-volume feeds collapse to a count, same stories collapse
             to one row, snoozed items return here. This is the home screen.

Timeline     Everything in chronological order. Filter: All / Unread / Saved.
             The "just show me the river" view for people who hate inboxes.

Feeds        The subscription tree. Folders, feeds, tags, feed health.
             Add, organize, mute, set per-feed rules here.

Saved        Read-later for anything: feed items, URLs saved from any app,
             highlights, tags. Full-text searchable. Exportable.

Search       Full-text search across everything you've ever received,
             not just what's cached on device.
```

Three lanes define how Today is ordered. They're user-assigned per feed, with a default of Normal.

```
Priority     Feeds you never want to miss. Always expanded, always first.
Normal       The default. Grouped by folder, most recent first.
Ambient      High-volume or low-stakes feeds. Collapsed to "N new from X".
             Never notify. Auto-mark-read after a configurable age.
```

Rules run server-side on ingest and can: move to a lane, mute (never show), star, tag, mark read, or notify. Rules match on feed, folder, title, body, author, URL pattern, and item age. There is no cap on rule count.

---

## 6. Screen concepts

### macOS and iPadOS: three panes

```
┌────────────────────────────────────────────────────────────────────────────────┐
│ ● ● ●   ‹ ›   Tributary                          ⌕ Search        ↻   ☆   ⋯      │  ← glass toolbar
├───────────────┬────────────────────────┬───────────────────────────────────────┤
│  TODAY     42 │ Priority             3 │                                       │
│  Timeline     │ ─────────────────────  │   The Verge                           │
│  Saved     17 │ ▌Daring Fireball       │   Apple's new Studio Display          │
│  Search       │ ▌ Apple's Studio D…    │   is a bet on the desk                │
│               │ ▌ 2h  ●               │   Nilay Patel · 2h · 6 min            │
│  FEEDS        │                        │ ───────────────────────────────────── │
│  ▾ Tech    18 │ ▌The Verge             │                                       │
│    The Verge  │ ▌ Studio Display is…   │   The thing about a display that      │
│    Ars        │ ▌ 2h  ●               │   costs more than the computer it's   │
│    Daring F.  │                        │   plugged into is that it has to      │
│  ▾ Design   6 │ Tech                 18 │   justify itself every morning …      │
│    Sidebar    │ ─────────────────────  │                                       │
│    Brand New  │ ▌Ars Technica          │   ┌─────────────────────────────┐     │
│  ▾ Ambient 1k │ ▌ Reviewing the M5…    │   │                             │     │
│    Hacker N.  │ ▌ 4h                   │   │        (inline image)        │     │
│    r/swift    │ ▌Ars Technica          │   │                             │     │
│               │ ▌ Linux 7.2 lands…     │   └─────────────────────────────┘     │
│  + Add feed   │ ▌ 5h                   │                                       │
├───────────────┴────────────────────────┴───────────────────────────────────────┤
│  1 of 42 unread · j/k next/prev · s save · m mark read · o open               │  ← macOS only
└────────────────────────────────────────────────────────────────────────────────┘
```

Sidebar and toolbar are the navigation layer and take the glass treatment. The list and the reader are content and take none. Reader pane typography is the one place where the app departs from system defaults, and that departure is a Figma decision, not something to fill in during implementation (see section 11).

### iPhone

```
┌─────────────────────────┐        ┌─────────────────────────┐
│ ▓▓▓▓ status ▓▓▓▓▓▓▓▓▓▓  │        │ ▓▓▓▓ status ▓▓▓▓▓▓▓▓▓▓  │
│                         │        │ ‹ Today            ☆  ⋯ │
│  Today             ⋯    │        │                         │
│                         │        │  THE VERGE              │
│  PRIORITY               │        │  Apple's new Studio     │
│  ┌─────────────────────┐│        │  Display is a bet on    │
│  │ Daring Fireball  2h ││        │  the desk               │
│  │ Apple's Studio Di…  ││        │  Nilay Patel · 6 min    │
│  └─────────────────────┘│   →    │                         │
│  ┌─────────────────────┐│        │  The thing about a      │
│  │ The Verge        2h ││        │  display that costs     │
│  │ Studio Display is…  ││        │  more than the computer │
│  └─────────────────────┘│        │  it's plugged into is   │
│                         │        │  that it has to justify │
│  TECH               18  │        │  itself every morning…  │
│  ┌─────────────────────┐│        │                         │
│  │ Ars Technica     4h ││        │                         │
│  │ Reviewing the M5 …  ││        │                         │
│  └─────────────────────┘│        │                         │
│                         │        │ ┌───────────────────┐   │
│  AMBIENT                │        │ │  ✓ Read    ↗ Open │   │  ← floating glass
│  › 212 new from Hacker  │        │ └───────────────────┘   │     action bar
│    News, r/swift        │        │                         │
│ ┌───┬───┬───┬───┐       │        │                         │
│ │ ◉ │ ≡ │ ☆ │ ⌕ │       │        │                         │
│ └───┴───┴───┴───┘       │        │                         │
│ ▓▓▓▓ home ▓▓▓▓▓▓        │        │ ▓▓▓▓ home ▓▓▓▓▓▓        │
└─────────────────────────┘        └─────────────────────────┘
   Today · Feeds · Saved · Search      Reader (push, swipe back)
```

Tab bar is glass and floats above content. Content scrolls behind status bar and tab bar. Large title collapses. Reader is a navigation push with the system back swipe. Swipe actions on list rows: leading = mark read, trailing = save. Both are springs because both are gestures.

### Android

```
┌─────────────────────────┐        ┌─────────────────────────┐
│ ▓▓▓▓ status ▓▓▓▓▓▓▓▓▓▓  │        │ ▓▓▓▓ status ▓▓▓▓▓▓▓▓▓▓  │
│                         │        │ ←                  ☆  ⋮ │
│  Today                  │        │                         │
│                    ⌕  ⋮ │        │  The Verge              │
│                         │        │  Apple's new Studio     │
│  Priority               │        │  Display is a bet on    │
│  ╭─────────────────────╮│        │  the desk               │
│  │ Daring Fireball  2h ││        │  Nilay Patel · 6 min    │
│  │ Apple's Studio Di…  ││        │                         │
│  ╰─────────────────────╯│   →    │  The thing about a      │
│  ╭─────────────────────╮│        │  display that costs     │
│  │ The Verge        2h ││        │  more than the computer │
│  │ Studio Display is…  ││        │  it's plugged into is   │
│  ╰─────────────────────╯│        │  that it has to justify │
│                         │        │  itself every morning…  │
│  Tech               18  │        │                         │
│  ╭─────────────────────╮│        │                         │
│  │ Ars Technica     4h ││        │                         │
│  ╰─────────────────────╯│        │                         │
│                    ╭──╮ │        │        ╭───────────╮    │
│  Ambient           │ +│ │        │        │ ✓    ↗   ⋯│    │  ← FloatingToolbar
│  › 212 new         ╰──╯ │        │        ╰───────────╯    │
│ ┌─────┬─────┬─────┬─────┐        │                         │
│ │  ◉  │  ≡  │  ☆  │  ⌕  │        │                         │
│ │Today│Feeds│Saved│Srch │        │                         │
│ └─────┴─────┴─────┴─────┘        │                         │
│ ▓▓▓ gesture nav ▓▓▓     │        │ ▓▓▓ gesture nav ▓▓▓     │
└─────────────────────────┘        └─────────────────────────┘
   NavigationBar, FAB = Add feed      Reader, predictive back
```

Edge-to-edge, `LargeFlexibleTopAppBar` collapsing on scroll, `NavigationBar` with four destinations, FAB for Add Feed, `FloatingToolbar` in the reader. Dynamic color from wallpaper with a brand fallback. `NavigationRail` replaces the bar at medium width and up, and the list-detail becomes a `ListDetailPaneScaffold`.

### Web

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ Tributary        Today  Timeline  Saved                 ⌕ Search      ◐  RH  │
├──────────────┬─────────────────────────┬─────────────────────────────────────┤
│ Priority   3 │ Priority              3 │                                     │
│ Tech      18 │ ▌Daring Fireball   2h ● │   The Verge                         │
│ Design     6 │ ▌The Verge         2h ● │   Apple's new Studio Display        │
│ Ambient   1k │ Tech                 18 │   is a bet on the desk              │
│              │ ▌Ars Technica      4h   │   Nilay Patel · 2h · 6 min          │
│ + Add feed   │ ▌Ars Technica      5h   │                                     │
│              │                         │   The thing about a display …       │
└──────────────┴─────────────────────────┴─────────────────────────────────────┘
   ≥1024: three panes    768–1023: list + reader, sidebar as drawer    <768: stacked
```

Next.js App Router, Server Components for the shell, a Client Component island for the list and reader with the local cache. Keyboard-first: the same j/k/s/m/o bindings as macOS. Installable PWA with offline reading of anything already synced. Same design tokens as native, expressed as CSS custom properties in one `:root` block.

---

## 7. Reading experience

This is where the product wins or loses. Every reader on the market treats the feed as the unit of work: fetch it, list it, count it. The unread badge is the product. This one treats the article as the unit and the reader's attention as the constraint. The features below are organized by the moment they serve, because a feature that doesn't map to a moment in someone's day is a checkbox, not value.

### Before you read: knowing what's worth it

The most common failure in feed reading is opening the app, seeing a four-digit number, and closing it again. Everything here exists to make the first thirty seconds calm.

- **Feed preview before subscribing.** Paste a URL and see the last ten items, posts per week, whether the feed carries full text or stubs, and how often it's updated. Subscribing is a decision, and today no reader gives you the information to make it. This alone would have saved most people from the feeds they later mute.
- **Volume caps per feed.** "Show me at most 5 a day from this one." The rest are still there in the feed's own view, they just don't enter Today. This is how a high-volume site stays subscribed instead of unsubscribed.
- **Story clustering.** When six feeds cover the same thing, Today shows one row with a "6 sources" chip that expands. Matching is deterministic: shared outbound links, near-identical titles inside a time window, the same canonical URL syndicated through two feeds. No model, no ranking, and the user can see exactly why two items were grouped. Choosing which one leads is a rule: the Priority-lane source if there is one, otherwise the earliest.
- **Cross-feed read state.** The same URL arriving through two feeds is one item with one read state. Reading it once marks it read everywhere.
- **Reading time and length on every row.** Derived from the extracted text, not the summary. A row says "6 min" before you tap it.
- **"I have fifteen minutes."** A time filter on Today that shows only what fits, longest first so the fifteen minutes gets spent on one good thing rather than nine short ones. Small feature, big change to how a commute gets used.
- **Snooze.** Hide an item until tonight, tomorrow morning, or the weekend. Snoozed items come back to the top of Today, unread. This is the missing verb between "read now" and "save forever".
- **Up Next.** A short ordered queue the user builds by swiping. It's a playlist for articles: when one is finished, the next opens, with the total time remaining shown. Reading sessions get a shape instead of being a series of returns to the list.
- **Weekend queue.** A rule-driven queue that collects long items automatically, off by default: "anything over 12 minutes from these folders goes to Weekend". Saturday morning opens to a curated pile rather than an inbox.

### While you read: the page as it should have been

Reader view is the default, and reader view has to be better than the original site, not just cleaner. Most readers stop at "strip the ads". These don't.

- **Extraction that keeps structure.** Headings, lists, tables, block quotes, footnotes, figures with captions, and code blocks survive extraction with their semantics intact. Most extractors flatten these into paragraphs. The core's extractor is tested against a fixture set of real articles from technical blogs, newspapers, Substacks, and long-form magazines, and a regression on any of them fails the build.
- **Code blocks** get syntax highlighting, horizontal scroll rather than wrap, and a copy button. Half the audience for an RSS reader in 2026 reads engineering blogs. Treating code as monospace text is not enough.
- **Footnotes as popovers.** Tap the marker, read the note in place, no scroll to the bottom and back. Sidenotes in the margin on wide layouts.
- **Tables scroll in place** and get a full-width mode. Never squashed, never truncated.
- **Math** renders through MathML, which every target platform now supports natively.
- **Images** open in a lightbox with pinch-zoom, show their captions, surface alt text for VoiceOver and TalkBack, and get a dimming treatment in dark mode instead of glaring. Galleries become swipeable sets.
- **Embeds without trackers.** A social post embedded in an article renders as quoted text with the author and a link, fetched server-side (or on-device in local mode), never through the platform's embed script. YouTube embeds use the privacy-enhanced domain and load on tap.
- **Links know what you know.** A link in an article to something already in your feeds shows a small badge. Tapping it opens the item in the reader, with its own read state, not a browser. A long-press on any link previews the target.
- **Paywalls, honestly.** If the extracted text is a stub because the site meters, the reader says so at the top instead of pretending. "Open in Safari" uses `SFSafariViewController` on Apple and Custom Tabs on Android, which share the system browser's cookies, so subscriptions the user already pays for just work. The product never circumvents a paywall.
- **Dead links fall through to the archive.** When the original returns a 404 or the domain is gone, the reader offers the Wayback Machine snapshot from nearest the item's publish date. Link rot is the one problem every long-time RSS user has and no reader addresses.
- **Listen.** Any article can be read aloud by the platform's own speech engine, with the paragraph being spoken highlighted and read position updated as it goes. A listen queue works like Up Next. It's how a saved pile gets cleared on a walk. No third-party voices, no server.
- **Handoff and continuity.** Start on the iPhone, the Mac's Dock shows the article, one click continues at the same paragraph. On Android, the same via the account-mode sync, surfaced as a "Continue reading" row at the top of Today on the other device.
- **Multiple articles open.** Tabs on the Mac and iPad, multiple windows on both. Comparing two posts shouldn't require Saved as a clipboard.
- **Typography that's yours.** Size, measure, line height, theme (system, light, dark, sepia, and true black for OLED), and a small curated set of faces: the system face, one serif, one humanist sans, one monospace. Per-feed override for the sites whose own design is the point. Reader settings are exported with everything else.
- **Keyboard everywhere on desktop and web.** `j`/`k` through items, `s` save, `m` mark read, `o` open original, `l` listen, `1`–`9` jump to a folder, `/` search, `⌘K` command palette with every action in it. The web app and the Mac app share the same map.

### After you read: keeping what mattered

- **Highlights and notes.** Select text, highlight, optionally add a note. Highlights sync, appear in Saved grouped by article, and export as Markdown in the shape Obsidian, Logseq, and Readwise accept. This overlap with Readwise Reader stays deliberately shallow: capture well, don't become a second brain.
- **Tags on saved items.** Free-form, autocompleted, exportable. Saved is a library, not a pile.
- **Stacks.** Drag two saved items together, or long-press and pick "stack with", and they're a stack: an unnamed group of a few things that belong together this week. No folder, no tag, no name unless you want one. Up Next is the one stack that's ordered. Stacks dissolve as easily as they form. This is the missing primitive between "one article" and "a taxonomy".
- **Quote cards.** Any highlight can become an image: the quote, the attribution, the source, set in the reader's own typography. For the share sheet, not for a feed of them.
- **Share with the quote.** Sharing from a highlight puts the quoted text, the title, and the link on the share sheet together. Sharing from the article puts the title and link. Nothing custom beyond that; the platform sheet does the rest.
- **What changed.** Feeds re-deliver updated articles constantly and every reader either ignores it or marks the item unread again. This one keeps the version you read, shows an "updated" chip, and on tap shows the diff: added paragraphs highlighted, removed ones struck. Corrections stop being invisible.
- **Comment feeds.** Many blogs still publish a per-post comment feed. When one exists, the article's footer shows "12 comments" and expands them inline. Discussion at the source, without a browser.
- **Follow the author.** Extraction picks up the author name and, where the page declares it, their own site, Mastodon, or Bluesky. A byline becomes a "follow" action that subscribes to the author's own feed, not the outlet's.
- **Related, from your own feeds.** "3 of your feeds linked to this article" and "this article links to 2 things you've saved". Built from the link graph of what the user already subscribes to. It's the useful half of recommendations without the algorithm half.
- **Resurfacing.** Saved is a graveyard in every reader, and the fix is not a bigger list. One card in Today, at most one a day, chosen by rule: a saved item older than thirty days that was never opened, or a saved item that something new in your feeds links to, or a saved item from a stack you touched this week. It says why it's there. Dismiss it and it won't return for ninety days; open it and it counts as read. Off switch in Settings. This is the feature that makes saving something feel like it pays back rather than piles up.
- **Grid view.** Saved, and any folder, can switch from the list to a grid of covers at their natural proportions. For design, photography, and architecture feeds the cover is the content, and a title-only list throws it away. A per-folder view setting, remembered, never the home screen.

### Beyond feeds: the one place articles go

Pocket is gone, Instapaper is quiet, and most people's read-later list is a row of Safari tabs. Saved is designed to be that list for everything, not just feed items.

- **Save anything.** A share extension on Apple and a share target on Android accept any URL from any app, extract it with the same core, and file it in Saved with full offline text. The browser extension does the same on desktop, and also shows a subscribe button on any page that publishes a feed.
- **Send to another device.** "Read on Mac" from the phone. In account mode this is a sync flag; in local mode it rides on CloudKit. The article is waiting, open, on the other screen.
- **Widgets.** Home and Lock Screen on iOS, Home Screen on Android, Notification Center on macOS: the Priority lane, the Up Next queue, or a single "continue reading" card. The widget is a doorway to one article, never a badge count.
- **Shortcuts and App Intents, and the Android equivalents.** "Save this", "What's in Priority", "Read my Up Next aloud" as intents that Siri, Shortcuts, Spotlight, and Google Assistant can call. Saved articles are indexed for Spotlight and Android's app search, so the system search finds things you read.
- **Digest.** In account mode, an optional morning email or notification: the Priority lane and story clusters from the last day, formatted for reading, with no tracking pixels. For people who want the reader to come to them one time a day and otherwise stay closed.

### Over time: a reading life, not a reading debt

- **Search everything.** Account mode searches every item ever received, not just what's on the device. Local mode searches everything cached, which is everything since install. Operators for feed, folder, author, date, and saved.
- **Reading review, private and optional.** Off by default. When on, a monthly page computed on the device: what you read, which feeds earned your time, which you never open, the longest thing you finished. Nothing leaves the device, nothing is a streak, nothing is a score.
- **Subscription hygiene.** "You haven't opened anything from these 14 feeds in 90 days" with a one-tap review. Feed health (errors, stale feeds, redirects that should be followed permanently) lives in the same place. The tree stays honest without the user auditing it.
- **Blogrolls.** Opt-in: publish a folder as a public OPML and HTML page, and subscribe to other people's. Discovery through people whose taste you trust, which is how blogs found readers before recommendation engines. This is the only social surface in the product and it is a list of links.
- **Notifications that respect you.** Per-feed, per-rule, or digest-only. A Priority-lane feed can notify on every item; nothing else can without a rule saying so. There is no "you have unread items" nudge and never will be.

### The rule for what gets in

Resurf 2, Raindrop, and Readwise Reader each show how a reading tool becomes an everything box: voice notes, photos, PDFs, freeform notes, a canvas, OCR. Every one of those is a good feature in a different product. The test for this one is two questions, and a feature has to pass both:

1. Does it operate on something that arrived as an article, meaning a feed item or a saved URL? New capture types fail here.
2. Does it make something the user already has get read, revisited, or kept better? Organization for its own sake fails here.

Stacks, resurfacing, quote cards, and the Markdown vault pass. A fourth organization layer, a whiteboard, and a voice recorder don't. This rule is in the concept so the next good idea gets the same filter.

### Where each feature lives

Mode and phase, so nothing above reads as a promise for day one.

| Feature | Local | Account | Phase |
| --- | --- | --- | --- |
| Feed preview, volume caps, snooze, Up Next, reading time, time filter | Yes | Yes | 1 |
| Story clustering, cross-feed read state | Yes, on device | Yes | 1 |
| Structured extraction, code, footnotes, tables, math, images, embeds | Yes | Yes | 1 |
| Link badges, previews, paywall handling, archive fallback | Yes | Yes | 1 |
| Listen, Handoff, multiple windows, typography, keyboard | Yes | Yes | 1 |
| Highlights, notes, tags, share with quote, quote cards | Yes | Yes | 1 |
| Stacks, grid view | Yes | Yes | 1 |
| Saved as a Markdown vault in the archive | Yes | Yes | 1 |
| Resurfacing | Yes | Yes | 2 |
| Save anything (share extension, browser extension) | Yes | Yes | 1 |
| Widgets, App Intents, Spotlight | Yes | Yes | 1 |
| What changed (article diffs) | Yes | Yes | 2 |
| Comment feeds, follow the author, related from your feeds | Yes | Yes | 2 |
| Send to another device | CloudKit only | Yes | 2 |
| Weekend queue, subscription hygiene, reading review | Yes | Yes | 2 |
| Search everything ever received | Cached only | Yes | 0 (service), 1 (clients) |
| Digest email or notification | No | Yes | 3 |
| Blogrolls | Publish via export only | Yes | 3 |
| Ask your saved articles | On-device or BYOK | Plus hosted | 4 |

Every feature in the table works offline once its data is on the device, and every one of them is in the export.

---

## 8. Sources

"Everything is a feed" is implemented as adapters on the fetch service. Each produces normalized items.

| Source | How |
| --- | --- |
| RSS, Atom, JSON Feed | Direct fetch. Conditional GET with ETag and Last-Modified. WebSub subscription where the feed advertises a hub, so those items arrive by push. |
| Newsletters | Each user gets a private ingest address. Inbound mail lands via a mail provider's inbound webhook to a Supabase Edge Function, which enqueues it for the Railway worker. HTML is cleaned into an item. One-click unsubscribe headers are surfaced as a "leave this newsletter" action. |
| YouTube | Channel and playlist feeds, which YouTube still publishes. Thumbnail and embedded player. |
| Podcasts | Standard RSS with enclosures. Episode item, system player handoff. |
| Bluesky, Mastodon | Native feed endpoints (Mastodon publishes RSS per account; Bluesky via its public feed API). |
| Reddit | Subreddit and user RSS. |
| Sites without a feed | A hosted feed generator: the user points at a page, picks the repeating element, and the service produces a feed from it. Change detection with a stable-ID heuristic. This is the RSSHub-shaped feature, first-party and maintained. |
| Bluesky and Mastodon posting-back, X, Instagram | Not supported. X and Instagram have no feed surface worth depending on, and the product does not scrape logged-in services. |

Feed discovery: paste any URL and the service finds the feed (HTML `<link rel>`, common paths, platform-specific patterns for YouTube, Substack, Medium, GitHub releases). Import from OPML and from Feedly, Inoreader, Feedbin, and NetNewsWire directly.

Feed health is visible in the Feeds tab: last successful fetch, error state, posting cadence, and a "stale" list of feeds that haven't posted in a configurable window with a one-tap unsubscribe.

---

## 9. Architecture

Follows the repo's lane rules exactly. Vercel is the web frontend, Railway is the trusted backend, Supabase is data, auth, realtime, and storage. Everything below the clients box is account mode. Local mode is the clients box plus the shared core, and nothing else.

```
                     ┌──────────────────────────────────────────┐
                     │                 Clients                  │
                     │  SwiftUI (iOS/iPadOS/macOS)              │
                     │  Compose (Android)                       │
                     │  Next.js on Vercel (web)                 │
                     │  Third-party (Google Reader API dialect) │
                     └───────┬──────────────────┬───────────────┘
                             │ Supabase JWT     │ Supabase SDK, anon key, RLS
                             ▼                  ▼
┌────────────────────────────────────┐   ┌──────────────────────────────────┐
│           Railway                  │   │            Supabase              │
│                                    │   │                                  │
│  api        Rust/axum. Verifies    │──▶│  Postgres                        │
│             Supabase JWTs via      │   │    feeds, items, subscriptions,  │
│             public key. Serves     │   │    item_state, folders, rules,   │
│             sync deltas, search,   │   │    highlights, ingest_addresses  │
│             discovery, import,     │   │  Auth (Apple, Google, passkeys,  │
│             Reader API compat.     │   │    email)                        │
│                                    │   │  Realtime: per-user "new items"  │
│  fetcher    Rust worker. Adaptive  │──▶│    nudge channel only            │
│             scheduler, conditional │   │  Storage: image proxy cache,     │
│             GET, WebSub receiver,  │   │    OPML/JSON exports (presigned) │
│             extraction, rules      │   │  Edge Functions: inbound mail    │
│             engine, dedupe.        │   │    webhook, WebSub verification, │
│                                    │   │    auth hooks                    │
│  cron       Stale-feed sweep,      │   │                                  │
│             retention, export jobs │   │                                  │
└────────────────────────────────────┘   └──────────────────────────────────┘
```

**The shared Rust core.** One crate, working name `tributary-core`, holds everything that has to behave identically in both modes: feed parsing (RSS, Atom, JSON Feed, the adapter normalizers), full-text extraction, the dedupe fingerprint, canonical URL normalization, the rules engine, and the archive reader and writer from section 4. The Railway fetcher and api link it directly. The Apple and Android clients embed it through UniFFI, which generates the Swift and Kotlin bindings from one interface definition. The web client gets none of it and doesn't need it: web is account-only, so the server does that work.

```
                 ┌──────────────────────┐
                 │   tributary-core     │   Rust. Parse, extract, dedupe,
                 │                      │   normalize, rules, archive I/O.
                 └──┬────────┬────────┬─┘
        native link │        │ UniFFI │ UniFFI
                    ▼        ▼        ▼
              Railway     SwiftUI    Compose
              fetcher     clients    client
              and api     (both      (both
                          modes)     modes)
```

Cost, stated plainly: a Rust toolchain in the Xcode and Gradle builds, an XCFramework and an AAR to produce in CI, and UniFFI's interface file as one more contract to keep in sync. The alternative is three parsers (a Swift one, a Kotlin one, and the server's) that disagree about malformed feeds in three different ways, and three importers that round-trip slightly differently. Local mode makes the shared core the right call, not a nice-to-have.

**Local mode on device.** The client owns a fetch scheduler that mirrors the server's (cadence-derived intervals, conditional GET, backoff) but runs inside the OS's background budget. Items, subscriptions, state, rules, and highlights live in SwiftData or Room with the same shape as the server tables below, minus `user_id`. CloudKit (Apple) or the Google Drive app-data journal (Android) carries the changes between devices. The archive mirror is written by the core after every sync.

**Why the clients talk to both.** User-owned state that's small and per-user (folders, preferences, rules, highlights) goes straight to Supabase under RLS with the anon key, and Realtime on that same connection carries the "you have new items" nudge. Items are shared across every subscriber of a feed, so reading them is a fan-out join that should not be an RLS policy in the hot path. The Railway API serves item sync, search, and extraction results using `service_role`, filtering by the verified user ID explicitly in every query. That split keeps RLS simple enough to `EXPLAIN ANALYZE` and keeps the heavy queries on the trusted side of the lane.

**Why Rust on Railway.** The fetcher holds thousands of concurrent connections, parses malformed XML all day, and runs readability extraction on every item. That's a throughput and memory problem, and it's the shape of work `rust-conventions` already covers (axum, sqlx, tokio discipline, thiserror/anyhow split). One language for api and fetcher means one toolchain and one deploy story. Flagging the cost honestly: Rust is slower to iterate on than TypeScript for the API surface. The recommendation is still Rust, because the API's hot path is the same delta-sync query the fetcher writes into, and splitting languages across that boundary is where bugs live.

**Data model, the important tables:**

```
feeds            id, canonical_url, title, site_url, hub_url, etag, last_modified,
                 fetch_interval, next_fetch_at, error_count, last_error, adapter
items            id, feed_id, guid, url, title, author, published_at,
                 summary_html, content_html (extracted), content_text (for search),
                 media (jsonb), fingerprint (dedupe)
subscriptions    user_id, feed_id, folder_id, custom_title, lane, muted
item_state       user_id, item_id, read, saved, read_position, updated_at, seq
folders          user_id, id, name, sort
rules            user_id, id, match (jsonb), action (jsonb), enabled
highlights       user_id, item_id, id, quote, note, position, created_at
ingest_addresses user_id, address, feed_id
change_log       user_id, seq (bigserial), table, row_id, op, at
```

`change_log` is the sync cursor. Clients send their last `seq`, get everything after it. Local writes queue offline and replay with client timestamps; conflicts resolve last-writer-wins per field, which is correct for read state and acceptable for everything else in scope.

Portability keys ride alongside the server IDs. `feeds.canonical_url` and `items.guid` are what the archive uses, so exporting is a projection of these tables and importing is a lookup on them. The local-mode store keeps the same columns, which is what makes the two modes interchangeable through one file format.

**Fetch scheduling.** Each feed gets an interval derived from its observed posting cadence, clamped between 5 minutes and 24 hours, with exponential backoff on errors and immediate fetch on WebSub notification. Priority-lane feeds get the floor of the range. One fetch serves every subscriber. `robots.txt` and `Retry-After` are respected. The crawler identifies itself with a URL publishers can read.

**Google Reader API compatibility.** The FreshRSS-documented dialect: `ClientLogin`, `token`, `subscription/list`, `stream/contents`, `stream/items/ids`, `stream/items/contents`, `edit-tag`, `mark-all-as-read`, `subscription/edit`. Those clients authenticate with username and password, so the account settings page issues app-specific passwords scoped to this endpoint and revocable individually. Third-party access is free and unmetered within the same fair-use limits first-party clients get.

**Search.** Postgres full-text search on `content_text` with a per-user filter through subscriptions, GIN-indexed. Good enough for launch; revisit only if it measurably isn't.

**Privacy in the architecture.** No analytics SDKs on any client. Server logs carry user IDs, never emails or content. The image proxy strips referrers and cookies and caches in Storage with a short TTL. Newsletter mail is stored as extracted content only; raw MIME is discarded after parsing. Nothing about reading behavior is aggregated across users, including for "popular" features, which the product does not have.

---

## 10. Optional intelligence

Off by default. Enabled per feature in settings. Three modes, chosen by the user:

1. **On-device.** Apple Foundation Models on iOS 26 and macOS 26, Gemini Nano through ML Kit on supported Android devices. Summaries and translation never leave the device. No web equivalent in this mode.
2. **Bring your own key.** Anthropic, OpenAI, or any OpenAI-compatible endpoint. The key is stored in the platform keychain on native and never on the server. The web app calls the provider directly from the browser.
3. **Hosted.** A first-party option on the paid plan for people who don't want to manage keys. Clearly labeled as sending article text to a third-party model provider, with the provider named.

What it does: summarize an item, summarize a folder's unread, translate, and suggest a lane for a new feed based on its cadence and the user's existing lanes. What it never does: rank, hide, or reorder anything on its own. Every AI output is a card the user asked for.

**Ask your saved articles**, last. A side pane, docked, that answers a question from the user's own Saved library and highlights, citing the articles it drew on with links back into the reader. Retrieval runs over the same full-text index search already uses, so the model only ever sees the passages it was handed, never the library. Scope is Saved and highlights only, not the feed stream; the point is the pile you chose to keep, not everything that came past. It ships in the same three modes as everything else here and not before phase 4, once the summaries plumbing has proven the key handling.

---

## 11. Design system and open design decisions

Default visual language is native per platform, per the repo's `CLAUDE.md`. That is a deliberate choice against the flat, identical-everywhere look that Folo and Feedly ship. The shared layer is tokens and information architecture; the rendered layer is each platform's own.

Shared token categories, one source of truth exported to SwiftUI, Compose, and CSS:

```
color        semantic roles only (surface, on-surface, accent, unread, saved, muted)
type         reader scale (body, lead, caption, heading 1–3) separate from UI scale
space        4-base scale
radius       platform-mapped (iOS concentric, M3 shape scale, web tokens)
motion       named durations and springs, platform-mapped
```

Decisions that need a designer, not an implementer. Each one changes what gets built, so they're listed rather than guessed:

1. **Reader pane typography.** Does the reading surface stay on the system face, or does it get a chosen serif and measure as the one intentional departure from native? This is the single biggest visual identity decision in the product.
2. **Unread indicator.** Dot, weight change, or color? It appears thousands of times a day.
3. **Ambient lane collapse.** A count row, a compact strip of favicons, or a summary card?
4. **List row density.** Title-only, title plus one line of summary, or title plus thumbnail? Probably a user setting; the default still has to be picked.
5. **Motion moments.** List row to reader (push on iOS, shared-element on Android, cross-fade on web?), mark-read feedback, Today refresh. Purpose is clear for each; parameters are not filled in here.
6. **Empty and error states.** Inbox zero, feed error, offline, first run.
7. **Brand.** Name, mark, accent color. Accent is the only brand color that appears in the UI.
8. **The mode picker.** It's the first screen anyone sees and it has to make an architectural choice feel like a preference. Two cards, a comparison, or a single default with "advanced" behind it?
9. **The mirror in Files.** How the iCloud Drive archive folder presents itself: one folder of dated snapshots, or one live folder that's always current? The concept says live; the Finder experience of that is a design call.
10. **Grid view covers.** Natural proportions in a masonry layout, or a fixed ratio in a regular grid? Masonry reads as a mood board, a fixed grid reads as a library. Pick one; the two say different things about what Saved is.
11. **The resurfacing card.** It's the one thing in Today that the user didn't just receive, so it has to look like an invitation and never like an ad. Placement, dismissal, and how it explains itself are design decisions.

Per the `design-tool-gates` skill, the Figma file needs the minimum screen set (Auth, Today with four states, Reader, Settings, navigation shell) in both light and dark before implementation starts.

**Design file.** The iOS and macOS design system and screens live in Figma: https://www.figma.com/design/ITHbnI4Gwey9xRHXAl04EY. Pages: Tokens (five variable collections, semantic color with Light and Dark modes, Swift code syntax on every token), Typography (iOS, macOS, and Reader scales in SF Pro), Components (icons, atoms, rows and cards, reader blocks, settings and auth, states, navigation chrome with real Glass effects), macOS, and iOS. It is built to the iOS 27 and macOS 27 design language (edge-to-edge sidebar, uniform frosted toolbar, colored sidebar icons in the active window only) and is the source of truth for token names until code exists.

---

## 12. Business model

- **Local mode:** free, no feed limit, no account. It costs nothing to serve, so it costs nothing to use. This is also the answer to "what happens if the company goes away": the local-mode app keeps working and the archive in iCloud Drive is already the user's.
- **Account, free:** up to 100 feeds, full sync, all clients including web, third-party API, reader view, rules. No newsletter ingest, no feed generation, no hosted AI, 30-day search history.
- **Account, paid, one tier:** unlimited feeds, newsletters, feed generation, unlimited search history, hosted AI, family sharing for up to five. Target price around $5 a month or $48 a year. Exact number is a decision.
- **Never:** ads, a "pro" tier that meters filters, a Teams pivot, or selling reading data.

On iOS and macOS, subscriptions go through StoreKit in-app purchase. The App Store "reader app" carve-out is for apps that only display previously purchased content, and relying on it for a subscription upsell is a review risk not worth taking. Sign in with Apple is mandatory on Apple platforms because Google sign-in is offered.

The free tier is generous on purpose. Feedly and Inoreader both trained users to expect the free plan to degrade over time. The retention play is that the paid features are things people want, not things people used to have.

---

## 13. Phasing

**Phase 0: the core, the service, and the web app.** `tributary-core` first, since both the fetcher and every later client depend on it. Then fetcher, api, Supabase schema, sync protocol, Reader API compatibility, the archive format with its round-trip test, competitor importers, and the web app. Ship this first because Reader API compatibility means NetNewsWire, Reeder Classic, Unread, and Lire users can adopt the service before a single native app exists. It also proves the sync layer under real load before the native clients depend on it.

**Phase 1: Apple, both modes.** iOS, iPadOS, macOS from one SwiftUI codebase with platform-specific navigation. Local mode with CloudKit sync and the iCloud Drive mirror ships in this phase, not later, because it's the mode that needs no server and is the honest answer to people leaving Feedly who never want another account. Mode switching in both directions ships here too, as does everything marked phase 1 in the reading-experience table: structured extraction, story clustering, snooze, Up Next, listen, save-anything, widgets, and intents. This is the flagship reading experience and the one most likely to earn word of mouth.

**Phase 2: Android, both modes.** Compose, M3 Expressive, adaptive layouts. Same sync client contract as Apple, ported not shared. Resurfacing and article diffs land across all clients in this phase. Whether Android local mode syncs across devices in this phase or ships single-device first is decision 8 below.

**Phase 3: sources and the service-only features.** Newsletter ingest, hosted feed generation, highlights export integrations, the digest, and blogrolls.

**Phase 4: intelligence.** On-device first, then BYOK, then hosted.

Windows is not in this plan. If it's added later it's WinUI per the repo's platform rules, not a web wrapper.

---

## 14. Proposed workstream breakdown

Independent enough to run in parallel once the schema and sync contract are frozen:

| Workstream | Depends on | Skill |
| --- | --- | --- |
| `tributary-core` crate: parsing, extraction, rules, archive format, UniFFI bindings | nothing | `rust-conventions` |
| Archive format spec and round-trip test fixtures | nothing | none, it's a document plus fixtures |
| Supabase schema, RLS policies, Auth setup (Google, Apple, passkey) | nothing | `web-platform` (supabase-integration), `backend-conventions` |
| Sync protocol spec (change_log, delta format, conflict rules) | schema | none, it's a document |
| Rust fetcher and extraction worker | core, schema | `rust-conventions`, `backend-conventions` |
| Rust api server, Reader API compat | schema, sync spec | `rust-conventions`, `backend-conventions` |
| Figma design system and screen set | brand decisions from section 11 | `figma-design-system`, `design-tool-gates`, `apple-platform`, `android-platform` |
| Web app | api, Figma | `web-platform`, `motion-design` |
| Apple clients, both modes, CloudKit sync, iCloud Drive mirror | core, api, Figma | `apple-platform`, `motion-design` |
| Android client, both modes | core, api, Figma | `android-platform`, `motion-design` |
| Competitor importers | core, archive spec | `rust-conventions` |

The critical path is core and archive spec together, then schema, then sync spec, then api, then clients. The Figma work runs alongside the backend and gates the clients.

---

## 15. What this concept does not decide

- The name.
- The exact price.
- Whether to ship Reader API compatibility at Phase 0 or hold it until first-party clients exist. The concept says Phase 0; the counterargument is that early adopters would judge the service through other people's UIs.
- Whether the web app gets the same offline depth as native or a lighter cache.
- Whether highlights ship in Phase 1 or Phase 3.
- Whether Rust holds for the api server once the surface grows, or whether it moves to TypeScript for velocity. Start in Rust; revisit with evidence.
- Whether Android local mode gets cross-device sync through Google Drive app data in its first release, or ships single-device with the archive mirror as the only way across. Decision 8 in section 11 covers the picker; this is the engineering half.
- Whether the local-mode Mac app runs a background helper for fetching when the app is closed, or only refreshes while open. NetNewsWire refreshes only while open and nobody complains.
- Whether the live sync in local mode is CloudKit, as this concept recommends, or literal iCloud Drive file sync as the brief phrased it. The concept's position is that the user asked for the outcome, local-only data that lives in iCloud Drive as their own files, and CloudKit plus the mirror delivers that outcome without the corruption risk. If the requirement is literally file-based sync, the mirror becomes the sync mechanism and conflict handling becomes a design problem the app has to surface.

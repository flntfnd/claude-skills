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
2. **Own the sync layer, keep it open.** Server-side fetching, one fetch per feed for every subscriber, delta sync to clients. Expose the Google Reader API dialect so NetNewsWire, Reeder Classic, Unread, Lire, and every self-hosted-compatible client work on day one. The lock-in is that it's good, not that it's closed.
3. **Reading is the feature.** Full-text extraction, real typography, read position that follows you, offline by default. The reader pane is where the design budget goes.
4. **Triage without an algorithm.** No engagement ranking, ever. Deterministic tools instead: rules, mutes, volume caps, priority lanes, digest grouping. The user can always explain why an item is where it is.
5. **AI is opt-in, bring-your-own or on-device, and never the default.** Summaries and translation through the user's own API key or the platform's on-device model. Nothing leaves the device or account without the user turning it on. Nothing is used for training.
6. **Everything is a feed.** RSS, Atom, JSON Feed, newsletters via a private ingest address, YouTube channels, podcasts, Bluesky and Mastodon accounts, Reddit, and generated feeds for sites that don't publish one.
7. **Leave whenever you want.** OPML in and out, full JSON export of state, importers from Feedly, Inoreader, Feedbin, and NetNewsWire, and the API is free for any client.
8. **No tracking.** No analytics SDKs, no fingerprinting, no reading-behavior telemetry. Fetching happens server-side so publishers see one crawler, not each reader's IP. Images go through a referrer-stripping proxy.

---

## 3. Information architecture

Five top-level destinations, identical across platforms, surfaced through each platform's own navigation pattern.

```
Today        Triage inbox. Unread, grouped by priority lane, then folder.
             High-volume feeds collapse to a count. This is the home screen.

Timeline     Everything in chronological order. Filter: All / Unread / Saved.
             The "just show me the river" view for people who hate inboxes.

Feeds        The subscription tree. Folders, feeds, tags, feed health.
             Add, organize, mute, set per-feed rules here.

Saved        Read-later and highlights. Full-text searchable. Exportable.

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

## 4. Screen concepts

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

Sidebar and toolbar are the navigation layer and take the glass treatment. The list and the reader are content and take none. Reader pane typography is the one place where the app departs from system defaults, and that departure is a Figma decision, not something to fill in during implementation (see section 9).

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

## 5. Reading experience

This is where the product wins or loses. Specifics:

- **Full-text extraction** runs server-side on ingest for every item, not on demand. Truncated feeds are the norm and the reader should never show a stub with a "read more" link when the article is fetchable.
- **Reader view is the default**, original-HTML view is one tap away, and per-feed preference is remembered.
- **Typography controls**: type size, line width, theme (system, light, dark, sepia), and a small curated set of body faces. System font is the default on each platform.
- **Read position sync** at paragraph granularity, not just read/unread. Open an item on the phone, keep reading on the Mac.
- **Offline first**: every client keeps a local database (SwiftData on Apple, Room on Android, IndexedDB on web). Unread items and their extracted text are always available offline. Images cache on read.
- **Highlights** on selected text, synced, exportable as Markdown, with an optional push to Obsidian, Notion, and Readwise. This is the Readwise Reader overlap and it stays deliberately shallow: capture, don't build a second brain.
- **Media**: YouTube items embed the player, podcast items show a play button that hands off to the system player. No in-app podcast client.
- **Sharing** uses the platform share sheet. Nothing custom.

---

## 6. Sources

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

## 7. Architecture

Follows the repo's lane rules exactly. Vercel is the web frontend, Railway is the trusted backend, Supabase is data, auth, realtime, and storage.

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

**Fetch scheduling.** Each feed gets an interval derived from its observed posting cadence, clamped between 5 minutes and 24 hours, with exponential backoff on errors and immediate fetch on WebSub notification. Priority-lane feeds get the floor of the range. One fetch serves every subscriber. `robots.txt` and `Retry-After` are respected. The crawler identifies itself with a URL publishers can read.

**Google Reader API compatibility.** The FreshRSS-documented dialect: `ClientLogin`, `token`, `subscription/list`, `stream/contents`, `stream/items/ids`, `stream/items/contents`, `edit-tag`, `mark-all-as-read`, `subscription/edit`. Those clients authenticate with username and password, so the account settings page issues app-specific passwords scoped to this endpoint and revocable individually. Third-party access is free and unmetered within the same fair-use limits first-party clients get.

**Search.** Postgres full-text search on `content_text` with a per-user filter through subscriptions, GIN-indexed. Good enough for launch; revisit only if it measurably isn't.

**Privacy in the architecture.** No analytics SDKs on any client. Server logs carry user IDs, never emails or content. The image proxy strips referrers and cookies and caches in Storage with a short TTL. Newsletter mail is stored as extracted content only; raw MIME is discarded after parsing. Nothing about reading behavior is aggregated across users, including for "popular" features, which the product does not have.

---

## 8. Optional intelligence

Off by default. Enabled per feature in settings. Three modes, chosen by the user:

1. **On-device.** Apple Foundation Models on iOS 26 and macOS 26, Gemini Nano through ML Kit on supported Android devices. Summaries and translation never leave the device. No web equivalent in this mode.
2. **Bring your own key.** Anthropic, OpenAI, or any OpenAI-compatible endpoint. The key is stored in the platform keychain on native and never on the server. The web app calls the provider directly from the browser.
3. **Hosted.** A first-party option on the paid plan for people who don't want to manage keys. Clearly labeled as sending article text to a third-party model provider, with the provider named.

What it does: summarize an item, summarize a folder's unread, translate, and suggest a lane for a new feed based on its cadence and the user's existing lanes. What it never does: rank, hide, or reorder anything on its own. Every AI output is a card the user asked for.

---

## 9. Design system and open design decisions

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

Per the `design-tool-gates` skill, the Figma file needs the minimum screen set (Auth, Today with four states, Reader, Settings, navigation shell) in both light and dark before implementation starts.

---

## 10. Business model

- **Free:** up to 100 feeds, full sync, all clients, third-party API, reader view, rules. No newsletter ingest, no feed generation, no hosted AI, 30-day search history.
- **Paid, one tier:** unlimited feeds, newsletters, feed generation, unlimited search history, hosted AI, family sharing for up to five. Target price around $5 a month or $48 a year. Exact number is a decision.
- **Never:** ads, a "pro" tier that meters filters, a Teams pivot, or selling reading data.

On iOS and macOS, subscriptions go through StoreKit in-app purchase. The App Store "reader app" carve-out is for apps that only display previously purchased content, and relying on it for a subscription upsell is a review risk not worth taking. Sign in with Apple is mandatory on Apple platforms because Google sign-in is offered.

The free tier is generous on purpose. Feedly and Inoreader both trained users to expect the free plan to degrade over time. The retention play is that the paid features are things people want, not things people used to have.

---

## 11. Phasing

**Phase 0: the service and the web app.** Fetcher, api, Supabase schema, sync protocol, Reader API compatibility, OPML and competitor import, web app. Ship this first because Reader API compatibility means NetNewsWire, Reeder Classic, Unread, and Lire users can adopt the service before a single native app exists. It also proves the sync layer under real load before the native clients depend on it.

**Phase 1: Apple.** iOS, iPadOS, macOS from one SwiftUI codebase with platform-specific navigation. This is the flagship reading experience and the one most likely to earn word of mouth.

**Phase 2: Android.** Compose, M3 Expressive, adaptive layouts. Same sync client contract as Apple, ported not shared.

**Phase 3: sources.** Newsletter ingest, hosted feed generation, highlights export integrations.

**Phase 4: intelligence.** On-device first, then BYOK, then hosted.

Windows is not in this plan. If it's added later it's WinUI per the repo's platform rules, not a web wrapper.

---

## 12. Proposed workstream breakdown

Independent enough to run in parallel once the schema and sync contract are frozen:

| Workstream | Depends on | Skill |
| --- | --- | --- |
| Supabase schema, RLS policies, Auth setup | nothing | `web-platform` (supabase-integration), `backend-conventions` |
| Sync protocol spec (change_log, delta format, conflict rules) | schema | none, it's a document |
| Rust fetcher and extraction worker | schema | `rust-conventions`, `backend-conventions` |
| Rust api server, Reader API compat | schema, sync spec | `rust-conventions`, `backend-conventions` |
| Figma design system and screen set | brand decisions from section 9 | `figma-design-system`, `design-tool-gates`, `apple-platform`, `android-platform` |
| Web app | api, Figma | `web-platform`, `motion-design` |
| Apple clients | api, Figma | `apple-platform`, `motion-design` |
| Android client | api, Figma | `android-platform`, `motion-design` |

The critical path is schema, then sync spec, then api, then clients. The Figma work runs alongside the backend and gates the clients.

---

## 13. What this concept does not decide

- The name.
- The exact price.
- Whether to ship Reader API compatibility at Phase 0 or hold it until first-party clients exist. The concept says Phase 0; the counterargument is that early adopters would judge the service through other people's UIs.
- Whether the web app gets the same offline depth as native or a lighter cache.
- Whether highlights ship in Phase 1 or Phase 3.
- Whether Rust holds for the api server once the surface grows, or whether it moves to TypeScript for velocity. Start in Rust; revisit with evidence.

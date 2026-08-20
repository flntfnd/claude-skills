# Crate selection

Current defaults by category, verified via web search in August 2026 where noted. Don't pull in a crate for what `std` already covers — `std::collections::HashMap`, `std::time::Duration`, `std::sync::LazyLock` (replaces `lazy_static`) are all fine as-is.

When in doubt, check `lib.rs` (alternative crates index) or `blessed.rs` (curated recommendations) for current best-of-class — this list will drift, that won't.

## Contents

- [Core stack](#core-stack)
- [Time: chrono vs jiff](#time-chrono-vs-jiff)
- [Everything else, by category](#everything-else-by-category)

## Core stack

| Category | Pick | Verified state (Aug 2026) |
| --- | --- | --- |
| Async runtime | `tokio` (`features = ["full"]` for prototypes, narrowed for production) | Current line 1.52.x. LTS branches exist (1.47.x, 1.51.x); `[Unverified]` which is "current LTS" at any given moment, check docs.rs. |
| HTTP server | `axum` 0.8+ | Latest released is 0.8.9. 0.9 is in development on `main`, not yet on crates.io — don't write code against unreleased 0.9 APIs. |
| HTTP client | `reqwest` (`default-features = false, features = ["rustls-tls", "json"]` to avoid native-tls) | Unchanged in shape. |
| SQL | `sqlx` (compile-time checked, async, no ORM) | Now at 0.9.0, with real breaking changes from 0.8 — see [web-stack.md](web-stack.md). `sea-orm` if you want an ORM; `diesel` for sync. |
| Migrations | `sqlx::migrate!` macro, or `sqlx-cli` externally | Unchanged. |
| CLI | `clap` 4+ with derive macros | 4.6.x confirmed current. |
| Errors | `thiserror` 2 for libraries, `anyhow` 1 for applications | thiserror at 2.0.x (2.0.19 seen). |
| Logging/tracing | `tracing` + `tracing-subscriber` (`env-filter`, `json` features) | tracing 0.1.x, tracing-subscriber 0.3.x (0.3.23 seen). |
| Tower middleware | `tower` 0.5, `tower-http` for the standard set | tower-http moved to 0.7.0 (was 0.6 previously). |

## Time: chrono vs jiff

This is the one real ecosystem shift since the last pass. Starting in 2026, chrono's maintainer publicly soft-deprecated `chrono`/`chrono-tz` — the design is dated (`Option<T>` errors instead of contextualized `Result`, no multi-unit calendar math, spotty IANA timezone integration without `chrono-tz`) and they now point people at `jiff` instead.

- **New projects**: default to `jiff`. It returns `Result<T, E>` with human-readable errors, has first-class timezone support without a separate crate, and can do calendar-duration math chrono can't.
- **sqlx integration**: no first-party `jiff` feature on sqlx itself — use the `jiff-sqlx` wrapper crate (Postgres and SQLite; MySQL isn't possible yet, pending sqlx exposing more API surface).
- **Existing chrono codebases**: chrono isn't broken or yanked, just no longer where new investment goes. Don't rip it out reflexively — migrate opportunistically or when timezone bugs push you to.
- One real trade-off: chrono's zone-aware datetime type is `Copy`; jiff's `Zoned` is not (it embeds a `TimeZone`). That affects some hot-path code.

`[Unverified — recent]`: this is a live, recent shift (the GitHub soft-deprecation issue and the jiff-sqlx crate are both current-year). Confirm against chrono's crates.io page and the sqlx ecosystem wiki before committing a new project to jiff, in case the picture has moved further since.

<details>
<summary>Legacy / deprecated</summary>

Older guidance recommended `chrono` for `DateTime` work and `time` for some embedded contexts, treating `jiff` as "the modern alternative — newer, better API, evaluate if starting fresh." That's now inverted: `jiff` is the default recommendation, `chrono` is the legacy option kept for existing codebases.

</details>

## Everything else, by category

- **Serialization**: `serde` + format crate (`serde_json`, `bincode`, `toml`, `serde_yaml`).
- **UUIDs**: `uuid` with `["v4", "serde"]`.
- **Validation**: `validator` for derive-based field validation.
- **Config**: `figment` or `config` for layered config from files + env.
- **Concurrent collections**: `dashmap` for concurrent HashMap, `arc-swap` for atomic `Arc<T>` swaps.
- **Channels**: `tokio::sync::*` for async, `crossbeam-channel` for sync MPMC, `flume` for cross-runtime.
- **Atomic numerics**: `std::sync::atomic::*` for the common types, `atomig` for atomic structs.
- **Random**: `rand` (default feature set pulls in OS RNG, correct for most apps).
- **Crypto**: `ring` for primitives, `argon2` or `bcrypt` for password hashing, `jsonwebtoken` for JWTs.
- **Property testing**: `proptest`.
- **Snapshot testing**: `insta`.
- **Faster test runner**: `cargo-nextest`.
- **Audio realtime**: `rtrb` or `ringbuf-basedrop`, `assert_no_alloc`, `basedrop` — see [audio-thread.md](audio-thread.md); maintenance status of this niche `[Unverified]`, check crates.io yourself before depending on them.
- **Embedded HTTP**: `embassy-net` + `embedded-svc` for no_std contexts.
- **Supply chain / CI**: `cargo-audit` (RustSec advisories) and `cargo-deny` (license/duplicate/source policy) — both confirmed still the standard pairing in 2026; `cargo-vet` is the heavier option for orgs with strict supply-chain requirements (finance, government, infra).

# rust.md
Rust development. 2024 edition (stable since Rust 1.85, Feb 2025) is the production default.
Tokio for async, axum for HTTP, sqlx for SQL, tracing for observability, thiserror+anyhow for errors.

This file extends the Rust conventions in CLAUDE.md (no `unwrap()` outside throwaway code, `thiserror` for libraries, `anyhow` for applications, no `clone()` to dodge the borrow checker, no `unsafe` without a safety comment, iterators over manual loops). Read CLAUDE.md first, then this for the operational details.

---

# STEP 0 — Edition and toolchain

Every new project: `edition = "2024"`. Every existing project: migrate via `cargo fix --edition`, then commit, then `cargo fix --edition-idioms` as a separate commit. The 2024 edition stabilized RPIT lifetime capture rules, async closures (`async || {}`), and the `AsyncFn` family — all are production-ready as of Rust 1.85+.

`Cargo.toml` essentials:

```toml
[package]
name = "my-app"
version = "0.1.0"
edition = "2024"
rust-version = "1.85"

[profile.release]
lto = "thin"
codegen-units = 1
strip = "symbols"
panic = "abort"

[profile.dev]
debug = "line-tables-only"
opt-level = 0

[profile.dev.package."*"]
opt-level = 3
```

`panic = "abort"` in release profile only when the binary doesn't need unwinding (most servers and CLIs don't). Libraries leave it at default.

`opt-level = 3` for dev dependencies makes debug builds tolerable when third-party crates are heavy (image processing, crypto, database drivers).

Pin a `rust-toolchain.toml` at the repo root for reproducibility:

```toml
[toolchain]
channel = "1.85.0"
components = ["rustfmt", "clippy", "rust-src"]
```

---

# STEP 1 — Tooling discipline

Non-negotiable in CI:

```bash
cargo fmt --all -- --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all-features
cargo audit
cargo deny check
```

`-D warnings` on clippy means warnings fail the build. This is the only setting that prevents lint debt.

`cargo audit` checks dependencies against the RustSec advisory database. Any `RUSTSEC-*` finding blocks merge.

`cargo deny check` validates licenses, duplicates, and sourced dependencies against `deny.toml`. Use it on any project past prototype.

`cargo nextest run` instead of `cargo test` for faster, more parallelizable test execution. It's not a default but it's the better default.

Format-on-save in editor configs. `rustfmt` defaults are correct — don't customize unless there's a specific reason.

---

# Error handling

Two patterns, picked deliberately:

## Library code → `thiserror`

Errors are part of the API. They have stable variants, source chains, and types consumers can match on.

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum DbError {
    #[error("connection failed: {0}")]
    Connection(#[from] sqlx::Error),

    #[error("row not found for id {id}")]
    NotFound { id: uuid::Uuid },

    #[error("invalid query: {message}")]
    InvalidQuery { message: String },
}
```

`#[from]` generates the `From` impl, which is what makes `?` work without manual conversion. Use it for one-to-one wrappings. If two source error types map to the same variant, write the impl by hand.

Source chain matters. `#[source]` on a field includes it in the error chain (printed by `{:#}` in anyhow, walked by error reporting tools). Use `#[from]` when the wrapping is structural; use `#[source]` when you want context plus source.

## Application code → `anyhow`

Top-level binary errors. The caller is `main`. Context strings are the value.

```rust
use anyhow::{Context, Result};

async fn load_config(path: &Path) -> Result<Config> {
    let raw = tokio::fs::read_to_string(path)
        .await
        .with_context(|| format!("reading config from {}", path.display()))?;

    toml::from_str(&raw)
        .with_context(|| format!("parsing TOML from {}", path.display()))
}
```

`with_context` over `context` for anything that allocates (format strings, paths). The closure is only evaluated on the error path.

Don't mix the two. Library code returns concrete errors. Binaries collect them with `?` into `anyhow::Error`. The boundary is the binary's `main`.

## Things to never do

- `Result<T, Box<dyn Error>>` in library APIs (consumers can't match on it). Use `thiserror`.
- `.unwrap()` outside tests, examples, or genuinely impossible states (prove it in the safety comment).
- `.expect("this should never happen")` — if it should never happen, type-encode that. If it might, return a Result.
- Stringly-typed errors (`Err("something failed".to_string())`).
- Eating errors with `let _ =` unless there's a comment explaining why the error is ignorable.

---

# Async

Tokio is the default runtime. Don't mix runtimes — pick one per binary. async-std and smol exist but the ecosystem is built around Tokio.

## Runtime setup

```rust
#[tokio::main(flavor = "multi_thread", worker_threads = 4)]
async fn main() -> anyhow::Result<()> {
    // ...
}
```

Specify `worker_threads` explicitly. The default (number of CPUs) is rarely what you want in a container with a CPU limit. Read the limit from the environment (`tokio::runtime::Builder` if you need fine control).

## Async closures (2024 edition)

`async || {}` is stable. Prefer it over `Box<dyn Future>` boilerplate for callbacks and middleware.

```rust
let process = async |item: Item| -> Result<()> {
    save(&item).await?;
    notify(&item).await?;
    Ok(())
};

for item in items {
    process(item).await?;
}
```

For library APIs that take async callbacks, accept `AsyncFn`, `AsyncFnMut`, or `AsyncFnOnce` from the prelude. Cleaner than the old `impl Fn() -> impl Future<...>` pattern.

## Cancellation safety

Every `.await` is a cancellation point. If the task is dropped (timeout, parent cancellation), execution stops there. Code after that point doesn't run.

This matters for cleanup. Use guards that implement `Drop`, not "do cleanup at the end of the function" patterns. RAII works in async because `Drop` runs on cancellation; `.await` doesn't.

```rust
// Wrong — cleanup never runs if cancelled mid-await
async fn process(file: File) -> Result<()> {
    let data = read_async(&file).await?;
    let result = transform(&data).await?;
    cleanup(&file).await?;  // skipped on cancellation
    Ok(result)
}

// Right — cleanup is a Drop guard
async fn process(file: File) -> Result<()> {
    let _guard = scopeguard::guard(&file, |f| {
        // sync cleanup, runs on drop including cancellation
        cleanup_sync(f);
    });
    let data = read_async(&file).await?;
    let result = transform(&data).await?;
    Ok(result)
}
```

For async cleanup, structured concurrency via `tokio::select!` with a cancellation token (`tokio_util::sync::CancellationToken`) is the pattern.

## Send bounds

`async fn` in traits works on stable now, but generic functions over those traits hit the "send bound" problem. Use `trait_variant` or return-type notation (RTN, when stable) until the language solution lands.

```rust
#[trait_variant::make(Send)]
pub trait Repository {
    async fn fetch(&self, id: Uuid) -> Result<Item>;
}
```

This generates two trait variants: a non-Send version and a Send version. Most async runtimes (Tokio multi-thread, axum) need Send.

## Don't block the runtime

Sync work that takes more than a few microseconds blocks the worker thread it's on. Move it:

- CPU-heavy work → `tokio::task::spawn_blocking`
- Blocking I/O (sync file reads, blocking DB drivers) → `spawn_blocking`
- Synchronous third-party libraries → `spawn_blocking` or wrap them

`spawn_blocking` runs on a dedicated blocking thread pool, separate from the async worker pool. It's fine to use; just don't pretend sync work is free in async context.

## Structured concurrency

Spawn tasks; await them in a scope; handle their results. Don't spawn fire-and-forget tasks from a request handler — they outlive the request and lose context.

```rust
let (a, b, c) = tokio::join!(
    fetch_user(id),
    fetch_orders(id),
    fetch_preferences(id),
);
let user = a?;
let orders = b?;
let prefs = c?;
```

`tokio::join!` runs them concurrently on the same task. `tokio::spawn` creates a new task — use it when work should run independently and the parent doesn't need to wait. `tokio::try_join!` short-circuits on the first error.

For backpressure, use bounded channels (`tokio::sync::mpsc::channel(N)`). Unbounded channels are an unbounded memory leak waiting to happen.

---

# Stack: web services

The default web service stack:

```toml
[dependencies]
tokio = { version = "1", features = ["full"] }
axum = { version = "0.8", features = ["macros"] }
tower = "0.5"
tower-http = { version = "0.6", features = ["trace", "cors", "compression-gzip"] }
sqlx = { version = "0.8", features = ["runtime-tokio", "tls-rustls", "postgres", "uuid", "chrono", "macros"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter", "json"] }
thiserror = "2"
anyhow = "1"
uuid = { version = "1", features = ["v4", "serde"] }
chrono = { version = "0.4", features = ["serde"] }
```

This stack is opinionated and current as of April 2026.

## axum

axum is the default web framework. Tokio team. Tower middleware. Plain async functions as handlers. axum 0.8 changed path syntax from `:id` to `{id}` to align with OpenAPI. New code uses `{id}`.

```rust
use axum::{Router, routing::get, extract::{State, Path}, Json};
use std::sync::Arc;

#[derive(Clone)]
struct AppState {
    db: sqlx::PgPool,
}

async fn get_user(
    State(state): State<Arc<AppState>>,
    Path(id): Path<uuid::Uuid>,
) -> Result<Json<User>, AppError> {
    let user = sqlx::query_as!(User, "SELECT * FROM users WHERE id = $1", id)
        .fetch_one(&state.db)
        .await?;
    Ok(Json(user))
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let state = Arc::new(AppState {
        db: sqlx::PgPool::connect(&std::env::var("DATABASE_URL")?).await?,
    });

    let app = Router::new()
        .route("/users/{id}", get(get_user))
        .with_state(state);

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await?;
    axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal())
        .await?;
    Ok(())
}

async fn shutdown_signal() {
    let _ = tokio::signal::ctrl_c().await;
    tracing::info!("shutdown signal received");
}
```

Always wire graceful shutdown. Crashing handlers mid-request loses data; `with_graceful_shutdown` lets in-flight requests complete.

State goes through `with_state(...)` and is extracted with `State<...>`. `Arc<AppState>` is the standard wrapping. Don't use `Extension<...>` for new code — it's the older pattern.

## Errors as IntoResponse

Custom error type that implements `IntoResponse`:

```rust
use axum::{response::{IntoResponse, Response}, http::StatusCode, Json};
use serde_json::json;

#[derive(Debug, thiserror::Error)]
enum AppError {
    #[error(transparent)]
    Db(#[from] sqlx::Error),

    #[error("not found")]
    NotFound,

    #[error(transparent)]
    Other(#[from] anyhow::Error),
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, message) = match &self {
            AppError::NotFound => (StatusCode::NOT_FOUND, self.to_string()),
            AppError::Db(sqlx::Error::RowNotFound) => (StatusCode::NOT_FOUND, "not found".into()),
            _ => {
                tracing::error!(error = ?self, "internal error");
                (StatusCode::INTERNAL_SERVER_ERROR, "internal error".into())
            }
        };
        (status, Json(json!({ "error": message }))).into_response()
    }
}
```

Log errors at the boundary, not inside business logic. Business logic returns `Result`; the response layer decides what to log and what to surface.

## sqlx

sqlx is compile-time-checked SQL. Not an ORM. You write SQL; the macros validate it against the schema at build time.

```rust
let user = sqlx::query_as!(
    User,
    "SELECT id, email, created_at FROM users WHERE id = $1",
    id
)
.fetch_one(&pool)
.await?;
```

Compile-time checking requires `DATABASE_URL` set during build, or `cargo sqlx prepare` to generate offline query metadata (`.sqlx/` directory committed to the repo for CI builds without DB access).

Always specify column lists. `SELECT *` works but pins your code to the column order.

Use `query!` for non-result queries, `query_as!` to map into a struct, `query_scalar!` for single-value results.

Migrations: `sqlx::migrate!()` macro embeds `migrations/` into the binary. Run on startup or via `sqlx-cli`. Pin migration order via timestamp prefixes (`20260416120000_create_users.sql`).

Connection pool sizing: start with `max_connections = number_of_cpus * 2`. Tune from there. For Postgres on Supabase, respect the connection pool limit on the Supabase side.

## Tower middleware

Use `tower-http` for the standard set: tracing, CORS, compression, timeouts.

```rust
use tower_http::trace::TraceLayer;
use tower_http::compression::CompressionLayer;
use std::time::Duration;

let app = Router::new()
    .route("/users/{id}", get(get_user))
    .layer(TraceLayer::new_for_http())
    .layer(CompressionLayer::new())
    .layer(tower::timeout::TimeoutLayer::new(Duration::from_secs(30)))
    .with_state(state);
```

Layers wrap from bottom to top in code, but execute outer-to-inner at runtime. Trace first, then auth, then rate limit, then handler.

For custom middleware, prefer `axum::middleware::from_fn` over implementing `tower::Service` by hand. The trait is correct but verbose.

---

# Observability with tracing

`println!` and `eprintln!` don't belong in production code. Use `tracing`.

```rust
use tracing::{info, error, debug, warn, instrument};

#[instrument(skip(pool), fields(user_id = %id))]
async fn fetch_user(pool: &PgPool, id: Uuid) -> Result<User, sqlx::Error> {
    debug!("querying users table");
    let user = sqlx::query_as!(User, "SELECT * FROM users WHERE id = $1", id)
        .fetch_one(pool)
        .await?;
    info!(email = %user.email, "user fetched");
    Ok(user)
}
```

`#[instrument]` adds a span around the function. Fields are structured. `skip` removes args that aren't worth logging (pools, large blobs). `%` is `Display`, `?` is `Debug`.

## Subscriber setup

```rust
use tracing_subscriber::{EnvFilter, fmt};

fn init_tracing() {
    fmt()
        .with_env_filter(EnvFilter::from_default_env()
            .add_directive("info".parse().unwrap()))
        .json()  // structured JSON for log aggregators
        .init();
}
```

Set log level via `RUST_LOG=info,my_app=debug,sqlx=warn`. Per-module filtering is the point. JSON output for production (Datadog, Loki, CloudWatch all parse it). Pretty output for dev — swap formatters based on env.

## Spans propagate context

Spans nest. A request gets a top-level span (axum's `TraceLayer` adds it); child spans inherit. `tracing::Instrument::instrument` attaches a span to a future.

For distributed tracing across services, add `tracing-opentelemetry` and export to an OTLP collector.

## What to log

- `info!` for state changes the operator cares about (request received, user created, config reloaded)
- `warn!` for recoverable problems (retry occurred, fallback used, rate limit hit)
- `error!` for things that need attention (5xx responses, database failures, panics caught)
- `debug!` for development context (intermediate state, decisions in branches)
- `trace!` for fine-grained event-stream debugging (rare)

Never log secrets, tokens, full request bodies (PII risk), or raw error messages from external services without sanitization.

---

# Concurrency primitives

## Channels

`tokio::sync::mpsc` for async message-passing. Bounded by default — pick the buffer size deliberately.

`tokio::sync::watch` for "latest value" broadcasts (config reload, state distribution).

`tokio::sync::broadcast` for "every receiver sees every message" (event bus). Slow receivers cause message loss after the buffer fills.

`tokio::sync::oneshot` for single-message request/reply.

For sync code: `crossbeam-channel` for MPMC, `flume` for cross-runtime, `std::sync::mpsc` only for trivial cases (it's slower than crossbeam).

## Locks

`std::sync::Mutex` and `std::sync::RwLock` are correct in async code as long as the critical section is short and doesn't `.await`. Holding a lock across `.await` is almost always a deadlock waiting to happen.

```rust
// Wrong
let mut state = state.lock().unwrap();
let result = some_async_op().await;  // holds lock across await
state.update(result);

// Right
let result = some_async_op().await;
{
    let mut state = state.lock().unwrap();
    state.update(result);
}  // lock released
```

Use `tokio::sync::Mutex` only when you genuinely need to hold a lock across `.await`. It's slower and the API is async (`.lock().await`).

`parking_lot` provides faster `Mutex` and `RwLock` than std, with no poisoning. Use it when measurement justifies the dependency.

## Atomics

For counters, flags, and small shared state: `std::sync::atomic::AtomicU64`, `AtomicBool`, etc. Memory ordering matters — default to `Ordering::SeqCst` until profiling justifies relaxing it.

`Arc<AtomicU64>` is fine for shared counters. `dashmap` for concurrent maps where lock-free is worth the dependency.

## Interior mutability

- `Cell<T>` for `Copy` types in single-threaded contexts
- `RefCell<T>` for non-`Copy` in single-threaded contexts (panics on borrow violations at runtime)
- `OnceCell<T>` and `OnceLock<T>` for write-once values (config, computed constants)
- `LazyLock<T>` for lazily-initialized statics (replaces `lazy_static!`)

`std::sync::LazyLock` is stable since 1.80. Use it instead of the `lazy_static` crate or `once_cell::sync::Lazy` in new code.

```rust
use std::sync::LazyLock;
use prometheus::IntCounter;

static REQUEST_COUNT: LazyLock<IntCounter> = LazyLock::new(|| {
    prometheus::register_int_counter!("requests_total", "total requests").unwrap()
});
```

---

# Audio thread (extends CLAUDE.md)

CLAUDE.md establishes the rule: no allocations, no locks, no Objective-C messaging. Rust-specific implementations:

## Lock-free SPSC ring buffers

For audio thread → UI thread (or any cross-thread message passing where one side is realtime), use a wait-free SPSC queue:

- `rtrb` — single-producer single-consumer, no_std capable
- `ringbuf` — supports const generics and heap allocation; for audio use `ringbuf-basedrop` so dropping references doesn't deallocate on the realtime thread
- `crossbeam-queue` — wider variety; for SPSC the dedicated crates are better

```rust
use rtrb::{RingBuffer, Producer, Consumer};

let (mut producer, mut consumer) = RingBuffer::<f32>::new(4096);

// On non-realtime thread:
let _ = producer.push(sample);  // returns Err if full, doesn't block

// On audio thread:
if let Ok(sample) = consumer.pop() {
    // process
}
```

Sized to a power of two. Allocate once at startup; never resize.

## Verifying no allocations on audio thread

`assert_no_alloc` crate wraps a custom global allocator that aborts (or warns) if allocation is attempted inside a flagged scope.

```rust
use assert_no_alloc::*;

#[cfg(debug_assertions)]
#[global_allocator]
static A: AllocDisabler = AllocDisabler;

fn audio_callback(buffer: &mut [f32]) {
    assert_no_alloc(|| {
        // any allocation here aborts in debug builds
        for sample in buffer.iter_mut() {
            *sample = process(*sample);
        }
    });
}
```

Run the test suite under this allocator. Any audio path that allocates surfaces immediately.

## Drop discipline

`Vec`, `String`, `Box`, `Arc<T>` (when refcount reaches zero), `Rc<T>` (same) — all deallocate on drop. Audio thread code must not own anything that allocates on drop.

`basedrop::Shared<T>` is a refcount type that defers deallocation to a non-realtime collector thread. Use it in place of `Arc<T>` when references will be dropped on the audio thread.

For owned data on the audio thread: pre-allocate in setup, pass references in, never own anything that drops to allocator.

---

# Testing

`cargo test` runs unit tests (`#[cfg(test)]` modules) and integration tests (`tests/` directory).

## What to test

Per CLAUDE.md: critical paths and business logic. Skip trivial getters/setters.

- Unit tests: pure functions, parsing, validation, error paths
- Integration tests: HTTP handlers (via `axum::serve` against a `TcpListener::bind("127.0.0.1:0")` and a real client), database queries (via test DB), end-to-end flows
- Property tests with `proptest` for serialization round-trips, parser invariants
- Snapshot tests with `insta` for complex output structures (JSON responses, generated code)

## Async tests

```rust
#[tokio::test]
async fn fetches_user() {
    let pool = test_pool().await;
    let user = create_test_user(&pool).await;
    let result = fetch_user(&pool, user.id).await.unwrap();
    assert_eq!(result.email, user.email);
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn concurrent_writes() {
    // multi-thread when the test exercises real concurrency
}
```

Default flavor is single-threaded (`current_thread`). Switch to multi-thread when concurrency is part of the test, not just incidental.

## Test database

For sqlx, use `sqlx::test` macro:

```rust
#[sqlx::test]
async fn user_can_be_created(pool: PgPool) -> anyhow::Result<()> {
    let id = create_user(&pool, "alice@example.com").await?;
    let user = fetch_user(&pool, id).await?;
    assert_eq!(user.email, "alice@example.com");
    Ok(())
}
```

The macro creates a fresh test database per test, runs migrations, passes the pool. Cleanup happens automatically. Requires `DATABASE_URL` pointing at a Postgres the test process can create databases in.

## Don't mock everything

Mock external I/O at the boundary (HTTP clients, third-party APIs). Don't mock your own database or business logic — use a real test DB and real functions. Mocks that simulate your code's behavior tend to drift from actual behavior.

For external HTTP, `wiremock` provides a real HTTP server to mock against, which is more realistic than trait-based mocking.

---

# Project structure

## Single binary, single crate

For services up to ~5k LoC:

```
my-service/
  Cargo.toml
  rust-toolchain.toml
  deny.toml
  .sqlx/                # offline query metadata
  migrations/
    20260416120000_initial.sql
  src/
    main.rs             # init: tracing, db, router, serve
    config.rs           # env parsing
    db.rs               # pool setup, migrations
    error.rs            # AppError + IntoResponse
    routes/
      mod.rs            # Router::new() composition
      users.rs          # handlers + request/response types
      ...
    domain/             # business logic
      mod.rs
      user.rs
    ...
  tests/
    integration.rs
```

Domain logic is separate from HTTP handlers. Handlers do extraction, call domain functions, format the response. Domain functions are testable without an HTTP server.

## Workspace

For multi-crate projects:

```
my-project/
  Cargo.toml             # [workspace]
  crates/
    my-core/             # domain types and logic, no I/O
      Cargo.toml
      src/lib.rs
    my-db/               # database layer, depends on my-core
      Cargo.toml
      src/lib.rs
    my-api/              # HTTP layer, depends on my-core, my-db
      Cargo.toml
      src/main.rs
    my-cli/              # CLI binary, depends on my-core, my-db
      Cargo.toml
      src/main.rs
```

Workspace `Cargo.toml`:

```toml
[workspace]
resolver = "3"
members = ["crates/*"]

[workspace.package]
version = "0.1.0"
edition = "2024"
rust-version = "1.85"

[workspace.dependencies]
tokio = { version = "1", features = ["full"] }
serde = { version = "1", features = ["derive"] }
sqlx = { version = "0.8", features = ["runtime-tokio", "tls-rustls", "postgres"] }
# ... shared deps
```

Member crates inherit:

```toml
[package]
name = "my-core"
version.workspace = true
edition.workspace = true
rust-version.workspace = true

[dependencies]
tokio.workspace = true
serde.workspace = true
```

This keeps versions aligned across the workspace. `resolver = "3"` is the 2024-edition default and handles feature unification correctly across workspace members.

## When to split into crates

Split when:
- The piece is independently versioned (published library)
- Compile time pressure justifies caching boundaries
- Separate teams own separate crates
- Multiple binaries share a substantial library

Don't split prematurely. A single crate with well-organized modules is easier to refactor than a workspace with circular dependency tendencies.

---

# Performance discipline

## String types

- `&str` for borrowed string slices in function parameters (default)
- `String` for owned, mutable strings
- `Cow<'_, str>` when the function might or might not need to allocate
- `Box<str>` for immutable owned strings (smaller than `String` — no capacity field)
- `Arc<str>` for cheaply-cloneable shared strings
- `&'static str` for compile-time string literals

```rust
// Take what you need, no more
fn process(input: &str) -> String { ... }            // borrow input, return owned
fn parse(input: &str) -> Result<Parsed, Error> { ... }  // pure borrow
fn normalize(input: &str) -> Cow<'_, str> { ... }    // maybe allocate
```

## Iterators over collect-then-loop

```rust
// Wrong — allocates intermediate Vec
let names: Vec<String> = users.iter().map(|u| u.name.clone()).collect();
for name in names {
    process(&name);
}

// Right — single pass, no allocation
for user in &users {
    process(&user.name);
}

// Or
users.iter().for_each(|u| process(&u.name));
```

Only collect when you need the collection (passing to another function, iterating multiple times, indexing).

## Avoid clone() to dodge borrow checker

Per CLAUDE.md. The fix is almost always restructuring ownership, not adding `.clone()`. Common patterns:

- Pass `&T` instead of `T`
- Return owned `T` from constructors, references from accessors
- Use `Cow<'_, T>` for parameters that might be borrowed or owned
- Use `Arc<T>` for shared ownership across threads/tasks
- Restructure to remove the aliasing the borrow checker is rejecting

`.clone()` is correct when the type is genuinely cheap to clone (`Arc`, `Rc`, small `Copy` types, integer IDs) or when you actually need an independent owned copy. Not as a workaround.

## Allocation awareness

- `format!("{}", x)` allocates. `write!(&mut buf, "{}", x)` reuses a buffer.
- `String::new()` doesn't allocate; `String::with_capacity(n)` allocates once for known sizes.
- `Vec::new()` doesn't allocate; `Vec::with_capacity(n)` allocates once.
- `.to_string()` allocates. `.into()` from `&str` to `String` allocates. `Cow::Borrowed(&str)` doesn't.

Profile before optimizing. `cargo flamegraph` for CPU profiling, `cargo bloat` for binary size investigation, `dhat` (via `dhat-rs`) for heap profiling.

---

# FFI

When Rust talks to C, or C calls Rust:

```rust
#[repr(C)]
pub struct Buffer {
    data: *mut u8,
    len: usize,
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn process_buffer(buf: Buffer) -> i32 {
    // SAFETY: caller guarantees buf.data points to buf.len readable bytes,
    // valid for the duration of this call, and not aliased mutably elsewhere.
    let slice = unsafe { std::slice::from_raw_parts(buf.data, buf.len) };
    // ...
    0
}
```

Every `unsafe` gets a `// SAFETY:` comment explaining the invariants the caller must uphold or that you've verified. Per CLAUDE.md, no exceptions.

For generating C headers: `cbindgen`. For consuming C: `bindgen`. Both run in `build.rs`.

For WASM in the browser: `wasm-bindgen` + `wasm-pack`. The browser is a different runtime — no Tokio, no threads (without SharedArrayBuffer), no filesystem. `web-sys` for DOM access.

---

# Documentation

`///` doc comments compile as part of the test suite when `cargo test` runs (doctests).

```rust
/// Computes the SHA-256 hash of the input.
///
/// # Examples
///
/// ```
/// let hash = my_crate::sha256(b"hello");
/// assert_eq!(hash.len(), 32);
/// ```
pub fn sha256(input: &[u8]) -> [u8; 32] { ... }
```

Doctests double as both documentation and integration tests. Use them for the public API surface.

`#![deny(missing_docs)]` at the crate root for libraries — every public item needs a doc comment. Don't enable it for binaries or internal crates.

`cargo doc --open` to preview. Review before publishing.

---

# Crate selection

For common categories, the current defaults:

- **Async runtime**: `tokio` (with `features = ["full"]` for prototypes, narrowed for production)
- **HTTP server**: `axum` 0.8+ (Tokio team, Tower middleware, plain async fn handlers)
- **HTTP client**: `reqwest` (with `default-features = false, features = ["rustls-tls", "json"]` to avoid native-tls)
- **Serialization**: `serde` + format crate (`serde_json`, `bincode`, `toml`, `serde_yaml`)
- **SQL**: `sqlx` (compile-time checked, async, no ORM). `sea-orm` if you want an ORM. `diesel` for sync.
- **Migrations**: `sqlx::migrate!` macro, or `sqlx-cli` for managing them outside the binary
- **CLI**: `clap` 4+ with derive macros
- **Errors**: `thiserror` 2 for libraries, `anyhow` 1 for applications
- **Logging/tracing**: `tracing` + `tracing-subscriber` (with `env-filter` and `json` features)
- **UUIDs**: `uuid` with `["v4", "serde"]`
- **Time**: `chrono` for DateTime work, `time` for some embedded contexts. `jiff` is the modern alternative — newer, better API, evaluate if starting fresh.
- **Validation**: `validator` for derive-based field validation
- **Config**: `figment` or `config` for layered config from files + env
- **Concurrent collections**: `dashmap` for concurrent HashMap, `arc-swap` for atomic Arc<T> swaps
- **Channels**: `tokio::sync::*` for async, `crossbeam-channel` for sync MPMC, `flume` for cross-runtime
- **Atomic numerics**: `std::sync::atomic::*` for the common types, `atomig` for atomic structs
- **Random**: `rand` (with the right feature set — defaults pull in os-rng which is correct for most apps)
- **Crypto**: `ring` for primitives, `argon2` or `bcrypt` for password hashing, `jsonwebtoken` for JWTs
- **HTTP middleware**: `tower-http` for the standard set
- **Property testing**: `proptest`
- **Snapshot testing**: `insta`
- **Faster test runner**: `cargo-nextest`
- **Audio realtime**: `rtrb` or `ringbuf-basedrop`, `assert_no_alloc`, `basedrop`
- **Embedded HTTP**: `embassy-net` + `embedded-svc` if you're in no_std land

Don't pull in a crate for what `std` covers. `std::collections::HashMap` is fine. `std::time::Duration` is fine. `std::sync::LazyLock` replaces `lazy_static`.

When in doubt, check `lib.rs` (the alternative crates index) or `blessed.rs` (curated recommendations) for current best-of-class.

---

# Anti-patterns

**`Box<dyn Error>` in library APIs.** Consumers can't match. Use `thiserror`.

**`.unwrap()` everywhere.** Either prove the unwrap is safe with a `// SAFETY:` comment or return a `Result`.

**Hold locks across `.await`.** Almost always a bug. Either drop the lock first or use `tokio::sync::Mutex` deliberately.

**Spawn-and-forget tasks from request handlers.** They outlive the request, lose tracing context, and leak on shutdown. Use structured concurrency.

**Unbounded channels.** Memory leak. Always size the buffer.

**Mix runtimes in the same binary.** Pick Tokio. Stay with Tokio.

**`SELECT *` in sqlx queries.** Loses compile-time column checking. Always list columns.

**Single-threaded async runtime in production.** `flavor = "current_thread"` is for tests and CLIs. Servers want multi-thread.

**Custom `Service` implementations for middleware.** Use `axum::middleware::from_fn`. Implement `Service` only when the from_fn version genuinely can't express what you need.

**`println!` in production.** Use `tracing`. Configure the subscriber once at startup.

**Skipping `cargo audit` and `cargo deny` in CI.** Supply chain attacks against Rust crates have happened. The tools are free; the cost of skipping is unbounded.

**Pinning to outdated `tokio = "0.2"` or `axum = "0.6"` for "stability".** Major versions of these crates are the production defaults. Pinning to ancient versions inherits unfixed bugs and locks you out of the current ecosystem.

**Ignoring clippy.** `-D warnings` is the only setting that prevents lint debt.

**Forgetting `with_graceful_shutdown` on axum servers.** Crashing handlers mid-request loses data and corrupts client expectations.

**Building debug binaries for benchmarks.** Performance numbers from `cargo run` (debug) are meaningless. Use `cargo run --release` for any timing claim.

---

# Audit checklist (extends audit.md)

When auditing Rust code, in addition to the rules in audit.md:

1. **Edition**: every crate on `edition = "2024"`?
2. **Toolchain pinned**: `rust-toolchain.toml` present with explicit channel?
3. **CI gates**: `cargo fmt --check`, `cargo clippy -- -D warnings`, `cargo audit`, `cargo deny check`, `cargo test`?
4. **Async rules**: any locks held across `.await`? Any unbounded channels? Any sync work blocking a worker thread?
5. **Error types**: libraries using `thiserror` with proper source chains? Applications using `anyhow` with `with_context`? Any `Box<dyn Error>` in library APIs?
6. **Tracing**: structured logging via `tracing`, not `println!`? Spans on request handlers? Sensitive data redacted?
7. **Database**: sqlx queries with explicit column lists? Compile-time checking enabled (DATABASE_URL or `.sqlx/`)? Connection pool sized for the runtime?
8. **HTTP**: `with_graceful_shutdown` wired? Errors implement `IntoResponse`? Tower middleware layered correctly (trace outermost)?
9. **Audio thread (if applicable)**: any allocations in the realtime callback? Any `Arc<T>::drop` on the audio thread? `assert_no_alloc` guarding the path in debug builds?
10. **Documentation**: public API has `///` doc comments? Doctests compile? `#![deny(missing_docs)]` on library crate roots?
11. **Workspace hygiene**: shared deps in `[workspace.dependencies]`? `resolver = "3"`? Consistent versions across members?
12. **Profile settings**: release profile has `lto = "thin"` (or `"fat"` if measured), `codegen-units = 1`, `strip = "symbols"`, appropriate `panic` strategy?

---

# References

- The Rust Programming Language (2024 edition): https://doc.rust-lang.org/book/
- Async Book: https://rust-lang.github.io/async-book/
- Tokio docs: https://docs.rs/tokio/
- axum docs and examples: https://docs.rs/axum/, https://github.com/tokio-rs/axum/tree/main/examples
- sqlx README: https://github.com/launchbadge/sqlx
- Rust API Guidelines (style and naming): https://rust-lang.github.io/api-guidelines/
- blessed.rs (curated crate recommendations): https://blessed.rs/
- This Week in Rust (weekly): https://this-week-in-rust.org/

[Inference] Some specifics here track current ecosystem state as of April 2026 (axum 0.8 path syntax, sqlx 0.8, thiserror 2, std::sync::LazyLock since 1.80). Verify against current docs before relying on exact version numbers.

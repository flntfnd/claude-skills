---
name: rust-conventions
description: Operational Rust conventions for production code, extending the floor rules in CLAUDE.md. Covers edition and toolchain pinning, CI gates (fmt, clippy, audit, deny, nextest), error handling with thiserror and anyhow, async/Tokio discipline (cancellation safety, Send bounds, structured concurrency, backpressure), the axum/sqlx/tower web stack, tracing-based observability, concurrency primitives (channels, locks, atomics, interior mutability), realtime audio-thread rules (lock-free ring buffers, no-alloc verification, basedrop), testing strategy, project and workspace structure, performance and allocation discipline, FFI and WASM, a crate selection guide across ~30 categories, an anti-pattern list, and a 12-point audit checklist. Use whenever writing, reviewing, or auditing Rust code, setting up a new Rust service or workspace, wiring Rust CI, choosing a crate, or debugging async, ownership, or audio-thread issues.
---

# Rust conventions

Operational layer on top of the floor rules in CLAUDE.md (no `unwrap()` outside throwaway code, `thiserror`/`anyhow` split, no `clone()` to dodge the borrow checker, `unsafe` needs a safety comment). This file assumes those rules and adds the how, the exact APIs, and the gotchas.

Default stack: Tokio for async, axum for HTTP, sqlx for SQL, tracing for observability, thiserror + anyhow for errors, edition 2024.

## Quick reference

| Topic | File |
| --- | --- |
| Async runtime, cancellation safety, Send bounds, structured concurrency, channels, locks, atomics, interior mutability | [reference/async-and-concurrency.md](reference/async-and-concurrency.md) |
| axum handlers/state/errors, sqlx queries/migrations, Tower middleware | [reference/web-stack.md](reference/web-stack.md) |
| tracing setup, spans, subscriber config, what to log | [reference/observability.md](reference/observability.md) |
| Realtime audio thread: lock-free SPSC queues, `assert_no_alloc`, `basedrop`, drop discipline | [reference/audio-thread.md](reference/audio-thread.md) |
| Test strategy, async tests, sqlx::test, project layout, workspaces | [reference/testing-and-structure.md](reference/testing-and-structure.md) |
| Crate picks across ~30 categories, current versions | [reference/crate-selection.md](reference/crate-selection.md) |
| String/allocation discipline, iterators, profiling, FFI, WASM, doctests | [reference/performance-and-ffi.md](reference/performance-and-ffi.md) |

## Edition and toolchain

Every project: `edition = "2024"`. It's been the production default since Rust 1.85 (Feb 2025) — RPIT lifetime capture, async closures (`async || {}`), and the `AsyncFn`/`AsyncFnMut`/`AsyncFnOnce` family are all stable and production-ready under it. Migrate existing crates with `cargo fix --edition`, commit, then `cargo fix --edition-idioms` as a separate commit.

No edition after 2024 has shipped or been scheduled. A 2027 edition is under active community discussion (candidate features floated include Polonius and range-expression fixes) but nothing is confirmed, and there's real debate about whether it happens on that timeline at all or slips to 2028/2029. Don't write code or docs that assume a 2027 edition exists yet. `[Unverified — check the edition guide before committing to this]`

```toml
[package]
name = "my-app"
version = "0.1.0"
edition = "2024"
rust-version = "1.85"   # floor; bump the toolchain pin below independently

[profile.release]
lto = "thin"
codegen-units = 1
strip = "symbols"
panic = "abort"          # only for binaries that don't need unwinding

[profile.dev]
debug = "line-tables-only"
opt-level = 0

[profile.dev.package."*"]
opt-level = 3             # keeps heavy dev-deps (image, crypto, DB drivers) tolerable
```

`rust-toolchain.toml` at the repo root pins the compiler for reproducibility. Pin the current stable release and bump it on a schedule — don't let it drift silently:

```toml
[toolchain]
channel = "1.98.0"        # bump periodically; verify against releases.rs
components = ["rustfmt", "clippy", "rust-src"]
```

`rust-version` in `Cargo.toml` is a floor (MSRV); the toolchain channel is what actually builds. `resolver = "3"` is implied by `edition = "2024"` — don't set it explicitly unless the workspace is virtual (no root package), where it must be set by hand.

## CI gates — non-negotiable

```bash
cargo fmt --all -- --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all-features          # or cargo nextest run for speed
cargo audit
cargo deny check
```

- `-D warnings` on clippy is the only setting that prevents lint debt accumulating.
- `cargo audit` checks the dependency tree against the RustSec advisory database. Any `RUSTSEC-*` finding blocks merge.
- `cargo deny check` validates licenses, duplicate versions, and dependency sources against `deny.toml`. Use it on anything past a prototype.
- `cargo nextest run` is faster and more parallel than `cargo test`. Not the built-in default, but should be the team default.
- Format-on-save in editor config. rustfmt defaults are correct — don't customize without a specific, written reason.

## Error handling — applies to every line

Two patterns, chosen deliberately, never mixed within a boundary:

**Library code → `thiserror`.** Errors are API surface: stable variants, source chains, types consumers can match on.

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum DbError {
    #[error("connection failed: {0}")]
    Connection(#[from] sqlx::Error),

    #[error("row not found for id {id}")]
    NotFound { id: uuid::Uuid },
}
```

`#[from]` generates the `From` impl `?` relies on — use it for one-to-one wrappings; write the impl by hand if two source types map to one variant. `#[source]` (without `#[from]`) includes a field in the error chain while adding your own context.

**Application code → `anyhow`.** Top-level binary errors, `main` is the caller, context strings are the value.

```rust
use anyhow::{Context, Result};

async fn load_config(path: &Path) -> Result<Config> {
    let raw = tokio::fs::read_to_string(path)
        .await
        .with_context(|| format!("reading config from {}", path.display()))?;
    toml::from_str(&raw).with_context(|| format!("parsing TOML from {}", path.display()))
}
```

`with_context` (lazy closure) over `context` (eager) for anything that allocates — the closure only runs on the error path.

**Never:**
- `Result<T, Box<dyn Error>>` in library APIs — consumers can't match on it.
- `.unwrap()` outside tests/examples/genuinely-impossible states (prove it in the safety comment).
- `.expect("should never happen")` — type-encode it if it truly can't happen; return `Result` if it might.
- Stringly-typed errors (`Err("something failed".to_string())`).
- `let _ = fallible_call()` without a comment explaining why the error is safe to drop.

## Ownership discipline — applies to every line

Per CLAUDE.md: no `.clone()` to dodge the borrow checker. The fix is restructuring ownership, not copying:

- Pass `&T` instead of `T`.
- Return owned `T` from constructors, references from accessors.
- `Cow<'_, T>` for parameters that might be borrowed or owned.
- `Arc<T>` for shared ownership across threads/tasks.
- Restructure to remove the aliasing the borrow checker is actually rejecting.

`.clone()` is correct when the type is genuinely cheap (`Arc`, `Rc`, small `Copy` types, integer IDs) or an independent owned copy is actually needed — never as a reflex to make the compiler stop complaining. See [reference/performance-and-ffi.md](reference/performance-and-ffi.md) for the full allocation-awareness list.

## Anti-patterns

**`Box<dyn Error>` in library APIs.** Consumers can't match. Use `thiserror`.

**`.unwrap()` everywhere.** Prove it safe with a `// SAFETY:` comment or return `Result`.

**Holding a lock across `.await`.** Almost always a bug. Drop the lock first, or use `tokio::sync::Mutex` deliberately.

**Spawn-and-forget tasks from request handlers.** They outlive the request, lose tracing context, leak on shutdown. Use structured concurrency (`join!`/`try_join!`, or a tracked `spawn` with a handle).

**Unbounded channels.** An unbounded memory leak waiting to happen. Always size the buffer.

**Mixing async runtimes in one binary.** Pick Tokio, stay with Tokio.

**`SELECT *` in sqlx queries.** Loses compile-time column checking. List columns explicitly.

**`flavor = "current_thread"` in production servers.** That flavor is for tests and CLIs. Servers want multi-thread.

**Hand-rolled `tower::Service` for middleware.** Use `axum::middleware::from_fn`; implement `Service` only when `from_fn` genuinely can't express it.

**`println!`/`eprintln!` in production code.** Use `tracing`, configure the subscriber once at startup.

**Skipping `cargo audit`/`cargo deny` in CI.** Supply-chain attacks against crates.io have happened. The tools are free.

**Pinning ancient majors ("`tokio = "0.2"`", "`axum = "0.6"`") for "stability."** Inherits unfixed bugs, locks you out of the current ecosystem.

**Ignoring clippy warnings.** `-D warnings` is the only setting that holds the line.

**Skipping `with_graceful_shutdown` on axum servers.** Crashing handlers mid-request loses data.

**Timing debug builds.** `cargo run` (debug) numbers are meaningless for perf claims. Always `--release`.

## Audit checklist

Extends the general rules in the `code-audit` skill. Working through a Rust diff or codebase:

1. **Edition** — every crate on `edition = "2024"`?
2. **Toolchain pinned** — `rust-toolchain.toml` present with an explicit channel?
3. **CI gates** — fmt --check, clippy -D warnings, audit, deny check, test, all wired?
4. **Async rules** — any lock held across `.await`? Any unbounded channel? Any sync work blocking a worker thread instead of `spawn_blocking`?
5. **Error types** — libraries on `thiserror` with real source chains? Applications on `anyhow` with `with_context`? Any `Box<dyn Error>` leaking into a library API?
6. **Tracing** — structured `tracing`, not `println!`? Spans on request handlers? Sensitive data redacted?
7. **Database** — sqlx queries with explicit column lists? Compile-time checking on (`DATABASE_URL` or committed `.sqlx/`)? Pool sized for the runtime?
8. **HTTP** — `with_graceful_shutdown` wired? Errors implement `IntoResponse`? Middleware layered trace-outermost?
9. **Audio thread (if applicable)** — any allocation in the realtime callback? Any `Arc<T>` dropped on the audio thread? `assert_no_alloc` guarding the path in debug builds?
10. **Documentation** — public API has `///` docs? Doctests compile? `#![deny(missing_docs)]` on library crate roots?
11. **Workspace hygiene** — shared deps in `[workspace.dependencies]`? Consistent versions across members?
12. **Profile settings** — release profile has `lto`, `codegen-units = 1`, `strip = "symbols"`, an intentional `panic` strategy?

## References

- The Rust Book (2024 edition): https://doc.rust-lang.org/book/
- Async Book: https://rust-lang.github.io/async-book/
- Edition Guide (2024 edition, resolver v3): https://doc.rust-lang.org/edition-guide/
- Rust API Guidelines: https://rust-lang.github.io/api-guidelines/
- blessed.rs (curated crate recommendations): https://blessed.rs/
- releases.rs (Rust release/version tracker): https://releases.rs/
- This Week in Rust: https://this-week-in-rust.org/

Version numbers throughout this skill were verified via web search in August 2026 (Rust 1.98 stable, 1.99 in beta; axum 0.8.9 with 0.9 still in development on main, unreleased; sqlx 0.9.0; tokio 1.53.x). Crate ecosystems move fast — re-verify anything load-bearing (a version pin going into a new `Cargo.toml`) against crates.io or docs.rs rather than trusting this file indefinitely. Items marked `[Unverified]` or `[Inference]` in the reference files could not be confirmed from a primary/changelog source and should get a direct check before being treated as fact.

# Testing and project structure

## Contents

- [What to test](#what-to-test)
- [Async tests](#async-tests)
- [Test database](#test-database)
- [Don't mock everything](#dont-mock-everything)
- [Single binary, single crate](#single-binary-single-crate)
- [Workspace](#workspace)
- [When to split into crates](#when-to-split-into-crates)

`cargo test` runs unit tests (`#[cfg(test)]` modules) and integration tests (`tests/` directory). `cargo nextest run` is the faster, more parallel alternative — not the built-in default, but should be the team default.

## What to test

Per CLAUDE.md: critical paths and business logic. Skip trivial getters/setters.

- Unit tests: pure functions, parsing, validation, error paths.
- Integration tests: HTTP handlers (via `axum::serve` against `TcpListener::bind("127.0.0.1:0")` and a real client), database queries against a test DB, end-to-end flows.
- Property tests with `proptest` for serialization round-trips and parser invariants.
- Snapshot tests with `insta` for complex output (JSON responses, generated code).

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

Default flavor is single-threaded (`current_thread`). Switch to multi-thread only when concurrency is actually part of what's being tested, not incidental.

## Test database

```rust
#[sqlx::test]
async fn user_can_be_created(pool: PgPool) -> anyhow::Result<()> {
    let id = create_user(&pool, "alice@example.com").await?;
    let user = fetch_user(&pool, id).await?;
    assert_eq!(user.email, "alice@example.com");
    Ok(())
}
```

`#[sqlx::test]` creates a fresh test database per test, runs migrations, passes the pool, cleans up automatically. Requires `DATABASE_URL` pointing at a Postgres the test process can create databases in.

## Don't mock everything

Mock external I/O at the boundary (HTTP clients, third-party APIs). Don't mock your own database or business logic — use a real test DB and real functions. Mocks that simulate your own code's behavior tend to drift from what that code actually does.

For external HTTP, `wiremock` runs a real HTTP server to mock against, more realistic than trait-based mocking.

## Single binary, single crate

For services up to roughly 5k LoC:

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
    config.rs            # env parsing
    db.rs                 # pool setup, migrations
    error.rs              # AppError + IntoResponse
    routes/
      mod.rs             # Router::new() composition
      users.rs           # handlers + request/response types
      ...
    domain/               # business logic
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

```toml
[workspace]
members = ["crates/*"]
# resolver = "3" is implied by edition = "2024" on the root package;
# set it explicitly only on a virtual workspace with no root package.

[workspace.package]
version = "0.1.0"
edition = "2024"
rust-version = "1.85"

[workspace.dependencies]
tokio = { version = "1", features = ["full"] }
serde = { version = "1", features = ["derive"] }
sqlx = { version = "0.9", features = ["runtime-tokio", "tls-rustls", "postgres"] }
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

This keeps versions aligned across the workspace.

## When to split into crates

Split when:
- The piece is independently versioned (published library).
- Compile-time pressure justifies caching boundaries.
- Separate teams own separate crates.
- Multiple binaries share a substantial library.

Don't split prematurely. A single crate with well-organized modules is easier to refactor than a workspace with circular-dependency tendencies.

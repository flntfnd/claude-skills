# Web stack: axum, sqlx, tower

## Contents

- [Default dependency block](#default-dependency-block)
- [axum](#axum)
- [Errors as IntoResponse](#errors-as-intoresponse)
- [sqlx](#sqlx)
- [Tower middleware](#tower-middleware)

## Default dependency block

```toml
[dependencies]
tokio = { version = "1", features = ["full"] }
axum = { version = "0.8", features = ["macros"] }
tower = "0.5"
tower-http = { version = "0.7", features = ["trace", "cors", "compression-gzip"] }
sqlx = { version = "0.9", features = ["runtime-tokio", "tls-rustls", "postgres", "uuid", "chrono", "macros"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter", "json"] }
thiserror = "2"
anyhow = "1"
uuid = { version = "1", features = ["v4", "serde"] }
```

Verified via web search in August 2026: axum's latest released version is 0.8.9 (0.9 is being developed on the `main` branch but has **not** shipped to crates.io — `{id}` path syntax and everything below is still correct for new code). tower-http moved to 0.7.0. sqlx moved to 0.9.0, which has real breaking changes over 0.8 — see the sqlx section below before bumping an existing project. `thiserror` is at 2.0.x, `tower` at 0.5.x, `tracing`/`tracing-subscriber` unchanged in shape (0.1.x / 0.3.x).

On the `chrono` feature: chrono's maintainer soft-deprecated chrono/chrono-tz in January 2026 (`chronotope/chrono#1768`) in favor of `jiff`, which now has direct sqlx integration via the `jiff-sqlx` crate (0.2.0, Postgres and SQLite only — no MySQL) rather than a first-party sqlx feature. New projects should default to `jiff` + `jiff-sqlx` over `chrono` unless there's a specific reason to stay (existing large chrono surface, a dependency that hard-requires chrono types). Confirmed against the primary GitHub issue, no longer `[Unverified]`. See [crate-selection.md](crate-selection.md) for more.

## axum

axum is the default web framework: Tokio team, Tower middleware, plain async functions as handlers. Path syntax is `{id}`, not the pre-0.8 `:id` — it aligns with OpenAPI.

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

State goes through `with_state(...)`, extracted with `State<...>`. `Arc<AppState>` is the standard wrapping. Don't use `Extension<...>` for new code — it's the older pattern.

## Errors as IntoResponse

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

Log errors at the response boundary, not inside business logic. Business logic returns `Result`; the response layer decides what to log and what to surface to the client.

## sqlx

sqlx is compile-time-checked SQL, not an ORM. You write SQL; the macros validate it against the schema at build time.

```rust
let user = sqlx::query_as!(
    User,
    "SELECT id, email, created_at FROM users WHERE id = $1",
    id
)
.fetch_one(&pool)
.await?;
```

Compile-time checking needs `DATABASE_URL` set at build time, or `cargo sqlx prepare` to generate offline query metadata (`.sqlx/` committed to the repo for CI builds without DB access).

Always specify column lists — `SELECT *` compiles but pins your code to column order.

`query!` for non-result queries, `query_as!` to map into a struct, `query_scalar!` for single-value results.

Migrations: `sqlx::migrate!()` embeds `migrations/` into the binary. Run on startup or via `sqlx-cli`. Pin order with timestamp prefixes (`20260416120000_create_users.sql`).

Connection pool sizing: start with `max_connections = number_of_cpus * 2`, tune from there. On managed Postgres (Supabase, RDS Proxy, etc.), respect the provider's own pool limit.

### sqlx 0.9 — what changed from 0.8

Verified against the sqlx changelog/discussion in August 2026. If bumping an existing 0.8 project, check for:

- **`SqlSafeStr` trait.** The `query*()` family now takes a generic parameter implementing `SqlSafeStr` instead of a bare `&str`, to signal an injection-safe query string. Plain `&str` literals still work; dynamically-built query strings may need an explicit wrap.
- **`sqlx.toml` config file.** New project-level config for multi-database/multi-tenant setups, global type overrides, and SQLite compile-time extension loading. Optional, not required to keep existing behavior.
- **Postgres option escaping.** `PgConnectOptions::options()` now auto-escapes; remove any manual escaping in existing code, it'll double-escape.
- **MySQL text columns.** Previously inferred as `Vec<u8>`, now infer as `String`. Also, the default collation directive changed from `SET NAMES utf8mb4 COLLATE utf8_general_ci` to plain `SET NAMES utf8mb4` (server picks the default collation).
- **`TransactionManager`** is no longer re-exported from the crate root. It was `#[doc(hidden)]` and already marked unstable, but the changelog flags that this will break SeaORM if SeaORM doesn't fix it proactively — worth checking if the project depends on SeaORM.

Confirmed line-for-line against `CHANGELOG.md` in the sqlx repo (no longer a synthesized summary) — all five points above match the actual 0.9.0 changelog entries. Still worth a direct read on a production bump for anything project-specific the changelog calls out beyond this list.

## Tower middleware

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

Layers wrap bottom-to-top in code but execute outer-to-inner at runtime: trace first, then auth, then rate limit, then handler.

For custom middleware, prefer `axum::middleware::from_fn` over implementing `tower::Service` by hand — the trait is correct but verbose. Reach for a hand-rolled `Service` only when `from_fn` genuinely can't express what's needed (e.g. middleware that needs to buffer/replay the body across layers).

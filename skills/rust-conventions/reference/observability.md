# Observability with tracing

`println!`/`eprintln!` don't belong in production code. Use `tracing` (current 0.1.x) with `tracing-subscriber` (current 0.3.x).

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

`#[instrument]` adds a span around the function. Fields are structured. `skip` removes args not worth logging (pools, large blobs). `%` formats with `Display`, `?` with `Debug`.

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

Set the log level via `RUST_LOG=info,my_app=debug,sqlx=warn` — per-module filtering is the point. JSON output for production (Datadog, Loki, CloudWatch all parse it); swap to pretty output for local dev based on env.

## Spans propagate context

Spans nest. A request gets a top-level span (axum's `TraceLayer` adds it); child spans inherit it. `tracing::Instrument::instrument` attaches a span to a future explicitly.

For distributed tracing across services, add `tracing-opentelemetry` and export to an OTLP collector.

## What to log

- `info!` — state changes the operator cares about (request received, user created, config reloaded).
- `warn!` — recoverable problems (retry occurred, fallback used, rate limit hit).
- `error!` — needs attention (5xx responses, database failures, caught panics).
- `debug!` — development context (intermediate state, branch decisions).
- `trace!` — fine-grained event-stream debugging (rare).

Never log secrets, tokens, full request bodies (PII risk), or raw error messages from external services without sanitization.

# Async and concurrency

## Contents

- [Runtime setup](#runtime-setup)
- [Async closures](#async-closures-2024-edition)
- [Cancellation safety](#cancellation-safety)
- [Send bounds on async traits](#send-bounds-on-async-traits)
- [Don't block the runtime](#dont-block-the-runtime)
- [Structured concurrency](#structured-concurrency)
- [Channels](#channels)
- [Locks](#locks)
- [Atomics](#atomics)
- [Interior mutability](#interior-mutability)

Tokio is the default runtime. Don't mix runtimes — pick one per binary. async-std and smol exist but the ecosystem (axum, tower, sqlx's `runtime-tokio` feature, most middleware) is built around Tokio. Current Tokio is in the 1.5x line (1.52.x); LTS branches exist (1.47.x, 1.51.x) for teams that want a slower-moving pin — `[Unverified]` check `docs.rs/tokio` for the current LTS window before committing to one.

## Runtime setup

```rust
#[tokio::main(flavor = "multi_thread", worker_threads = 4)]
async fn main() -> anyhow::Result<()> {
    // ...
}
```

Specify `worker_threads` explicitly. The default (number of CPUs) is rarely right in a container with a CPU limit — read the limit from the environment, or use `tokio::runtime::Builder` for fine control.

## Async closures (2024 edition)

`async || {}` is stable and the default over `Box<dyn Future>` boilerplate for callbacks and middleware.

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

For library APIs that take async callbacks, accept `AsyncFn`, `AsyncFnMut`, or `AsyncFnOnce` from the prelude — cleaner than the older `impl Fn() -> impl Future<...>` pattern.

## Cancellation safety

Every `.await` is a cancellation point. If the task is dropped (timeout, parent cancellation), execution stops there and code after that point never runs.

This matters for cleanup. Use `Drop` guards, not "do cleanup at the end of the function." RAII works in async because `Drop` runs on cancellation even though `.await` doesn't.

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
        cleanup_sync(f); // sync cleanup, runs on drop including cancellation
    });
    let data = read_async(&file).await?;
    let result = transform(&data).await?;
    Ok(result)
}
```

For async cleanup, structured concurrency via `tokio::select!` with a cancellation token (`tokio_util::sync::CancellationToken`) is the pattern.

## Send bounds on async traits

`async fn` in traits works on stable, but generic functions over those traits hit the "Send bound" problem: the compiler can't express "the future this returns is `Send`" without help. Two options:

- `trait_variant::make(Send)` — generates a non-Send and a Send variant of the trait. Well-established, works today.
- Return Type Notation (RTN, `T::method(..): Send`) — stabilized for where-clause and item-bound positions on trait methods with lifetime generics. `[Unverified]` whether RTN alone now fully replaces `trait_variant` for the common "make my async trait Send" case, or whether it only covers a subset — check current async-book guidance before dropping `trait_variant` from a project that relies on it.

```rust
#[trait_variant::make(Send)]
pub trait Repository {
    async fn fetch(&self, id: Uuid) -> Result<Item>;
}
```

Most async runtimes that matter in practice (Tokio multi-thread, axum) need `Send` futures.

## Don't block the runtime

Sync work over a few microseconds blocks the worker thread it's on. Move it:

- CPU-heavy work → `tokio::task::spawn_blocking`
- Blocking I/O (sync file reads, blocking DB drivers) → `spawn_blocking`
- Synchronous third-party libraries → `spawn_blocking` or a wrapper

`spawn_blocking` runs on a dedicated blocking thread pool, separate from the async worker pool. Fine to use — just don't pretend sync work is free in async context.

## Structured concurrency

Spawn tasks, await them in a scope, handle their results. Don't spawn fire-and-forget tasks from a request handler — they outlive the request and lose its tracing context.

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

`tokio::join!` runs futures concurrently on the same task. `tokio::spawn` creates a genuinely independent task — use it when work should outlive the caller's scope and the parent doesn't need to wait. `tokio::try_join!` short-circuits on the first error.

For backpressure, use bounded channels (`tokio::sync::mpsc::channel(N)`). Unbounded channels are an unbounded memory leak waiting to happen.

## Channels

- `tokio::sync::mpsc` — async message-passing, bounded by default. Pick the buffer size deliberately.
- `tokio::sync::watch` — "latest value" broadcasts (config reload, state distribution).
- `tokio::sync::broadcast` — every receiver sees every message (event bus). Slow receivers lose messages once the buffer fills.
- `tokio::sync::oneshot` — single-message request/reply.
- Sync code: `crossbeam-channel` for MPMC, `flume` for cross-runtime, `std::sync::mpsc` only for trivial cases (slower than crossbeam).

## Locks

`std::sync::Mutex`/`RwLock` are correct in async code as long as the critical section is short and doesn't `.await`. Holding a lock across `.await` is almost always a deadlock waiting to happen.

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
} // lock released before the next await
```

Use `tokio::sync::Mutex` only when a lock genuinely must be held across `.await`. It's slower and the API is async (`.lock().await`).

`parking_lot` gives faster `Mutex`/`RwLock` than std, with no poisoning. Use it when measurement justifies the dependency.

## Atomics

For counters, flags, small shared state: `std::sync::atomic::AtomicU64`, `AtomicBool`, etc. Memory ordering matters — default to `Ordering::SeqCst` until profiling justifies relaxing it.

`Arc<AtomicU64>` is fine for shared counters. `dashmap` for concurrent maps where lock-free is worth the dependency.

## Interior mutability

- `Cell<T>` — `Copy` types, single-threaded.
- `RefCell<T>` — non-`Copy`, single-threaded, panics on borrow violations at runtime.
- `OnceCell<T>` / `OnceLock<T>` — write-once values (config, computed constants).
- `LazyLock<T>` — lazily-initialized statics; `std::sync::LazyLock` has been stable since 1.80 and replaces both the `lazy_static` crate and `once_cell::sync::Lazy` in new code.

```rust
use std::sync::LazyLock;
use prometheus::IntCounter;

static REQUEST_COUNT: LazyLock<IntCounter> = LazyLock::new(|| {
    prometheus::register_int_counter!("requests_total", "total requests").unwrap()
});
```

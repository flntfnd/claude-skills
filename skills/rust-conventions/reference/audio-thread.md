# Audio thread (extends CLAUDE.md)

CLAUDE.md establishes the rule: no allocations, no locks, no Objective-C messaging on the realtime callback. This is the Rust-specific implementation of that rule.

Maintenance status, checked directly against the crates.io API in August 2026: this is a mixed bag, not a uniformly healthy set.

- `rtrb` — actively maintained, released as recently as August 2026 (0.4.0). Safe default.
- `basedrop` — last published October 2025 (0.1.3). Reasonably current, single-digit release cadence but not abandoned.
- `ringbuf-basedrop` — last published **May 2022** (0.1.1), over four years stale, single maintainer, 716 lines. This is not actively maintained. Treat the recommendation below as "the fork exists and works" rather than "this is a healthy dependency" — check its issue tracker before pulling it into new production code, and consider whether wrapping plain `ringbuf` with your own `basedrop::Shared` glue is safer than depending on an unmaintained fork.
- `assert_no_alloc` — last published **August 2021** (1.1.2), over five years stale. Still the standard answer for this specific job (no real competitor has emerged), but it's unmaintained in the literal sense — no bug fixes are coming. Vendor it or fork it if a compiler/std change ever breaks it.

None of these are large enough crates that staleness alone is disqualifying — the audio-Rust ecosystem is thin and these are all small, focused, largely-finished pieces of code — but don't assume "still the standard answer" means "actively maintained." Re-check crates.io yourself before a new dependency decision.

## Lock-free SPSC ring buffers

For audio thread → UI thread (or any cross-thread handoff where one side is realtime), use a wait-free SPSC queue:

- `rtrb` — single-producer single-consumer, no_std capable.
- `ringbuf` — const generics or heap allocation; for audio, use `ringbuf-basedrop` so dropping a reference doesn't deallocate on the realtime thread.
- `crossbeam-queue` — broader variety of queue types; for SPSC specifically the dedicated crates above are the better fit.

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

Size to a power of two. Allocate once at startup; never resize.

## Verifying no allocations on the audio thread

`assert_no_alloc` wraps a custom global allocator that aborts (or warns) if allocation is attempted inside a flagged scope.

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

Run the test suite under this allocator. Any audio path that allocates surfaces immediately instead of showing up as an intermittent glitch in production.

## Drop discipline

`Vec`, `String`, `Box`, `Arc<T>` (refcount hits zero), `Rc<T>` (same) — all deallocate on drop. Audio thread code must not own anything that allocates on drop.

`basedrop::Shared<T>` is a refcount type that defers deallocation to a non-realtime collector thread. Use it in place of `Arc<T>` when references will be dropped on the audio thread.

For owned data on the audio thread: pre-allocate in setup, pass references in, never own anything that drops to the allocator.

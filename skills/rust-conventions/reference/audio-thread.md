# Audio thread (extends CLAUDE.md)

CLAUDE.md establishes the rule: no allocations, no locks, no Objective-C messaging on the realtime callback. This is the Rust-specific implementation of that rule.

`[Unverified]` note up front: the small, specialized crates below (`rtrb`, `ringbuf-basedrop`, `basedrop`, `assert_no_alloc`) are the standard answer in the Rust audio community and their APIs shown here match current docs.rs, but this search pass could not confirm recent publish dates or active-maintenance status for all of them from crates.io directly (JS-rendered pages blocked a direct check). Before depending on any of them in a new project, check crates.io's "last updated" date and open-issues count yourself — realtime-audio crates are a thin part of the ecosystem and a stale one is a real risk.

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

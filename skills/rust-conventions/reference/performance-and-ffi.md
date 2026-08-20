# Performance, FFI, WASM, documentation

## Contents

- [String types](#string-types)
- [Iterators over collect-then-loop](#iterators-over-collect-then-loop)
- [Allocation awareness](#allocation-awareness)
- [FFI](#ffi)
- [WASM](#wasm)
- [Documentation](#documentation)

## String types

- `&str` — borrowed string slices in function parameters (default).
- `String` — owned, mutable.
- `Cow<'_, str>` — when the function might or might not need to allocate.
- `Box<str>` — immutable owned string, smaller than `String` (no capacity field).
- `Arc<str>` — cheaply-cloneable shared string.
- `&'static str` — compile-time string literals.

```rust
fn process(input: &str) -> String { ... }              // borrow input, return owned
fn parse(input: &str) -> Result<Parsed, Error> { ... }  // pure borrow
fn normalize(input: &str) -> Cow<'_, str> { ... }       // maybe allocate
```

## Iterators over collect-then-loop

```rust
// Wrong — allocates an intermediate Vec
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

Only collect when the collection itself is needed (passed to another function, iterated multiple times, indexed).

## Allocation awareness

- `format!("{}", x)` allocates; `write!(&mut buf, "{}", x)` reuses a buffer.
- `String::new()` doesn't allocate; `String::with_capacity(n)` allocates once for known sizes.
- `Vec::new()` doesn't allocate; `Vec::with_capacity(n)` allocates once.
- `.to_string()` allocates; `.into()` from `&str` to `String` allocates; `Cow::Borrowed(&str)` doesn't.

Profile before optimizing: `cargo flamegraph` for CPU, `cargo bloat` for binary size, `dhat` (via `dhat-rs`) for heap profiling. Always benchmark `--release` — debug-build timings are meaningless for perf claims.

## FFI

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

## WASM

For WASM in the browser: `wasm-bindgen` (current line 0.2.1xx) is the foundation. The browser is a different runtime — no Tokio, no threads without `SharedArrayBuffer`, no filesystem. `web-sys` for DOM access.

`wasm-pack` is the traditional build wrapper around `wasm-bindgen`, still receiving releases. `[Unverified]` there was recent public discussion in the wasm-bindgen project about wasm-pack's long-term maintenance ownership shifting — the wasm-bindgen docs reportedly still recommend it as of this pass, but confirm current tooling guidance (wasm-pack vs. `trunk` vs. building the target directly) before starting a new WASM project rather than assuming this file is current.

## Documentation

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

Doctests double as documentation and integration tests — use them for the public API surface.

`#![deny(missing_docs)]` at the crate root for libraries: every public item needs a doc comment. Don't enable it for binaries or internal crates.

`cargo doc --open` to preview before publishing.

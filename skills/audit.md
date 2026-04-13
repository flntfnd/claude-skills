# Audit

Run all audits in order. Group findings by category. Flag every issue as critical, warning, or minor. Don't rewrite anything unless asked.

---

## Code

1. **Dead code**: unused vars, imports, functions, unreachable branches
2. **Memory leaks**: uncleared timers, event listener accumulation, unclosed streams, stale closures
3. **Security**: service_role exposure, RLS bypass paths, JWT verification gaps, unvalidated inputs, exposed secrets
4. **Error handling**: unhandled promise rejections, missing error boundaries, silent failures
5. **Performance**: unnecessary re-renders, missing memoization, N+1 queries
6. **Deprecated APIs**: anything with a current replacement available

---

## UI

1. **Hardcoded values**: flag every hardcoded color, spacing, type size, radius, shadow, and duration
2. **Design system coherence**: tokens defined, named consistently, actually used? Parallel systems contradicting each other?
3. **Component structure**: styling co-located correctly? Magic overrides masking structural problems?
4. **Responsive logic**: systematic or a pile of exceptions?
5. **Animation**: timing values hardcoded? Motion consistent with defined tokens?
6. **Custom vs. stock**: any stock components standing in where custom was intended?

---

## Audio Thread

Run this audit on any DSP or real-time audio code.

1. **Allocations**: any memory allocation on the audio thread, including implicit ones (containers resizing, string formatting, etc.)
2. **Blocking calls**: locks, mutexes, semaphores, file I/O, network calls, or anything that can block
3. **Objective-C messaging**: any ObjC dispatch on the audio thread
4. **Cross-thread communication**: anything other than lock-free ring buffers
5. **Buffer assumptions**: undocumented buffer size assumptions
6. **Load testing**: audio paths tested under load, not just in isolation

---

## Security

Run this audit on any auth, API, or data layer code.

1. **Key exposure**: service_role or secret keys reachable from the client
2. **RLS**: policies enforced via auth.uid()? Any bypass paths? Run EXPLAIN ANALYZE on complex policies.
3. **JWT**: Railway services verifying via Supabase public key?
4. **Input validation**: all external inputs validated before hitting the database or filesystem
5. **PII in logs**: any personally identifiable data in log output, including dev and debug paths
6. **Third-party SDKs**: any outbound network calls not documented in the codebase
7. **Entitlements**: Apple platform entitlements scoped to minimum required

---

## Rust

1. **unwrap()**: any unwrap() outside of clearly throwaway/test code
2. **Error types**: library errors using thiserror? Application errors using anyhow?
3. **Unnecessary clones**: clone() used to sidestep borrow checker friction instead of fixing ownership
4. **Unsafe blocks**: any unsafe without a safety comment explaining the invariants being upheld
5. **Manual index loops**: anywhere iterators would be cleaner and safer

---

## Design Files (Figma / Sketch)

Run this audit on any Figma or Sketch design file before handoff.

1. **Canvas background**: is the canvas dark (#1E1E1E)? A white canvas indicates setup was skipped.
2. **Empty pages**: any page in the file that exists but has no content is incomplete. Flag it.
3. **Token population**: are variable collections (Figma) or Color Variables + Tokens Studio (Sketch) fully populated? Primitives and semantic aliases both present? Light and dark mode values for every semantic token?
4. **Token naming vs code**: do Figma/Sketch token names match the names in the codebase? `color/semantic/background/primary` in Figma should correspond to the actual Swift/Kotlin/CSS token name. Drift here creates permanent design-to-code gaps.
5. **Component completeness**: are all atomic components present (Button, Input, Checkbox, Toggle, Badge, Chip, Avatar, Icon Button)? Are all states present for each (Default, Hover, Pressed, Disabled, Focus, Error)?
6. **Interactive components**: do all stateful components have prototype connections wired? A component set with variants but no prototype interactions is incomplete.
7. **Platform coverage**: is there a populated page for every platform the project targets? iOS-only projects don't need an Android page, but if an Android page exists it must have content.
8. **Screen completeness per platform**: does each platform page have the minimum screen set? Authentication flow, home/main (default + loading + empty + error states), detail view, settings/profile, navigation shell.
9. **Light and dark mode**: are screens visible in both modes? Toggle the variable mode on each screen frame and verify nothing breaks.
10. **Hardcoded values**: any layer with a hardcoded hex fill, hardcoded opacity, or hardcoded font size instead of a token reference.
11. **Detached instances**: any component instance that has been detached from its master. Detached instances don't update when the component changes.
12. **Missing accessibility annotations**: interactive elements with icon-only labels, missing contrast annotations, unlabeled form fields.

---

## Rust Toolchain

Run these tools, not just manual inspection.

1. **`cargo clippy -- -D warnings`**: treat all clippy warnings as errors. Fix everything it flags.
2. **`cargo audit`**: check all dependencies against the RustSec advisory database. Any `RUSTSEC` finding is a critical issue.
3. **`cargo deny check`**: if configured -- license compliance and dependency duplication.
4. **`cargo test`**: all tests passing. No `#[ignore]` without a documented reason.
5. **Dead code via clippy**: `#[allow(dead_code)]` annotations masking unused items without explanation.

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

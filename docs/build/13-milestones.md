# 13. Milestones

The task list. Each task has an id, a lane, its dependencies, the files it touches, the contract
documents it must obey, and the command that proves it is done. Tasks are written so an agent can
be handed one in isolation and start work.

Lanes: **D** data, **B** backend, **F** frontend, **T** transport, **A** Apple, **O** ops.

A task is done when its acceptance command exits zero. Not when the code looks right.

## Phase 0: foundations

Everything else depends on this phase. It is also the phase where a mistake is cheapest, so do not
rush it.

| Id | Lane | Task | Depends on |
| --- | --- | --- | --- |
| 0.1 | O | Repository, workspaces, CI skeleton | none |
| 0.2 | D | Migrations 0001 to 0011, applied locally | 0.1 |
| 0.3 | D | pgTAP suite for RLS, ceilings, and the download race | 0.2 |
| 0.4 | D | Storage buckets and policies | 0.2 |
| 0.5 | T | `packages/crypto`: envelope, manifest, link format, vectors | 0.1 |
| 0.6 | B | Railway skeleton: JWT verification, health, error format | 0.1 |
| 0.7 | F | Next.js skeleton: proxy, tokens, CSP, layout | 0.1 |
| 0.8 | O | Secret grep, preview isolation check, deploy pipeline | 0.1 |

### 0.1 Repository and CI

Create the pnpm workspace and Turborepo layout from [02-architecture.md](02-architecture.md).
Node 22, TypeScript 5.6, ESLint and Prettier in `packages/config`. CI runs lint, typecheck, and
build on every pull request. No Next.js app or API logic yet, just the shells.

**Done when** `pnpm install && pnpm lint && pnpm typecheck && pnpm build` exits zero from a clean
clone, and CI runs the same on a pull request.

### 0.2 Migrations

Write `supabase/migrations/0001` through `0011` exactly as specified in
[03-data-model.md](03-data-model.md). Forward only. No `down` files. Every table has RLS enabled
even when it has no policy.

**Done when** `supabase db reset` applies all migrations cleanly and
`supabase db diff` reports no drift.

### 0.3 pgTAP suite

Implement every test listed at the end of [03-data-model.md](03-data-model.md), including the
50-way concurrency test against `try_consume_download`.

**Done when** `pnpm test:db` exits zero and deliberately breaking any single RLS policy makes at
least one test fail. Prove the second half by actually breaking one and pasting the failure into
the pull request.

### 0.4 Storage buckets and policies

Create the `drops` and `drive` buckets and the policies from
[03-data-model.md](03-data-model.md). Include the `request_slot_open` function.

**Done when** `pnpm test:storage` exits zero, covering: owner can insert into their own uploading
drop, cannot insert into someone else's, cannot insert after seal, a request slot allows exactly
one object, and an expired slot is denied.

### 0.5 The crypto package

Implement [04-crypto-spec.md](04-crypto-spec.md) in `packages/crypto`: envelope encryption and
decryption as streams, manifest build and parse with path validation, the link fragment codec, the
password wrap, and the X25519 request-mode derivation. Write every vector in
`packages/crypto/vectors/`.

This is the highest-risk task in the project. Do not start it by writing the streaming layer;
start it by writing the vectors and the length identity check, then make them pass.

**Done when** `pnpm --filter crypto test` exits zero, every vector in the spec exists, a 10 GB
file encrypts and decrypts with peak heap under 200 MB in Chromium, and the hostile manifest
fixture is rejected on every entry.

### 0.6 Railway skeleton

Fastify, JWT verification against the project JWKS with `jose`, the RFC 9457 error format, request
logging that contains no slug or IP, graceful shutdown, `/healthz`, and `/readyz`. No business
endpoints yet.

**Done when** `pnpm --filter api test` exits zero, an expired token returns `401`, a token signed
by the wrong key returns `401`, `/readyz` returns `503` when Postgres is unreachable, and a log
sample from the test run contains no slug-shaped string.

### 0.7 Next.js skeleton

App Router, `proxy.ts` doing session refresh only, the CSP and security headers from
[08-web-app.md](08-web-app.md), the token layer generated from the Figma variable export, light
and dark, and empty routes for every path in the route map.

**Done when** `pnpm --filter web build` exits zero, a test asserts every security header is
present, and no route handler exists under `app/api/`.

### 0.8 Ops guardrails

The secret grep, the preview isolation check, and the deploy pipeline order from
[11-ops-runbook.md](11-ops-runbook.md).

**Done when** CI fails on a branch that adds `sb_secret_` to `apps/web`, and passes when it is
removed.

**Phase 0 exits when** a 10 GB file round-trips through `packages/crypto` with flat memory in
Chromium and Safari, and the pgTAP suite covers every RLS path.

## Phase 1: peer-to-peer send

Ships first because it has no storage, no retention, and no sweeper. Smallest trust surface,
hardest engineering.

| Id | Lane | Task | Depends on |
| --- | --- | --- | --- |
| 1.1 | B | `POST /v1/drops` with plan enforcement | 0.2, 0.6 |
| 1.2 | B | `POST /v1/drops/:slug/turn` | 1.1 |
| 1.3 | T | `packages/transport-p2p`: signaling and session setup | 0.5, 1.2 |
| 1.4 | T | Framing, backpressure, and the send loop | 1.3 |
| 1.5 | T | Resume and reconnect | 1.4 |
| 1.6 | T | Multi-recipient fan-out | 1.4 |
| 1.7 | F | Composer: drop zone, transport picker, expiry, cap | 0.7, 1.1 |
| 1.8 | F | Recipient page: p2p path, sender-offline state | 0.7, 1.3 |
| 1.9 | B | Session-expiry via Realtime presence webhook | 1.1 |

### 1.1 Create drop

Implement `POST /v1/drops` per [05-api-contract.md](05-api-contract.md). Plan resolution through
`current_plan`, ceiling checks against `plan_limits`, slug generation in the Crockford alphabet,
manage secret generation and hashing.

**Done when** the contract tests for this endpoint pass, including every `plan_ceiling_*` firing at
exactly the boundary, and the manage secret appearing in exactly one response and never again.

### 1.2 TURN minting

Call Cloudflare's `generate-ice-servers` with a six hour TTL. Check `relay_usage` against the plan.
Return `policy: 'relay'` unless the drop opted into direct.

**Done when** the endpoint returns an `iceServers` array containing a `turns:` entry on port 443,
an over-quota account gets `quota_exceeded`, and the Cloudflare token never appears in a response
or a log.

### 1.3 Signaling and session setup

Implement the signaling protocol from [06-transport-p2p.md](06-transport-p2p.md): the derived
topic, encrypted payloads, `hello`, `offer`, `answer`, `candidate`, `bye`, presence, and the
relay-only peer connection with candidate filtering.

**Done when** two headless Chromium contexts establish a connection, every local and remote
candidate is `typ relay`, and injecting a host candidate aborts the session.

### 1.4 Framing and the send loop

The 16 KiB frame format, the `bufferedamountlow` backpressure pattern, the control channel
messages, and acks every 4 MB.

**Done when** a 200 MB fixture round-trips byte-identically between two contexts and
`bufferedAmount` never exceeds the high-water mark plus one frame across a 1 GB send.

### 1.5 Resume

Offset tracking, the five second grace on `disconnected`, re-hello on `failed`, and the `resume`
control message.

**Done when** killing the data channel at 40 percent completes the transfer with byte equality,
and the test proves the sender seeked rather than restarted.

### 1.6 Fan-out

Per-recipient connections, windows, and progress. Cap from `plan_limits`.

**Done when** four recipients transfer concurrently, one throttled to 1 Mbps does not slow the
other three by more than 10 percent, and the ninth recipient on a free plan is refused with a
clear message.

### 1.7 Composer

Every state from [01-product-spec.md](01-product-spec.md), the transport picker with its honesty
line, presets and custom expiry, download cap, in light and dark, against the Figma design.

**Done when** the e2e anonymous send flow passes, axe reports no violations, and no hardcoded
color, spacing, radius, or duration exists in the diff.

### 1.8 Recipient page, peer-to-peer

The tree, subset selection, progress, the sender-offline state with its exact copy, and the
tombstone.

**Done when** the e2e peer-to-peer flow passes including closing and reopening the sender context,
and the offline state uses the exact string from the spec.

### 1.9 Session expiry

A Realtime presence webhook to Railway that ends a `session`-expiry drop when the sender leaves.

**Done when** closing the sender tab flips the drop to `ended` within 30 seconds, and the 24 hour
backstop still fires if the webhook never arrives.

**Phase 1 exits when** a 10 GB folder round-trips between two browsers on different networks with
neither IP visible to the other, verified by inspecting the ICE candidate list on both sides.

## Phase 2: cloud send

| Id | Lane | Task | Depends on |
| --- | --- | --- | --- |
| 2.1 | T | `packages/transport-cloud`: TUS upload pipeline | 0.5, 0.4 |
| 2.2 | B | `POST /v1/drops/:id/seal` with size verification | 1.1 |
| 2.3 | B | `authorize` and `download` with signed URLs | 2.2 |
| 2.4 | T | Download pipeline and the three sinks | 2.3 |
| 2.5 | B | Sweeper and the `/internal/sweep` endpoint | 2.2 |
| 2.6 | F | Composer cloud path, unsealed recipient state | 1.7, 2.1 |
| 2.7 | F | Password gate, both ends | 2.3 |

### 2.1 TUS upload

The pipeline from [07-transport-cloud.md](07-transport-cloud.md). Exactly 6 MB chunks, the
dedicated storage hostname, `removeFingerprintOnSuccess`, `application/octet-stream` always, three
files in flight.

**Done when** a 2 GB fixture uploads, a connection killed at 30 percent resumes without
re-uploading completed chunks, and a second upload of the same file in the same browser actually
re-uploads.

### 2.2 Seal

Commit the manifest, verify every object's size against the client's claim by listing the prefix,
reject on mismatch.

**Done when** a client that under-reports a size gets `409`, and a correct seal flips the drop to
`sealed` and populates `size_bytes` rounded.

### 2.3 Authorize and download

The recipient token, constant-time password comparison, `try_consume_download`, the event, and the
60 second signed URL, in that order.

**Done when** the contract tests pass, a token for drop A cannot download from drop B, and 50
concurrent downloads against a cap of 10 yield exactly 10 successes.

### 2.4 Download pipeline

Header verification, segment decryption, BLAKE3 check, `Range` resume on a segment boundary, and
all three sinks with feature detection.

**Done when** each sink is forced individually and produces byte-identical output, and a download
aborted at 50 percent resumes correctly.

### 2.5 Sweeper

`expire_due_drops`, object deletion in batches, `drop_files` cleanup, `rate_buckets` pruning, and
the cron wiring.

**Done when** a drop expired in the past has its objects gone within one interval, its row remains
as a tombstone with a null manifest, and the sweep is idempotent when run twice concurrently.

### 2.6 Composer cloud path

The link before the upload completes, the unsealed recipient state, upload progress with resume.

**Done when** the e2e cloud flow passes and the recipient page shows the exact "still uploading"
string before seal.

### 2.7 Password gate

Generation, argon2id in a worker, the wrap, the verifier, and the recipient-side gate with rate
limiting.

**Done when** the e2e password flow passes, a wrong password shows the exact string, the eleventh
attempt in an hour returns `429`, and the server never receives the password or the wrapping key.

**Phase 2 exits when** the same 10 GB folder round-trips over cloud on a deliberately flaky
connection and expired drops are provably gone within 15 minutes.

## Phase 3: management, accounts, request mode

| Id | Lane | Task | Depends on |
| --- | --- | --- | --- |
| 3.1 | B | `PATCH` and `DELETE` on drops, manage-secret auth | 2.2 |
| 3.2 | F | Management page for anonymous senders | 3.1 |
| 3.3 | F | Dashboard with live counts over Realtime | 3.1 |
| 3.4 | F | Sign-in, anonymous upgrade, account deletion | 0.7 |
| 3.5 | B | Request mode: slots, completion, per-uploader manifests | 2.2 |
| 3.6 | F | Request mode UI, both ends | 3.5 |
| 3.7 | F | Direct-connection opt-in with its warning | 1.3 |
| 3.8 | B | Abuse reports and the operator review queue | 3.1 |

### 3.4 Accounts

Anonymous sessions everywhere. Upgrade goes through email first, then optionally a passkey,
because Supabase does not allow an anonymous user to register a passkey directly. Account deletion
deletes the `auth.users` row, which cascades, and purges both buckets.

**Done when** an anonymous user's drops survive the upgrade with no merge step, and the deletion
test proves every row and object is gone.

### 3.8 Abuse

`POST /v1/reports` with no reporter identity, the optional key with explicit consent copy, the
operator-only queue with 30 day retention, and the two-person review requirement in the runbook.

**Done when** a report with no key writes a row, a report with a key writes to the separate queue,
and neither writes anything that identifies the reporter.

**Phase 3 exits when** signed-in and anonymous senders can manage and kill drops on both
transports, and account deletion is complete and tested.

## Phase 4: Apple apps

Independent of phase 5; either can go first.

| Id | Lane | Task | Depends on |
| --- | --- | --- | --- |
| 4.1 | A | `DropKit`: crypto port, passes the shared vectors | 0.5 |
| 4.2 | A | `DropKit`: API client and TUS over background URLSession | 4.1, 2.3 |
| 4.3 | A | iOS app: send, drops, receive, settings | 4.2 |
| 4.4 | A | iOS share extension | 4.3 |
| 4.5 | A | macOS app: window, sidebar, detail | 4.2 |
| 4.6 | A | macOS menu bar via NSStatusItem with drag target | 4.5 |
| 4.7 | A | macOS share extension | 4.5 |
| 4.8 | A | StoreKit purchase and entitlement parity | 5.1 |
| 4.9 | O | Export compliance filing | none, start early |

### 4.9 Export compliance

Start this in phase 0, not phase 4. It is the longest-lead item in the project. File the non-exempt
encryption documentation with App Store Connect, get the
`ITSEncryptionExportComplianceCode`, and determine whether a BIS CCATS classification is needed.

**Done when** the code is in `Info.plist` and a TestFlight external build distributes without an
encryption hold.

**Phase 4 exits when** a file can be dropped from Finder or the iOS share sheet and shared without
opening a browser, and a 10 GB upload survives backgrounding, a network change, and an app
relaunch.

## Phase 5: paid plan and drive

| Id | Lane | Task | Depends on |
| --- | --- | --- | --- |
| 5.1 | B | Stripe checkout, portal, and the Edge Function webhook | 0.6 |
| 5.2 | B | Entitlement enforcement across every ceiling | 5.1 |
| 5.3 | T | Drive key hierarchy, recovery key, PRF wrap | 0.5 |
| 5.4 | B | Drive endpoints and quota | 5.2 |
| 5.5 | F | Drive browser, activation flow, unlock | 5.3, 5.4 |
| 5.6 | F | Share from drive without re-upload | 5.4 |
| 5.7 | O | Relay reconciliation against Cloudflare metering | 1.2 |

### 5.3 Drive keys

The root key, the mandatory recovery key shown once, the argon2id password wrap, and the PRF wrap
with a throwaway assertion at enrollment to confirm the authenticator actually returns PRF output.

**Done when** all three unwrap paths work, PRF failure falls back rather than losing data, and the
activation flow refuses to allow an upload until the recovery key is confirmed saved.

### 5.6 Share from drive

Create a drop whose `drop_files` point at existing `drive` bucket objects, with the manifest
repeating the existing content keys.

**Done when** sharing a 5 GB drive file uploads zero bytes, the recipient downloads it correctly,
and revoking the drop leaves the drive node untouched.

**Phase 5 exits when** a paying user keeps a file permanently, shares it with a one year link,
revokes it, and the drive copy is intact.

## Critical path

```
 0.1 ─▶ 0.2 ─▶ 0.3
   │      └──▶ 0.4 ──────────────┐
   ├──▶ 0.5 ─────────────┐       │
   ├──▶ 0.6 ─▶ 1.1 ─▶ 1.2 ┼─▶ 1.3 ─▶ 1.4 ─▶ 1.5 ─▶ [phase 1 exit]
   └──▶ 0.7 ─▶ 1.7        │       │
                          └─▶ 2.1 ┴─▶ 2.2 ─▶ 2.3 ─▶ 2.4 ─▶ [phase 2 exit]

 0.5 ─▶ 4.1 ─▶ 4.2 ─▶ 4.3 ...        runs in parallel from phase 2 onward
 0.6 ─▶ 5.1 ─▶ 5.2 ─▶ 5.4 ...        runs in parallel from phase 3 onward
 4.9 export compliance               starts at phase 0, finishes whenever BIS finishes
```

`packages/crypto` (0.5) is the true critical path. Everything that matters depends on it and it is
the task where a mistake is most expensive to discover late. Give it to whoever is best, do it
first, and review it twice.

## What would make this plan wrong

Stated so the assumptions are visible.

- **Relay cost.** If peer-to-peer usage is high, Cloudflare egress dominates and the free tier's
  relay quota has to shrink or the transport has to fall back to direct more often. This is the
  most likely reason a plan number changes.
- **Data channel throughput.** If relayed transfers settle well below 50 Mbps in practice, the
  peer-to-peer transport becomes a niche feature rather than a headline one, and the ordering of
  phases 1 and 2 should have been reversed.
- **Guideline 1.2.** If App Review reads the report-and-block implementation as insufficient for a
  zero-knowledge product, the Apple apps need a different content posture, and that changes phase 4
  more than any technical risk here.
- **Export compliance.** If CCATS is required and slow, the Apple apps ship late regardless of
  engineering progress.

# Quick file sharing app: product and architecture brief

Status: brainstorm, v0.2 (September 2026). Nothing here is built yet.

## Thesis

One drop, one link. The product is not a drive. There is no folder tree to maintain, no sync client, no "my files" that grows forever. Every interaction starts with a file or folder on the sender's machine and ends with a link that dies on its own.

Dropbox and OneDrive optimize for *keeping*. WeTransfer, Smash, Wormhole, and SwissTransfer optimize for *sending*, but each gives up something: folder structure gets flattened into a zip, encryption is either absent or all-or-nothing, expiry is a footnote, and revocation usually needs a paid plan. This app treats the send itself as the whole product and gets the four things they compromise on right.

Security and anonymity are the product, not features of it. The sender chooses one of two transports per drop, **peer-to-peer** or **cloud**, and the app is honest about exactly what each one hides and from whom. The threat model below is the contract; every design decision in this document traces back to a row in it.

## What makes it different

1. **Folder-native.** Drag a folder in and the recipient sees the folder, browsable, with per-file download or a one-click bundle. Structure survives. Nobody zips first.
2. **Expiry and revocation are the default, not a setting.** Every drop has a lifetime (default 7 days) and a kill switch. The sender sees views and downloads as they happen and can end the drop with one tap.
3. **End-to-end encryption always.** Every drop, on either transport, is encrypted in the browser with a key that lives only in the URL fragment. No server ever sees plaintext bytes or filenames. There is no unencrypted mode. Server-side previews, scanning, and bundling are simply not offered; the client does what the server can't see.
4. **Two transports, chosen per drop.** *Peer-to-peer* never stores bytes anywhere: the file streams from the sender's browser to the recipient's while both tabs are open, relayed so neither side learns the other's IP. *Cloud* stores ciphertext for a bounded lifetime so the recipient can collect it later. Same link format, same encryption, same expiry rules.
5. **No account to receive. Optional account to manage.** Recipients never sign up. Senders can share anonymously; signing in later claims the drops they already made.
6. **Resumable on both transports.** Multi-gigabyte drops resume after a dropped connection whether streaming peer-to-peer or uploading to cloud. Bytes never pass through the web server.
7. **Request mode.** A reverse link where other people upload into a drop that only the requester can open. Same expiry and encryption rules.

Deliberately out of scope: sync clients, file editing, comments, version history, team folders, and anything that turns this into a drive.

## Primary flows

### Sender

```
┌──────────────────────────────────────────────────────┐
│  Drop files or a folder here                          │
│  ┌──────────────────────────────────────────────┐    │
│  │            ⬇  drag, paste, or browse          │    │
│  └──────────────────────────────────────────────┘    │
│  Transport  (●) Peer-to-peer   ( ) Cloud              │
│             sender stays online · nothing stored      │
│  Expires   [while tab open ▾]  Downloads  [1 ▾]      │
│  Password  [off]                                      │
│                                                       │
│  ▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░  2.1 GB of 3.4 GB  resumable   │
│                                                       │
│  https://…/d/8kq2ma      [Copy link]  [QR]  [Email]   │
└──────────────────────────────────────────────────────┘
```

In cloud mode the link exists before the upload finishes and the recipient page shows "still uploading" until the manifest is sealed. In peer-to-peer mode the link is live immediately and the sender's page shows who is connected (as an anonymous session, never an IP) and transfer progress per recipient.

### Recipient

```
┌──────────────────────────────────────────────────────┐
│  Q3 brand assets                    expires in 6 days │
│  peer-to-peer · 3.4 GB · 42 files · sender unnamed     │
│ ┌────────────────────────────────────────────────────┐│
│ │ ▸ logos/                    12 files      18 MB    ││
│ │ ▸ photography/              24 files     3.2 GB    ││
│ │   guidelines.pdf                          4 MB     ││
│ │   README.md                               2 KB     ││
│ └────────────────────────────────────────────────────┘│
│                     [Download all]  [Download selected]│
└──────────────────────────────────────────────────────┘
```

No login, no app install, no "sign up to download". Password-protected drops show a single password field first. Every drop decrypts in the browser and streams straight to disk. A peer-to-peer drop whose sender has gone offline shows "the sender isn't here right now" rather than an error, and reconnects on its own when they return.

### Sender dashboard (signed-in only)

A flat list of drops, newest first: title, size, expiry countdown, views, downloads, and a revoke button. That is the entire management surface.

## Architecture

Follows the repo lane rules, with one documented exception (the TURN relay, explained under Transports). Each service has one job.

```
 sender browser ◀──WebRTC, relay-only──▶ Cloudflare TURN ◀──▶ recipient browser
    │  ▲                                                          ▲  │
    │  └────── signaling: Supabase Realtime Broadcast ────────────┘  │
    │                                                                │
    ├──TUS ciphertext──▶ Supabase Storage (private bucket) ◀─signed URL─┤
    │                            ▲                                   │
    │ anon key + RLS             │ service_role                      │
    ▼                            │                                   ▼
 Vercel / Next.js 16 ──JWT──▶ Railway API ◀──────────────────── Vercel
                                 ├── download authorization
                                 ├── TURN credential minting
                                 ├── expiry sweeper (cron)
                                 └── rate limiting / revoke-on-report
                                 │
                       Supabase Postgres + Auth
```

### Vercel (Next.js 16, App Router)

Landing, sender UI, recipient page, dashboard. Anon key only, RLS enforced. Server Components by default; the upload widget and the decryption path are Client Components at the leaves. Vercel is never in the byte path for uploads or downloads.

### Supabase

- **Auth.** Anonymous sign-in for senders who do not want an account. This gives every sender a real `auth.uid()` so RLS works for anonymous drops without any special casing. Magic link or passkey later converts the anonymous user and keeps their drops. `@supabase/ssr` for cookie sessions.
- **Postgres.** Source of truth for drops, files, and access events. RLS on every table.
- **Storage.** One private bucket. Uploads go browser to Storage directly over TUS (resumable, 6 MB chunks). Object paths are `{drop_id}/{file_id}`; a storage policy allows inserts only where the drop is owned by `auth.uid()` and still in `uploading` state. Downloads use short-lived signed URLs minted by Railway. Storage caps: 50 MB per file on the free plan, configurable up to 500 GB on Pro, 50 GB per file over resumable uploads.
- **Realtime.** Sender dashboard subscribes to its own drops' event rows for live view and download counts. Low frequency, fits the WAL model.
- **Edge Functions.** A DB trigger side effect when a drop is sealed or revoked (notify the sender's open dashboard, schedule the sweep). Nothing heavy.

### Railway (TypeScript/Node, or Rust if the bundler gets hot)

Verifies Supabase JWTs against the project JWKS. Holds `service_role`. Four responsibilities:

1. **Download authorization.** `POST /drops/:slug/download` checks status, expiry, download cap, and the password verifier (constant-time), records the event, and returns a 60 second signed URL for ciphertext.
2. **TURN credentials.** `POST /drops/:slug/turn` mints short-TTL Cloudflare TURN credentials scoped to one P2P session, so the long-term TURN key never leaves Railway.
3. **Expiry sweeper.** Railway cron, every 15 minutes: mark expired drops, delete their objects, keep a tombstone row so the link returns a clean "this drop has ended" instead of a 404.
4. **Rate limiting and abuse.** Fingerprint-based limits with daily key rotation, and the revoke-on-report path. There is no scanning or thumbnail job because Railway only ever sees ciphertext; folder bundling happens client-side for the same reason.

### Data model (first cut)

```
drops           id, owner_id, slug, transport (p2p|cloud), kind (file|folder),
                mode (send|request), status (open|uploading|sealed|revoked|expired),
                allow_direct bool (p2p only),
                expires_at, max_downloads, download_count, password_hash,
                size_bytes (rounded), file_count, created_at, sealed_at
drop_files      id, drop_id, storage_key (cloud only), size_bytes (rounded),
                encrypted_meta (bytea: name, path, mime, exact size, tree hash)
drop_events     id, drop_id, kind (view|download|revoke|expire), created_at,
                country (coarse, optional)
```

No IP addresses, no user agents, no per-recipient identity anywhere. The privacy rules in CLAUDE.md apply to the event log too: counts and coarse geography only.

### Recipient reads without an account

Recipients hit the drop page with no session. Instead of opening the `drops` table to `anon` selects, a `security definer` function `get_public_drop(slug)` returns only the public projection (transport, rounded size, file count, encrypted manifest, expiry, whether a password is required) and only when the drop is sealed and unexpired. RLS stays closed on the base tables.

### Encryption (both transports)

- Sender's browser generates a 256-bit AES-GCM key, encrypts each file as a stream with per-chunk nonces, and encrypts a manifest (filenames, paths, mimes, sizes rounded to the nearest 64 KB so exact sizes leak less). The key goes in the URL fragment, which browsers never send to the server.
- Recipient's browser decrypts through a `TransformStream` and writes to disk with the File System Access API where available (Chromium), falling back to a service-worker-mediated streaming download elsewhere. Memory stays flat regardless of file size.
- Password protection layers on top: the password derives a second key (argon2id in a worker) that wraps the fragment key, so the server holds a verifier only and a password is never compared server-side in plaintext.
- Optional out-of-band key delivery: the sender can strip the key from the link and show it separately as a short word sequence, so the link and the key travel through different channels.
- Integrity: each chunk carries its GCM tag; the manifest carries a BLAKE3 tree hash per file so a truncated or tampered transfer fails loudly.

## Transports

The two modes share the link format, encryption, expiry, password, and UI. They differ only in where ciphertext lives and who has to be online.

| | Peer-to-peer | Cloud |
| --- | --- | --- |
| Bytes stored anywhere | No | Ciphertext in Supabase Storage until expiry |
| Sender must stay online | Yes, until every recipient finishes | Only until upload completes |
| Size ceiling | None in principle; practical ceiling is session length | 50 GB per file (Supabase resumable limit) |
| Speed | Bounded by the slower peer and the relay | Upload once, download at Storage speed |
| Recipient's IP visible to sender | No (relayed by default) | No |
| Sender's IP visible to recipient | No (relayed by default) | No |
| Works over Tor Browser | No (WebRTC is disabled there) | Yes |
| Default expiry | When the sender closes the tab | 7 days |
| Default download cap | 1 | Unlimited |

### Peer-to-peer

Transport is WebRTC data channels. Signaling runs over Supabase Realtime Broadcast on a private channel named by a hash of the drop slug; the channel carries only encrypted SDP and ICE blobs, so Supabase sees that two anonymous sessions rendezvoused and nothing else. Browser-to-Supabase direct fits the lane rules and costs nothing extra.

**Relay by default.** ICE is pinned to `iceTransportPolicy: "relay"`, so no host or server-reflexive candidates are ever generated and neither peer learns the other's IP. The relay is Cloudflare's TURN service with short-TTL credentials minted by Railway per drop. This is a deliberate deviation from the three-lane stack: Railway cannot host a TURN server because it has no inbound UDP, and a TURN relay is the only mechanism that hides peer IPs from each other in WebRTC. Cost is 1 TB free then $0.05 per GB relayed; the sender's page shows this budget honestly if the project ever meters it.

**Direct as explicit opt-in.** A per-drop "allow direct connection" switch drops the relay pin for faster LAN and same-network transfers. The switch is off by default, labeled with what it reveals, and the recipient sees the same label before accepting.

**Throughput reality.** SCTP over DTLS was tuned for calls, not bulk transfer, and a data channel that could push 500 Mbps direct often settles around 50 to 100 Mbps. Mitigations: 16 KB messages with `bufferedAmountLowThreshold` backpressure, multiple parallel data channels per file, and a per-recipient chunk window so a slow recipient doesn't stall a fast one. WebTransport is client-to-server only and is not a P2P option; it is the right upgrade path for the cloud transport if Storage's TUS path ever becomes the bottleneck, not for this mode.

**Multi-recipient.** The sender fans out; each recipient gets its own connection and its own progress. A cap of 8 simultaneous recipients keeps the sender's upstream sane and is shown in the UI.

**Resumability.** A dropped connection resumes from the last acknowledged chunk index; both sides keep a small window of chunk hashes so a resume verifies before it continues.

### Cloud

Exactly the Supabase Storage path described above: TUS resumable upload of ciphertext direct from the browser, Railway mints short-lived signed download URLs after checking status, expiry, cap, and password verifier. Because bytes are always ciphertext, Storage, Railway, and Vercel are all untrusted for confidentiality; they are trusted only for availability and for enforcing expiry and caps.

## Threat model

What each party can learn, and what the app promises about it. "Sees" means the party is in a position to observe it; "records" means the app writes it down. The gap between the two is the honest part.

| Party | Can see | App records | Cannot learn |
| --- | --- | --- | --- |
| Recipient | Plaintext, file names, drop title, that a sender exists | | Sender's IP (relayed P2P, cloud), sender's identity, sender's other drops |
| Sender | Number of recipients, progress per recipient | | Recipient IPs (relayed P2P, cloud), recipient identity |
| App operators (Vercel, Railway, Supabase) | Ciphertext sizes, file count, timing, drop lifetime, request IPs at the infrastructure layer | Drop rows, rounded sizes, counts, event kinds, coarse country | Plaintext, file names, passwords, the key |
| Cloudflare TURN | Relayed ciphertext volume, both peers' IPs | | Plaintext, file names, which drop a relay session belongs to |
| Someone with only the link | Whether the drop still exists | | Anything without the fragment key |
| Someone with link + key | Everything the recipient can | | Who else downloaded |

**Promises the app makes.** No plaintext leaves the browser. No account is required to send or receive. No IP address, user agent, or per-recipient identity is ever written to the database or application logs. Keys never touch a server. Expired data is deleted, not retained.

**Promises the app does not make, said out loud in the UI.** Infrastructure providers can see connection metadata at the network layer; the app cannot prevent that and does not claim to. A recipient can keep and re-share what they decrypt. A password does not protect against a recipient who already has the key. Peer-to-peer mode does not work under Tor Browser and is not recommended when the user's own network is the concern; cloud mode over Tor is.

**Anonymity defaults.** Anonymous Supabase sessions are the norm; accounts are the exception. Sender and recipient are given random per-drop session identifiers, never stable ones. The dashboard for a signed-in sender shows counts, never who. Analytics and telemetry are absent by design, per the repo's privacy rules, and there is no opt-in because there is nothing to opt into.

**Abuse handling without surveillance.** Rate limits are keyed by hashed, salted, daily-rotating request fingerprints on Railway that are discarded at rotation. Reports come through the drop link, not through identification of the sender; a reported drop is revoked, not inspected, since inspection is impossible.

## Phasing

| Phase | Scope | Exit criteria |
| --- | --- | --- |
| 0 | Threat model signed off, Figma design (sender, recipient, dashboard, light and dark), schema and RLS written and tested, streaming encrypt/decrypt library with tests | RLS, JWT, and crypto paths have tests; a 10 GB file encrypts and decrypts with flat memory in Chromium and Safari |
| 1 | Peer-to-peer send: file or folder, relay-only WebRTC, Realtime signaling, resume, multi-recipient | A 10 GB folder round-trips between two browsers on different networks with neither IP visible to the other |
| 2 | Cloud send: TUS ciphertext upload, signed download, expiry, sweeper, password | Same folder round-trips over cloud on a flaky connection; expired drops are gone |
| 3 | Accounts, dashboard, revoke, download caps, Realtime counts, request mode, direct-connection opt-in | Signed-in sender can manage and kill drops on both transports |
| 4 | Apple share extension and menu bar app (SwiftUI, iOS/macOS 26) | Drop from Finder or the share sheet without opening a browser |

P2P ships before cloud because it has no storage, no retention, and no sweeper: it is the smaller trust surface and the harder engineering, so it validates the crypto and UX first.

## Parallel workstreams for the build

Four lanes that can run concurrently once Phase 0 design is done:

- **Data lane.** Supabase migrations, RLS policies, storage policies, `get_public_drop`, pgTAP tests for the auth and RLS paths.
- **Backend lane.** Railway service: JWT verification, download authorization, bundler, sweeper, queue consumer, health check and graceful shutdown per `backend-conventions`.
- **Frontend lane.** Next.js app against the Figma design: upload widget with TUS, recipient page, dashboard.
- **Transport lane.** Isolated TypeScript packages with no UI: streaming crypto, WebRTC session (signaling, relay pin, resume, fan-out), TUS client wrapper. Each has deterministic tests and a headless two-browser integration test.

Contracts between lanes (table shapes, the Railway API surface, storage key layout) are fixed in this document before the lanes split.

## Open decisions

1. **Relay provider.** Cloudflare TURN (recommended: managed, cheap, TLS on 443 for hostile networks) versus self-hosting coturn on a VPS outside the three lanes. Either way this is one service beyond Vercel, Railway, and Supabase, and it needs to be an explicit exception in the lane rules.
2. **Where the code lives.** Assumed: a new repository, not this skills repo.
3. **Name.** Not chosen. Candidates should be short, verb-like, and not collide with the incumbents.
4. **Visual direction.** Default is the web platform's own conventions per CLAUDE.md. If a `visual-styles` style is wanted, it needs to be named before Figma work starts.

## Sources

- Supabase Storage resumable uploads and limits: https://supabase.com/docs/guides/storage/uploads/resumable-uploads and https://supabase.com/docs/guides/storage/uploads/file-limits
- Supabase Storage v3 (50 GB resumable): https://supabase.com/blog/storage-v3-resumable-uploads
- Next.js 16 LTS status: https://nextjs.org/support-policy
- Streaming client-side decryption pattern: https://transcend.io/blog/open-sourcing-penumbra
- WebRTC data channel throughput limits: https://handrive.ai/blog/webrtc-not-built-for-file-transfer
- Relay-only ICE to prevent IP exposure: https://blog.send.win/webrtc-leak-prevention-methods-complete-guide-2026/
- Cloudflare TURN credentials and pricing: https://developers.cloudflare.com/realtime/turn/
- Railway inbound UDP limitation: https://station.railway.com/questions/adding-inbound-udp-fad19847
- Supabase Realtime Broadcast authorization: https://supabase.com/blog/supabase-realtime-broadcast-and-presence-authorization
- Competitive landscape: https://blog.bytesizedsecurity.show/2026/07/09/wetransfer-alternatives-2026-privacy-first/

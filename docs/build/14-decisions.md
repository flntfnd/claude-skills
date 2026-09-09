# 14. Decisions

Two lists. Decisions already made, with the reasoning, so nobody relitigates them by accident. Open
decisions, with a recommendation, so nobody blocks on them silently.

Format for a new entry: what was decided, what it costs, and what would reverse it.

## Decided

### D-1. Peer-to-peer ships before cloud

**Decision.** Build the peer-to-peer transport first.

**Why.** It has no storage, no retention, and no sweeper, so it is the smaller trust surface. It is
also the harder engineering, so building it first validates the crypto and the interaction model
while they are still cheap to change.

**Cost.** The easier, more broadly compatible transport ships second, so the first usable build
does not work in Safari as well as it eventually will.

**Reverses if.** Relayed data channel throughput measures below roughly 50 Mbps in real
conditions, which would make peer-to-peer a niche feature rather than a headline one.

### D-2. Cloudflare TURN, and it is an explicit exception to the lane rules

**Decision.** Use Cloudflare's managed TURN service. Railway mints short-lived credentials.

**Why.** WebRTC cannot hide peer IP addresses from each other without a relay. Railway has no
inbound UDP so it cannot host one. Self-hosting coturn on a VPS would add a fourth service to
operate, patch, and scale, for the same result at higher cost and effort.

**Cost.** One service outside the three lanes. Cloudflare sees both peers' addresses and the
relayed volume, which the threat model states. Every relayed byte is billed at $0.05 per GB above
one terabyte a month, which is the dominant variable cost of the product.

**Reverses if.** Relay spend outgrows the price of operating coturn, or a requirement appears that
Cloudflare cannot meet, such as IPv6 relay addresses.

### D-3. No Merkle tree over file chunks

**Decision.** Drop the BLAKE3 tree hashes the brief proposed. Keep one BLAKE3 hash of the whole
plaintext in the manifest.

**Why.** Every segment already carries a GCM tag under a key the server does not hold, so a
modified, reordered, or truncated segment fails during decryption. That is the property the tree
would have provided. Resume works on acknowledged ciphertext offsets, which needs no tree.

**Cost.** A resume cannot verify a partially written file without reading it. In practice the next
segment's tag catches a bad resume immediately, so this costs nothing real.

**Reverses if.** A future feature needs to verify an arbitrary byte range without possessing the
key, such as third-party mirroring.

### D-4. `cacheComponents` stays off in Next.js 16

**Decision.** Do not enable `cacheComponents`.

**Why.** Almost nothing in this app is cacheable. Drops are private, time sensitive, and often
single use, and the recipient page must be request-time fresh or the countdown lies. Enabling it
would remove `dynamic` and `revalidate` from the codebase and force every uncached read into a
`Suspense` boundary for no benefit.

**Cost.** The four static pages, landing, pricing, privacy, and errors, do not get partial
prerendering. They are static without it anyway.

**Reverses if.** A marketing surface grows large enough that its caching story matters.

### D-5. Two storage buckets, not one

**Decision.** `drops` and `drive`, rather than the single bucket the brief proposed.

**Why.** The policies are completely different: `drops` objects are written once by an owner during
a bounded upload window or by a pre-authorized stranger, and are never read with a user token.
`drive` objects are read and written by their owner for as long as the account exists. One bucket
would mean one policy set expressing both, which is longer and easier to get wrong.

**Cost.** Two key layouts to remember. They are documented in
[02-architecture.md](02-architecture.md) and nothing else writes to either bucket.

### D-6. Permissive Realtime authorization for signaling

**Decision.** The RLS policies on `realtime.messages` allow any authenticated user to read and
write broadcast messages, rather than restricting each topic to the parties of one drop.

**Why.** A per-drop policy would require a table mapping topics to drops that `anon` can read,
which leaks the existence and identity of drops to anyone who can query it. The topic is derived
from a 50-bit slug that only link holders know, and every payload on it is encrypted with a key
derived from the drop key. Supabase sees opaque blobs on an unguessable topic either way.

**Cost.** Someone who guesses a topic can inject noise into a signaling channel. They cannot read
anything, and the session simply fails to establish, which is a denial of service against a single
drop that they would have to guess first.

**Reverses if.** Supabase adds a way to authorize a topic against a secret without exposing a
lookup table.

### D-7. The download cap counts authorizations, not completions

**Decision.** `try_consume_download` increments when a signed URL is issued.

**Why.** A completion cannot be observed honestly. The client reports it, and a client that lies
would get unlimited downloads from a cap of one.

**Cost.** A download that fails at the network layer still consumes one from the cap. The UI says
"times the file was handed out" rather than "downloads" so this is not a surprise.

### D-8. Peer-to-peer is not in the first Apple release

**Decision.** The iOS and macOS apps do cloud only in v1.

**Why.** WebRTC on Apple platforms means adding a large third-party framework and reimplementing
the entire session protocol in a second language. The transport's value is highest in the browser,
where there is nothing to install. An Apple user who needs peer-to-peer opens the web app.

**Cost.** A real feature gap between platforms, which the app has to state rather than hide.

**Reverses if.** Apple usage concentrates on cases where nothing should be stored, or a maintained
Swift WebRTC package makes the port cheap.

### D-9. macOS uses a custom `NSStatusItem`, not `MenuBarExtra`

**Decision.** Build the menu bar item with AppKit and host SwiftUI inside it.

**Why.** `MenuBarExtra` does not support dropping files onto the status item at all, and
drag-to-share is the feature. Its `.window` style also cannot be dismissed programmatically and
does not report open and close reliably.

**Cost.** More code, and an `NSApplicationDelegateAdaptor` in an otherwise pure SwiftUI app.

**Reverses if.** SwiftUI gains a drop target on the status item.

### D-10. Finder integration is a Share Extension, not Finder Sync

**Decision.** Ship a macOS Share Extension.

**Why.** Finder Sync is designed for sync-status badging on a directory tree the app claims. Using
it for a global share action is off-label, it requires the user to enable it in Login Items and
Extensions, and it has been failing to load on Apple silicon across several macOS 26 point
releases. The Share Extension reaches the Finder share submenu and the system share sheet with one
target and reuses the iOS item-provider code.

**Cost.** No sync badges. Nothing in v1 needs them.

### D-11. Backups exclude storage objects

**Decision.** Postgres has point-in-time recovery. Storage objects have no backup.

**Why.** Drop objects are ciphertext with a scheduled death. Backing them up would be keeping a
copy of data the product promised to delete.

**Cost.** The drive, which a paying customer reasonably expects to be durable, is not backed up in
v1. The activation flow says so alongside the recovery key warning.

**Reverses if.** The drive ships to real paying customers, at which point durability is a scoped
project and this entry gets superseded.

### D-12. Supabase's new key names from day one

**Decision.** Use `sb_publishable_` and `sb_secret_` rather than `anon` and `service_role`.

**Why.** The JWT-style keys are deprecated at the end of 2026. Starting on the new names avoids a
migration during the build.

**Cost.** Older tutorials and examples will not match the code.

## Open

Each of these has a recommendation. None blocks phase 0.

### O-1. Where the code lives

**Question.** A new repository, or this one.

**Recommendation.** A new repository. This one is a skills repository and the product is not a
skill. Move `docs/file-sharing-*.md` and `docs/build/` across when it is created.

**Needed by.** Task 0.1, which is the first thing anyone does.

### O-2. The name

**Question.** Not chosen.

**Recommendation.** Short, verb-like, no collision with the incumbents. Pick it before the
composer's copy is written, because "drop" is already load bearing in the glossary and a name that
fights it will cost a rewrite.

**Needed by.** Phase 1's UI copy.

### O-3. Plan numbers

**Question.** The ceilings in `plan_limits` are opening proposals, not modeled prices.

**Recommendation.** Model Cloudflare relay egress and Supabase storage against a price point
before launch. The relay quota is the number most likely to be wrong: at $0.05 per GB above one
free terabyte across the whole account, a free tier of 100 GB per user is only viable while the
user count is small.

**Needed by.** Before the pricing page goes live, not before the code is written, because the
numbers are data.

### O-4. Privacy-preserving payment

**Question.** Whether to offer a path that keeps identity away from Stripe, such as prepaid codes
or a crypto processor.

**Recommendation.** Not at launch. The honest copy about what Stripe learns is enough for v1, and
the free tier is fully featured and fully anonymous. Revisit if paying users ask for it.

### O-5. Drive durability

**Question.** The drive has no backup, which conflicts with what a paying customer expects.

**Recommendation.** Ship phase 5 with the warning, then treat durability as the next project. The
options are cross-region object replication, or an export tool that lets the user hold their own
backup, and the second is more in keeping with the product.

**Needed by.** Before the drive is marketed as permanent storage rather than persistent storage.

### O-6. WebTransport for the cloud transport

**Question.** Whether to replace TUS over HTTP/1.1 with WebTransport over HTTP/3.

**Recommendation.** No, and not soon. Supabase Storage does not speak it, and putting a
WebTransport endpoint on Railway would put file bytes through a service that currently never sees
them. Revisit only if Storage throughput becomes the measured constraint.

### O-7. Post-quantum key agreement in request mode

**Question.** Request mode uses X25519, which is classical.

**Recommendation.** Not now. When it matters, the migration is `XWingMLKEM768X25519`, which is
already in CryptoKit on the 26 platforms, and it needs a version bump in
[04-crypto-spec.md](04-crypto-spec.md). Nothing in the format prevents it; that is why the version
byte exists.

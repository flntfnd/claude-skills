# 02. Architecture

Four services, one job each, plus one documented exception. This document fixes the boundaries.
If a change blurs them, it needs an entry in [14-decisions.md](14-decisions.md) first.

## The shape

```
              ┌──────────────────────────────────────────────┐
              │              sender browser                   │
              │  crypto worker · TUS client · WebRTC session  │
              └───┬───────────────┬──────────────────┬───────┘
                  │               │                  │
   share link     │               │ ciphertext       │ encrypted SDP/ICE
   (out of band)  │               │ (TUS, direct)    │
                  │               ▼                  ▼
                  │      ┌────────────────┐  ┌──────────────────┐
                  │      │ Supabase       │  │ Supabase         │
                  │      │ Storage        │  │ Realtime         │
                  │      │ (private)      │  │ (private channel)│
                  │      └───────┬────────┘  └────────┬─────────┘
                  │              │                    │
                  │              │ signed URL         │
                  ▼              │ (60 s)             ▼
    ┌─────────────────────┐      │           ┌──────────────────┐
    │ recipient browser   │◀─────┘           │ Cloudflare TURN  │
    │ crypto worker · FS  │◀─── relayed ciphertext ──┤ (relay only) │
    └──────────┬──────────┘                  └──────────────────┘
               │ authorize / events                   ▲
               ▼                                      │ short-TTL creds
    ┌───────────────────────────────────────────────┐ │
    │                Railway API                     ├─┘
    │  JWT verify (JWKS) · download authorization    │
    │  TURN minting · sweeper · plan enforcement     │
    │  rate limiting · abuse                         │
    └────────────────────┬──────────────────────────┘
                         │ secret key, RLS bypassed
                         ▼
              ┌────────────────────────┐
              │ Supabase Postgres+Auth │
              └────────────────────────┘

    Vercel / Next.js 16 renders every page. It is never in the byte path.
```

## Service responsibilities

### Vercel, Next.js 16

Renders the landing page and composer, the recipient page, the management page, the dashboard,
the drive, settings, and pricing. Uses the **publishable key** only, with RLS enforced. Never
holds a secret key. Never proxies file bytes: Vercel's function request and response body limits
make it unsuitable, and routing bytes through it would break the "no plaintext, no bulk traffic
on the web tier" rule.

Server Components by default. Client Components only at the leaves that need them: the drop
zone, the crypto worker bridge, the WebRTC session, the TUS uploader, and the countdown timers.

### Supabase

- **Auth.** Anonymous sign-in gives every sender a real `auth.uid()` so RLS needs no special
  cases. Upgrading an anonymous user goes through email first, then optionally a passkey, because
  anonymous users cannot register a passkey directly.
- **Postgres.** Source of truth for drops, files, events, subscriptions, drive nodes, and plan
  limits. RLS on every table, including the ones only Railway touches.
- **Storage.** One private bucket, `drops`. Browser to Storage directly over TUS. Downloads
  through short-lived signed URLs minted by Railway.
- **Realtime.** Two uses: private Broadcast channels carrying WebRTC signaling, and Postgres
  changes on `drop_events` for the sender's live counters.
- **Edge Functions.** The Stripe webhook receiver only. Nothing else. It verifies the signature
  and writes one `subscriptions` row.

### Railway

TypeScript on Node, Fastify. Holds the **secret key** and is the only place RLS is bypassed,
which is exactly why every entitlement decision lives here.

1. Download authorization: status, expiry, cap, and password verifier, then a 60 second signed
   URL.
2. TURN credential minting, scoped per drop session.
3. The expiry sweeper, on a schedule.
4. Plan enforcement at creation, at upload authorization, and at expiry changes.
5. Rate limiting and the abuse path.

No image processing, no scanning, no bundling. Railway only ever holds ciphertext, so there is
nothing for those jobs to do.

### Cloudflare TURN, the documented exception

WebRTC cannot hide peer IP addresses from each other without a relay, and Railway has no inbound
UDP so it cannot host one. Cloudflare's managed TURN is the relay. Railway mints short-lived
credentials so the long-term key never reaches a browser. This is the only service outside the
three lanes and it exists for one reason, recorded in [14-decisions.md](14-decisions.md).

## Key handling

Supabase is retiring the `anon` and `service_role` JWT-style keys at the end of 2026. Use the
new names from day one.

| Key | Where it lives | RLS |
| --- | --- | --- |
| `sb_publishable_...` | Vercel, browsers, Apple apps | Enforced |
| `sb_secret_...` | Railway only, and the Stripe Edge Function | Bypassed |

The secret key is never in a client bundle, never in a Next.js Server Component, and never in an
environment variable prefixed `NEXT_PUBLIC_`. CI fails the build if the string `sb_secret_`
appears anywhere under the web app's source tree.

## JWT verification on Railway

Supabase signs with asymmetric keys now, ES256 by default. Railway verifies locally against the
project JWKS with `jose`:

```ts
const JWKS = createRemoteJWKSet(
  new URL(`${env.SUPABASE_URL}/auth/v1/.well-known/jwks.json`)
)

const { payload } = await jwtVerify(token, JWKS, {
  issuer: `${env.SUPABASE_URL}/auth/v1`,
  audience: 'authenticated',
})
```

Then assert `payload.sub`, `payload.role === 'authenticated'`, and read `payload.is_anonymous`
to decide entitlements. The JWKS is cached in process; key rotation is zero downtime and needs
no deploy. Never verify with a shared secret, and never call the Auth API per request.

## Repository layout

One repository, pnpm workspaces, Turborepo for task orchestration.

```
.
├── apps/
│   ├── web/                  Next.js 16, deploys to Vercel
│   └── api/                  Fastify, deploys to Railway
├── packages/
│   ├── crypto/               streaming AEAD, manifest, key derivation, link format
│   ├── transport-p2p/        WebRTC session, signaling, resume, fan-out
│   ├── transport-cloud/      TUS wrapper, signed-URL download, retries
│   ├── contract/             Zod schemas for the API, shared error codes, plan types
│   └── config/               eslint, tsconfig, prettier bases
├── supabase/
│   ├── migrations/           numbered SQL, forward only
│   ├── functions/stripe/     the one Edge Function
│   └── tests/                pgTAP
├── apple/
│   ├── DropApp/              shared SwiftUI package
│   ├── DropApp-iOS/
│   ├── DropApp-macOS/
│   └── DropShareExtension/
└── docs/                     this directory
```

`packages/crypto`, `packages/transport-p2p`, and `packages/transport-cloud` have no DOM-framework
dependency and no React. They are testable headlessly and are what the Apple clients are ported
against.

## Data flow, drop creation, cloud transport

```
 1. browser   generate drop key (256-bit), generate slug locally? no: ask API
 2. browser → API    POST /v1/drops {transport, mode, expiry, cap, size estimate,
                                     password_verifier?, file_count}
                     API checks plan ceilings, inserts row status='uploading',
                     returns {id, slug, manage_secret?}
 3. browser   encrypt each file streaming, upload ciphertext via TUS direct to Storage
              at drops/{drop_id}/{file_id}; storage RLS checks ownership and status
 4. browser   build manifest, encrypt it with the drop key
 5. browser → API    POST /v1/drops/{id}/seal {encrypted_manifest, files[]}
                     API validates sizes against what Storage reports, sets status='sealed'
 6. browser   compose https://host/d/{slug}#{key}
```

The drop key never appears in steps 2 or 5. The API learns sizes, counts, and timing, and
nothing else.

## Data flow, recipient, cloud transport

```
 1. Next.js server component calls rpc get_public_drop(slug) with the publishable key
 2. page renders: title-less shell, transport, rounded size, count, countdown, password gate
 3. client decrypts the manifest with the fragment key, renders the tree
 4. client → API   POST /v1/drops/{slug}/authorize {password_proof?}  → recipient token
 5. client → API   POST /v1/drops/{slug}/download {file_id}  (Bearer recipient token)
                   API checks status, expiry, cap, records the event, returns a 60 s signed URL
 6. client   fetch(signedUrl) → decrypt stream → write to disk
```

Step 4 exists so the password is checked once and the download endpoint stays cheap. The
recipient token is opaque, per session, and carries no identity.

## Data flow, peer-to-peer

```
 sender                         Supabase Realtime                      recipient
   │  join private channel  drop:{h(slug)}                                │
   │◀───────────────── presence: a recipient appeared ────────────────────│
   │  POST /v1/drops/{slug}/turn  → iceServers (short TTL)                │
   │──────────────── offer (encrypted SDP blob) ─────────────────────────▶│
   │◀─────────────── answer (encrypted SDP blob) ─────────────────────────│
   │◀────────────── ICE candidates, relay only, both ways ───────────────▶│
   │══════════ DataChannels: manifest, then chunked ciphertext ══════════▶│
```

Signaling payloads are encrypted with a key derived from the drop key, so Supabase sees two
anonymous sessions exchanging opaque blobs. Realtime's Broadcast payload cap is 256 KB, which is
far above what an SDP or ICE candidate needs, but chunked media is never sent over this channel.

## Environments

Three, all identical in shape.

| | Supabase project | Railway env | Vercel env | Bucket |
| --- | --- | --- | --- | --- |
| local | local stack via CLI | `pnpm dev` | `pnpm dev` | `drops` |
| preview | shared preview project | preview service | preview deploys | `drops` |
| production | production project | production service | production | `drops` |

Preview deploys never point at production. The check that enforces this is in
[11-ops-runbook.md](11-ops-runbook.md).

## Non-negotiables for reviewers

A pull request is rejected on sight if it does any of these.

- Puts a secret key anywhere but Railway or the Stripe Edge Function.
- Sends file bytes through a Next.js route handler or a Vercel function.
- Adds a column that stores an IP address, a user agent, a referrer, or a stable per-recipient
  identifier.
- Reads an entitlement from a client-supplied field.
- Adds a server-side code path that would require plaintext.
- Introduces a hardcoded limit or duration instead of reading `plan_limits`.

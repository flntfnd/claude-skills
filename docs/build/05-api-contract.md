# 05. API contract

The Railway HTTP surface. Fastify on Node 22, TypeScript, every route validated by a Zod schema
exported from `packages/contract` so the web app and the Apple app share the types.

Base URL: `https://api.{host}`. All paths are prefixed `/v1`. All bodies are JSON except where
noted. All timestamps are RFC 3339 in UTC.

## Authentication

Three credential kinds. A route accepts exactly one of them; the table on each endpoint says
which.

| Kind | Header | Verified how |
| --- | --- | --- |
| **User** | `Authorization: Bearer <supabase access token>` | `jose` against the project JWKS, ES256, `iss` and `aud` checked. Anonymous users are valid users and carry `is_anonymous: true`. |
| **Manage** | `Authorization: Manage <base64url secret>` | `SHA-256` compared in constant time against `drop_manage.secret_hash`. |
| **Recipient** | `Authorization: Recipient <token>` | Stateless token minted by `/authorize`, HMAC-SHA256 over `{drop_id, exp, pw}` with a server key. Never stored. |

There is no API key, no session cookie, and no refresh flow. Railway never issues a credential
that outlives 15 minutes except the manage secret, which the sender holds.

## Error format

RFC 9457 `application/problem+json`, always with a machine-readable `code`.

```json
{
  "type": "https://host/errors/plan_ceiling_size",
  "title": "Drop exceeds the plan size limit",
  "status": 422,
  "code": "plan_ceiling_size",
  "detail": "This drop is 6.2 GB. Free drops are limited to 5 GB.",
  "limit": 5368709120,
  "plan": "free"
}
```

| Code | Status | When |
| --- | --- | --- |
| `invalid_request` | 400 | Schema validation failed |
| `unauthenticated` | 401 | Missing or invalid credential |
| `forbidden` | 403 | Valid credential, wrong subject |
| `not_found` | 404 | No such slug or id |
| `drop_ended` | 410 | Expired, revoked, or cap reached. `reason` says which |
| `password_required` | 401 | No recipient token and the drop has a password |
| `password_incorrect` | 401 | Proof did not match |
| `plan_ceiling_size` | 422 | Size over the plan limit |
| `plan_ceiling_expiry` | 422 | Expiry over the plan limit |
| `plan_ceiling_files` | 422 | File count over the plan limit |
| `plan_ceiling_drops` | 422 | Too many active drops |
| `quota_exceeded` | 422 | Drive or relay quota |
| `not_sealed` | 409 | Download attempted before the manifest was committed |
| `already_sealed` | 409 | Seal called twice |
| `rate_limited` | 429 | With `Retry-After` |
| `internal` | 500 | Never leaks a stack trace or a query |

`detail` is user-facing copy. It never contains a slug, a key, or an internal id.

## Endpoints

### `POST /v1/drops`

Create a drop. Auth: **User**.

```jsonc
// request
{
  "transport": "cloud",              // p2p | cloud
  "kind": "folder",                  // file | folder
  "mode": "send",                    // send | request
  "allow_direct": false,             // p2p only
  "expiry": { "kind": "relative", "seconds": 604800 },
  // or { "kind": "absolute", "at": "2026-10-01T09:00:00Z" }
  // or { "kind": "never" }            paid, drive-backed drops only
  // or { "kind": "session" }          p2p only, expires when the sender disconnects
  "max_downloads": 1,                // null for unlimited
  "estimated_size": 3623878656,
  "file_count": 42,
  "password": {                      // omit when there is no password
    "salt": "base64url 16 bytes",
    "verifier": "base64url 32 bytes",   // SHA-256 of VER, computed client side
    "params": { "alg": "argon2id", "v": 19, "m": 65536, "t": 3, "p": 1 }
  },
  "request_public_key": null,        // required when mode is request
  "from_drive": ["node-uuid", "..."] // optional, paid, reuses existing objects
}
```

```jsonc
// 201
{
  "id": "uuid",
  "slug": "8kq2mavx3f",
  "status": "uploading",             // "sealed" immediately for p2p and drive-backed drops
  "expires_at": "2026-09-16T14:12:00Z",
  "manage_secret": "base64url 32 bytes",   // only for anonymous owners, only here, once
  "upload": {                        // cloud only
    "endpoint": "https://{ref}.storage.supabase.co/storage/v1/upload/resumable",
    "bucket": "drops",
    "prefix": "8f2c.../"             // the drop id
  }
}
```

Behavior:

- Resolves the plan through `current_plan`, then checks size, file count, expiry, and active drop
  count against `plan_limits`. Failure is a `plan_ceiling_*` error naming the limit and the plan
  that would raise it. The client never pre-decides this; it renders whatever the API allows.
- `session` expiry stores `expires_at = now() + 24 hours` as a backstop and is really ended by the
  sender's Realtime presence going away. The sweeper is the safety net, not the mechanism.
- `never` requires the paid plan and `from_drive` to be non-empty.
- `from_drive` copies `wrapped_content_key` references into `drop_files` pointing at the existing
  `drive` bucket objects. Nothing is uploaded and the drop is created already sealed once the
  client posts its manifest.
- The manage secret is generated server side, returned exactly once, and stored only as a hash.

### `POST /v1/drops/:id/seal`

Commit the manifest and open the drop. Auth: **User** (owner).

```jsonc
// request
{
  "encrypted_manifest": "base64 of the envelope",
  "files": [
    { "id": "uuid", "storage_key": "8f2c.../0f4c...", "size_bytes": 12648430 }
  ]
}
```

```jsonc
// 200
{ "status": "sealed", "sealed_at": "...", "size_bytes": 3623878656, "file_count": 42 }
```

The server independently asks Storage for the size of every object and rejects the seal if a
reported size disagrees with the client's by more than one segment's overhead. This is the only
defense against a client that lies about size to dodge a quota, and it is cheap because it is one
list call per prefix.

### `PATCH /v1/drops/:id`

Change expiry or cap. Auth: **User** (owner) or **Manage**.

```jsonc
// request, any subset
{ "expiry": { "kind": "relative", "seconds": 86400 }, "max_downloads": 5 }
```

Returns the updated public projection. Extending past the plan ceiling fails with
`plan_ceiling_expiry`. Shortening below `now()` is treated as a revoke. Every change writes an
`extend` or `shorten` event.

### `DELETE /v1/drops/:id`

Revoke. Auth: **User** (owner) or **Manage**. Idempotent.

Sets `status = 'revoked'`, `ended_reason = 'revoked'`, nulls the manifest, writes a `revoke`
event, and queues the objects for deletion on the next sweep. Returns `204`. A revoked drop's
link still resolves to the tombstone page.

### `GET /v1/drops/:slug/public`

The public projection, identical to `get_public_drop`. Auth: **none**.

This exists as a fallback and for the Apple clients. The web app calls the Postgres function
directly from a Server Component instead, which saves a hop. Both must return the same shape;
one contract test asserts it.

Cache: `Cache-Control: no-store`. A countdown that is even slightly stale is a bug.

### `POST /v1/drops/:slug/authorize`

Exchange an optional password proof for a recipient token. Auth: **none**.

```jsonc
// request
{ "proof": "base64url 32 bytes" }   // omit when the drop has no password
```

```jsonc
// 200
{ "token": "...", "expires_in": 900 }
```

Rate limited hard: 10 attempts per drop per fingerprint per hour, then `429` with `Retry-After`.
Constant-time comparison. A wrong proof and a missing proof produce the same timing.

### `POST /v1/drops/:slug/download`

Authorize one file download. Auth: **Recipient**.

```jsonc
// request
{ "file_id": "uuid" }
```

```jsonc
// 200
{ "url": "https://...", "expires_in": 60 }
```

Order of operations, which matters:

1. Verify the recipient token binds to this drop and, if the drop has a password, that `pw` is
   true.
2. Call `try_consume_download(drop_id)`. A `false` return means ended; read the row to say why
   and return `410` with `reason`.
3. Insert a `download_start` event.
4. Mint a 60 second signed URL for the object.

The cap counts authorizations, not completions, because a completion cannot be observed
honestly. This is stated in the UI: "downloads" means "times the file was handed out". A
`download_complete` event is recorded when the client reports success, and is used only for the
sender's progress display, never for the cap.

### `POST /v1/drops/:slug/events/view`

Record a view. Auth: **none**. Body: `{ "nonce": "random per page load" }`.

Deduplicated on `(drop_id, nonce)` in a five minute in-memory window so a refresh does not inflate
the count. Returns `204` always, including for a dead drop, so it can never be used as an oracle.

### `POST /v1/drops/:slug/turn`

Mint TURN credentials for one peer-to-peer session. Auth: **User** (owner) or **Recipient**.

```jsonc
// 200
{
  "iceServers": [
    { "urls": ["stun:stun.cloudflare.com:3478"] },
    {
      "urls": [
        "turn:turn.cloudflare.com:3478?transport=udp",
        "turns:turn.cloudflare.com:5349?transport=tcp",
        "turns:turn.cloudflare.com:443?transport=tcp"
      ],
      "username": "...",
      "credential": "..."
    }
  ],
  "expires_in": 21600,
  "policy": "relay"
}
```

Railway calls Cloudflare:

```
POST https://rtc.live.cloudflare.com/v1/turn/keys/{TURN_KEY_ID}/credentials/generate-ice-servers
Authorization: Bearer {TURN_KEY_API_TOKEN}
{ "ttl": 21600 }
```

TTL is six hours. Cloudflare's maximum is 48 hours and credentials cannot be revoked, so short is
the only control. The long-term key never leaves Railway.

`policy` is `"relay"` unless the drop has `allow_direct` and both peers opted in, in which case it
is `"all"`. The client must honor it; the server also declines to mint credentials for a drop that
has ended.

Relay egress is billed at $0.05 per GB after the first terabyte each month, so this endpoint
checks `relay_usage` against the plan's `relay_bytes_per_month` and returns `quota_exceeded` when
the sender is over. Usage is reported by the sender at the end of a session and is advisory; the
authoritative number comes from Cloudflare's own metering, reconciled daily.

### `POST /v1/drops/:slug/request-slot`

Pre-authorize one upload into a request-mode drop. Auth: **User** (any, including anonymous).

```jsonc
// request
{ "size_bytes": 104857600 }
// 201
{ "slot_id": "uuid", "storage_key": "8f2c.../{slot_id}", "expires_at": "..." }
```

The slot id is the file id, so the storage policy can check it. Slots expire in two hours. The
plan's `max_request_inbound_bytes` caps a single slot and the sum of open slots.

### Drive endpoints

All auth: **User**, paid plan enforced by `current_plan` and by RLS.

| Method | Path | Purpose |
| --- | --- | --- |
| `POST` | `/v1/drive/activate` | Store the wrapped root keys. Fails if already activated. |
| `GET` | `/v1/drive/keys` | Return the wrapped blobs so the client can unwrap locally. |
| `POST` | `/v1/drive/keys/rewrap` | Replace one wrap (password change, new passkey). |
| `POST` | `/v1/drive/nodes` | Create a folder or reserve a file node, returns the storage key. |
| `PATCH` | `/v1/drive/nodes/:id` | Rename or move. Body carries a new `encrypted_meta`. |
| `DELETE` | `/v1/drive/nodes/:id` | Soft delete, then hard delete on the next sweep. |
| `GET` | `/v1/drive/usage` | `{ used_bytes, quota_bytes }`. |

Node creation checks `drive_usage(user) + size <= plan_limits.drive_bytes` and returns
`quota_exceeded` otherwise.

### `POST /v1/reports`

Report a drop. Auth: **none**. Body: `{ "slug": "...", "reason": "...", "key": "optional" }`.

Writes an `abuse_reports` row with no reporter identity and a `report` event. If the reporter
volunteers the decryption key, it is stored in a separate operator-only queue with a 30 day
retention, because App Store guideline 1.2 requires a mechanism to review reported content and
this is the only way to review anything in a zero-knowledge system. The UI says exactly that
before the checkbox. Without a key, the response is a takedown decision made on report volume and
pattern alone.

### Billing endpoints

| Method | Path | Auth | Purpose |
| --- | --- | --- | --- |
| `POST` | `/v1/billing/checkout` | User | Create a Stripe Checkout session, return its URL |
| `POST` | `/v1/billing/portal` | User | Create a Customer Portal session, return its URL |
| `GET` | `/v1/billing/subscription` | User | The four fields stored, nothing else |

The Stripe webhook does **not** land here. It lands on a Supabase Edge Function; see
[10-billing-plans.md](10-billing-plans.md).

### Operational endpoints

| Method | Path | Auth | Purpose |
| --- | --- | --- | --- |
| `GET` | `/healthz` | none | Process is up. No dependency checks. |
| `GET` | `/readyz` | none | Postgres and Storage reachable. Used by the deploy gate. |
| `POST` | `/internal/sweep` | shared secret header | Runs one sweep pass. Called by Railway cron. |

## Rate limits

Keyed by `HMAC(daily_salt, fingerprint)` where the fingerprint is derived from the request and
never stored in reversible form. The salt rotates at midnight UTC and the old salt is discarded,
so yesterday's buckets cannot be linked to today's.

| Endpoint | Limit |
| --- | --- |
| `POST /v1/drops` | 20 per hour, 100 per day |
| `POST /v1/drops/:slug/authorize` | 10 per hour per drop |
| `POST /v1/drops/:slug/download` | 120 per hour per drop |
| `POST /v1/drops/:slug/turn` | 30 per hour per drop |
| `POST /v1/drops/:slug/request-slot` | 50 per hour per drop |
| `GET /v1/drops/:slug/public` | 300 per hour |
| everything else | 300 per hour |

Exceeding a limit returns `429` with `Retry-After` and never explains which bucket was hit.

## Cross-cutting requirements

- **CORS**: allow the web origin and the Apple apps' origin only. No wildcard.
- **Logging**: method, route pattern, status, duration, and a request id. Never the full path with
  its slug, never a header, never a body, never an IP. The reverse proxy's own access log is
  disabled.
- **Timeouts**: 10 seconds for anything touching Cloudflare or Stripe, 5 seconds for Postgres.
- **Graceful shutdown**: stop accepting, drain for 15 seconds, close the pool. Per
  `backend-conventions`.
- **Idempotency**: `seal`, `revoke`, and the billing endpoints accept an `Idempotency-Key` header
  and replay the stored response for 24 hours.
- **No response ever contains** a drop key, a manage secret after creation, a storage key for a
  drop the caller does not own, a Stripe object, or a database error string.

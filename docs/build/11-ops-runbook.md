# 11. Ops runbook

Environments, secrets, deploys, monitoring, and what to do at three in the morning. Written for
someone who did not build the system.

## Environments

| | Supabase | Railway | Vercel |
| --- | --- | --- | --- |
| local | CLI stack on `localhost:54321` | `pnpm dev` | `pnpm dev` |
| preview | shared preview project | preview service | preview deployments |
| production | production project | production service | production |

A preview deployment never points at production. Enforced by a CI check that asserts the preview
build's `NEXT_PUBLIC_SUPABASE_URL` does not equal the production URL.

## Secrets

| Secret | Lives in | Never in |
| --- | --- | --- |
| `sb_publishable_...` | Vercel, Railway, Apple apps | nowhere sensitive, it is public by design |
| `sb_secret_...` | Railway, Stripe Edge Function | Vercel, any client, any `NEXT_PUBLIC_` variable |
| `TURN_KEY_ID`, `TURN_KEY_API_TOKEN` | Railway | anywhere else |
| `STRIPE_SECRET_KEY` | Railway, Edge Function | anywhere else |
| `STRIPE_WEBHOOK_SECRET` | Edge Function | anywhere else |
| `RECIPIENT_TOKEN_KEY` | Railway | anywhere else |
| `RATE_LIMIT_SALT_SEED` | Railway | anywhere else |
| `SWEEP_SHARED_SECRET` | Railway | anywhere else |

CI fails the build if `sb_secret_` or `sk_live_` appears anywhere under `apps/web` or `apple/`.
This is a grep, it runs in under a second, and it has caught this class of mistake in every
project that has had it.

Rotation: the Supabase secret key and the TURN token rotate quarterly. Supabase JWT signing keys
rotate through standby to current to revoked with no deploy, because Railway reads JWKS at
runtime.

## Deploy

Order matters. Migrations first, then the API, then the web.

```
 1. supabase db push                 forward-only migrations
 2. pgTAP suite against preview      blocks on failure
 3. railway up                       API, health-gated
 4. vercel deploy --prod             web
 5. smoke suite against production   see below
```

Migrations are forward only. There is no down migration. Rolling back means writing a new
migration, which is slower and safer than the alternative and forces the schema change to be
compatible with the previous version of the code.

Every migration is additive first: add the column, deploy the code that writes both, backfill,
then deploy the code that reads the new one, then drop the old one in a later release. Nothing
ships a breaking schema change and its consuming code in one deploy.

### Smoke suite

Runs against production after every deploy. Five checks, under 60 seconds.

1. Create an anonymous session and a 1 MB cloud drop, seal it, download it, assert byte equality.
2. Assert the drop's public projection has no manifest before seal and has one after.
3. Revoke it, assert `410` with `reason: revoked`.
4. Mint TURN credentials, assert `iceServers` includes a `turns:` entry on port 443.
5. Fetch the web app and assert every security header from
   [08-web-app.md](08-web-app.md) is present.

A failure rolls back the web deploy automatically and pages.

## Scheduled jobs

| Job | Where | Interval | Alert if |
| --- | --- | --- | --- |
| sweep | Railway cron | 5 minutes | two consecutive failures, or a run over 60 seconds |
| orphan objects | Railway cron | daily | any orphan found, since there should be none |
| anonymous user cleanup | `pg_cron` | daily | job did not run |
| relay reconciliation | Railway cron | daily | Cloudflare usage differs from the client-reported figure by more than 20 percent |

The sweep contract is that ciphertext is deleted within 15 minutes of expiry. Five minute
intervals give two chances to meet it. A missed sweep is a privacy incident, not a performance
issue, and is treated that way.

## Monitoring

What is watched, and nothing more. There is no analytics and no user-level telemetry.

| Signal | Source | Threshold |
| --- | --- | --- |
| API error rate | Railway logs | over 1 percent of requests for 5 minutes |
| API p99 latency | Railway | over 800 ms for 5 minutes |
| Sweep lag | `max(now() - expires_at)` for unswept drops | over 15 minutes |
| Storage bucket size | Supabase | growth over 20 percent day over day |
| Relay spend | Cloudflare | over 80 percent of the monthly budget |
| Stripe webhook failures | Stripe dashboard | any |
| Postgres connections | Supabase | over 70 percent of the pool |

Logs contain method, route pattern, status, duration, and a request id. They do not contain a
slug, a key, a header, a body, or an IP address. The reverse proxy's own access log is disabled.
This is checked by a test that greps a log sample for a slug-shaped string.

## Incident playbooks

### Sweep is behind

Ciphertext that should be deleted still exists. Treat as a privacy incident.

1. `GET /readyz` on Railway. If the service is down, that is the cause.
2. Run `POST /internal/sweep` manually and watch the count.
3. If `expire_due_drops` is slow, check for a lock on `drops` from a long-running migration.
4. If Storage deletes are failing, check the Supabase status page and the secret key's validity.
5. Record the maximum lag in the incident note. If any drop was readable more than 15 minutes past
   its expiry, that is a broken promise and goes in the changelog.

### A drop is reported as abusive

1. Read the `abuse_reports` row. There is no reporter identity, by design.
2. If the reporter supplied a key, a human may review the content from the operator-only queue.
   Two people must be present. The review is logged with the reviewer identity and the outcome.
3. Revoke with `DELETE /v1/drops/:id`. Objects are deleted immediately.
4. If the same sender lineage produces repeated reports, suspend the account by setting its
   subscription status; there is no other lever, and that is the intended design.
5. Reports are answered within one business day, which is what guideline 1.2 requires.

### Relay spend is spiking

1. Check `relay_usage` for the top accounts this month.
2. Confirm against Cloudflare's own metering; the client-reported figure is advisory.
3. If one account dominates, its quota check should already be refusing new credentials. If it is
   not, that is the bug.
4. The emergency lever is lowering `relay_bytes_per_month` in `plan_limits`, which takes effect on
   the next credential mint. It is a migration, so it is reviewable.

### Supabase is down

1. The web app cannot render the recipient page, because `get_public_drop` is a database call.
   That is acceptable and it fails to the error page.
2. Peer-to-peer sessions already connected keep running, because signaling is only needed to
   establish the session. Say so on the status page.
3. Do not fail over to a cached projection. A stale expiry is worse than an outage.

### A key was exposed

If the Supabase secret key, the TURN token, or the Stripe key is exposed:

1. Rotate immediately in the provider dashboard.
2. Update the Railway variable and redeploy. Railway is the only consumer, so this is one deploy.
3. For the TURN token, existing credentials remain valid for their remaining TTL, up to six hours,
   and cannot be revoked. That window is the reason the TTL is six hours and not forty-eight.
4. For `RECIPIENT_TOKEN_KEY`, rotating invalidates every outstanding recipient token, which forces
   password re-entry on protected drops. Acceptable.

## Backups

Postgres has Supabase's point-in-time recovery. Storage objects are **not** backed up, on purpose:
they are ciphertext with a scheduled death, and a backup would be a copy of data the product
promised to delete. Restoring the database without the objects is the correct outcome; the drops
resolve to tombstones.

The drive is the exception a paying customer will expect to be backed up. It is not, in v1, and
the UI says so at activation alongside the recovery key warning. Making the drive durable is a
scoped project, not a checkbox, and it is an open decision.

## Cost model

| Line | Driver | Notes |
| --- | --- | --- |
| Cloudflare TURN | $0.05 per GB over 1 TB per month | The dominant variable cost |
| Supabase Storage | Per GB stored and egress | Bounded by expiry, which is the point |
| Supabase Realtime | Message volume | Signaling only, negligible |
| Railway | One always-on service | Flat |
| Vercel | Requests | No bytes, so flat |
| Stripe | 2.9 percent plus 30 cents | Only on the paid tier |

The interesting property of this product is that free-tier storage cost is self-limiting: the
7 day ceiling means the steady state is one week of uploads, not an ever-growing archive.

## Definition of production ready

1. The smoke suite passes against production.
2. Sweep lag has stayed under 15 minutes for seven consecutive days.
3. A key rotation has been rehearsed end to end in preview.
4. The abuse playbook has been walked through with the person who will be on call.
5. The status page exists and says what peer-to-peer does during a Supabase outage.
6. No log sample from a full day contains a slug, a key, or an IP address.

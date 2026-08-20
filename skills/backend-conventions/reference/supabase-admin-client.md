## Contents

- [Why the RLS bypass is safe here](#why-the-rls-bypass-is-safe-here)
- [Client setup](#client-setup)
- [Legacy vs new API keys](#legacy-vs-new-api-keys)
- [Connection pooling: Supavisor vs direct Postgres](#connection-pooling-supavisor-vs-direct-postgres)
- [supabase-js admin client vs a raw Postgres client](#supabase-js-admin-client-vs-a-raw-postgres-client)
- [Mistakes specific to the admin client](#mistakes-specific-to-the-admin-client)

## Why the RLS bypass is safe here

Per the repo's lane rules, Supabase RLS is the security boundary everywhere except Railway. On Vercel, every query goes through the anon key and a user session, and `auth.uid()` enforces row-level access. On Railway, the service authenticates as the project itself using `service_role` (or the newer secret key) — RLS doesn't apply to that key at all, by design. That's not a workaround, it's what makes Railway the place for admin operations: user management, cross-tenant aggregation, background writes with no request-scoped user, webhook processing.

The discipline that keeps this safe is entirely about where the key can go:

- It's a Railway service variable, sealed if the plan supports it. Never in a `.env` file committed to source control, never in `railway.json`.
- It's imported only in Railway-deployed code paths. If a file that constructs this client could plausibly end up in a Vercel/Next.js bundle, that's a lane violation regardless of intent.
- Every query issued with this client does its own authorization. There's no `auth.uid()` filtering rows automatically anymore — if a query should only touch one tenant's/user's rows, the `WHERE` clause has to say so explicitly.

## Client setup

```typescript
// lib/supabase-admin.ts
import { createClient } from "@supabase/supabase-js";
import type { Database } from "./database.types"; // from `supabase gen types typescript`

export const supabaseAdmin = createClient<Database>(
    process.env.SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    {
        auth: {
            persistSession: false,
            autoRefreshToken: false,
            detectSessionInUrl: false,
        },
    }
);
```

`persistSession`, `autoRefreshToken`, and `detectSessionInUrl` are all `false` because this client isn't managing a user session at all — it authenticates as the project. Leaving them at their (browser-oriented) defaults wastes effort trying to persist a session that doesn't exist and can throw in a non-browser runtime that lacks `localStorage` `[Verified — Supabase docs/troubleshooting: service-side admin client]`.

Admin-only user management (ban, delete, list users, generate links) goes through `supabaseAdmin.auth.admin.*` — this namespace is only usable with the service_role/secret key, never the anon/publishable key.

## Legacy vs new API keys

Supabase is retiring the legacy `anon`/`service_role` key names in favor of a new key system: `sb_publishable_...` (replaces anon) and `sb_secret_...` (replaces service_role), with legacy keys deprecated by end of 2026 `[Verified — Supabase changelog #29260, checked Aug 2026]`. Both key generations work simultaneously today; creating the new keys doesn't invalidate the old ones.

Practical differences that matter for a Railway service:

- The new secret key returns `401` if used from a browser context, matched by `User-Agent` — a real defense-in-depth improvement over the legacy `service_role` key, which works from anywhere it's presented.
- The new keys go on the `apikey` header, not `Authorization: Bearer` — if hand-rolling requests instead of using `supabase-js`, check which header the code is actually setting.
- Env var naming isn't standardized yet across the ecosystem. This repo's existing `web-platform` skill uses `SUPABASE_SERVICE_ROLE_KEY` (legacy) for its documented pattern. Match whatever key generation the project's Supabase dashboard actually issued — don't assume.

## Connection pooling: Supavisor vs direct Postgres

Supabase offers three ways to reach Postgres. For a Railway service — a persistent, long-running process, not serverless — the right default is different from what a Vercel Edge Function or Server Action would use:

| Mode | Port | Fit for a Railway backend |
| --- | --- | --- |
| Direct connection | 5432 | **Primary choice.** Built for persistent servers and long-lived containers — exactly what a Railway service is. Supports prepared statements, holds its own connection pool. |
| Supavisor session mode | 5432 (pooler) | Fallback only: use when the Railway network is IPv4-only and the project doesn't have the IPv4 add-on. Behaves like a direct connection otherwise. |
| Supavisor transaction mode | 6543 | **Wrong tool here.** Built for serverless/edge functions opening many short-lived connections. Doesn't support prepared statements. A persistent Railway service holding its own pool doesn't need transaction-mode churn. |

`[Verified — supabase.com/docs/guides/database/connecting-to-postgres, checked Aug 2026]`

If the service uses `supabase-js` exclusively (PostgREST under the hood), pooling is Supabase's problem, not the service's — this table matters when the service also opens a raw Postgres connection (via `pg`, `postgres.js`, Prisma, Drizzle) for queries that don't fit well through PostgREST.

Pool sizing isn't given a hard number in Supabase's docs; size the pool against the project's plan-level max-connection limit (visible in the Supabase dashboard's database settings) and leave headroom for other services/tools connecting to the same project. `[Inference — no documented recommended pool size found]` A starting point of 10-20 connections for a single Railway service is reasonable for most workloads; tune based on observed saturation, not a guess baked in up front.

```typescript
// lib/db-pool.ts -- for raw SQL alongside supabase-js
import { Pool } from "pg";

export const pgPool = new Pool({
    connectionString: process.env.DATABASE_URL, // direct connection string, port 5432
    max: 15,
});
```

## supabase-js admin client vs a raw Postgres client

Use `supabaseAdmin` (supabase-js with the service key) for:
- Anything already modeled as a Supabase table with generated types — standard CRUD, upserts, RPC calls to Postgres functions.
- Auth admin operations (`auth.admin.*`) — no raw-SQL equivalent exists for these.
- Storage operations (signed URLs, admin bucket access).

Reach for a raw Postgres client (`pg`, `postgres.js`, an ORM) when:
- The query is complex enough that PostgREST's query builder is awkward — deep joins, window functions, recursive CTEs, bulk operations.
- The service needs a real transaction spanning multiple statements — supabase-js doesn't expose multi-statement transactions.
- Migrations — these run as raw SQL/DDL regardless of which client the app uses at runtime.

Both can coexist against the same database from the same Railway service; they're not mutually exclusive.

## Mistakes specific to the admin client

| Mistake | Why it's wrong |
| --- | --- |
| Constructing `supabaseAdmin` in a file under a shared `lib/` also imported by Next.js code | If that file ships to Vercel, the service_role key ships with it |
| Leaving `persistSession`/`autoRefreshToken` at default (`true`) | Tries to manage a browser session that doesn't exist in a server process |
| Relying on RLS to filter results through the admin client | RLS doesn't apply to service_role — the query itself must filter |
| Using Supavisor transaction mode (port 6543) as the main pool for a long-running service | Wrong connection lifecycle for a persistent process; no prepared statement support |
| Hardcoding the Supabase URL/key instead of reading from Railway service variables | Breaks per-environment (staging/prod) separation that Railway environments are for |

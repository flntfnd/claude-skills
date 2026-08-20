---
name: backend-conventions
description: Railway backend conventions for standalone compute outside the Next.js request cycle -- bare API servers, background workers, cron jobs, queue consumers. Covers healthcheckPath/healthcheckTimeout, graceful shutdown (SIGTERM, RAILWAY_DEPLOYMENT_DRAINING_SECONDS, in-flight draining), restart policy, railway.json/railway.toml, Railpack/Nixpacks/Dockerfile builders, env vars and sealed/shared/reference secrets, the Supabase service_role admin client (RLS bypass safety on Railway, Supavisor vs direct Postgres pooling), Railway's native cron jobs, worker vs queue patterns (BullMQ, pg-boss), retry/backoff, idempotency, structured JSON logging, and monorepo multi-service layout. Use when building or reviewing a Railway API server, worker, cron job, or queue consumer, wiring health checks or graceful shutdown, setting up a Supabase admin client outside Next.js, or configuring railway.json. Defers to rust-conventions for Rust backends and web-platform for Supabase inside Next.js.
---

# Backend conventions (Railway)

Operational layer for backend compute on Railway that runs on its own -- not behind a Next.js route. Bare API servers, always-on workers, cron jobs, queue consumers. Per the repo's lane rules: Railway is the trusted backend, `service_role` lives here, RLS is intentionally bypassed here and nowhere else.

Default worked example throughout: TypeScript/Node. This is the likely default for non-Rust backend work in this stack. **If the service is written in Rust, use `rust-conventions` instead** -- axum/sqlx/tower, async discipline, and Rust-specific error handling are fully covered there and not repeated here. This skill covers what's language-agnostic to running *any* backend service on Railway; the Node track is the concrete example.

If the Supabase client lives inside a Next.js Server Component, Server Action, or route handler, that's `web-platform`'s `reference/supabase-integration.md`, not this skill -- that file covers the anon-key, cookie-session, RLS-enforced path. This skill covers the other side of the lane: the `service_role` key, no user session, no RLS.

## Quick reference

| Topic | File |
| --- | --- |
| Health check endpoints, Railway's healthcheck config, restart policy, SIGTERM/graceful shutdown, PORT binding | [reference/health-and-lifecycle.md](reference/health-and-lifecycle.md) |
| Supabase `service_role` admin client setup, why the RLS bypass is safe here, Supavisor vs direct Postgres pooling | [reference/supabase-admin-client.md](reference/supabase-admin-client.md) |
| Cron jobs vs background workers vs queues, Railway's native cron, BullMQ/pg-boss, retry/backoff, idempotency | [reference/background-jobs.md](reference/background-jobs.md) |
| `railway.json`/`railway.toml` schema, Railpack vs Nixpacks vs Dockerfile, env var types, sealed secrets, monorepo layout | [reference/deployment-config.md](reference/deployment-config.md) |
| Structured JSON logging, Railway's log indexing, OpenTelemetry traces, metrics | [reference/observability.md](reference/observability.md) |

## The two essentials

These come up on nearly every Railway backend task, so they're inlined rather than left behind a link.

### service_role is safe here -- but only here

`SUPABASE_SERVICE_ROLE_KEY` (legacy naming) / the newer `sb_secret_...` secret key bypasses RLS entirely. That's not a bug to work around, it's the point of running on Railway -- Railway is the trusted backend per the lane rules, so the admin client is allowed to see every row. The discipline that makes this safe:

- The key never leaves Railway's environment. Not logged, not returned in an API response, not passed to a client-side anything.
- It's a **service variable**, ideally **sealed** (Railway hides the value after save) -- see [reference/deployment-config.md](reference/deployment-config.md).
- Every query issued with this client is doing the authorization the RLS policy would otherwise do. Filter by tenant/user explicitly in the query -- there's no `auth.uid()` doing it for you anymore.
- Supabase is retiring the legacy `anon`/`service_role` key names in favor of `sb_publishable_...`/`sb_secret_...` by end of 2026 `[Verified via Supabase changelog, Aug 2026]`. Both work today. New projects should reach for the new secret key; existing projects don't need to rush a rotation. Full setup in [reference/supabase-admin-client.md](reference/supabase-admin-client.md).

```typescript
// lib/supabase-admin.ts -- Railway only. Never imported into Vercel/Next.js code.
import { createClient } from "@supabase/supabase-js";

export const supabaseAdmin = createClient(
    process.env.SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,   // or SUPABASE_SECRET_KEY (sb_secret_...)
    { auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false } }
);
```

`persistSession`/`autoRefreshToken`/`detectSessionInUrl` are all `false` -- there's no end-user session to manage. This client authenticates as the project itself, not as a user.

### Health checks and graceful shutdown are how Railway decides you're alive

Railway gates every deploy on this and tears down every old deployment through it. Get it wrong and deploys either loop-restart or drop in-flight requests.

**Health check** -- an HTTP endpoint that returns `200` when the service is actually ready to take traffic (not just "process started"):

```typescript
app.get("/health", async (_req, res) => {
    try {
        await supabaseAdmin.from("_healthcheck").select("*").limit(1).maybeSingle();
        res.status(200).send("ok");
    } catch {
        res.status(503).send("not ready");
    }
});
```

Wire it in `railway.json`:

```json
{ "deploy": { "healthcheckPath": "/health", "healthcheckTimeout": 300 } }
```

`healthcheckPath` must start with `/` or Railway rejects the config `[Verified — docs.railway.com]`. Default `healthcheckTimeout` is 300 seconds if unset `[Verified — docs.railway.com/deployments/healthchecks]`. A cron job or worker with no HTTP surface doesn't get an automatic liveness check from Railway the way a web service does — see [reference/health-and-lifecycle.md](reference/health-and-lifecycle.md) for how to handle that case `[Inference — not directly documented]`.

**Graceful shutdown** -- when a new deployment goes active, Railway sends the old one `SIGTERM` and then `SIGKILL` after a grace period that **defaults to 0 seconds** `[Verified — docs.railway.com/guides/deployment-teardown]`. Zero seconds means immediate hard kill unless the service configures `RAILWAY_DEPLOYMENT_DRAINING_SECONDS` (or `drainingSeconds` in `railway.json`) and actually handles `SIGTERM`:

```typescript
const server = app.listen(process.env.PORT || 3000, "0.0.0.0");

process.on("SIGTERM", () => {
    server.close(() => {
        supabaseAdmin.removeAllChannels(); // close any Realtime subscriptions, DB pools, etc.
        process.exit(0);
    });
    // safety net: force-exit if connections don't drain in time
    setTimeout(() => process.exit(1), 10_000).unref();
});
```

Railway sends no other signal, ever `[Verified — docs.railway.com/guides/deployment-teardown]` — there's no `SIGINT` fallback to lean on. Full detail, including restart policy and `PORT` binding, in [reference/health-and-lifecycle.md](reference/health-and-lifecycle.md).

## Common mistakes

| Mistake | Why it's wrong |
| --- | --- |
| Hardcoding a port instead of reading `process.env.PORT` | Railway assigns `PORT` dynamically; a hardcoded port never receives traffic |
| No `SIGTERM` handler | Default drain is 0 seconds — every deploy hard-kills in-flight requests |
| `service_role` client imported into any file that could end up in a Vercel bundle | Bypasses RLS from an untrusted environment — the exact thing the lane rules exist to prevent |
| Health check that just returns `200` unconditionally | Deploy looks healthy while the DB connection is actually down |
| Running a BullMQ (Redis) worker as a Railway cron job | Cron jobs must exit; a queue worker holds an open connection and never does |
| Committing `SUPABASE_SERVICE_ROLE_KEY` (or any secret) into `railway.json`/`railway.toml` | Config-as-code is source-controlled; secrets belong in Railway's variable store, sealed if possible |
| Transaction-mode pooler (port 6543) for a long-running Railway service's main pool | Built for serverless/edge's many short-lived connections; doesn't support prepared statements and is the wrong tool for a persistent server holding its own pool |
| Unstructured `console.log` strings for anything you'll need to query later | Railway indexes structured JSON logs (`level`, `message`, custom fields) for filtering; plain strings aren't filterable |

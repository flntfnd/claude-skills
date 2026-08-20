## Contents

- [PORT binding](#port-binding)
- [Health checks](#health-checks)
- [Restart policy](#restart-policy)
- [Deploy sequence and graceful shutdown](#deploy-sequence-and-graceful-shutdown)
- [Worker/cron services with no HTTP surface](#workercron-services-with-no-http-surface)
- [Full lifecycle example](#full-lifecycle-example)

## PORT binding

Railway injects a `PORT` environment variable at runtime and expects the service to bind `0.0.0.0:$PORT`, not a hardcoded port and not `localhost`/`127.0.0.1` `[Verified — docs.railway.com]`. If `PORT` isn't read, Railway still provides and exposes one, but a service that hardcodes e.g. `3000` starts fine and never receives traffic, because Railway is routing to the port it assigned, not the one the code picked.

```typescript
const port = Number(process.env.PORT) || 3000; // fallback only for local dev
app.listen(port, "0.0.0.0");
```

## Health checks

`healthcheckPath` in `railway.json`/`railway.toml` (or the dashboard) tells Railway which endpoint to poll during a deploy. Rules, confirmed against current docs:

- Must start with `/`, or Railway rejects the config or the check never passes, which puts the service into a restart loop.
- Must return HTTP `200` when the app is live and ready. Any other status is treated as not-ready.
- Default `healthcheckTimeout` is **300 seconds** if not set explicitly `[Verified — docs.railway.com/deployments/healthchecks]`. Railway waits up to this long for the check to start passing before failing the deploy.
- While a deploy is in the `Deploying` state, Railway waits for the healthcheck to succeed before marking the deployment `Active` and cutting traffic over. No healthcheck configured means Railway has less signal that the *application* (versus just the *process*) is actually ready.

```json
{
  "deploy": {
    "healthcheckPath": "/health",
    "healthcheckTimeout": 300
  }
}
```

**Write the check to prove real readiness, not just that the HTTP server is up.** A check that always returns `200` gives Railway (and you, reading the deploy log) false confidence:

```typescript
app.get("/health", async (_req, res) => {
    try {
        // touch the actual dependency the service needs to function
        await supabaseAdmin.from("_healthcheck").select("*").limit(1).maybeSingle();
        res.status(200).json({ status: "ok" });
    } catch (err) {
        res.status(503).json({ status: "not ready", error: String(err) });
    }
});
```

Keep it cheap — this runs on every deploy and can run repeatedly if a downstream dependency is flapping. A single lightweight query is enough; don't fan out to every dependency the service has on every check.

## Restart policy

`restartPolicyType` controls what Railway does after a crash:

| Value | Behavior |
| --- | --- |
| `ON_FAILURE` | Restart only on non-zero exit. The default choice for most services. |
| `ALWAYS` | Restart regardless of exit code, including clean exits. |
| `NEVER` | Never restart — the service stays down after any exit. |

Pair it with `restartPolicyMaxRetries` (integer) to cap restart attempts before Railway gives up and leaves the deployment crashed:

```json
{
  "deploy": {
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 3
  }
}
```

A service left at platform defaults without an explicit `restartPolicyType` can stay down after a crash instead of recovering — set this explicitly rather than relying on the dashboard default.

## Deploy sequence and graceful shutdown

When a new deployment goes active, Railway sends the **previous** deployment `SIGTERM`, waits a configurable grace period, then sends `SIGKILL` if the process hasn't exited `[Verified — docs.railway.com/guides/deployment-teardown]`.

- The grace period is controlled by `RAILWAY_DEPLOYMENT_DRAINING_SECONDS` (env var) or `drainingSeconds` in `railway.json` — same setting, two ways to set it.
- **Default is 0 seconds.** Without explicitly configuring this, `SIGTERM` is followed essentially immediately by `SIGKILL` — there's no free grace period to lean on.
- Railway sends no signal other than `SIGTERM` under any circumstances. No `SIGINT` fallback, no second warning.
- `overlapSeconds` (`RAILWAY_DEPLOYMENT_OVERLAP_SECONDS`) controls how long the old and new deployments run simultaneously before the old one is torn down — this is what makes zero-downtime deploys possible, since the new deployment is already accepting traffic before the old one starts draining.

Set a draining window and actually use it in code:

```json
{ "deploy": { "drainingSeconds": 15 } }
```

```typescript
let shuttingDown = false;

process.on("SIGTERM", () => {
    if (shuttingDown) return;
    shuttingDown = true;

    server.close(() => {              // stop accepting new connections, let in-flight ones finish
        void pgPool.end();            // close DB pool cleanly
        void redisClient.quit();      // close any other held connections
        process.exit(0);
    });

    // hard stop if graceful close hangs past the configured drain window
    setTimeout(() => process.exit(1), 12_000).unref();
});
```

Set the force-exit timer comfortably under `drainingSeconds` (12s here against a 15s window) — the goal is to exit cleanly on your own terms before Railway's `SIGKILL` arrives, not to race it.

## Worker/cron services with no HTTP surface

`[Inference — not directly documented]` Railway's healthcheck mechanism as documented is HTTP-based (`healthcheckPath`). A background worker or cron job with no HTTP server has nothing for that mechanism to poll. In practice:

- Don't set `healthcheckPath` on a service with no HTTP listener — there's nothing for Railway to hit, and an unreachable path will fail the check and loop-restart the deploy.
- Railway's signal for "did this deploy succeed" for a non-HTTP service is process liveness: did it start and stay running (for a worker) or exit 0 (for a cron job)? Restart policy (`ON_FAILURE` etc.) is the safety net here, not a healthcheck.
- If a worker process needs a liveness signal for external monitoring, that's usually solved with a minimal internal HTTP server on a side port purely for a `/health` check, or by shipping heartbeat logs and alerting on their absence — not by contorting the Railway healthcheck config.

## Full lifecycle example

```typescript
import express from "express";
import { supabaseAdmin } from "./lib/supabase-admin";

const app = express();
const port = Number(process.env.PORT) || 3000;

app.get("/health", async (_req, res) => {
    try {
        await supabaseAdmin.from("_healthcheck").select("*").limit(1).maybeSingle();
        res.status(200).json({ status: "ok" });
    } catch (err) {
        res.status(503).json({ status: "not ready", error: String(err) });
    }
});

const server = app.listen(port, "0.0.0.0", () => {
    console.log(JSON.stringify({ level: "info", message: `listening on ${port}` }));
});

let shuttingDown = false;
process.on("SIGTERM", () => {
    if (shuttingDown) return;
    shuttingDown = true;
    console.log(JSON.stringify({ level: "info", message: "SIGTERM received, draining" }));
    server.close(() => process.exit(0));
    setTimeout(() => process.exit(1), 12_000).unref();
});
```

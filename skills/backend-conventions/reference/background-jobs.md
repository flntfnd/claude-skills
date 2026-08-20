## Contents

- [Choosing cron vs worker vs queue](#choosing-cron-vs-worker-vs-queue)
- [Railway cron jobs](#railway-cron-jobs)
- [Background workers](#background-workers)
- [Queue consumers](#queue-consumers)
- [Retry and backoff](#retry-and-backoff)
- [Idempotency](#idempotency)

## Choosing cron vs worker vs queue

Railway's own guidance draws the line like this `[Verified — docs.railway.com/guides/cron-workers-queues]`:

| Pattern | Use for | Shape |
| --- | --- | --- |
| Cron job | Scheduled, time-based tasks: report generation, data cleanup, periodic syncs, cache warming | Starts on a schedule, does the work, **exits**. Railway won't force-kill a hung one. |
| Background worker | Real-time event processing, long-running computation, streaming pipelines — anything that reacts to events as they happen | Always-on service. Runs continuously, typically over Railway's private networking from another service. |
| Message queue | Work that needs retry logic, load leveling, fan-out to multiple consumers, or processing decoupled from the producer's request/response cycle | A broker (Redis, or Postgres via pg-boss) holds jobs; one or more consumer services pull and process them. |

The dividing question that matters most in practice: **does the process need to exit when it's done, or stay running?** Cron jobs must exit. Workers and queue consumers must not — conflating the two is the most common mistake here (see below).

## Railway cron jobs

Configured via crontab expression, either in the dashboard's Cron Schedule setting or the `cronSchedule` field in `railway.json`/`railway.toml`:

```json
{ "deploy": { "cronSchedule": "30 * * * *" } }
```

Confirmed constraints `[Verified — docs.railway.com/cron-jobs]`:

- Standard 5-field crontab syntax (minute, hour, day-of-month, month, day-of-week), evaluated in **UTC** — convert manually for any other timezone.
- The shortest interval between executions is **5 minutes**. Nothing more frequent is possible.
- If a previous execution is still running when the next is due, Railway **skips** the new one rather than running them concurrently.
- Railway does not forcibly terminate a hung cron process. If the code doesn't exit on its own, subsequent scheduled executions keep getting skipped indefinitely — the job silently stops running on schedule with no crash to alert on. Enforce an internal hard timeout in the job itself:

```typescript
async function main() {
    const timeout = setTimeout(() => {
        console.error(JSON.stringify({ level: "error", message: "cron job exceeded timeout, forcing exit" }));
        process.exit(1);
    }, 4 * 60 * 1000).unref();

    await runCleanupJob();
    clearTimeout(timeout);
    process.exit(0); // explicit -- don't rely on the event loop draining naturally
}

main().catch((err) => {
    console.error(JSON.stringify({ level: "error", message: "cron job failed", error: String(err) }));
    process.exit(1);
});
```

Cron jobs are regular Railway services with cron scheduling enabled, not a distinct service type — same `railway.json`, same build, just a `cronSchedule` instead of an always-running process.

## Background workers

An always-on Railway service with no HTTP entrypoint (or a minimal one just for `/health` — see [health-and-lifecycle.md](health-and-lifecycle.md)). Typically talks to another service in the same project over Railway's private networking (`RAILWAY_PRIVATE_DOMAIN`) rather than the public internet. Use for anything that needs to react continuously — a Realtime subscription handler, a long-poll consumer, a streaming pipeline — where "run every N minutes" doesn't fit the workload.

Deploy it as its own Railway service within the project so it scales, restarts, and gets resource limits independently of the API server.

## Queue consumers

For work that needs retry, fan-out, or decoupling from the producer's request path. Two common backends in this stack:

- **Redis + BullMQ** — the default choice if Redis is already in the stack or throughput is high. A producer (often the API server) adds jobs; one or more worker services consume them.
- **Postgres + pg-boss** (or graphile-worker) — uses the existing Supabase Postgres as the queue backend. Fewer moving parts if Redis isn't otherwise needed, lower throughput than Redis-backed queues, but gets ACID guarantees for free.

**A queue consumer is a background worker, not a cron job.** A BullMQ worker holds an open Redis connection and blocks waiting for jobs — it's designed to never exit. Running it as a Railway cron job violates the "must exit" contract: either it gets killed mid-poll on the next scheduled overlap check, or it runs once and then Railway thinks the "job" (the whole long-lived process) is still in progress and skips every subsequent scheduled invocation.

```typescript
// worker.ts -- deployed as its own always-on Railway service
import { Worker } from "bullmq";

const worker = new Worker("emails", async (job) => {
    await sendEmail(job.data);
}, { connection: { url: process.env.REDIS_URL } });

process.on("SIGTERM", async () => {
    await worker.close(); // finishes the in-flight job, stops pulling new ones
    process.exit(0);
});
```

## Retry and backoff

Push retry policy into the queue library rather than hand-rolling it:

```typescript
await queue.add("send-email", payload, {
    attempts: 5,
    backoff: { type: "exponential", delay: 2000 }, // 2s, 4s, 8s, 16s, 32s
});
```

For anything without a queue library backing it (a plain cron job hitting a flaky external API), implement backoff explicitly rather than looping with a fixed delay — a fixed retry interval synchronizes retries across failures and can hammer a struggling downstream service.

Route jobs that exhaust retries to a dead-letter queue or a `failed_jobs` table rather than dropping them silently — someone needs to be able to find and reprocess them later.

## Idempotency

Any job that might run more than once (retries, at-least-once queue delivery, a cron execution that overlaps a slow previous run despite the skip behavior) needs to be safe to run twice:

- **Idempotency keys** for anything that calls an external API with side effects (payment charges, emails) — generate a stable key per logical operation and check/store it before acting.
- **Upserts instead of inserts** for anything writing rows keyed by a natural identifier — `on conflict do update`/`do nothing` rather than a bare `insert` that fails or duplicates on retry.
- **Dedupe by job ID** when consuming from a queue that guarantees at-least-once delivery — track processed job IDs (with a TTL) and skip anything already seen.

Idempotency is the property that makes "Railway skipped an overlapping cron run" or "the queue redelivered this job" a non-event instead of a data-corruption bug.

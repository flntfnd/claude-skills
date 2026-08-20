## Contents

- [Structured logging](#structured-logging)
- [What to log](#what-to-log)
- [Metrics](#metrics)
- [Traces](#traces)
- [Exporting beyond Railway](#exporting-beyond-railway)

## Structured logging

Railway parses and indexes JSON-formatted logs automatically — emit a log as a JSON object with fields like `level` and `message` (plus whatever custom attributes matter) and Railway's log viewer treats those fields as filterable/queryable, including preserving multi-line values like stack traces `[Verified — docs.railway.com/observability/logs]`. Plain `console.log("something happened")` strings still show up, but aren't structured — no filtering by field, no clean stack traces.

```typescript
console.log(JSON.stringify({
    level: "info",
    message: "job completed",
    jobId: job.id,
    durationMs: Date.now() - start,
}));
```

In practice, use a logging library that emits this shape by default rather than hand-building JSON strings at every call site — `pino` is a common choice for Node services and emits structured JSON out of the box with negligible overhead. Whatever library is chosen, avoid the pretty-printed/colorized transport in production — that format defeats Railway's log parsing.

## What to log

Tie every log line back to something identifiable:

- `RAILWAY_DEPLOYMENT_ID` / `RAILWAY_REPLICA_ID` — which deployment and instance emitted this, useful when multiple replicas are running
- A request ID or job ID, generated at the entry point (HTTP request, queue job, cron invocation) and threaded through every downstream log call for that unit of work
- Enough context to debug from logs alone: what operation, what identifiers (user/tenant/job), what outcome — without ever logging secrets, tokens, or full request bodies containing PII (per the repo's privacy rules in `CLAUDE.md`)

Log at service boundaries deliberately: request in / response out, job started / job completed or failed, external API call made / response received. Don't log inside tight loops or on every iteration of a batch operation — that's noise that buries the signal it's supposed to help find.

## Metrics

Railway tracks CPU, memory, and network usage per service automatically, no instrumentation required `[Verified — docs.railway.com]`. That covers infrastructure-level health. Application-level metrics (request latency percentiles, job queue depth, error rates by endpoint) need explicit instrumentation — Prometheus-style `/metrics` endpoint or a push-based metrics service, depending on where the metrics need to end up.

## Traces

For a service that calls other services (API → worker → external API, or a queue producer/consumer pair), request-scoped logs alone don't show the full path a request took. OpenTelemetry is the current standard approach: instrument the service, export traces to a backend (Honeycomb, Grafana Tempo, Jaeger, Datadog are all common choices), and carry the trace ID in structured logs so logs and traces can be cross-referenced `[Verified — blog.railway.com/p/using-logs-metrics-traces-and-alerts-to-understand-system-failures]`.

This is worth setting up once a service graph has more than one hop worth debugging together — a single standalone API server with no downstream services doesn't need full distributed tracing, structured logs with a request ID carry most of the same value at a fraction of the setup cost.

## Exporting beyond Railway

Railway's own log retention is not indefinite. For longer retention or centralized observability across multiple projects/services, export logs to an external platform — Datadog and Axiom are both explicitly supported destinations `[Verified — docs.railway.com/observability/logs]`. Worth setting up once logs matter for anything beyond immediate debugging (compliance retention windows, cross-service incident analysis, alerting rules that need history).

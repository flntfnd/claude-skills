## Contents

- [railway.json / railway.toml schema](#railwayjson--railwaytoml-schema)
- [Builder choice: Railpack vs Nixpacks vs Dockerfile](#builder-choice-railpack-vs-nixpacks-vs-dockerfile)
- [Environment variables and secrets](#environment-variables-and-secrets)
- [Railway-provided runtime variables](#railway-provided-runtime-variables)
- [Monorepo / multiple services in one repo](#monorepo--multiple-services-in-one-repo)

## railway.json / railway.toml schema

Config-as-code lives at the repo root as either `railway.json` or `railway.toml` — functionally identical, pick one `[Verified — docs.railway.com/config-as-code]`. Fields confirmed against the current reference:

```json
{
  "$schema": "https://railway.com/railway.schema.json",
  "build": {
    "builder": "RAILPACK",
    "buildCommand": null,
    "dockerfilePath": null,
    "watchPatterns": ["src/**", "package.json"]
  },
  "deploy": {
    "startCommand": "node dist/server.js",
    "preDeployCommand": ["npm run db:migrate"],
    "healthcheckPath": "/health",
    "healthcheckTimeout": 300,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 3,
    "cronSchedule": null,
    "drainingSeconds": 15,
    "overlapSeconds": 5
  }
}
```

| Field | Notes |
| --- | --- |
| `build.builder` | `"RAILPACK"` (current default) or `"DOCKERFILE"` |
| `build.buildCommand` | Overrides the builder's inferred build step |
| `build.dockerfilePath` | Non-standard Dockerfile location, when `builder` is `"DOCKERFILE"` |
| `build.watchPatterns` | Glob patterns — only trigger a redeploy when matching paths change. Essential in a monorepo (below) |
| `deploy.startCommand` | Overrides the builder's inferred start command |
| `deploy.preDeployCommand` | Runs before the new deployment takes traffic — migrations are the canonical use |
| `deploy.healthcheckPath` / `healthcheckTimeout` | See [health-and-lifecycle.md](health-and-lifecycle.md) |
| `deploy.restartPolicyType` / `restartPolicyMaxRetries` | See [health-and-lifecycle.md](health-and-lifecycle.md) |
| `deploy.cronSchedule` | Crontab expression — makes this service a cron job. See [background-jobs.md](background-jobs.md) |
| `deploy.drainingSeconds` | Same setting as `RAILWAY_DEPLOYMENT_DRAINING_SECONDS` |
| `deploy.overlapSeconds` | Same setting as `RAILWAY_DEPLOYMENT_OVERLAP_SECONDS` |
| `deploy.multiRegionConfig` | Per-region `numReplicas` for multi-region deploys |

`environments.[name]` blocks in the same file override any of the above per Railway environment (e.g. `staging`, and the special `pr` environment for PR previews). Priority resolution when the same field is set in multiple places: **environment-specific config-as-code → base config-as-code → dashboard settings** `[Verified — docs.railway.com/config-as-code/reference]`.

## Builder choice: Railpack vs Nixpacks vs Dockerfile

Railway's build landscape shifted in 2026: **Railpack** (a Go/BuildKit-based builder, launched in beta March 2026) is now the default for new projects, replacing **Nixpacks**, which Railway has put into maintenance mode `[Verified — blog.railway.com, checked Aug 2026]`. Existing projects on Nixpacks keep working; new projects get Railpack by default.

- **Railpack (default)** — zero-config for common languages (detects `package.json`, etc.). Smaller, faster, more cache-friendly builds than Nixpacks. Right choice for a standard Node service with no unusual build requirements.
- **Dockerfile** — full control, most portable, easiest to debug locally (`docker build` reproduces exactly what Railway runs). Reach for this once the build has real requirements Railpack's convention-based detection doesn't cover: native dependencies, multi-stage builds, a specific base image.
- **Nixpacks (legacy)** — don't pick it for new services. Existing services on it aren't broken and don't need an urgent migration, but new work should default to Railpack or a Dockerfile.

For a small standalone Railway service, Railpack's zero-config path is usually the right default. Reach for a Dockerfile when the build stops being simple — not preemptively.

## Environment variables and secrets

Railway's variable system, confirmed current `[Verified — docs.railway.com/guides/managing-secrets-on-railway]`:

| Type | Scope | Use for |
| --- | --- | --- |
| Service variable | One service, one environment | Per-service config and secrets |
| Shared variable | Project-wide, referenced by name | Values reused across services (e.g. a shared API key) |
| Reference variable | Points at another variable: `${{ shared.STRIPE_SECRET_KEY }}`, `${{ Postgres.DATABASE_URL }}` | Avoids duplicating a value Railway already knows (e.g. another service's connection string) |
| Sealed variable | Write-only — the dashboard shows `••••••` after save, never the real value again | Anything genuinely sensitive: `SUPABASE_SERVICE_ROLE_KEY`, API secrets, signing keys |

Sealed variables are deliberately excluded from PR/preview environments — a PR environment that needs to boot needs a separate, non-sealed test credential, not the production secret. Local development uses `railway run <command>` to inject the real variables at runtime without writing them to disk; sealed variables specifically won't be available this way, so local dev needs its own credential for anything sealed in production.

**Nothing sensitive belongs in `railway.json`/`railway.toml`.** That file is source-controlled. The practical test Railway's own docs suggest: would this value be fine pasted into a public GitHub repo? If not, it's a Railway variable, not a config-as-code value.

## Railway-provided runtime variables

Injected automatically, no setup required `[Verified — docs.railway.com/reference/variables]`:

| Variable | What it is |
| --- | --- |
| `PORT` | The port to bind — see [health-and-lifecycle.md](health-and-lifecycle.md) |
| `RAILWAY_SERVICE_NAME` / `RAILWAY_SERVICE_ID` | This service's name/id |
| `RAILWAY_DEPLOYMENT_ID` / `RAILWAY_REPLICA_ID` | Identifies this specific deployment/replica — useful in structured logs |
| `RAILWAY_ENVIRONMENT_NAME` / `RAILWAY_ENVIRONMENT_ID` | Which Railway environment this is (production/staging/pr-N/...) |
| `RAILWAY_PROJECT_NAME` / `RAILWAY_PROJECT_ID` | The project this service belongs to |
| `RAILWAY_PUBLIC_DOMAIN` | Public URL for the service, if exposed |
| `RAILWAY_PRIVATE_DOMAIN` | Internal DNS name for service-to-service calls over Railway's private network — use this for worker/API traffic instead of the public URL |
| `RAILWAY_TCP_PROXY_DOMAIN` / `RAILWAY_TCP_PROXY_PORT` / `RAILWAY_TCP_APPLICATION_PORT` | For services exposed via TCP proxy rather than HTTP |
| `RAILWAY_REPLICA_REGION` | Region this replica is running in |
| `RAILWAY_VOLUME_NAME` / `RAILWAY_VOLUME_MOUNT_PATH` | Attached volume info, if the service has one |
| `RAILWAY_DEPLOYMENT_DRAINING_SECONDS` | SIGTERM-to-SIGKILL grace period — see [health-and-lifecycle.md](health-and-lifecycle.md) |
| `RAILWAY_DEPLOYMENT_OVERLAP_SECONDS` | Old/new deployment overlap window during a deploy |
| `RAILWAY_HEALTHCHECK_TIMEOUT_SEC` | Mirrors `healthcheckTimeout` from config |

`RAILWAY_PRIVATE_DOMAIN` is worth calling out specifically: service-to-service calls within the same project (API server calling a worker, worker calling back to the API) should go over the private network, not round-trip through the public internet.

## Monorepo / multiple services in one repo

Railway handles a monorepo as multiple services within one project, each pointed at a subdirectory `[Verified — blog.railway.com/p/best-monorepo-deployment-platforms-2026]`:

- Set each service's **root directory** to its subfolder (`apps/api`, `apps/worker`, etc.) in the service settings.
- Use `build.watchPatterns` per service so a change to `apps/worker` doesn't trigger a rebuild of `apps/api`, and vice versa.
- Each service gets its own `railway.json` (at its root directory) or its own block if a single top-level config is used — per-service build/deploy settings, independent scaling, independent restart policy.
- Shared code (a `packages/shared` workspace package) works the same as any monorepo build — the builder just needs the workspace's install step to resolve it, which is where a Dockerfile earns its keep over Railpack's zero-config path once the build graph gets non-trivial.

For a typical shape in this stack — an API server, a worker, maybe a queue consumer — that's 2-3 Railway services in one project, one repo, sharing Railway's shared/reference variables for anything common (the Supabase connection info, for instance) rather than duplicating it per service.

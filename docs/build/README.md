# Build plan

A complete, hand-off-ready specification for the quick file sharing app described in
[`../file-sharing-brief.md`](../file-sharing-brief.md). Every document here is written so a
developer or an agent can open it, read the section for their lane, and start writing code
without asking a design question first.

Status: v1.0, September 2026. Nothing is built yet. The Figma design system exists and is
referenced where it matters, but no document here depends on opening Figma.

## Read in this order

| # | Document | Who needs it |
| --- | --- | --- |
| 01 | [Product spec](01-product-spec.md) | Everyone, first |
| 02 | [Architecture](02-architecture.md) | Everyone, first |
| 03 | [Data model](03-data-model.md) | Data lane |
| 04 | [Crypto spec](04-crypto-spec.md) | Transport lane, both clients |
| 05 | [API contract](05-api-contract.md) | Backend lane, frontend lane, Apple lane |
| 06 | [Peer-to-peer transport](06-transport-p2p.md) | Transport lane |
| 07 | [Cloud transport](07-transport-cloud.md) | Transport lane, backend lane |
| 08 | [Web app](08-web-app.md) | Frontend lane |
| 09 | [Apple apps](09-apple-apps.md) | Apple lane |
| 10 | [Plans and billing](10-billing-plans.md) | Backend lane |
| 11 | [Ops runbook](11-ops-runbook.md) | Whoever is on call |
| 12 | [Testing](12-testing.md) | Everyone |
| 13 | [Milestones](13-milestones.md) | Whoever is sequencing the work |
| 14 | [Decisions](14-decisions.md) | Everyone, when something looks arbitrary |

## The contracts that let lanes run in parallel

Four lanes can work at the same time once the schema is applied. They meet at exactly four
frozen contracts. Changing one of these is a pull request against this directory before it is
a pull request against code.

1. **Table shapes and RLS.** [03-data-model.md](03-data-model.md). The migration files are the
   source of truth; the document explains them.
2. **The Railway HTTP surface.** [05-api-contract.md](05-api-contract.md). Typed with Zod on
   the server and published as a shared package the clients import.
3. **The wire format.** [04-crypto-spec.md](04-crypto-spec.md). Header layout, chunk framing,
   manifest JSON, and the link format. Both the web client and the Apple client implement it,
   so it has cross-language test vectors.
4. **Storage key layout.** `{drop_id}/{file_id}` for drops, `{owner_id}/{node_id}` for drive
   objects. Nothing else writes to the bucket.

## Ground rules that apply to every lane

These come from [`../../CLAUDE.md`](../../CLAUDE.md) and are repeated because they are load
bearing here, not stylistic.

- **The server never sees plaintext.** If a feature needs the server to read file content, the
  feature is cut, not the encryption. This has already removed server-side previews, virus
  scanning, thumbnailing, and zip bundling from scope.
- **No IP addresses, user agents, or per-recipient identifiers** reach the database or the
  application logs, including in development. Coarse country on an event row is the maximum.
- **`service_role` lives on Railway only.** Vercel gets the anon key. The Apple apps get the
  anon key. RLS is the enforcement layer everywhere else.
- **Entitlements are decided by Railway**, never by a client, and never by trusting a field the
  client sent.
- **No hardcoded values** for color, spacing, type, radius, shadow, motion, or for limits and
  durations. Limits live in `plan_limits`; design values live in the token layer.
- **No analytics, telemetry, or third-party SDK that phones home.** There is nothing to opt
  into because nothing is collected.

## How to hand this off

To a developer: point them at 01 and 02, then the document for their lane, then
[13-milestones.md](13-milestones.md) for the task list and its acceptance criteria.

To an agent: the milestone entries in 13 are written as self-contained task prompts. Each one
names the files it touches, the contract documents it must obey, and the command that proves it
is done. A task is finished when its acceptance command exits zero, not when the code looks
right.

## What is deliberately not here

Naming, brand, marketing copy beyond the UI strings in 01, and the choice of analytics vendor
(there is none). The repository this ships in is also not decided; see
[14-decisions.md](14-decisions.md).

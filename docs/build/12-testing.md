# 12. Testing

What gets tested, what does not, and the commands that prove a task is done. Per the repo rules:
critical paths and business logic, integration over unit for UI and API boundaries, and mocks only
for external dependencies and I/O.

## What is not tested

Trivial getters, setters, pass-throughs, and React components with no logic. Anything mocked
purely to reach a coverage number. There is no coverage threshold and no coverage badge, because
this codebase has four or five places where a bug is catastrophic and a hundred where it is
cosmetic, and a single percentage cannot tell them apart.

## The five things that must never break

Every one of these has dedicated, adversarial tests. A change that touches one of them and does
not touch its tests is rejected in review.

1. **RLS.** No user can read another user's rows, through any table, function, or Realtime
   subscription.
2. **The crypto wire format.** Both implementations agree, byte for byte, and tampering fails.
3. **Expiry and the download cap.** A drop that should be dead is dead, atomically, under
   concurrency.
4. **Entitlements.** No client-supplied value can raise a ceiling.
5. **Key confinement.** No key material reaches a server, a log, a URL query string, or storage.

## Layers

### pgTAP, `supabase/tests/`

Runs against a fresh local database on every pull request. The full list is at the end of
[03-data-model.md](03-data-model.md); the shape is:

```sql
select plan(42);

select is_empty(
  $$ select * from drops where owner_id <> auth.uid() $$,
  'a user cannot see another user''s drops'
);

select throws_ok(
  $$ insert into drops (owner_id, slug, transport, kind, expires_at)
     values (auth.uid(), 'aaaaaaaaaa', 'cloud', 'file', now() + interval '8 days') $$,
  'plan_ceiling_expiry',
  'free plan cannot exceed 7 days'
);

select * from finish();
```

The concurrency test for `try_consume_download` runs 50 parallel sessions against a drop with
`max_downloads = 10` and asserts exactly 10 succeed. It is the one test that catches the race that
matters most.

### Crypto vectors, `packages/crypto/vectors/`

JSON fixtures run by both the TypeScript suite and the Swift test target. Listed in
[04-crypto-spec.md](04-crypto-spec.md). A vector that passes in one language and fails in the
other blocks the release. There is no "it works on web, we will fix Swift later".

### API contract tests, `apps/api/test/`

Every endpoint, every error code in the table in [05-api-contract.md](05-api-contract.md). Real
Postgres, real Storage against the local stack. Stripe and Cloudflare are the only mocks, because
they are the only things this suite does not own.

The tests that matter more than the happy paths:

- A recipient token for drop A cannot download from drop B.
- A manage secret for drop A cannot modify drop B.
- An anonymous user's token cannot seal another user's drop.
- `authorize` takes the same time for a wrong password and a missing drop.
- Every `plan_ceiling_*` fires at exactly the boundary, not one byte early or late.
- `seal` rejects an under-reported size.
- A revoked drop returns `410` from `download` within one request, not one sweep.

### Transport integration, `packages/transport-*/test/`

Headless, no UI. The peer-to-peer suite runs two browser contexts in Playwright against the
pre-installed Chromium. The cloud suite runs against the local Supabase stack.

Both suites' full test lists are in [06-transport-p2p.md](06-transport-p2p.md) and
[07-transport-cloud.md](07-transport-cloud.md).

The memory test deserves a note: it asserts peak heap stays under 200 MB while moving a 10 GB
file. It is slow, it runs nightly rather than per pull request, and it is the test that proves the
central technical claim of the product.

### End to end, `apps/web/e2e/`

Playwright. Not a re-test of the API; these cover the flows a user actually performs.

| Flow | Asserts |
| --- | --- |
| Anonymous cloud send | Folder in, link out, recipient downloads, structure preserved |
| Password protected | Wrong password fails, right password decrypts |
| Expiry edit | Extend from the management link, countdown updates on the recipient page |
| Revoke | Recipient page flips to the tombstone within one reload |
| Cap reached | Second download shows the cap message |
| Sign in and claim | Anonymous drops survive the upgrade to a real account |
| Peer to peer | Two contexts, sender offline and back, resume completes |
| Request mode | Stranger uploads, requester decrypts, stranger cannot read |
| Drive share | Share from drive, revoke the drop, drive copy intact |
| Account deletion | Every row and object is gone |

### Manual checklist per release

Some things cannot be automated in this environment and are checked by hand. The list is short on
purpose.

- Safari on macOS and iOS: cloud upload, download through the service-worker sink, password flow.
- Firefox: same.
- A real network transition mid-upload, wifi to cellular, on a phone.
- The macOS share extension from Finder, and the menu bar drop target.
- VoiceOver through the composer and the recipient page.
- The recovery key flow, including deliberately losing the passkey.

## Fixtures

| Fixture | Size | Purpose |
| --- | --- | --- |
| `tiny/` | 4 files, 12 KB | Fast path for most tests |
| `nested/` | 200 files, 8 levels deep, 40 MB | Structure preservation and manifest size |
| `unicode/` | Names with emoji, RTL, NFC and NFD pairs, 255-char names | Path normalization |
| `hostile/` | `../`, absolute paths, NUL, backslash, reserved Windows names | Manifest rejection |
| `large.bin` | 10 GB, generated, not committed | Memory and throughput |
| `empty.txt` | 0 bytes | The zero-length segment case |

`hostile/` is generated by a script rather than committed, because some of its names cannot exist
on every filesystem. That is the point of it.

## CI

```
 pull request:
   lint + typecheck            all packages
   secret grep                 fails on sb_secret_ or sk_live_ outside apps/api
   unit + vectors              packages/*
   pgTAP                       fresh local Supabase
   api contract                local stack
   e2e                         Chromium, tiny and nested fixtures only
   build                       web and api

 nightly:
   memory + throughput         large.bin, 10 GB
   p2p two-browser suite       full
   Safari and Firefox e2e      where the runner supports it

 pre-release:
   manual checklist
   smoke suite against preview
```

`next lint` no longer exists in Next.js 16, so ESLint is its own CI step and `next build` is not
relied on to catch lint errors.

## Definition of done for any task

A task is finished when its acceptance command exits zero, not when the code looks right. Every
milestone entry in [13-milestones.md](13-milestones.md) names its command. If a task has no
acceptance command, it is not specified well enough to start.

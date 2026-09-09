# 03. Data model

Complete schema, RLS, storage policies, and the functions that back the API. The SQL here is
copy-pasteable into `supabase/migrations/` as numbered, forward-only files. Nothing in this
document is illustrative; if the code and this document disagree, this document is wrong and
gets a pull request.

## Principles the schema enforces

1. **No plaintext.** There is no column for a file name, a folder name, a drop title, or a mime
   type. All of that lives inside `drops.encrypted_manifest`, which the server cannot read.
2. **No identity beyond `auth.uid()`.** No IP, no user agent, no referrer, no per-recipient row.
   Recipient sessions are stateless tokens signed by Railway and never stored.
3. **Sizes are rounded** to the nearest 64 KB before they are written, so exact sizes leak less.
   The exact size lives in the encrypted manifest.
4. **Limits are data, not code.** `plan_limits` is the single source, read by Railway and by RLS.
5. **RLS is on for every table**, including tables only Railway touches. A missing policy denies.

## Migration 0001: extensions, enums, helpers

```sql
create extension if not exists "pgcrypto";
create extension if not exists "pg_cron";

create type transport_kind as enum ('p2p', 'cloud');
create type drop_kind      as enum ('file', 'folder');
create type drop_mode      as enum ('send', 'request');
create type drop_status    as enum ('uploading', 'sealed', 'revoked', 'expired');
create type node_kind      as enum ('file', 'folder');
create type event_kind     as enum (
  'view', 'download_start', 'download_complete',
  'seal', 'extend', 'shorten', 'revoke', 'expire', 'report'
);

-- Round a byte count up to the nearest 64 KB. Every size column goes through this.
create or replace function public.round_bytes(b bigint)
returns bigint
language sql
immutable
parallel safe
as $$
  select ((b + 65535) / 65536) * 65536;
$$;
```

## Migration 0002: plan limits

```sql
create table public.plan_limits (
  plan                       text primary key,
  max_drop_bytes             bigint      not null,
  max_file_bytes             bigint      not null,
  max_files_per_drop         integer     not null,
  max_expiry                 interval    not null,
  allow_never_expiry         boolean     not null default false,
  max_active_drops           integer     not null,
  max_request_inbound_bytes  bigint      not null,
  drive_bytes                bigint      not null default 0,
  relay_bytes_per_month      bigint      not null,
  max_concurrent_recipients  integer     not null default 8,
  updated_at                 timestamptz not null default now()
);

insert into public.plan_limits values
  ('free', 5368709120,  5368709120,  2000,  interval '7 days',  false, 50,
           1073741824,  0,            107374182400, 8),
  ('paid', 53687091200, 53687091200, 20000, interval '365 days', true, 5000,
           10737418240, 1099511627776, 1099511627776, 16);

alter table public.plan_limits enable row level security;

-- Anyone may read the ceilings. They are public product information.
create policy plan_limits_read on public.plan_limits
  for select to anon, authenticated using (true);
```

Nothing but a migration writes to this table. Changing a number is a migration and a deploy, on
purpose, so a ceiling change is reviewable.

## Migration 0003: subscriptions and the plan resolver

```sql
create table public.subscriptions (
  user_id               uuid primary key references auth.users(id) on delete cascade,
  stripe_customer_id    text unique not null,
  stripe_subscription_id text unique,
  plan                  text not null references public.plan_limits(plan) default 'free',
  status                text not null default 'incomplete',
  current_period_end    timestamptz,
  cancel_at_period_end  boolean not null default false,
  updated_at            timestamptz not null default now()
);

alter table public.subscriptions enable row level security;

create policy subscriptions_read_own on public.subscriptions
  for select to authenticated using ((select auth.uid()) = user_id);
-- No insert, update, or delete policy. Only the secret key writes here.

-- The one function every entitlement check goes through.
create or replace function public.current_plan(p_user uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select s.plan
       from public.subscriptions s
      where s.user_id = p_user
        and s.status in ('active', 'trialing')
        and (s.current_period_end is null or s.current_period_end > now())),
    'free'
  );
$$;

revoke execute on function public.current_plan(uuid) from public;
grant execute on function public.current_plan(uuid) to authenticated, service_role;
```

A subscription that is `past_due` still resolves to `free` for new drops but does not delete
anything. The grace behavior is in [10-billing-plans.md](10-billing-plans.md).

## Migration 0004: drops

```sql
create table public.drops (
  id                 uuid primary key default gen_random_uuid(),
  owner_id           uuid not null references auth.users(id) on delete cascade,
  slug               text not null unique,
  transport          transport_kind not null,
  kind               drop_kind      not null,
  mode               drop_mode      not null default 'send',
  status             drop_status    not null default 'uploading',

  allow_direct       boolean not null default false,

  encrypted_manifest bytea,

  expires_at         timestamptz,
  never_expires      boolean not null default false,
  max_downloads      integer,
  download_count     integer not null default 0,
  view_count         integer not null default 0,

  password_salt      bytea,
  password_verifier  bytea,
  password_params    jsonb,

  request_public_key bytea,

  size_bytes         bigint  not null default 0,
  file_count         integer not null default 0,

  created_at         timestamptz not null default now(),
  sealed_at          timestamptz,
  ended_at           timestamptz,
  ended_reason       text,

  constraint slug_shape        check (slug ~ '^[0-9abcdefghjkmnpqrstvwxyz]{10}$'),
  constraint expiry_exclusive  check (never_expires <> (expires_at is not null)),
  constraint cap_positive      check (max_downloads is null or max_downloads > 0),
  constraint sealed_has_manifest
    check (status <> 'sealed' or encrypted_manifest is not null),
  constraint password_complete
    check ((password_verifier is null) = (password_salt is null)),
  constraint direct_is_p2p_only
    check (allow_direct = false or transport = 'p2p'),
  constraint request_has_key
    check (mode <> 'request' or request_public_key is not null)
);

create index drops_owner_created_idx
  on public.drops (owner_id, created_at desc);

create index drops_sweep_idx
  on public.drops (expires_at)
  where status in ('uploading', 'sealed') and never_expires = false;

alter table public.drops enable row level security;

create policy drops_select_own on public.drops
  for select to authenticated
  using ((select auth.uid()) = owner_id);

create policy drops_insert_own on public.drops
  for insert to authenticated
  with check ((select auth.uid()) = owner_id);

create policy drops_update_own on public.drops
  for update to authenticated
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

create policy drops_delete_own on public.drops
  for delete to authenticated
  using ((select auth.uid()) = owner_id);
```

The slug alphabet is Crockford base32 without `i`, `l`, `o`, and `u`, so a slug read aloud or
written down does not collide with a lookalike and cannot spell an English obscenity. Ten
characters is 50 bits, which makes enumeration pointless against a rate-limited endpoint.

Note what is **not** here: no title, no file names, no IP, no user agent, no recipient table.

### The client cannot raise its own ceiling

RLS above lets a signed-in user insert any row they own, including one with a 10 year expiry.
That is deliberate: the API is the only writer in practice, and defense in depth lives in a
trigger rather than in a policy, because a policy cannot read `plan_limits` cheaply per row.

```sql
create or replace function public.enforce_drop_ceilings()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  lim public.plan_limits%rowtype;
begin
  select * into lim
    from public.plan_limits
   where plan = public.current_plan(new.owner_id);

  if new.never_expires and not lim.allow_never_expiry then
    raise exception 'plan_ceiling_expiry' using errcode = 'check_violation';
  end if;

  if new.expires_at is not null and new.expires_at > now() + lim.max_expiry then
    raise exception 'plan_ceiling_expiry' using errcode = 'check_violation';
  end if;

  if new.size_bytes > lim.max_drop_bytes then
    raise exception 'plan_ceiling_size' using errcode = 'check_violation';
  end if;

  if new.file_count > lim.max_files_per_drop then
    raise exception 'plan_ceiling_file_count' using errcode = 'check_violation';
  end if;

  new.size_bytes := public.round_bytes(new.size_bytes);
  return new;
end;
$$;

create trigger drops_enforce_ceilings
  before insert or update on public.drops
  for each row execute function public.enforce_drop_ceilings();
```

The trigger fires for `service_role` too. Railway is trusted to be correct, not trusted to be
bug free.

## Migration 0005: files, events, management secrets

```sql
create table public.drop_files (
  id            uuid primary key default gen_random_uuid(),
  drop_id       uuid not null references public.drops(id) on delete cascade,
  storage_key   text,
  size_bytes    bigint not null default 0,
  drive_node_id uuid,
  created_at    timestamptz not null default now(),
  constraint cloud_has_key check (storage_key is not null or drive_node_id is not null
                                  or size_bytes = 0)
);

create index drop_files_drop_idx on public.drop_files (drop_id);

alter table public.drop_files enable row level security;

create policy drop_files_select_own on public.drop_files
  for select to authenticated
  using (exists (select 1 from public.drops d
                  where d.id = drop_id and d.owner_id = (select auth.uid())));

create policy drop_files_write_own on public.drop_files
  for all to authenticated
  using (exists (select 1 from public.drops d
                  where d.id = drop_id and d.owner_id = (select auth.uid())))
  with check (exists (select 1 from public.drops d
                       where d.id = drop_id and d.owner_id = (select auth.uid())
                         and d.status = 'uploading'));

create table public.drop_events (
  id         bigint generated always as identity primary key,
  drop_id    uuid not null references public.drops(id) on delete cascade,
  kind       event_kind not null,
  country    char(2),
  created_at timestamptz not null default now()
);

create index drop_events_drop_idx on public.drop_events (drop_id, created_at desc);

alter table public.drop_events enable row level security;

create policy drop_events_select_own on public.drop_events
  for select to authenticated
  using (exists (select 1 from public.drops d
                  where d.id = drop_id and d.owner_id = (select auth.uid())));
-- Inserts come from the secret key only. No policy.

create table public.drop_manage (
  drop_id     uuid primary key references public.drops(id) on delete cascade,
  secret_hash bytea not null,
  created_at  timestamptz not null default now()
);

alter table public.drop_manage enable row level security;
-- No policy at all. Only the secret key reads or writes this table.
```

`drop_events` is added to the Realtime publication so the dashboard sees live counts:

```sql
alter publication supabase_realtime add table public.drop_events;
```

RLS applies to Realtime, so a sender only receives events for drops they own.

## Migration 0006: request-mode upload slots

Request mode lets a stranger upload into a drop. Rather than opening a broad storage policy,
Railway pre-authorizes each file and RLS checks the slot.

```sql
create table public.request_slots (
  id         uuid primary key default gen_random_uuid(),
  drop_id    uuid not null references public.drops(id) on delete cascade,
  max_bytes  bigint not null,
  used_bytes bigint not null default 0,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);

create index request_slots_drop_idx on public.request_slots (drop_id);

alter table public.request_slots enable row level security;
-- Written by the secret key. Read by the storage policy through a definer function.

create or replace function public.request_slot_open(p_slot uuid, p_drop uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
      from public.request_slots s
      join public.drops d on d.id = s.drop_id
     where s.id = p_slot
       and s.drop_id = p_drop
       and s.expires_at > now()
       and d.mode = 'request'
       and d.status in ('uploading', 'sealed')
       and (d.never_expires or d.expires_at > now())
  );
$$;

grant execute on function public.request_slot_open(uuid, uuid) to authenticated;
```

## Migration 0007: the public projection

The only thing an unauthenticated recipient can read, and the only reason `anon` has any grant
at all.

```sql
create or replace function public.get_public_drop(p_slug text)
returns table (
  slug               text,
  transport          transport_kind,
  kind               drop_kind,
  mode               drop_mode,
  status             drop_status,
  allow_direct       boolean,
  encrypted_manifest bytea,
  size_bytes         bigint,
  file_count         integer,
  expires_at         timestamptz,
  never_expires      boolean,
  max_downloads      integer,
  download_count     integer,
  requires_password  boolean,
  password_salt      bytea,
  password_params    jsonb,
  ended_at           timestamptz,
  ended_reason       text,
  request_public_key bytea
)
language sql
stable
security definer
set search_path = public
as $$
  select
    d.slug, d.transport, d.kind, d.mode, d.status, d.allow_direct,
    case when d.status = 'sealed' then d.encrypted_manifest else null end,
    d.size_bytes, d.file_count,
    d.expires_at, d.never_expires, d.max_downloads, d.download_count,
    d.password_verifier is not null,
    d.password_salt, d.password_params,
    d.ended_at, d.ended_reason, d.request_public_key
  from public.drops d
  where d.slug = p_slug;
$$;

revoke execute on function public.get_public_drop(text) from public;
grant execute on function public.get_public_drop(text) to anon, authenticated;
```

What it deliberately returns for a dead drop: the row, with `status` and `ended_reason`, and no
manifest. That is what makes P-18's honest end-of-life page possible without leaking anything.

`password_salt` and `password_params` are public on purpose. The recipient needs them to derive
the unwrap key before they can prove anything, and they are useless without the password.

## Migration 0008: atomic download consumption

The download cap has to be race free. One statement does the check and the increment.

```sql
create or replace function public.try_consume_download(p_drop uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  ok boolean;
begin
  update public.drops
     set download_count = download_count + 1
   where id = p_drop
     and status = 'sealed'
     and (never_expires or expires_at > now())
     and (max_downloads is null or download_count < max_downloads)
  returning true into ok;

  return coalesce(ok, false);
end;
$$;

revoke execute on function public.try_consume_download(uuid) from public;
grant execute on function public.try_consume_download(uuid) to service_role;
```

Only Railway may call it. A `false` return maps to `410 Gone` with a reason derived from a
follow-up read.

## Migration 0009: the sweeper

```sql
create or replace function public.expire_due_drops(p_limit integer default 500)
returns table (drop_id uuid, storage_key text)
language plpgsql
security definer
set search_path = public
as $$
begin
  -- 1. Transition everything that is due.
  with due as (
    select d.id
      from public.drops d
     where d.status in ('uploading', 'sealed')
       and d.never_expires = false
       and d.expires_at <= now()
     order by d.expires_at
     limit p_limit
     for update skip locked
  ),
  ended as (
    update public.drops d
       set status = 'expired',
           ended_at = now(),
           ended_reason = 'expired',
           encrypted_manifest = null
      from due
     where d.id = due.id
    returning d.id
  )
  insert into public.drop_events (drop_id, kind)
  select id, 'expire' from ended;

  -- 2. Return every object that still needs deleting. This deliberately includes
  --    drops ended by an earlier pass whose storage delete failed, so a retry
  --    picks them up instead of orphaning them.
  return query
    select f.drop_id, f.storage_key
      from public.drop_files f
      join public.drops d on d.id = f.drop_id
     where d.status in ('expired', 'revoked')
       and f.storage_key is not null
     limit p_limit * 20;
end;
$$;

revoke execute on function public.expire_due_drops(integer) from public;
grant execute on function public.expire_due_drops(integer) to service_role;
```

Railway calls this, deletes the returned storage keys from the bucket, then deletes the
`drop_files` rows. The `drops` row survives as the tombstone, with the manifest nulled, so the
link keeps explaining itself and nothing about the contents remains.

The function is split into a transition step and a return step for a reason. If the storage
delete fails halfway, the `drop_files` rows are still there and the next pass returns them again,
because step 2 selects on drop status rather than on what step 1 just changed. Marking a drop
expired and losing track of its objects is the failure mode this shape exists to prevent.

Revocation is the same shape with `ended_reason = 'revoked'`; see the API contract.

## Migration 0010: drive

```sql
create table public.drive_nodes (
  id                  uuid primary key default gen_random_uuid(),
  owner_id            uuid not null references auth.users(id) on delete cascade,
  parent_id           uuid references public.drive_nodes(id) on delete cascade,
  kind                node_kind not null,
  storage_key         text,
  size_bytes          bigint not null default 0,
  encrypted_meta      bytea not null,
  wrapped_content_key bytea,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz,
  constraint folder_has_no_object
    check (kind = 'file' or (storage_key is null and wrapped_content_key is null)),
  constraint file_has_object
    check (kind = 'folder' or (storage_key is not null and wrapped_content_key is not null))
);

create index drive_nodes_owner_parent_idx
  on public.drive_nodes (owner_id, parent_id) where deleted_at is null;

alter table public.drive_nodes enable row level security;

create policy drive_nodes_all_own on public.drive_nodes
  for all to authenticated
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id
              and public.current_plan((select auth.uid())) = 'paid');

create table public.account_keys (
  user_id             uuid primary key references auth.users(id) on delete cascade,
  root_key_id         uuid not null default gen_random_uuid(),
  wrapped_by_recovery bytea not null,
  wrapped_by_password bytea,
  password_salt       bytea,
  password_params     jsonb,
  wrapped_by_prf      bytea,
  prf_credential_id   bytea,
  prf_salt            bytea,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

alter table public.account_keys enable row level security;

create policy account_keys_all_own on public.account_keys
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create or replace function public.drive_usage(p_user uuid)
returns bigint
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(sum(size_bytes), 0)
    from public.drive_nodes
   where owner_id = p_user and kind = 'file' and deleted_at is null;
$$;
```

Every value in `account_keys` is a wrapped blob. Losing all three wraps means the data is
unrecoverable, which the UI says in plain words at activation (P-34).

## Migration 0011: relay usage, abuse, rate limits

```sql
create table public.relay_usage (
  owner_id uuid not null references auth.users(id) on delete cascade,
  month    date not null,
  bytes    bigint not null default 0,
  primary key (owner_id, month)
);
alter table public.relay_usage enable row level security;
create policy relay_usage_read_own on public.relay_usage
  for select to authenticated using ((select auth.uid()) = owner_id);

create table public.abuse_reports (
  id         uuid primary key default gen_random_uuid(),
  drop_id    uuid not null references public.drops(id) on delete cascade,
  reason     text not null,
  created_at timestamptz not null default now()
);
alter table public.abuse_reports enable row level security;
-- No policies. Secret key only. No reporter identity is stored, by design.

create table public.rate_buckets (
  key_hash     bytea      not null,
  window_start timestamptz not null,
  count        integer    not null default 0,
  primary key (key_hash, window_start)
);
alter table public.rate_buckets enable row level security;
```

`key_hash` is `HMAC(daily_salt, fingerprint)` computed on Railway, where `daily_salt` rotates at
midnight UTC and the previous salt is discarded. Rows older than two windows are deleted by the
sweeper. Nothing in this table survives long enough or is reversible enough to identify anyone.

## Storage buckets and policies

Two private buckets. Keeping drive objects out of the drops bucket makes both policies short,
which is the point.

| Bucket | Key layout | Written by | Read by |
| --- | --- | --- | --- |
| `drops` | `{drop_id}/{file_id}` | owner over TUS, or request uploader with a slot | signed URL only |
| `drive` | `{owner_id}/{node_id}` | owner over TUS | owner, and signed URL for shares |

```sql
insert into storage.buckets (id, name, public) values
  ('drops', 'drops', false),
  ('drive', 'drive', false);

-- Owner uploads into their own drop while it is still uploading.
create policy "drops insert by owner"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'drops'
  and exists (
    select 1 from public.drops d
     where d.id::text = (storage.foldername(name))[1]
       and d.owner_id = (select auth.uid())
       and d.status = 'uploading'
  )
);

-- Request-mode uploads: the file id must match an open, unexpired slot.
create policy "drops insert by request slot"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'drops'
  and public.request_slot_open(
        (storage.filename(name))::uuid,
        ((storage.foldername(name))[1])::uuid
      )
);

-- Owners may replace an object only while the drop is still uploading.
create policy "drops update by owner"
on storage.objects for update to authenticated
using (
  bucket_id = 'drops'
  and exists (
    select 1 from public.drops d
     where d.id::text = (storage.foldername(name))[1]
       and d.owner_id = (select auth.uid())
       and d.status = 'uploading'
  )
);

-- Nobody selects from `drops` with a user token. Downloads are signed URLs from Railway.

create policy "drive all by owner"
on storage.objects for all to authenticated
using (
  bucket_id = 'drive'
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id = 'drive'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and public.current_plan((select auth.uid())) = 'paid'
);
```

Storage policies that join a table are slow at scale. `drops.id` is the primary key so the join
is an index lookup, and the policy runs once per upload creation, not per chunk. If TUS
creation latency ever becomes a problem, replace the `exists` with a `security definer` function
the same way `request_slot_open` does it.

## Scheduled jobs

Two, both owned by Railway rather than `pg_cron`, so that failures surface in one place and the
storage deletes and row updates stay in the same process.

| Job | Interval | What it does |
| --- | --- | --- |
| sweep | 5 minutes | `expire_due_drops`, delete objects, delete `drop_files`, prune `rate_buckets` |
| orphans | daily | delete storage objects with no `drop_files` row, and anonymous users with no drops older than 30 days |

`pg_cron` is installed anyway because the orphan job's anonymous-user cleanup is a plain SQL
delete and is safer to run inside the database.

## Realtime

| Channel | Kind | Who |
| --- | --- | --- |
| `drop:{sha256(slug)[0:16]}` | Broadcast, private | sender and recipients of one p2p drop |
| `drop_events` | Postgres changes | the owning sender, filtered by RLS |

Broadcast authorization is RLS on `realtime.messages`:

```sql
create policy "signaling read"
on realtime.messages for select to authenticated
using (realtime.messages.extension = 'broadcast');

create policy "signaling write"
on realtime.messages for insert to authenticated
with check (realtime.messages.extension = 'broadcast');
```

This is intentionally permissive: the channel name is derived from a slug that only link holders
know, and every payload on it is encrypted with a key derived from the drop key. Supabase sees
opaque blobs on an unguessable topic. Tightening this to a per-drop policy would require putting
the slug into a readable table for `anon`, which leaks more than it protects. Recorded in
[14-decisions.md](14-decisions.md).

## pgTAP coverage required before the data lane is done

Every one of these is a test, not a checklist item. See [12-testing.md](12-testing.md).

- An anonymous user cannot select another user's drop, drop_files, drop_events, or drive node.
- `get_public_drop` returns a manifest only when `status = 'sealed'`.
- `get_public_drop` returns a tombstone shape for revoked and expired drops.
- `try_consume_download` returns false at the cap, on expiry, and on revocation, and is race
  free under 50 concurrent calls.
- The ceiling trigger rejects a free-plan drop with an 8 day expiry, a 6 GB size, and
  `never_expires`.
- `current_plan` returns `free` for `past_due` and for an expired period end.
- A storage insert into another user's drop folder is denied.
- A request-slot insert is denied once the slot expires.
- `expire_due_drops` nulls the manifest, keeps the row, and returns the storage keys.
- `expire_due_drops` returns the same keys again on a second call when the caller did not delete
  the `drop_files` rows, so a failed storage delete is retried rather than orphaned.
- `drive_nodes` insert is denied for a free-plan user.

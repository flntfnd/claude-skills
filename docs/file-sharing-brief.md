# Quick file sharing app: product and architecture brief

Status: brainstorm, v0.1 (September 2026). Nothing here is built yet.

## Thesis

One drop, one link. The product is not a drive. There is no folder tree to maintain, no sync client, no "my files" that grows forever. Every interaction starts with a file or folder on the sender's machine and ends with a link that dies on its own.

Dropbox and OneDrive optimize for *keeping*. WeTransfer, Smash, Wormhole, and SwissTransfer optimize for *sending*, but each gives up something: folder structure gets flattened into a zip, encryption is either absent or all-or-nothing, expiry is a footnote, and revocation usually needs a paid plan. This app treats the send itself as the whole product and gets the four things they compromise on right.

## What makes it different

1. **Folder-native.** Drag a folder in and the recipient sees the folder, browsable, with per-file download or a one-click bundle. Structure survives. Nobody zips first.
2. **Expiry and revocation are the default, not a setting.** Every drop has a lifetime (default 7 days) and a kill switch. The sender sees views and downloads as they happen and can end the drop with one tap.
3. **End-to-end encryption per drop.** Toggle on a drop and the files are encrypted in the browser with a key that lives only in the URL fragment. The server never sees plaintext bytes or filenames. Trade: no server-side previews or bundling for those drops.
4. **No account to receive. Optional account to manage.** Recipients never sign up. Senders can share anonymously; signing in later claims the drops they already made.
5. **Resumable uploads, large files.** Multi-gigabyte drops resume after a dropped connection. Uploads never pass through the web server.
6. **Request mode.** A reverse link where other people upload into a drop that only the requester can open. Same expiry and encryption rules.

Deliberately out of scope: sync clients, file editing, comments, version history, team folders, and anything that turns this into a drive.

## Primary flows

### Sender

```
┌──────────────────────────────────────────────────────┐
│  Drop files or a folder here                          │
│  ┌──────────────────────────────────────────────┐    │
│  │            ⬇  drag, paste, or browse          │    │
│  └──────────────────────────────────────────────┘    │
│  Expires   [7 days ▾]      Downloads  [unlimited ▾]  │
│  Password  [off]           Encrypt end-to-end [off]  │
│                                                       │
│  ▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░  2.1 GB of 3.4 GB  resumable   │
│                                                       │
│  https://…/d/8kq2ma      [Copy link]  [QR]  [Email]   │
└──────────────────────────────────────────────────────┘
```

The link exists before the upload finishes. The recipient page shows "still uploading" until the manifest is sealed.

### Recipient

```
┌──────────────────────────────────────────────────────┐
│  Q3 brand assets                    expires in 6 days │
│  from Rob · 3.4 GB · 42 files                          │
│ ┌────────────────────────────────────────────────────┐│
│ │ ▸ logos/                    12 files      18 MB    ││
│ │ ▸ photography/              24 files     3.2 GB    ││
│ │   guidelines.pdf                          4 MB     ││
│ │   README.md                               2 KB     ││
│ └────────────────────────────────────────────────────┘│
│                     [Download all]  [Download selected]│
└──────────────────────────────────────────────────────┘
```

No login, no app install, no "sign up to download". Password-protected drops show a single password field first. Encrypted drops decrypt in the browser and stream straight to disk.

### Sender dashboard (signed-in only)

A flat list of drops, newest first: title, size, expiry countdown, views, downloads, and a revoke button. That is the entire management surface.

## Architecture

Follows the repo lane rules exactly. Each service has one job.

```
 browser ──TUS chunks──────────────▶ Supabase Storage (private bucket)
    │                                       ▲
    │ anon key + RLS                        │ service_role, signed URLs
    ▼                                       │
 Vercel / Next.js 16 ──JWT──▶ Railway API ──┘
    │                            │
    │                            ├── expiry sweeper (cron)
    │                            ├── bundler (folder → zip stream)
    │                            └── scanner / thumbnailer (queue)
    ▼
 Supabase Postgres + Auth + Realtime
```

### Vercel (Next.js 16, App Router)

Landing, sender UI, recipient page, dashboard. Anon key only, RLS enforced. Server Components by default; the upload widget and the decryption path are Client Components at the leaves. Vercel is never in the byte path for uploads or downloads.

### Supabase

- **Auth.** Anonymous sign-in for senders who do not want an account. This gives every sender a real `auth.uid()` so RLS works for anonymous drops without any special casing. Magic link or passkey later converts the anonymous user and keeps their drops. `@supabase/ssr` for cookie sessions.
- **Postgres.** Source of truth for drops, files, and access events. RLS on every table.
- **Storage.** One private bucket. Uploads go browser to Storage directly over TUS (resumable, 6 MB chunks). Object paths are `{drop_id}/{file_id}`; a storage policy allows inserts only where the drop is owned by `auth.uid()` and still in `uploading` state. Downloads use short-lived signed URLs minted by Railway. Storage caps: 50 MB per file on the free plan, configurable up to 500 GB on Pro, 50 GB per file over resumable uploads.
- **Realtime.** Sender dashboard subscribes to its own drops' event rows for live view and download counts. Low frequency, fits the WAL model.
- **Edge Functions.** A DB trigger side effect when a drop is sealed (enqueue scan and thumbnail jobs). Nothing heavy.

### Railway (TypeScript/Node, or Rust if the bundler gets hot)

Verifies Supabase JWTs against the project JWKS. Holds `service_role`. Four responsibilities:

1. **Download authorization.** `POST /drops/:slug/download` checks status, expiry, download cap, and password (argon2id hash, constant-time), records the event, and returns a 60 second signed URL. This is the only place a plaintext password is ever compared.
2. **Bundling.** Streams a zip of a folder drop straight from Storage to the client without buffering whole files. Skipped for encrypted drops (the client builds the archive locally instead).
3. **Expiry sweeper.** Railway cron, every 15 minutes: mark expired drops, delete their objects, keep a tombstone row so the link returns a clean "this drop has ended" instead of a 404.
4. **Post-upload jobs.** Queue consumer (pg-boss) for malware scanning and image thumbnails on non-encrypted drops. Idempotent per file.

### Data model (first cut)

```
drops           id, owner_id, slug, title, kind (file|folder), mode (send|request),
                status (uploading|sealed|revoked|expired), e2e bool,
                expires_at, max_downloads, download_count, password_hash,
                size_bytes, file_count, created_at, sealed_at
drop_files      id, drop_id, path, size_bytes, mime, storage_key, sha256,
                encrypted_meta (bytea, e2e only: encrypted name and mime)
drop_events     id, drop_id, kind (view|download|revoke|expire), created_at,
                country (coarse, optional)
```

No IP addresses, no user agents, no per-recipient identity anywhere. The privacy rules in CLAUDE.md apply to the event log too: counts and coarse geography only.

### Recipient reads without an account

Recipients hit the drop page with no session. Instead of opening the `drops` table to `anon` selects, a `security definer` function `get_public_drop(slug)` returns only the public projection (title, size, file list, expiry, whether a password is required) and only when the drop is sealed and unexpired. RLS stays closed on the base tables.

### End-to-end mode

- Sender's browser generates a 256-bit AES-GCM key, encrypts each file as a stream with per-chunk nonces, and encrypts a manifest (filenames, paths, mimes). The key goes in the URL fragment, which browsers never send to the server.
- Recipient's browser fetches ciphertext via signed URL, decrypts through a `TransformStream`, and writes to disk with the File System Access API where available (Chromium), falling back to a service-worker-mediated streaming download elsewhere. Memory stays flat regardless of file size.
- Password protection still works on top: it gates the signed URL, the fragment key gates the bytes.
- Server-side previews, thumbnails, scanning, and bundling are all skipped for these drops, and the UI says so at toggle time.

## Phasing

| Phase | Scope | Exit criteria |
| --- | --- | --- |
| 0 | Figma design (sender, recipient, dashboard, light and dark), schema and RLS written and tested | Design signed off; RLS and JWT verification paths have tests |
| 1 | Anonymous send: file or folder, resumable upload, link, expiry, download, sweeper | A 10 GB folder round-trips on a flaky connection |
| 2 | Accounts, dashboard, revoke, password, download caps, streamed folder zip, Realtime counts | Signed-in sender can manage and kill drops |
| 3 | End-to-end mode, request mode | Encrypted 10 GB drop decrypts with flat memory in Chromium and Safari |
| 4 | Apple share extension and menu bar app (SwiftUI, iOS/macOS 26) | Drop from Finder or the share sheet without opening a browser |

## Parallel workstreams for the build

Three lanes that can run concurrently once Phase 0 design is done:

- **Data lane.** Supabase migrations, RLS policies, storage policies, `get_public_drop`, pgTAP tests for the auth and RLS paths.
- **Backend lane.** Railway service: JWT verification, download authorization, bundler, sweeper, queue consumer, health check and graceful shutdown per `backend-conventions`.
- **Frontend lane.** Next.js app against the Figma design: upload widget with TUS, recipient page, dashboard, streaming decrypt path.

Contracts between lanes (table shapes, the Railway API surface, storage key layout) are fixed in this document before the lanes split.

## Open decisions

1. **Encryption default.** Opt-in per drop (recommended: keeps previews, bundling, and scanning for the common case) versus always-on (Wormhole model: simpler trust story, loses all server-side conveniences).
2. **Where the code lives.** Assumed: a new repository, not this skills repo.
3. **Name.** Not chosen. Candidates should be short, verb-like, and not collide with the incumbents.
4. **Visual direction.** Default is the web platform's own conventions per CLAUDE.md. If a `visual-styles` style is wanted, it needs to be named before Figma work starts.

## Sources

- Supabase Storage resumable uploads and limits: https://supabase.com/docs/guides/storage/uploads/resumable-uploads and https://supabase.com/docs/guides/storage/uploads/file-limits
- Supabase Storage v3 (50 GB resumable): https://supabase.com/blog/storage-v3-resumable-uploads
- Next.js 16 LTS status: https://nextjs.org/support-policy
- Streaming client-side decryption pattern: https://transcend.io/blog/open-sourcing-penumbra
- Competitive landscape: https://blog.bytesizedsecurity.show/2026/07/09/wetransfer-alternatives-2026-privacy-first/

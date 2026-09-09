# 07. Cloud transport

`packages/transport-cloud`. Ciphertext goes from the browser straight to Supabase Storage over
resumable uploads. Bytes never touch Vercel and never touch Railway.

## Upload

### Why TUS and not the plain upload

Standard `upload()` handles files up to about 5 GB but has no resume. This app routinely moves
multi-gigabyte folders on connections that drop. Supabase's resumable endpoint speaks TUS 1.0 and
is the documented path for anything above 6 MB.

### Client

`tus-js-client` directly. Supabase's JS client has no TUS wrapper, and `uploadToSignedUrl` is a
different, non-resumable path that is only used for request-mode slots.

```ts
const upload = new tus.Upload(encryptedStream, {
  endpoint: `${projectRef}.storage.supabase.co/storage/v1/upload/resumable`,
  headers: {
    authorization: `Bearer ${accessToken}`,
    'x-upsert': 'false',
  },
  metadata: {
    bucketName: 'drops',
    objectName: `${dropId}/${fileId}`,
    contentType: 'application/octet-stream',
    cacheControl: '0',
  },
  chunkSize: 6 * 1024 * 1024,
  uploadDataDuringCreation: true,
  removeFingerprintOnSuccess: true,
  retryDelays: [0, 1000, 3000, 5000, 10000, 20000],
  onProgress,
  onError,
  onSuccess,
})
```

Four of those are load bearing and must not be changed:

- **`chunkSize` is exactly 6 MB.** Supabase's documentation still says it must be, and a different
  value fails in ways that look like network errors.
- **The dedicated storage hostname**, `{ref}.storage.supabase.co`, not `{ref}.supabase.co`. It is
  the documented throughput path.
- **`removeFingerprintOnSuccess: true`**, or re-uploading the same file in the same browser
  silently resumes a finished upload and does nothing.
- **`contentType: 'application/octet-stream'`** always. Every object is ciphertext. Passing a real
  mime type would leak what the file is and would be a lie about the bytes.

An upload URL is valid for 24 hours and accepts exactly one client at a time. A second client on
the same URL gets `409`, which the retry logic must treat as fatal rather than retrying.

### Pipeline

```
 File.stream()
   → 256 KiB plaintext segments
     → Worker: AES-GCM segment encrypt + BLAKE3 update
       → envelope framing (33 byte header, then segments)
         → tus.Upload, 6 MB chunks
           → Supabase Storage, drops/{drop_id}/{file_id}
```

The crypto segment size and the TUS chunk size are unrelated numbers that happen to be nested. Do
not couple them. 6 MB is 24 crypto segments plus change, and neither side cares.

Concurrency: three files in flight, chosen because Supabase throttles per connection rather than
per object and three saturates a typical uplink without starving the encryption worker. It is a
constant in the package, not a magic number in the app.

### Sequence

```
 1. POST /v1/drops                     → { id, slug, upload: { endpoint, prefix } }
 2. for each file, in parallel (3):
      encrypt → TUS upload to drops/{id}/{file_id}
 3. build manifest, encrypt with MK
 4. POST /v1/drops/{id}/seal           → status becomes 'sealed'
 5. show https://host/d/{slug}#{fragment}
```

The link is copyable from step 1. The recipient page shows "still uploading" until step 4, which
is why `get_public_drop` withholds the manifest for an unsealed drop rather than 404ing.

If the tab closes between 1 and 4, the drop stays `uploading`, the sweeper expires it on schedule,
and its objects are deleted. There is no orphan.

### Request-mode uploads

An uploader who is not the owner cannot satisfy the ownership storage policy, so the flow differs:

```
 1. POST /v1/drops/{slug}/request-slot { size_bytes } → { slot_id, storage_key }
 2. TUS upload to drops/{drop_id}/{slot_id} with the uploader's own anonymous token
 3. POST /v1/drops/{slug}/request-complete { slot_id, encrypted_entry }
```

The storage policy checks `request_slot_open(slot_id, drop_id)`, so a stranger can write exactly
one object of a pre-authorized size and nothing else. Slots expire in two hours and the sweeper
deletes objects for slots that were never completed.

## Download

```
 1. POST /v1/drops/{slug}/authorize    → recipient token
 2. POST /v1/drops/{slug}/download     → { url, expires_in: 60 }
 3. fetch(url)                         → ciphertext ReadableStream
 4. Worker: verify header, decrypt segments, BLAKE3 check
 5. sink.write()                       → disk
```

The signed URL is minted by Railway with the secret key after the status, expiry, cap, and
password checks. Sixty seconds is enough to start a transfer and short enough that a leaked URL in
a screenshot is worthless. The URL is used once; a resumed download asks for a new one.

Range requests work against the signed URL, so a download resumes by asking for a fresh URL and
setting `Range: bytes={ciphertextOffset}-`. Because resume offsets are on the ciphertext envelope,
the decryptor recomputes which segment index that offset lands on and refuses anything that is not
a segment boundary.

### Sinks

Feature detection picks one, in this order.

1. **File System Access API.** `showSaveFilePicker` for a single file, `showDirectoryPicker` for a
   folder, then `createWritable()` and `pipeTo`. Chromium only. The picker needs transient user
   activation, so it must be called inside the click handler before any `await` on the network.
   Get the handle first, then start the request.
2. **Origin Private File System** in a Worker with `createSyncAccessHandle()`, then a save at the
   end. Safari 15.2 and up, Firefox 111 and up. Costs double the storage and is quota limited, so
   it is used only when the drop fits comfortably in the origin quota.
3. **Same-origin service worker** answering a fetch with a `ReadableStream` response. About sixty
   lines, written in this repository rather than pulled from StreamSaver.js, whose cross-origin
   iframe hop is unnecessary when the worker is same origin and which is barely maintained.

For a folder download on sink 2 or 3, files are written one at a time in manifest order with a
visible per-file progress, because there is no directory handle to write into.

## Sealing and size verification

`seal` is the only place the server learns sizes, and it does not take the client's word for them.
Railway lists the prefix, compares each object's reported size to the client's claim, and rejects
the seal if any differs by more than one segment's overhead. This is what stops a client from
under-reporting size to dodge a quota. It is one list call per drop.

The sizes written to Postgres are rounded up to 64 KB by `round_bytes`. Exact sizes live only in
the encrypted manifest.

## Expiry and the sweeper

Railway runs a sweep every five minutes.

```
 1. select expire_due_drops(500)       → rows of (drop_id, storage_key)
 2. storage.remove(keys) in batches of 100
 3. delete from drop_files where drop_id in (...)
 4. delete from rate_buckets where window_start < now() - interval '2 days'
```

The `drops` row survives with `status = 'expired'`, `ended_at`, `ended_reason`, and a null
manifest. That tombstone is what makes P-18's honest end-of-life page possible.

Contract: ciphertext is deleted within 15 minutes of expiry. Five minute sweeps give two chances
to hit that. If a sweep fails, it alerts; it does not silently skip.

Revocation takes the same path immediately rather than waiting for a sweep, because a sender who
hits revoke expects the file to be gone.

## Failure handling

| Failure | Behavior |
| --- | --- |
| Network drop mid-upload | TUS resumes from the last chunk. No user action. |
| Tab closed mid-upload | Drop stays `uploading`, expires on schedule, objects deleted. |
| `409` on an upload URL | Fatal. Another tab is uploading the same file. Surface it. |
| Signed URL expired mid-download | Request a new one and resume with `Range`. Transparent. |
| Storage 5xx | Retry with the configured backoff, then surface a retry button. |
| Seal size mismatch | `409`, the client re-lists its own uploads and retries once. |
| Quota exceeded mid-upload | Cannot happen; the ceiling is checked at creation and at seal. |

## Why not WebTransport

WebTransport over HTTP/3 would be a better bulk pipe than TUS over HTTP/1.1, and unlike the
peer-to-peer case it is architecturally possible here because there is a server on one end. It is
not used because Supabase Storage does not speak it, and putting a WebTransport endpoint on
Railway would put file bytes back into a service that currently never sees them. If Storage
throughput ever becomes the constraint, this is the upgrade to evaluate, and it needs an entry in
[14-decisions.md](14-decisions.md) before anyone starts.

## Tests

| Test | How |
| --- | --- |
| Round trip | 2 GB fixture, upload, seal, download, byte equality |
| Resume upload | Kill the connection at 30 percent, assert TUS resumes and the hash matches |
| Resume download | Abort at 50 percent, assert `Range` resume lands on a segment boundary |
| Flat memory | Assert peak heap stays under 200 MB for a 10 GB file in Chromium |
| Signed URL expiry | Assert a 61 second old URL fails and the client recovers |
| Seal mismatch | Claim a smaller size, assert `409` |
| Request slot | Upload with a slot, assert a second upload to the same key is denied |
| Sweeper | Expire a drop, assert objects gone within one interval and the tombstone remains |
| Sink fallback | Force each of the three sinks, assert byte equality on all three |

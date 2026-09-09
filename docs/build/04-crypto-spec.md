# 04. Crypto spec

The wire format. Two independent implementations exist (TypeScript in `packages/crypto`, Swift in
`apple/DropApp`), so every byte layout here is normative and every construction has test vectors.
If you are tempted to change a constant, add a version byte instead.

## Design rules

1. **Nothing invented.** The streaming AEAD is Tink's `AES_GCM_HKDF_STREAMING` layout. The
   password KDF is argon2id per RFC 9106. Key agreement is X25519 with HKDF-SHA256.
2. **The server never holds a key**, wrapped or otherwise, that it can also unwrap. It holds
   verifiers and wrapped blobs whose wrapping keys never leave a client.
3. **Every ciphertext is bound to its position.** Reordering, truncating, or splicing chunks
   fails a tag rather than producing plausible output.
4. **Feature detection never weakens the format.** WebAuthn PRF and the File System Access API
   are optional paths; neither changes what is written.

## Primitives

| Purpose | Algorithm | Notes |
| --- | --- | --- |
| Bulk encryption | AES-256-GCM, 96-bit nonce, 128-bit tag | `SubtleCrypto` in a Worker, `CryptoKit.AES.GCM` on Apple |
| Key derivation | HKDF-SHA256 | extract and expand, contexts below |
| Password stretching | argon2id, m=65536 KiB, t=3, p=1 | `@openpgp/argon2id` on web, `swift-argon2` on Apple |
| Key agreement | X25519 | request mode only |
| Content hash | BLAKE3, 256-bit | `hash-wasm` on web, `blake3-swift` on Apple |
| Randomness | `crypto.getRandomValues` / `SystemRandomNumberGenerator` | never `Math.random` |

AES-GCM over WASM alternatives is deliberate: browsers and Apple silicon both accelerate AES in
hardware, and a WASM AEAD would be slower for no security gain.

## Key hierarchy

```
                          drop key  DK  (32 random bytes, lives in the URL fragment)
                              │
        ┌─────────────────────┼──────────────────────┐
        │ HKDF info=          │ HKDF info=           │ wraps
        │ "drp/manifest/v1"   │ "drp/signal/v1"      │
        ▼                     ▼                      ▼
   manifest key MK      signaling key SK      content keys CK₁..CKₙ
   encrypts the         encrypts SDP and      each 32 random bytes,
   manifest blob        ICE payloads          carried inside the manifest


  password (optional)
        │ argon2id(salt, m=64MiB, t=3, p=1) → 64 bytes
        ├── bytes 0..31   KEK   wraps DK inside the link fragment
        └── bytes 32..63  VER   SHA-256(VER) is stored server side


  drive (paid)
   root key RK (32 random bytes, generated client side, never transmitted)
        │ wraps
        └── content keys CK for every drive node

   RK itself is stored only as wrapped blobs:
        wrapped_by_recovery   ← recovery key, 256 bits, shown once
        wrapped_by_password   ← argon2id of the account password
        wrapped_by_prf        ← HKDF(WebAuthn PRF output), where supported
```

Content keys are per file and live inside the manifest. That is what makes sharing a drive file
free: the drop's manifest simply repeats the existing `CK`, and no ciphertext is re-uploaded.
Revoking the drop deletes the drop row, and the drive object is untouched.

## HKDF contexts

Always `HKDF-SHA256(ikm, salt, info, length)`. Salt is the 16 byte value from the file header
where one exists, otherwise 32 zero bytes.

| Derived key | ikm | info | length |
| --- | --- | --- | --- |
| Manifest key `MK` | `DK` | `"drp/manifest/v1"` | 32 |
| Signaling key `SK` | `DK` | `"drp/signal/v1"` | 32 |
| File segment key | `CK` | `"drp/file/v1"` | 32 |
| Request-mode file key | X25519 shared secret | `"drp/request/v1"` | 32 |
| Drive wrap key from PRF | PRF output | `"drp/prf/v1"` | 32 |

Never reuse a context string for a new purpose. Add a new one.

## File envelope

Every encrypted file, on either transport and in either bucket, is this exact byte sequence.

```
 offset  size   field
 ------  -----  -------------------------------------------------------------
      0      4  magic, ASCII "DRP1"
      4      1  version, 0x01
      5      1  algorithm, 0x01 = AES-256-GCM-HKDF-STREAM
      6      4  plaintext segment size, uint32 big endian (default 262144)
     10     16  HKDF salt, random per file
     26      7  nonce prefix, random per file
 ------  -----  header is 33 bytes, transmitted and stored in the clear
     33      *  segment 0
      *      *  segment 1 ...
```

Segment `i` is `AES-GCM(key = segment key, nonce = N(i), aad = header, plaintext = P(i))`
followed by its 16 byte tag. Every `P(i)` is exactly `segment size` bytes except the last, which
is 1 to `segment size` bytes. A zero-length file has exactly one segment with a zero-length
plaintext.

```
 N(i) = nonce_prefix (7 bytes)
      ‖ uint32be(i)   (4 bytes)
      ‖ last_flag     (1 byte: 0x01 on the final segment, else 0x00)
```

The AAD is the 33 byte header, so a segment cannot be moved to another file or replayed under a
different segment size. The counter and the final-segment flag are inside the nonce, so
reordering or truncating changes the nonce and the tag fails.

Ciphertext length for a plaintext of `n` bytes with segment size `s`:

```
 segments = max(1, ceil(n / s))
 length   = 33 + n + 16 * segments
```

The implementation must reject a file whose length does not satisfy that identity before it
decrypts anything.

### Why there is no Merkle tree

The brief proposed BLAKE3 tree hashes per file. They were dropped. Every segment already carries
a GCM tag under a key the server does not have, so a modified or reordered segment fails during
decryption, which is the property a Merkle tree would have provided. The manifest keeps a single
BLAKE3 hash of the whole plaintext as a cheap end-to-end check, and resume works on
acknowledged ciphertext offsets. Recorded in [14-decisions.md](14-decisions.md).

## Manifest

One JSON document, UTF-8, encrypted with `MK` into the same envelope format as a file (so there
is one decryptor, not two) and stored in `drops.encrypted_manifest`.

```jsonc
{
  "v": 1,
  "title": "Q3 brand assets",
  "kind": "folder",
  "created_at": "2026-09-09T14:12:00Z",
  "total_size": 3623878656,
  "files": [
    {
      "id": "0f4c2b9e-1d6a-4a3f-9c21-8b5e7d0a1f33",
      "path": "logos/mark.svg",
      "mime": "image/svg+xml",
      "size": 12345,
      "key": "base64url of 32 bytes",
      "hash": "base64url of BLAKE3-256 over the plaintext",
      "segment_size": 262144
    }
  ]
}
```

Rules the implementations enforce:

- `path` is a POSIX relative path. No leading `/`, no `.` or `..` segment, no backslash, no NUL,
  no drive letter. A manifest that violates this is rejected before any file is written, because
  a malicious manifest is the obvious path traversal in a folder download.
- `path` values are unique within a manifest, compared after Unicode NFC normalization.
- `id` matches the `drop_files.id` and therefore the storage key. A manifest entry with no
  matching file row, or a file row with no manifest entry, is an error.
- `size` is exact. The rounded size in Postgres is derived from it and never the other way round.
- The whole manifest is capped at 8 MB after compression, which is roughly 20,000 files.

## The link

```
 share:      https://host/d/{slug}#{fragment}
 management: https://host/m/{slug}#{manage_secret}
```

The fragment is base64url, unpadded, of:

```
 offset  size  field
      0     1  version, 0x01
      1     1  flags
      2     *  payload
```

| Flag bit | Meaning | Payload |
| --- | --- | --- |
| `0x00` | none set | 32 bytes: `DK` in the clear |
| `0x01` | password wrapped | 12 byte nonce ‖ 32 byte ciphertext ‖ 16 byte tag = 60 bytes |
| `0x02` | request mode | 32 bytes: the requester's X25519 private key |

Bits `0x01` and `0x02` are mutually exclusive. Unknown bits abort with a version error rather
than being ignored.

The fragment is never sent to a server: browsers do not include it in the request line, it does
not appear in `Referer`, and the app must never place it in a query string, a log, a
`history.pushState` URL, or an analytics call (there is no analytics). Server rendered pages must
not echo `location.hash` into markup.

`manage_secret` is 32 random bytes, base64url. The server stores only `SHA-256(secret)` in
`drop_manage.secret_hash` and compares in constant time.

## Passwords

The password protects the content, not just the door. This is the whole reason the password path
is worth building.

```
 client:
   salt   ← 16 random bytes
   okm    ← argon2id(password, salt, m = 65536 KiB, t = 3, p = 1, out = 64)
   KEK    ← okm[0..32]
   VER    ← okm[32..64]
   wrapped_DK ← AES-GCM(KEK, nonce, DK, aad = "drp/link/v1")
   fragment   ← 0x01 ‖ 0x01 ‖ nonce ‖ wrapped_DK

 sent to the server at creation:
   password_salt      = salt
   password_verifier  = SHA-256(VER)
   password_params    = {"alg":"argon2id","v":19,"m":65536,"t":3,"p":1}

 recipient:
   fetch salt and params from get_public_drop
   recompute okm, split into KEK and VER
   POST /v1/drops/{slug}/authorize { proof: base64url(VER) }
   server compares SHA-256(proof) to password_verifier in constant time
   client unwraps DK locally with KEK
```

The server can verify but cannot decrypt: it holds `SHA-256(VER)` and never sees `KEK`. A
compromised database yields an offline attack against the password with argon2id in the way, and
nothing else.

Parameters are stored per drop so they can be raised later without breaking existing links.
Clients must accept any parameter set they can run and must refuse parameters that would exceed
512 MiB of memory.

### Out-of-band key delivery

P-10 is the password path with a generated passphrase, not a separate mechanism. The app
generates eight words from the EFF short wordlist (about 83 bits), uses them as the password, and
displays them for the sender to deliver through another channel. The link then carries only a
wrapped key. One code path, one format.

## Request mode

The requester holds a private key; uploaders hold only the public key.

```
 requester, at creation:
   (sk, pk) ← X25519 keygen
   drops.request_public_key ← pk
   fragment ← 0x01 ‖ 0x02 ‖ sk

 uploader, per file:
   (esk, epk) ← X25519 keygen (ephemeral, per file)
   shared     ← X25519(esk, pk)
   CK         ← HKDF(shared, salt = epk ‖ pk, info = "drp/request/v1", 32)
   encrypt the file with CK into the standard envelope
   send epk alongside the file entry

 requester:
   shared ← X25519(sk, epk)
   CK     ← same HKDF
```

Each uploader's entry is appended to a per-uploader manifest fragment rather than a shared
manifest, because uploaders must not be able to read each other's files. The requester merges
fragments client side when they open the drop.

## Drive key hierarchy

```
 activation:
   RK            ← 32 random bytes
   recovery_key  ← 32 random bytes, rendered as 13 groups of 4 Crockford base32 characters
   wrapped_by_recovery ← AES-GCM(HKDF(recovery_key, info="drp/recovery/v1"), RK)
   wrapped_by_password ← AES-GCM(argon2id(account password), RK)          [optional]
   wrapped_by_prf      ← AES-GCM(HKDF(prf_output, info="drp/prf/v1"), RK) [where supported]
```

Rules that are not negotiable:

- The recovery key wrap is **mandatory**. The user confirms they saved it before the first
  upload is allowed. There is no server-side escrow and no reset.
- PRF is never the only wrap. Before relying on a PRF wrap, the client performs a throwaway
  assertion at enrollment to confirm the authenticator actually returns PRF output, because
  `enabled: true` at registration does not guarantee it.
- Cross-device (hybrid) passkey flows can return a different PRF value than the same passkey used
  locally. Treat a PRF unwrap failure as "try another method", never as data loss.
- `RK` exists in memory only. It is never written to `localStorage`, `IndexedDB`, or a cookie. On
  Apple platforms it goes in the Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` and
  is never marked synchronizable.

## Signaling encryption

Every Realtime Broadcast payload for a p2p drop is encrypted with `SK` before it is published.

```
 payload = base64url( 12 byte nonce ‖ AES-GCM(SK, nonce, json, aad = "drp/signal/v1") )
```

The channel topic is `drop:` followed by the first 16 hex characters of `SHA-256(slug)`, so the
topic does not reveal the slug to anyone watching channel names. Supabase sees two anonymous
sessions exchanging opaque blobs on an unguessable topic.

## Streaming implementation notes

**Web.** Encryption and hashing run in a dedicated Worker. The pipeline is
`File.stream()` → segment slicer → `SubtleCrypto` → framing. Decryption is the reverse into a
`WritableStream`. The main thread never holds a full segment. Target output sinks in order:

1. File System Access API: `showSaveFilePicker` or `showDirectoryPicker`, then
   `createWritable()`. Chromium only. The picker requires transient user activation, so it must
   be called synchronously inside the click handler, before any `await` on the network.
2. Origin Private File System in a Worker with `createSyncAccessHandle()`, then a final save.
   Safari 15.2+ and Firefox 111+. Costs double the storage.
3. A same-origin service worker that answers a fetch with a `ReadableStream` response. Roughly
   sixty lines. Do not add StreamSaver.js: the library's cross-origin iframe hop is unnecessary
   when the worker is same origin, and it is barely maintained.

**Apple.** `CryptoKit.AES.GCM` has no incremental API, so the same segmentation is done by hand
over a `FileHandle`. Encrypt to a temporary file, then hand that file to a background
`URLSession`, because background sessions require a file body and cannot stream. For a large
encryption pass triggered by a user action, use `BGContinuedProcessingTask` on iOS 26 so the
work survives backgrounding with system progress UI.

## Test vectors

`packages/crypto/vectors/` holds JSON fixtures that both implementations run. Adding a vector is
part of any change to this document.

| Vector | Asserts |
| --- | --- |
| `envelope-empty.json` | Zero-length file produces one segment, correct length identity |
| `envelope-exact.json` | Plaintext exactly one segment long sets the last flag on segment 0 |
| `envelope-multi.json` | Three segments, known key and prefix, byte-exact ciphertext |
| `envelope-tamper.json` | Flipping one ciphertext bit fails segment 1, and nothing is written |
| `envelope-truncate.json` | Dropping the last segment fails rather than yielding a short file |
| `envelope-reorder.json` | Swapping segments 1 and 2 fails both |
| `hkdf-contexts.json` | All five contexts produce the documented outputs from a fixed `DK` |
| `password-wrap.json` | Known password and salt produce a known `KEK`, `VER`, and fragment |
| `fragment-parse.json` | All three flag combinations parse, unknown bits throw |
| `manifest-paths.json` | Traversal, absolute, backslash, NUL, and duplicate paths are rejected |
| `request-ecies.json` | Known X25519 pair derives a known `CK` |

The Swift test target runs the same JSON files. A vector that passes in one language and fails in
the other blocks the release, no exceptions.

## Threats this format does not address

Stated so nobody assumes otherwise.

- **Traffic analysis.** Ciphertext size and timing are visible to the network and to the relay.
  Sizes are padded to 64 KB only in the database, not on the wire.
- **A malicious recipient.** Anyone who can decrypt can keep and re-share. A password does not
  help once the key is known.
- **A compromised client.** If the browser or the app is compromised, the key is compromised. The
  web app mitigates the class of attack it can, with a strict CSP and no third-party scripts, and
  claims nothing more.
- **Quantum adversaries.** X25519 in request mode is classical. If this matters later, the
  migration is `XWingMLKEM768X25519`, which is available in CryptoKit on the 26 platforms and
  would need a version bump here.

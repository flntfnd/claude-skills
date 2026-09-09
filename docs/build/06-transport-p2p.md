# 06. Peer-to-peer transport

`packages/transport-p2p`. No DOM framework, no React, no UI. It exposes a session object, emits
events, and is driven identically by the web app and by a headless test harness.

Peer-to-peer ships before cloud. It has no storage, no retention, and no sweeper, so it is the
smaller trust surface, and it is the harder engineering, so building it first validates the
crypto and the UX while they are still cheap to change.

## What it guarantees and what it does not

**Guarantees.** Neither peer learns the other's IP address when the relay pin is on. No byte of
file content is stored anywhere. The signaling server sees two anonymous sessions exchanging
opaque blobs on an unguessable topic.

**Does not guarantee.** Cloudflare, as the relay, sees both peers' addresses and the volume of
relayed traffic. Relay-only removes the fast path, so throughput is lower and latency higher than
a direct connection. It does not work in Tor Browser, where WebRTC is disabled. If the recipient's
client is not also relay-pinned, its own candidates can expose it, so the sender filters any
non-relay candidate it receives.

## Session lifecycle

```
        sender                                            recipient
          │                                                   │
    create drop (status=sealed, manifest committed)            │
          │                                                   │
    join channel drop:{h(slug)}                    open /d/{slug}
    track presence ────────────────────────────▶  join same channel
          │                                                   │
          │◀──────────────── hello {session, caps} ───────────│
    POST /turn ─▶ iceServers                        POST /turn ─▶ iceServers
          │                                                   │
    new RTCPeerConnection({iceServers, iceTransportPolicy:'relay'})
          │──────────────── offer (encrypted) ───────────────▶│
          │◀─────────────── answer (encrypted) ───────────────│
          │◀────────────── candidates, both ways ────────────▶│
          │                                                   │
    ═══ control channel open ═══════════════════════════════ │
          │──────────────── manifest-ready ─────────────────▶│
          │◀─────────────── want {file_ids} ─────────────────│
    ═══ bulk channel: framed ciphertext ═════════════════════▶│
          │◀─────────────── ack {file_id, offset} ───────────│
          │──────────────── file-complete ──────────────────▶│
          │◀─────────────── bye ─────────────────────────────│
```

The sender may hold up to `plan_limits.max_concurrent_recipients` connections at once. Each
recipient gets its own `RTCPeerConnection`, its own send loop, and its own window, so a slow
recipient never stalls a fast one.

## Signaling

Transport is Supabase Realtime Broadcast on a private channel.

```ts
const topic = `drop:${sha256(slug).slice(0, 16)}`

await supabase.realtime.setAuth()
const channel = supabase.channel(topic, {
  config: { private: true, broadcast: { self: false, ack: true } },
})
```

Every payload is encrypted with `SK` before publish, per
[04-crypto-spec.md](04-crypto-spec.md). Message types:

| Type | From | Payload |
| --- | --- | --- |
| `hello` | recipient | `{ session, caps: { relay_only, max_message_size } }` |
| `offer` | sender | `{ session, sdp }` |
| `answer` | recipient | `{ session, sdp }` |
| `candidate` | either | `{ session, candidate }` |
| `bye` | either | `{ session, reason }` |

`session` is 16 random bytes generated per connection attempt and never reused. It is the only
identifier either side has for the other. Presence carries the same value and nothing else.

Broadcast payloads are capped at 256 KB, which is far above an SDP. Nothing but signaling ever
crosses this channel; file bytes never do.

Realtime authorization policies are permissive by design and are justified in
[03-data-model.md](03-data-model.md): the topic is derived from an unguessable slug and every
payload is encrypted.

## ICE configuration

```ts
const pc = new RTCPeerConnection({
  iceServers,                       // from POST /v1/drops/:slug/turn
  iceTransportPolicy: policy,       // 'relay' unless both peers opted into direct
  bundlePolicy: 'max-bundle',
})
```

Belt and braces on top of the policy: reject any received candidate whose type is not `relay`
while pinned, and refuse to proceed if the remote description contains a host or `srflx`
candidate. A peer that will not relay is a peer this drop does not connect to.

Cloudflare's TURN offers UDP on 3478, TCP on 3478 and 80, and TLS on 5349 and 443. The 443 TLS
entry is what gets through hostile networks and is always included. Cloudflare does not relay over
IPv6 and does not relay TCP to the peer, which is a limitation to know about, not to work around.

Credentials last six hours. A session that outlives them calls `/turn` again and applies the
result with `pc.setConfiguration()` rather than tearing down.

## Data channels

Two channels, created by the sender before the offer.

| Label | Ordered | Reliable | Carries |
| --- | --- | --- | --- |
| `ctl` | yes | yes | JSON control messages |
| `bulk` | yes | yes | framed ciphertext |

**One bulk channel, not several.** SCTP congestion control is per association, so all channels
share one window. Parallel channels buy head-of-line independence, not bandwidth, and this
transport sends one file at a time per recipient anyway.

### Frame format

`bulk` is `binaryType = 'arraybuffer'`. Every frame is at most 16384 bytes.

```
 offset  size  field
      0     1  type: 0x01 data, 0x02 file-complete
      1    16  file id, raw UUID bytes
     17     4  uint32 big endian, byte offset into the file's ciphertext envelope
     21     2  uint16 big endian, payload length
     23     *  payload, at most 16361 bytes
```

16 KiB frames are the interoperable choice. `pc.sctp.maxMessageSize` advertises 256 KiB in
Chromium, but end-of-record handling differs across implementations and large messages cause
head-of-line blocking on the association. Read `maxMessageSize` at startup anyway and refuse to
run if it is below 16384.

The 4 byte offset caps a single file at 4 GiB of ciphertext per channel epoch. Files larger than
that reset the offset at each 4 GiB boundary and the receiver tracks the epoch from the
`file-progress` control message. The alternative, a 64 bit offset in every frame, costs 4 bytes
per 16 KiB forever to save one control message.

### Backpressure

The only correct pattern. Never poll `bufferedAmount` in a loop.

```ts
const LOW  = 1 << 20   // 1 MB
const HIGH = 8 << 20   // 8 MB

bulk.bufferedAmountLowThreshold = LOW

async function send(frame: ArrayBuffer) {
  if (bulk.bufferedAmount > HIGH) {
    await once(bulk, 'bufferedamountlow')
  }
  bulk.send(frame)
}
```

The default threshold is zero, which never fires, so setting it is not optional.

### Control messages

JSON, UTF-8, on `ctl`.

| Type | From | Payload |
| --- | --- | --- |
| `manifest-ready` | sender | `{ file_count, total_ciphertext_bytes }` |
| `want` | recipient | `{ file_ids: string[] }` |
| `file-begin` | sender | `{ file_id, ciphertext_bytes, epoch }` |
| `ack` | recipient | `{ file_id, offset }` highest contiguous byte written |
| `resume` | recipient | `{ file_id, offset }` after a reconnect |
| `file-complete` | sender | `{ file_id }` |
| `error` | either | `{ code, file_id? }` |
| `bye` | either | `{ reason }` |

The recipient sends `ack` every 4 MB and on every file boundary. The sender keeps the last
acknowledged offset per file so a resume is a seek, not a restart.

## Resume

A dropped connection is expected, not exceptional.

1. The recipient keeps written ciphertext offsets per file, in memory and, where the File System
   Access API is in use, implied by the file length on disk.
2. On `iceconnectionstatechange` reaching `disconnected`, both sides wait five seconds before
   tearing down, because ICE recovers on its own more often than not.
3. On `failed`, the recipient re-joins the channel and sends `hello` again. The sender answers
   with a fresh offer.
4. The recipient sends `resume { file_id, offset }` for the file that was in flight. The sender
   seeks its encrypted stream to that offset and continues.
5. Integrity needs no extra machinery: every segment carries its GCM tag, so a resume that lands
   on the wrong boundary fails loudly at the next segment.

Resume offsets are always on the ciphertext envelope, never the plaintext, so the receiver can
resume without having decrypted anything yet.

## Sender offline

The recipient page must never show an error for this, per P-17.

- Realtime presence tells the recipient whether a sender is on the channel.
- No sender present means the "the sender isn't here right now" state, with the page still
  joined and waiting.
- When presence shows a sender, the recipient sends `hello` and the flow resumes at whatever
  offsets it had.
- The page keeps waiting indefinitely while the drop is alive. It flips to the tombstone state
  only when the drop actually ends.

## Session expiry

A `session` expiry drop ends when the sender's tab closes. The mechanism is Realtime presence
leaving the channel, observed by Railway through a Realtime webhook, which sets `status` and
`ended_reason`. `expires_at` is set to 24 hours out at creation purely as a backstop for the case
where the presence event is missed. Presence is the mechanism; the sweeper is the safety net.

## Public API of the package

```ts
export interface SenderSession {
  readonly recipients: ReadonlyMap<string, RecipientState>
  start(): Promise<void>
  stop(reason?: string): Promise<void>
  on(event: 'recipient-joined' | 'recipient-left' | 'progress' | 'error', cb): Unsubscribe
}

export interface RecipientSession {
  readonly state: 'waiting' | 'connecting' | 'transferring' | 'complete' | 'ended'
  request(fileIds: string[]): Promise<void>
  cancel(): void
  on(event: 'state' | 'progress' | 'error', cb): Unsubscribe
}

export function createSender(opts: {
  slug: string
  dropKey: Uint8Array
  files: AsyncIterable<EncryptedFile>
  turn: () => Promise<TurnConfig>
  realtime: RealtimeClient
  maxRecipients: number
}): SenderSession

export function createRecipient(opts: {
  slug: string
  dropKey: Uint8Array
  turn: () => Promise<TurnConfig>
  realtime: RealtimeClient
  sink: WritableSinkFactory
}): RecipientSession
```

`progress` events carry `{ recipient?, file_id, bytes, total }` and nothing identifying.

## Throughput expectations

Set them honestly in the UI. SCTP over DTLS was tuned for real-time media, not bulk transfer. A
data channel that could push 500 Mbps on a direct LAN connection commonly settles between 50 and
100 Mbps, and relaying adds the round trip to the nearest Cloudflare point of presence on top.

What actually helps, in order of effect: 16 KiB frames with proper backpressure, avoiding any
main-thread work in the send loop, and keeping the encryption worker ahead of the channel so it is
never the bottleneck. What does not help: more channels, bigger frames, or unordered delivery.

WebTransport is not an option here. It is client-to-server only, so it cannot carry a peer-to-peer
session. It is the right upgrade path for the cloud transport if Storage ever becomes the
bottleneck, and it is noted in [07-transport-cloud.md](07-transport-cloud.md) for that reason.

## Cost

Every relayed byte is Cloudflare egress: one terabyte free per month, then $0.05 per GB. A 1 GB
transfer to one recipient costs about five cents; the same file to eight recipients costs forty.
This is the dominant variable cost of the product and it is why `relay_bytes_per_month` is a plan
limit rather than an afterthought. The sender's page shows remaining relay budget when the account
is within 20 percent of its ceiling.

## Tests

| Test | How |
| --- | --- |
| Two-browser round trip | Playwright, two contexts, a 200 MB fixture, asserts byte equality |
| Relay pin holds | Assert every local and remote candidate has `typ relay` |
| Non-relay candidate rejected | Inject a host candidate, assert the session aborts |
| Resume | Kill the data channel at 40 percent, assert completion and byte equality |
| Backpressure | Assert `bufferedAmount` never exceeds `HIGH + one frame` over a 1 GB send |
| Fan-out | Four recipients, one slow, assert the fast three are not stalled |
| Sender offline | Close the sender context, assert the recipient shows waiting, reopen, assert resume |
| Frame fuzz | Corrupt one byte in a random frame, assert a tag failure and no partial file |
| Manifest traversal | A manifest with `../` aborts before any write |

The two-browser test runs on the pre-installed Chromium in CI. Safari coverage is a manual
checklist per release, documented in [12-testing.md](12-testing.md).

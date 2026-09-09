# 01. Product spec

What the app does, in enough detail that a developer never has to guess a behavior. Every
requirement here has an ID (`P-*`) so tasks and tests can cite it.

## Glossary

Use these words in code, in the database, and in the UI. Do not introduce synonyms.

| Term | Meaning |
| --- | --- |
| **Drop** | One share. A file or a folder, one link, one expiry policy, one transport. The core noun. |
| **Transport** | How bytes travel for a drop: `p2p` or `cloud`. Chosen at creation, never changed. |
| **Mode** | `send` (sender supplies the files) or `request` (others upload into the drop). |
| **Manifest** | The encrypted description of a drop's contents: names, paths, mime types, exact sizes, hashes. |
| **Drop key** | The 256-bit key that encrypts a drop's files and manifest. Lives in the URL fragment. |
| **Share link** | `https://host/d/{slug}#{key}`. Grants read access. |
| **Management link** | `https://host/m/{slug}#{manage_secret}`. Grants expiry and revocation control. Never read access. |
| **Seal** | The moment a cloud drop's upload finishes and the manifest is committed. Before sealing the link works but shows "still uploading". |
| **Revoke** | The sender ending a drop early. Irreversible. |
| **Sweep** | The scheduled job that expires drops and deletes their ciphertext. |
| **Drive** | The paid, persistent, owner-only encrypted tree. |
| **Node** | One drive entry, file or folder. |

Words that are banned in the UI because they promise something the app does not do: "secure
cloud storage", "backup", "sync", "scan", "preview".

## Who this is for

Three people, in priority order. They are a design tool, not a marketing segment.

1. **The one-off sender.** Has a folder to get to someone in the next ten minutes. Does not want
   an account, will not read documentation, and will judge the product by whether the link is in
   the clipboard within one interaction of dropping the folder.
2. **The careful sender.** Cares who can see the file and for how long. Reads the expiry
   dropdown, turns on the password, and wants to be able to kill the link later.
3. **The recipient.** Did not choose this app. Success is that they never notice it: no account,
   no install, no waiting, the folder structure they were promised.

## Requirements

### Creating a drop

- **P-1** A sender can create a drop by dragging files or a folder onto the drop zone, by pasting
  from the clipboard, or by using a file picker. Folder selection uses `webkitdirectory` and the
  File System Access API where present.
- **P-2** Folder structure is preserved. The relative path of every file is recorded in the
  manifest and rebuilt on the recipient's disk. Nothing is zipped at any point by any server.
- **P-3** The sender chooses a transport before the drop is created. The default is `p2p` when
  the browser supports WebRTC and the total size is under the cloud free ceiling, otherwise
  `cloud`. The default is a computed suggestion, always visible and always overridable.
- **P-4** The sender chooses an expiry from presets (1 hour, 1 day, 7 days, 30 days), a custom
  duration, or an exact date and time. Peer-to-peer drops additionally offer "while my tab is
  open". Paid accounts additionally offer "never" for drops created from drive items.
- **P-5** The sender chooses a download cap: 1, a specific number, or unlimited. A drop ends when
  either the time expires or the cap is reached, whichever is first.
- **P-6** The sender may set a password. The password never leaves the browser; see
  [04-crypto-spec.md](04-crypto-spec.md).
- **P-7** The share link is available and copyable before a cloud upload finishes. The recipient
  page shows an honest "still uploading" state until the drop is sealed.
- **P-8** For a peer-to-peer drop the link is live the moment it is created.
- **P-9** Anonymous senders receive a management link at creation time, shown once, with an
  explicit "save this or you cannot revoke" warning. Signed-in senders do not need one because
  the dashboard covers it.
- **P-10** The sender can strip the key from the share link and display it separately as a
  sequence of words, for out-of-band delivery.
- **P-11** Drop creation is refused, with a specific message, when the request exceeds the
  account's plan ceiling for size or expiry. The message names the limit and the plan that
  raises it.

### Receiving a drop

- **P-12** A recipient needs no account, no install, and no browser extension.
- **P-13** The recipient page shows: the drop title, transport, total size, file count, expiry
  countdown, remaining downloads, and a browsable tree with per-file sizes.
- **P-14** The recipient can download the whole drop or any subset. Multi-file downloads write
  files individually into a chosen directory where the File System Access API is available, and
  fall back to sequential streamed downloads elsewhere.
- **P-15** Decryption is streaming. Memory use is flat and independent of file size. A 10 GB file
  works in a tab with no swap thrash.
- **P-16** A password-protected drop shows a password field and nothing else until the password
  is correct. A wrong password produces a specific message and is rate limited.
- **P-17** A peer-to-peer drop whose sender is offline shows "the sender isn't here right now",
  keeps waiting, and connects on its own when the sender returns.
- **P-18** An expired, revoked, or exhausted drop shows a clean end-of-life page that says which
  of those happened and when. It is never a 404 and never an unstyled error.
- **P-19** Integrity failure is loud. A chunk that fails its tag, or a file whose hash does not
  match the manifest, aborts the download with a message that says the data was altered or
  truncated, and never leaves a partial file that looks complete.

### Managing a drop

- **P-20** A sender with the management link or a session that owns the drop can extend expiry,
  shorten it, change the download cap, or end the drop immediately.
- **P-21** Changes apply to a link that is already circulating, within one sweep interval at
  worst and immediately for anything that goes through download authorization.
- **P-22** The signed-in dashboard is a flat, newest-first list of drops with title, size, expiry
  countdown, view count, download count, and a revoke action. There is no folder tree, no search
  beyond a filter box, and no bulk editing in v1.
- **P-23** View and download counts update live via Realtime while the dashboard is open.
- **P-24** Revocation deletes ciphertext within one sweep interval and leaves a tombstone so the
  link explains itself.

### Accounts

- **P-25** Sending and receiving never require an account on the free tier.
- **P-26** Every sender gets an anonymous Supabase session so that RLS applies uniformly.
- **P-27** A sender can later sign in with a magic link or a passkey; the anonymous user is
  upgraded in place and keeps its drops. No merge UI, no "claim your drops" flow.
- **P-28** Signing out of an anonymous session warns that the drops become unmanageable without
  their management links.

### Request mode

- **P-29** A requester creates a drop in `request` mode and shares its link. Anyone with the link
  can upload into it; only the requester can read it.
- **P-30** Uploads into a request drop are encrypted to the requester's public key, not to a
  shared symmetric key. See [04-crypto-spec.md](04-crypto-spec.md).
- **P-31** Request drops carry the same expiry, cap, and password rules, plus an inbound size
  limit from the plan.

### Drive (paid)

- **P-32** A paying user has a persistent encrypted tree: upload, organize into folders, rename,
  move, delete, and share.
- **P-33** Sharing a drive item creates a normal drop that reuses the existing ciphertext. No
  re-upload. Revoking that drop never affects the drive copy.
- **P-34** Drive activation generates a recovery key, displays it exactly once, and requires the
  user to confirm they saved it before any file can be uploaded.
- **P-35** The drive is not a sync client. There is no background folder watching, no conflict
  resolution, and no version history, on any platform.

### Honesty requirements

These are product requirements, not copy suggestions. Each has a specific place in the UI.

- **P-36** The transport picker states, for each option, what it hides and what it does not, in
  one line, before the choice is made.
- **P-37** The "allow direct connection" switch is off by default and states that turning it on
  reveals both peers' IP addresses to each other.
- **P-38** The paid plan's billing section states that paying identifies the user to Stripe and
  lists the four fields the app stores.
- **P-39** The recipient page names the transport and, for peer-to-peer, states that the sender
  must stay online.
- **P-40** Any page that mentions encryption links to a plain-language threat model page derived
  from the table in the brief.

## Screen inventory

Web. The Apple screens are in [09-apple-apps.md](09-apple-apps.md).

| Route | Purpose | Auth |
| --- | --- | --- |
| `/` | Landing and the sender composer. The composer is the landing page. | none |
| `/d/[slug]` | Recipient page. | none |
| `/m/[slug]` | Management page for anonymous senders. | manage secret in fragment |
| `/drops` | Dashboard. | session |
| `/drive` | Drive browser. | session, paid |
| `/settings` | Account, plan, keys. | session |
| `/plans` | Pricing. | none |
| `/privacy` | Threat model in plain language. | none |

### States every screen must implement

Not an afterthought. Each of these is a distinct render, designed in Figma, and covered by a
test.

```
 composer:   empty → files staged → creating → uploading → live → error
 recipient:  loading → password → uploading (cloud, unsealed) → ready →
             downloading → complete → sender-offline (p2p) → ended → integrity-failure
 dashboard:  empty → populated → filtered-empty → offline
 drive:      locked (no key in memory) → empty → populated → uploading → quota-full
```

## Copy that is part of the spec

Exact strings for the states where the wording is the feature. Everything else is the writer's
call.

| Situation | String |
| --- | --- |
| P2P sender offline | The sender isn't here right now. This page will connect on its own when they come back. |
| Drop expired | This drop ended on {date}. The files are deleted. |
| Drop revoked | The sender ended this drop. The files are deleted. |
| Download cap reached | This drop reached its download limit. |
| Cloud drop unsealed | Still uploading. This page will update when it's ready. |
| Integrity failure | This file was altered or cut short in transit. Nothing was saved. |
| Wrong password | That password doesn't match. |
| Management link shown once | Save this link. It's the only way to change or end this drop, and we can't recover it. |
| Recovery key shown once | Save this key. If you lose it and your passkey, your drive is gone. We can't reset it. |
| Direct connection switch | Faster on the same network. Both sides will see each other's IP address. |
| Billing honesty | Paying tells Stripe who you are. This app stores only your customer id, plan, status, and renewal date. |

## Explicitly out of scope for v1

Sync clients, file editing, comments, version history, team folders, collaboration, server-side
previews, virus scanning, server-side zip, search inside file contents, Android and Windows
clients, custom domains, SAML, and any form of analytics.

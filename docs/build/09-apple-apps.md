# 09. Apple apps

iOS and macOS, targeting 26 and later. SwiftUI only, current APIs only, no UIKit except where the
platform gives no choice. The design system is already built in Figma; this document is the
engineering plan, not the visual one.

## Targets

```
apple/
├── DropKit/                  shared Swift package: crypto, transports, API client, models
├── DropApp-iOS/              app target
├── DropApp-macOS/            app target
├── DropShareExtension-iOS/   share sheet
└── DropShareExtension-macOS/ Finder share menu and system share sheet
```

`DropKit` is the Swift port of `packages/crypto` and `packages/transport-cloud`, and it runs the
same JSON test vectors. Peer-to-peer on Apple is deferred; see the scope note below.

## Scope, and what is deliberately not in v1

**In.** Cloud drops: pick files or a folder, encrypt, upload, get a link, set expiry and cap, set a
password. The drops list with countdowns and revoke. Receiving a drop by opening a link. Settings,
plan, account deletion. Share extensions on both platforms. Drive browsing and sharing if phase 5
has landed.

**Out of v1.** Peer-to-peer. WebRTC on Apple means bringing in a large third-party framework and
reimplementing the whole session protocol, and the transport's value is highest in the browser
where there is nothing to install. An Apple user who needs peer-to-peer opens the web app. This is
a scope decision with a real cost and it is recorded in [14-decisions.md](14-decisions.md).

## Share extensions

There is no SwiftUI-native share extension API on iOS 26 or macOS 26. The shape is still
`NSExtensionPrincipalClass` pointing at a `UIViewController` or `NSViewController` that hosts
SwiftUI through a hosting controller. Delete the storyboard.

Accepted content is declared with an `NSExtensionActivationRule` predicate rather than the
`NSExtensionActivationSupports*` dictionary keys, because the dictionary form cannot express
"a folder or any number of files".

### Reading the input without blowing the memory limit

Apple does not document a share extension memory ceiling. The observed jetsam limit on iOS is
around 120 MB and it is lower on some devices. Design so the extension never holds file bytes.

```swift
for provider in attachments {
  try await provider.loadFileRepresentation(forTypeIdentifier: UTType.item.identifier)
  // move, do not read
}
```

`loadFileRepresentation` and `loadInPlaceFileRepresentation` hand back a URL. `loadItem` and
`loadDataRepresentation` materialize the payload in memory and must not be used.

The returned URL is valid only inside the callback, so coordinate a move into the App Group
container immediately:

```swift
let coordinator = NSFileCoordinator()
coordinator.coordinate(readingItemAt: src, options: .forUploading,
                       writingItemAt: dst, options: .forReplacing) { read, write in
  try? FileManager.default.moveItem(at: read, to: write)
}
```

`.forUploading` also materializes iCloud and File Provider items and gives a snapshot for
directories, which is exactly what a folder drop needs.

### Starting the upload from the extension

The extension writes a small JSON job record into the App Group and starts a background
`URLSession` bound to the shared container, so the transfer survives the extension being torn
down and completion is delivered to the containing app.

```swift
let config = URLSessionConfiguration.background(withIdentifier: "app.drop.upload")
config.sharedContainerIdentifier = "group.app.drop"
config.isDiscretionary = false
```

Encryption does not happen in the extension. The extension moves the file and enqueues; the
containing app encrypts and uploads.

## Background upload

Two constraints drive the design.

**Background sessions require a file body.** Only `uploadTask(with:fromFile:)` and download tasks
are supported. `uploadTask(withStreamedRequest:)` cannot be serviced while the app is dead, and an
in-memory `Data` body is not honored. So the pipeline is: encrypt to a temporary ciphertext file,
then hand that file to the background session.

**Resumable upload is native.** `URLSession.uploadTask(withResumeData:)`, available since iOS 17
and macOS 14, implements the IETF resumable upload draft, paired with
`cancelByProducingResumeData(_:)` and `urlSession(_:task:didReceiveInformationalResponse:)` for the
1xx interim responses. Supabase's TUS endpoint does not speak that draft, so the Apple client has
two options and the plan picks the second:

1. Reimplement TUS by hand over `URLSession`. Works, but it is protocol code to maintain in a
   second language.
2. Put a small resumable-upload endpoint on Railway that speaks the IETF draft and forwards to
   Storage. Rejected: it would put file bytes through Railway, which the architecture forbids.
3. **Chosen:** implement TUS in `DropKit` over a background `URLSession`, uploading each 6 MB
   chunk as its own file-backed task. TUS chunk uploads are plain `PATCH` requests with a file
   body, which background sessions handle natively, and the offset bookkeeping is a few dozen
   lines. Resume across app launches falls out of it.

For the encryption pass over a large file, iOS 26 offers `BGContinuedProcessingTask`. It must be
submitted in direct response to a user action and it shows system progress UI, which fits "the
user just tapped share" exactly. It does not replace the background session for the network leg.

## macOS specifics

### Menu bar

`MenuBarExtra` cannot do what this app needs. Its `.window` style cannot be dismissed
programmatically, `scenePhase` does not report open and close reliably, and, decisively, it does
not support dropping files onto the status item at all: `onDrop` only works on views inside the
popover, which requires a click first.

So the menu bar item is a custom `NSStatusItem` created from an `NSApplicationDelegateAdaptor`,
with `statusItem.button?.window?.registerForDraggedTypes([.fileURL])` and an
`NSDraggingDestination`. The popover content is SwiftUI in an `NSHostingView`. This is more code
than `MenuBarExtra` and it is the only way to get drag-to-share, which is the feature.

### Finder integration

Use the **macOS Share Extension**, not Finder Sync. Finder Sync is designed for sync-status
badging on a directory tree the app claims, using it for a global share action is off-label, it
requires the user to enable it in Login Items and Extensions, and it is currently failing to load
on Apple silicon across several macOS 26 point releases. The Share Extension puts the app in the
Finder share submenu and the system share sheet with one target and shares its `NSItemProvider`
code path with iOS. The `NSServices` menu is legacy and poorly discovered.

If sync badges on a drive folder are ever wanted, add Finder Sync then, as a separate extension.

## Crypto on Apple

`CryptoKit.AES.GCM` has no incremental API. Only one-shot `seal` and `open` exist, so the
segmentation from [04-crypto-spec.md](04-crypto-spec.md) is done by hand over a `FileHandle`, with
the same 33 byte header, the same nonce layout, and the same AAD.

- `SymmetricKey(size: .bits256)` for key generation.
- `HKDF<SHA256>.deriveKey(inputKeyMaterial:salt:info:outputByteCount:)` for every context.
- BLAKE3 is not in CryptoKit or swift-crypto. Use `blake3-swift`, or `SwiftBlake3` if throughput
  matters, and keep it behind a protocol so it can be swapped.
- argon2id comes from a small Swift package wrapping the reference implementation, with the same
  parameters as the web client so a password set on one platform works on the other.

Worth knowing for later: iOS 26 and macOS 26 add `MLKEM768`, `MLKEM1024`, and
`XWingMLKEM768X25519` to CryptoKit. If request mode ever needs post-quantum key agreement, X-Wing
is the migration, and it needs a version bump in the crypto spec.

## Key storage

The drive root key at rest goes in the Keychain as a generic password with
`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`. The `ThisDeviceOnly` suffix is what keeps it out of
iCloud Keychain and encrypted backups, which is the point. Do not set `kSecAttrSynchronizable`.

Optionally gate it behind biometrics with `SecAccessControlCreateWithFlags` and
`.biometryCurrentSet`, which invalidates the item if enrolled biometrics change.

The Secure Enclave cannot store an arbitrary symmetric key. It holds P-256 keys, and now
ML-KEM-1024. The pattern, if the Enclave is wanted, is to generate a
`SecureEnclave.P256.KeyAgreement.PrivateKey`, do ECDH against a stored public key, run the shared
secret through HKDF, and use that to unwrap the root key, which then exists in memory only.

WebAuthn PRF is available in `AuthenticationServices` from iOS 18 and macOS 15, so it is fully
available on the 26 target: `ASAuthorizationPublicKeyCredentialPRFRegistrationInput`,
`ASAuthorizationPublicKeyCredentialPRFAssertionInput`, and their outputs, set through the `prf`
property on requests from `ASAuthorizationPlatformPublicKeyCredentialProvider`. PRF over external
security keys is still not implemented on iOS, so platform passkeys are the only reliable source,
and the recovery key remains mandatory.

## SwiftUI 26

The visual language is Apple's own, per the repo's default. Liquid Glass belongs on the navigation
layer only, which is both the HIG rule and what the Figma build confirmed.

| Need | API |
| --- | --- |
| Glass surface | `glassEffect(_:in:)` with `Glass.regular`, `.tint(_:)`, `.interactive()` |
| Multiple glass shapes | `GlassEffectContainer`, required for correct blending |
| Morph transitions | `glassEffectID(_:in:)` with a `@Namespace` |
| Glass buttons | `.buttonStyle(.glass)` and `.glassProminent` |
| Toolbar grouping | `ToolbarSpacer(.fixed)` and `.flexible` between item groups |
| Content behind nav | `backgroundExtensionEffect()` |
| iPhone navigation | `NavigationStack` with `navigationDestination(for:)` |
| iPad and Mac | `NavigationSplitView` |
| Tabs | `TabView` with the `Tab` value type, `Tab(role: .search)` |
| Persistent accessory | `tabViewBottomAccessory(content:)`, iOS only |
| Tab bar on scroll | `tabBarMinimizeBehavior(_:)` |
| Search placement | `SearchToolbarBehavior.minimize` |

Custom components are built custom. If a native component is hard to style to the design, build
the custom one rather than accepting the stock appearance.

## Screens

### iOS

| Screen | Notes |
| --- | --- |
| Send | Composer: picker, transport (cloud only in v1), expiry, cap, password |
| Uploading | Progress, cancel, background-safe |
| Link ready | Copy, share sheet, management warning for anonymous senders |
| Drops | List with countdowns, swipe to revoke |
| Drop detail | Counts, expiry editor, revoke |
| Receive | Password gate, file tree, download to Files |
| Settings | Account, plan, delete account, export compliance and privacy links |
| Sign-in sheet | Magic link, then passkey once the account is permanent |
| Drive | Phase 5 only |

### macOS

| Window | Notes |
| --- | --- |
| Main window | Sidebar with Send, Drops, Drive; detail pane |
| Menu bar popover | Drop target, recent drops, quick expiry |
| Drop detail | Same content as the sidebar detail, standalone |
| Settings | Tabs: General, Account, Plan, Privacy |
| Share extension | Compact composer |

## App Store compliance

This is the section that will decide whether the app ships on time. None of it is optional.

### Export compliance is the long pole

The app ships its own AES-GCM and HKDF protocol, so it is **not** exempt.
`ITSAppUsesNonExemptEncryption` is `YES`, documentation is uploaded to App Store Connect, and the
returned `ITSEncryptionExportComplianceCode` goes in `Info.plist`. Filing non-exempt documentation
with Apple removes the year-end BIS self-classification report obligation that exempt apps carry.
If distribution exceeds mass-market thresholds, a CCATS classification from BIS is needed, and
that takes weeks and blocks external TestFlight.

**Start this in parallel with development, not at submission.** It is the single most likely
schedule risk in the plan.

### Guideline 1.2, user-generated content

There is no "we cannot see the content" exemption. All four requirements apply:

1. **A method for filtering objectionable material.** Cannot be server side. Implemented at the
   sharing boundary: the recipient sees the sender is unverified, and content is not surfaced
   anywhere public.
2. **A mechanism to report offensive content, with timely responses.** The recipient-side report
   action, which optionally includes the decryption key so a human can actually review, with the
   reporter's explicit consent and an accurate explanation of what that means. See
   [05-api-contract.md](05-api-contract.md).
3. **The ability to block abusive users.** A recipient can block a drop's sender, which suppresses
   any future drop opened from the same management lineage on that device.
4. **Published contact information.** In Settings and on the web privacy page.

Guideline 1.2 is also explicitly hostile to random or anonymous chat. Position the app as directed
sharing between people who already know each other, never as anonymous broadcast. This is a real
constraint on marketing copy, not only on code.

### Guideline 5.1.1, sign-in and account deletion

An app with server-side storage and recipients has significant account-based features, so
requiring an account for the paid tier is defensible, and the free tier requires none anyway.

**If the app supports account creation, it must offer account deletion inside the app.** Build the
delete-account flow in v1. It is a common rejection and it is cheap to build early: delete the
`auth.users` row, which cascades to every table in the schema, and purge the buckets.

### Guideline 3.1.1, purchases

- Selling the subscription inside the app requires In-App Purchase. There is no exemption for
  end-to-end encryption or for cloud storage.
- Honoring a subscription bought on the web is allowed under 3.1.3(b), Multiplatform Services,
  provided the same thing is also available as an in-app purchase. So: sell through IAP in the
  app, sell through Stripe on the web, unlock both.
- **Storefront matters for linking out.** On the United States storefront, apps may include
  buttons, external links, and calls to action to a web purchase with no entitlement and no
  commission, following the 2025 injunction. Everywhere else the older regime holds: an External
  Purchase Link Entitlement is required and is only available in specific storefronts, and outside
  those, steering to non-IAP purchase is not permitted.

  So the "subscribe on the web" link is gated on storefront, and IAP is the universal in-app path.

Entitlement resolution stays server side either way. A StoreKit transaction is verified on
Railway and written into the same `subscriptions` row shape as a Stripe subscription, so
`current_plan` does not care where the money came from.

## Definition of done

1. `DropKit` passes the shared JSON test vectors from `packages/crypto/vectors/`.
2. A 10 GB upload survives backgrounding, a network change, and an app relaunch.
3. The share extension never exceeds 60 MB of resident memory on a 10 GB folder.
4. Account deletion removes every row and object, verified by a test.
5. Export compliance documentation is filed and the code is in `Info.plist`.
6. Report, block, and contact information are present and reachable.
7. Every screen renders in light and dark and at the largest Dynamic Type size.

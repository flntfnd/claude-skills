# 08. Web app

`apps/web`. Next.js 16 on Vercel. Renders every page, holds no secret, and is never in the byte
path.

## Version pins and what changed in 16

Next.js 16 removed several things a developer coming from 15 will reach for by habit.

| Thing | Status in 16 | What to do instead |
| --- | --- | --- |
| `middleware.ts` | Deprecated, still works, Edge only | Use `proxy.ts`, exporting a function named `proxy`. Node runtime only. |
| `export const runtime = 'edge'` | Deprecated | Remove the export. Everything is Node. |
| Sync `params` and `searchParams` | Removed | `await params`. Same for `cookies()`, `headers()`, `draftMode()`. |
| `experimental.ppr`, `dynamicIO`, `useCache` | Removed | One flag, `cacheComponents`. See below. |
| `revalidateTag(tag)` | Deprecated | `revalidateTag(tag, 'max')` |
| `next lint` | Removed | ESLint runs as its own CI step. `next build` no longer lints. |
| Custom `webpack` config | Fails the build | Turbopack is the default for dev and build. |
| Parallel route slot without `default.js` | Fails the build | Add `default.js` to every slot. |

Pins: Next.js 16.3 or later, React 19.2, Node 22, TypeScript 5.6.

### `cacheComponents` is off

This app caches almost nothing. Drops are private, time sensitive, and single use; the recipient
page must be request-time fresh or the countdown lies. Turning `cacheComponents` on would remove
`dynamic` and `revalidate` from the codebase and force every uncached read into a `Suspense`
boundary, for a benefit this product does not have. The four genuinely static pages, landing,
pricing, privacy, and errors, are static without it.

Recorded in [14-decisions.md](14-decisions.md). Revisit only if a marketing surface grows.

## Route map

```
app/
├── layout.tsx                    fonts, tokens, theme, CSP nonce
├── page.tsx                      landing and composer
├── d/[slug]/page.tsx             recipient
├── m/[slug]/page.tsx             management
├── drops/page.tsx                dashboard
├── drive/page.tsx                drive browser
├── settings/page.tsx             account, plan, keys
├── plans/page.tsx                pricing
├── privacy/page.tsx              threat model in plain language
├── errors/[code]/page.tsx        the tombstone and failure pages
└── api/                          nothing. There are no route handlers.
proxy.ts                          Supabase session refresh only
```

There are no route handlers on purpose. Every mutation goes to Railway, so a route handler would
be a second, weaker copy of the API contract with a 4.5 MB body limit attached to it.

## The proxy

`proxy.ts` at the project root does one thing: refresh the Supabase session cookie.

```ts
export async function proxy(request: NextRequest) {
  return await updateSession(request)
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|webp)$).*)'],
}
```

Two rules that follow from how 16 works:

- The proxy runs on the Node runtime, so `export const runtime` inside it throws.
- **The proxy is not an authorization boundary.** Server Functions post to the route they live on,
  so a matcher change can silently drop coverage. Every page that needs a user checks the user
  itself.

Session reads use `supabase.auth.getClaims()`, which verifies the JWT locally against the JWKS.
Never `getSession()` in server code. `getUser()` is a network round trip per render and is not
needed once claims are verified locally.

Cookie handling uses `getAll` and `setAll` only. `setAll` now receives a second `headers`
argument carrying `Cache-Control`, `Expires`, and `Pragma` on refresh; apply them or a CDN can
serve one user's session cookie to another.

## Rendering strategy per route

| Route | Strategy | Notes |
| --- | --- | --- |
| `/` | Static shell, client composer | The composer is a Client Component tree |
| `/d/[slug]` | Dynamic, `no-store` | Calls `get_public_drop` server side, hydrates the client decryptor |
| `/m/[slug]` | Dynamic, `no-store` | Secret is in the fragment, so the page renders empty and fills client side |
| `/drops` | Dynamic, session | Realtime subscription on the client |
| `/drive` | Dynamic, session | Locked until the root key is unwrapped in memory |
| `/plans`, `/privacy` | Static | The only two genuinely cacheable pages |

The recipient page is the one worth spelling out. The server renders everything that does not
need the key: transport, rounded size, file count, countdown, password gate, and the tombstone
when the drop is dead. The client then decrypts the manifest with the fragment key and replaces
the file list. The page is useful and honest before any JavaScript decrypts anything.

## Component structure

```
components/
├── composer/
│   ├── DropZone.tsx              drag, paste, picker, folder selection
│   ├── TransportPicker.tsx       with the honesty line for each option (P-36)
│   ├── ExpiryPicker.tsx          presets, custom duration, absolute datetime
│   ├── DownloadCapField.tsx
│   ├── PasswordField.tsx         optional, with the generated-passphrase mode (P-10)
│   ├── UploadProgress.tsx
│   └── LinkResult.tsx            copy, QR, and the management link warning
├── recipient/
│   ├── PasswordGate.tsx
│   ├── FileTree.tsx              browsable, per-file and subset selection
│   ├── TransferProgress.tsx
│   ├── SenderOffline.tsx
│   └── Tombstone.tsx
├── dashboard/
│   ├── DropRow.tsx
│   ├── Countdown.tsx
│   └── RevokeButton.tsx
├── drive/
│   ├── NodeGrid.tsx
│   ├── ActivationFlow.tsx        recovery key shown once, confirmed before upload
│   └── UnlockPrompt.tsx
└── ui/                           tokens, primitives, matching the Figma component set
```

Every component is self contained. A component reaches outside its own scope for layout only if
it is explicitly a layout component. Responsive behavior lives in tokens and components, never in
per-screen overrides.

## Client-side workers

Three, all registered from the client tree.

| Worker | Job |
| --- | --- |
| `crypto.worker.ts` | Segment encryption and decryption, BLAKE3, argon2id. The main thread never touches key material beyond handing it over once. |
| `download.sw.ts` | The streaming-download service worker, sink 3 in [07-transport-cloud.md](07-transport-cloud.md). |
| `transfer.worker.ts` | Owns the TUS upload and the WebRTC send loop so a busy main thread cannot stall the pipe. |

The key is transferred to `crypto.worker.ts` as a non-extractable `CryptoKey` where the sink
allows it. It is never placed in `localStorage`, `sessionStorage`, `IndexedDB`, or a cookie.

## Security headers

Set in `next.config.ts`, verified by a test that fetches the deployed preview and asserts each
header.

```
Content-Security-Policy: default-src 'self';
  script-src 'self' 'nonce-{nonce}' 'strict-dynamic';
  style-src 'self' 'nonce-{nonce}';
  img-src 'self' blob: data:;
  connect-src 'self' https://*.supabase.co https://*.storage.supabase.co
              wss://*.supabase.co https://api.{host};
  worker-src 'self' blob:;
  frame-ancestors 'none';
  base-uri 'none';
  form-action 'self';
  object-src 'none';
  upgrade-insecure-requests
Referrer-Policy: no-referrer
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Resource-Policy: same-origin
X-Content-Type-Options: nosniff
Permissions-Policy: camera=(), microphone=(), geolocation=(), payment=()
```

`Referrer-Policy: no-referrer` is not cosmetic. It is part of keeping the fragment key from
leaking, together with the rule that the key never enters a query string or `pushState`.

There is no third-party script tag anywhere in the app. Not for fonts, not for analytics, not for
error reporting. The CSP is what makes that a guarantee rather than an intention.

## Styling

All CSS is custom. No Tailwind, no CSS framework. Design tokens are CSS custom properties in a
single `:root` block generated from the Figma variable export, with the dark set under
`@media (prefers-color-scheme: dark)` and an explicit `[data-theme]` override so the manual toggle
wins in both directions. No magic numbers inline, ever, for color, spacing, type, radius, shadow,
or motion.

Motion uses named timing tokens. Springs for anything the user triggers, ease curves for anything
the system triggers, never linear. The specific curves come from the design spec, not from
whatever felt right.

## State

No state management library. Server Components hold server state. The composer and the transfer
UI hold their state in a reducer colocated with the feature. Realtime subscriptions live in a
hook that unsubscribes on unmount. If a piece of state seems to need a global store, it is
probably server state that was fetched in the wrong place.

## Vercel constraints that shape the design

- **Request and response bodies are capped at 4.5 MB.** This is the hard reason bytes bypass
  Vercel entirely, not a preference.
- Function duration is up to 800 seconds on Pro, which no page here comes close to needing.
- The Edge runtime is deprecated in Next.js 16, so nothing targets it.

## Accessibility

Not a phase. Every state in the state list renders correctly at 200 percent zoom, every
interactive element is keyboard reachable in a sensible order, the file tree is a real tree with
`aria-expanded`, progress uses `aria-live="polite"`, and the countdown announces at one hour, ten
minutes, and one minute rather than every second. Focus is never trapped except in a modal, and
every modal returns focus to its trigger.

## Definition of done for a screen

1. Every state from the list in [01-product-spec.md](01-product-spec.md) renders, in light and
   dark.
2. No hardcoded color, spacing, type, radius, shadow, or duration.
3. Keyboard path verified, axe reports no violations.
4. Copy matches the strings that are part of the spec, exactly.
5. A Playwright test drives the happy path and at least one failure path.

# 10. Plans and billing

One free tier, one paid tier. The numbers live in `plan_limits` and nowhere else. Changing one is
a migration, which is deliberate: a ceiling change should be reviewable.

## The plans

| | Free | Paid |
| --- | --- | --- |
| Peer-to-peer drops | Yes | Yes |
| Cloud drop size | 5 GB per drop | 50 GB per drop |
| Files per drop | 2,000 | 20,000 |
| Expiry ceiling | 7 days | 365 days |
| Never expires | No | Drive-backed drops only |
| Active drops | 50 | 5,000 |
| Download caps, passwords, revoke | Yes | Yes |
| Request mode inbound | 1 GB | 10 GB |
| Persistent drive | No | 1 TB |
| Relay quota per month | 100 GB | 1 TB |
| Concurrent p2p recipients | 8 | 16 |
| Account required | No | Yes, email or passkey |

These are opening numbers, not researched prices. The relay quota is the one to watch, because
Cloudflare bills $0.05 per GB above the first free terabyte across the whole account, so a free
tier at 100 GB per user is only viable while the user count is small. Model this before launch;
it is an open decision in [14-decisions.md](14-decisions.md).

## How an entitlement is decided

One path, no exceptions.

```
 client asks for something
        │
        ▼
 Railway resolves current_plan(auth.uid())
        │  reads subscriptions, checks status and period end
        ▼
 Railway reads plan_limits for that plan
        │
        ▼
 allow, or a plan_ceiling_* error naming the limit and the plan that raises it
        │
        ▼
 the drops trigger re-checks the same ceilings on write
```

The client never decides. The expiry dropdown renders what `GET /v1/plans` returns; it does not
know the rules. If the API and the UI ever disagree, the API wins and the UI is the bug.

`current_plan` returns `paid` only for `active` and `trialing` with a period end in the future.
Everything else resolves to `free`.

## Grace behavior

A lapsed subscription must never destroy data. It restricts new actions only.

| State | Effect |
| --- | --- |
| `past_due` | Resolves to `free`. Existing drops and drive files are untouched. New drops fall under free ceilings. Drive uploads are refused; drive reads and shares still work. |
| `canceled`, `unpaid` | Same as `past_due`, plus a banner with a deadline. |
| Over drive quota after downgrade | Reads, downloads, deletes, and shares all keep working. Uploads are refused until the user is under quota. Nothing is deleted automatically, ever. |
| Drop with a 365 day expiry after downgrade | Honored to its existing expiry. Only extensions are capped. |

Automatic deletion on downgrade is not implemented and should not be. Deleting a paying customer's
files because a card expired is the kind of thing that ends a product.

## Stripe

Pins: API version `2026-08-26.dahlia`, `stripe` Node SDK v22.

### Checkout

```ts
const session = await stripe.checkout.sessions.create({
  mode: 'subscription',
  line_items: [{ price: env.STRIPE_PRICE_ID, quantity: 1 }],
  client_reference_id: userId,               // the Supabase auth.uid()
  customer: existingCustomerId ?? undefined,
  success_url: `${env.WEB_URL}/settings?session_id={CHECKOUT_SESSION_ID}`,
  cancel_url: `${env.WEB_URL}/plans`,
})
```

`client_reference_id` is how a Stripe object maps back to a user. Never pass an email that the
user did not type into Stripe themselves.

### Customer portal

```ts
await stripe.billingPortal.sessions.create({ customer, return_url: `${env.WEB_URL}/settings` })
```

The portal must be configured in the Stripe dashboard **per mode**, live and each sandbox
separately. Skipping this is a common launch blocker and it fails at runtime, not at deploy.

### Fulfillment

Stripe does not promise event ordering, so the design is idempotency plus re-fetch, never
sequencing.

```ts
// Called from the webhook and from the success_url landing page. Safe to call concurrently.
async function fulfillCheckout(sessionId: string) {
  const session = await stripe.checkout.sessions.retrieve(sessionId, {
    expand: ['line_items', 'subscription'],
  })
  if (session.payment_status === 'unpaid') return
  await syncSubscription(session.subscription as Stripe.Subscription, session.client_reference_id)
}
```

`syncSubscription` re-reads the subscription from Stripe and writes the current state. It never
computes state from the event payload, and it is a single upsert so concurrent calls converge.

### Webhook events

The webhook lands on a Supabase Edge Function, not on Railway, because it is exactly the
"validate a signature and write one row" job Edge Functions exist for.

| Event | Action |
| --- | --- |
| `checkout.session.completed` | `fulfillCheckout` |
| `checkout.session.async_payment_succeeded` | `fulfillCheckout` |
| `customer.subscription.created` | `syncSubscription` |
| `customer.subscription.updated` | `syncSubscription` |
| `customer.subscription.deleted` | `syncSubscription`, resolves to free |
| `invoice.paid` | `syncSubscription` |
| `invoice.payment_failed` | `syncSubscription` |
| `invoice.payment_action_required` | `syncSubscription`, sets a banner flag |
| `customer.subscription.trial_will_end` | `syncSubscription` |

Provision on `active` or `trialing`. Revoke on `canceled` and `unpaid`, not on `past_due`.

Note for the `dahlia` API version: `invoice.subscription` moved to
`invoice.parent.subscription_details.subscription`. Code written against an older example will
read `undefined` and silently do nothing.

Checkout waits up to ten seconds for a `2xx` from the `checkout.session.completed` handler before
redirecting the user, so the handler must be fast. It writes the row and returns; it does not do
anything else.

### The Edge Function

```ts
import Stripe from 'npm:stripe@^22'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
  apiVersion: '2026-08-26.dahlia',
  httpClient: Stripe.createFetchHttpClient(),
})
const cryptoProvider = Stripe.createSubtleCryptoProvider()

const event = await stripe.webhooks.constructEventAsync(
  await req.text(),                                  // raw body, never req.json()
  req.headers.get('Stripe-Signature')!,
  Deno.env.get('STRIPE_WEBHOOK_SECRET')!,
  undefined,
  cryptoProvider,
)
```

Deployed with JWT verification off, because Stripe does not send a Supabase token. The signature
is the authentication. Runtime is Deno 2.1; the entrypoint is the current
`export default { fetch: withSupabase({ auth: 'none' }, handler) }` form.

Limits to respect: 2 seconds of CPU per request, which is ample for a signature check and an
upsert, and 150 seconds of wall clock.

## What is stored about a paying customer

Exactly this, and the UI says so before checkout:

```
 user_id, stripe_customer_id, stripe_subscription_id, plan, status,
 current_period_end, cancel_at_period_end
```

No name, no address, no card, no email beyond what Supabase Auth already holds for the account. If
a future feature wants a billing address, it needs an entry in
[14-decisions.md](14-decisions.md) and a change to the honesty copy in
[01-product-spec.md](01-product-spec.md).

## In-app purchase

The Apple apps sell through StoreKit, because guideline 3.1.1 requires it and there is no
exemption. Railway verifies the StoreKit transaction and writes the same `subscriptions` row
shape, with `stripe_customer_id` replaced by the App Store original transaction id in a nullable
sibling column. `current_plan` does not care which one paid.

A subscription bought on the web unlocks the app under guideline 3.1.3(b), and a subscription
bought in the app unlocks the web. Both are the same row.

## Relay metering

Sender clients report relayed bytes at the end of a peer-to-peer session, which is advisory.
Cloudflare's own metering is authoritative and is reconciled daily by a Railway job that updates
`relay_usage`. A sender over quota is refused new TURN credentials with `quota_exceeded`; sessions
already running are not cut off mid-transfer.

The sender's page shows remaining relay budget once the account is within 20 percent of its
ceiling, and not before, because showing a quota meter to someone who will never hit it is noise.

## Tests

| Test | Asserts |
| --- | --- |
| `current_plan` matrix | Every Stripe status maps to the right plan, including expired period ends |
| Idempotent fulfillment | Ten concurrent `fulfillCheckout` calls produce one row and one state |
| Out-of-order events | `subscription.updated` before `checkout.session.completed` converges |
| Signature rejection | A tampered body is rejected |
| Downgrade safety | A downgraded user over quota can still read, download, share, and delete |
| Ceiling enforcement | Free plan cannot create an 8 day expiry, a 6 GB drop, or a drive node |
| StoreKit parity | A StoreKit-sourced row and a Stripe-sourced row resolve identically |

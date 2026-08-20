## Contents

- [Required HTTP headers](#required-http-headers)
- [Content Security Policy](#content-security-policy)
- [Input validation](#input-validation)
- [Core Web Vitals](#core-web-vitals)
- [Asset optimization](#asset-optimization)
- [Bundle strategy](#bundle-strategy)

## Required HTTP headers

Deploy all of these. They block entire classes of attacks with no application code:

```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "DENY" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "camera=(), microphone=(), geolocation=(self)" always;
add_header Cross-Origin-Opener-Policy "same-origin" always;
```

**HSTS**: forces HTTPS for the specified duration. Include `preload` and submit to the HSTS preload list. Don't set it before HTTPS is fully working.

**X-Content-Type-Options: nosniff**: prevents MIME-type sniffing attacks. Set on every response.

**X-Frame-Options: DENY**: blocks the page from being embedded in iframes on other sites — clickjacking prevention. The modern equivalent is CSP `frame-ancestors 'none'`; set both.

**Referrer-Policy**: `strict-origin-when-cross-origin` sends origin only to different origins, full URL to same origin.

**Permissions-Policy**: restricts which browser APIs the page can use and which can be delegated to iframes.

## Content Security Policy

CSP is the most powerful XSS defense. Deploy in report-only mode first, then enforce:

```http
# Report-only (during rollout)
Content-Security-Policy-Report-Only: default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; object-src 'none'; base-uri 'self'; frame-ancestors 'none'; form-action 'self'; report-uri /csp-report

# Enforced (production)
Content-Security-Policy: default-src 'self'; script-src 'self' 'nonce-{RANDOM}'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; object-src 'none'; base-uri 'self'; frame-ancestors 'none'; form-action 'self'
```

Use nonces for inline scripts instead of `'unsafe-inline'`:

```html
<script nonce="r4nd0mN0nc3PerRequest">
    // This inline script is allowed
</script>
```

## Input validation

Validate all input server-side. Client-side validation is UX, not security.

```typescript
import { z } from "zod";

const UserSchema = z.object({
    email: z.string().email().max(255),
    username: z.string().min(3).max(20).regex(/^[a-zA-Z0-9_]+$/),
    age: z.number().int().min(13).max(120),
});

export async function createUser(input: unknown) {
    const result = UserSchema.safeParse(input);
    if (!result.success) {
        return { error: result.error.flatten() };
    }
    await db.users.create({ data: result.data });
}
```

## Core Web Vitals

Three metrics, measured at the 75th percentile of real user data.

**LCP (Largest Contentful Paint) ≤ 2.5s** — time until the largest visible content element renders. Usually a hero image or large text block.

Fixes in priority order:
1. Preload the LCP image: `<link rel="preload" as="image" fetchpriority="high">`
2. Use `fetchpriority="high"` on the `<img>` element directly
3. No lazy loading on the LCP image (never `loading="lazy"` on hero images)
4. Optimize image format (WebP/AVIF) and file size
5. Reduce TTFB: faster server, CDN, edge deployment
6. Eliminate render-blocking CSS and JS in `<head>`

**INP (Interaction to Next Paint) ≤ 200ms** — time from user interaction to the browser painting the next frame. Measures every interaction, not just the first (replaced FID).

Fixes:
1. Reduce JavaScript bundle size
2. Code-split: load only what's needed for the current page
3. Defer non-critical third-party scripts with `defer` or `async`
4. Break long tasks into smaller chunks with `scheduler.yield()` or `setTimeout`
5. Move heavy processing to Web Workers
6. Avoid synchronous layout reads mid-animation (forced reflow)

**CLS (Cumulative Layout Shift) ≤ 0.1** — unexpected layout shifts during page load.

Fixes:
1. Always set `width` and `height` on images and video
2. Reserve space for ads, embeds, and dynamically injected content
3. Never inject content above existing content
4. Use `font-display: swap` or `optional` for web fonts
5. Avoid CSS animations that change layout properties

## Asset optimization

```html
<link rel="preconnect" href="https://api.example.com" />
<link rel="prefetch" href="/next-page.html" />
<link rel="preload" as="font" href="/font.woff2" crossorigin />
<link rel="preload" as="image" href="/hero.webp" fetchpriority="high" />

<!-- async for independent scripts, defer for execution-order-sensitive ones -->
<script async src="/analytics.js"></script>
<script defer src="/app.js"></script>
<!-- Never a synchronous <script> block in <head> without async/defer -->
```

## Bundle strategy

- Ship less JavaScript. Move logic to the server.
- Measure bundle with `next build --analyze` (Next.js) or `astro build --verbose` (Astro)
- Dynamic imports for route-level and component-level code splitting
- Tree-shake libraries: import named exports, not entire libraries
- Audit third-party scripts — every analytics, chat, and marketing tag has a cost

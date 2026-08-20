---
name: web-platform
description: Modern web development reference covering HTML5, CSS (cascade layers, oklch, container queries, :has(), nesting, subgrid, anchor positioning, scroll-driven animations), JavaScript/TypeScript (ES2025/2026, Temporal, strict TS patterns), Next.js App Router (Server/Client Components, Cache Components, "use cache", proxy.ts, Server Actions), Astro (islands, Content Layer API, Server Islands), Supabase SSR integration with Vercel/Railway lane rules, WCAG 2.2 accessibility, mobile web and PWA, Core Web Vitals performance, HTTP security headers and CSP, and advanced visual techniques (blend modes, clip-path, SVG, Canvas 2D). Use when building, reviewing, or debugging any web frontend or full-stack code — pages, components, forms, layouts, routing, auth flows, animations, or performance and accessibility fixes.
---

# Web Platform

Reference for building on the current web platform: browser-native HTML/CSS/JS, the Next.js App Router, Astro, and Supabase-backed auth, plus the accessibility, performance, security, and visual-craft details that separate hand-built work from generic component-library output.

Evergreen browser targets. No IE, no legacy polyfills unless explicitly required. Mobile-first: design and build for the 75th-percentile user — a mid-range Android device on a cell network — not a desktop monitor.

JavaScript is responsible for most performance problems. Load less of it. Move logic to the server where possible. If a UI behavior can be done in CSS, do it in CSS — CSS runs on the compositor thread, JavaScript doesn't.

## Quick Reference

| Topic | Reference file |
| --- | --- |
| Document structure, semantic elements, images, forms, dialog/popover | [reference/html.md](reference/html.md) |
| Cascade layers, oklch, nesting, container queries, `:has()`, fluid type, subgrid, `@property`, `@starting-style`, anchor positioning, scroll-driven animations | [reference/css.md](reference/css.md) |
| ES2025/2026, Temporal, TypeScript strict patterns, async patterns, modules | [reference/javascript-typescript.md](reference/javascript-typescript.md) |
| App Router, Server/Client Components, Cache Components & `"use cache"`, `proxy.ts`, Server Actions, revalidation | [reference/nextjs.md](reference/nextjs.md) |
| Islands architecture, Content Layer API, Server Islands | [reference/astro.md](reference/astro.md) |
| `@supabase/ssr` client setup, session refresh, `getUser()`/`getClaims()`, lane rules in code | [reference/supabase-integration.md](reference/supabase-integration.md) |
| WCAG 2.2 AA, contrast, keyboard nav, ARIA, screen readers | [reference/accessibility.md](reference/accessibility.md) |
| Mobile-first CSS, touch targets, viewport/zoom, PWA | [reference/mobile-web.md](reference/mobile-web.md) |
| Error/loading boundaries, Server Action error results | [reference/error-handling.md](reference/error-handling.md) |
| HTTP headers, CSP, input validation, Core Web Vitals, bundle strategy | [reference/security-performance.md](reference/security-performance.md) |
| Blend modes, clip-path, filters, custom cursor, SVG, Canvas 2D | [reference/advanced-visual-techniques.md](reference/advanced-visual-techniques.md) |
| Baseline support targets, cross-browser testing checklist | [reference/browser-compatibility.md](reference/browser-compatibility.md) |

## Load-bearing facts

These come up on nearly every web task, so they're inlined rather than left behind a link.

**CSS layer order.** Declare it once at the top of the root stylesheet — it eliminates specificity wars, since a later layer always beats an earlier one regardless of selector specificity:

```css
@layer reset, base, tokens, components, utilities, overrides;
```

**Only animate `transform` and `opacity`.** They run on the compositor thread. `width`, `height`, `top`, `left`, `margin`, `padding` trigger layout on every frame.

**Colors: use `oklch()`.** `oklch(lightness chroma hue)` is perceptually uniform and predictable when adjusting lightness — unlike HSL, where lightness shifts hue perception. Never hardcode raw hex/rgb for design tokens.

**Server Components are the Next.js default.** No `"use client"` needed for anything that doesn't touch `useState`, `useEffect`, browser APIs, or event handlers. Keep Client Components at the leaves; Server Components compose them, not the other way around.

**`cookies()`, `headers()`, `params`, and `searchParams` are fully async** in current Next.js — always `await` them, there is no sync fallback. `middleware.ts` is deprecated in favor of `proxy.ts` (same logic, renamed file and export). See `reference/nextjs.md`.

**Every input needs a `<label>`.** Never use placeholder text as a label substitute. Validate server-side always — client-side validation is UX, not security.

### Lane rules enforced in code (Supabase / Vercel / Railway)

The stack's Vercel/Railway/Supabase lane boundaries (defined at the repo level, not repeated here) show up concretely in how the Supabase client is constructed per environment:

```typescript
// lib/supabase/server.ts -- Vercel, Server Components / Actions / Route Handlers
// Anon key only. Never service_role here.
import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

export async function createClient() {
    const cookieStore = await cookies(); // async -- must await
    return createServerClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,   // anon key: safe for Vercel
        {
            cookies: {
                getAll() { return cookieStore.getAll(); },
                setAll(cookiesToSet) {
                    cookiesToSet.forEach(({ name, value, options }) =>
                        cookieStore.set(name, value, options)
                    );
                },
            },
        }
    );
}
```

RLS via `auth.uid()` is the actual security boundary — this client just carries the user's session. If a query needs `service_role`, it belongs on Railway behind an API endpoint, never in a Vercel Server Action. Full pattern, including the `proxy.ts` session-refresh middleware and `getUser()` vs `getClaims()`, is in `reference/supabase-integration.md`.

## Common mistakes

| Mistake | Why it's wrong |
| --- | --- |
| JS-computed sizing/scroll toggling instead of container queries / scroll-driven animations | CSS runs on the compositor thread; JS layout reads force reflow |
| `any` in TypeScript | Type-safety hole. Use `unknown` and narrow explicitly |
| Default exports everywhere | Harder to refactor, auto-import, and tree-shake than named exports |
| Animating `width`/`height`/`top`/`left`/`margin`/`padding` | Triggers layout every frame; animate `transform`/`opacity` instead |
| `outline: none` with no replacement | Fails WCAG 2.4.7 — always provide a visible focus indicator |
| `user-scalable=no` / `maximum-scale=1` in viewport meta | Blocks zoom; WCAG 1.4.4 violation |
| `html { font-size: <16px }` or the `62.5%` rem hack | Overrides user font-size preference |
| Autoplaying media with sound | Banned by WCAG 1.4.2 without a pause control |
| Placeholder text as a label | Disappears on input; screen readers don't announce it consistently |
| Infinite scroll with no alternative | Keyboard/screen-reader users lose navigation and scope; provide pagination |
| Importing a whole library for one function (`moment`, `lodash` for `debounce`) | Real bundle-size cost for code that's a few lines |
| Missing `width`/`height` on images | Causes CLS |
| `loading="lazy"` on the LCP image, or missing `fetchpriority="high"` on it | Directly hurts LCP |
| Sync `cookies()`/`headers()`/`params` access in Next.js | Removed — these are async-only now, code will throw |
| `middleware.ts` in a Next.js 16 project | Deprecated; rename to `proxy.ts` |
| Plain `@supabase/supabase-js` client in a Server Component | Doesn't handle cookie refresh; use `@supabase/ssr` |

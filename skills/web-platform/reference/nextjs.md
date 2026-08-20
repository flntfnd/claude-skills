Next.js 16 (React 19.2) is current stable, released October 2025 and iterated through 2026. It changed enough from Next.js 15 that code written against 15-era assumptions will break. The differences that matter most: Turbopack is now the default bundler, `middleware.ts` is deprecated in favor of `proxy.ts`, every previously-sync request API is now fully async with no sync fallback, and the caching model has shifted from implicit to explicit opt-in via `"use cache"` / Cache Components.

<details>
<summary>Verify before relying on: Next.js version drift</summary>

This reference targets Next.js 16.x as documented at nextjs.org in August 2026. Next.js ships fast — check `nextjs.org/blog` for anything past 16.x before assuming this is still current.
</details>

## Contents

- [File system and routing](#file-system-and-routing)
- [Server vs Client Components](#server-vs-client-components)
- [Caching: Cache Components and "use cache"](#caching-cache-components-and-use-cache)
- [proxy.ts (formerly middleware.ts)](#proxyts-formerly-middlewarets)
- [Async request APIs](#async-request-apis)
- [Server Actions](#server-actions)
- [Revalidation APIs](#revalidation-apis)
- [Image optimization](#image-optimization)
- [Fonts](#fonts)

## File system and routing

```
app/
├── layout.tsx          ← root layout (required), renders <html> and <body>
├── page.tsx            ← index route
├── loading.tsx         ← Suspense fallback during data waits
├── error.tsx           ← error boundary
├── not-found.tsx       ← 404 handler
├── globals.css
├── (marketing)/        ← route group, doesn't affect URL
│   ├── layout.tsx      ← shared layout for group
│   ├── page.tsx        ← /
│   └── about/page.tsx  ← /about
├── products/
│   ├── page.tsx        ← /products
│   └── [id]/page.tsx   ← /products/[id]
├── @modal/              ← parallel route slot
│   └── default.tsx      ← REQUIRED in Next.js 16: build fails without it
└── api/
    └── route.ts        ← route handler (GET, POST, etc.)
```

Every parallel route slot needs an explicit `default.js`/`default.tsx` as of Next.js 16 — builds fail without one. Have it call `notFound()` or return `null` to match the old implicit behavior.

## Server vs Client Components

The default is Server Components. They render on the server, produce HTML, ship zero JavaScript. Use them for everything that doesn't need interactivity.

```tsx
// Server Component (default) -- no "use client" needed
// Can: fetch data, access server resources, import server-only packages
// Cannot: use useState, useEffect, browser APIs, event handlers
export default async function ProductList() {
    const products = await db.products.findMany();
    return (
        <ul>
            {products.map(p => <li key={p.id}>{p.name}</li>)}
        </ul>
    );
}
```

```tsx
// Client Component -- add "use client" at top
// Can: useState, useEffect, event handlers, browser APIs
// Cannot: be async, access server resources directly
"use client";
import { useState } from "react";

export function Counter() {
    const [count, setCount] = useState(0);
    return <button onClick={() => setCount(c => c + 1)}>{count}</button>;
}
```

Keep Client Components at the leaves. Compose Server Components that import Client Components, not the other way around.

```tsx
export default async function Page() {
    const data = await fetchData(); // runs on server
    return (
        <ServerRenderedContent data={data}>
            <InteractiveWidget />  {/* Client Component island */}
        </ServerRenderedContent>
    );
}
```

## Caching: Cache Components and "use cache"

Next.js 16 reverses the App Router's default caching stance. In Next.js 15 and earlier, `fetch()` in a Server Component was cached by default unless told otherwise. In Next.js 16 with Cache Components enabled, **all dynamic code runs at request time by default** — caching is opt-in via the `"use cache"` directive, not implicit.

Enable it in config:

```ts
// next.config.ts
const nextConfig = {
    cacheComponents: true,
};
export default nextConfig;
```

```tsx
// Cache a function, component, or entire page with "use cache"
async function getPosts() {
    "use cache";
    return db.posts.findMany();
}
```

`cacheLife` and `cacheTag` are stable (no more `unstable_` prefix):

```ts
import { cacheLife, cacheTag } from "next/cache";

async function getPost(id: string) {
    "use cache";
    cacheTag(`post-${id}`);
    cacheLife("hours");
    return db.posts.findById(id);
}
```

<details>
<summary>Legacy / deprecated: pre-16 fetch caching</summary>

Before Cache Components, `fetch()` caching was controlled by options passed directly to fetch, and this pattern still works outside Cache Components mode:

```tsx
// Static: cached indefinitely, revalidated on deploy
const data = await fetch('https://api.example.com/posts');

// ISR: revalidate every 60 seconds
const data = await fetch('https://api.example.com/posts', {
    next: { revalidate: 60 }
});

// Dynamic: not cached, runs on every request
const data = await fetch('https://api.example.com/user', { cache: 'no-store' });

// Route segment config
export const dynamic = 'force-dynamic';  // SSR
export const revalidate = 3600;          // ISR, 1 hour
```

`experimental.dynamicIO`, `experimental.useCache`, `experimental.ppr`, and route-level `export const experimental_ppr` were all removed in Next.js 16. If migrating from any of them, adopt top-level `cacheComponents` instead — it is not a drop-in rename; enabling it can surface build errors for uncached data used outside `<Suspense>`.
</details>

## proxy.ts (formerly middleware.ts)

`middleware.ts` is deprecated. Rename the file to `proxy.ts` and the exported function to `proxy` — logic is unchanged. `proxy.ts` runs on the Node.js runtime only (not Edge); if Edge runtime is required, `middleware.ts` still works but is deprecated and slated for removal.

```ts
// proxy.ts
import { NextResponse, type NextRequest } from "next/server";

export default function proxy(request: NextRequest) {
    return NextResponse.redirect(new URL('/home', request.url));
}

export const config = {
    matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
```

Config flags renamed accordingly: `skipMiddlewareUrlNormalize` → `skipProxyUrlNormalize`.

## Async request APIs

`cookies()`, `headers()`, `draftMode()`, `params`, and `searchParams` are fully async in Next.js 16 — the temporary synchronous compatibility mode from Next.js 15 was removed. Always `await` them; there is no sync fallback.

```tsx
export default async function Page(props: PageProps<'/blog/[slug]'>) {
    const { slug } = await props.params;
    const query = await props.searchParams;
    return <h1>Blog Post: {slug}</h1>;
}
```

Run `npx next typegen` to generate `PageProps`/`LayoutProps`/`RouteContext` helpers for type-safe async params.

## Server Actions

Server Actions replace API routes for mutations. Mark functions with `'use server'`.

```tsx
// actions/posts.ts
"use server";
import { db } from "@/lib/db";
import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";

export async function createPost(formData: FormData) {
    const title = formData.get("title") as string;
    const body = formData.get("body") as string;
    if (!title || !body) return { error: "Title and body required" };

    await db.posts.create({ data: { title, body } });
    revalidatePath("/posts");
    redirect("/posts");
}
```

```tsx
"use client";
import { createPost } from "@/actions/posts";

export function CreatePostForm() {
    return (
        <form action={createPost}>
            <input name="title" placeholder="Title" required />
            <textarea name="body" placeholder="Content" required />
            <button type="submit">Publish</button>
        </form>
    );
}
```

## Revalidation APIs

Three distinct tools, pick by what the user needs to see:

| API | Where | Semantics | Use for |
| --- | --- | --- | --- |
| `revalidateTag(tag, profile)` | anywhere | stale-while-revalidate; **profile argument now required** | content that can tolerate eventual consistency (blog posts, catalogs) |
| `updateTag(tag)` | Server Actions only | read-your-writes — expires and refetches within the same request | user just made a change and must see it immediately (settings, profile edits) |
| `refresh()` | Server Actions only | refreshes uncached data only, doesn't touch the cache | live counters/badges fetched separately from the cached page shell |

```ts
"use server";
import { revalidateTag, updateTag, refresh } from "next/cache";

// Eventual consistency is fine
revalidateTag("blog-posts", "max"); // second arg is a cacheLife profile now required

// User needs to see their own change immediately
export async function updateUserProfile(userId: string, profile: Profile) {
    await db.users.update(userId, profile);
    updateTag(`user-${userId}`);
}

// Uncached badge count elsewhere on the page
export async function markNotificationAsRead(id: string) {
    await db.notifications.markAsRead(id);
    refresh();
}
```

The old single-argument `revalidateTag('tag')` is deprecated and now produces a TypeScript error — always pass a `cacheLife` profile (`'max'` covers most cases) or an inline `{ expire: seconds }`.

## Image optimization

```tsx
import Image from "next/image";

<Image
    src="/hero.jpg"
    alt="Hero description"
    width={1200}
    height={600}
    priority           // for LCP images above the fold
    sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
/>
```

Next.js 16 changed several image defaults: `images.minimumCacheTTL` is now 4 hours (was 60s), `images.qualities` defaults to `[75]` only (was 1–100 — an out-of-range `quality` prop is coerced to the nearest allowed value), and local images with query strings need `images.localPatterns` configured or they're blocked (enumeration-attack mitigation). `images.domains` is deprecated — use `images.remotePatterns`.

## Fonts

```tsx
import { Inter, Roboto_Mono } from "next/font/google";

const inter = Inter({ subsets: ["latin"], variable: "--font-inter", display: "swap" });
const mono = Roboto_Mono({ subsets: ["latin"], variable: "--font-mono" });

export default function RootLayout({ children }) {
    return (
        <html lang="en" className={`${inter.variable} ${mono.variable}`}>
            <body>{children}</body>
        </html>
    );
}
```

`next/font` eliminates FOUT, layout shift, and external network requests by self-hosting and inlining font metadata at build time.

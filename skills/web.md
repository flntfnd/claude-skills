# WEB.md
Modern web development. HTML5, CSS, JavaScript/TypeScript, Next.js, Astro, accessibility, performance, security, mobile web.
Current as of 2026. Evergreen browser targets. No IE. No legacy polyfills unless explicitly required.

---

# Philosophy

The browser platform is the stable layer under every framework. Know it. The CSS features that were "cutting edge" in 2024 are production baselines in 2026. Container queries, cascade layers, native nesting, `:has()`, scroll-driven animations -- these are not experimental. Ship them.

JavaScript is responsible for most performance problems. Load less of it. Move logic to the server where possible. Reserve client-side JavaScript for things that are genuinely interactive. If you can do it in CSS, do it in CSS.

The web is not a desktop app. Design and build mobile-first. Over 60% of web traffic is mobile. The 75th percentile of your users is probably on a mid-range Android device on a cell network. Optimize for that.

Accessibility is not an add-on. WCAG 2.2 Level AA is the legal minimum in most jurisdictions. Build it in from the start. It's far cheaper to fix in design than after deployment.

Research before building. The web moves fast and wrong patterns accumulate fast. If the current API for something is unclear, look it up before writing code.

---

# HTML5

## Document Structure

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="description" content="Page description under 160 chars" />
    <title>Page Title | Site Name</title>
    <link rel="canonical" href="https://example.com/page" />

    <!-- Preconnect for critical third-party origins -->
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />

    <!-- Preload LCP image -->
    <link rel="preload" as="image" href="/hero.webp" fetchpriority="high" />

    <!-- Critical CSS inlined, deferred CSS loaded async -->
    <style>/* critical styles */</style>
    <link rel="stylesheet" href="/styles.css" />
</head>
<body>
    <header>
        <nav aria-label="Main navigation">
            <a href="/" aria-current="page">Home</a>
        </nav>
    </header>
    <main id="main-content">
        <h1>Page Heading</h1>
    </main>
    <footer>
        <!-- footer content -->
    </footer>
</body>
</html>
```

Never omit `lang` on `<html>`. Never remove the viewport meta tag. Never set `user-scalable=no` or `maximum-scale=1` -- this blocks zoom for users with low vision.

## Semantic Elements

Use semantic elements. The browser accessibility tree is built from them.

```html
<!-- Document structure -->
<header>     Site header, navigation
<nav>        Navigation landmarks (multiple allowed with aria-label)
<main>       Primary content (one per page)
<article>    Self-contained content (blog post, product card)
<section>    Thematic grouping with a heading
<aside>      Tangentially related content, sidebars
<footer>     Footer content

<!-- Content -->
<h1>–<h6>   Heading hierarchy (don't skip levels)
<p>          Paragraphs
<ul> <ol>    Lists
<figure> <figcaption>  Media with captions
<time datetime="2026-04-13">April 13, 2026</time>
<address>    Contact info for nearest <article> or <body>
<mark>       Highlighted text
<details> <summary>    Disclosure widget

<!-- Interactive -->
<button>     Clickable actions (not links)
<a href="…"> Navigation and external links
<form>       Form containers
<label>      Form labels (always associated with inputs)
<input> <textarea> <select>  Form controls
<dialog>     Modal dialogs
```

Never use `<div>` or `<span>` for interactive elements. Never use `<div onclick>`. If it needs to be clickable, use `<button>`. If it navigates somewhere, use `<a>`.

## Images

```html
<!-- Always set width and height to prevent CLS -->
<img
    src="/image.webp"
    alt="Descriptive alternative text"
    width="800"
    height="400"
    loading="lazy"
/>

<!-- LCP image: no lazy loading, high fetch priority -->
<img
    src="/hero.webp"
    alt="Hero description"
    width="1200"
    height="600"
    fetchpriority="high"
/>

<!-- Responsive images -->
<img
    srcset="/image-400.webp 400w, /image-800.webp 800w, /image-1200.webp 1200w"
    sizes="(max-width: 600px) 100vw, (max-width: 900px) 50vw, 800px"
    src="/image-800.webp"
    alt="Description"
    width="800"
    height="400"
    loading="lazy"
/>

<!-- Decorative image (empty alt, no role) -->
<img src="/decoration.svg" alt="" />
```

Use WebP or AVIF formats. AVIF has better compression but slower encoding. WebP is safe for all browsers 2026. Never serve JPEG/PNG for UI images unless the image is a photo where quality is paramount.

## Forms

```html
<form method="post" action="/submit" novalidate>
    <!-- novalidate when using custom validation -->

    <div class="field">
        <label for="email">
            Email address
            <span aria-hidden="true">*</span>
        </label>
        <input
            type="email"
            id="email"
            name="email"
            autocomplete="email"
            required
            aria-required="true"
            aria-describedby="email-error"
        />
        <span id="email-error" role="alert" aria-live="polite">
            <!-- Error message inserted here by JS -->
        </span>
    </div>

    <button type="submit">Submit</button>
</form>
```

Every input needs a `<label>`. Never use placeholder text as a label substitute -- it disappears when the user types. `autocomplete` attributes speed up mobile form fill significantly. Always validate server-side. Client-side validation is UX, not security.

---

# CSS

## Architecture

Organize CSS with cascade layers. Define layer order at the top of your root stylesheet:

```css
@layer reset, base, tokens, components, utilities, overrides;
```

- **reset**: normalize browser defaults
- **base**: global element styles (body, typography, links)
- **tokens**: custom properties (design tokens)
- **components**: UI component styles
- **utilities**: single-purpose helpers
- **overrides**: page-specific adjustments, theme overrides

Each layer overrides the one before it regardless of specificity. This eliminates specificity wars. No more `!important` for specificity issues.

```css
@layer reset {
    *, *::before, *::after {
        box-sizing: border-box;
        margin: 0;
        padding: 0;
    }
    img, video { max-width: 100%; display: block; }
}

@layer tokens {
    :root {
        --color-primary: oklch(55% 0.2 260);
        --color-surface: oklch(98% 0 0);
        --color-text: oklch(15% 0 0);
        --space-base: 1rem;
        --radius-sm: 0.25rem;
        --radius-md: 0.5rem;
        --font-body: 'Inter', system-ui, sans-serif;
    }
}
```

## Custom Properties (CSS Variables)

Design tokens live as custom properties. Never hardcode colors, spacing, or typography values.

```css
/* Token architecture: primitive → semantic → component */

/* Primitives */
:root {
    --color-blue-500: oklch(60% 0.2 260);
    --space-4: 1rem;
    --font-size-base: 1rem;
}

/* Semantic */
:root {
    --color-interactive: var(--color-blue-500);
    --space-content: var(--space-4);
    --font-size-body: var(--font-size-base);
}

/* Dark mode */
@media (prefers-color-scheme: dark) {
    :root {
        --color-surface: oklch(15% 0 0);
        --color-text: oklch(95% 0 0);
    }
}

/* Component */
.button {
    background: var(--color-interactive);
    padding: var(--space-content);
}
```

Use `oklch()` for colors in 2026. It's perceptually uniform, supports wide-gamut P3 displays, and produces predictable results when adjusting lightness and chroma. `oklch(lightness chroma hue)`. Lightness 0-100%, chroma 0-0.4, hue 0-360.

```css
/* oklch examples */
:root {
    --color-primary:      oklch(55% 0.20 260);   /* blue */
    --color-primary-dark: oklch(40% 0.20 260);   /* darker blue */
    --color-primary-pale: oklch(92% 0.05 260);   /* tint for backgrounds */

    /* Relative color syntax (Level 4) */
    --color-hover: oklch(from var(--color-primary) calc(l - 0.1) c h);
}
```

## Native Nesting

```css
/* 2026: native nesting, no preprocessor needed */
.card {
    background: var(--color-surface);
    border-radius: var(--radius-md);
    padding: 1.5rem;

    & .card-title {
        font-size: 1.25rem;
        font-weight: 600;
    }

    &:hover {
        outline: 2px solid var(--color-interactive);
    }

    &.card--featured {
        border-left: 4px solid var(--color-primary);
    }

    @media (width > 768px) {
        padding: 2rem;
    }
}
```

Supported: Chrome 112+, Firefox 117+, Safari 16.5+. Production safe in 2026.

## Container Queries

Container queries are the correct tool for component-level responsiveness. Media queries govern the viewport. Container queries govern the component.

```css
/* Define a container context */
.card-wrapper {
    container-type: inline-size;
    container-name: card;
}

/* Style based on container width, not viewport */
@container card (width < 400px) {
    .card {
        flex-direction: column;
    }
    .card-image {
        width: 100%;
        height: 200px;
    }
}

@container card (width >= 400px) {
    .card {
        display: flex;
        flex-direction: row;
        gap: 1.5rem;
    }
    .card-image {
        width: 200px;
        flex-shrink: 0;
    }
}
```

Container query units: `cqw` (container query width), `cqh`, `cqi` (inline), `cqb` (block). Use them inside `@container` blocks for sizing relative to the container.

## :has() Selector

`:has()` is a relationship selector. Use it to style a parent based on its children's state.

```css
/* Form field with error */
.field:has(input:invalid:not(:focus)) {
    color: var(--color-error);
}

/* Card with an image gets different layout */
.card:has(img) {
    display: grid;
    grid-template-columns: 200px 1fr;
}

/* Navigation item that contains the active link */
.nav-item:has(a[aria-current="page"]) {
    font-weight: 700;
    border-bottom: 2px solid currentColor;
}

/* Grid that has 5 or more items changes layout */
.product-grid:has(.product-item:nth-child(5)) {
    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
}
```

Supported in all major browsers as of 2026. No polyfill needed.

## Fluid Typography and Spacing

Use `clamp()` for values that scale smoothly between a min and max based on viewport:

```css
/* clamp(min, preferred, max) */
:root {
    /* Typography scale */
    --font-size-sm:   clamp(0.8rem,  0.75rem + 0.25vw,  0.9rem);
    --font-size-base: clamp(1rem,    0.9rem  + 0.5vw,   1.125rem);
    --font-size-lg:   clamp(1.125rem, 1rem   + 0.75vw,  1.375rem);
    --font-size-xl:   clamp(1.375rem, 1.1rem + 1.5vw,   2rem);
    --font-size-2xl:  clamp(1.75rem,  1.3rem + 2.5vw,   3rem);
    --font-size-3xl:  clamp(2.25rem,  1.5rem + 4vw,     5rem);

    /* Spacing */
    --space-section:  clamp(3rem, 5vw, 6rem);
    --space-gap:      clamp(1rem, 2vw, 2rem);
}

h1 { font-size: var(--font-size-3xl); }
h2 { font-size: var(--font-size-2xl); }
```

Never use fixed `px` values for font sizes on headings. Let them breathe.

## Viewport Units

Mobile browsers introduced `dvh`, `svh`, and `lvh` to solve the dynamic viewport problem (the browser toolbar shifts visible height):

```css
/* dvh: dynamic viewport height -- adjusts as browser chrome shows/hides */
/* Use for: full-height sections where the address bar affects layout */
.hero {
    min-height: 100dvh;  /* correct on mobile */
}

/* svh: small viewport height -- accounts for maximum chrome */
/* Use for: safe minimum heights */
.modal {
    max-height: 85svh;
}

/* lvh: large viewport height -- ignores chrome */
/* Use for: decorative full-bleed backgrounds */
.bg-section {
    height: 100lvh;
}

/* Fallback for older browsers */
.hero {
    min-height: 100vh;    /* fallback */
    min-height: 100dvh;   /* overrides where supported */
}
```

## Subgrid

Subgrid lets nested elements align to the parent grid's tracks:

```css
.grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 1.5rem;
}

/* Card participates in parent grid tracks */
.card {
    display: grid;
    grid-row: span 3;
    grid-template-rows: subgrid;   /* aligns content to parent rows */
}

.card-header { grid-row: 1; }
.card-body   { grid-row: 2; }
.card-footer { grid-row: 3; }
```

All cards in a row now align their headers, bodies, and footers to the same baseline regardless of content length. No JavaScript needed.

## @property (Typed Custom Properties)

Declare typed custom properties to enable animations of CSS variables:

```css
@property --gradient-angle {
    syntax: '<angle>';
    inherits: false;
    initial-value: 0deg;
}

@property --progress {
    syntax: '<number>';
    inherits: false;
    initial-value: 0;
}

/* Now you can transition custom properties */
.animated-gradient {
    background: conic-gradient(from var(--gradient-angle), blue, purple, blue);
    transition: --gradient-angle 1s;
}
.animated-gradient:hover {
    --gradient-angle: 360deg;
}
```

## @starting-style

Animate elements from their initial state on insertion into the DOM:

```css
dialog {
    opacity: 1;
    transform: translateY(0);
    transition: opacity 0.3s, transform 0.3s, display 0.3s allow-discrete;

    @starting-style {
        opacity: 0;
        transform: translateY(12px);
    }
}

dialog[open] {
    display: block;
}
```

Works with `display` property transitions via `allow-discrete`. Enables enter animations without JavaScript.

## Performance in CSS

Only animate `transform` and `opacity` -- they run on the compositor thread. Animating `width`, `height`, `top`, `left`, `margin`, `padding` triggers layout on every frame.

```css
/* Correct: compositor-accelerated */
.card:hover {
    transform: translateY(-4px);
    opacity: 0.95;
    transition: transform 0.2s, opacity 0.2s;
}

/* Wrong: triggers layout */
.card:hover {
    margin-top: -4px;     /* triggers layout */
    height: 104%;         /* triggers layout */
}

/* Use will-change sparingly for elements that animate frequently */
.persistent-animation {
    will-change: transform;   /* promotes to compositor layer */
}
/* Remove it if the element isn't currently animating */
```

---

# JavaScript / TypeScript

## ES2025 / ES2026 Features

ES2026 finalizes mid-year. Already stable in modern browsers and Node:

```javascript
// Temporal API -- replaces Date entirely
import { Temporal } from 'temporal-polyfill'; // use polyfill until fully shipped

const now = Temporal.Now.zonedDateTimeISO('America/New_York');
const meeting = Temporal.PlainDateTime.from({ year: 2026, month: 6, day: 1, hour: 14 });
const diff = meeting.since(Temporal.Now.plainDateTimeISO());
// No timezone string parsing hell. Immutable. Composable.

// using / await using -- explicit resource disposal
class DBConnection {
    [Symbol.dispose]() { this.close(); }
}
function query() {
    using conn = new DBConnection();
    return conn.execute('SELECT ...');
    // conn.close() called automatically when scope exits
}

// Array.fromAsync
const results = await Array.fromAsync(asyncIterable);

// Iterator helpers
const doubled = [1, 2, 3].values()
    .map(x => x * 2)
    .filter(x => x > 2)
    .toArray();

// Error.isError() -- reliable check
if (Error.isError(value)) { ... }

// Import attributes (ES2025, stable)
import config from './config.json' with { type: 'json' };
```

## TypeScript

TypeScript is the default in 2026 for all non-trivial projects. TypeScript is now the #1 language on GitHub.

```typescript
// tsconfig.json -- strict baseline
{
    "compilerOptions": {
        "strict": true,
        "noUncheckedIndexedAccess": true,
        "exactOptionalPropertyTypes": true,
        "target": "ES2025",
        "module": "ESNext",
        "moduleResolution": "bundler",
        "lib": ["ES2025", "DOM", "DOM.Iterable"],
        "jsx": "react-jsx",        // or "preserve" for Next.js
        "paths": { "@/*": ["./src/*"] }
    }
}
```

```typescript
// Pattern: discriminated unions instead of any
type Result<T> =
    | { ok: true; data: T }
    | { ok: false; error: Error };

async function fetchUser(id: string): Promise<Result<User>> {
    try {
        const user = await db.users.findById(id);
        return { ok: true, data: user };
    } catch (error) {
        return { ok: false, error: error instanceof Error ? error : new Error(String(error)) };
    }
}

// Pattern: satisfies operator for type-checked literals
const config = {
    api: 'https://api.example.com',
    timeout: 5000,
} satisfies Partial<AppConfig>;

// Pattern: const type parameters
function identity<const T>(value: T): T {
    return value;
}
const result = identity(['a', 'b', 'c']); // type: readonly ["a", "b", "c"]
```

## Modern Async Patterns

```javascript
// Promise.withResolvers (ES2025)
const { promise, resolve, reject } = Promise.withResolvers();
// Pass resolve/reject outside the executor
eventEmitter.once('done', resolve);
return promise;

// structuredClone for deep copies
const copy = structuredClone(complexObject);

// Crypto API (no library needed)
const id = crypto.randomUUID();
const bytes = crypto.getRandomValues(new Uint8Array(32));

// AbortController for cancellable fetch
const controller = new AbortController();
setTimeout(() => controller.abort(), 5000);
const data = await fetch('/api/data', { signal: controller.signal });
```

## Module Patterns

```javascript
// Named exports preferred over default exports (better refactoring, tooling)
export function formatDate(date: Date): string { ... }
export function parseDate(str: string): Date { ... }

// Dynamic imports for code splitting
const Chart = await import('./Chart.js');

// Import maps for dependency management (native browser support)
// In HTML:
// <script type="importmap">
// { "imports": { "lodash": "/node_modules/lodash-es/lodash.js" } }
// </script>
```

---

# Next.js (App Router)

Current stable: Next.js 15.x with React 19. Next.js 16 is in preview with Partial Prerendering (PPR) stable.

## File System and Routing

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
└── api/
    └── route.ts        ← route handler (GET, POST, etc.)
```

## Server vs Client Components

The default is Server Components. They render on the server, produce HTML, ship zero JavaScript. Use them for everything that doesn't need interactivity.

```tsx
// Server Component (default) -- no "use client" needed
// Can: fetch data, access server resources, import server-only packages
// Cannot: use useState, useEffect, browser APIs, event handlers

export default async function ProductList() {
    const products = await db.products.findMany(); // direct DB access
    return (
        <ul>
            {products.map(p => (
                <li key={p.id}>{p.name}</li>
            ))}
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

Pattern: keep Client Components at the leaves. Compose Server Components that import Client Components, not the other way around.

```tsx
// Correct: Server Component wraps Client Component
export default async function Page() {
    const data = await fetchData(); // runs on server
    return (
        <ServerRenderedContent data={data}>
            <InteractiveWidget />  {/* Client Component island */}
        </ServerRenderedContent>
    );
}
```

## Data Fetching and Caching

```tsx
// fetch() in Server Components has built-in caching
// Cache: static (default), with revalidation, or no-store

// Static: cached indefinitely, revalidated on deploy
const data = await fetch('https://api.example.com/posts');

// ISR: revalidate every 60 seconds
const data = await fetch('https://api.example.com/posts', {
    next: { revalidate: 60 }
});

// Dynamic: not cached, runs on every request
const data = await fetch('https://api.example.com/user', {
    cache: 'no-store'
});

// Route segment config
export const dynamic = 'force-dynamic';  // SSR
export const revalidate = 3600;          // ISR, 1 hour
```

## Server Actions

Server Actions replace API routes for mutations. Mark functions with `'use server'`:

```tsx
// Server Action in a separate file
"use server";

import { db } from "@/lib/db";
import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";

export async function createPost(formData: FormData) {
    const title = formData.get("title") as string;
    const body = formData.get("body") as string;

    if (!title || !body) {
        return { error: "Title and body required" };
    }

    await db.posts.create({ data: { title, body } });
    revalidatePath("/posts");
    redirect("/posts");
}
```

```tsx
// Client Component uses Server Action
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

## Image Optimization

```tsx
import Image from "next/image";

// Always use next/image
// Automatic: WebP/AVIF conversion, responsive sizes, lazy loading, CLS prevention

<Image
    src="/hero.jpg"
    alt="Hero description"
    width={1200}
    height={600}
    priority           // for LCP images above the fold
    sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
/>

// Remote images need domain config in next.config.ts
// images.remotePatterns: [{ hostname: 'cdn.example.com' }]
```

## Fonts

```tsx
// next/font eliminates FOUT, layout shift, and external network requests
import { Inter, Roboto_Mono } from "next/font/google";

const inter = Inter({
    subsets: ["latin"],
    variable: "--font-inter",
    display: "swap",
});

const mono = Roboto_Mono({
    subsets: ["latin"],
    variable: "--font-mono",
});

// In root layout
export default function RootLayout({ children }) {
    return (
        <html lang="en" className={`${inter.variable} ${mono.variable}`}>
            <body>{children}</body>
        </html>
    );
}
```

---

# Supabase Integration (Stack Context)

The web stack is Vercel (frontend) + Railway (backend) + Supabase (auth, database, storage). These lanes don't blur. The rules below enforce them at the implementation level.

## Client Setup (Vercel / Next.js)

Use `@supabase/ssr` for cookie-based sessions in Next.js. Never use the plain `@supabase/supabase-js` client directly in server components or middleware -- it doesn't handle cookies correctly.

```typescript
// lib/supabase/client.ts -- browser client (Client Components)
import { createBrowserClient } from "@supabase/ssr";

export function createClient() {
    return createBrowserClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
    );
}

// lib/supabase/server.ts -- server client (Server Components, Server Actions, Route Handlers)
import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

export function createClient() {
    const cookieStore = cookies();
    return createServerClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
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

## Middleware (Session Refresh)

```typescript
// middleware.ts
import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

export async function middleware(request: NextRequest) {
    let response = NextResponse.next({ request });

    const supabase = createServerClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
        {
            cookies: {
                getAll() { return request.cookies.getAll(); },
                setAll(cookiesToSet) {
                    cookiesToSet.forEach(({ name, value }) =>
                        request.cookies.set(name, value)
                    );
                    response = NextResponse.next({ request });
                    cookiesToSet.forEach(({ name, value, options }) =>
                        response.cookies.set(name, value, options)
                    );
                },
            },
        }
    );

    // Refresh session -- must be called in middleware
    await supabase.auth.getUser();
    return response;
}

export const config = {
    matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
```

## Data Fetching with Auth (Server Components)

```typescript
// Server Component -- direct DB access with the user's session
import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";

export default async function ProtectedPage() {
    const supabase = createClient();

    // Always get user server-side for protected routes
    const { data: { user }, error } = await supabase.auth.getUser();
    if (error || !user) redirect("/login");

    // RLS enforces row-level access automatically via auth.uid()
    const { data: items } = await supabase
        .from("items")
        .select("*"); // only returns rows owned by auth.uid()

    return <ItemList items={items} />;
}
```

## Mutations (Server Actions)

```typescript
// actions/items.ts
"use server";

import { createClient } from "@/lib/supabase/server";
import { revalidatePath } from "next/cache";

export async function createItem(formData: FormData) {
    const supabase = createClient();

    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return { error: "Not authenticated" };

    const title = formData.get("title") as string;
    if (!title?.trim()) return { error: "Title required" };

    const { error } = await supabase
        .from("items")
        .insert({ title, user_id: user.id });

    if (error) return { error: error.message };

    revalidatePath("/items");
    return { success: true };
}
```

## Lane Rules Enforced in Code

**Never use `service_role` on Vercel.** The service_role key bypasses RLS. It lives on Railway only. On Vercel you have the anon key. If a query needs service_role, it goes through a Railway API endpoint, not a Next.js Server Action.

**Never use the plain JS client in Server Components.** It doesn't handle cookie refresh correctly. Always use `createServerClient` from `@supabase/ssr`.

**Never expose `SUPABASE_SERVICE_ROLE_KEY` to the browser.** Environment variables without `NEXT_PUBLIC_` prefix are server-only. `NEXT_PUBLIC_SUPABASE_ANON_KEY` is safe to expose. `SUPABASE_SERVICE_ROLE_KEY` must never have the `NEXT_PUBLIC_` prefix.

**RLS is the security layer.** `createClient()` on Vercel uses the anon key with the user's session cookie. Supabase enforces RLS via `auth.uid()`. The user can only read/write their own rows. This is correct. Don't try to add application-level filtering on top of RLS -- you'll end up with duplicate logic that drifts.

---

# Astro

Astro is the correct choice for content-driven sites: blogs, marketing pages, documentation, portfolios. For complex web applications with heavy interactivity, use Next.js.

Current stable: Astro 5.x with Content Layer API and Server Islands.

## Islands Architecture

Astro ships zero JavaScript by default. Interactive components are "islands" that hydrate independently:

```astro
---
// Page is static HTML by default
import ReactCounter from "@/components/Counter.jsx";
import VueWidget from "@/components/Widget.vue";
---

<html>
<body>
    <!-- Static HTML -- no JS -->
    <h1>Static Content</h1>

    <!-- Island: hydrate immediately on load -->
    <ReactCounter client:load />

    <!-- Island: hydrate when visible in viewport -->
    <VueWidget client:visible />

    <!-- Island: hydrate on first user interaction -->
    <HeavyComponent client:idle />

    <!-- Island: hydrate only on specific media query -->
    <MobileMenu client:media="(max-width: 768px)" />
</body>
</html>
```

`client:*` directives:
- `client:load` — hydrate immediately. Use for above-fold interactive elements.
- `client:idle` — hydrate when browser is idle. Use for below-fold.
- `client:visible` — hydrate when element enters viewport.
- `client:media` — hydrate when CSS media query matches.
- `client:only` — skip SSR, client-side only. Use sparingly.

## Content Collections (Astro 5)

```typescript
// src/content.config.ts
import { defineCollection, z } from "astro:content";

const blog = defineCollection({
    loader: glob({ pattern: "**/*.{md,mdx}", base: "./src/blog" }),
    schema: z.object({
        title: z.string(),
        pubDate: z.date(),
        description: z.string().max(160),
        author: z.string().default("Rob"),
        tags: z.array(z.string()).default([]),
        image: z.object({
            url: z.string(),
            alt: z.string(),
        }).optional(),
        draft: z.boolean().default(false),
    }),
});

export const collections = { blog };
```

```astro
---
// Query with type safety
import { getCollection } from "astro:content";

const posts = await getCollection("blog", ({ data }) => !data.draft);
const sortedPosts = posts.sort((a, b) =>
    b.data.pubDate.valueOf() - a.data.pubDate.valueOf()
);
---
```

## Server Islands

Combine static HTML with dynamic personalized content:

```astro
---
import UserAvatar from "@/components/UserAvatar.astro";
import CartCount from "@/components/CartCount.astro";
---

<!-- Static -- served from CDN cache, instant -->
<header>
    <nav>...</nav>

    <!-- Server Islands: dynamic, rendered per-request, isolated -->
    <UserAvatar server:defer>
        <div slot="fallback" class="avatar-skeleton" />
    </UserAvatar>

    <CartCount server:defer>
        <span slot="fallback">Cart</span>
    </CartCount>
</header>
```

Each island is a separate server request. A slow island doesn't block a fast one. Set per-island cache headers with `Astro.response.headers`.

---

# Performance

## Core Web Vitals

Three metrics. Measured at the 75th percentile of real user data.

**LCP (Largest Contentful Paint) ≤ 2.5s**
The time until the largest visible content element is rendered. Usually a hero image or large text block.

Fixes in priority order:
1. Preload the LCP image: `<link rel="preload" as="image" fetchpriority="high">`
2. Use `fetchpriority="high"` on the `<img>` element directly
3. No lazy loading on the LCP image (never set `loading="lazy"` on hero images)
4. Optimize image format (WebP/AVIF) and file size
5. Reduce TTFB: faster server, CDN, edge deployment
6. Eliminate render-blocking CSS and JS in `<head>`

**INP (Interaction to Next Paint) ≤ 200ms**
Time from user interaction (click, tap, key press) to the browser painting the next frame. Replaced FID in March 2024. Measures every interaction, not just the first.

Fixes:
1. Reduce JavaScript bundle size -- less to parse and execute
2. Code-split: load only what's needed for the current page
3. Defer non-critical third-party scripts with `defer` or `async`
4. Break long tasks into smaller chunks with `scheduler.yield()` or `setTimeout`
5. Move heavy processing to Web Workers
6. Avoid synchronous layout reads mid-animation (forced reflow)

**CLS (Cumulative Layout Shift) ≤ 0.1**
Unexpected layout shifts during page load.

Fixes:
1. Always set `width` and `height` on images and video
2. Reserve space for ads, embeds, and dynamically injected content
3. Never inject content above existing content
4. Use `font-display: swap` or `optional` for web fonts
5. Avoid CSS animations that change layout properties

## Asset Optimization

```html
<!-- Preconnect to critical third-party origins -->
<link rel="preconnect" href="https://api.example.com" />

<!-- Prefetch next page resources the user is likely to navigate to -->
<link rel="prefetch" href="/next-page.html" />

<!-- Preload critical assets that are discovered late in the render tree -->
<link rel="preload" as="font" href="/font.woff2" crossorigin />
<link rel="preload" as="image" href="/hero.webp" fetchpriority="high" />
```

```html
<!-- Scripts: async for independent, defer for execution-order-sensitive -->
<script async src="/analytics.js"></script>
<script defer src="/app.js"></script>

<!-- Never in <head> without async/defer -->
<!-- Never synchronous <script> blocks rendering -->
```

## Bundle Strategy

- Ship less JavaScript. Move logic to the server.
- Measure bundle with `next build --analyze` (Next.js) or `astro build --verbose` (Astro)
- Dynamic imports for route-level and component-level code splitting
- Tree-shake libraries: import named exports, not entire libraries
- Audit third-party scripts -- every analytics, chat, and marketing tag has a cost

---

# Accessibility (a11y)

## WCAG 2.2 Level AA

The legal standard in most jurisdictions (EAA, ADA, Section 508). Build to 2.2 AA -- it's backward compatible with 2.1 and 2.0.

The four principles (POUR): **Perceivable**, **Operable**, **Understandable**, **Robust**.

## Color and Contrast

```css
/* Minimum contrast ratios */
/* Normal text: 4.5:1 */
/* Large text (18pt+, or 14pt bold+): 3:1 */
/* UI components and graphics: 3:1 */

/* oklch makes contrast analysis predictable */
/* Lightness difference drives perceptual contrast */
:root {
    --color-text-on-dark: oklch(95% 0 0);       /* on dark backgrounds */
    --color-text-on-light: oklch(15% 0 0);      /* on light backgrounds */
    --color-focus-ring: oklch(60% 0.2 260);     /* must be 3:1 against adjacent colors */
}
```

Never use color as the only means of conveying information. An error state needs more than a red border -- it needs an icon, text, or both.

## Keyboard Navigation

Every interactive element must be reachable by Tab and operable by Enter or Space. Test your entire application with keyboard only -- no mouse.

```html
<!-- Skip links for keyboard users -->
<a href="#main-content" class="skip-link">Skip to main content</a>

<main id="main-content">...</main>
```

```css
/* Visible focus style -- never remove outline without a better replacement */
:focus-visible {
    outline: 3px solid var(--color-focus-ring);
    outline-offset: 2px;
    border-radius: 2px;
}

/* Hide the outline for mouse users, show for keyboard users */
:focus:not(:focus-visible) {
    outline: none;
}
```

## ARIA

Use native HTML first. ARIA is for cases where native semantics aren't sufficient.

```html
<!-- Never replace native elements with ARIA when the element exists -->
<!-- Bad -->
<div role="button" tabindex="0" onclick="submit()">Submit</div>

<!-- Good -->
<button type="submit">Submit</button>

<!-- ARIA is correct when building custom widgets -->
<div
    role="combobox"
    aria-expanded="false"
    aria-controls="listbox-id"
    aria-haspopup="listbox"
    aria-activedescendant=""
    tabindex="0"
>
    Select an option
</div>

<!-- Landmark roles (usually from semantic HTML, ARIA when needed) -->
<nav aria-label="Breadcrumb">
<nav aria-label="Pagination">
<nav aria-label="Main navigation">

<!-- Live regions for dynamic updates -->
<div role="status" aria-live="polite">
    <!-- Polite: waits for user to finish before announcing -->
    Form saved successfully
</div>

<div role="alert" aria-live="assertive">
    <!-- Assertive: interrupts immediately. For errors only. -->
    Session expired. Please log in again.
</div>

<!-- Icon-only buttons always need accessible names -->
<button aria-label="Close dialog">
    <svg aria-hidden="true" focusable="false">...</svg>
</button>
```

## Forms and Error Handling

```html
<form>
    <div class="field" aria-describedby="email-hint email-error">
        <label for="email">
            Email address
            <span class="required" aria-hidden="true">*</span>
        </label>

        <input
            type="email"
            id="email"
            name="email"
            autocomplete="email"
            required
            aria-required="true"
            aria-invalid="true"            <!-- set when field has error -->
            aria-describedby="email-error"
        />

        <p id="email-hint" class="hint">We'll never share your email</p>

        <p id="email-error" role="alert" class="error">
            <!-- Injected by JS. role=alert auto-announces. -->
            Please enter a valid email address
        </p>
    </div>
</form>
```

WCAG 2.2 new criteria to know:
- **2.4.11 Focus Not Obscured**: keyboard-focused elements must not be fully hidden behind sticky headers
- **2.4.12 Focus Not Obscured (Enhanced)**: no part of the focused element is hidden
- **2.5.3 Target Size (Minimum)**: 24x24px minimum for pointer targets (AA)
- **2.5.8 Target Size**: same, 24x24px with adequate spacing
- **3.2.6 Consistent Help**: if help is present, it appears consistently
- **3.3.7 Redundant Entry**: don't ask for the same information twice in a multi-step process
- **3.3.8 Accessible Authentication**: no cognitive tests (CAPTCHA without alternative) in login flows

## Screen Readers

Test with:
- VoiceOver on macOS (Cmd+F5) and iOS (triple-click side button)
- NVDA on Windows with Firefox -- the most common screen reader in field use
- TalkBack on Android

Common issues:
- Images without alt text
- Icon-only buttons without `aria-label`
- Tab focus order that doesn't match visual order
- Dynamic content that updates without `aria-live` regions
- Modals that don't trap focus and don't restore focus on close
- Tables without `<caption>` and `<th scope="...">`

## Testing Tools

Automated tools catch about 30-40% of WCAG issues:
- **axe DevTools** (browser extension) -- most actionable findings
- **Chrome Lighthouse** -- accessibility audit built in
- **WAVE** (WebAIM) -- visual overlays showing issues
- **Colour Contrast Analyser** (TPGi) -- desktop tool for checking any screen colors

Automated testing is not a substitute for manual keyboard testing and screen reader testing on critical flows.

---

# Mobile Web

## Mobile-First CSS

Write styles for the smallest screen first, then add complexity for larger screens:

```css
/* Mobile first: base styles apply to all sizes */
.container {
    padding: 1rem;
    display: flex;
    flex-direction: column;
    gap: 1rem;
}

/* Enhance for larger screens */
@media (width >= 768px) {
    .container {
        padding: 2rem;
        flex-direction: row;
    }
}

@media (width >= 1200px) {
    .container {
        max-width: 1200px;
        margin-inline: auto;
        padding: 2.5rem;
    }
}
```

Google indexes the mobile version of your site first (mobile-first indexing). Your mobile experience is your SEO experience.

## Touch Targets

Minimum 44x44px (Apple HIG) or 48x48px (Material Design). WCAG 2.2 sets 24x24px as the legal minimum but that's too small in practice. Use padding to extend the clickable area without affecting visual size:

```css
.icon-button {
    display: flex;
    align-items: center;
    justify-content: center;
    min-width: 44px;
    min-height: 44px;
    padding: 12px;   /* extends hit area */
}

/* Ensure adequate spacing between adjacent targets */
.nav-list {
    display: flex;
    gap: 4px;   /* 4px minimum between 44px targets = 48px center-to-center */
}
```

## Viewport and Zoom

```html
<!-- Correct: allows user zoom -->
<meta name="viewport" content="width=device-width, initial-scale=1.0" />

<!-- Wrong: disables zoom -- accessibility violation, WCAG 1.4.4 -->
<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no" />
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1" />
```

## Touch Interactions

```css
/* Prevent text selection on interactive elements during touch */
button, .interactive {
    -webkit-user-select: none;
    user-select: none;
}

/* Keep body text selectable */
p, h1, h2, article {
    user-select: text;
}

/* Fast tap response on iOS */
button, a {
    touch-action: manipulation;   /* eliminates 300ms delay on iOS */
}

/* Smooth scrolling in scroll containers */
.scroll-container {
    overflow-y: auto;
    overscroll-behavior: contain;   /* prevents scroll chaining */
    -webkit-overflow-scrolling: touch;
}
```

```javascript
// Pointer Events API unifies mouse, touch, and stylus
element.addEventListener("pointerdown", handleStart);
element.addEventListener("pointermove", handleMove);
element.addEventListener("pointerup", handleEnd);
element.addEventListener("pointercancel", handleCancel);
```

## Base Font Size

Never set `html { font-size: < 16px }`. 16px is the browser default. Mobile users on glasses or squinting need it. Going smaller increases cognitive load and WCAG failures. Use `rem` for everything.

```css
/* Correct */
html { font-size: 100%; }    /* 16px, respects user browser settings */
body { font-size: 1rem; }    /* inherits 16px */

/* Wrong */
html { font-size: 14px; }    /* ignores user preferences */
html { font-size: 62.5%; }   /* 1rem = 10px "hack" -- violates user preferences */
```

## Progressive Web Apps

PWA adds app-like behaviors without an app store:

```json
// manifest.webmanifest
{
    "name": "App Name",
    "short_name": "App",
    "description": "Short description",
    "start_url": "/",
    "display": "standalone",
    "background_color": "#1a1a1a",
    "theme_color": "#1a1a1a",
    "orientation": "portrait-primary",
    "icons": [
        { "src": "/icons/192.png", "sizes": "192x192", "type": "image/png" },
        { "src": "/icons/512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
    ],
    "shortcuts": [
        { "name": "New Post", "url": "/new", "icons": [{ "src": "/icons/add.png", "sizes": "96x96" }] }
    ]
}
```

```javascript
// Service Worker: cache-first for assets, network-first for API
self.addEventListener("install", (event) => {
    event.waitUntil(
        caches.open("app-v1").then(cache =>
            cache.addAll(["/", "/styles.css", "/app.js", "/offline.html"])
        )
    );
});

self.addEventListener("fetch", (event) => {
    if (event.request.mode === "navigate") {
        event.respondWith(
            fetch(event.request).catch(() => caches.match("/offline.html"))
        );
        return;
    }
    event.respondWith(
        caches.match(event.request).then(cached =>
            cached ?? fetch(event.request)
        )
    );
});
```

---

# Error Handling

## Next.js Error Boundaries

Every route segment needs an `error.tsx`. Without it, an unhandled error kills the entire page tree.

```tsx
// app/error.tsx (or any segment's error.tsx)
"use client";

import { useEffect } from "react";

export default function Error({
    error,
    reset,
}: {
    error: Error & { digest?: string };
    reset: () => void;
}) {
    useEffect(() => {
        // Log to your error tracking service here
        console.error(error);
    }, [error]);

    return (
        <div>
            <h2>Something went wrong</h2>
            <button onClick={() => reset()}>Try again</button>
        </div>
    );
}
```

`not-found.tsx` handles 404s specifically:

```tsx
// app/not-found.tsx
export default function NotFound() {
    return (
        <div>
            <h2>Page not found</h2>
        </div>
    );
}
```

## Server Action Error Handling

Server Actions should return typed results, not throw. Throwing breaks the error boundary contract and loses the action's return context.

```typescript
// Return a discriminated union, not throw
type ActionResult<T> =
    | { success: true; data: T }
    | { success: false; error: string };

export async function createItem(formData: FormData): Promise<ActionResult<Item>> {
    const supabase = createClient();

    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return { success: false, error: "Not authenticated" };

    const { data, error } = await supabase
        .from("items")
        .insert({ title: formData.get("title") as string })
        .select()
        .single();

    if (error) return { success: false, error: error.message };

    revalidatePath("/items");
    return { success: true, data };
}
```

```tsx
// Client Component consuming the action
"use client";
import { useActionState } from "react";
import { createItem } from "@/actions/items";

export function CreateItemForm() {
    const [state, formAction, isPending] = useActionState(
        async (prev: unknown, formData: FormData) => {
            return createItem(formData);
        },
        null
    );

    return (
        <form action={formAction}>
            {state && !state.success && (
                <p role="alert">{state.error}</p>
            )}
            <input name="title" required />
            <button disabled={isPending}>
                {isPending ? "Creating..." : "Create"}
            </button>
        </form>
    );
}
```

## Loading States

Every async route segment gets a `loading.tsx`. It wraps the segment in a Suspense boundary automatically.

```tsx
// app/products/loading.tsx
export default function Loading() {
    return <ProductListSkeleton />;
}
```

For granular loading states within a page, use Suspense explicitly:

```tsx
export default async function Page() {
    return (
        <div>
            <h1>Products</h1>
            <Suspense fallback={<SkeletonList />}>
                <ProductList />  {/* async Server Component */}
            </Suspense>
        </div>
    );
}
```

## Client-Side Error Boundaries

For Client Component trees that need error isolation:

```tsx
"use client";

import { Component, type ReactNode } from "react";

interface Props {
    children: ReactNode;
    fallback: ReactNode;
}

interface State {
    hasError: boolean;
}

export class ErrorBoundary extends Component<Props, State> {
    state = { hasError: false };

    static getDerivedStateFromError() {
        return { hasError: true };
    }

    componentDidCatch(error: Error) {
        console.error("Error boundary caught:", error);
    }

    render() {
        return this.state.hasError ? this.props.fallback : this.props.children;
    }
}
```

---

# Security

## Required HTTP Headers

Deploy all of these. They block entire classes of attacks with no application code:

```nginx
# Nginx example
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "DENY" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "camera=(), microphone=(), geolocation=(self)" always;
add_header Cross-Origin-Opener-Policy "same-origin" always;
```

**HSTS**: Forces HTTPS for the specified duration. Include `preload` and submit to the HSTS preload list. Don't set before HTTPS is fully working.

**X-Content-Type-Options: nosniff**: Prevents MIME-type sniffing attacks. Set it on every response.

**X-Frame-Options: DENY**: Blocks your pages from being embedded in iframes on other sites. Prevents clickjacking. The modern equivalent is CSP `frame-ancestors 'none'` -- set both.

**Referrer-Policy**: Controls how much referrer information is sent. `strict-origin-when-cross-origin` sends origin only to different origins, full URL to same origin.

**Permissions-Policy**: Restricts which browser APIs the page can use and which can be delegated to iframes.

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
<script nonce="r4nd0mN0nc3Per Request">
    // This inline script is allowed
</script>
```

## Input Validation

Validate all input server-side. Client-side validation is UX, not security.

```typescript
// Use Zod for schema validation
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
    // result.data is now typed and validated
    await db.users.create({ data: result.data });
}
```

---

# Browser Compatibility

## Baseline 2026 Targets

Target the "Baseline 2026" feature set: features available across all major browsers for at least 12 months. This covers Chrome, Firefox, Safari, and Edge.

Production-safe as of 2026:
- CSS: container queries, cascade layers, native nesting, `:has()`, `oklch()`, `color-mix()`, subgrid, `@starting-style`, `@property`, `dvh/svh/lvh`, `clamp()`, CSS scroll-driven animations
- HTML: `<dialog>`, `popover` attribute, `inert` attribute, `fetchpriority`
- JS: ES2025 (import attributes, Promise.withResolvers, Set methods), `structuredClone`, `crypto.randomUUID`, Temporal (with polyfill)
- APIs: Web Animations API, Intersection Observer v2, ResizeObserver, MutationObserver, View Transitions

Progressive enhancement: build the core experience without features that aren't universally supported, then enhance with `@supports`:

```css
/* Base: works everywhere */
.element {
    position: relative;
}

/* Enhanced: only where anchor positioning is supported */
@supports (anchor-name: --foo) {
    .tooltip {
        position: absolute;
        anchor-name: --trigger;
    }
}
```

## Cross-Browser Testing Checklist

- Chrome (latest, latest-1)
- Firefox (latest, latest-1)
- Safari (latest on macOS, iOS Safari latest)
- Edge (latest)
- Samsung Internet (significant Android share globally)
- At least one mid-range Android device on a real device or BrowserStack

Safari has historically lagged on certain features and has its own WebKit quirks. Always test on real iOS Safari -- the DevTools emulator misses rendering differences and touch behavior issues.

---

# Advanced Visual Techniques

The techniques in this section are what separate hand-crafted visual experiences from generic component-library output. Use them deliberately -- each one has a specific use case and a wrong application.

## CSS Blend Modes and Compositing

Blend modes run on the compositor thread. Zero JavaScript.

```css
/* mix-blend-mode: how an element blends with what's behind it */
.text-overlay {
  mix-blend-mode: overlay;       /* contrast boost, good on images */
  mix-blend-mode: multiply;      /* darken, like printing ink */
  mix-blend-mode: screen;        /* lighten, good for glow/light leaks */
  mix-blend-mode: difference;    /* inversion, Y2K / glitch aesthetic */
  mix-blend-mode: hard-light;    /* strong contrast, Neo-Brutalism */
  mix-blend-mode: soft-light;    /* subtle contrast, Neo-Minimalism */
  mix-blend-mode: color-dodge;   /* blown-out highlights, Futuristic */
  mix-blend-mode: luminosity;    /* preserve luminance, discard color */
}

/* isolation: prevent blending from propagating outside a group */
.blend-group {
  isolation: isolate; /* children blend within this context only */
}

/* background-blend-mode: blend an element's own background layers */
.texture-overlay {
  background-image: url('noise.svg'), linear-gradient(135deg, #667eea, #764ba2);
  background-blend-mode: overlay;  /* blends the two backgrounds together */
}
```

Practical patterns:

```css
/* Glow text effect without box-shadow (Futuristic) */
.glow-text {
  color: #00f5d4;
  mix-blend-mode: screen;
  text-shadow: 0 0 20px currentColor;
}

/* Color-matched grain over gradients (Neo-Minimalism, Texture) */
.grainy-surface {
  background: linear-gradient(135deg, #faf9f7, #f0ede8);
  position: relative;
}
.grainy-surface::after {
  content: '';
  position: absolute;
  inset: 0;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.65' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)'/%3E%3C/svg%3E");
  opacity: 0.04;
  mix-blend-mode: multiply;
  pointer-events: none;
}
```

## clip-path

Clips elements to arbitrary shapes. Animatable via CSS or GSAP.

```css
/* Polygon shapes */
.diagonal-cut    { clip-path: polygon(0 0, 100% 0, 100% 85%, 0 100%); }
.v-notch         { clip-path: polygon(0 0, 100% 0, 100% 100%, 50% 85%, 0 100%); }
.chevron         { clip-path: polygon(10% 0%, 90% 0%, 100% 50%, 90% 100%, 10% 100%, 0% 50%); }
.angled-card     { clip-path: polygon(0 0, 100% 0, 100% 90%, 95% 100%, 0 100%); }

/* Circle and ellipse */
.circle-reveal   { clip-path: circle(0% at 50% 50%); }  /* start hidden */
.circle-revealed { clip-path: circle(100% at 50% 50%); } /* animate to this */

/* inset for rounded clips */
.inset-clip { clip-path: inset(10px 20px 30px 40px round 16px); }
```

Animated reveal with GSAP:

```javascript
// Wipe-in from left (for image reveals, content entrances)
gsap.fromTo(element,
  { clipPath: 'polygon(0 0, 0 0, 0 100%, 0 100%)' },
  { clipPath: 'polygon(0 0, 100% 0, 100% 100%, 0 100%)',
    duration: 0.8, ease: 'power3.inOut' }
);

// Diagonal wipe
gsap.fromTo(element,
  { clipPath: 'polygon(0 0, 0 0, 0 100%, 0 100%)' },
  { clipPath: 'polygon(0 0, 110% 0, 100% 100%, 0 100%)',
    duration: 0.9, ease: 'expo.inOut' }
);
```

## CSS Filters

Hardware-accelerated visual effects. Compositing layer per filtered element.

```css
/* Individual filters */
.frosted    { backdrop-filter: blur(16px) saturate(1.5); }
.desaturate { filter: grayscale(1); }
.warm       { filter: sepia(0.2) saturate(1.1); }
.glow       { filter: drop-shadow(0 0 12px rgba(0, 245, 212, 0.8)); }
.glitch     { filter: hue-rotate(180deg) saturate(3); }

/* Duotone effect (two-color image treatment) */
.duotone {
  filter: grayscale(1) contrast(1.2);
}
.duotone-container {
  background: linear-gradient(to bottom, #ff6b35, #1a1a2e);
  mix-blend-mode: multiply; /* or screen for inverted duotone */
}

/* CRT phosphor glow (Y2K) */
.crt-screen {
  filter:
    contrast(1.1)
    brightness(0.95)
    blur(0.3px);  /* softens pixel edges */
}
```

## Custom Cursor

Signature touch for premium products. Especially effective in Futuristic, Neo-Brutalism, and Kinetic Typography styles.

```javascript
// Magnetic cursor with GSAP
const cursor = document.querySelector('.cursor');
const follower = document.querySelector('.cursor-follower');

// Cursor follows mouse exactly
document.addEventListener('mousemove', (e) => {
  gsap.set(cursor, { x: e.clientX, y: e.clientY });
  // Follower lags behind for the "trailing" effect
  gsap.to(follower, {
    x: e.clientX,
    y: e.clientY,
    duration: 0.15,
    ease: 'power2.out'
  });
});

// Expand on hoverable elements
document.querySelectorAll('a, button, [data-cursor-expand]').forEach(el => {
  el.addEventListener('mouseenter', () => {
    gsap.to(follower, { scale: 3, duration: 0.3, ease: 'power2.out' });
  });
  el.addEventListener('mouseleave', () => {
    gsap.to(follower, { scale: 1, duration: 0.3, ease: 'power2.out' });
  });
});
```

```css
/* Hide the system cursor on interactive elements */
body { cursor: none; }

.cursor {
  position: fixed;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--accent);
  pointer-events: none;
  transform: translate(-50%, -50%);
  z-index: 9999;
  mix-blend-mode: difference; /* inverts against background -- signature look */
}

.cursor-follower {
  position: fixed;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  border: 1px solid var(--accent);
  pointer-events: none;
  transform: translate(-50%, -50%);
  z-index: 9998;
}
```

Always provide a fallback: `@media (pointer: coarse) { body { cursor: auto; } }` on touch devices.

## SVG Animation and Manipulation

SVGs are DOM elements. They respond to CSS and JavaScript like any other element.

```css
/* Animated SVG stroke draw-on */
.path-draw {
  stroke-dasharray: 1000;
  stroke-dashoffset: 1000;
  animation: draw 2s ease forwards;
}

@keyframes draw {
  to { stroke-dashoffset: 0; }
}
```

```javascript
// Accurate stroke length for any path
const path = document.querySelector('path');
const length = path.getTotalLength();
path.style.strokeDasharray = length;
path.style.strokeDashoffset = length;

// GSAP scroll-driven stroke animation
gsap.to(path, {
  strokeDashoffset: 0,
  ease: 'none',
  scrollTrigger: {
    trigger: path,
    start: 'top 80%',
    end: 'bottom 20%',
    scrub: true
  }
});

// Morphing between two SVG paths with GSAP MorphSVG plugin
// (requires GSAP Club membership)
gsap.to('#path1', {
  morphSVG: '#path2',
  duration: 1,
  ease: 'power2.inOut'
});
```

Inline SVG filters for effects not achievable with CSS:

```html
<svg width="0" height="0" style="position:absolute">
  <defs>
    <!-- Blob / gooey merging effect -->
    <filter id="goo">
      <feGaussianBlur in="SourceGraphic" stdDeviation="10" result="blur"/>
      <feColorMatrix in="blur" mode="matrix"
        values="1 0 0 0 0  0 1 0 0 0  0 0 1 0 0  0 0 0 19 -9"
        result="goo"/>
    </filter>

    <!-- Liquid distortion -->
    <filter id="liquid">
      <feTurbulence type="turbulence" baseFrequency="0.015" numOctaves="4"
        seed="2" stitchTiles="stitch" result="turbulence"/>
      <feDisplacementMap in="SourceGraphic" in2="turbulence" scale="30"
        xChannelSelector="R" yChannelSelector="G"/>
    </filter>
  </defs>
</svg>

<style>
  /* Apply to container -- children merge like blobs */
  .blob-container { filter: url(#goo); }
  /* Apply to images for liquid distortion on hover */
  .liquid-image:hover { filter: url(#liquid); transition: filter 0.5s; }
</style>
```

## Canvas 2D

Use for procedural drawing: generative art, custom charts, pixel manipulation, particle systems that don't need WebGL.

```javascript
const canvas = document.querySelector('canvas');
const ctx = canvas.getContext('2d');

// Always set canvas size via JS, not CSS, to match device pixel ratio
function setCanvasSize() {
  const dpr = window.devicePixelRatio || 1;
  const rect = canvas.getBoundingClientRect();
  canvas.width = rect.width * dpr;
  canvas.height = rect.height * dpr;
  ctx.scale(dpr, dpr);
}

// Noise-based generative background (Organic/Biomorphic)
function drawNoisyBlob(time) {
  ctx.clearRect(0, 0, canvas.width, canvas.height);

  const cx = canvas.width / 2;
  const cy = canvas.height / 2;
  const points = 8;
  const baseRadius = 120;

  ctx.beginPath();
  for (let i = 0; i <= points; i++) {
    const angle = (i / points) * Math.PI * 2;
    const noise = Math.sin(angle * 3 + time * 0.5) * 20 +
                  Math.cos(angle * 5 + time * 0.3) * 15;
    const r = baseRadius + noise;
    const x = cx + Math.cos(angle) * r;
    const y = cy + Math.sin(angle) * r;
    i === 0 ? ctx.moveTo(x, y) : ctx.bezierCurveTo(/* ... */);
  }
  ctx.closePath();

  const grad = ctx.createRadialGradient(cx, cy, 0, cx, cy, baseRadius + 40);
  grad.addColorStop(0, 'rgba(120, 190, 150, 0.8)');
  grad.addColorStop(1, 'rgba(80, 140, 120, 0.2)');
  ctx.fillStyle = grad;
  ctx.fill();
}

let animFrame;
function animate(time) {
  drawNoisyBlob(time * 0.001);
  animFrame = requestAnimationFrame(animate);
}

// Always cancel on cleanup
return () => cancelAnimationFrame(animFrame);
```

---



**JavaScript for CSS problems.** If you're using JavaScript to detect element sizes and manually set styles, you probably need container queries. If you're using JavaScript to toggle classes based on scroll position, you probably need CSS scroll-driven animations or an Intersection Observer. CSS running on the compositor thread is faster than any JavaScript.

**`any` in TypeScript.** `any` is a type-safety hole. If you don't know the type, use `unknown` and narrow it explicitly.

**Default exports everywhere.** Named exports are safer to refactor, easier to auto-import, and more explicit. Default exports make renaming and tree-shaking harder.

**Layout-triggering animations.** Never animate `width`, `height`, `top`, `left`, `margin`, `padding`. Always animate `transform` and `opacity`.

**Removing focus outlines.** `outline: none` without a replacement focus style fails WCAG 2.4.7. Always provide a visible focus indicator.

**`user-scalable=no` in the viewport meta.** Accessibility violation. Always allow zoom.

**Setting `font-size` on `html` below 16px.** Violates user preferences. Causes WCAG 1.4.4 failures. Use `rem` and let the user's settings govern the base.

**Auto-playing media with sound.** Banned by WCAG 1.4.2 without a pause control. Also a UX failure that drives users away.

**Placeholder text as a label.** Placeholder disappears on input. Screen readers don't consistently announce it. Always use a `<label>`.

**Infinite scroll without an alternative.** Keyboard users can't navigate past it. Screen reader users get no sense of scope. Always provide pagination as an alternative.

**Loading full third-party libraries for single functions.** `import moment from 'moment'` for date formatting. `import _ from 'lodash'` for `debounce`. The Temporal API handles dates. Debounce is 5 lines. Bundle size has a real user cost.

**Missing `width` and `height` on images.** Causes CLS. Always set both.

**`fetchpriority` or `loading` on the LCP image wrong direction.** Hero images must not have `loading="lazy"`. They should have `fetchpriority="high"`.

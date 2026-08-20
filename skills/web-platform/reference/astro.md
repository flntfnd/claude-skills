Astro is the correct choice for content-driven sites: blogs, marketing pages, documentation, portfolios. For complex web applications with heavy interactivity, use Next.js.

Current stable is Astro 7.x (7.0 shipped June 2026). It's a speed release: the `.astro` compiler was rewritten in Rust, the Markdown/MDX pipeline moved to a Rust pipeline, and the bundler switched to Vite 8 with Rolldown — builds are reported 15-61% faster on real production sites. The Islands Architecture, Content Layer API, and Server Islands patterns below are unchanged from Astro 5/6 and remain the current way to build.

The Rust-based compiler is stricter than the old one: it rejects unclosed non-void tags and no longer auto-corrects invalid nesting. Write fully-closed, well-nested `.astro` markup.

## Contents

- [Islands architecture](#islands-architecture)
- [Content collections](#content-collections)
- [Server islands](#server-islands)

## Islands architecture

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

    <!-- Island: hydrate when browser is idle -->
    <HeavyComponent client:idle />

    <!-- Island: hydrate only on specific media query -->
    <MobileMenu client:media="(max-width: 768px)" />
</body>
</html>
```

`client:*` directives:
- `client:load` — hydrate immediately. Above-fold interactive elements.
- `client:idle` — hydrate when browser is idle. Below-fold.
- `client:visible` — hydrate when element enters viewport.
- `client:media` — hydrate when CSS media query matches.
- `client:only` — skip SSR, client-side only. Use sparingly.

## Content collections

The Content Layer API (config file `src/content.config.ts`, not the legacy `src/content/config.ts`) is the current way to define and query content. `glob()` and `file()` are the built-in loaders for local Markdown, MDX, Markdoc, JSON, YAML, and TOML — both are imported from `astro/loaders`.

```typescript
// src/content.config.ts
import { defineCollection, z } from "astro:content";
import { glob } from "astro/loaders";

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

Third-party and CMS-backed sources (Strapi, Payload, etc.) use custom loaders implementing the same Loader interface — write a loader object with a `load()` function rather than reaching for a legacy fetch-in-frontmatter pattern.

## Server islands

Combine static HTML with dynamic personalized content. Each server island is a separate, isolated per-request render — a slow island doesn't block a fast one, and the static shell still serves from CDN cache.

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

Set per-island cache headers with `Astro.response.headers`.

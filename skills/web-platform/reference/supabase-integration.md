## Contents

- [Client setup](#client-setup)
- [Proxy / middleware (session refresh)](#proxy--middleware-session-refresh)
- [Data fetching with auth](#data-fetching-with-auth)
- [getUser() vs getClaims()](#getuser-vs-getclaims)
- [Mutations (Server Actions)](#mutations-server-actions)
- [Lane rules enforced in code](#lane-rules-enforced-in-code)

Use `@supabase/ssr` for cookie-based sessions in Next.js. Never use the plain `@supabase/supabase-js` client directly in Server Components or route handlers — it doesn't handle cookies correctly.

`cookies()` is fully async in current Next.js (no sync fallback — see `nextjs.md`). Every server-side Supabase client must `await cookies()` before constructing the client.

## Client setup

```typescript
// lib/supabase/client.ts -- browser client (Client Components)
import { createBrowserClient } from "@supabase/ssr";

export function createClient() {
    return createBrowserClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
    );
}
```

```typescript
// lib/supabase/server.ts -- server client (Server Components, Server Actions, Route Handlers)
import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

export async function createClient() {
    const cookieStore = await cookies(); // async -- must await

    return createServerClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
        {
            cookies: {
                getAll() { return cookieStore.getAll(); },
                setAll(cookiesToSet) {
                    try {
                        cookiesToSet.forEach(({ name, value, options }) =>
                            cookieStore.set(name, value, options)
                        );
                    } catch {
                        // setAll called from a Server Component -- cookies can't be
                        // set there. Safe to ignore if the proxy/middleware below
                        // is refreshing the session on every request.
                    }
                },
            },
        }
    );
}
```

Because `createClient()` is now `async`, every call site needs `await createClient()`, not `createClient()`.

## Proxy / middleware (session refresh)

Next.js 16 deprecated `middleware.ts` in favor of `proxy.ts` (same logic, renamed file and function — see `nextjs.md`). Session-refresh logic is unchanged either way:

```typescript
// proxy.ts (Next.js 16+) -- or middleware.ts on Next.js 15 / if Edge runtime is required
import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

export default async function proxy(request: NextRequest) {
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

    // Refresh session -- must be called here so cookies rotate on every request
    await supabase.auth.getUser();
    return response;
}

export const config = {
    matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
```

## Data fetching with auth

```typescript
// Server Component -- direct DB access with the user's session
import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";

export default async function ProtectedPage() {
    const supabase = await createClient();

    const { data: { user }, error } = await supabase.auth.getUser();
    if (error || !user) redirect("/login");

    // RLS enforces row-level access automatically via auth.uid()
    const { data: items } = await supabase
        .from("items")
        .select("*"); // only returns rows owned by auth.uid()

    return <ItemList items={items} />;
}
```

## getUser() vs getClaims()

Supabase now issues asymmetric (RSA/ECC) JWT signing keys by default for new projects (since May 2025). This unlocked `getClaims()`, which verifies the JWT locally against the project's published JWKS instead of round-tripping to the Auth server on every call — meaningfully faster than `getUser()` at scale.

- **`getUser()`**: always calls the Auth server. Slightly slower, but reflects instant ban/delete/sign-out.
- **`getClaims()`**: verifies locally (fast, cached JWKS) when the project uses asymmetric keys; falls back to a server round-trip on projects still using a symmetric (shared-secret) key. Preferred when raw performance matters more than sub-second propagation of account-status changes.

`getUser()` remains correct and is the simpler default for typical protected-route checks. Reach for `getClaims()` on high-traffic paths (middleware/proxy running on every request, hot API routes) where the extra round-trip is measurable. Never use `getSession()` alone to gate access — it reads the (possibly stale, unverified) client-side session without validating the JWT.

```typescript
// getClaims example -- same shape of use as getUser
const { data: claims, error } = await supabase.auth.getClaims();
if (error || !claims) redirect("/login");
const userId = claims.claims.sub;
```

## Mutations (Server Actions)

```typescript
// actions/items.ts
"use server";

import { createClient } from "@/lib/supabase/server";
import { revalidatePath } from "next/cache";

export async function createItem(formData: FormData) {
    const supabase = await createClient();

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

## Lane rules enforced in code

**Never use `service_role` on Vercel.** The service_role key bypasses RLS. It lives on Railway only. On Vercel you have the anon key. If a query needs service_role, it goes through a Railway API endpoint, not a Next.js Server Action.

**Never use the plain JS client in Server Components.** It doesn't handle cookie refresh correctly. Always use `createServerClient` from `@supabase/ssr`, awaited, per request.

**Never expose `SUPABASE_SERVICE_ROLE_KEY` to the browser.** Environment variables without the `NEXT_PUBLIC_` prefix are server-only. `NEXT_PUBLIC_SUPABASE_ANON_KEY` is safe to expose. `SUPABASE_SERVICE_ROLE_KEY` must never carry the `NEXT_PUBLIC_` prefix.

**RLS is the security layer.** `createClient()` on Vercel uses the anon key with the user's session cookie. Supabase enforces RLS via `auth.uid()`. The user can only read/write their own rows. Don't add application-level filtering on top of RLS — it produces duplicate logic that drifts from the real policy.

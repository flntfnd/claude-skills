## Contents

- [Next.js error boundaries](#nextjs-error-boundaries)
- [Server Action error handling](#server-action-error-handling)
- [Loading states](#loading-states)
- [Client-side error boundaries](#client-side-error-boundaries)

## Next.js error boundaries

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

## Server Action error handling

Server Actions should return typed results, not throw. Throwing breaks the error boundary contract and loses the action's return context.

```typescript
type ActionResult<T> =
    | { success: true; data: T }
    | { success: false; error: string };

export async function createItem(formData: FormData): Promise<ActionResult<Item>> {
    const supabase = await createClient();

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
"use client";
import { useActionState } from "react";
import { createItem } from "@/actions/items";

export function CreateItemForm() {
    const [state, formAction, isPending] = useActionState(
        async (prev: unknown, formData: FormData) => createItem(formData),
        null
    );

    return (
        <form action={formAction}>
            {state && !state.success && <p role="alert">{state.error}</p>}
            <input name="title" required />
            <button disabled={isPending}>
                {isPending ? "Creating..." : "Create"}
            </button>
        </form>
    );
}
```

## Loading states

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

## Client-side error boundaries

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

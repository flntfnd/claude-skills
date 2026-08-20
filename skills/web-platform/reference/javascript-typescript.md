## Contents

- [ES2025 / ES2026 features](#es2025--es2026-features)
- [TypeScript](#typescript)
- [Modern async patterns](#modern-async-patterns)
- [Module patterns](#module-patterns)

## ES2025 / ES2026 features

ES2026 (which includes the Temporal API) reached TC39 Stage 4 in March 2026 — it's finalized, not speculative.

```javascript
// Temporal API -- replaces Date entirely
// Ships natively in Chrome 144+ and Firefox 139+ (both landed early-to-mid 2026).
// [Unverified] Safari support: was still behind a flag in Safari Technology Preview
// as of mid-2026, not yet in stable Safari -- verify current Safari status before
// dropping the polyfill. Use temporal-polyfill for any project with real Safari traffic.
import { Temporal } from 'temporal-polyfill';

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

// Error.isError() -- reliable check, works across realms unlike instanceof
if (Error.isError(value)) { /* ... */ }

// Import attributes (stable)
import config from './config.json' with { type: 'json' };
```

## TypeScript

TypeScript is the default for any non-trivial project.

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

`any` is a type-safety hole. If the type is genuinely unknown, use `unknown` and narrow it explicitly — never reach for `any` as an escape hatch.

## Modern async patterns

```javascript
// Promise.withResolvers
const { promise, resolve, reject } = Promise.withResolvers();
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

## Module patterns

```javascript
// Named exports preferred over default exports -- safer to refactor,
// easier to auto-import, more explicit, better tree-shaking.
export function formatDate(date: Date): string { /* ... */ }
export function parseDate(str: string): Date { /* ... */ }

// Dynamic imports for code splitting
const Chart = await import('./Chart.js');

// Import maps for dependency management (native browser support)
// <script type="importmap">
// { "imports": { "lodash-es": "/node_modules/lodash-es/lodash.js" } }
// </script>
```

Don't load a full third-party library for one function: `import moment from 'moment'` for date formatting, or `import _ from 'lodash'` just for `debounce`. Temporal (with polyfill) handles dates; debounce is five lines. Bundle size has a real user cost.

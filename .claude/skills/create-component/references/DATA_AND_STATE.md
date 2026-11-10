# Data, forms and state

## Data fetching (always through the generated client)
| Framework | Preferred pattern |
|---|---|
| React (SPA) | A server-state library (e.g. TanStack Query / SWR) wrapping the generated client: one hook per operation (`useItems`, `useCreateItem`) |
| Next.js App Router | Fetch in Server Components or route handlers. Client components use the query hook for interactive or refreshing data. Mutations go through server actions or the client mutation hook |
| Vue / Nuxt | `useFetch`/`useAsyncData` (Nuxt) or a vue-query composable over the client |
| Angular | A service over the generated client + a signal store (or the query adapter); `HttpClient` interceptors for auth and errors |
| SvelteKit | `load` in `+page(.server).ts`, plus form actions for mutations |
| Solid | `createResource`, or solid-query |

**Rules:** one cache key per operation + params; invalidate after mutations; no fetch inside render loops; cancel or ignore stale requests; never call the API with hand-written URLs when a generated client exists.

## Error mapping (from the contract's error model)
```ts
export function messageFor(err: ApiError): string {
  switch (err.code) {
    case 'unauthenticated':   return 'Your session has expired. Please sign in again.';
    case 'forbidden':         return "You don't have access to this.";
    case 'not_found':         return "We couldn't find that.";
    case 'validation_failed': return 'Please check the highlighted fields.';
    case 'conflict':
    case 'version_mismatch':  return 'This was changed by someone else. Refresh to see the latest version.';
    case 'rate_limited':      return 'Too many attempts. Please wait a moment and try again.';
    default:                  return 'Something went wrong. Please try again.';
  }
}
```
Map `validation_failed.details[]` to field errors. On `unauthenticated`, redirect to sign-in and keep the return URL.

## Forms
- Use the project's form library and schema library (PROJECT.md → Coding guides: React Hook Form or Formik with zod or yup, VeeValidate, Angular Reactive Forms, Superforms…) and the shared or contract-generated schema. Full rules: `coding-foundations` → FORMS_AND_VALIDATION.md.
- Validate on blur, then on change; on submit, focus the first invalid field.
- Disable submit only while submitting; keep the input on error; prevent double submission; send an `Idempotency-Key` on create operations that the contract marks idempotent.
- Optimistic updates only when the operation is reversible and its failure is rare. Roll back and show an error on failure.

## State placement
| State | Where |
|---|---|
| Server data | The server-state cache (the query library / the framework's loaders) |
| URL-shareable (filters, sort, page, selected tab) | The URL query string |
| Form drafts | The form library state (persist to storage only if the PRD asks) |
| Cross-page UI state (theme, sidebar) | A small global store / context |
| Component-local UI | Local state |
Never duplicate server data in a global store.

## Realtime (only when ARCHITECTURE says so)
Wrap the socket or SSE stream in one hook, composable or store per channel; reconnect with backoff; merge events into the server-state cache (don't keep a parallel copy); show a connection-status indicator when the data could be stale. Full rules: coding-foundations → REALTIME.md §4.

## Large data
Server-side pagination or cursors per the contract; virtualize long lists; debounce search inputs (250–300 ms); avoid re-rendering whole tables on single-row updates. Budgets and the checklist: coding-foundations → PERFORMANCE.md; work over ~50 ms goes to a web worker (WORKERS.md).

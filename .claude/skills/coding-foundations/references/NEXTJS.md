# Next.js guide (App Router)

With: REACT.md (components, state, hooks), TYPESCRIPT.md, FORMS_AND_VALIDATION.md, PERFORMANCE.md, and the folder tree in design-architecture → FOLDER_STRUCTURES.md §A1. Versions are pinned in `PROJECT.md`; where a default differs between versions (caching, async request APIs), follow the pinned version's documentation.

## Routing: route groups (must)
Every route lives in a **route group**, chosen by its layout and its access level. A group is a folder in parentheses; it organizes files and does not appear in the URL.

| Group | Holds | Layout | Access |
|---|---|---|---|
| `(auth)` | Sign in, sign up, password recovery, verification | Centered, no app navigation | Public; signed-in users are redirected away |
| `(app)` (or one group per shell, e.g. `(dashboard)`, `(admin)`) | The product's signed-in screens | App shell: navigation, sidebar, user menu | Authenticated; role checks per segment |
| `(marketing)` | The landing page (`F-LANDING`), pricing, about, legal pages | Public header and footer | Public, indexable |
| `api/` | Route handlers (webhooks, health, BFF endpoints) | — | Each handler authenticates and authorizes |

- Each group has its own `layout.tsx`, `error.tsx`, `loading.tsx` and, where useful, `not-found.tsx`. Two shells never share one layout through conditionals.
- **Access is enforced on the server:** in the group layout or a server-side guard that reads the session, plus middleware for the cheap redirect. Hiding a link is never the access control.
- Add a group when a set of screens needs a different shell or a different access rule (e.g. `(admin)`, `(onboarding)`); don't add one per feature. Features are folders inside a group.
- Dynamic segments `[id]`, parallel routes `@slot` and intercepting routes are used only where the UI-UX flows need them, and are named after the domain term.
- Route constants live in one place (`config/routes.ts`); components never build paths from string fragments.

## Server and client components (must)
- **Server Components by default.** `"use client"` goes on the smallest interactive leaf, never on a layout or page for convenience.
- Server-only code (database, secrets, private SDKs) is never imported into a client component; mark such modules with the `server-only` package.
- Pass serializable props from server to client. Fetch on the server and hand the result down, or hydrate the query cache with it; don't fetch the same data twice.
- Client-only widgets that can't render on the server (editors, charts using browser APIs) are loaded with a dynamic import and a sized fallback.

## Data and mutations
- Reads: in Server Components through the contract-generated client; in client components through the project's query library (REACT.md "State").
- Fetch independent data in parallel; fetch in sequence only when one call needs the other's result.
- **Server Actions and Route Handlers are public endpoints (must):** validate input with the same schema the form uses (`safeParse`), authenticate and authorize every call, return field errors to the form and contract-shaped errors to API callers. Never trust a hidden field or a client-computed value.
- **Be explicit about caching and revalidation** on every fetch and route (`cache` / `revalidate` options, `revalidatePath` / `revalidateTag` after a mutation). Per-user data is never cached in a shared cache.
- Secrets stay in server environment variables. Only values safe for the browser use the public prefix.

## Errors and loading (must)
Four layers, so one failure never blanks the whole app:
1. `global-error.tsx`: the root layout crashed. Self-contained (no providers, no shared components).
2. `error.tsx` per route group (and per segment where a screen is critical): message in the brand voice, "Try again" (`reset()`), a way out, and a report to the error tracker.
3. A section-level error boundary around each independent widget (feed, chart, sidebar): the rest of the page keeps working.
4. `not-found.tsx` for missing resources (call `notFound()` instead of rendering an empty page).

`loading.tsx` and `<Suspense>` boundaries stream slow sections behind skeletons that match the mockup's loading state. Never show a technical message or a stack trace to the user.

## Metadata, assets, performance
- Metadata API (`metadata` / `generateMetadata`) on every public route: title, description, canonical URL, Open Graph image. `sitemap` and `robots` files for the `(marketing)` group.
- `next/image` for every image (sized, `priority` only for the LCP image); `next/font` for fonts (self-hosted, no layout shift).
- Dynamic imports for heavy client code below the fold. Budgets and measurement: PERFORMANCE.md.

## Middleware
Only cheap, stateless checks: the auth redirect, locale, security headers. No database calls and no business rules.

## Testing
Component tests per REACT.md. Server Actions and Route Handlers get tests for validation, authorization and error shape. E2E (Playwright) covers each group's guard: a signed-out user can't open `(app)`, a signed-in user is redirected from `(auth)`, a wrong role gets the no-permission state.

## Review checklist
- [ ] Every route sits in a route group with its own layout, `error.tsx` and `loading.tsx`; access is enforced server-side.
- [ ] `"use client"` only on interactive leaves; no server-only import reaches the client.
- [ ] Server Actions and Route Handlers validate with the shared schema and authorize every call.
- [ ] Caching and revalidation are explicit; no per-user data in a shared cache.
- [ ] Error layers present (global, group, section, not-found); loading states match the mockups.
- [ ] Public routes have metadata; images use `next/image`, fonts use `next/font`.
- [ ] Routes come from the route constants; folders follow FOLDER_STRUCTURES §A1.

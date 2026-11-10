# React guide

Next.js projects also read [NEXTJS.md](NEXTJS.md) (route groups, server and client components, error layers). With: TYPESCRIPT.md, OOP_AND_PATTERNS.md (components are composition, not inheritance), the design system (`build-design-system`: tokens, components) and `create-component`.

## Components
- Function components, typed props, one responsibility, small (split at about 150 lines or when it renders several concerns). Composition through `children` and slots, never inheritance.
- **Presentational vs container:** UI components take props and render; data fetching and side effects live in hooks or route-level containers.
- Use the design-system components and **semantic tokens only**; no raw colors, spacing or font sizes.
- **Component library first (must):** before writing a component, check the project's UI library (named in `PROJECT.md`; the default for React is Tailwind CSS + shadcn/ui on Radix primitives). Add it with the library's own command (e.g. `shadcn add <component>`) into `components/ui/`, then **compose** it; don't rewrite what the library provides. A custom base component is allowed only when the library has none, and it needs a spec in DESIGN-SYSTEM.md.
- **Component layers** (imports point downward only): `components/ui` (library and base components: presentation only, no business logic, no API calls) → `components/shared` (reused across features: empty state, pagination, file upload) → `components/features/<feature>` (business logic, API hooks, feature forms) → `components/layout` (navigation, shell) and `components/providers` (theme, query, auth, realtime). A feature never imports from another feature; share through `shared` or lift it.
- Library components are themed through the token variables (build-design-system → DESIGN_TOKENS.md §8), never by editing colors inside the component file.
- Stable, unique `key`s from data ids, never array indexes for dynamic lists.

## State (choose the smallest that works)
| Kind | Where |
|---|---|
| Local UI state | `useState` / `useReducer` in the component |
| Derived values | Computed during render (no state, no effect) |
| Server data | A query library (TanStack Query, SWR, RTK Query) or Server Components; never copied into global state. One hook file per resource in `hooks/api/` with a **query-key factory** (`all → lists → list(filters) → detail(id)`), explicit stale times, and mutations that invalidate the keys they change |
| URL state (filters, tabs, pagination) | The router's search params |
| Form state | **React Hook Form or Formik** (one per project) + a **zod or yup** schema shared with the server ([FORMS_AND_VALIDATION.md](FORMS_AND_VALIDATION.md)) |
| Truly global client state | Context for rarely-changing values; a small store (Zustand, Redux Toolkit) only when needed, in `stores/`, for UI state only (sidebar, modals, filters). **Never auth tokens or server data in a persisted store** |

## Hooks and effects (must)
- Follow the Rules of Hooks (lint: `react-hooks`); exhaustive dependency arrays, never silenced.
- **You probably don't need an effect:** no effects for derived state, data transforms or event handling. Effects only to sync with external systems, always with cleanup (abort fetches, unsubscribe, clear timers).
- Extract reusable logic into custom hooks (`useOrderTotals`), named `use…`, with their own tests.
- `useMemo`/`useCallback`/`memo` only when a measurement or a referential-equality need justifies them (or the React Compiler handles it).

## Data, errors, loading
- API calls through the contract-generated client; types from the contract.
- Every async view handles loading, empty, error and success (the mockup states); error boundaries per route/section; Suspense where the data layer supports it.
- Optimistic updates: cancel in-flight queries, snapshot, update, **roll back on failure** and show the error, then revalidate.
- Realtime events update the query cache ([REALTIME.md](REALTIME.md)); work over ~50 ms moves off the main thread ([WORKERS.md](WORKERS.md)).

## Accessibility and UX (must)
- Semantic HTML first (`button`, `a`, `label`, landmarks); ARIA only when no native element fits. Every input has a label; images have alt text; focus is visible and managed in dialogs; keyboard reachable; respect `prefers-reduced-motion`.

## Security
- No `dangerouslySetInnerHTML` without a vetted sanitizer; no secrets or private keys in the bundle (only public env vars with the framework's public prefix); validate redirects.

## Performance
- Code-split by route; lazy-load heavy, below-the-fold widgets; virtualize long lists; optimize images (framework image component); keep the bundle budget in the NFRs. Budgets, measurement and the full checklist: [PERFORMANCE.md](PERFORMANCE.md).

## Next.js (App Router)
See [NEXTJS.md](NEXTJS.md): route groups by layout and access, Server Components by default, Server Actions and Route Handlers as public endpoints, explicit caching, the four error layers, metadata.

## Testing
- Testing Library: query by role, label and text (what users see), not by class or test-internal structure; user-event for interactions; MSW for network. Hooks tested through components or `renderHook`. Visual states match the mockups (design QA); E2E with Playwright for journeys.

## Review checklist
- [ ] Components small, typed, composed; tokens only; stable keys.
- [ ] Library components used and composed (none rewritten); each component sits in the right layer; no feature imports another feature.
- [ ] State in the smallest right place; no server data in global stores; no derived state in effects.
- [ ] Effects have correct deps and cleanup; no silenced hook lint.
- [ ] Loading, empty, error and success states all handled.
- [ ] Forms follow FORMS_AND_VALIDATION.md: the project's form + schema library, shared schema, server errors mapped to fields, accessible errors.
- [ ] Accessible: semantic elements, labels, focus, keyboard.
- [ ] Next.js projects: the NEXTJS.md checklist.

# React and Next.js guide

With: TYPESCRIPT.md, OOP_AND_PATTERNS.md (components are composition, not inheritance), the design system (`build-design-system`: tokens, components) and `create-component`.

## Components
- Function components, typed props, one responsibility, small (split at about 150 lines or when it renders several concerns). Composition through `children` and slots, never inheritance.
- **Presentational vs container:** UI components take props and render; data fetching and side effects live in hooks or route-level containers.
- Use the design-system components and **semantic tokens only**; no raw colors, spacing or font sizes.
- Stable, unique `key`s from data ids, never array indexes for dynamic lists.

## State (choose the smallest that works)
| Kind | Where |
|---|---|
| Local UI state | `useState` / `useReducer` in the component |
| Derived values | Computed during render (no state, no effect) |
| Server data | A query library (TanStack Query, SWR, RTK Query) or Server Components; never copied into global state |
| URL state (filters, tabs, pagination) | The router's search params |
| Form state | A form library (React Hook Form) + the boundary schema |
| Truly global client state | Context for rarely-changing values; a small store (Zustand, Redux Toolkit) only when needed |

## Hooks and effects (must)
- Follow the Rules of Hooks (lint: `react-hooks`); exhaustive dependency arrays, never silenced.
- **You probably don't need an effect:** no effects for derived state, data transforms or event handling. Effects only to sync with external systems, always with cleanup (abort fetches, unsubscribe, clear timers).
- Extract reusable logic into custom hooks (`useOrderTotals`), named `use…`, with their own tests.
- `useMemo`/`useCallback`/`memo` only when a measurement or a referential-equality need justifies them (or the React Compiler handles it).

## Data, errors, loading
- API calls through the contract-generated client; types from the contract.
- Every async view handles loading, empty, error and success (the mockup states); error boundaries per route/section; Suspense where the data layer supports it.
- Optimistic updates roll back on failure and show the error.

## Accessibility and UX (must)
- Semantic HTML first (`button`, `a`, `label`, landmarks); ARIA only when no native element fits. Every input has a label; images have alt text; focus is visible and managed in dialogs; keyboard reachable; respect `prefers-reduced-motion`.

## Security
- No `dangerouslySetInnerHTML` without a vetted sanitizer; no secrets or private keys in the bundle (only public env vars with the framework's public prefix); validate redirects.

## Performance
- Code-split by route; lazy-load heavy, below-the-fold widgets; virtualize long lists; optimize images (framework image component); keep the bundle budget in the NFRs.

## Next.js (App Router)
- **Server Components by default;** `"use client"` only at the smallest interactive leaf. Never import server-only code (DB, secrets) into client components (`server-only` package).
- **Server Actions and Route Handlers are public endpoints:** validate input with the schema, authenticate and authorize every call, and return contract-shaped errors.
- Be explicit about caching and revalidation (`fetch` cache options, `revalidate`, `revalidatePath/Tag`); defaults differ between versions, so follow the pinned version's docs.
- `loading.tsx`, `error.tsx` and `not-found.tsx` per route segment; metadata API for SEO; middleware only for cheap checks (auth redirect, locale), not business logic.

## Testing
- Testing Library: query by role, label and text (what users see), not by class or test-internal structure; user-event for interactions; MSW for network. Hooks tested through components or `renderHook`. Visual states match the mockups (design QA); E2E with Playwright for journeys.

## Review checklist
- [ ] Components small, typed, composed; tokens only; stable keys.
- [ ] State in the smallest right place; no server data in global stores; no derived state in effects.
- [ ] Effects have correct deps and cleanup; no silenced hook lint.
- [ ] Loading, empty, error and success states all handled.
- [ ] Accessible: semantic elements, labels, focus, keyboard.
- [ ] Next.js: client boundary minimal; server actions/route handlers validate and authorize; caching explicit.

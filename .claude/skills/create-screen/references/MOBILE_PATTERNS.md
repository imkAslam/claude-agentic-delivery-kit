# Mobile patterns

## Network and offline
| PRD need | Pattern |
|---|---|
| Online only | Detect offline → banner + disabled submit; queries retry when connectivity returns |
| Read offline | Persist the query cache (encrypted if it holds personal data); show "last updated <time>" |
| Write offline | An outbox queue of mutations with idempotency keys; replay in order when online; show the pending state per item; conflict → `409` → let the user resolve it |
Timeouts 10–15 s; retry idempotent GETs with exponential backoff and jitter; never auto-retry non-idempotent writes without an idempotency key.

## Lifecycle
- Refetch stale data on app foreground. Pause polling and sockets in the background.
- Save form drafts on background if losing them would hurt (as the PRD requires).
- Handle process death: restore the navigation state and drafts. Don't assume memory survives.

## Permissions (camera, location, photos, notifications)
1. Explain the benefit **before** the system prompt (a pre-permission screen).
2. Request only when the feature is used, never at launch.
3. On denial, give a graceful fallback plus a deep link to the settings.
4. Store the permission state; re-check it on foreground.

## Deep links and navigation
- Every shareable screen has a route/path. Validate params and handle unknown ids (show not-found).
- Auth-protected deep links: sign in, then continue to the original destination.
- Android back button and iOS swipe-back behave predictably. Confirm discarding unsaved changes.

## Push notifications
Register after the user opts in; send the token to the backend through the contract; tapping a notification opens the deep link; respect the quiet settings; no sensitive content in the payload.

## Forms on mobile
The correct keyboard type per field (email, number, phone); autofill/autocomplete hints; "next" moves focus; keyboard avoidance; submit stays reachable above the keyboard.

## Performance
Virtualized lists (`FlatList`/`ListView.builder`) with stable keys; memoized rows; image caching and sizing; avoid re-rendering the whole screen on small state changes; measure startup time and keep the first screen light.

## Release-sensitive code
Feature flags or remote config for risky features; the API stays backward compatible with the previous app version (users update late); never hardcode environment URLs, use the build-profile config from the `ship → mobile-eas` target.

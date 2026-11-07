# React Native and Expo guide

With: REACT.md (components, state, hooks), TYPESCRIPT.md. Templates: `create-screen`.

## Structure and navigation
- Expo (managed or prebuild) unless the architecture says otherwise; feature folders; screens are thin containers over presentational components.
- One navigation library (Expo Router or React Navigation) with typed routes and params; deep links and universal links configured and tested.

## Rendering and performance (must)
- Lists with `FlatList`/`SectionList` (or FlashList): stable `keyExtractor`, memoized row components, `getItemLayout` for fixed rows; never `map` a long list inside a `ScrollView`.
- No heavy work on the JS thread during gestures or animations; use the native-driven animation library (Reanimated) for animations.
- Images sized and cached; avoid re-renders from inline objects/functions in hot list rows.

## Forms
Same libraries and shared schemas as the web app (FORMS_AND_VALIDATION.md); next-field focus with `returnKeyType`, keyboard avoidance, `textContentType`/`autoComplete` for autofill, errors announced to screen readers.

## Offline, network and lifecycle
- Assume poor networks: request timeouts, retries for idempotent calls, cached server state that persists across launches, optimistic updates with rollback, and a visible offline state.
- Handle app state changes (background/foreground): pause timers and subscriptions, refresh stale data on resume.

## Security and permissions (must)
- Tokens and secrets in secure storage (Keychain/Keystore via `expo-secure-store` or equivalent), never in AsyncStorage or plain files; no secrets in the bundle.
- Ask for permissions just in time, explain why, and handle denial gracefully.
- Certificate pinning and jailbreak/root detection only if the threat model requires them.

## Platform and accessibility
- Respect platform conventions (back button on Android, safe areas, keyboard avoidance); `Platform.select` or `.ios.tsx`/`.android.tsx` files for real differences.
- Every touchable has an `accessibilityLabel` and `accessibilityRole`; touch targets at least 44×44 pt; supports dynamic type and screen readers.

## Releases
- Versioning and build numbers automated; OTA updates only for JS-only changes compatible with the installed native code (runtime version policy).

## Testing
- React Native Testing Library for components (query by role/label); E2E with Maestro or Detox on real or emulated devices for the critical journeys.

## Review checklist
- [ ] Long lists virtualized with stable keys; no blocking work on gestures.
- [ ] Offline/poor-network behavior and app-resume handled.
- [ ] Secrets in secure storage only; permissions just in time.
- [ ] Accessibility labels/roles and target sizes; safe areas and keyboard handled.

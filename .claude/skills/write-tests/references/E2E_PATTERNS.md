# E2E patterns

## Structure (web, Playwright-style)
```
<e2e-root>/
├── fixtures/         # auth state per role, API seeding helpers
├── pages/            # page objects: one per screen id (S-05 → checkout.page.ts)
└── specs/            # one spec per feature; test titles start with the TC id
```
```ts
test('TC-001 create order with valid payment (AC-ORD-1)', async ({ page, seed, evidence }) => {
  await seed.cart('twoItems');                                  // API/factory seeding, never via the UI
  const checkout = await new CartPage(page).open().then((c) => c.checkout());
  await expect(checkout.total).toHaveText('120.00');
  await evidence(page, 'TC-001', '1-checkout');                  // screenshot to docs/delivery/evidence/TC-001/
  const confirmation = await checkout.pay();
  await expect(confirmation.heading).toHaveText(/order confirmed/i);
  await evidence(page, 'TC-001', '2-confirmation');
});
```
Evidence helper: `await page.screenshot({ path: \`docs/delivery/evidence/${tc}/${step}.png\`, fullPage: true })`.

## Selectors (in priority order)
1. Role + accessible name: `getByRole('button', { name: 'Pay' })`
2. Label / placeholder / text for form fields
3. A `data-testid` agreed with the frontend (ask through `NEEDS: frontend — test id …`)
Never use CSS classes, DOM position or generated ids.

## Data and isolation
- Each test seeds its own data through the API or factories, and uses unique values (suffixed with the test id).
- Store authentication state per role once in a fixture. Don't log in through the UI in every test.
- No order dependence between tests. Tests can run in parallel.
- External services (payment, email) run in their sandbox or test mode, or as contract mocks. Never production.

## Waiting and flakiness
- Use web-first assertions (`toHaveText`, `toBeVisible`). Never fixed sleeps.
- Retry at most once in CI. A test that fails, then passes, gets **flaky** marked in the QA report, and a ticket opens for it.
- Collect traces, video or screenshots on failure.

## Mobile (Maestro-style flow)
```yaml
# .maestro/TC-020-login.yaml   (AC-AUTH-1)
appId: ${APP_ID}
---
- launchApp: { clearState: true }
- tapOn: { id: "email" }
- inputText: "qa+tc020@example.test"
- tapOn: { id: "password" }
- inputText: ${TEST_PASSWORD}
- tapOn: "Sign in"
- assertVisible: "Welcome"
- takeScreenshot: docs/delivery/evidence/TC-020/1-home
```
Detox-style tests follow the same rules: accessibility ids, seeded data, screenshots per step.

## API-level cases
Use the generated client or schema-aware requests; assert status, body shape and error codes from the contract; cover authorization with each role's token.

## Accessibility checks
Run an automated scan (e.g. an axe integration) on every P1 screen and state; fail on serious or critical violations. Add a keyboard-only walkthrough of the P1 journeys.

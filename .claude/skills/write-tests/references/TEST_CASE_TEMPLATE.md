# TEST-CASES.md template

```markdown
> Status: in-review · Owner: qa-agent · Sources: PRD.md, BA-ANALYSIS.md, UI-UX.md, contracts · Updated: <ISO>

# Test cases

## Conventions
Priority: P1 release-blocking · P2 important · P3 minor. Type: manual | e2e | api | mobile. Test data comes from seeds/factories (never production data).

## TC-001 Create order with valid payment (AC-ORD-1)
- **Type / priority:** e2e / P1        **Persona:** customer        **Screen:** S-05 Checkout
- **Preconditions:** signed-in customer; cart contains 2 items (seed `cart.twoItems`)
- **Test data:** test card from the payment provider's sandbox (by name, e.g. "sandbox visa success")
- **Steps:**
  1. Open the cart and select "Checkout"
  2. Confirm the address and select "Pay"
- **Expected:**
  1. The checkout page shows a total of 120.00
  2. A confirmation page with the order number is shown; the order list shows the status "Confirmed"
- **Evidence:** docs/delivery/evidence/TC-001/

## TC-002 Missing postcode blocks checkout (AC-ORD-2)
…

## Traceability
| AC | Test cases | Types | Covered |
|---|---|---|---|
| AC-ORD-1 | TC-001 | e2e | ✓ |
| AC-ORD-2 | TC-002, TC-003 | e2e, api | ✓ |

## Non-functional checks
| Check | Method | Target | TC |
|---|---|---|---|
| Accessibility | automated a11y scan + keyboard walkthrough on P1 screens | no serious violations | TC-090 |
| Performance | load test on the main operations | p95 < target from PRD | TC-091 |
```

## Coverage checklist per feature
- [ ] Happy path, and each alternative path from the BA journeys
- [ ] Validation: required, format, min/max, unexpected types
- [ ] Permission: each role allowed and denied, plus another user's object
- [ ] Empty, loading and error states for each screen
- [ ] Concurrency and double submission where data is shared
- [ ] Recovery: network failure, retry, session expiry
- [ ] Accessibility: keyboard-only and screen-reader names on P1 flows

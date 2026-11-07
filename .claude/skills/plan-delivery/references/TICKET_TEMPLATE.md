# Ticket template

```markdown
T-<nnn> · <imperative title>
role: frontend | backend | mobile | devops | integration | qa | security      milestone: ms-<n>      size: S | M
depends_on: [T-…]
acceptance: [AC-…]            test_cases: [TC-…]            contracts: [<operationId>…]
owned_paths: ["<subset of project.json roles.<role>.paths>"]
mockups: [docs/delivery/mockups/<screen>-*.png]                (UI tickets)
components: [<DESIGN-SYSTEM.md components used>]                  (UI tickets)

## Goal
One or two sentences: the user-visible outcome.

## Scope
- In: …
- Out: … (anything for other roles goes in a separate ticket)

## Notes
Business rules (BR-…), edge cases, data/migration notes, feature flags.

## Definition of done
- [ ] Tests written first and failing, then passing (red/green evidence)
- [ ] Role lint, typecheck and test green (commit gate)
- [ ] All AC listed above demonstrably met; evidence in docs/delivery/evidence/<ticket>/
- [ ] Independent reviewer APPROVE
- [ ] One Conventional Commit with `Refs: T-<nnn>`
```

## Good vs. bad tickets
| Bad | Good |
|---|---|
| "Build the orders feature" (several roles, large) | T-010 backend `createOrder` + `listOrders`; T-011 frontend orders list (S-03) against mocks; T-012 qa E2E TC-001..003 |
| "Fix stuff in checkout" | "Show the field-level error for a missing postcode (AC-ORD-2)" |
| Two parallel tickets that both edit the root dependency manifest | T-020 integrator/owner adds the dependencies first; the others depend on it |

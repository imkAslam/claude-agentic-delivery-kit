# Ticket template

## Feature, chore and spike tickets
```markdown
T-<nnn> · <role> · <module>: <capability>          e.g. "T-010 · backend · Auth API: signup, login, verification and recovery"
type: feature | chore | spike      role: frontend | backend | mobile | devops | integration | qa | security
milestone: ms-<n>      size: S | M | L      status: ready      module: <bounded context / feature folder>
depends_on: [T-…]
acceptance: [AC-…]            test_cases: [TC-…]            contracts: [<operationId>…]
owned_paths: ["<subset of project.json roles.<role>.paths>"]
mockups: [docs/delivery/mockups/<screen>-*.png]                (UI tickets)
components: [<DESIGN-SYSTEM.md components used>]                  (UI tickets)

## Goal
One or two sentences: the user-visible outcome of the whole capability.

## Checklist (M and L tickets; the engineer ticks these)
- [ ] <operation / screen / state 1> (AC-…)
- [ ] <operation / screen / state 2> (AC-…)

## Scope
- In: …
- Out: … (anything for other roles goes in their own ticket)

## Notes
Business rules (BR-…), edge cases, data/migration notes, feature flags, security controls from the threat model.

## Definition of done
- [ ] Every checklist item done; tests written first and failing, then passing (red/green evidence)
- [ ] Role lint, typecheck and test green (commit gate)
- [ ] All AC listed above demonstrably met; evidence in docs/delivery/evidence/<ticket>/
- [ ] Independent reviewer APPROVE (plus the database-reviewer for data changes)
- [ ] One Conventional Commit with `Refs: T-<nnn>`
```

## Bug tickets (created by triage, never by the planner)
```markdown
T-<nnn> · bug · <role> · <symptom in one line>
type: bug      role: <role>      milestone: ms-<n> (where the fix ships)      size: S | M
severity: P1 | P2 | P3      status: ready
bug_of: T-<original>        feature: F-<n>        acceptance: [AC-… that is broken]
found_in: <ms-n integration | mbr:ms-n | QA TC-… | acceptance | quality-security | staging | production>

## Reproduce
1. … 2. … 3. …
**Expected:** … (the AC)    **Actual:** …    **Evidence:** docs/delivery/evidence/<bug>/…

## Root cause
<filled by the engineer>

## Fix and regression test
- [ ] A regression test that fails before the fix and passes after it (named after the AC and the bug id)
- [ ] The fix, inside the original ticket's owned paths unless triage says otherwise
- [ ] Reviewer APPROVE; one commit `fix(<scope>): <subject>` with `Refs: T-<bug>, T-<original>`
- [ ] QA re-runs the reproduction on the candidate → status `verified`
```
**Severity:** **P1** blocks a journey, loses or corrupts data, or is a security flaw (fix before the next gate). **P2** a broken AC with a workaround (fix in the current or next milestone). **P3** cosmetic or minor (scheduled).

## Sizing
| Size | Effort | Typical content | Use for |
|---|---|---|---|
| **S** | ≤ 1 day | 1–2 operations or one screen state | Bugs, chores, a small change to an existing capability |
| **M** | 1–2 days | 3–5 operations, or 2–4 screens of one flow | **The default** for features |
| **L** | 2–4 days | 6–8 operations, or 5–6 screens of one module | A whole module capability (needs the checklist) |
| XL | > 4 days | | **Never.** Split by capability |

Slice **by capability, vertically within one role**, never by layer. A backend ticket includes its migrations, repository, service, handlers and tests; a frontend ticket includes its screens, state, API use and tests.

## Good vs. bad tickets
| Bad | Why | Good |
|---|---|---|
| T-021 "signup endpoint", T-022 "login endpoint", T-023 "OTP endpoint", T-024 "forgot password endpoint" … | Too small: one module split into many near-identical tickets that all touch the same files | **T-010 · backend · Auth API**: signup, login, logout, refresh, email verification, OTP send/verify, forgot/reset password (L, checklist of 8 operations) |
| T-030 "auth DTOs", T-031 "auth migrations", T-032 "auth service" | Sliced by layer: nothing works until all are done | One backend Auth API ticket containing all of them |
| "Build the whole user area" (auth + profile + settings + admin users) | Too big: several modules | Auth API (L) · Profile & settings API (M) · Admin user management API (M) |
| T-001 "root workspace files", T-002 "ignore rules", T-003 "env example" | Chores as tickets | **T-001 · backend · foundation**: scaffold, tooling, health, env example (checklist) |
| "Build the orders feature" (several roles) | Several roles in one ticket | T-040 backend Orders API · T-041 frontend Orders screens against mocks · T-042 qa Orders E2E |
| "Fix stuff in checkout" | No clear outcome | Bug T-077 linked to T-041: "Missing postcode error not shown (AC-ORD-2)" |
| Two parallel tickets that both edit the root dependency manifest | File overlap | The owner's ticket adds the dependencies first; the others depend on it |

# Engineering principles (always on)

The principles every role designs and builds by. The detailed rules are in `coding-standards.md` (code), `database-standards.md` (data), `secure-coding.md`, `testing.md`, `api-design.md` and `documentation.md`. When two principles conflict, the order below is the priority, and the trade-off is recorded in an ADR.

1. **Correct, then secure, then simple, then fast.** Meet the acceptance criteria and the threat model first. Optimize only what a measurement or an NFR says is slow.
2. **Simplicity (KISS, YAGNI).** Build what the ticket needs today, in the plainest way that meets it. No speculative abstraction, configuration or extension points. A modular monolith beats distributed parts until a driver says otherwise.
3. **Single responsibility and separation of concerns.** One reason to change per module, class and function. UI, application logic, domain rules and infrastructure live in separate layers.
4. **Dependencies point inward.** Domain code depends on nothing: no framework, ORM, HTTP or vendor SDK. Infrastructure implements ports the domain defines (LAYERED_BLUEPRINT dependency rule, enforced by the import-boundary lint).
5. **Explicit contracts at every boundary.** APIs, events, ports and modules have typed, documented interfaces. Validate input where it enters; trust nothing from outside the boundary.
6. **DRY by knowledge, not by text.** One source of truth for each business rule. Duplicate code twice before extracting on the third use (rule of three); a wrong abstraction costs more than duplication.
7. **Composition over inheritance; small, pure, immutable where practical.** Prefer pure functions and immutable data for domain logic; isolate side effects at the edges.
8. **Fail fast, fail loud, fail safe.** Reject invalid state at construction. Never swallow errors. On failure, keep data consistent and the user informed, and deny access rather than grant it.
9. **Design for failure.** Every remote call has a timeout; retries are bounded, use backoff with jitter and hit only idempotent operations; circuit breakers protect dependencies; work that must happen survives a crash (outbox, durable queue).
10. **Observable by default.** Structured logs with a request id, metrics for the golden signals (latency, traffic, errors, saturation), traces across services, and health checks. If it can't be seen in production, it isn't done.
11. **Secure and private by design.** Least privilege, deny by default, data minimization, secrets by name only (`secure-coding.md`, `security.md`).
12. **Evolve without breaking.** Additive changes, expand → migrate → contract for data and APIs, feature flags for risky releases, and a rollback for every change. Prefer decisions that are cheap to reverse; make the expensive ones explicit in an ADR.
13. **Configuration in the environment.** Build once, deploy many: the same artifact runs in every environment; config and secrets come from environment variables, validated at startup.
14. **Automate what repeats.** Format, lint, typecheck, test, scan and deploy run in CI. A check that only runs on one laptop doesn't exist.
15. **Consistency beats preference.** Follow the patterns already in the codebase and the project's conventions. Changing a convention is a decision with an ADR, not a drive-by edit. Where they're written down (both are created during a run, not shipped with the kit):
    - `.claude/PROJECT.md`: the stack, coding conventions and tools, written by the solution-architect at the `boundaries` step after G1. Before that, use PRD §10–§11 and `ARCHITECTURE.md`.
    - `docs/CODEMAP.md`: where the code lives, written by the docs-writer after each milestone is integrated. Before the first one, use the planned folder structure in PRD §11 and search the code (`grep`).
16. **Small, reviewable increments.** One ticket, one concern, one commit. Leave the code you touch a little better, but refactor beyond the ticket only through a ticket.
17. **Few, deliberate dependencies.** Add a library only when it saves real work, is maintained, licensed compatibly and free of known critical vulnerabilities, and say why in the ticket report.

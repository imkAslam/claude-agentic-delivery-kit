# Readiness rubric

Score each dimension 0–10 using the anchors (interpolate between them). Weighted sum ÷ 10 = readiness %.

| # | Dimension | Weight | 0 — absent | 5 — partial | 10 — ready |
|---|---|---|---|---|---|
| 1 | Problem & goals | 10 | No stated problem | Problem stated, no measurable goal | Problem, goals and success metrics agreed |
| 2 | Users & roles | 10 | Users unknown | Main user named | All personas/roles with goals and permissions |
| 3 | Scope in / out | 15 | No boundary | In-scope list only | In, out and later agreed, with the MVP slice identified |
| 4 | Key journeys | 15 | None | Happy paths for the main users | Happy, alternative and error paths for the MVP journeys |
| 5 | Business rules & data | 10 | None | Some rules, entities named | Rules precise and testable; entities and their lifecycle known |
| 6 | Integrations | 10 | Unknown | Systems named | Each integration has its owner, protocol, auth and data direction |
| 7 | Non-functional needs | 10 | None | A few stated (e.g. "fast") | Targets for security, privacy, performance, availability, accessibility, compliance |
| 8 | Constraints | 10 | None | Budget **or** timeline | Budget, timeline, hosting/region, team, existing contracts, stack preference (or "recommend one") |
| 9 | Success metrics | 5 | None | Qualitative | Quantified, with a baseline and a target |
| 10 | Brand & look and feel | 5 | Nothing known | A logo/colors, or a few likes and dislikes | Brand guidelines or assets provided, **or** the client agrees that agents propose directions; references, likes/dislikes and the tone are known |

The brand dimension never blocks the run: with no brand evidence, record `ASSUMPTION: no existing brand; agents propose 3 visual directions at G1` (define-brand skill).

## Severity of a gap
- **critical:** blocks dependent work (e.g. an unknown payment provider blocks checkout design)
- **major:** work can start, but rework is likely
- **minor:** a polish item; it won't change the design

## Question rules
Ask only **business** questions (see `.claude/rules/decision-policy.md`): **at most 5 per round**, each with options and a recommended default. Technical unknowns (hosting details, protocols, the technical scope of a regulation, tooling, the integration mechanism) become `ASSUMPTION:` notes for the architect, not questions. Once the score reaches **80%**, stop the intake loop. The remaining business items move to G1 as tracked assumptions.

## Typical questions per dimension
1. What problem costs the client money or time today, and how will we know it's solved?
2. Who uses it, how often, and with which permissions? Are there admins or back-office roles?
3. What's explicitly *not* in the first release?
4. Walk through the most important task step by step. What can go wrong?
5. What exact rules apply (limits, approvals, calculations, state changes)?
6. Which external systems are involved, who owns them, and do we have API access?
7. Is there personal or payment data? Which regions? What uptime and response-time expectations?
8. What are the budget, deadline, hosting preference and existing licenses? Do you have a preferred tech stack (languages, frameworks, database, hosting) or a team that will maintain it, or should our architect recommend one?
9. Which number should move, and by how much?
10. Is there an existing brand (logo, colors, fonts, guidelines)? Which products do you like or dislike the look of, and how should users feel?

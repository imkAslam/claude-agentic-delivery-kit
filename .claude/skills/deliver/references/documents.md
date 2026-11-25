# Documents: the lean set

A run writes **few documents, each with one owner and a length limit.** Everything else is a section inside one of them. Across the kit, `X.md › Name` means "the section called Name inside X.md" (for example `PRD.md › Analysis`). A template that used to produce its own file now describes that section.

## 1. The set (paths under `docs/delivery/` unless shown)
| Document | Sections (who writes them) | Limit (lines) | Gate |
|---|---|---|---|
| `Intake-Readiness.md` | Evidence, agreed decisions, gaps, score (intake-agent) | 80 | intake |
| `PRD.md` | §1–§9 requirements (product-manager) · **Analysis**: personas and permissions, journeys, business rules, entities, acceptance criteria (ba-agent) · §10–§12 architecture summary and every diagram (solution-architect) · **Research notes**: only when the researcher ran, one table (researcher-agent) | 900 | g1 |
| `ARCHITECTURE.md` | §0–§14 (solution-architect) · **Research**: the candidates and why, one table (the detail goes in the stack ADR) · **Integrations** (integration-engineer) · **Operations**: environments, pipeline, hosting, backups, secrets by name (devops-engineer) · **API conventions**: only what differs from the kit's API rules (api-designer) · **Security**: trust boundaries, controls, abuse cases (cybersecurity-agent) | 750 | g1, g2 |
| `THREAT-MODEL.md` | **Only** when the product handles payments, health data or other sensitive personal data; otherwise the Security section above is enough | 250 | g1 |
| `DATA-MODEL.md` | database-architect | 500 | g2 |
| Contracts (`contracts.paths`) | api-designer | — | g2 |
| `DESIGN.md` | **Directions** (for G1; the chosen one stays, the others are deleted after G1) · **Brand** · **UX**: flows, screen inventory, states matrix, copy · **Components**: only what differs from the UI library (uiux-agent) | 800 | g1 (Directions), g2 |
| `tokens.json` (+ themes), `mockups/` (key screens: default + one unhappy state), `brand/` | uiux-agent | — | g2 |
| `PLAN.md` | **Milestones** · **Tickets** (one short block per ticket: role, scope, AC ids, paths, checklist) · **Quality**: checks and thresholds · **Test cases**: one line per AC, the journeys for end-to-end (qa-agent) · **Features**: status table (docs-writer) | 400 + 12 per ticket | g2 |
| `milestones/<ms>/REVIEW.md` | **Build** (what was built) · **Tickets** (one row each: commit, verdict, commands and results) · **Checks** · **Run guide** · **Design QA** · **Performance** · **Improvement report** (orchestrator) | 200 | mbr |
| `milestones/<ms>/screens/` | One screenshot per screen built in the milestone | — | mbr |
| `ACCEPTANCE.md` | **Summary** · **QA** · **Open issues** · **Quality and security** · **Security audit** · **Performance** | 300 | acceptance |
| `RELEASE.md` | **Review** · **Deployment plan** · **Rollback** · **Operations handoff** · **Result** | 250 | g3, ops_ack |
| `BASELINE.md` (adopt runs) | Check results, boundaries, debt register · **Tests**: the test inventory | 300 | baseline |
| `GATE-LOG.md`, `LESSONS.md` | Gate decisions and change requests; lessons (orchestrator) | — | — |
| `docs/CODEMAP.md`, `docs/database/DATABASE.md`, `docs/SYSTEM-FLOWS.md` | Living, as built (docs-writer) | 150 · 400 · 300 | — |
| `docs/adr/ADR-*.md` | **Major decisions only:** stack, architecture style, data store, authentication, hosting, and anything expensive to reverse. Every other technical choice is one line in ARCHITECTURE | 60 each | — |
| `README.md`, `CHANGELOG.md` | docs-writer | — | — |

## 2. What is not written any more
- No separate research, analysis, API-guidelines, integrations, DevOps-plan, brand-brief, UI/UX, design-system, delivery-plan, tickets, quality-plan or test-cases files, and no per-ticket files: each is a section above.
- No `MESSAGES.md`: agent messages live in the run state (`delivery-state.sh msg …`).
- No change-request draft files: a change request is one row in `GATE-LOG.md` (what changes, why, approved by) plus the edits themselves.
- No `docs/README.md` index, no `FEATURES.md`, no ADR index: the folder and `PLAN.md › Features` are enough.
- No report per agent: reviewers and checkers write their result into the section of the document they review.

## 3. Evidence
**Evidence is shown, not stored.** A ticket's proof is in its return block (the commands run, their exit codes, the test summary line) and becomes one row in `REVIEW.md › Tickets`. Do not save log files, command output, or per-ticket evidence folders.
- Screenshots: UI tickets save **one image per screen** (its final state) to `milestones/<ms>/screens/<screen-id>.png`. Design QA and the human review use these.
- A reviewer or the human who doubts a result re-runs the command; that is why every result names its command.
- Acceptance and audits follow the same rule: results in `ACCEPTANCE.md`, no report files.

## 4. Writing rules
- Every document opens with a **plain summary of at most five lines** that a non-engineer can read.
- Tables and short lines beat paragraphs. Say a thing once, in the document that owns it; elsewhere, point to it.
- Stay inside the limit. When a document is at its limit, cut what is no longer needed before adding. **Never cut a required format to fit** (a template section, a table, a tree, a diagram the kit requires): if the required content doesn't fit, keep it, and report it in your return block as `NEEDS: <document> is over its limit with required content (<sections>)`; the orchestrator decides with the human whether to raise that project's limit (`project.json → docs.limits`) or move content.
- Several agents write sections of the same file. Each agent edits **only its own section**; the orchestrator runs them one after another when two would touch the same file.

## 5. Checking
`bash .claude/skills/integrate-milestone/scripts/check-hygiene.sh` has a `docs` check: a file in `docs/delivery/` that is not in §1, or a document over its limit, is a finding. It runs at every gate and at every integration.

## 6. Runs that started before the lean set
A run whose `project.json` says `"docs": { "layout": "classic" }` keeps the documents it already has, adds no new document types, and skips the `docs` check. The lean set is the default for every new run.

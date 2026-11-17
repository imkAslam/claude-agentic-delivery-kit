# As-built rules (every agent in `MODE: adopt`)

In a new project a document is a decision. In an adopted codebase a document is a **description**, and it is only useful if it is true. These rules apply to every as-built artifact.

## 1. Evidence
- **Every statement cites its source:** `path/to/file.ext:line` (or a line range), a test name, a config key, a migration file, or an existing document. A table of features, tables or operations has a "Source" column.
- **Read before you write.** Do not infer a framework convention where the code may differ; open the file.
- Prefer sources in this order: tests (they prove behavior) → code → configuration → migrations → existing documentation (often stale: verify it against the code and say when it disagrees).
- Record what you did **not** read ("not covered: `legacy/reports/**`, 214 files") so the gaps are known.

## 2. Labels
Use these labels so readers can tell fact from guess:
| Label | Meaning |
|---|---|
| *(no label)* | Verified in the cited source |
| `AS-BUILT:` | How it works today, when that differs from the kit's standards or from the existing documentation |
| `ASSUMPTION:` | A reasonable reading the code doesn't prove; say what would confirm it |
| `QUESTION:` | A business fact the code can't tell; goes to the baseline gate with a recommended default |
| `DEBT: D-<n>` | A problem recorded in the BASELINE debt register |
| `NOT DERIVABLE:` | Something the template asks for that can't be recovered from the repository (say why) |

## 3. Never invent
- **No acceptance criteria without proof.** Write `AC-…` only where a test demonstrates the behavior (cite the test). Elsewhere write "AC: to be written when this feature changes".
- **No business rules from intuition.** A rule is listed only with the code that enforces it.
- **No targets as facts.** Performance, uptime, retention and scale targets are `QUESTION:` items unless a config value or document states them.
- **No tidy architecture that isn't there.** Describe the layers and dependencies that exist. Where the code breaks the kit's dependency rule or standards, say so and record a debt; do not draw the ideal.
- **No designs.** Tokens come from the existing theme, components from the existing component folder, screens from real screenshots.

## 4. Decisions that were already made
Stack, structure and library choices found in the code become ADRs with status `accepted (inherited)`: context "found in the codebase at the baseline", the evidence, the consequences observed, and "alternatives: not recorded". They are not re-opened by agents; changing one is a change request.

## 5. Record, don't fix
Lane `adopt` changes no product code, configuration or tests. Every problem found becomes a debt register entry with evidence and a proposal (fix now / fix when touched / accept). The one exception is reporting: a P1 security or data-loss issue is reported to the orchestrator at once.

## 6. Diagrams
Draw only what the code supports: usually D0 context, D1 main system, D3 deployment, D6 data, D7 integrations. For each of the others (D2 layers, D4 trust boundaries, D5 sequences, D8 CI/CD) either derive it or list it under "NOT DERIVABLE" with what is missing. Diagrams are written in the PRD by the solution-architect and mirrored into ARCHITECTURE §14 (`sync-diagrams.sh`). In an adopt run, `check-diagrams.sh --require` lists only the derived ids.

## 7. Size and cost
- Start from manifests, entry points, route tables, the schema and the test folders; they describe most of a system cheaply.
- Sample large modules (the biggest, the most changed in `git log`, the ones the human named) and state the sample.
- Keep each document as short as its template allows. The code map is about 150 lines however large the repository is.

## Review checklist (architect-reviewer, `as-built-review`)
- [ ] Every claim has a citation; sampled citations are correct.
- [ ] Labels are used: no unmarked assumptions, no invented acceptance criteria, targets or designs.
- [ ] `project.json`: paths exist and don't overlap, every command was run and passed, unmapped folders are listed.
- [ ] Deviations from the kit's standards are debts, not hidden and not "fixed" in the documents.
- [ ] What was not read is stated.
- [ ] No secrets, tokens, personal data or internal hostnames in any document.

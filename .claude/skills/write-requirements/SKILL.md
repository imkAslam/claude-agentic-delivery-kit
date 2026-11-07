---
name: write-requirements
description: "Requirements toolkit for research, business analysis and product management: 5-product market comparison, BA analysis (personas, journeys, business rules, entities, acceptance criteria), PRD authoring and revision, and the product-owner review checklist. Includes templates and a Given/When/Then acceptance-criteria guide."
when_to_use: "Use when writing RESEARCH.md, BA-ANALYSIS.md or PRD.md, when revising the PRD after review findings, or when reviewing a PRD for value, scope and testability."
---

# Write requirements

Lane `understand`, steps `research` → `ba` → `discovery`. Produces the inputs for gate **g1**.

## When to Use
- **researcher-agent:** after the intake gate, when the domain is unfamiliar or the scope is broad
- **ba-agent:** to turn the agreed intake into a structured requirements model
- **product-manager:** to write the PRD, and to revise it after product or technical corrections
- **product-owner-reviewer:** to review a PRD draft

## Instructions

### Step 0: Load the inputs
Read the approved `docs/delivery/Intake-Readiness.md` (the decision log is binding), the evidence in `docs/intake/`, and whatever earlier artifacts exist: `RESEARCH.md`, `BA-ANALYSIS.md`, `PRD.md`. In a revision round, read the brief's `PRIOR FINDINGS` first.

### Step 1: Research (researcher-agent)
Follow [RESEARCH_TEMPLATE.md](references/RESEARCH_TEMPLATE.md). Choose 5 comparable products or approaches and cite fetched sources. Close with *table stakes* (features users will expect) and *differentiators*. Skip the whole step, recording the reason, for a known or narrow change.

### Step 2: Business analysis (ba-agent)
Follow [BA_TEMPLATE.md](references/BA_TEMPLATE.md): personas and permissions, a feature map with MoSCoW priorities, journeys (happy, alternative and error paths), business rules `BR-<n>`, conceptual entities with their state machines, non-functional needs, out of scope, and open questions.

### Step 3: Acceptance criteria (ba-agent, product-manager)
Write every criterion as Given/When/Then with a stable id `AC-<area>-<n>`, following [ACCEPTANCE_CRITERIA.md](references/ACCEPTANCE_CRITERIA.md). Each story needs at least one happy-path, one validation/error and one permission criterion, and empty-state and concurrency criteria where they apply.

### Step 4: PRD (product-manager)
Follow [PRD_TEMPLATE.md](references/PRD_TEMPLATE.md). Slice the release into milestones, each delivering one usable end-to-end journey. In a revision round, add a `Revision log` entry for every finding you addressed or rejected (with the reason).

### Step 5: Review (product-owner-reviewer)
Apply the review checklist in [PRD_TEMPLATE.md](references/PRD_TEMPLATE.md#review-checklist). Return `VERDICT: APPROVE | CHANGES` with findings `[P1|P2|P3] §section — problem — required change`.

## Rules
- Trace everything: PRD → BA → decision log → evidence. Nothing appears without a source or an `ASSUMPTION:` label.
- No technology choices. Technical constraints come from the solution-architect, as findings.
- A scope trade-off is a decision for the human at G1. Show the options and their consequences.

## Integration with Other Skills
- **intake-readiness:** the source of agreed decisions.
- **design-architecture:** the architect reviews the PRD in the same discovery round.
- **threat-model:** the security acceptance criteria (`AC-SEC-<n>`) are added to the PRD.
- **write-tests:** QA derives test cases from the `AC-` ids.

## File Structure
```
.claude/skills/write-requirements/
├── SKILL.md
└── references/
    ├── RESEARCH_TEMPLATE.md
    ├── BA_TEMPLATE.md
    ├── PRD_TEMPLATE.md          # includes the PO review checklist
    └── ACCEPTANCE_CRITERIA.md   # Given/When/Then guide with examples
```

---
name: intake-readiness
description: "Turns raw client evidence (briefs, notes, transcripts, screenshots, spreadsheets) into a scored readiness package: evidence inventory, agreed-decision log with supersession, weighted readiness score, gaps with consequences, and prioritized questions for the Intake gate."
when_to_use: "Use at the start of a delivery run, whenever new client evidence arrives, or when the user asks whether requirements are ready to start."
---

# Intake readiness

Produces `docs/delivery/Intake-Readiness.md`, the review package for the **intake** gate.

## When to Use
- First step of every delivery run (lane `understand`, step `intake`)
- New or changed evidence lands in `docs/intake/`
- The human answered intake questions and the score must be recomputed

## Instructions

### Step 0: Collect the inputs
1. List every file in `docs/intake/` (recursively). Read text, markdown, PDF, spreadsheets and images. For audio or video, use the transcript if one exists; otherwise record "not readable" as a gap.
2. If `Intake-Readiness.md` already exists, read it and note its round number. You'll carry forward the answered questions.

### Step 1: Build the evidence inventory
For each source: `E-<n>` id, file, type, date, author/owner, and a one-line summary. The newest file isn't automatically authoritative.

### Step 2: Build the decision log
Extract each decision (scope, rule, constraint, priority) as `D-<n>`, citing its source `E-<n>`. Apply **supersession**: the latest decision the client actually *agreed to* wins. A newer draft, an unconfirmed suggestion or a later timestamp doesn't override an agreed decision. Mark each losing entry `superseded by D-<m>` with the reason. Conflicts you can't settle become questions.

### Step 3: Score readiness
Score each dimension with [READINESS_RUBRIC.md](references/READINESS_RUBRIC.md) (0–10 against its anchors), multiply by the weight, and sum to a percentage. Show the table.

### Step 4: Gaps, consequences, questions
- Each gap gets a dimension, a **consequence** if left unresolved (which work it blocks or puts at risk) and a severity: `critical` (dependent work can't start), `major`, or `minor`.
- Each question is concrete and answerable, linked to the gap it closes, and ordered by impact. Offer options where it helps ("A or B?").

### Step 5: Recommendation
Apply the gate rule: **80% or more** → Start / Update / Hold. **Below 80%** → Update / Provisional scope / Hold. With any **critical** gap, list the dependent work that must wait.

### Step 6: Write the package
Use [INTAKE_TEMPLATE.md](references/INTAKE_TEMPLATE.md) exactly. Set `Status: in-review`.

## Rules
- Cite `E-<n>` for every fact. Label inferences `ASSUMPTION:`.
- Don't propose solutions or technology. Readiness is about the problem and the agreement.
- Never ask the human directly. Questions go in the package; the orchestrator presents them at the gate.

## Integration with Other Skills
- **gate-review** presents this package at the `intake` gate.
- **write-requirements** consumes the decision log and the answered questions.

## File Structure
```
.claude/skills/intake-readiness/
├── SKILL.md
└── references/
    ├── READINESS_RUBRIC.md     # dimensions, weights, 0/5/10 anchors
    └── INTAKE_TEMPLATE.md      # Intake-Readiness.md structure
```

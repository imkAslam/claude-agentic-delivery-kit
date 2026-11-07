---
name: threat-model
description: "Security design and assessment toolkit: STRIDE threat model with data-flow diagram and trust boundaries, security acceptance criteria, a controls catalog (auth, authorization, input handling, secrets, crypto, rate limiting, logging, supply chain, privacy), and the procedure for assessing and verifying security fixes."
when_to_use: "Use when the PRD involves auth, payments, personal data, multi-tenancy, uploads, public APIs or compliance; for security tickets; for security reviews; and when the quality/security agent evaluates scan findings."
---

# Threat model

For the **cybersecurity-agent** (design input in lane understand, security tickets in lane build), the **security-reviewer**, and the **quality-security-agent** (when evaluating findings).

## When to Use
- During discovery, when data sensitivity or exposure calls for it (the orchestrator decides from the intake and the PRD)
- Security-labeled tickets: implementing a control or assessing an area
- Reviewing any diff that touches auth, input handling, secrets, data access or uploads
- Triaging scanner findings into real issues

## Instructions

### Step 0: Load the inputs
`PRD.md` (data, users, NFRs), `BA-ANALYSIS.md` (entities and their data classes), `ARCHITECTURE.md` (containers, topology), contracts (auth on each operation), and `DEVOPS-PLAN.md` (environments and secrets) if it exists.

### Step 1: Model the system
Follow [THREAT_MODEL_TEMPLATE.md](references/THREAT_MODEL_TEMPLATE.md): assets and data classes, actors, the data flow with its **trust boundaries**, and entry points. The diagram is **PRD §12 · D4**: send your boundary and data-class corrections to the solution-architect in a `handoff` message. Never create a separate diagram file or a copy here (`design-architecture/references/DIAGRAMS.md` → "Single home").

### Step 2: Enumerate the threats (STRIDE per boundary-crossing flow)
Spoofing, Tampering, Repudiation, Information disclosure, Denial of service, Elevation of privilege. Rate each threat's likelihood and impact (L/M/H) → its priority.

### Step 3: Choose controls
Choose from [CONTROLS_CATALOG.md](references/CONTROLS_CATALOG.md). Map each high- or medium-priority threat to one or more controls, an owner role and a verification method (a test, a scan, a review).

### Step 4: Security acceptance criteria
Write `AC-SEC-<n>` in Given/When/Then form for each control that's testable (see the write-requirements acceptance guide). The PM merges them into the PRD, and QA covers them.

### Step 5: Build-time work (security tickets)
Implement controls test-first, inside the owned paths. For an assessment: read the code, reproduce safely in a local or test environment only, and report `file:line`, severity, an exploit scenario, the fix, and a test that would fail without the fix.

### Step 6: Review and verification (security-reviewer)
Apply the Security section of **review-checklists**. For each claimed fix, confirm a regression test exists. Scan the diff for secrets.

## Rules
- Dynamic testing runs **only** against environments listed in `DEVOPS-PLAN.md` as owned by the project, with the authorization recorded in the brief.
- Never write real secrets or exploit payloads that target third parties.
- Severity: CRITICAL/HIGH blocks a merge or release unless the human accepts the risk at a gate.

## Integration with Other Skills
- **design-architecture:** controls go into ARCHITECTURE §10; contracts carry auth and rate limits
- **write-requirements:** `AC-SEC-` criteria become part of the PRD
- **review-checklists:** the security reviewer's checklist
- **release-docs:** security items in the release review (secrets rotation, dependency status)

## File Structure
```
.claude/skills/threat-model/
├── SKILL.md
└── references/
    ├── THREAT_MODEL_TEMPLATE.md   # THREAT-MODEL.md structure with DFD and STRIDE table
    └── CONTROLS_CATALOG.md        # controls by area with verification methods
```

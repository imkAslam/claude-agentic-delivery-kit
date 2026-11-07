---
name: security-audit
description: "Scoped, authorized security audit workflow for web apps, APIs, mobile backends and infrastructure: scope and authorization, attack-surface mapping of owned assets, automated scanning (SAST, dependency, secrets, container and IaC), manual data-flow tracing and adversarial feature analysis, OWASP Top 10:2021 and API Top 10:2023 testing, authorized dynamic testing on owned staging, hardening verification, compliance mapping, and CVSS-rated reporting with quality gates."
when_to_use: "Use for the security audit in Verify & Accept, a pre-release or delta audit, a compliance readiness check, investigating a reported vulnerability, or designing the CI security pipeline."
---

# Security audit

For the **security-auditor**, with support from the **quality-security-agent** (automated tools), the **cybersecurity-agent** (threat model and controls) and the **devops-engineer** (pipeline and cloud posture).

## When to Use
- Lane `verify`, `verify-fork`: the full audit of the accepted candidate
- Before a release: a delta audit of the changes since the last report
- Designing or reviewing the CI security stages (with the devops-engineer)
- A vulnerability report or incident: a focused audit of the affected area

## Instructions

Follow the phases in [AUDIT_WORKFLOW.md](references/AUDIT_WORKFLOW.md). Each phase lists its actions, tools (only the ones detected in `SYSTEM-PROFILE.md`) and evidence.

| Phase | Goal | Key references |
|---|---|---|
| 0. Scope and authorization | The assets, environments, standards and authorization recorded | `DEVOPS-PLAN.md`, the brief |
| 1. Attack surface (owned assets only) | Entry points, technologies, exposed services, data flows | ARCHITECTURE, contracts, THREAT-MODEL |
| 2. Automated scanning | SAST, dependencies/SBOM, secrets, containers, IaC | [DEVSECOPS_PIPELINE.md](references/DEVSECOPS_PIPELINE.md) |
| 3. Manual review | Data-flow tracing, adversarial feature analysis, auth and middleware choke points | [OWASP_CHECKLISTS.md](references/OWASP_CHECKLISTS.md) |
| 4. Web and API testing | OWASP Top 10:2021 + API Top 10:2023 checks | [OWASP_CHECKLISTS.md](references/OWASP_CHECKLISTS.md) |
| 5. Authorized dynamic testing | DAST and targeted manual tests on **owned staging** only | AUDIT_WORKFLOW §5 |
| 6. Hardening verification | Headers, TLS, cloud posture, least privilege, logging and monitoring | CONTROLS_CATALOG (threat-model skill) |
| 7. Reporting | CVSS-rated findings, remediation, residual risk, compliance | [AUDIT_REPORT_TEMPLATE.md](references/AUDIT_REPORT_TEMPLATE.md), [COMPLIANCE_MAP.md](references/COMPLIANCE_MAP.md) |

## Quality gates (all of them must hold before you report DONE)
- [ ] Scope and authorization are documented; no test ran outside them
- [ ] Every planned phase ran, or was skipped with a reason (for example, a tool isn't installed)
- [ ] Each finding was confirmed manually (no unverified scanner output), with a CVSS score and business impact
- [ ] Each finding has its remediation and a verification test
- [ ] Residual risk and the accepted risks are listed for the acceptance gate
- [ ] The report contains no secrets, live exploit payloads or personal data

## Safety
- **Authorization first.** Dynamic and intrusive testing only on environments listed as owned in `DEVOPS-PLAN.md`, with authorization recorded in the brief. Never on production without written approval from the human, recorded at a gate.
- Reconnaissance covers **the project's own assets only.** No third-party scanning, and no internet-wide search engines against other people's systems.
- Exploitation stays at proof-of-concept level: show impact with the minimum necessary action, never destructive, and roll back any test data.

## Integration with Other Skills
- **threat-model:** the planned threats and controls to verify (`CONTROLS_CATALOG.md`)
- **review-checklists:** the Security section, used per diff during build
- **ci / release-docs:** the DevSecOps stages and the security summary in the release review
- **design-database:** RLS, encryption and classification checks
- **write-tests:** confirmed findings become regression tests

## File Structure
```
.claude/skills/security-audit/
├── SKILL.md
└── references/
    ├── AUDIT_WORKFLOW.md          # phases 0–7: actions, tools, evidence
    ├── OWASP_CHECKLISTS.md        # Top 10:2021, API Top 10:2023, ASVS, headers, adversarial prompts
    ├── DEVSECOPS_PIPELINE.md      # CI security stages, tools by category, policies
    ├── COMPLIANCE_MAP.md          # GDPR, HIPAA, PCI DSS, SOC 2, ISO 27001, NIST CSF mapping
    └── AUDIT_REPORT_TEMPLATE.md   # SECURITY-AUDIT-REPORT.md, CVSS guidance
```

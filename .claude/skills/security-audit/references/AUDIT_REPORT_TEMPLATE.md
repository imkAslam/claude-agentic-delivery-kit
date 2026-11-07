# SECURITY-AUDIT-REPORT.md template

```markdown
> Status: in-review · Owner: security-auditor · Candidate: <commit sha> · Environment(s): <env> · Updated: <ISO>

# Security audit report

## 1. Executive summary
Overall posture (one paragraph, in business terms) · findings: Critical <n> · High <n> · Medium <n> · Low <n> · the top 3 risks and what fixing them protects.

## 2. Scope and method
| Item | Value |
|---|---|
| Assets | apps, APIs, mobile, infra in scope |
| Environments | local / staging (owned); production: not tested |
| Authorization | "<text from brief>", approved by <role> on <date> |
| Standards | OWASP Top 10:2021, API Top 10:2023, ASVS L<1/2/3>, <compliance frameworks> |
| Tools | <tool + version> per phase; skipped tools with reasons |

## 3. Attack surface
| Entry point | Auth | Data class | Notes |

## 4. Findings
### SA-001 <title>
- **Severity:** High · CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:N (8.1)
- **Category:** A01 Broken Access Control / API1 BOLA
- **Asset:** <operationId or route> · `file:line`
- **Description:** what's wrong, and where in the data flow
- **Reproduction (safe):** the steps with test accounts on staging; no live payloads
- **Impact:** data class and blast radius (user / tenant / global)
- **Remediation:** the concrete fix (code or config) and its owner role
- **Verification:** the regression test (TC id or test name) that fails before the fix and passes after
- **Status:** open / fixed (commit) / accepted (gate, approver, expiry)

## 5. Positive observations
Controls verified as working (so they aren't regressed).

## 6. Compliance mapping
| Framework | Requirement | Control / artifact | Status | Owner |

## 7. Residual risk and recommendations
Accepted risks (with expiry), recommended next steps, and when to re-audit.
```

## CVSS v3.1 quick guide
Score with the base metrics: **AV** (N/A/L/P), **AC** (L/H), **PR** (N/L/H), **UI** (N/R), **S** (U/C), **C/I/A** (H/L/N). Then adjust the priority for business context: data class, blast radius, compensating controls. Bands: Critical 9.0–10 · High 7.0–8.9 · Medium 4.0–6.9 · Low 0.1–3.9.

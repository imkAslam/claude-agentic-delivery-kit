# Audit workflow

Use only tools that `SYSTEM-PROFILE.md` shows as installed. Record each tool's version, command and exit code as evidence. Missing tools → "skipped (not installed)" in the report.

## Phase 0: Scope and authorization
1. List the assets in scope: apps, APIs, mobile builds, infrastructure (from ARCHITECTURE §3, §5 and DEVOPS-PLAN §1).
2. Identify the environments and their **ownership** (DEVOPS-PLAN). Only owned staging or test environments qualify for dynamic testing.
3. Record the authorization: the brief must state "dynamic testing authorized on <env> by <approver>". Without it, phases 5 and 6 are static only.
4. Note the compliance requirements (PRD NFRs, THREAT-MODEL §7) and the ASVS level (L1 by default; L2 for personal or financial data; L3 for high-assurance systems).

## Phase 1: Attack surface (owned assets only)
1. Entry points: every contract operation, page route, webhook, file upload, websocket channel, admin route and background job trigger.
2. Technologies and versions (from project.json and the dependency manifests).
3. Exposed services per environment (from IaC and platform config): ports, public buckets, debug endpoints, admin consoles.
4. Data flows across trust boundaries (THREAT-MODEL DFD); mark where personal or sensitive data crosses them.
Output: an attack-surface table in the report §3.

## Phase 2: Automated scanning
| Category | What | Example tools (use whichever is installed) |
|---|---|---|
| Secrets | The repo and its history | gitleaks, trufflehog (plus the kit's guard-secrets regex) |
| SAST | Code patterns | Semgrep, CodeQL, SonarQube (MCP/scanner) |
| Dependencies (SCA) + SBOM | Known CVEs, licenses | The package manager's audit, OSV-Scanner, Trivy, Syft (SBOM) |
| Containers | Image CVEs, misconfiguration | Trivy, Grype |
| IaC / config | Cloud misconfiguration | Checkov, tfsec/Trivy config, kube-linter |
Triage every result: confirm it by reading the code, or mark it a false positive with the reason. Unconfirmed scanner output never goes in the report as a finding.

## Phase 3: Manual review
1. **Data-flow tracing:** for each critical journey, follow the request through the client → edge → middleware → controller → service → repository/SDK → database, then the response path back. At every hop, check authentication, authorization, validation and encoding. Flag **privileged paths** (admin SDKs, service-role keys, background jobs) that skip RLS or ownership checks.
2. **Choke-point verification:** confirm the auth middleware covers every protected route (matchers, file naming, exports, ordering). Try a protected route without credentials, and with another tenant's credentials (in tests or on staging).
3. **Adversarial feature analysis:** for each feature, use the adversarial prompts in OWASP_CHECKLISTS §4.
4. **Configuration review:** CORS, cookies, headers, CSP, error handling, logging, rate limits, timeouts.

## Phase 4: Web and API testing
Go through the OWASP Top 10:2021 and API Top 10:2023 checklists (OWASP_CHECKLISTS §1–§2). Prefer automated tests in the test suite (they become regression tests), run against the local or staging environment.

## Phase 5: Authorized dynamic testing (owned staging only)
- Run a DAST baseline, then an authenticated scan where authorized (e.g. OWASP ZAP, or another scanner that's installed), and targeted manual tests for the high-risk areas found in phases 3–4.
- Proof of concept only: demonstrate impact with the minimum action, use test accounts, roll back the test data.
- **Never:** production, third-party systems, denial-of-service, destructive payloads, social engineering.

## Phase 6: Hardening verification
TLS configuration and HSTS · security headers · least-privilege IAM, CI and database roles · secrets in the secret store and rotated · logging of security events plus alerting · backups encrypted, with a tested restore · container and runtime settings (non-root, read-only filesystem where possible) · cloud posture (public access blocked, encryption on).

## Phase 7: Reporting
Write `SECURITY-AUDIT-REPORT.md` (AUDIT_REPORT_TEMPLATE.md): CVSS v3.1 per finding, business impact, safe reproduction, remediation, verification test, residual risk, and the compliance mapping. Append the confirmed findings to `OPEN-ISSUES.md`. Return the findings to the orchestrator for triage.

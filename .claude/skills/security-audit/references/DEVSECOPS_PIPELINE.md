# DevSecOps pipeline (shift-left)

The devops-engineer adds these stages through the `ci` skill. The security-auditor checks that they exist and that they gate correctly. Only tools available to the project are used; the others are listed as planned.

## Stages
| Stage | When | Gate | Typical tools |
|---|---|---|---|
| Pre-commit / hooks | Local | Blocks commits with secrets (kit hook) | guard-secrets.sh, gitleaks |
| Secrets scan | Every push / PR | Fail on any finding | gitleaks, trufflehog |
| SAST | Every PR | Fail on new high/critical | Semgrep, CodeQL, SonarQube quality gate |
| SCA + license | Every PR + nightly | Fail on new critical/high without an exception | Package-manager audit, OSV-Scanner, Trivy fs |
| SBOM | Every build | Artifact attached to the release | Syft / CycloneDX tooling |
| Container scan | Image build | Fail on critical/high fixable CVEs | Trivy, Grype |
| IaC scan | Infra PRs | Fail on high misconfigurations | Checkov, Trivy config, tfsec |
| DAST baseline | After the staging deploy | Report; fail on high alerts | OWASP ZAP baseline |
| Provenance / signing | Release builds | Required for production promotion | SLSA provenance, artifact signing (e.g. Sigstore cosign) |
| Policy as code | Infra and deploy | Deny non-compliant resources | OPA/Conftest, the cloud's native policies |

## Policies
- **New** high/critical findings block the merge. Existing ones are tracked with an owner and a due date (no silent baseline growth).
- Exceptions are time-boxed, with the reason and the approver recorded in OPEN-ISSUES and accepted at a gate.
- CI credentials are least privilege (OIDC where possible), with third-party actions and images pinned by SHA or digest.
- Secrets are managed in the platform's secret store, or a vault, with a rotation schedule documented in the DEVOPS-PLAN.
- Production promotion requires: green security stages on the **same artifact**, plus the SBOM and provenance attached.

## Monitoring and response (production)
- Alerts on authn anomalies, authz-denial spikes, error spikes and WAF blocks.
- An incident response playbook (NIST-style: prepare → detect → contain → eradicate → recover → lessons learned) in OPERATIONS-HANDOFF, with breach-notification steps when personal data is involved.

# Controls catalog

| Id | Control | Applies when | Verify by |
|---|---|---|---|
| **Authentication** ||||
| C-AUTH-1 | Use a vetted auth library or provider; no custom password crypto | any login | review |
| C-AUTH-2 | Password hashing with a memory-hard algorithm (argon2id / scrypt / bcrypt with an adequate cost) | local passwords | unit test on the hash format |
| C-AUTH-3 | MFA available (required for admins) | admin or sensitive data | e2e |
| C-AUTH-4 | Session cookies `HttpOnly; Secure; SameSite=Lax/Strict`; rotate on login and privilege change; idle and absolute timeouts | cookie sessions | integration test |
| C-AUTH-5 | Tokens: short-lived access tokens, rotating refresh tokens, server-side revocation | token auth | integration test |
| C-AUTH-6 | Account enumeration resistance (the same response for an unknown user and a wrong password) | login, reset | test |
| **Authorization** ||||
| C-AUTHZ-1 | Deny by default; permission checks in the service layer | always | review + tests per role |
| C-AUTHZ-2 | Object-level checks (owner/tenant scoping in queries) | any id in a URL or body | IDOR tests |
| C-AUTHZ-3 | Admin functions on separate routes with extra auth and audit | back-office | e2e + audit-log test |
| C-AUTHZ-4 | Auth middleware/guards verified to apply to every protected route (matchers, exports, file naming, ordering) | any framework middleware | test: protected route without credentials → 401 |
| C-AUTHZ-5 | Privileged clients (admin SDKs, service roles, background jobs) re-check ownership and tenancy before acting for a user; never used directly from request handlers without a check | privileged DB/SDK access | data-flow review + IDOR tests |
| C-AUTHZ-6 | Shared/global resources (settings, catalogs, templates) writable only by explicitly authorized roles | any shared state | authz tests per role |
| C-AUTH-7 | Passkeys/WebAuthn or TOTP for MFA; step-up auth for sensitive actions | sensitive actions | e2e |
| C-AUTH-8 | JWT validation: fixed algorithm allow-list, issuer, audience, expiry, key rotation (JWKS); no tokens in URLs | token auth | unit tests |
| **Input and output** ||||
| C-IN-1 | Schema validation at the boundary; reject unknown fields | all writes | contract tests |
| C-IN-2 | Parameterized queries only; no string-built queries or commands | data access, shell | review + SAST |
| C-IN-3 | Output encoding / framework auto-escaping; no raw HTML injection without a sanitizer | rendering user content | XSS test |
| C-IN-4 | CSRF protection for cookie-authenticated state changes | cookie sessions | test |
| C-IN-5 | SSRF defenses: an allow-list for outbound URLs; block private, loopback and link-local ranges; resolve-then-pin the IP (DNS rebinding); re-validate redirects | fetching user-supplied URLs | test |
| C-IN-7 | No mass assignment: allow-listed writable fields per operation; responses expose only contract fields | APIs | contract tests |
| C-IN-8 | XML parsers with external entities and DTDs disabled; no deserialization of untrusted data into objects | XML or serialized input | review + test |
| C-IN-6 | File uploads: type sniffing, size limits, storage outside the web root, randomized names, malware scan if needed | uploads | test |
| **Secrets and crypto** ||||
| C-SEC-1 | Secrets only in a secret store or CI secrets, referenced by name; never in the repo or logs | always | secret scan (hook + CI) |
| C-SEC-2 | TLS everywhere; HSTS on web | always | config review |
| C-SEC-3 | Encryption at rest for databases, backups and object storage | personal or payment data | platform config |
| C-SEC-4 | Rotation plan for keys and credentials; separate credentials per environment | always | DEVOPS-PLAN review |
| **Abuse and availability** ||||
| C-RATE-1 | Rate limits on auth, reset, OTP, search and expensive operations (per IP + account) | public endpoints | test |
| C-RATE-2 | Pagination caps, request size limits, timeouts | APIs | contract + config |
| **Logging and monitoring** ||||
| C-LOG-1 | Structured logs without secrets or PII; a request id for correlation | always | review |
| C-LOG-2 | Audit trail for security events (login, permission change, export, delete) | sensitive data or admin | test |
| C-LOG-3 | Alerts on auth anomalies and error spikes | production | DEVOPS-PLAN |
| **Supply chain** ||||
| C-SUP-1 | Lockfiles committed; dependency audit in CI; no critical/high vulnerabilities without an accepted exception | always | CI job |
| C-SUP-2 | Pinned CI actions/images (by digest/SHA); least-privilege CI tokens (OIDC) | CI/CD | devops review |
| **Privacy** ||||
| C-PRIV-1 | Data minimization; a retention period and deletion path per personal-data column | personal data | ARCHITECTURE §7 review |
| C-PRIV-2 | Data-subject export and deletion | when privacy law applies | e2e |
| C-PRIV-3 | Security headers (HSTS, CSP, frame-ancestors, nosniff, referrer-policy, permissions-policy, COOP/CORP) | web | header test |
| **DevSecOps** ||||
| C-DSO-1 | CI security stages: secrets, SAST, SCA + SBOM, container and IaC scans, DAST baseline on staging (security-audit → DEVSECOPS_PIPELINE.md) | always | CI evidence |
| C-DSO-2 | Release provenance/signing; production promotes only artifacts with green security stages | production releases | release review |
| C-DSO-3 | Incident response playbook with breach notification steps | production | OPERATIONS-HANDOFF |

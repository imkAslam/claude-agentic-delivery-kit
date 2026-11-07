# OWASP checklists

## 1. OWASP Top 10:2021 (web)
| Id | Category | Check |
|---|---|---|
| A01 | Broken Access Control | Object-level checks on every read/update/delete (IDOR), including privileged SDK and service paths; deny by default; no forced browsing to admin routes; CORS restricted; JWT/session tampering rejected; shared/global resources writable only by authorized roles |
| A02 | Cryptographic Failures | TLS everywhere + HSTS; no sensitive data in URLs; encryption at rest for personal/sensitive data; strong password hashing; no weak or custom crypto; keys in a KMS or secret store |
| A03 | Injection | Parameterized SQL/NoSQL; no shell, template or LDAP injection; output encoding (XSS lives here in 2021) |
| A04 | Insecure Design | Abuse cases per feature; rate limits; business-logic limits (quantities, workflows); threat model exists and its controls are implemented |
| A05 | Security Misconfiguration | Security headers; no default credentials; no debug or stack traces; minimal services and ports; XML parsers with external entities disabled (XXE was a separate 2017 category) |
| A06 | Vulnerable and Outdated Components | SCA clean or with accepted exceptions; SBOM produced; base images current |
| A07 | Identification and Authentication Failures | Brute-force protection; MFA/passkeys where required; session rotation and expiry; secure recovery flows; no enumeration |
| A08 | Software and Data Integrity Failures | No unsafe deserialization of untrusted data (a separate 2017 category); signed or pinned CI dependencies and artifacts; integrity of updates and webhooks (signature verification) |
| A09 | Security Logging and Monitoring Failures | Security events logged with request ids; alerting on anomalies; logs free of secrets and PII |
| A10 | Server-Side Request Forgery | URL allow-lists; block private, loopback and link-local ranges; resolve-then-pin DNS (rebinding); no blind redirects |

**Mapping from the 2017 list:** Sensitive Data Exposure → A02 · XXE → A05 · XSS → A03 · Insecure Deserialization → A08 · Broken Authentication → A07 · Insufficient Logging → A09.

## 2. OWASP API Security Top 10:2023
| Id | Risk | Check |
|---|---|---|
| API1 | Broken Object Level Authorization | Every id in a path, query or body is checked against the caller's ownership or tenancy |
| API2 | Broken Authentication | Token validation (alg, iss, aud, exp), key rotation, no tokens in URLs, rate-limited auth |
| API3 | Broken Object Property Level Authorization | No mass assignment (allow-listed writable fields); responses don't over-expose fields |
| API4 | Unrestricted Resource Consumption | Pagination caps, request size limits, timeouts, rate limits, GraphQL depth and cost limits |
| API5 | Broken Function Level Authorization | Admin or privileged operations need explicit roles; no hidden-but-callable endpoints |
| API6 | Unrestricted Access to Sensitive Business Flows | Anti-automation on purchase, signup and referral flows (limits, step-up verification) |
| API7 | Server-Side Request Forgery | As A10 |
| API8 | Security Misconfiguration | CORS, headers, verbose errors, unused HTTP methods disabled |
| API9 | Improper Inventory Management | Every exposed endpoint is in the contract; old versions retired; no shadow or debug APIs in staging or production |
| API10 | Unsafe Consumption of APIs | Validate and time-bound third-party responses; TLS; don't trust upstream data blindly |

## 3. ASVS levels (choose them in the threat model)
| Level | Use for | Typical verification |
|---|---|---|
| L1 | Low-risk apps, MVPs without sensitive data | Automated plus checklist review |
| L2 | **Most business apps**: personal data, payments through a provider, B2B SaaS | L1 + manual review of auth, access control, data protection |
| L3 | High assurance: health, finance, critical infrastructure | L2 + in-depth design review and testing |

## 4. Adversarial prompts (per feature)
- Can a user read or **modify another user's, or a global/shared, resource** by changing an id, a slug or a tenant header?
- Does any code path use a **privileged client** (admin SDK, service role, background job) on behalf of a user without re-checking ownership?
- Can the steps of a workflow be skipped, replayed or reordered (pay → ship, approve → edit)?
- What happens with negative, zero, huge or concurrent values (double spend, double submit)?
- Can this endpoint be used to enumerate users, emails, ids or coupon codes?
- Can uploaded content execute, or be served from our origin (stored XSS, HTML/SVG uploads)?
- Can this feature be used to make the server call arbitrary URLs (webhooks, imports, previews)?
- What's the most damaging thing an authenticated low-privilege user could do here?
- Is the middleware or guard actually applied to this route (matcher, export, naming)?

## 5. Security headers baseline (web)
`Strict-Transport-Security: max-age=31536000; includeSubDomains` · `Content-Security-Policy` (default-src 'self'; script-src without unsafe-inline where possible; frame-ancestors 'none' or the explicit list) · `X-Content-Type-Options: nosniff` · `Referrer-Policy: strict-origin-when-cross-origin` · `Permissions-Policy` (disable unused features) · `Cross-Origin-Opener-Policy: same-origin` · `Cross-Origin-Resource-Policy: same-site` (where compatible) · cookies `Secure; HttpOnly; SameSite=Lax|Strict`.

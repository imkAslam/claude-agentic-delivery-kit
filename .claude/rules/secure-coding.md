---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
  - "**/*.py"
  - "**/*.go"
  - "**/*.java"
  - "**/*.kt"
  - "**/*.cs"
  - "**/*.rb"
  - "**/*.php"
  - "**/*.rs"
  - "**/*.swift"
  - "**/*.dart"
  - "**/*.vue"
  - "**/*.svelte"
---

# Secure coding standards

Full catalog and checklists: the `threat-model` skill (`CONTROLS_CATALOG.md`) and the `security-audit` skill (`OWASP_CHECKLISTS.md`).

## Principles
Defense in depth · least privilege · deny by default · never trust input (including from internal services) · fail securely, without leaking information · keep it simple (custom security code is a liability).

## Access control (OWASP A01)
- Every operation runs authentication **and** authorization in the service layer. Middleware is a choke point, not the only check.
- **Object-level checks on every read, update and delete:** verify ownership or tenancy, including when you use privileged SDKs, admin clients or service accounts that bypass database security rules.
- Shared or global resources (settings, catalogs, templates, other users' content) are writable only by explicitly authorized roles.
- Verify that auth middleware actually applies: route matchers, exports and file naming conventions of the framework. Add a test that hits a protected route without credentials.

## Injection and input (A03)
- Parameterized queries only; no string-built SQL, NoSQL, LDAP, shell or template expressions.
- Validate input at the boundary against the contract schema (types, lengths, ranges, enums); reject unknown fields.
- Encode output for its context (HTML, attribute, JS, URL). Never inject raw HTML without a vetted sanitizer.
- Disable XML external entities and DTDs; don't deserialize untrusted data into objects.

## Authentication and sessions (A07)
- Use the vetted auth library or provider. No custom password hashing (memory-hard algorithms only, via the library).
- Session cookies are `HttpOnly; Secure; SameSite`; rotate on login and privilege change. Tokens: validate the signature algorithm, issuer, audience and expiry; keep them short-lived; refresh by rotation.
- Return the same response for an unknown user and a wrong password; rate-limit auth, reset and OTP endpoints.

## Cryptography and secrets (A02)
- TLS everywhere; no custom crypto; use the platform's or a library's authenticated encryption.
- Secrets come from environment variables or the secret store by name, never from code, config files, logs or error messages.

## SSRF and outbound calls (A10)
- Fetch user-supplied URLs only through an allow-list; resolve DNS, block private, loopback and link-local ranges, and pin the resolved IP for the request (DNS rebinding protection). Disable redirects or re-validate each hop.

## Web hardening (A05)
- Security headers: `Content-Security-Policy` (no `unsafe-inline` for scripts where possible), `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `Referrer-Policy`, `Permissions-Policy`, frame-ancestors / `X-Frame-Options`, and `Cross-Origin-Opener-Policy`/`Cross-Origin-Resource-Policy` where they apply.
- CORS lists explicit origins; no credentialed wildcard.
- Errors return the contract's error body. No stack traces, SQL or internal paths in responses.

## Components (A06) and integrity (A08)
- Add dependencies only from maintained sources, with lockfiles committed; no known critical/high CVEs without an accepted exception.
- Verify the integrity of downloaded artifacts; CI actions and images are pinned.

## Logging (A09)
- Log security events (authn failures, authz denials, admin actions, exports) with a request id. Never log secrets, tokens, passwords, full card numbers or unnecessary PII.

## Insecure design (A04)
- Every feature has abuse cases in its tests: enumeration, replay, race conditions (double spend, double submit), negative or overflow values, skipped workflow steps.

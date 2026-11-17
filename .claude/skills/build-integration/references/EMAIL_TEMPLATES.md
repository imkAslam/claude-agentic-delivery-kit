# Transactional email guide

With: [INTEGRATION_PATTERNS.md](INTEGRATION_PATTERNS.md) (ports and adapters, outbox), [RESILIENCE.md](RESILIENCE.md), [PROVIDER_CATALOG.md](PROVIDER_CATALOG.md), `.claude/rules/integrations.md`, `.claude/rules/secure-coding.md`.

## 1. Where email sits
- Email is an outbound integration. A use case asks for a domain action ("send the verification message") through a port. An adapter implements the port for the chosen provider: Resend, SendGrid, Postmark, or SMTP through nodemailer. The architect picks the provider and records it in an ADR.
- Messages the user must receive (verification, password reset, receipts) are written to the outbox in the same transaction as the change that caused them. A worker sends them with retries, backoff with jitter, and a dead-letter queue after a set number of attempts.
- Every message carries an idempotency key, so a retry never sends it twice.

## 2. Templates
- Build templates with React Email (TSX components) or MJML, one template per message type. Props are typed and validated before rendering.
- Responsive layout. Use inline styles or the library's inliner, because mail clients ignore external CSS.
- Every template has preheader text, one clear call to action, and a plain-text alternative.
- The standard set: welcome, password reset (single-use link with expiry), email verification, receipt or invoice, notification, team invitation.
- Marketing messages add an unsubscribe link and honour the recipient's preferences. Consent wording and retention are business items for the client.
- Links are absolute and built from the configured app URL. Never build them from request headers.
- Reset and verification tokens are single-use, short-lived and stored hashed. They never appear in logs.

## 3. Preview and tests
- Preview templates with the library's dev server (for React Email, `email dev`), or capture sent mail with a local SMTP service such as Mailpit from `LOCAL_SERVICES`.
- Test each template by rendering it with sample props and asserting the required text, the links and the plain-text alternative.
- Adapter tests use the provider's sandbox or the local mock, and cover provider errors, timeouts and rate limits.

## 4. Configuration (names only)
- The provider key, the sender address and the reply-to address come from environment variables. List their names in `.env.example` and `project.json → deploy.required_secrets`.
- The sending domain's SPF, DKIM and DMARC records are a bootstrap step for the human, listed in BOOTSTRAP.md.

## 5. Checklist
- [ ] Email goes through a port and an adapter; no provider SDK in domain code.
- [ ] Messages the user must receive use the outbox and an idempotency key.
- [ ] Every template has a preheader, a plain-text alternative and absolute links.
- [ ] Tokens are single-use, short-lived, hashed at rest and kept out of logs.
- [ ] Marketing messages have an unsubscribe link and honour preferences.
- [ ] Template tests render each template and assert its content.
- [ ] Credentials and addresses come from environment variable names.

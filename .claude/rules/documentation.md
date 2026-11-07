---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
  - "**/*.vue"
  - "**/*.svelte"
  - "**/*.py"
  - "**/*.go"
  - "**/*.java"
  - "**/*.kt"
  - "**/*.swift"
  - "**/*.dart"
  - "**/*.rb"
  - "**/*.php"
  - "**/*.cs"
  - "**/*.rs"
  - "**/*.sql"
---

# Documentation in code

- **Comment the why, not the what.** Explain non-obvious intent, constraints, workarounds and gotchas; reference the ADR, business rule (BR-…) or ticket that explains it. Never restate the code.
- Public functions, exported types and API handlers carry doc comments (parameters, return value, errors thrown, an example when the usage isn't obvious), in the stack's standard format (TSDoc, docstrings, GoDoc, KDoc…).
- Document known gotchas where they bite ("must run before hydration: see ADR-003").
- No commented-out code (git keeps history). No `TODO` without a ticket id (`TODO(T-123): …`).
- A significant technical decision made while coding (a new dependency, a pattern, a deviation) needs an ADR (`write-docs` → ADR_GUIDE.md) before the ticket is approved; reviewers check for it.
- Migrations start with a header comment: what changes, why (ticket), the phase (expand / migrate / contract) and how to roll back.

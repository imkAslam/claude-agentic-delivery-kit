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

- **One comment at the top, not many inside.** Each function, method and class starts with one short doc comment: what it does, its parameters and return value, the errors it raises, and the reason when it is not obvious (with the ADR, business rule `BR-…` or ticket). **No line-by-line comments in the body.** A single short note is allowed only on a line whose reason cannot be guessed (a workaround, an ordering constraint). Never restate the code; clear names replace most comments.
- Use the stack's standard format for that top comment (TSDoc, docstrings, GoDoc, KDoc…). Private one-line helpers with clear names need none.
- Document known gotchas where they bite ("must run before hydration: see ADR-003").
- No commented-out code (git keeps history). No `TODO` without a ticket id (`TODO(T-123): …`).
- A **major** decision made while coding (a change to the stack, the architecture style, authentication, or anything expensive to reverse) needs an ADR (`write-docs` → ADR_GUIDE.md) before the ticket is approved. Every other technical choice is one line in `ARCHITECTURE.md`; no ADR.
- Migrations start with a header comment: what changes, why (ticket), the phase (expand / migrate / contract) and how to roll back.

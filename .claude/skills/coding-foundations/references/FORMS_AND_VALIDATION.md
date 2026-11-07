# Forms and input validation (every stack)

With: `secure-coding.md` (validate at the boundary), `api-design.md` (the error model), the stack guides, and the form pattern in `design-inspiration` → COMPONENT_PATTERNS.md.

## 1. Principles (must)
1. **The server is the authority; the client is for UX.** Every rule is enforced on the server. Client validation only gives fast feedback and is never trusted for security or integrity.
2. **One source of truth per rule.** Derive the schema from the contract where codegen supports it (OpenAPI → zod/yup/Pydantic/DTO generators); otherwise write it once in a shared schema package (TypeScript monorepos) or mirror the contract exactly, with a contract test that proves the client and server agree.
3. **The same rules on both sides:** required, types, lengths, ranges, formats, enums and cross-field rules match the contract and the business rules (BR-…). A rule that exists only on the client is a bug.
4. **Parse, don't validate:** the schema turns raw input into typed values (trimmed strings, numbers, dates, enums), and only the parsed value goes on to the API call or the use case.
5. **One form library and one schema library per project**, chosen by the architect, recorded in an ADR and in PROJECT.md (§2). No mixing within one app.
6. **Messages come from the copy deck** (UI-UX.md microcopy, in the brand voice), are specific and actionable ("Enter a postcode like SW1A 1AA", not "Invalid"), and are translatable (i18n keys).

## 2. Library choice per stack (the architect picks one row)
| Stack | Form state | Schema / validation | Notes |
|---|---|---|---|
| **React (default)** | **React Hook Form** | **zod** via `@hookform/resolvers/zod` (or yup via `@hookform/resolvers/yup`) | Uncontrolled inputs, few re-renders; `mode: "onTouched"` gives "validate on blur, then on change" |
| **React (Formik)** | **Formik** | **yup** via `validationSchema` (native), or **zod** via `zod-formik-adapter` (`toFormikValidationSchema`) | Choose when the team knows Formik; check its maintenance status at the `boundaries` step |
| React (alternative) | TanStack Form | zod (Standard Schema) | Type-safe; newer |
| **Next.js** | React Hook Form or Formik on the client | **The same zod schema in the Server Action / Route Handler** (`safeParse` the `FormData`) | Return field errors to the form; works without JavaScript when built on form actions |
| **React Native / Expo** | React Hook Form or Formik | zod or yup (same as web; share the schema package) | Next-field focus, `returnKeyType`, keyboard avoidance |
| **Vue / Nuxt** | VeeValidate | zod (`@vee-validate/zod`, `toTypedSchema`) or yup | |
| **Angular** | Typed **Reactive Forms** | Built-in `Validators` + custom validators (sync and async) | Keep validators in pure functions; reuse them in tests |
| **SvelteKit** | Superforms | zod (or another adapter) | Server-validated form actions, progressive enhancement |
| **Flutter** | `Form` + `TextFormField` validators (or `reactive_forms`) | Validator functions shared per field | |
| **Node (Express/Fastify/Hono)** | — | zod (shared with the frontend) or JSON Schema (Fastify/Ajv) from the contract | Reject unknown fields |
| **NestJS** | — | `class-validator` DTOs + global `ValidationPipe({ whitelist, forbidNonWhitelisted, transform })`, or a zod pipe with the shared schema | |
| **Python** | — | **Pydantic** (FastAPI), DRF serializers, or Django forms | `extra="forbid"` on request models |
| **Go** | — | `go-playground/validator` struct tags + explicit checks for cross-field rules | |
| **Java/Kotlin Spring** | — | Jakarta **Bean Validation** (`@Valid`, `@NotBlank`, `@Size`, custom constraints) | |
| **.NET** | — | **FluentValidation** or DataAnnotations + `[ApiController]` automatic 400 | |

## 3. Examples (adapt to the pinned versions)
**React Hook Form + zod**
```tsx
const SignupSchema = z.object({
  email: z.string().trim().toLowerCase().email(),         // messages via i18n keys in real code
  password: z.string().min(12).max(128),
  confirm: z.string(),
}).refine(v => v.password === v.confirm, { path: ["confirm"], message: "auth.passwordMismatch" });
type Signup = z.infer<typeof SignupSchema>;

const { register, handleSubmit, setError, setFocus, formState: { errors, isSubmitting } } =
  useForm<Signup>({ resolver: zodResolver(SignupSchema), mode: "onTouched" });

const onSubmit = handleSubmit(async values => {
  const res = await api.signup(values);                    // generated client
  if (res.error?.code === "validation_failed")
    res.error.details.forEach(d => setError(d.field as keyof Signup, { message: d.message }));
});
```
**Formik + yup**
```tsx
const SignupSchema = yup.object({
  email: yup.string().trim().lowercase().email().required(),
  password: yup.string().min(12).max(128).required(),
  confirm: yup.string().oneOf([yup.ref("password")], "auth.passwordMismatch").required(),
});
<Formik initialValues={{ email: "", password: "", confirm: "" }} validationSchema={SignupSchema}
  onSubmit={async (values, { setFieldError }) => {
    const res = await api.signup(values);
    res.error?.details?.forEach(d => setFieldError(d.field, d.message));
  }}>…</Formik>
```
**Formik + zod:** `validationSchema={toFormikValidationSchema(SignupSchema)}` (`zod-formik-adapter`).
**Server (Next.js Server Action or a Node handler):** `const parsed = SignupSchema.safeParse(input); if (!parsed.success) return fieldErrors(parsed.error);`, with the same schema object and the contract's error body.

## 4. Field rules that bite (must)
| Field | Rule |
|---|---|
| All text | Trim; enforce max length on both sides (and in the database); normalize Unicode where identity matters |
| Email | Syntax check only + a verification email; lowercase for lookups only if the data model says so; never reveal whether an account exists |
| Password | NIST SP 800-63B: length-based (minimum from the threat model, at least 8), allow at least 64 characters and paste, no composition rules, block common and breached passwords server-side, show/hide toggle |
| Phone | Parse to E.164 with a phone library; store E.164 |
| OTP / codes | Exact length and digits; `autocomplete="one-time-code"`; rate-limited and expiring on the server |
| Numbers and money | Locale-aware input, parsed to number/minor units; ranges from BR-; no floats for money |
| Dates and times | Parsed with the user's time zone, stored in UTC; min/max and cross-field order (start before end) |
| URLs | Scheme allow-list (`https:`); no `javascript:`; server-side SSRF rules for anything fetched |
| Files | Type checked by content on the server (not just the extension), size limits on both sides, virus/malware scan if the threat model requires, stored outside the web root |
| Free text / rich text | Length limit; sanitize rich text on the server with an allow-list; encode on output |
| Unique values (username, slug) | Async check is a hint only (debounced, cancelled on change); the database UNIQUE constraint decides, and the 409 maps to the field |

## 5. UX and accessibility (must)
- Validate on blur, then on change for touched fields; validate everything on submit; on failure, **focus the first invalid field**, and for long forms show an **error summary** at the top linking to each field.
- Each input has a visible `<label>`; errors are linked with `aria-describedby` and the field gets `aria-invalid="true"`; the summary uses `role="alert"` (or a live region); don't rely on color alone.
- Mark required (or optional) fields consistently; use the right `type`, `inputmode` and `autocomplete` attributes.
- Keep the user's input on error; disable submit only while submitting; prevent double submits; send an `Idempotency-Key` on creates the contract marks idempotent.
- Warn about unsaved changes on navigation for long forms; multi-step forms validate each step and the whole payload on the final submit.

## 6. Server errors → the form
Map the contract's `validation_failed.details[] {field, code, message}` to field errors (`setError` / `setFieldError`); unknown fields or other errors become a form-level error; 409 conflicts map to the conflicting field. Never show raw server messages that leak internals.

## 7. Testing
- **Schema unit tests:** a table of valid and invalid inputs per rule, including boundaries (min-1, min, max, max+1) and cross-field rules, for the shared schema and for the server validator.
- **Component tests:** errors appear on blur and submit, focus moves to the first invalid field, `aria-invalid`/`aria-describedby` are set, server field errors display.
- **Backend tests:** every rule rejected with the contract error body; unknown fields rejected.
- **E2E:** the critical forms (signup, checkout, …) happy path + one invalid path. Each test names its AC/TC.

## 8. Review checklist
- [ ] One form library and one schema library, as recorded in PROJECT.md.
- [ ] Schema derived from the contract or shared; client and server rules identical; server enforces all of them.
- [ ] Parsed (typed, trimmed) values are submitted, not raw input.
- [ ] Messages from the copy deck/i18n; specific and actionable.
- [ ] Blur/submit timing, first-invalid focus, error summary for long forms, `aria-invalid` + `aria-describedby`, labels.
- [ ] Server validation errors mapped to fields; no double submit.
- [ ] Field rules in §4 respected (passwords, files, phone, dates, money, unique values).
- [ ] Schema tests with boundary values; component and backend tests for the rules.

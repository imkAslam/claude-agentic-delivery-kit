# Auth screens: sign up, sign in, code, recovery

The sign-in and sign-up screens are the product's **first impression** and the moment people decide whether to trust it. They get the brand's full expression, a real layout and every state. A bare form at the top-left of an empty page passes the accessibility checks and still fails this guide.

## 1. Layout
**Desktop (≥ 1024 px): split screen.**
```
┌──────────────────────────────┬─────────────────────────────────┐
│ BRAND PANEL (40–50%)         │            FORM SIDE            │
│ name / logo                  │   ┌─────────────────────────┐   │
│                              │   │ H1 (one task)           │   │
│ One promise, 1–2 lines       │   │ one line: what happens  │   │
│ 3 reassurance points (icon + │   │ [ field              ]  │   │
│   short line)                │   │ [  Primary action    ]  │   │
│ a brand visual: shapes in    │   │ secondary link          │   │
│   brand tints, an app        │   │ trust line (privacy)    │   │
│   preview, or a quote        │   └─────────────────────────┘   │
│                              │    legal links, small, bottom   │
└──────────────────────────────┴─────────────────────────────────┘
```
- The **form card** is 400–440 px wide, centred vertically and horizontally on its side, with 32–40 px padding, on the surface color with a hairline border or the style's card treatment.
- The **brand panel** uses the light secondary tint or a soft brand gradient in the light theme (never a full dark panel in light, COLOR_METHOD §4), the brand's shapes or an illustration, and real words, not lorem.
- **Tablet (640–1023 px):** the brand panel becomes a band above the card (promise + one reassurance line).
- **Mobile (< 640 px):** a short branded header (name, one-line promise, brand tint or shape), then the form full width with 16–24 px gutters; the primary button within thumb reach; no brand panel content below the fold that the user must scroll past.

## 2. What every auth screen has
| Element | Rule |
|---|---|
| H1 | One task in plain words: "Sign in", "Create your account", "Check your email" |
| Subline | What happens next, one line ("We'll email you a 6-digit code. No password to remember.") |
| Fields | Only what is needed now (DESIGN_GUIDELINES: Parkinson's law). Labels above, `autocomplete` set (`email`, `one-time-code`), `inputmode` for codes |
| Primary action | One, full card width, the Primary button spec (COMPONENTS_FORMS) |
| Secondary path | One link under the button: "New here? Create an account" / "Already have an account? Sign in" |
| Reassurance | A short trust line near the action, with an icon: privacy ("Your answers stay private"), security ("No password; a one-time code"), cost ("Free plan, no card"): only true statements from the PRD |
| Legal | Terms and privacy links, small, at the bottom of the card or page; consent checkboxes only where the PRD requires them, grouped under one heading |
| Brand | The name or logo on every auth screen; the brand panel or header carries the promise |
| Safety controls | Product-specific controls the PRD requires (e.g. Quick exit, language switch) stay visible but quiet, top right |

## 3. The flow and its screens
Design every screen and state the chosen method needs, not only the form:
- **Email code (passwordless):** enter email → "Check your email" (shows the address, "Change email", where to look, resend with a countdown) → enter code (one field with `autocomplete="one-time-code"` or 6 boxes that accept paste; auto-submit on the last digit) → success or straight into the app.
- **Password:** sign in (show/hide toggle, "Forgot password?"), sign up (rules shown before typing, met rules ticked live), reset request → "Check your email" → new password → success.
- **Social or passkey sign-in** (only if in scope): provider buttons above the form with an "or" divider; never the only way in.
- **States for each screen:** default, filled, loading (button spinner, no double submit), field error, form error summary (several errors), code wrong / expired / too many tries (with the wait time), rate-limited, offline, signed out after inactivity (an info alert saying why), invite or pilot entry (one line of context above the H1).

## 4. Feel
- **Calm and certain.** One action per screen, generous space, the brand's warmth. Errors say what to do and keep what was typed.
- **Fast.** No unnecessary steps; remember the email between sign-in screens; the code screen focuses the field on load.
- **Accessible.** Focus starts on the first field, the error summary receives focus, the countdown is announced politely, nothing depends on color alone.

## 5. Review (the design-reviewer scores each auth screen with UI_QUALITY_BAR)
Fail as P2 when any of these is true: a bare form on an empty page (no card, no brand panel or header); no reassurance line; a missing "check your email" or code-error state; more than one primary action; the light theme dominated by a dark panel.

# Brand discovery

## 1. Evidence to collect (from intake, references and research; ask nothing technical)
| Item | Where it usually comes from | Default if missing (label `ASSUMPTION:`) |
|---|---|---|
| Product name | Intake | The working name from the brief; the final name is a client decision |
| Existing logo, colors, fonts, guidelines | `docs/intake/**`, `design-references/` | Case C (no brand) |
| Audience and context of use | BA personas, PRD §2 | The primary persona, on the device the PRD names |
| What the client likes / dislikes | Meeting notes, reference images | Neutral, professional, calm |
| Comparable products | RESEARCH.md | The 5 products the researcher compared |
| Market and locales | Intake, PRD | One locale, the client's language |
| Constraints | Intake | WCAG 2.2 AA, open-license fonts, light theme only |

## 2. Brand foundation (write it in BRAND-DIRECTIONS §1, then BRAND-BRIEF §1)
- **Purpose:** one sentence, the change the product makes for its users.
- **Audience:** the primary and secondary personas, and what they need to feel (confident, safe, fast, delighted…).
- **Personality:** 3–5 traits, each with **is / is not** (e.g. *Clear: is direct and plain, is not curt or technical*).
- **Positioning:** "For <audience> who <need>, <product> is the <category> that <benefit>, unlike <alternative>."
- **Differentiation:** what the visual landscape of the comparable products looks like, and where this brand sits.

## 3. Personality sliders (1–5; mark each direction on them)
| Left (1) | Right (5) |
|---|---|
| Classic | Modern |
| Serious | Playful |
| Calm | Energetic |
| Minimal | Rich |
| Corporate | Personal |
| Utilitarian | Expressive |
| Mass-market | Premium |
The safe direction stays within ±1 of the client's references; the bold one moves at least 2 steps on two sliders.

## 4. Competitor visual landscape (from RESEARCH.md; patterns, not copies)
| Product | Dominant colors | Type style | Shape / density | Imagery | Mood words |
|---|---|---|---|---|---|
Close with: the **table stakes** (what users of this category expect), the **clichés** to avoid, and the **gap** this brand can own.

## 5. Audit checklist (case A and B)
- [ ] Every brand color tested for text and UI contrast on white and on dark; failing ones get an accessible "text" variant
- [ ] Semantic colors exist (success, warning, danger, info) and don't clash with the brand colors
- [ ] Fonts are licensed for web and app embedding; a fallback stack is defined
- [ ] The logo works at 16 px (favicon), in one color, and on dark backgrounds
- [ ] Interactive states (hover, focus, pressed, disabled) are defined or derivable
- [ ] Gaps are listed with a proposed fix; nothing in the existing brand is changed without saying so

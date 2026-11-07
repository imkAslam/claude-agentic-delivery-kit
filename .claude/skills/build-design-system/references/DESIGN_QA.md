# Design review and design QA

## A. Design review checklist (design-reviewer, Lane 1 directions and Lane 2 designs)
**Severity:** P1 = an accessibility failure (contrast, keyboard, missing label), a journey or AC with no screen, a brand rule broken, a fabricated render · P2 = a missing state, an inconsistent component or token, an unspecified component used in a mockup, a copy-voice violation · P3 = polish.

### Brand directions (before G1)
- [ ] Each direction is distinct (at least 2 sliders apart) and traceable to the foundation and the personas
- [ ] Every palette passes `check-tokens.sh`; the result is shown on each board
- [ ] Fonts have recorded licenses; paid assets are flagged as business decisions
- [ ] Nothing imitates a competitor's or another company's identity
- [ ] The boards render (real PNGs); the recommendation is justified in business terms

### Designs (before G2)
- [ ] UI-UX: every journey has a flow; every flow screen is in the inventory; every `AC-` maps to a screen and a state
- [ ] The states matrix has no empty cells (a mockup or "n/a" with a reason)
- [ ] Wireframes were reviewed before the hi-fi mockups (or the deviation is explained)
- [ ] BRAND-BRIEF is complete (template sections 1–10), and tokens.json passes `check-tokens.sh` for every theme
- [ ] Mockups use only token values (their `:root` comes from `check-tokens.sh --css`); no raw colors in the markup
- [ ] Every component in the mockups is specified in DESIGN-SYSTEM.md, with all its states
- [ ] Copy follows the voice and the word list; product terms match the BA glossary; legal/marketing copy is marked `CLIENT COPY`
- [ ] Accessibility: contrast, visible focus, target sizes, labels, headings and landmarks, no color-only meaning, 320 px reflow
- [ ] Desktop and mobile renders exist for every screen state; the asset kit exists (logo set, favicon, app icons if mobile, social image)

## B. Milestone design QA (uiux-agent, before `mbr:<ms>`)
1. Take the integrator's screenshots (`milestones/<ms>/evidence/`) of every screen and state the milestone delivered, at the mockup sizes (1440×900 and 390×844); add missing ones with `render-png.sh` against the running app or Playwright.
2. Compare each one with its approved mockup: layout and spacing, typography, color and tokens, component variants and states, copy, icons, responsive behavior, focus states.
3. Grep the UI paths for raw color literals and hardcoded sizes that tokens cover (e.g. `#[0-9a-fA-F]{3,8}\b`, `rgb(`) outside the generated theme files.
4. Run an automated accessibility scan if one is available (axe through Playwright) and note what was and wasn't checked.
5. Write `docs/delivery/milestones/<ms>/DESIGN-QA.md`. P1/P2 findings go to triage (UI → frontend or mobile); P3 are listed.

### DESIGN-QA.md template
```markdown
> Milestone: <ms> · Owner: uiux-agent · Candidate: <integration commit> · Updated: <ISO>
# Design QA: <ms>
| Screen · state | Mockup | Built (screenshot) | Verdict | Findings |
|---|---|---|---|---|
| S-03 · empty | mockups/S-03-…-empty.png | evidence/S-03-empty.png | match / minor / mismatch | [P2] spacing above the empty-state action is 8 px, mockup 24 px (space-6) |
**Token audit:** <n> raw literals found (file:line) · **Accessibility scan:** <tool, result, or "not available"> · **Verdict:** PASS / FIX (P1/P2 present)
```

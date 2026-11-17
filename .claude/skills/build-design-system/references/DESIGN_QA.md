# Design review and design QA

## A. Design review checklist (design-reviewer, Lane 1 directions and Lane 2 designs)
**Severity:** P1 = an accessibility failure (contrast, keyboard, missing label), a journey or AC with no screen, a brand rule broken, a fabricated render · P2 = a missing state, an inconsistent component or token, an unspecified component used in a mockup, a copy-voice violation · P3 = polish.

### Brand directions (before G1)
- [ ] Each direction is distinct (at least 2 sliders apart) and traceable to the foundation and the personas
- [ ] Every palette passes `check-tokens.sh` (contrast and distinctness); the result is shown on each board and every warning is explained
- [ ] Each direction states its color rationale (COLOR_METHOD §2–§3) and its 60/30/10 split; the key screen visibly follows it (the accent never dominates)
- [ ] Fonts have recorded licenses; paid assets are flagged as business decisions
- [ ] Nothing imitates a competitor's or another company's identity
- [ ] Design research is recorded with real, cited sources (or marked "not performed"); each direction names the patterns it takes; no third-party images or fonts were copied into the repo
- [ ] The boards render (real PNGs); the recommendation is justified in business terms

### Designs (before G2)
- [ ] DESIGN.md › UX: every journey has a flow; every flow screen is in the inventory; every `AC-` maps to a screen and a state
- [ ] The states matrix has no empty cells (a mockup or "n/a" with a reason)
- [ ] Wireframes were reviewed before the hi-fi mockups (or the deviation is explained)
- [ ] DESIGN.md › Brand is complete (template sections 1–10), and tokens.json passes `check-tokens.sh` for every theme
- [ ] Mockups use only token values (their `:root` comes from `check-tokens.sh --css`); no raw colors in the markup
- [ ] Every component in the mockups is specified in DESIGN.md › Components, with all its states
- [ ] Copy follows the voice and the word list; product terms match the BA glossary; legal/marketing copy is marked `CLIENT COPY`
- [ ] Accessibility: contrast, visible focus, target sizes, labels, headings and landmarks, no color-only meaning, 320 px reflow
- [ ] Desktop and mobile renders exist for every screen state; the asset kit exists (logo set, favicon, app icons if mobile, social image)
- [ ] Every component and key screen passes `UI_QUALITY_BAR.md` (score recorded); each component follows its `COMPONENTS_*.md` entry and names its references
- [ ] Every mockup keeps the 60-30-10 split (dominant / secondary / accent); status colors never appear as decoration
- [ ] If `F-LANDING`: the landing mockups follow LANDING_PAGE.md §1–§4 (section sources, only released features, `CLIENT COPY` marked, no unbacked claims, SEO and social image planned)

## B. Milestone design QA (uiux-agent, before `mbr:<ms>`)
1. Take the integrator's screenshots (`milestones/<ms>/screens/`) of every screen and state the milestone delivered, at the mockup sizes (1440×900 and 390×844); add missing ones with `render-png.sh` against the running app or Playwright.
1a. **Review components on the dev-only gallery page** (`UI_QUALITY_BAR.md` §4): every component the milestone built, in all its states, at desktop and mobile width. Score each with the ten checks and record the scores in `REVIEW.md › Design QA` (one line per component: score, failing checks). One screenshot of each component's gallery section is enough.
2. Compare each one with its approved mockup: layout and spacing, typography, color and tokens (including the 60-30-10 split), component variants and states, copy, icons, responsive behavior, focus states.
3. Grep the UI paths for raw color literals and hardcoded sizes that tokens cover (e.g. `#[0-9a-fA-F]{3,8}\b`, `rgb(`) outside the generated theme files.
4. Run an automated accessibility scan if one is available (axe through Playwright) and note what was and wasn't checked.
5. Write `docs/delivery/milestones/<ms>/REVIEW.md › Design QA`. P1/P2 findings go to triage (UI → frontend or mobile); P3 are listed.

### REVIEW.md › Design QA template
```markdown
> Milestone: <ms> · Owner: uiux-agent · Candidate: <integration commit> · Updated: <ISO>
# Design QA: <ms>
| Screen · state | Mockup | Built (screenshot) | Verdict | Findings |
|---|---|---|---|---|
| S-03 · empty | mockups/S-03-…-empty.png | evidence/S-03-empty.png | match / minor / mismatch | [P2] spacing above the empty-state action is 8 px, mockup 24 px (space-6) |
**Token audit:** <n> raw literals found (file:line) · **Accessibility scan:** <tool, result, or "not available"> · **Verdict:** PASS / FIX (P1/P2 present)
```

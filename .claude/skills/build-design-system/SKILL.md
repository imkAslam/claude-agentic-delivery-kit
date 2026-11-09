---
name: build-design-system
description: "Design system toolkit: UX structure (information architecture, user flows, low-fidelity wireframes, screen inventory, states matrix, copy deck in UI-UX.md), design tokens in the W3C DTCG format (primitive → semantic → component tiers, light and dark themes, web and mobile theme mappings), the component specification (DESIGN-SYSTEM.md: anatomy, variants, sizes, states, behavior, accessibility), a token and WCAG contrast checker, a PNG renderer for mockups, and design QA of built screens against the approved mockups."
when_to_use: "Use when writing UI-UX.md, DESIGN-SYSTEM.md or tokens.json, building or rendering mockups, checking contrast, mapping tokens into a web or mobile theme, reviewing designs, or running milestone design QA."
argument-hint: "[structure | tokens | system | mockups | qa]"
---

# Build design system

Turns the approved brand into a buildable system: structure first, then tokens, then components, then high-fidelity mockups. Everything visual traces back to **tokens.json**, and every design claim has a real render behind it.

## When to Use
- **uiux-agent, design mode** (lane `plan`, `design-fork`): UI-UX.md → tokens.json → DESIGN-SYSTEM.md → mockups
- **uiux-agent, design-QA mode** (lane `build`, before `mbr:<ms>`): DESIGN-QA.md
- **design-reviewer:** the checklists in DESIGN_QA.md §A
- **frontend / mobile engineers:** mapping tokens into the theme (DESIGN_TOKENS.md §8) and building components from their specs

## Instructions

### Step 0: Load the inputs
`BRAND-BRIEF.md` (or the chosen direction in `BRAND-DIRECTIONS.md`), `PRD.md` (journeys, AC, NFRs incl. accessibility and locales), `BA-ANALYSIS.md` (personas, permissions, glossary), the contracts (the data each screen shows), ARCHITECTURE (realtime or polling, offline), and the design-inspiration load order.

### Step 1: Structure, low fidelity
Write `docs/delivery/UI-UX.md` §1–§6 with [UX_STRUCTURE.md](references/UX_STRUCTURE.md): principles, IA and sitemap, a flow per journey, text wireframes for the key screens, the inventory and the states matrix. Send it to the **design-reviewer** (through the orchestrator) before building high-fidelity mockups. Fix structural findings first; they are cheap now and expensive later.

### Step 2: Tokens
Write `docs/delivery/tokens.json` (and `tokens.dark.json` if dark mode is in scope) per [DESIGN_TOKENS.md](references/DESIGN_TOKENS.md), using the BRAND-BRIEF values. Then run:
```bash
bash ${CLAUDE_SKILL_DIR}/scripts/check-tokens.sh [--theme docs/delivery/tokens.dark.json] docs/delivery/tokens.json
```
Fix every failure by adjusting the semantic mapping (pick another primitive step), not by lowering the minimum. Paste the result into BRAND-BRIEF §3.

### Step 3: Component specification
Write `docs/delivery/DESIGN-SYSTEM.md` with [DESIGN_SYSTEM_TEMPLATE.md](references/DESIGN_SYSTEM_TEMPLATE.md): the foundations, the inventory of components the screens actually use, one spec per component (anatomy, variants, sizes, states, tokens, behavior, accessibility, content), and the patterns.

### Step 4: High-fidelity mockups
Follow the design-inspiration MOCKUP_TEMPLATE. Generate each mockup's `:root` from `check-tokens.sh --css`, use only the specified components, and cover every cell of the states matrix. Render every file at both sizes:
```bash
bash ${CLAUDE_SKILL_DIR}/scripts/render-png.sh docs/delivery/mockups/S-03-orders-list-default.html docs/delivery/mockups/S-03-orders-list-default.png 1440x900
bash ${CLAUDE_SKILL_DIR}/scripts/render-png.sh docs/delivery/mockups/S-03-orders-list-default.html docs/delivery/mockups/S-03-orders-list-default.mobile.png 390x844
```
Exit 3 means no renderer was available: keep the HTML and report "not rendered". Finish UI-UX.md §7–§10 (behavior, responsive, accessibility, copy deck). Keep the 60-30-10 color split on every screen (define-brand → COLOR_METHOD §4). If the PRD has `F-LANDING`, design the landing page with [LANDING_PAGE.md](references/LANDING_PAGE.md) (every section, both sizes, copy marked `CLIENT COPY (draft)`).

### Step 5: Design review loop
The orchestrator sends the package to the design-reviewer (loop id `design-review`, cap 3). Fix every P1/P2 finding, re-run both scripts, and report what changed.

### Step 6: Milestone design QA (build lane)
Follow [DESIGN_QA.md](references/DESIGN_QA.md) §B and write `milestones/<ms>/DESIGN-QA.md`. Return P1/P2 mismatches as findings for triage (`UI → frontend/mobile`), each with both screenshots.

## Rules
- Tokens, not values. A needed value without a token means the token set is incomplete: add it to tokens.json (before G2) or request it through a change request (after G2).
- Specify before use: a mockup may only show components that DESIGN-SYSTEM.md specifies.
- Accessibility is checked, not assumed: contrast by the script, the rest by the checklist; never claim an untested pass.
- No network in mockups, boards or assets. No fabricated renders.
- After G2, UI-UX.md, tokens, DESIGN-SYSTEM.md and the mockups change only through a change request on g2.

## Integration with Other Skills
- **define-brand:** provides BRAND-BRIEF (the values) and the voice for the copy deck
- **design-inspiration:** the load order and the mockup skeleton
- **create-component / create-screen:** build the specified components with the token theme
- **write-tests:** E2E visual and accessibility checks reuse the screen ids and states
- **review-checklists:** the Design checklist for reviewers

## File Structure
```
.claude/skills/build-design-system/
├── SKILL.md
├── references/
│   ├── UX_STRUCTURE.md            # UI-UX.md: IA, flows, wireframes, inventory, states matrix, copy deck
│   ├── DESIGN_TOKENS.md           # DTCG tokens: tiers, naming, required tokens, contrast pairs, themes, platform mapping, templates
│   ├── DESIGN_SYSTEM_TEMPLATE.md  # DESIGN-SYSTEM.md: foundations, component specs, patterns, governance
│   ├── LANDING_PAGE.md            # opt-in landing page (F-LANDING): section sources, copy, SEO/perf baseline, refresh per release
│   └── DESIGN_QA.md               # design-review checklists + milestone design QA + DESIGN-QA.md template
└── scripts/
    ├── check-tokens.sh            # validates tokens.json, resolves aliases, WCAG contrast + OKLab distinctness (with CVD simulation) per theme, --css export
    └── render-png.sh              # HTML → PNG (Playwright, else installed Chrome/Chromium); exit 3 = not rendered
```

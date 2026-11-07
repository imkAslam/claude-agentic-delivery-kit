---
name: define-brand
description: "Brand identity toolkit: brand discovery (audit an existing brand or define a new one), 2–3 visual brand directions for the client to choose at G1, the full brand guidelines (BRAND-BRIEF.md: foundation, personality, voice and tone, logo usage, color, typography, iconography, imagery, motion, accessibility), and the brand asset kit (logo files, favicon, app icons, social preview images, email header, splash screens)."
when_to_use: "Use when a brand is being defined, audited or extended, when preparing the visual directions for G1, when writing BRAND-BRIEF.md or the voice-and-tone rules, when producing logos, favicons, app icons or social images, or when a UI question depends on a brand rule."
argument-hint: "[discovery | directions | guidelines | assets]"
---

# Define brand

The brand is a **client decision** (`.claude/rules/decision-policy.md`). Agents do the work: they audit what exists, propose well-reasoned directions, and turn the chosen one into precise guidelines and assets. The client chooses, at G1, with a recommended option.

## When to Use
- **uiux-agent, brand mode** (lane `understand`, step `discovery`, round 1): discovery + `BRAND-DIRECTIONS.md` + direction boards → G1
- **uiux-agent, design mode** (lane `plan`, step `design-fork`): `BRAND-BRIEF.md` and the asset kit for the chosen direction → G2
- **design-reviewer:** reviewing directions, guidelines and assets
- **frontend / mobile engineers:** a brand rule decides a UI detail (logo clear space, imagery, copy tone)

## Instructions

### Step 0: Load the inputs
`docs/delivery/Intake-Readiness.md` (brand evidence and agreed decisions), `docs/intake/**`, `docs/delivery/design-references/*` (read every image), `RESEARCH.md` (comparable products), `BA-ANALYSIS.md` (personas), PRD §1–§2 and §5 when they exist, and the INBOX of your brief.

### Step 1: Classify the starting point and run discovery
Follow [BRAND_DISCOVERY.md](references/BRAND_DISCOVERY.md).
| Case | Evidence | What you do |
|---|---|---|
| **A. Full brand** | Guidelines with logo, palette, type, voice | **Audit** for digital use: contrast failures, missing semantic colors, missing states, web/mobile font licensing. One "brand application" board, no directions. |
| **B. Partial brand** | A logo or colors only | Keep what exists, **extend** it: 2 directions that differ in type, shape and density, not in the existing marks. |
| **C. No brand** | Nothing, or only likes/dislikes | **Define** it: 3 directions (A safe, B evolved, C bold). |
Write the brand foundation (purpose, audience, personality traits with "is / is not", personality sliders, the competitor landscape, differentiation, constraints). Missing brand inputs never block the run: use the documented defaults and label them `ASSUMPTION:`.

### Step 2: Visual directions (for G1)
Fill [BRAND_DIRECTIONS_TEMPLATE.md](references/BRAND_DIRECTIONS_TEMPLATE.md) → `docs/delivery/BRAND-DIRECTIONS.md`. For each direction, build one self-contained HTML board in `docs/delivery/brand/directions/<A|B|C>-board.html` (mood words, palette with contrast results, type pairing, shape and density, iconography, imagery, a wordmark proposal, one key screen and a component strip), and render it to PNG at 1440×900 (same render commands as the mockups). Check each palette with `bash .claude/skills/build-design-system/scripts/check-tokens.sh <direction-tokens.json>` and show the result on the board.

### Step 3: Queue the client decision
Queue **one business question** for G1: "Which visual direction?" with the options, one line on what each says about the product, and a **recommended** direction tied to the personas and the goals. Queue client-only items separately (product name, ownership of an existing logo, trademark checks, paid fonts or stock imagery: each is a cost or legal decision). Never ask the client about tokens, scales or component details.

### Step 4: Brand guidelines (lane plan)
For the chosen direction, write `docs/delivery/BRAND-BRIEF.md` with [BRAND_GUIDELINES_TEMPLATE.md](references/BRAND_GUIDELINES_TEMPLATE.md). The values become `docs/delivery/tokens.json` through the **build-design-system** skill (the same agent writes both, so names never drift).

### Step 5: Voice and tone
Apply [VOICE_AND_TONE.md](references/VOICE_AND_TONE.md): the voice traits, the tone per context, the microcopy patterns and the word list go into BRAND-BRIEF §6; the actual strings go into the UI-UX copy deck.

### Step 6: Asset kit
Produce the assets in [BRAND_ASSETS.md](references/BRAND_ASSETS.md) as SVG/HTML sources in `docs/delivery/brand/assets/`, with the export list. The frontend and mobile engineers wire them in during the design-foundation tickets of `ms-1`.

### Step 7: Verify
Every board and asset renders (PNG next to the HTML/SVG); every palette passes `check-tokens.sh`; every font has a recorded license that allows web and app embedding. If rendering fails, keep the source and say so. Never fabricate a PNG.

## Rules
- Never copy or imitate another company's logo, name, distinctive palette or trade dress. Competitors are analyzed for patterns, not reused.
- Fonts: prefer open licenses (SIL OFL, Apache) or system stacks. Store font files with their license in `docs/delivery/brand/fonts/`. A paid font is a business decision for the gate.
- Logos made by agents are **proposals** (typographic wordmarks and simple marks). The client approves the final logo and owns trademark clearance.
- Boards, mockups and assets load nothing from the network; they must render offline.
- After G2, BRAND-BRIEF, tokens and the asset kit change only through a change request on g2.

## Integration with Other Skills
- **build-design-system:** turns BRAND-BRIEF into tokens.json, DESIGN-SYSTEM.md and the mockups; owns the contrast checker
- **design-inspiration:** the load order every UI agent follows (the brand files come first)
- **intake-readiness:** the brand dimension of the readiness score
- **gate-review:** the direction choice is one of the G1 business questions

## File Structure
```
.claude/skills/define-brand/
├── SKILL.md
└── references/
    ├── BRAND_DISCOVERY.md            # cases A/B/C, foundation, personality sliders, landscape, defaults
    ├── BRAND_DIRECTIONS_TEMPLATE.md  # BRAND-DIRECTIONS.md + the direction board skeleton
    ├── BRAND_GUIDELINES_TEMPLATE.md  # BRAND-BRIEF.md (full brand guidelines)
    ├── VOICE_AND_TONE.md             # voice traits, tone by context, microcopy patterns, word list
    └── BRAND_ASSETS.md               # logo set, favicon, app icons, social images, email, splash: sizes and formats
```

---
name: define-brand
description: "Brand identity toolkit: brand discovery (audit an existing brand or define a new one), 2–3 visual brand directions for the client to choose at G1, the full brand guidelines (DESIGN.md › Brand: foundation, personality, voice and tone, logo usage, color, typography, iconography, imagery, motion, accessibility), and the brand asset kit (logo files, favicon, app icons, social preview images, email header, splash screens)."
when_to_use: "Use when a brand is being defined, audited or extended, when preparing the visual directions for G1, when writing DESIGN.md › Brand or the voice-and-tone rules, when producing logos, favicons, app icons or social images, or when a UI question depends on a brand rule."
argument-hint: "[discovery | directions | guidelines | assets]"
---

# Define brand

The brand is a **client decision** (`.claude/rules/decision-policy.md`). Agents do the work: they audit what exists, propose well-reasoned directions, and turn the chosen one into precise guidelines and assets. The client chooses, at G1, with a recommended option.

## When to Use
- **uiux-agent, brand mode** (lane `understand`, step `discovery`, round 1): discovery + `DESIGN.md › Directions` + direction boards → G1
- **uiux-agent, design mode** (lane `plan`, step `design-fork`): `DESIGN.md › Brand` and the asset kit for the chosen direction → G2
- **design-reviewer:** reviewing directions, guidelines and assets
- **frontend / mobile engineers:** a brand rule decides a UI detail (logo clear space, imagery, copy tone)

## Instructions

### Step 0: Load the inputs
`docs/delivery/Intake-Readiness.md` (brand evidence and agreed decisions), `docs/intake/**`, `docs/delivery/design-references/*` (read every image), `PRD.md › Research notes` (comparable products), `PRD.md › Analysis` (personas), PRD §1–§2 and §5 when they exist, and the INBOX of your brief.

### Step 1: Classify the starting point and run discovery
Follow [BRAND_DISCOVERY.md](references/BRAND_DISCOVERY.md).
| Case | Evidence | What you do |
|---|---|---|
| **A. Full brand** | Guidelines with logo, palette, type, voice | **Audit** for digital use: contrast failures, missing semantic colors, missing states, web/mobile font licensing. One "brand application" board, no directions. |
| **B. Partial brand** | A logo or colors only | Keep what exists, **extend** it: 2 directions that differ in type, shape and density, not in the existing marks. |
| **C. No brand** | Nothing, or only likes/dislikes | **Define** it: 3 directions (A safe, B evolved, C bold). |
Write the brand foundation (purpose, audience, personality traits with "is / is not", personality sliders, the competitor landscape, differentiation, constraints). Missing brand inputs never block the run: use the documented defaults and label them `ASSUMPTION:`.

### Step 1a: Design research
Follow [DESIGN_RESEARCH.md](references/DESIGN_RESEARCH.md): 6–10 current references for this domain and these personas from design galleries, palette and type sources (with `WebSearch` / `WebFetch`), recorded with their URLs in DESIGN.md › Directions §1a: the trends seen, the table stakes and clichés, and the patterns each direction takes. Patterns, never copies; with no web access, say "not performed" and continue.

### Step 2: Visual directions (for G1)
Fill [BRAND_DIRECTIONS_TEMPLATE.md](references/BRAND_DIRECTIONS_TEMPLATE.md) → `docs/delivery/DESIGN.md › Directions`. For each direction, build one self-contained HTML board in `docs/delivery/brand/directions/<A|B|C>-board.html` (mood words, palette with contrast results, type pairing, shape and density, iconography, imagery, **three logo concepts researched and drawn per [LOGO_AND_ICONS.md](references/LOGO_AND_ICONS.md)** at 16–256 px, a static frame of the auth illustration in the direction's style, one key screen and a component strip), and render it to PNG at 1440×900 (same render commands as the mockups). Give each direction a **different visual style** from [VISUAL_STYLES.md](references/VISUAL_STYLES.md) (Minimalism, Lightweight, Glassmorphism, Liquid glass, Neumorphism, Spatial UI, or a style the client names), chosen for the product and the personas, and apply its guardrails. Choose each palette with [COLOR_METHOD.md](references/COLOR_METHOD.md): hue from the domain meaning, personas and competitor gap; status hues reserved; the **60-30-10** split (60% dominant, 30% secondary, 10% accent); OKLCH scales; the rationale recorded. **Every direction has a light and a dark palette**; check both with `bash .claude/skills/build-design-system/scripts/check-tokens.sh --theme <direction-dark.json> <direction-tokens.json>` (contrast + distinctness) and show the result on the board.

### Step 3: Queue the client decision
Queue **one business question** for G1: "Which visual direction?" with the options, one line on what each says about the product, and a **recommended** direction tied to the personas and the goals. Queue client-only items separately (product name, ownership of an existing logo, trademark checks, paid fonts or stock imagery: each is a cost or legal decision). When SYSTEM-PROFILE lists an image or video generation tool, also queue "Generated or drawn images for the landing page and sign-in?" with the cost and licence of each (build-design-system → ILLUSTRATIONS_AND_ANIMATION §4); the recommended default is drawn. Never ask the client about tokens, scales or component details.

### Step 4: Brand guidelines (lane plan)
For the chosen direction, write `docs/delivery/DESIGN.md › Brand` with [BRAND_GUIDELINES_TEMPLATE.md](references/BRAND_GUIDELINES_TEMPLATE.md). The values become `docs/delivery/tokens.json` through the **build-design-system** skill (the same agent writes both, so names never drift).

### Step 5: Voice and tone
Apply [VOICE_AND_TONE.md](references/VOICE_AND_TONE.md): the voice traits, the tone per context, the microcopy patterns and the word list go into DESIGN.md › Brand §6; the actual strings go into the DESIGN.md › UX copy deck.

### Step 6: Asset kit
Produce the assets in [BRAND_ASSETS.md](references/BRAND_ASSETS.md) as SVG/HTML sources in `docs/delivery/brand/assets/`, with the export list. The logo set and any custom icons follow [LOGO_AND_ICONS.md](references/LOGO_AND_ICONS.md); the illustrations follow build-design-system → ILLUSTRATIONS_AND_ANIMATION.md; `check-assets.sh` passes on the folder. The frontend and mobile engineers wire them in during the design-foundation tickets of `ms-1`.

### Step 7: Verify
Every board and asset renders (PNG next to the HTML/SVG); every palette passes `check-tokens.sh` (contrast and distinctness; warnings explained) and states its color rationale and 60/30/10 split; every font has a recorded license that allows web and app embedding. If rendering fails, keep the source and say so. Never fabricate a PNG.

## Rules
- Never copy or imitate another company's logo, name, distinctive palette or trade dress. Competitors are analyzed for patterns, not reused.
- Colors follow COLOR_METHOD.md: 60-30-10 per screen, brand colors never mistakable for status colors, status never shown by color alone. A client's existing brand color is never changed silently; the status color moves instead.
- Fonts: prefer open licenses (SIL OFL, Apache) or system stacks. Store font files with their license in `docs/delivery/brand/fonts/`. A paid font is a business decision for the gate.
- Logos made by agents are **proposals** (typographic wordmarks and simple marks). The client approves the final logo and owns trademark clearance.
- Boards, mockups and assets load nothing from the network; they must render offline.
- After G2, DESIGN.md › Brand, tokens and the asset kit change only through a change request on g2.

## Integration with Other Skills
- **build-design-system:** turns DESIGN.md › Brand into tokens.json, DESIGN.md › Components and the mockups; owns the contrast checker
- **design-inspiration:** the load order every UI agent follows (the brand files come first)
- **intake-readiness:** the brand dimension of the readiness score
- **gate-review:** the direction choice is one of the G1 business questions

## File Structure
```
.claude/skills/define-brand/
├── SKILL.md
└── references/
    ├── BRAND_DISCOVERY.md            # cases A/B/C, foundation, personality sliders, landscape, defaults
    ├── DESIGN_RESEARCH.md            # where to look for current design, palette and type references; what to record; rules
    ├── BRAND_DIRECTIONS_TEMPLATE.md  # DESIGN.md › Directions + the direction board skeleton
    ├── BRAND_GUIDELINES_TEMPLATE.md  # DESIGN.md › Brand (full brand guidelines)
    ├── COLOR_METHOD.md               # how colors are chosen: hue by meaning + gap, reserved status hues, 60-30-10, OKLCH scales, CVD
    ├── VISUAL_STYLES.md              # the style catalog (minimal, lightweight, glass, liquid glass, neumorphism, spatial) and its guardrails
    ├── VOICE_AND_TONE.md             # voice traits, tone by context, microcopy patterns, word list
    ├── LOGO_AND_ICONS.md             # logo and custom icons: online reference research, construction, SVG hygiene, review
    └── BRAND_ASSETS.md               # logo set, favicon, app icons, social images, email, splash: sizes and formats
```

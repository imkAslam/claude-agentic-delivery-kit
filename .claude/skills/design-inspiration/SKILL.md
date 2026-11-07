---
name: design-inspiration
description: "Visual design reference library and procedure. Loads the project's brand guidelines, design tokens, design system, approved mockups and client-supplied reference images plus the kit's design guidelines and component patterns, then extracts tokens, layout, density, states and interaction cues so UI work matches the agreed look and feel."
when_to_use: "Use before creating or modifying any UI (components, pages, screens, layouts, mockups), and when reviewing UI for design alignment."
---

# Design inspiration

Make every UI artifact match the **agreed** visual language, never generic defaults.

## When to Use
- **uiux-agent:** creating `UI-UX.md`, `BRAND-BRIEF.md` and the mockups (lane plan)
- **frontend-engineer / mobile-engineer:** before writing any UI code
- **frontend-reviewer / mobile-reviewer:** checking that an implementation matches the design
- Any task with visual output: pages, components, modals, forms, empty/error states, emails

## Instructions

### Step 1: Load the design references (in this order)
1. **Project references.** These override the kit's defaults:
   - `docs/delivery/BRAND-BRIEF.md`: the brand guidelines (foundation, logo, color, type, voice and tone, iconography, imagery); before G2, the chosen direction in `BRAND-DIRECTIONS.md`
   - `docs/delivery/tokens.json` (+ `tokens.<theme>.json`): **every visual value**, as DTCG tokens (build-design-system → DESIGN_TOKENS.md)
   - `docs/delivery/DESIGN-SYSTEM.md`: the component specs (variants, sizes, states, tokens, accessibility) and the patterns
   - `docs/delivery/UI-UX.md`: information architecture, flows, wireframes, the screen inventory, the states matrix and the copy deck
   - `docs/delivery/mockups/*.png` and `*.html`: the **approved** visual contract after G2
   - `docs/delivery/design-references/*`: images the client supplied (screenshots, inspiration, an existing brand)
   - The project's theme or token source, if the code exists (e.g. a Tailwind config, CSS custom properties, the component library's theme)
2. **Kit references:** [DESIGN_GUIDELINES.md](references/DESIGN_GUIDELINES.md) for principles, the token system, accessibility and the do's and don'ts; [COMPONENT_PATTERNS.md](references/COMPONENT_PATTERNS.md) for layout and component patterns with every state.
3. Read every image you're given (PNG, JPG, WEBP, SVG) to understand the target visually.

### Step 2: Extract design cues
Record them in your working notes, or in BRAND-BRIEF if you're the uiux-agent:
- **Color:** primary, secondary, accent, neutrals, semantic (success, warning, danger, info), and the contrast pairs
- **Typography:** families, the size scale, weights, line heights, letter-spacing for display text
- **Spacing:** the base unit and the scale, plus density (spacious or compact)
- **Shape:** border radius levels, border usage, elevation and shadows
- **Layout:** the grid, max content width, navigation pattern, card vs. table vs. list density
- **Components:** buttons, inputs, selects, cards, tables, badges, navigation, dialogs, toasts
- **Interaction:** hover, focus and active states, transitions (duration, easing), loading feedback
- **Iconography and imagery:** outlined or filled, stroke width, sizes, illustration style
- **Mood:** minimal, bold, playful, corporate, editorial…

### Step 3: Apply to the work
1. Use **tokens**, never raw values. If a needed token is missing, request it from the uiux-agent (it goes into tokens.json) rather than hardcoding it. Use only components specified in DESIGN-SYSTEM.md.
2. Match the spacing rhythm, density and typography hierarchy of the references.
3. Design and build **every state**: loading, empty, error, success, no-permission, and offline (mobile).
4. Meet WCAG 2.2 AA: contrast ≥ 4.5:1 for text (3:1 for large text and UI parts), a visible focus indicator, targets ≥ 24×24 CSS px (44pt/48dp on mobile), no meaning carried by color alone, and reduced-motion support.
5. Mockups (uiux-agent) follow [MOCKUP_TEMPLATE.md](references/MOCKUP_TEMPLATE.md) and are rendered to PNG at desktop and mobile widths with `build-design-system/scripts/render-png.sh`.
6. Copy follows the voice, the word list and the copy deck (define-brand → VOICE_AND_TONE.md).

### Step 4: Call out deviations
If the implementation must deviate from the references (a technical limit, accessibility, a library constraint), say so explicitly in your report: what changed, why, and the screenshot.

## How to Add References (per project)
- Put client images in `docs/delivery/design-references/` with descriptive names (`dashboard-layout.png`, `brand-colors.png`, `competitor-checkout.png`).
- Brand rules go in `docs/delivery/BRAND-BRIEF.md`, values in `docs/delivery/tokens.json`, components in `docs/delivery/DESIGN-SYSTEM.md` (the uiux-agent owns all three).
- After G2, the brand brief, tokens, design system and mockups change only through a change request on `g2`.
- The kit's `references/` stay generic. Never put project-specific branding there.

## Integration with Other Skills
- **define-brand:** brand discovery, directions, guidelines, voice and assets (produces BRAND-BRIEF)
- **build-design-system:** UI-UX structure, tokens, component specs, mockups, the contrast checker and the renderer
- **create-component / create-screen:** load this skill before generating UI
- **review-checklists:** the frontend and mobile reviewers compare screenshots with the mockups
- **write-tests:** visual and accessibility checks in E2E reuse the same states

## File Structure
```
.claude/skills/design-inspiration/
├── SKILL.md
└── references/
    ├── DESIGN_GUIDELINES.md     # principles, token system, accessibility, do's and don'ts
    ├── COMPONENT_PATTERNS.md    # layouts and components with all states (framework-neutral)
    └── MOCKUP_TEMPLATE.md       # static HTML mockup skeleton + rendering commands
```

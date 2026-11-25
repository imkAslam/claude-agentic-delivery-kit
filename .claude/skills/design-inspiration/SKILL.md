---
name: design-inspiration
description: "Visual design reference library and procedure. Loads the project's brand guidelines, design tokens, design system, approved mockups and client-supplied reference images plus the kit's design guidelines and component patterns, then extracts tokens, layout, density, states and interaction cues so UI work matches the agreed look and feel."
when_to_use: "Use before creating or modifying any UI (components, pages, screens, layouts, mockups), and when reviewing UI for design alignment."
---

# Design inspiration

Make every UI artifact match the **agreed** visual language, never generic defaults.

## When to Use
- **uiux-agent:** creating `DESIGN.md › UX`, `DESIGN.md › Brand` and the mockups (lane plan)
- **frontend-engineer / mobile-engineer:** before writing any UI code
- **frontend-reviewer / mobile-reviewer:** checking that an implementation matches the design
- Any task with visual output: pages, components, modals, forms, empty/error states, emails

## Instructions

### Step 1: Load the design references (in this order)
1. **Project references.** These override the kit's defaults:
   - `docs/delivery/DESIGN.md › Brand`: the brand guidelines (foundation, logo, color, type, voice and tone, iconography, imagery); before G2, the chosen direction in `DESIGN.md › Directions`
   - `docs/delivery/tokens.json` (+ `tokens.<theme>.json`): **every visual value**, as DTCG tokens (build-design-system → DESIGN_TOKENS.md)
   - `docs/delivery/DESIGN.md › Components`: the component specs (variants, sizes, states, tokens, accessibility) and the patterns
   - `docs/delivery/DESIGN.md › UX`: information architecture, flows, wireframes, the screen inventory, the states matrix and the copy deck
   - `docs/delivery/mockups/*.png` and `*.html`: the **approved** visual contract after G2
   - `docs/delivery/design-references/*`: images the client supplied (screenshots, inspiration, an existing brand)
   - The project's theme or token source, if the code exists (e.g. a Tailwind config, CSS custom properties, the component library's theme)
2. **Kit references:** [PAGE_LAYOUTS.md](references/PAGE_LAYOUTS.md) for the page compositions and craft defaults every key screen starts from (built from build-design-system → assets/mockup-kit.css); [DESIGN_GUIDELINES.md](references/DESIGN_GUIDELINES.md) for principles, the token system, accessibility and the do's and don'ts; [COMPONENT_PATTERNS.md](references/COMPONENT_PATTERNS.md) for layout patterns and the index of components; [AUTH_SCREENS.md](references/AUTH_SCREENS.md) whenever the product has sign-up or sign-in; the **component references** for the professional standard of each component (anatomy, sizes, states, behavior, accessibility, what to avoid): [COMPONENTS_FORMS.md](references/COMPONENTS_FORMS.md), [COMPONENTS_DATA.md](references/COMPONENTS_DATA.md), [COMPONENTS_NAVIGATION.md](references/COMPONENTS_NAVIGATION.md), [COMPONENTS_FEEDBACK.md](references/COMPONENTS_FEEDBACK.md) (read only the file for what you are designing or building); [UI_RESOURCES.md](references/UI_RESOURCES.md) for where to look (component systems, real products, principles, accessibility patterns, assets); [UI_QUALITY_BAR.md](references/UI_QUALITY_BAR.md) for the scored definition of "professionally designed"; the chosen direction's visual style and its guardrails in define-brand → [VISUAL_STYLES.md](../define-brand/references/VISUAL_STYLES.md).
3. Read every image you're given (PNG, JPG, WEBP, SVG) to understand the target visually.

### Step 2: Extract design cues
Record them in your working notes, or in DESIGN.md › Brand if you're the uiux-agent:
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
1. Use **tokens**, never raw values. If a needed token is missing, request it from the uiux-agent (it goes into tokens.json) rather than hardcoding it. Use only components specified in DESIGN.md › Components.
2. Match the spacing rhythm, density and typography hierarchy of the references.
3. Design and build **every state**: loading, empty, error, success, no-permission, and offline (mobile).
4. Meet WCAG 2.2 AA: contrast ≥ 4.5:1 for text (3:1 for large text and UI parts), a visible focus indicator, targets ≥ 24×24 CSS px (44pt/48dp on mobile), no meaning carried by color alone, and reduced-motion support.
5. Mockups (uiux-agent) follow [MOCKUP_TEMPLATE.md](references/MOCKUP_TEMPLATE.md) and are rendered to PNG at desktop and mobile widths with `build-design-system/scripts/render-png.sh`.
6. Copy follows the voice, the word list and the copy deck (define-brand → VOICE_AND_TONE.md).

### Step 4: Call out deviations
If the implementation must deviate from the references (a technical limit, accessibility, a library constraint), say so explicitly in your report: what changed, why, and the screenshot.

## How to Add References (per project)
- Put client images in `docs/delivery/design-references/` with descriptive names (`dashboard-layout.png`, `brand-colors.png`, `competitor-checkout.png`).
- Brand rules go in `docs/delivery/DESIGN.md › Brand`, values in `docs/delivery/tokens.json`, components in `docs/delivery/DESIGN.md › Components` (the uiux-agent owns all three).
- After G2, the brand brief, tokens, design system and mockups change only through a change request on `g2`.
- The kit's `references/` stay generic. Never put project-specific branding there.

## Integration with Other Skills
- **define-brand:** brand discovery, directions, guidelines, voice and assets (produces DESIGN.md › Brand)
- **build-design-system:** DESIGN.md › UX structure, tokens, component specs, mockups, the contrast checker and the renderer
- **create-component / create-screen:** load this skill before generating UI
- **review-checklists:** the frontend and mobile reviewers compare screenshots with the mockups
- **write-tests:** visual and accessibility checks in E2E reuse the same states

## File Structure
```
.claude/skills/design-inspiration/
├── SKILL.md
└── references/
    ├── DESIGN_GUIDELINES.md     # principles, token system, accessibility, do's and don'ts
    ├── COMPONENT_PATTERNS.md    # layout patterns + the index of components
    ├── AUTH_SCREENS.md          # sign up / sign in / code / recovery: layout, elements, flow, states, review
    ├── COMPONENTS_FORMS.md      # button, inputs, select, checkbox/radio, switch, date, upload, search, code input, form layout
    ├── COMPONENTS_DATA.md       # table, list, card, stat, badge, avatar, chart, detail view, timeline, pagination, empty state, skeleton
    ├── COMPONENTS_NAVIGATION.md # app shell, sidebar, top bar, tabs, breadcrumbs, menu, dialog, drawer, popover, tooltip, stepper, command palette
    ├── COMPONENTS_FEEDBACK.md   # toast, alert, banner, spinner, progress, error pages, notifications, connection status, onboarding
    ├── UI_RESOURCES.md          # where to look: component systems, real products, principles, accessibility, assets
    ├── UI_QUALITY_BAR.md        # the ten scored checks, the pass mark, the dev-only component gallery
    └── MOCKUP_TEMPLATE.md       # static HTML mockup skeleton + rendering commands
```

---
name: create-component
description: "Creates web UI components and pages adapted to the project's framework (React/Next.js, Vue/Nuxt, Angular, Svelte/SvelteKit, Solid, Astro), component library and styling, using design tokens, the generated API client, every UI state, accessibility and test-first delivery. Reads the stack from project.json and the look from the approved mockups."
when_to_use: "Use when a frontend ticket needs a new or changed component, page, form, table or layout."
---

# Create component

For the **frontend-engineer** in lane `build`. Every component traces to a ticket, its `AC-` ids, a mockup and contract operations.

## When to Use
- New UI components, pages, forms, tables, dialogs or layouts
- Feature components that fetch data, submit forms or subscribe to realtime updates
- UI fixes routed by triage

## Instructions

### Step 0: Detect the stack (don't guess)
1. Read `.claude/project.json`: `stack.frontend`, `stack.languages`, `roles.frontend.paths`, `roles.frontend.commands`, `contracts.codegen_cmd`.
2. Inside the owned paths, detect the component library (e.g. a `components.json` → a copy-in component system; a material, chakra, mantine, antd, vuetify or primevue dependency), the styling (utility CSS, CSS modules, CSS-in-JS, SCSS), and the token source (theme config, CSS custom properties, theme provider).
3. Find the existing conventions: the folder layout (`ui/`, `features/`, `layouts/`), naming, test location, and the story/preview setup. **Follow them over the defaults below.**
4. If anything is ambiguous, report `NEEDS_HUMAN` with the options. Don't pick one silently.

### Step 1: Resolve the inputs from artifacts (subagents don't ask the user)
| Question | Where the answer lives |
|---|---|
| What does it look like, and in which states? | `docs/delivery/mockups/<screen>-*.png`, `UI-UX.md` (load the **design-inspiration** skill) |
| Which colors, spacing and type? | `docs/delivery/tokens.json` → the project's generated theme (build-design-system → DESIGN_TOKENS.md §8). Never raw values |
| Which variants, sizes and states? | The component spec in `DESIGN-SYSTEM.md` |
| Which data, and which errors? | Contract operations in the ticket → the generated client and its types |
| How much data, and how often does it update? | PRD NFRs + the ticket (decides on pagination, virtualization, polling or realtime) |
| Server or client component (SSR frameworks)? | ARCHITECTURE §8 + whether it needs interactivity |
| Which behavior must pass? | The ticket's `AC-` ids → your tests |

### Step 2: Decide the file location
Use the existing structure. If there's none, use: `<frontend-root>/src/components/ui/` (reusable), `…/components/features/<feature>/` (feature), `…/components/layouts/`, and pages/routes per the framework's routing convention. Tests sit next to the component, or in the project's test folder.

### Step 3: Write the tests first (tdd skill)
One test per AC: rendering of each state (loading, empty, error, success, no-permission), the user interactions (with role- and label-based queries), validation messages, calls to the API client (mocked through the generated mocks), and keyboard operation.

### Step 4: Generate the component
Use the matching template in [FRAMEWORK_TEMPLATES.md](references/FRAMEWORK_TEMPLATES.md) and the data and state patterns in [DATA_AND_STATE.md](references/DATA_AND_STATE.md):
- Typed props, with no `any`
- The generated client for every API call, handling each error code the contract defines
- All states from `UI-UX.md`
- Semantic HTML first, ARIA only where it's needed

### Step 5: Apply the tokens
Use the project's semantic tokens (e.g. `bg-primary text-on-primary`, `var(--color-primary)`, `theme.palette.primary`). **Never hardcode hex, rgb or pixel values that have a token.** If a token is missing, report `NEEDS: uiux — token <name> — <use>`.

### Step 6: Accessibility
Labels for every control; visible focus; keyboard support (Tab order, Enter/Space, Esc closes overlays, arrow keys in menus and lists); announced errors (`aria-describedby`, `aria-live`); `aria-busy` while loading; no meaning carried by color alone.

### Step 7: Performance (when the data or update rate calls for it)
More than about 200 rendered rows → virtualize. Frequent updates → memoize, or use fine-grained state. Heavy computation → move it off the main thread. Route-level code splitting for large pages. Size images and lazy-load them.

### Step 8: Verify and capture evidence
Run the role's `lint`, `typecheck` and `test`. Start `commands.dev`, open the screen, and save a screenshot of each state to `docs/delivery/evidence/<ticket>/`, so the reviewer can compare them with the mockups.

## Integration with Other Skills
- **design-inspiration:** always load it before UI work
- **tdd:** the red → green → refactor loop and its evidence
- **role-boundaries:** if you need a contract, dependency or token change
- **review-checklists:** what the frontend-reviewer will check

## File Structure
```
.claude/skills/create-component/
├── SKILL.md
└── references/
    ├── FRAMEWORK_TEMPLATES.md   # React/Next, Vue/Nuxt, Angular, Svelte, Solid, Astro + test skeletons
    └── DATA_AND_STATE.md        # data fetching, forms, state, realtime, error mapping per framework
```

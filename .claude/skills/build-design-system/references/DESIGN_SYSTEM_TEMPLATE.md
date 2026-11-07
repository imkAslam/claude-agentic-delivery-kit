# DESIGN-SYSTEM.md template (G2)

The design system turns the brand into **reusable, specified components**. Engineers build from it; reviewers check against it.

```markdown
> Status: in-review · Owner: uiux-agent · Tokens: docs/delivery/tokens.json (+ tokens.dark.json) · Brand: BRAND-BRIEF.md · Updated: <ISO>

# Design system

## 1. Foundations
- Tokens: the tiers and naming (DESIGN_TOKENS.md), the themes in scope, and the `check-tokens.sh` result
- Layout: the grid (columns, gutters, margins per breakpoint), the max content width, the spacing rhythm
- Typography scale and usage; color usage (BRAND-BRIEF §3); elevation levels and when to use each
- Iconography (library, sizes) and motion (durations, easing, reduced motion)

## 2. Component inventory
| Component | Variants | Sizes | Used on screens | Library basis | Status |
|---|---|---|---|---|---|
| Button | primary, secondary, ghost, danger, link | sm, md, lg | all | <library or custom> | specified |

## 3. Component specifications (one block per component)
### Button
- **Purpose / when to use:** … · **When not to:** navigation (use a link)
- **Anatomy:** container, label, optional leading icon, optional spinner
- **Variants:** primary (one per view), secondary, ghost, danger, link
- **Sizes:** sm 32 px, md 40 px, lg 48 px height (touch ≥ 44 px on mobile)
- **States:** default, hover, active, focus-visible, disabled, loading
- **Tokens:** `button.primary.bg`, `button.primary.bgHover`, `button.primary.fg`, `radius.md`, `space.2`/`space.4`, `motion.duration.fast`
- **Behavior:** loading keeps the width and blocks double submit; disabled has a reason nearby
- **Accessibility:** native `<button>`; label from the text; `aria-busy` while loading; focus ring token; 3:1 for the boundary
- **Content:** verb + object, sentence case (VOICE_AND_TONE.md)
- **Do / Don't:** …

## 4. Patterns
Forms (layout, validation, required markers), tables and lists (sorting, pagination, empty and loading), navigation, search and filters, dialogs and drawers, notifications (toast, inline, banner), onboarding and empty states, data visualization (the chart palette, axis and legend rules), file upload, date and time input.

## 5. Accessibility standards
WCAG 2.2 AA commitments per component type; the keyboard model for composite widgets (menu, tabs, combobox, dialog: WAI-ARIA Authoring Practices).

## 6. Governance
- After G2, new or changed components go through a change request on g2 (uiux-agent + design-reviewer)
- Engineers needing an unspecified component send the uiux-agent a `request` message; they don't invent one
- Versioning: the change log at the end of this document
```

## Baseline component list (specify what the screens use; skip the rest with "n/a")
Button · Icon button · Link · Text input · Textarea · Select · Combobox/autocomplete · Checkbox · Radio · Switch · Date picker · File upload · Form field (label, help, error) · Badge/tag · Avatar · Card · Table · List · Pagination · Tabs · Breadcrumbs · Top bar · Sidebar / bottom nav · Menu/dropdown · Dialog · Drawer · Toast · Inline alert · Banner · Tooltip · Popover · Skeleton · Spinner/progress · Empty state · Stepper · Chart container.

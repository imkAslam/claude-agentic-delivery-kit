# Design guidelines (kit defaults; the project's BRAND-BRIEF overrides them)

## Principles
1. **Clarity over decoration.** Every element earns its place, and the primary action is obvious.
2. **Consistency.** The same thing looks and behaves the same everywhere: tokens, components, wording.
3. **Feedback.** Every action has a visible result within 100 ms (pressed state, spinner, optimistic update, toast).
4. **Forgiveness.** Undo where possible, confirm only destructive actions, never lose user input.
5. **Accessible by default.** Keyboard, screen reader, contrast and motion preferences come first, not later.

## Token system (kit defaults; the project's names and values live in `docs/delivery/tokens.json`, see build-design-system → DESIGN_TOKENS.md)
| Group | Tokens |
|---|---|
| Color (semantic) | `color.bg.default/subtle`, `color.surface.default/raised`, `color.border.default/strong`, `color.text.default/muted/inverse`, `color.primary.default/hover/on`, `color.secondary.default`, `color.accent.default`, `color.success/warning/danger/info.default` (+ `.on`), `color.focus.ring` |
| Typography | `font-sans`, `font-mono`; sizes `xs 12`, `sm 14`, `base 16`, `lg 18`, `xl 20`, `2xl 24`, `3xl 30`, `4xl 36`; weights 400/500/600/700; line height 1.5 for body, 1.2 for headings |
| Spacing | 4px base: `1=4`, `2=8`, `3=12`, `4=16`, `5=20`, `6=24`, `8=32`, `10=40`, `12=48`, `16=64` |
| Radius | `none 0`, `sm 4`, `md 8`, `lg 12`, `xl 16`, `full 9999` |
| Elevation | `shadow-sm` (cards), `shadow-md` (dropdowns), `shadow-lg` (dialogs) |
| Motion | `fast 120ms`, `base 200ms`, `slow 320ms`; easing `standard cubic-bezier(.2,0,0,1)`; respect `prefers-reduced-motion` |
| Layout | breakpoints `sm 640`, `md 768`, `lg 1024`, `xl 1280`; content max-width 1200–1280; 12-column grid with 24px gutters on desktop and 16px on mobile |

Dark mode, if it's in scope: define every color token for both themes. Never invert images or brand marks.

## Accessibility (WCAG 2.2 AA)
- Contrast: text ≥ 4.5:1, large text (≥ 24px, or ≥ 18.66px bold) ≥ 3:1, UI components and focus indicators ≥ 3:1.
- A focus indicator is always visible (2px ring with an offset, ≥ 3:1 against the adjacent colors). Never use `outline: none` without a replacement.
- Targets ≥ 24×24 CSS px (44×44 recommended on touch, 44pt iOS / 48dp Android).
- Every input has a visible label. Errors appear as text next to the field and are announced (`aria-live` / `aria-describedby`).
- Use headings in order, landmark regions (header, nav, main, footer) and a skip link on long pages.
- Don't convey information by color alone (pair it with an icon or text).
- Media: alt text for meaningful images, captions for video, no autoplay with sound.

## Content
- Write in sentence case. Use plain verbs on buttons ("Save changes", not "Submit").
- Error messages say what happened and how to fix it ("Card expired. Use another card.").
- An empty state explains what will appear there and offers the next action.
- Format numbers, dates and currency for the user's locale.

## Do / Don't
| Do | Don't |
|---|---|
| One primary button per view or section | Several competing primary buttons |
| Skeletons for content loading > 300 ms | Spinners that block the whole page for partial loads |
| Inline validation after blur, then on change | Validation errors before the user has typed |
| Tables for comparing many records, cards for browsing | Cards for dense comparison data |
| Toasts for confirmations, inline alerts for errors that block | Modals for non-blocking information |
| Confirm destructive actions, naming the object | "Are you sure?" with no context |

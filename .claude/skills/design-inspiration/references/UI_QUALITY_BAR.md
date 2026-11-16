# UI quality bar: what "professionally designed" means

Used by the uiux-agent (self-check), the design-reviewer (designs), and design QA (built components and screens). Score **each component and each key screen**. A component is professional when a designer at a good product company would ship it without comment.

## 1. The ten checks (0 = fails, 1 = acceptable, 2 = good)
| # | Check | What "good" looks like | Typical failure |
|---|---|---|---|
| 1 | **Spacing rhythm** | Every gap is a step of the spacing scale (4/8-based tokens); related things sit closer than unrelated things; padding is even on all sides of a container | Odd values (5, 13, 22 px); elements crammed or floating; uneven padding |
| 2 | **Alignment** | Edges line up on a visible grid; text baselines align across a row; icons are optically centered with their label | Ragged left edges; an icon 1–2 px off; mixed alignments in one block |
| 3 | **Type hierarchy** | At most 3–4 sizes on a screen from the type scale; one clear primary per screen; weight and color create hierarchy before size does | Many sizes; everything bold; long lines (over ~75 characters) |
| 4 | **Color discipline** | The 60-30-10 split holds; one accent action per view; status colors only for status; text contrast passes | Several competing accent buttons; color used as decoration; grey text on grey |
| 5 | **Consistency** | The same component looks and behaves the same everywhere; same radius, border, shadow and icon set throughout | Two button heights; mixed icon sets; a one-off shadow |
| 6 | **Complete states** | Default, hover, focus-visible, active, disabled, loading, error, empty, and long or missing content all designed | Only the happy state; layout breaks with a long name or no data |
| 7 | **Density and touch** | Density fits the task (data tools compact, consumer flows roomy); touch targets at least 44×44 px on touch devices, 24×24 minimum elsewhere | Tiny hit areas; a table that needs scrolling for 5 rows |
| 8 | **Feedback and motion** | Every action answers within 100 ms (pressed state, spinner, optimistic update); transitions 120–250 ms with the token easing; reduced motion respected | Clicks that seem to do nothing; long or bouncy animations |
| 9 | **Content** | Labels say what happens (verb + object); errors say what went wrong and how to fix it; no placeholder or lorem text; numbers and dates formatted | "Submit", "Error occurred", raw ids, untranslated enum values |
| 10 | **Accessibility** | Keyboard reaches and operates everything in a logical order; visible focus; correct roles and names; meaning never by color alone | Div buttons; focus hidden; icon-only buttons without a name |

## 2. Passing
- **Component:** at least **16 of 20**, with no check at 0. Checks 6 and 10 must be 2 for interactive components.
- **Key screen:** at least **16 of 20**, with no check at 0.
- Below the bar is `CHANGES` (P2; P1 when check 10 fails or contrast fails). The finding names the check, the place and the fix ("Check 1: card padding is 12 px top and 20 px sides; use space.4 on all sides").

## 3. How to check
1. **Look at it rendered,** never only at code: the mockup PNG, or the component on the dev-only gallery page in every state, at desktop and mobile width, in each theme in scope.
2. Compare with the library's own documentation for that component and the matching `COMPONENTS_*.md` entry.
3. Squint test: the primary action and the main content should still stand out when the screen is blurred.
4. Stress it: the longest realistic text, no data, 1 item, 1,000 items, an error, a slow network.
5. Tab through it with the keyboard.

## 4. The component gallery (frontend and mobile)
Every project has a **dev-only gallery page** (for example `/dev/components`, excluded from production builds) that renders each base and feature component in all its states with realistic content. The frontend engineer adds a component there when it is built; design QA reviews components there and records the scores in `REVIEW.md › Design QA`. It replaces per-state screenshots: one screenshot of the gallery section per component is enough.

## 5. What makes UI look unprofessional (fix these first)
Inconsistent spacing · more than one primary button in a view · centered long text · borders and shadows on everything · too many colors or font sizes · unstyled default browser controls · missing empty and loading states · truncated text without a tooltip · modals for everything · walls of fields with no grouping · technical error text shown to users.

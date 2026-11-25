# UI quality bar: what "professionally designed" means

Used by the uiux-agent (self-check), the design-reviewer (designs), and design QA (built components and screens). Score **each component and each key screen**. A component is professional when a designer at a good product company would ship it without comment.

## 1. The ten checks (0 = fails, 1 = acceptable, 2 = good)
| # | Check | What "good" looks like | Typical failure |
|---|---|---|---|
| 1 | **Spacing rhythm** | Every gap is a step of the spacing scale (4/8-based tokens); related things sit closer than unrelated things; padding is even on all sides of a container | Odd values (5, 13, 22 px); elements crammed or floating; uneven padding |
| 2 | **Alignment** | Edges line up on a visible grid; text baselines align across a row; icons are optically centered with their label | Ragged left edges; an icon 1–2 px off; mixed alignments in one block |
| 3 | **Type hierarchy and scanning** | At most **2 font families**; about **3 sizes** on a screen (never more than 4) from the type scale; one clear primary per screen; weight and color create hierarchy before size does; the screen scans in an F or Z pattern (DESIGN_GUIDELINES principle 8) | Many sizes or a third font; everything bold; long lines (over ~75 characters); the key fact buried mid-paragraph |
| 4 | **Color discipline** | A limited palette: primary, secondary and neutrals, with status colors only for status; the 60-30-10 split holds; one accent action per view; text contrast passes in light and dark; the light theme reads light (no full-width dark bands); errors stand apart from the brand color | Several competing accent buttons; color used as decoration; grey text on grey; a theme that only works in one mode |
| 5 | **Consistency** | The same component looks and behaves the same everywhere; same radius, border, shadow and icon set throughout | Two button heights; mixed icon sets; a one-off shadow |
| 6 | **Complete states** | Default, hover, focus-visible, active, disabled, loading, error, empty, and long or missing content all designed | Only the happy state; layout breaks with a long name or no data |
| 7 | **Density and touch** | Density fits the task (data tools compact, consumer flows roomy); touch targets at least 44×44 px on touch devices, 24×24 minimum elsewhere | Tiny hit areas; a table that needs scrolling for 5 rows |
| 8 | **Feedback and motion** | Every action answers within 100 ms (pressed state, spinner, optimistic update); transitions 120–250 ms with the token easing; reduced motion respected | Clicks that seem to do nothing; long or bouncy animations |
| 9 | **Content** | Labels say what happens (verb + object); errors say what went wrong and how to fix it; no placeholder or lorem text; numbers and dates formatted | "Submit", "Error occurred", raw ids, untranslated enum values |
| 10 | **Accessibility** | Keyboard reaches and operates everything in a logical order; visible focus; correct roles and names; meaning never by color alone | Div buttons; focus hidden; icon-only buttons without a name |

## 2. Passing
- **Component:** at least **16 of 20**, with no check at 0. Checks 6 and 10 must be 2 for interactive components.
- **Key screen:** at least **16 of 20**, with no check at 0. It also meets every craft rule in §6, and next to its two anchor reference captures (DESIGN_RESEARCH §1) it reads as finished product design, not a wireframe: the reviewer says why in one line.
- Below the bar is `CHANGES` (P2; P1 when check 10 fails or contrast fails). The finding names the check, the place and the fix ("Check 1: card padding is 12 px top and 20 px sides; use space.4 on all sides").

## 3. How to check
0. **Polish pass (the designer, before asking for review):** render the screen, read the PNG next to its anchor references, write down the three biggest gaps (hierarchy, spacing, density, colour, content), fix them, and render again. Repeat once if a gap remains.
1. **Look at it rendered,** never only at code: the mockup PNG, or the component on the dev-only gallery page in every state, at desktop and mobile width, in light and in dark.
2. Compare with the library's own documentation for that component and the matching `COMPONENTS_*.md` entry.
3. Squint test: the primary action and the main content should still stand out when the screen is blurred.
4. Stress it: the longest realistic text, no data, 1 item, 1,000 items, an error, a slow network.
5. Tab through it with the keyboard.
6. Walk the UX laws in DESIGN_GUIDELINES.md (choice overload, short forms, figure-ground, closure, connectedness, banner blindness). A breach lowers the check it touches, usually 3, 7 or 9.
7. With a glass, soft or spatial style: check the VISUAL_STYLES.md §3 guardrails on the render (text over the busiest background, the solid fallback, 3:1 edges, reduced motion).

## 4. The component gallery (frontend and mobile)
Every project has a **dev-only gallery page** (for example `/dev/components`, excluded from production builds) that renders each base and feature component in all its states with realistic content. The frontend engineer adds a component there when it is built; design QA reviews components there and records the scores in `REVIEW.md › Design QA`. It replaces per-state screenshots: one screenshot of the gallery section per component is enough.

## 5. What makes UI look unprofessional (fix these first)
A bare form on a wide empty page (auth screens: AUTH_SCREENS.md) · inconsistent spacing · more than one primary button in a view · centered long text · borders and shadows on everything · too many colors or font sizes · unstyled default browser controls · missing empty and loading states · truncated text without a tooltip · modals for everything · walls of fields with no grouping · technical error text shown to users.

## 5a. The default AI look (fix on sight)
Adapted from the MIT-licensed `frontend-ui-engineering` skill (addyosmani/agent-skills), rewritten for this kit.

| Default | Why it fails | Fix |
|---|---|---|
| Purple or indigo everything | The safest palette, so every app looks the same | The project's palette from the brand |
| Heavy gradients | Noise that competes with the content | Flat, or the brand's own gradient only |
| Rounded everything | Ignores the radius scale | The radius tokens |
| Generic hero and stock card grids | A template with no link to the content or its priority | A content-first layout |
| Placeholder copy | Hides wrapping and overflow problems | Realistic copy from the copy deck |
| Oversized padding everywhere | Flattens the hierarchy | The spacing scale (check 1) |
| Shadow-heavy cards | Slows low-end devices and competes with content | Shadows only where the design system specifies them |
| Glass or soft effects as decoration | Unreadable text, slow pages, a trend with no reason | Only where the chosen direction's visual style puts them (define-brand → VISUAL_STYLES.md), within its guardrails |

## 6. Craft rules (measured on the render; each failure is a check-1, 2 or 3 deduction)
1. The screen starts from a PAGE_LAYOUTS.md composition, and mockups are built from `mockup-kit.css` (no hand-rolled base styles).
2. One clear focal point: the page title and the one primary action stand out in the squint test; at most one primary button per view.
3. Controls share one height (40 px default); auth primary buttons are full card width.
4. One depth level: no card inside a card, no border around every element; sections are separated by space first.
5. Type has hierarchy: at most 3 sizes per card; headings semibold; numbers tabular; KPI values 30–36 px.
6. KPI tiles carry a label, a value and context (a change, a target or a status), and there are at most 4 in a row.
7. The brand shows beyond the primary button: the selected navigation item, highlights and empty-state icons use the brand tints (60-30-10).
8. Empty, loading and error states sit inside their card in the same visual language; never a full-bleed red block.
9. Real content with realistic lengths; no placeholder text, "Item 1" or empty boxes; the fold is used (no half-empty screen with a lone card).
10. Navigation fits the product: a sidebar once there are more than 5 sections; the theme switch lives in the account menu.

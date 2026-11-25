# Page layouts: proven compositions with measurements

Components make a screen look finished; **composition** makes it look designed. Start every key screen from one of these layouts, build it from `build-design-system/assets/mockup-kit.css` (mockups) or the UI library's matching block (code: shadcn/ui blocks such as the dashboard, sidebar and login blocks), then fit it to the brand. Measurements are defaults for a 1440×900 desktop; the tokens supply the values.

## 1. App shell (every signed-in screen)
- **Sidebar** 240–264 px, collapsible to 64 px icons; brand at the top; grouped navigation (a small group label above each group); the current item filled with the secondary tint; counts right-aligned; account and help at the bottom. More than 5 top-level sections → a sidebar, never a crowded top bar.
- **Top bar** 56–64 px: breadcrumb or context switcher on the left; search (≤ 320 px), notifications and the account menu on the right. No theme toggle in the top bar: it lives in the account menu.
- **Content** max-width 1280 px (data-dense apps may go full width), 32 px padding (16 px on phones), 24 px between sections.

## 2. Dashboard
- **Page header:** a title that says something ("Good morning, Dr. Patel"), a subline with the one thing that matters today, and at most one primary action plus one secondary.
- **KPI row:** 3–4 tiles, never 6 equal ones. Each tile: label (14 px, muted) → value (30–36 px, semibold, tabular numbers) → a change or context line (▲ 8% vs last month) or a sparkline. Put the number that needs action first, or mark it with a status badge.
- **Body:** main column (2/3) with the work list or the chart; side column (1/3) with the queue, alerts or activity. Every card earns its place by answering a question the user has.
- **States:** empty cards show what will appear and the first action; errors are an inline alert inside the card, never a full red block.

## 3. List or table page
- Header (title + count + primary action) → a toolbar (search, 2–3 filters as dropdowns, view options, bulk actions when rows are selected) → the table in one card → pagination or infinite load.
- Rows 48–56 px with the first column carrying a primary line and a muted secondary line; numbers right-aligned with tabular figures; status as a tinted badge with a dot; row actions in a trailing menu; sticky header when the list scrolls.
- Phones: rows become cards with the 2–3 fields that matter.

## 4. Detail page
- Header with the record name, its status badge, key facts in one line, and actions (primary + a "more" menu) → tabs for the sections (Overview first) → a two-column body: main content (2/3) and a side panel (1/3) for properties, people and activity.

## 5. Form and settings
- Forms: one column, 480–640 px wide, labels above fields, related fields grouped under a short heading, the primary action at the bottom left (or a sticky footer for long forms). Never two columns for unrelated fields.
- Settings: a left section list (or tabs) and a right panel; each section is a card with a title, one line of description, the fields, and its own Save.

## 6. Auth (AUTH_SCREENS.md)
Split screen: form side with a 400 px card centred, a 28–32 px title, full-width 40–44 px primary button; brand side with the product's animated illustration, the promise and 3 reassurance points. One task per screen.

## 7. Landing page (LANDING_PAGE.md)
Hero (headline ≤ 10 words, subline, primary + secondary CTA, the product visual) → social proof the client approved → 3–6 features (benefit headline + one line + a screenshot or icon) → how it works (3 steps) → final CTA → footer. Sections 96–128 px apart on desktop; alternate a light band to separate sections instead of borders.

## 8. Craft defaults (the details that separate finished from wireframe)
| Element | Default |
|---|---|
| Type scale | 12 · 14 · 16 · 18 · 20 · 24 · 30 · 36; body 14–16; headings semibold; at most 3 sizes on one card |
| Control height | 40 px (36 compact, 44 touch); inputs, selects and buttons share it |
| Spacing | an 8 px rhythm (4 for tight pairs); 16–24 inside cards; 24–32 between sections |
| Radius | one scale: inputs and buttons md, cards lg, badges and avatars full |
| Depth | one level: cards on a subtle background with a hairline border **or** a soft shadow, not both strong; no card inside a card |
| Colour | 60-30-10; brand tint for selected and highlighted states; status colours only for status |
| Icons | one set, 16 px in text and buttons, 20 px in navigation, stroke matched to the type weight |
| Numbers | tabular figures, right-aligned in tables, units in muted text |
| Content | real names, real numbers and realistic lengths; never "Lorem", "Item 1" or empty boxes |

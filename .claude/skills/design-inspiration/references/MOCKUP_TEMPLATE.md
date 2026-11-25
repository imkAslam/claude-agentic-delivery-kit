# Mockup template (uiux-agent)

Mockups are **static, self-contained HTML** in `docs/delivery/mockups/<screen-id>-<state>.html` (no external network requests), rendered to PNG next to each file. After G2 they are the visual contract.

## Naming
`<screen-id>-<state>.html` → `S-03-orders-list-default.html`, `S-03-orders-list-empty.html`, `S-03-orders-list-error.html`. Every screen in the `DESIGN.md › UX` inventory has at least default, empty/loading and error variants where they apply.

## Build from the kit
Start every key screen from a design-inspiration → `PAGE_LAYOUTS.md` composition, and compose it from **`mockup-kit.css`**: copy `.claude/skills/build-design-system/assets/mockup-kit.css` once to `docs/delivery/mockups/mockup-kit.css` and link it right after the token `<style>` block (`<link rel="stylesheet" href="mockup-kit.css">`). The kit gives the app shell, page header, cards, KPI tiles, buttons, fields, badges, tables, tabs, alerts, empty states and the auth split, all from the tokens; a screen's own `<style>` only adds what its component spec needs. Before review, do the polish pass (UI_QUALITY_BAR §3 step 0).

## Skeleton
```html
<!doctype html>
<html lang="en" data-theme="light">
<head>
<meta charset="utf-8">
<script>document.documentElement.dataset.theme = new URLSearchParams(location.search).get('theme') || 'light'</script>
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>S-03 Orders list (default)</title>
<!-- covers: AC-ORD-1, AC-ORD-5 -->
<style>
  /* Paste the output of: bash .claude/skills/build-design-system/scripts/check-tokens.sh --css --theme docs/delivery/tokens.dark.json docs/delivery/tokens.json
     (it emits :root for light and [data-theme="dark"] for dark). Never type values by hand. */
  :root { --color-bg-default: #ffffff; --color-text-default: #0f172a; /* … the generated variables … */ }
  * { box-sizing: border-box; }
  body { margin: 0; font-family: var(--font-family-sans); font-size: var(--font-size-base); line-height: var(--font-lineHeight-body); color: var(--color-text-default); background: var(--color-bg-default); }
  .btn { border-radius: var(--radius-md); padding: var(--space-2) var(--space-4); border: 1px solid var(--color-border-strong); background: var(--color-surface-default); color: var(--color-text-default); }
  .btn-primary { background: var(--button-primary-bg, var(--color-primary-default)); color: var(--color-primary-on); border-color: transparent; }
  :focus-visible { outline: 2px solid var(--color-focus-ring); outline-offset: 2px; }
</style>
</head>
<body>
  <header><!-- top bar --></header>
  <main><!-- page header, content, states --></main>
</body>
</html>
```
The example values are placeholders. The variables always come from `tokens.json` through `check-tokens.sh --css`; only components specified in DESIGN.md › Components appear in a mockup.

## Render to PNG
```bash
R=.claude/skills/build-design-system/scripts/render-png.sh
bash $R docs/delivery/mockups/S-03-orders-list-default.html docs/delivery/mockups/S-03-orders-list-default.png 1440x900
bash $R docs/delivery/mockups/S-03-orders-list-default.html docs/delivery/mockups/S-03-orders-list-default.mobile.png 390x844
bash $R docs/delivery/mockups/S-03-orders-list-default.html docs/delivery/mockups/S-03-orders-list-default.dark.png 1440x900 dark
```
Every screen's **default** state is also rendered in dark (`.dark.png`, desktop size); other states in dark only where they look different. Skip the dark render only for a recorded single-theme brand.
The renderer uses Playwright when its browser is installed, otherwise an installed Chrome/Chromium. Exit 3 = no renderer: keep the HTML and report "not rendered". Never fabricate a PNG.

## DESIGN.md › UX screen inventory row
| Screen id | Name | Persona | Journey | States (mockup files) | AC covered | Contract operations | Components |
|---|---|---|---|---|---|---|---|
| S-03 | Orders list | Customer | J-2 | default, empty, error, loading | AC-ORD-1, AC-ORD-5 | listOrders | Table, Badge, Pagination, Empty state |

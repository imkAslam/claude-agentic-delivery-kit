# Design tokens (W3C DTCG format)

The tokens are the **single source of truth for every visual value**. They live in `docs/delivery/tokens.json` (plus `tokens.<theme>.json` overrides, e.g. `tokens.dark.json`), written by the uiux-agent from BRAND-BRIEF, approved at G2, and consumed by the mockups, the web theme and the mobile theme. Code never hardcodes a color, size or duration that a token covers.

## 1. Format
[Design Tokens Community Group format](https://design-tokens.github.io/community-group/format/): every token is an object with `$value` and a `$type` (on the token or inherited from its group). Aliases reference another token: `"{color.neutral.900}"`. Types used: `color`, `dimension`, `fontFamily`, `fontWeight`, `number`, `duration`, `cubicBezier`, `shadow`.

## 2. Three tiers
| Tier | Example | Who uses it | Rule |
|---|---|---|---|
| **Primitive** (the palette and raw scales) | `color.neutral.900`, `color.brand.600`, `space.4` | Only other tokens | Never used directly in UI code |
| **Semantic** (the meaning) | `color.text.default`, `color.primary.default`, `color.danger.on` | Components, screens, mockups | Themes override **only** this tier |
| **Component** (optional, for shared components) | `button.primary.bg` → `{color.primary.default}` | The component library | Always an alias of a semantic token |

## 3. Naming
`<category>.<role>.<variant>` in lowercase; `default` for the base variant; `on` for content placed on that color (`color.primary.on`); states as variants (`hover`, `active`, `disabled`, `subtle`). Numeric scales for primitives (`50`–`950`, `1`–`16`). The CSS name is the path joined with dashes: `color.text.muted` → `--color-text-muted`.

## 4. Required semantic tokens (checked)
`color.bg.default`, `color.surface.default`, `color.border.default`, `color.border.strong`, `color.text.default`, `color.text.muted`, `color.primary.default`, `color.primary.hover`, `color.primary.on`, `color.secondary.default`, `color.secondary.on`, `color.danger.default`, `color.danger.on`, `color.success.default`, `color.warning.default`, `color.info.default`, `color.focus.ring`, `font.family.sans`, `font.size.base`, `space.4`, `radius.md`. Add project-specific ones under `$extensions."delivery.required"` (a JSON array of paths).

## 5. Contrast pairs (checked, per theme)
The defaults cover text on backgrounds and surfaces (4.5:1), muted text (4.5:1), labels on primary, secondary and danger (4.5:1), the primary color, input borders and the focus ring against the background (3:1, WCAG 1.4.11). Add more under `$extensions."delivery.contrastPairs"`: `[{"fg": "color.accent.default", "bg": "color.bg.default", "min": 3}]` (this list replaces the defaults, so copy them in).

## 5a. Distinctness pairs (checked, per theme)
Contrast says a color is readable; distinctness says it **doesn't look like another role**. The checker measures the perceptual difference ΔE in OKLab between pairs: by default primary and secondary vs danger, success and warning (min **0.10**), and success and warning vs danger (min **0.08**). Below the min is a failure (e.g. a rose brand color next to a red danger color). Each pair is also simulated for protanopia and deuteranopia (Machado 2009); below `cvdMin` (0.05) is a **warning**: the pair is fine for most users, but status must then never be shown by color alone (icon + text, which the design system already requires). Override with `$extensions."delivery.distinctPairs"`: `[{"a": "color.accent.default", "b": "color.danger.default", "min": 0.1}]` (this list replaces the defaults, so copy them in). How the colors are chosen in the first place: define-brand → COLOR_METHOD.md.

## 6. Themes
- A theme file overrides **semantic** tokens only (same paths), never primitives or component tokens.
- Every semantic color in the base exists in every theme file; the checker runs all pairs again for each theme.
- Dark themes: raise surfaces with lighter neutrals instead of shadows; desaturate the brand colors (lighter steps); never invert images or logos (use `logo-inverse.svg`).

## 7. Commands
```bash
S=.claude/skills/build-design-system/scripts
bash $S/check-tokens.sh --theme docs/delivery/tokens.dark.json docs/delivery/tokens.json      # contrast + distinctness checks (exit 1 on failure; WARN lines don't fail)
bash $S/check-tokens.sh --css --theme docs/delivery/tokens.dark.json docs/delivery/tokens.json > /tmp/tokens.css   # CSS variables
```
The CSS output: primitives as literal values, aliases as `var(--…)` (so component tokens follow the active theme), a `[data-theme="dark"]` block and a `prefers-color-scheme` block. Paste it into each mockup's `<style>`, and generate the web theme from it.

## 8. Mapping into code (design-foundation tickets, ms-1)
| Platform | How | Owner |
|---|---|---|
| Web, CSS / any framework | Generate the CSS variables file from tokens.json in the build (the `--css` output, or Style Dictionary when the stack already uses it); components use `var(--color-…)` | frontend |
| Tailwind | `theme.extend.colors.primary = 'var(--color-primary-default)'` etc.; no raw hex in `className` | frontend |
| Component libraries (MUI, Chakra, Vuetify, Angular Material…) | Build the library theme object from the semantic tokens | frontend |
| React Native / Expo | A generated `theme.ts` (light/dark objects keyed by semantic name), with `useColorScheme` | mobile |
| Flutter | A generated `ThemeData` / `ColorScheme` + `ThemeExtension` for the extra semantic tokens | mobile |
| Native iOS / Android | Asset-catalog colors / `colors.xml` + `values-night` generated from the tokens | mobile |
**Copy-in component libraries themed by CSS variables (shadcn/ui and its Vue and Svelte ports):** map the library's variables to the semantic tokens in the generated theme file, for the base and for each theme. The brand then drives every library component, and the 60-30-10 roles stay intact.
| Library variable | Semantic token |
|---|---|
| `--background` / `--foreground` | `color.bg.default` / `color.text.default` |
| `--card`, `--popover` (+ `-foreground`) | `color.surface.default`, `color.surface.raised` / `color.text.default` |
| `--primary` / `--primary-foreground` | `color.primary.default` / `color.primary.on` |
| `--secondary` / `--secondary-foreground` | `color.secondary.default` / `color.secondary.on` |
| `--muted` / `--muted-foreground` | `color.bg.subtle` / `color.text.muted` |
| `--accent` / `--accent-foreground` (hover and selected surfaces) | `color.secondary.subtle` (or `color.bg.subtle`) / `color.text.default` |
| `--destructive` (+ `-foreground`) | `color.danger.default` / `color.danger.on` |
| `--border`, `--input` / `--ring` | `color.border.default`, `color.border.strong` / `color.focus.ring` |
| `--radius` | `radius.md` |
| Chart variables | The chart palette from BRAND-BRIEF §3 |
Use the color format the pinned library version expects, generated from the token hex values. Never keep the library's default palette, and never edit colors inside a component file.

The generated theme is checked in under the role's owned paths; a test (or lint rule) fails on raw color literals outside the theme files.

## 9. tokens.json template (passes check-tokens.sh)
```json
{
  "$schema": "https://design-tokens.github.io/community-group/format/",
  "$description": "Product design tokens (DTCG). Primitives -> semantic -> component. Values from BRAND-BRIEF.md.",
  "color": {
    "$type": "color",
    "neutral": {
      "0":   { "$value": "#ffffff" },
      "50":  { "$value": "#f8fafc" },
      "100": { "$value": "#f1f5f9" },
      "200": { "$value": "#e2e8f0" },
      "400": { "$value": "#94a3b8" },
      "500": { "$value": "#64748b" },
      "600": { "$value": "#475569" },
      "700": { "$value": "#334155" },
      "800": { "$value": "#1e293b" },
      "900": { "$value": "#0f172a" },
      "950": { "$value": "#020617" }
    },
    "brand": {
      "500": { "$value": "#2563eb" },
      "600": { "$value": "#1d4ed8" },
      "700": { "$value": "#1e40af" },
      "300": { "$value": "#93c5fd" },
      "200": { "$value": "#bfdbfe" }
    },
    "violet": { "50": { "$value": "#f5f3ff" }, "200": { "$value": "#ddd6fe" }, "300": { "$value": "#c4b5fd" }, "700": { "$value": "#6d28d9" }, "800": { "$value": "#5b21b6" }, "900": { "$value": "#4c1d95" } },
    "red":    { "600": { "$value": "#dc2626" }, "700": { "$value": "#b91c1c" }, "300": { "$value": "#fca5a5" } },
    "green":  { "700": { "$value": "#15803d" }, "300": { "$value": "#86efac" } },
    "amber":  { "700": { "$value": "#b45309" }, "300": { "$value": "#fcd34d" } },
    "sky":    { "700": { "$value": "#0369a1" }, "300": { "$value": "#7dd3fc" } },

    "bg":      { "default": { "$value": "{color.neutral.0}" },  "subtle": { "$value": "{color.neutral.50}" } },
    "surface": { "default": { "$value": "{color.neutral.0}" },  "raised": { "$value": "{color.neutral.0}" } },
    "border":  { "default": { "$value": "{color.neutral.200}" }, "strong": { "$value": "{color.neutral.500}" } },
    "text":    { "default": { "$value": "{color.neutral.900}" }, "muted": { "$value": "{color.neutral.600}" }, "inverse": { "$value": "{color.neutral.0}" } },
    "primary": { "default": { "$value": "{color.brand.600}" },  "hover": { "$value": "{color.brand.700}" }, "on": { "$value": "{color.neutral.0}" } },
    "secondary": { "default": { "$value": "{color.violet.700}" }, "hover": { "$value": "{color.violet.800}" }, "on": { "$value": "{color.neutral.0}" }, "subtle": { "$value": "{color.violet.50}" } },
    "danger":  { "default": { "$value": "{color.red.700}" },    "on": { "$value": "{color.neutral.0}" } },
    "success": { "default": { "$value": "{color.green.700}" } },
    "warning": { "default": { "$value": "{color.amber.700}" } },
    "info":    { "default": { "$value": "{color.sky.700}" } },
    "focus":   { "ring": { "$value": "{color.brand.600}" } }
  },
  "font": {
    "family": { "sans": { "$type": "fontFamily", "$value": ["Inter", "system-ui", "-apple-system", "Segoe UI", "Roboto", "sans-serif"] },
                "mono": { "$type": "fontFamily", "$value": ["JetBrains Mono", "ui-monospace", "monospace"] } },
    "size":   { "$type": "dimension", "sm": { "$value": "14px" }, "base": { "$value": "16px" }, "lg": { "$value": "18px" }, "xl": { "$value": "20px" }, "2xl": { "$value": "24px" }, "3xl": { "$value": "30px" } },
    "weight": { "$type": "fontWeight", "regular": { "$value": 400 }, "medium": { "$value": 500 }, "semibold": { "$value": 600 }, "bold": { "$value": 700 } },
    "lineHeight": { "$type": "number", "body": { "$value": 1.5 }, "heading": { "$value": 1.25 } }
  },
  "space":  { "$type": "dimension", "1": { "$value": "4px" }, "2": { "$value": "8px" }, "3": { "$value": "12px" }, "4": { "$value": "16px" }, "6": { "$value": "24px" }, "8": { "$value": "32px" }, "12": { "$value": "48px" } },
  "radius": { "$type": "dimension", "sm": { "$value": "4px" }, "md": { "$value": "8px" }, "lg": { "$value": "12px" }, "full": { "$value": "9999px" } },
  "shadow": { "$type": "shadow", "sm": { "$value": { "offsetX": "0", "offsetY": "1px", "blur": "2px", "spread": "0", "color": "#0f172a14" } } },
  "motion": { "duration": { "$type": "duration", "fast": { "$value": "120ms" }, "base": { "$value": "200ms" } },
              "easing": { "$type": "cubicBezier", "standard": { "$value": [0.2, 0, 0, 1] } } },
  "button": {
    "primary": { "bg": { "$value": "{color.primary.default}" }, "bgHover": { "$value": "{color.primary.hover}" }, "fg": { "$value": "{color.primary.on}" }, "radius": { "$value": "{radius.md}" } }
  }
}
```

## 10. tokens.dark.json template
```json
{
  "color": {
    "bg":      { "default": { "$value": "{color.neutral.950}" }, "subtle": { "$value": "{color.neutral.900}" } },
    "surface": { "default": { "$value": "{color.neutral.900}" }, "raised": { "$value": "{color.neutral.800}" } },
    "border":  { "default": { "$value": "{color.neutral.700}" }, "strong": { "$value": "{color.neutral.400}" } },
    "text":    { "default": { "$value": "{color.neutral.50}" },  "muted": { "$value": "{color.neutral.400}" }, "inverse": { "$value": "{color.neutral.900}" } },
    "primary": { "default": { "$value": "{color.brand.300}" },   "hover": { "$value": "{color.brand.200}" }, "on": { "$value": "{color.neutral.950}" } },
    "secondary": { "default": { "$value": "{color.violet.300}" }, "hover": { "$value": "{color.violet.200}" }, "on": { "$value": "{color.neutral.950}" }, "subtle": { "$value": "{color.violet.900}" } },
    "danger":  { "default": { "$value": "{color.red.300}" },     "on": { "$value": "{color.neutral.950}" } },
    "success": { "default": { "$value": "{color.green.300}" } },
    "warning": { "default": { "$value": "{color.amber.300}" } },
    "info":    { "default": { "$value": "{color.sky.300}" } },
    "focus":   { "ring": { "$value": "{color.brand.300}" } }
  }
}
```

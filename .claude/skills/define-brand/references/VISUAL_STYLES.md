# Visual styles: the catalog the directions are built from

A **visual style** is how surfaces, depth and light behave: flat or layered, solid or translucent, raised or pressed. The palette, type and voice (COLOR_METHOD, BRAND_GUIDELINES) sit on top of it. Each G1 direction names **one style** from this catalog; the client chooses the direction, and so the style.

## 1. Choosing styles for the directions
- **The three directions use three different styles**, so the client compares real alternatives, not three shades of one look. The safe direction is usually Minimalism or Lightweight; the bold one may be a glass, neumorphic or spatial style when the product fits it (table §2, "Fits").
- **Pick by the product, not the trend.** Dense data, forms, long reading, low-end phones and users under stress favour Minimalism or Lightweight. Short sessions, media, onboarding and marketing surfaces can carry Glass, Liquid glass or Spatial.
- **A style decorates the chrome, never the content.** Effects (blur, translucency, soft extrusion, depth) go on navigation bars, sheets, overlays, cards and controls. Body text, tables, form fields and numbers always sit on a solid surface.
- **Every style comes in light and dark** (DESIGN_TOKENS §6). The board shows both.
- A client who names another style (for example Material, Brutalism, Claymorphism) gets it as one of the directions, written up with the same columns as §2.

## 2. The catalog
| Style | The look | Fits | Avoid when | Tokens it adds |
|---|---|---|---|---|
| **Minimalism** | Few elements, generous whitespace, one accent, hierarchy from type and spacing alone; borders over shadows | Almost everything; finance, health, tools, content | The brand must feel playful or rich and the client wants that shown | None beyond the base set |
| **Lightweight** | Flat, airy and fast: hairline borders (1 px), light neutral surfaces, small radius, no blur, at most one subtle shadow level; few images | Mobile-first and low-bandwidth audiences, dashboards, long forms | A premium or immersive feel is the goal | None; `shadow.sm` only |
| **Glassmorphism** | Frosted translucent panels over a colourful or photographic background: background blur, a 1 px light edge, soft shadow | Overlays, navigation, cards on a hero or media background; onboarding | Dense data or text-heavy screens; plain white backgrounds (the effect disappears); low-end devices | `material.glass.blur` (dimension, 12–24 px), `material.glass.opacity` (number, 0.6–0.8), `material.glass.edge` (color reference) |
| **Liquid glass** | Glass that behaves like a fluid lens: controls float above content, refract and tint from what is behind them, with a specular highlight; shapes morph between states | The control layer of a mobile or app-like web UI: tab bars, toolbars, floating buttons, sheets | Content surfaces; anything that must look identical across browsers; reduced-motion users (falls back to plain glass) | The glass tokens + `material.glass.highlight` (color reference), `motion.duration.morph` (≤ 300 ms) |
| **Neumorphism (soft UI)** | Elements extruded from or pressed into one same-colour surface by a light shadow above-left and a dark shadow below-right | Small, low-density surfaces: a player, a calculator, a settings panel, toggles | Anything where controls must be found fast: low-contrast boundaries are its known accessibility failure | `shadow.soft.raised`, `shadow.soft.pressed` (shadow pairs); a mandatory `color.border.default` edge (guardrail 3) |
| **Spatial UI** | Depth as structure: layered planes on a z-axis, parallax and scale on focus, content floating above a dimmed backdrop; inspired by spatial computing | Immersive onboarding, media, product showcases, step-by-step flows where depth shows order | Fast repeated tasks and data entry; reduced-motion users (depth stays, motion goes) | `elevation.1–4` (shadow + z scale), `motion.duration.depth` (≤ 300 ms) |

## 3. Guardrails (the design-reviewer checks every one)
1. **Contrast on the worst case.** Text on a translucent surface passes 4.5:1 against its *opaque fallback* colour (the semantic token, which `check-tokens.sh` checks) **and** in a render over the busiest background it will sit on. When the render fails, raise the opacity or add a scrim; never thin the text.
2. **Solid fallbacks.** Every translucent surface has a solid semantic colour, used when `backdrop-filter` is unsupported and under `@media (prefers-reduced-transparency: reduce)` and `(prefers-contrast: more)`.
3. **Boundaries at 3:1.** Buttons, inputs and toggles need an edge or fill at 3:1 against their surroundings. Neumorphic and glass controls get a visible border to reach it.
4. **Motion is optional.** Parallax, morphing and depth animations stop under `prefers-reduced-motion: reduce`; the layout and the states stay the same.
5. **Performance budget.** At most **two** blurred layers visible at once, blur ≤ 24 px, and no blur on scrolling lists. Minimalism and Lightweight carry no such cost, which is a reason to recommend them for low-end devices.
6. **Tokens only.** Every blur, opacity, shadow pair and depth level is a token. Colour tokens stay opaque (an alpha colour only gets a `check-tokens.sh` warning and skips the real contrast check), so translucency lives in `material.*.opacity` and is applied in CSS with `color-mix()`.

## 4. In the direction write-up
Each direction records: the style, why it fits the personas and the product, where the effect is used (which surfaces) and where it is not, its fallback, and the cost (device performance, browser support). The board's component strip and key screen show the style for real, in light and in dark.

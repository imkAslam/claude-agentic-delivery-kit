# Color method: how the palette is chosen

`check-tokens.sh` proves a palette is **readable** (WCAG contrast) and **unambiguous** (distinctness). This method decides **which colors** to use and **how much of each**. Use it for every direction (cases B and C) and to audit an existing brand (case A). The steps run in order; record the outcome of each on the direction board and in BRAND-DIRECTIONS §2.

## 1. Inputs
| Input | From | What it tells you |
|---|---|---|
| Domain and category | Intake, PRD §1 | The meanings users already attach to colors in this category |
| Persona context | BA-ANALYSIS personas, PRD §2 | Stress, lighting, session length, device, age, accessibility needs (e.g. clinicians on long night shifts need calm, low-glare screens) |
| Personality sliders | BRAND_DISCOVERY §3 | Calm vs energetic and serious vs playful drive saturation and hue temperature |
| Competitor landscape | BRAND_DISCOVERY §4 | The dominant category hue, the clichés, and the gap |
| Design research | DESIGN_RESEARCH.md → BRAND-DIRECTIONS §1a | Current palettes and color use in good products of this kind; a trend is used only if it passes §2–§7 |
| Existing brand | `docs/intake/**`, `design-references/` | Colors the client already owns (case A/B: keep them, never change them silently) |

## 2. Pick the hue family: meaning + gap
Start from what the color must communicate, then move away from the competitors where the direction allows.

| Domain | Common hue families and why | Avoid as the main brand color |
|---|---|---|
| Healthcare, clinical, wellbeing | Blue, teal, soft green: calm, trust, cleanliness | Saturated red or orange (they collide with alerts and critical values), neon |
| Finance, insurance, legal | Navy, deep blue, green, restrained gold: stability, money, seriousness | Playful pastels; red near numbers (reads as a loss) |
| Education, children | Warm yellows, oranges, friendly blues: energy, optimism | Low-contrast pastels for text |
| Developer and data tools | High-contrast neutrals with one vivid accent: focus, precision | Many competing hues |
| Food, hospitality, retail | Warm reds, oranges, greens: appetite, freshness, urgency | Cold grey-blue as the only color |
| Sustainability, outdoors | Greens, earth tones: nature, care | A green so close to `success` that brand and status merge |
| Luxury, premium | Near-black, deep jewel tones, metallic accents: restraint | Bright saturated primaries |

These are **heuristics, not rules**. The **safe** direction stays near the category norm, the **evolved** one shifts the hue or temperature one step, and the **bold** one moves away from the dominant competitor hue (BRAND_DISCOVERY §3: at least 2 slider steps). Culture and locale can reverse meanings (e.g. white for mourning, red for luck): check the PRD locales.

## 3. Reserve the status hues
Danger (red), warning (amber/orange), success (green) and info (blue/sky) carry meaning in every product. Brand colors must not be mistaken for them:
- The primary, secondary and accent colors must be clearly distinct from danger, warning and success. `check-tokens.sh` enforces ΔE ≥ 0.10 in OKLab (DESIGN_TOKENS §5a).
- If the client's brand *is* red or green (case A), keep the brand and **shift the status color** instead (e.g. danger to a deeper crimson with a stronger icon, or success to teal), and record why on the board and in BRAND-BRIEF §3.
- Status colors are always shown with an icon and text, never by color alone.

## 4. Proportion: the 60-30-10 rule
Every screen uses three roles in roughly this balance:

| Share | Role | What it covers | Tokens |
|---|---|---|---|
| **60%: dominant (main)** | The base that sets the overall tone | Page backgrounds, large surfaces, content areas | `color.bg.*`, `color.surface.*` (neutral, or a light tint of the brand hue) |
| **30%: secondary** | Supports the dominant without competing with it | Navigation, app bars, headers, section bands, cards, secondary buttons | `color.secondary.default`, `.hover`, `.on`, `.subtle` |
| **10%: accent (the loud color)** | The focal point that draws the eye | Primary call to action, key highlights, links, selection, focus | `color.primary.*` (the main action), `color.accent.*` (highlights) |

Rules for applying it:
- The dominant 60% is almost always a neutral or a very light brand tint. A saturated color across 60% of a screen tires the eye and fights text contrast.
- The accent is the loudest color and the rarest one. If it doesn't stand out against the dominant, it has failed; if it covers more than ~10%, nothing stands out any more.
- Text and status colors sit **outside** the ratio: they are functional, not decorative.
- Allowed variations: when the secondary is a strong neutral (e.g. a dark navigation shell), the dominant and secondary may swap places; tints and shades of the three hues extend the palette without adding new hues.
- It is a guideline per screen type, not a pixel count. Dense data screens (tables, dashboards, clinical charts) can run more neutral; marketing and landing screens can show more secondary. The accent stays near 10% everywhere.
- Every direction board's key screen and every mockup states its split (e.g. "dominant neutral-0/50 · secondary violet-700 nav + cards · accent brand-600 CTAs"), and the design-reviewer checks it on the rendered PNG.

## 5. Build the scales in OKLCH
- For each hue (brand, secondary, accent, neutrals, status), build a 50–950 scale in **OKLCH**: keep the hue stable, step the lightness evenly, and reduce the chroma toward both ends (very light and very dark steps can't hold full saturation). OKLCH is perceptually uniform, so equal steps look equal, which HSL does not guarantee.
- Choose `primary.default` as the **first step that passes contrast** for its uses (`primary.on` on it ≥ 4.5:1, it on `bg` ≥ 3:1), usually 600 or 700 in light mode. Do the same for `secondary.default`.
- Neutrals: pure grey for utilitarian directions, or tinted slightly toward the brand hue (chroma ≤ 0.02) for warmer ones.
- Store the hex values in `tokens.json` primitives (the checker reads hex); note the OKLCH source values on the board.

## 6. Dark theme
Follow DESIGN_TOKENS §6 (lighter, desaturated steps; surfaces raised with lighter neutrals). The 60-30-10 roles keep their meaning in dark mode; the dominant becomes the dark neutrals.

## 7. Color vision
About 1 in 12 men and 1 in 200 women have a color-vision deficiency, most often red/green. `check-tokens.sh` simulates protanopia and deuteranopia and **warns** when a pair collapses. A warning is acceptable only because status is never color alone; it is a design failure if the brand color and danger collapse. Chart palettes: a categorical sequence of 6–8 colors that stays distinguishable under the same simulation, with labels or patterns as backup.

## 8. Record the reasoning
Each direction states, on its board and in BRAND-DIRECTIONS §2:
- **Color rationale:** why this hue (meaning, persona, gap) and what it avoids (clichés, status collisions)
- **60/30/10:** which tokens fill the dominant, secondary and accent roles
- **Checks:** the `check-tokens.sh` summary line (contrast + distinctness, failures and warnings)

## Sources
- Nielsen Norman Group, *Using Color to Enhance Your Design*: https://www.nngroup.com/articles/color-enhance-design/
- UX Planet, *The 60–30–10 Rule: A Simple Way to Create Catchy User Interfaces*: https://uxplanet.org/the-60-30-10-rule-a-simple-way-to-creating-catchy-user-interfaces-e9e2cf957213
- UX Collective Bootcamp, *60–30–10 Rule: How to choose colors for your UI design*: https://bootcamp.uxdesign.cc/60-30-10-rule-how-to-choose-colors-for-your-ui-design-713b3d4c1445
- LogRocket, *OKLCH in CSS: consistent, accessible color palettes*: https://blog.logrocket.com/oklch-css-consistent-accessible-color-palettes
- Evil Martians, *Exploring the OKLCH ecosystem and its tools*: https://evilmartians.com/chronicles/exploring-the-oklch-ecosystem-and-its-tools
- Machado, Oliveira and Fernandes (2009), *A Physiologically-based Model for Simulation of Color Vision Deficiency* (the simulation matrices in `check-tokens.sh`)
- Björn Ottosson (2020), *A perceptual color space for image processing* (OKLab, used for ΔE): https://bottosson.github.io/posts/oklab/

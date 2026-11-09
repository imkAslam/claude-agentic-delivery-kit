# BRAND-BRIEF.md template (the brand guidelines, G2)

```markdown
> Status: in-review · Owner: uiux-agent · Direction: <A|B|C> chosen at G1 (GATE-LOG) · Tokens: docs/delivery/tokens.json · Updated: <ISO>

# Brand guidelines: <product name>

## 1. Foundation
Purpose · audience · personality traits (is / is not) · positioning · the 3 words every screen should feel like.

## 2. Logo
- Files: `brand/assets/logo.svg` (full), `logo-mark.svg` (symbol), `logo-mono.svg` (one color), `logo-inverse.svg` (on dark)
- Clear space: <x> = the cap height of the wordmark, on every side · minimum size: <n> px wide (wordmark), 16 px (mark)
- Placement: top-left in the app bar; centered on auth screens and emails
- Don't: stretch, recolor outside the palette, add effects, place it on busy imagery, rebuild it in text
- Status: proposal by agents · approved by <client> on <date> · trademark clearance: client responsibility

## 3. Color
Chosen with COLOR_METHOD.md. Rationale: <why these hues: meaning, personas, competitor gap; what they avoid>.
| Role (60-30-10) | Token (tokens.json) | Light | Dark (if in scope) | Use for | Never use for |
|---|---|---|---|---|---|
| Dominant · 60% | color.bg.default, color.surface.default (neutrals 50 … 950) | #… | #… | page backgrounds, large surfaces, content areas | saturated fills |
| Secondary · 30% | color.secondary.default | #… | #… | navigation, app bar, headers, section bands, cards, secondary buttons | the main call to action, status |
| Text on secondary | color.secondary.on | #… | #… | labels and icons on secondary surfaces | |
| Accent · 10% (the loud color) | color.primary.default | #… | #… | the main action, links, selection, focus | large backgrounds, body text |
| Text on primary | color.primary.on | #… | #… | labels on primary buttons | |
| Accent highlight (optional) | color.accent.default | | | highlights, badges, charts | errors |
| Success / warning / danger / info | color.<status>.default | | | status only, always with an icon or text (outside the 60-30-10 split) | decoration |
Proportion: **60% dominant, 30% secondary, 10% accent** per screen; text and status sit outside the split (COLOR_METHOD §4). Checks: the `check-tokens.sh` output (contrast and distinctness, every pair, both themes; warnings explained).
Charts and data visualization: a categorical sequence of 6–8 colors that stays distinguishable with color-vision deficiency.

## 4. Typography
| Role | Family (license) | Size / line height | Weight | Letter spacing |
|---|---|---|---|---|
| Display | | 36/44 | 700 | -0.02em |
| H1 / H2 / H3 | | 30/38 · 24/32 · 20/28 | 600 | |
| Body / small / caption | | 16/24 · 14/20 · 12/16 | 400 | |
| Mono | | 14/20 | 400 | |
Fallback stacks, font files and licenses (`brand/fonts/`), numerals (tabular for tables), the maximum line length (60–80 characters).

## 5. Shape, space, elevation, motion
Radius levels, border usage, the spacing scale and density, the shadow levels, the motion durations and easing, and the reduced-motion behavior (values: tokens.json).

## 6. Voice and tone
Voice traits (do / don't), tone by context, capitalization, the word list (use / avoid), and the microcopy patterns (VOICE_AND_TONE.md).

## 7. Iconography
Library (open license) or custom; stroke width, corner style, the sizes (16/20/24), when an icon needs a label.

## 8. Imagery and illustration
Photography or illustration style, subjects, treatments, alt-text rules, and sourcing (owned, open license, or paid: paid is a business decision).

## 9. Applications
Favicon and app icons, social preview, email header and footer, splash screen, error pages (404/500), print/PDF if in scope: each with its file in `brand/assets/` (BRAND_ASSETS.md).

## 10. Accessibility commitments
WCAG 2.2 AA; contrast on every pair; never color alone; focus ring token; reduced motion; minimum text size 14 px (12 px only for captions).
```

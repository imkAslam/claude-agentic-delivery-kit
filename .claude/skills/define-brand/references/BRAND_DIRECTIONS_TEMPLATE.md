# BRAND-DIRECTIONS.md template (G1)

```markdown
> Status: in-review · Owner: uiux-agent · Sources: Intake-Readiness.md, design-references/*, RESEARCH.md, BA-ANALYSIS.md · Updated: <ISO>

# Brand directions

## 1. Starting point and foundation
Case A / B / C (BRAND_DISCOVERY.md) and why. Purpose · audience · personality (is / is not) · positioning · the competitor landscape summary and the gap.

## 2. Directions at a glance
| | A · <name> (safe) | B · <name> (evolved) | C · <name> (bold) |
|---|---|---|---|
| In one line | | | |
| Mood words | | | |
| Sliders (classic→modern, serious→playful, calm→energetic, minimal→rich) | 2·2·2·1 | | |
| Dominant 60 / secondary 30 / accent 10 | neutral-0 / #… / #… | | |
| Color rationale (COLOR_METHOD) | why these hues, what they avoid | | |
| Type (headings / body) | <font> / <font> (license) | | |
| Shape and density | radius, borders, spacing | | |
| Iconography / imagery | | | |
| Contrast + distinctness check | `tokens: n checks pass, 0 failures, n warnings` | | |
| Board | brand/directions/A-board.png | | |
| Cost or licensing impact | none (open fonts) | | |

## 3. Recommendation
Direction <X>, because <tie to the personas, goals and the competitor gap>. What the client gives up by choosing it.

## 4. Questions for G1 (business only)
- Q-B1: Which visual direction? Options A / B / C (recommended: <X>).
- Client-only items (name, logo ownership, trademark, paid assets), each with a default.
```

## Direction board (`docs/delivery/brand/directions/<A|B|C>-board.html`, 1440×900)
One self-contained page with these blocks, in this order:
1. **Header:** direction name, 3–5 mood words, the one-line idea
2. **Wordmark proposal:** the product name in the heading font, on light and on dark, plus a small mark (favicon size preview at 16/32 px)
3. **Palette:** swatches sized by their 60/30/10 share (dominant, secondary, accent), then the status colors; each with hex, OKLCH, its role and the contrast ratio of each text pair; the color rationale in one line and the `check-tokens.sh` summary (contrast + distinctness)
4. **Typography:** the display, heading and body samples with the scale (e.g. 36/30/24/20/16/14)
5. **Shape and density:** buttons (primary, secondary, ghost), an input with its error state, a card, a badge, a toast
6. **Key screen:** the product's most important screen (from the BA journeys), at real content density, with its 60/30/10 split labeled
7. **Imagery and iconography:** the icon style (stroke, corners) and the image or illustration treatment, described or drawn in CSS/SVG (no stock images, no network)

Use the same HTML conventions as the mockups (build-design-system → DESIGN_TOKENS.md for the CSS variables).

# Component and layout patterns (framework-neutral)

The class and token names are semantic. Map them to the project's styling system (utility classes, CSS variables, theme props).

---

## App shell (authenticated product)
```
┌──────────────────────────────────────────────────────────┐
│ Top bar (sticky, 56px): logo · global search · alerts · avatar │
├──────────┬───────────────────────────────────────────────┤
│ Side nav │ Page header: title · description · [Secondary] [Primary] │
│ 240px    │───────────────────────────────────────────────│
│ (collap- │ Content: summary cards row → main table/list   │
│ sible to │          + optional right panel (320px)        │
│ 64px)    │                                                │
└──────────┴───────────────────────────────────────────────┘
Mobile: top bar + bottom tab bar (≤ 5 items) or a drawer; the page header actions collapse into an overflow menu.
```
**Rules:** one primary action per page header; breadcrumbs when nesting is deeper than two levels; content max-width from the tokens; keep the scroll position when navigating back.

## Page states (every data-backed view)
| State | Pattern |
|---|---|
| Loading | A skeleton matching the final layout (rows, cards). Show it only if loading takes longer than ~300 ms |
| Empty | An illustration or icon, a one-line explanation, and a primary action ("Create your first …") |
| Error | An inline alert with a human message, a retry action and a reference id; keep any already-loaded content visible |
| No permission | An explanation and who to contact; never a blank page |
| Partial / stale | A subtle banner "Showing cached data from <time>" with a refresh action |

## Data table
```
[Search] [Filter ▾] [Filter ▾]                      [Export] [+ New]
┌──┬──────────────┬──────────┬────────┬──────────┬───┐
│☐ │ Name ▲       │ Status   │ Owner  │ Updated  │ ⋯ │
├──┼──────────────┼──────────┼────────┼──────────┼───┤
│☐ │ Item A       │ ● Active │ Avatar │ 2h ago   │ ⋯ │
└──┴──────────────┴──────────┴────────┴──────────┴───┘
Showing 1–20 of 248                          ‹ Prev  1 2 3 …  Next ›
```
**Rules:** sortable columns show the direction; status uses badge + text (not color alone); row actions live in an overflow menu, plus bulk actions when rows are selected; numbers are right-aligned; on mobile, collapse to a card list; virtualize above about 200 rendered rows.

## Form
```
Section title
Helper text for the section

Label *                       Label
[ input              ]        [ select        ▾]
Hint text                     Error text (danger, with an icon)

                                    [Cancel] [Save changes]
```
**Rules:** labels above inputs; mark the required fields (or the optional ones, whichever is fewer); validate on blur, then on change; on submit, focus the first invalid field and show an error summary for long forms; disable submit only while it's submitting (with a spinner on the button); keep the input after an error; warn about unsaved changes when leaving.

## Card (summary / metric)
```
┌───────────────────────────┐
│ Label              (icon) │
│ 2,847                     │
│ +12.5% vs last period     │
└───────────────────────────┘
```
**Rules:** label `text-muted sm`; the value `2xl–3xl` with tight tracking; the trend uses icon + sign + text and semantic color; the whole card is clickable only if it navigates (then add a hover elevation and a focus ring).

## Dialog / modal
**Rules:** for blocking decisions only; a title that states the action; the body names the affected object; buttons are [Cancel] [Destructive or primary] with the destructive one in the danger color; focus is trapped while open and returns to the trigger on close; Esc and the backdrop close it, except during submission; on mobile, a full-height sheet.

## Toast / notification
**Rules:** for success and info confirmations; auto-dismiss after 4–6 s (pause on hover/focus); errors that block the user go inline, not in a toast; include an action ("Undo") where possible; announce through `aria-live="polite"`.

## Navigation
**Rules:** the current location is clearly indicated (it isn't only color); ≤ 7 top-level items; icons with labels; mobile bottom tabs for ≤ 5 primary destinations.

## Buttons
| Variant | Use |
|---|---|
| Primary | The main action of the view (one per area) |
| Secondary / outline | Alternative actions |
| Ghost / link | Tertiary, inline actions |
| Danger | Destructive actions (always confirmed, naming the object) |
States: default, hover, active, focus-visible, disabled, loading (spinner + keep the width).

## Search
Debounce 250–300 ms; show the result count; highlight matches; empty results suggest how to broaden the search; offer `/` or `Ctrl/Cmd+K` for a global search when the product has one.

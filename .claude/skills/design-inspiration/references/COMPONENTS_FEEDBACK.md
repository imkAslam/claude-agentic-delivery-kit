# Components: feedback and status

Build each from the project's UI library component and theme it with tokens. Reference systems: Polaris and Atlassian (messages and content), GOV.UK (errors), Material 3 (`UI_RESOURCES.md`). Wording: define-brand → VOICE_AND_TONE.md.

## Choosing the right feedback
| Situation | Use | Not |
|---|---|---|
| An action succeeded and nothing else is needed | A toast (auto-dismiss) or an inline change | A dialog |
| A field is wrong | A message next to the field | A toast |
| The whole form or section failed | An inline alert at the top of it | Only a toast that disappears |
| The system needs attention across the page (billing, maintenance, offline) | A banner | A dialog |
| A destructive action | A confirmation dialog, or do it and offer undo | A silent action |
| Something is loading | A skeleton (known shape), a spinner (short, unknown), a progress bar (long, measurable) | A frozen screen |

## Components
| Component | Use it for | Anatomy and sizes | States and behavior | Accessibility | Don't |
|---|---|---|---|---|---|
| **Toast** | Brief confirmation or a recoverable problem | One line (two at most), optional action ("Undo"); bottom or top corner, stacked max 3; 4–6 s, longer with an action; pauses on hover | info, success, warning, error (errors stay until dismissed) | A live region (`role="status"`, or `alert` for errors); reachable and dismissible by keyboard | Essential information only in a toast; a toast for every save in an autosaving form |
| **Inline alert** | A message tied to a section or form | Icon + title + one sentence + optional action; full width of its container; colored left border or tinted background from the status tokens | info, success, warning, danger; dismissible when not critical | `role="alert"` only when it appears in response to an action; icon and text, never color alone | Several stacked alerts; alerts as decoration |
| **Banner** | A system-wide condition | Full width under the top bar; one line; a link or button; one banner at a time by priority | info, warning, danger; dismissible unless action is required | A region with a label; not announced repeatedly on every page | Marketing in the same style as warnings |
| **Spinner** | A short wait of unknown length | 16–24 px inline, 32–48 px for a region; a label when the wait may exceed ~2 s ("Saving…") | shown after ~200 ms to avoid flashes | `role="status"` with a text label | A full-page spinner for content whose layout is known |
| **Progress bar** | A long or multi-step operation | A determinate bar with a percentage or "3 of 12"; indeterminate only when unknown; a cancel action for long jobs | running, paused, done, failed (reason + retry) | `role="progressbar"` with value, min and max | A fake progress bar; no way to leave the screen during a long job |
| **Page or section error** | Content that failed to load | An icon, a plain title ("We couldn't load your orders"), a sentence on what to do, Retry, and a way out; the rest of the page keeps working | first failure, retrying, failed again (offer support with a reference id) | Focus is not stolen; the message is announced | Stack traces or codes as the message; a blank area; an error that blanks the whole app |
| **Not found / no permission** | A missing page or a blocked area | A plain explanation, a link back to a safe place, and (for permission) who can grant access | — | A proper page title and heading | A raw 404; showing the feature and failing on click |
| **Notification center** | Messages that arrive while the user is elsewhere | A bell with an unread count (99+); a panel of items: who, what, when, link; mark as read and mark all; grouped by day | empty, unread, read, loading more, new arrivals | The count is in the button's name; a list with real links | Notifications for the user's own actions; a count that never clears |
| **Connection status** | Offline or reconnecting (realtime and mobile) | A small persistent indicator or banner; queued actions shown as pending | online, reconnecting, offline, back online (brief confirmation) | Announced politely once per change | Failing silently; blocking the whole UI while offline |
| **Onboarding hint** | Helping a first-time user start | An inviting empty state, a short checklist, or one contextual hint at a time; always skippable | not started, in progress, done, dismissed (and stays dismissed) | Hints are reachable by keyboard and do not trap focus | A multi-slide tour before the user has seen the product |

## Writing messages
- **Say what happened, why if known, and what to do next**, in the user's words: "We couldn't save your changes because the connection dropped. Try again."
- Success messages are short and specific ("Invoice sent to maria@example.com").
- Never blame ("You entered an invalid…"); never show internal codes alone; give a reference id only when support will ask for it.
- The same event uses the same words everywhere.

# Voice and tone

The **voice** is constant (who the product is). The **tone** adapts to the user's situation. The client approves legal and marketing copy; agents write the product microcopy within the approved voice.

## Voice traits (choose 3; write each as do / don't)
| Trait | Do | Don't |
|---|---|---|
| Clear | Short sentences, everyday words, one idea per sentence | Jargon, internal names, double negatives |
| Helpful | Say what happened and what to do next | Blame the user, leave dead ends |
| Confident | Active voice, plain verbs | Hedging ("might possibly"), exclamation marks everywhere |
| Warm | Address the user as "you", acknowledge effort | Forced jokes, slang that won't translate |

## Tone by context
| Context | Tone | Example |
|---|---|---|
| Onboarding, empty states | Encouraging, specific | "No projects yet. Create one to invite your team." |
| Success | Brief, factual | "Invoice sent to 3 clients." |
| Errors the user can fix | Calm, direct, actionable | "That email is already registered. Sign in instead?" |
| System failures | Honest, reassuring, with a next step | "We couldn't save your changes. Your draft is kept. Try again in a moment." |
| Destructive actions | Serious, explicit about the object and the consequence | "Delete project 'Apollo'? Its 42 tasks are deleted too. This can't be undone." |
| Security and privacy | Precise, no alarm | "We sent a sign-in link to j•••@example.com. It expires in 15 minutes." |

## Microcopy patterns
- **Buttons:** verb + object, sentence case ("Save changes", "Invite member"); the destructive button repeats the verb ("Delete", not "OK").
- **Labels:** nouns, no colon; helper text says the format or the reason; placeholders are examples, never the label.
- **Validation:** after blur; say how to fix it ("Use at least 12 characters"), not just "Invalid".
- **Empty states:** what will appear here + why it's empty + the next action.
- **Loading:** name the thing ("Loading invoices…"); for > 10 s, set expectations.
- **Confirmation:** a toast for reversible actions with "Undo"; a dialog only for destructive or costly ones.
- **Numbers, dates, money:** the user's locale; relative times under 7 days ("2 hours ago"), absolute beyond.
- **Inclusive language:** gender-neutral, no idioms that don't translate, no ableist metaphors.
- **Internationalization:** allow +30% text length; never build sentences from fragments; keep strings in the i18n files.

## Word list (fill per project; reviewers check it)
| Use | Avoid | Why |
|---|---|---|
| Sign in / sign out | Log in, login (as a verb) | Consistency |
| Delete | Remove (when it's permanent) | Clarity about the consequence |
| <product term> | <synonyms> | One name for one concept (matches the BA glossary) |

## Copy deck (in UI-UX.md)
| String id | Screen / state | Text | Notes (max length, variables) |
|---|---|---|---|
| S-03.empty.title | S-03 empty | No orders yet | ≤ 40 chars |

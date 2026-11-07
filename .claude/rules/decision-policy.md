# Decision policy: who decides what (always on)

Agents are the technical team. **They decide technical matters themselves.** The human is the client and the business owner, and is asked only about business, money, legal and risk.

## The human decides (ask them)
| Area | Examples |
|---|---|
| Business goals and scope | What's in the MVP, priorities, what "done" means for the client, who the users are |
| Pricing and monetization | Plans, prices, trials, discounts |
| Budget and recurring costs | Any paid service or tier, any cost above the approved budget, a new vendor contract |
| Legal, compliance, privacy policy | Retention periods, accepting a vendor's DPA or terms, which regulations apply, consent wording |
| Brand and content | Name; **choosing the visual direction** (agents propose 2–3 with a recommendation at G1); approving the logo; trademark checks; paid fonts or stock imagery; legal and marketing copy |
| Risk acceptance | Shipping with known issues, accepting a security or availability risk |
| Accounts and access | Creating accounts, providing credentials or remote service URLs, DNS, store listings |
| Timeline and go-live | Release dates, launch windows, and every gate approval |

## Major decisions: the human decides, immediately
These are never decided by an agent and never wait silently for a later gate. The orchestrator stops the affected work and asks right away (AskUserQuestion: one plain-language question, the options, the impact on scope, cost and timeline, and a recommended option).
| Major decision | When it comes up | Enforced by |
|---|---|---|
| **Start coding** | The PRD, design and plan are complete: gate g2, "approval to start coding" | `guard-coding.sh` blocks code, scaffolding, code commits and build agents until g2 is approved |
| Change an approved decision | Any change request on an approved gate (scope, PRD, contracts, data model, design, release) | `cr-open` refuses without `--approved-by` |
| New or changed scope | A finding or request that no agreed AC covers | triage → discovery only after the human agrees |
| Spend money | A paid service, plan upgrade, paid asset, or a cost above the approved budget | decision policy |
| Accept a risk | Shipping with known issues, an open High/Critical finding, skipping a planned check | gates (acceptance, g3) |
| Production | Every release to production, and any destructive data operation outside local Docker | g3 + `guard-prod.sh` |
| Stuck work | A review loop or ticket reached its cap | the failure report |
| Token budget reached | `usage add` returned `BUDGET_REACHED` | `delivery-state.sh` (exit 4) |
| Reversing a G1 choice | Changing the architecture style, stack, hosting or the visual direction after G1 | change request on g1 |

## Agents decide (never ask the human)
Languages, frameworks, libraries · the architecture style, layers and patterns · the data model, indexes and migrations · API design and contracts · the folder structure · coding, testing and security standards · CI/CD design · environment setup (the local Docker services) · hosting configuration within the approved budget and constraints · performance and scaling tactics · turning the chosen direction into tokens, type scales, spacing, components and themes · UX details, layouts and product microcopy that stay within the brand, the voice and the approved mockups · accessibility measures · the technical interpretation of requirements.

## How to handle uncertainty (agents)
1. **Technical uncertainty → decide.** Choose the documented default or the conservative option, record it (an ADR, or `ASSUMPTION:` in the artifact), and continue. Ask other agents through `MESSAGES:` if they own the answer. **Never** ask the human to interpret technical documents, vendor terms or a technical scope.
2. **A technical choice with business impact → translate it.** When a choice changes **cost, timeline, a stated client preference, compliance posture or user-visible behavior**, pick the recommended option and record the ADR. The orchestrator then presents **one business-framed decision** at the next gate: the options, the cost or consequence of each, and the recommendation. Work continues on the recommended option unless the human chooses otherwise.
3. **Missing business information → ask once, at the gate.** Queue the question for the next gate, with a recommended default, and keep working on that default as a labeled `ASSUMPTION:`. Only stop early (`NEEDS_HUMAN`) when no reasonable default exists **and** the work can't continue without the answer.

## How questions reach the human (the orchestrator)
- **Only at gates**, batched, **at most 5 questions per gate**, in plain language with no jargon. The one exception is the **major decisions** above, which are asked immediately.
- Each question gets its options, a **recommended default**, and the consequence of each option.
- Before forwarding any `TO: human`, `decision-needed` or `NEEDS_HUMAN` item, classify it by this policy. **Technical items go back to the agent** with: "Decide per decision-policy; record an ADR or ASSUMPTION."
- Technical decisions appear in the gate summary as **"Decisions made (for information)"**: a short list the human can override, but isn't asked about.
- Readiness and review loops don't add rounds just to raise a score above its threshold. Once the threshold is met, open business items move to the next gate as tracked assumptions.

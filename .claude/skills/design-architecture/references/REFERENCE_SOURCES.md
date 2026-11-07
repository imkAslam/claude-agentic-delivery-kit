# Architecture research: sources and procedure

The solution-architect researches **before** choosing. The goal is the most widely proven, scalable architecture that fits *this* PRD, backed by fetched evidence and not by memory.

## Authoritative sources (tier 1: prefer these)
| Source | Use it for | URL |
|---|---|---|
| AWS Well-Architected Framework (+ AWS Architecture Center) | Pillars (reliability, performance, cost, security, operations, sustainability), reference architectures | https://aws.amazon.com/architecture/well-architected/ · https://aws.amazon.com/architecture/ |
| Azure Architecture Center + Well-Architected | Architecture styles, cloud design patterns, reference architectures | https://learn.microsoft.com/azure/architecture/ |
| Google Cloud Architecture Framework + Center | Design principles, reference architectures | https://cloud.google.com/architecture/framework · https://cloud.google.com/architecture |
| The Twelve-Factor App | Cloud-native app principles | https://12factor.net |
| C4 model | How to diagram context, containers, components | https://c4model.com |
| microservices.io (pattern language) | Decomposition, data, messaging, saga, outbox patterns | https://microservices.io/patterns/ |
| martinfowler.com (architecture guides) | Modular monoliths, CQRS, event sourcing, evolutionary architecture | https://martinfowler.com/architecture/ |
| OWASP ASVS / Cheat Sheet Series | Security architecture requirements | https://owasp.org/www-project-application-security-verification-standard/ · https://cheatsheetseries.owasp.org |
| Official framework and database documentation | Capabilities, deployment guidance, limits, scaling notes | the vendor's docs site |

## Tier 2 (supporting evidence)
Thoughtworks Technology Radar (https://www.thoughtworks.com/radar) for adoption signals · the System Design Primer (https://github.com/donnemartin/system-design-primer) for scalability building blocks · well-known engineering blogs from companies operating at scale, for case studies (use them as examples, not as rules).

**Not acceptable as sole evidence:** marketing pages, anonymous posts, SEO listicles, or AI-generated summaries with no primary source.

## Procedure
1. **State the drivers** from the PRD: users and growth, read/write mix, latency, availability, realtime, offline, data sensitivity and compliance, integrations, team skills, budget, hosting constraint.
2. **Shortlist 3 candidate architectures** from [ARCHITECTURE_PATTERNS.md](ARCHITECTURE_PATTERNS.md) (one should be the simplest option that could work).
3. **Search.** Example queries:
   - `"reference architecture" <domain> <cloud or hosting target>`
   - `<pattern> "when to use" site:learn.microsoft.com/azure/architecture`
   - `well-architected <workload type> scalability`
   - `<framework> production deployment scaling guide` (official docs)
   - `<database> horizontal scaling limits` (official docs)
4. **Fetch** at least **5 sources**: at least 2 tier-1 cloud architecture sources, at least 1 pattern source (microservices.io or Fowler), and the official docs for each technology you choose. Record the URL, title, fetch date and the specific claim each one supports.
5. **Score** the candidates in the weighted matrix ([STACK_SELECTION.md](STACK_SELECTION.md)), adding the evidence column.
6. **Decide** the style, then build the **layer-by-layer blueprint** ([LAYERED_BLUEPRINT.md](LAYERED_BLUEPRINT.md)) and the **folder structure** ([FOLDER_STRUCTURES.md](FOLDER_STRUCTURES.md)).
7. **Write** `docs/delivery/ARCHITECTURE-RESEARCH.md` ([ARCH_RESEARCH_TEMPLATE.md](ARCH_RESEARCH_TEMPLATE.md)) and an ADR for the style.

## Rules
- Cite only the pages you actually fetched. If one fails to load, say so and use another source.
- Summarize in your own words; quote a few words at most.
- Mark each recommendation *evidence-backed* (with its citations) or *judgment*.
- Popular doesn't mean right. A pattern only wins when its "use when" conditions match the drivers.
- If the evidence conflicts, present both sides and the condition that decides between them. The human decides at G1 if it matters.

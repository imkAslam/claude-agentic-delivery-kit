# Object-oriented design, domain modeling and patterns

Applies in every language, including ones that aren't class-based (the ideas map to modules, structs and functions).

## 1. SOLID, in practice
| Principle | Means | You're violating it when |
|---|---|---|
| **S**ingle responsibility | One reason to change per class/module | A class handles HTTP, rules and SQL; the name needs "And" or "Manager" |
| **O**pen/closed | Add behavior by adding code, not editing stable code | Every new payment type adds an `if` to the same `switch` |
| **L**iskov substitution | A subtype works wherever its parent does | An override throws `NotSupported` or ignores a parameter |
| **I**nterface segregation | Small, client-specific interfaces | Implementers stub out methods they don't need |
| **D**ependency inversion | Depend on abstractions you own; inject the details | Domain code imports the ORM, an HTTP client or a vendor SDK |

## 2. Class and module design
- **Cohesion high, coupling low.** Things that change together live together; modules talk through small public surfaces.
- **Encapsulate state and enforce invariants in the constructor/factory.** An object is valid from the moment it exists; no public setters that can break it. Prefer methods that express intent (`order.cancel(reason)`) over setters (`order.status = 'cancelled'`).
- **Tell, don't ask.** Ask an object to do the work instead of pulling its data out and deciding for it. Respect the Law of Demeter: no `a.b().c().d()` chains into other objects' internals.
- **Composition over inheritance.** Inherit only for a true is-a relationship with a stable base; at most one level of implementation inheritance in application code. Share behavior through composition, interfaces/traits or plain functions.
- **Immutability by default.** Value objects are immutable; entities change only through their methods.
- **Small interfaces defined by the consumer** (a port the domain needs), implemented by infrastructure (an adapter).
- **No static mutable state and no singletons holding state.** Use dependency injection; a DI container's singleton lifetime is fine for stateless services.
- **Functional core, imperative shell.** Keep decisions in pure functions/methods; push I/O to the edges where it's easy to fake in tests.

## 3. Domain modeling (tactical DDD, used where the domain has real rules)
| Building block | Use for | Rules |
|---|---|---|
| **Value object** | Money, email, date range, address, ids | Immutable, compared by value, validates itself |
| **Entity** | Things with identity and a lifecycle (Order, Invoice) | Identity is stable; state changes through methods that enforce BR- rules |
| **Aggregate** | A consistency boundary (Order + its lines) | Changed only through its root; one aggregate per transaction; reference other aggregates by id |
| **Repository** | Loading/saving aggregates | Interface in the domain, implementation in infrastructure; returns domain objects, not rows |
| **Domain service** | A rule that spans aggregates and belongs to none | Stateless; named after the domain operation |
| **Application service / use case** | One user intention (PlaceOrder) | Orchestrates: load → call domain → save → publish; owns the transaction; no business rules inside |
| **Domain event** | Something that happened (OrderPlaced) | Past tense, immutable; published after commit (outbox) |
For CRUD-only areas with no rules, a thin service over a repository is enough. Don't build aggregates for forms.

## 4. Design patterns: when to use, when not
| Pattern | Use when | Avoid when |
|---|---|---|
| **Factory / factory method** | Creation has rules or picks an implementation | `new` with valid arguments is enough |
| **Builder** | Many optional parameters; test data builders | Two or three required fields |
| **Singleton** | Never hand-rolled; let the DI container manage lifetimes | Always, as a global access point |
| **Adapter** | Wrapping a vendor SDK or legacy API behind your port (anti-corruption layer) | You own both sides |
| **Facade** | One simple entry point over a complex subsystem | It becomes a god object; keep it thin |
| **Decorator** | Adding cross-cutting behavior (caching, retry, metrics) around a port | The behavior is core logic |
| **Proxy** | Lazy loading, access control, remote stubs | Plain delegation adds nothing |
| **Composite** | Tree structures treated uniformly (menus, rule trees) | Flat lists |
| **Strategy** | Interchangeable algorithms chosen at runtime (pricing, tax, payment provider) | One algorithm; a function parameter is enough |
| **Template method** | Rarely; prefer Strategy or composition | Deep inheritance hierarchies |
| **Observer / domain events** | Decoupling side effects from the action (notify, index, audit) | The caller needs the result synchronously |
| **Command** | Queued, logged, undoable or retried operations; CQRS writes | Simple method calls |
| **Chain of responsibility / middleware** | Pipelines: validation, auth, logging | Business decisions that need the whole context |
| **State machine** | Entities with explicit lifecycles (order, ticket, subscription) | Two states and one transition |
| **Specification** | Reusable, composable business predicates | One-off filters |
| **Repository + Unit of Work** | Persistence behind a domain interface, one transaction per use case | Read-only reporting (query directly) |
| **Ports and adapters (hexagonal)** | The default layering (LAYERED_BLUEPRINT) | — |
| **CQRS** | Read and write models differ a lot, or reads need their own scaling (by ADR) | Ordinary CRUD |
| **Outbox** | Publishing events/messages reliably with a DB change | No external side effects |
| **Saga / process manager** | Multi-step workflows across services or providers with compensation | A single transaction can do it |
| **Circuit breaker, retry with backoff, bulkhead, timeout** | Every remote dependency | In-process calls |

## 5. Anti-patterns reviewers flag
God class or "Manager/Helper/Util" dumping ground · anemic domain where the rules live in controllers · primitive obsession (strings for money, ids and emails) · boolean flag parameters (`send(true, false)`) · deep inheritance · service locator / reaching into the container · feature envy (a method using another object's data more than its own) · shotgun surgery (one change touches ten files) · temporal coupling (methods that must be called in an order nobody enforces) · leaky abstractions (ORM entities or vendor types in API responses or the domain) · copy-pasted business rules · speculative generality (interfaces with one implementation "for later", unless it's a port the tests need).

## 6. Review checklist
- [ ] Each class/module has one responsibility and a name from the domain.
- [ ] Invariants enforced at construction; no public mutable state; intent-revealing methods.
- [ ] Domain code has no framework, ORM, HTTP or SDK imports; dependencies injected.
- [ ] Composition used over inheritance; no hierarchy deeper than one implementation level.
- [ ] Patterns used only where §4 says they pay off; none of the §5 anti-patterns introduced.
- [ ] Use cases own the transaction; side effects after commit.

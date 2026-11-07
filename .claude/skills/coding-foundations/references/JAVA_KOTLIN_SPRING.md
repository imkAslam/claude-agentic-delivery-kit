# Java / Kotlin with Spring Boot guide

With: OOP_AND_PATTERNS.md.

## Tooling (must)
- Pinned JDK (LTS) and Spring Boot versions; Gradle or Maven wrapper committed; Spotless (google-java-format/ktlint), Checkstyle or detekt, SpotBugs/Error Prone; tests and static analysis in CI.

## Structure
- Package by feature (`orders/api`, `orders/application`, `orders/domain`, `orders/infrastructure`); enforce layer rules with ArchUnit or Spring Modulith.
- Domain classes free of Spring and JPA annotations where the domain has real rules; JPA entities in infrastructure map to and from domain objects (or are kept rich but never exposed in APIs).

## Spring (must)
- **Constructor injection only** (no field `@Autowired`); `final` fields (Java) or `val` (Kotlin).
- Controllers thin: validate (`@Valid` + Bean Validation on DTOs), call one application service, return response DTOs (Java `record`s / Kotlin `data class`es). Never return entities. The server rules mirror the form rules exactly (FORMS_AND_VALIDATION.md).
- `@Transactional` on application-service public methods (Spring proxies don't apply to self-invocation or private methods); read-only transactions for queries; no remote calls inside transactions.
- One `@RestControllerAdvice` mapping domain exceptions to the contract's error body (ProblemDetails where the contract uses it).
- Typed configuration with `@ConfigurationProperties` + validation; profiles per environment; secrets from the environment.
- `spring.jpa.open-in-view=false`.

## JPA / data
- `LAZY` fetching for associations; fetch joins, entity graphs or DTO projections per query to avoid N+1; pagination on every list; optimistic locking with `@Version` where concurrent edits matter.
- Migrations with Flyway or Liquibase only (never `ddl-auto` outside local tests).

## Kotlin specifics
- Null-safety used, not bypassed: no `!!` except with a comment; `data class` for DTOs/value objects; sealed classes for results and states; coroutines with structured concurrency and timeouts if the stack uses WebFlux/coroutines.

## Resilience and observability
- HTTP clients (RestClient/WebClient) with connect and read timeouts; Resilience4j for retries and circuit breakers; Micrometer metrics and tracing; structured JSON logs with MDC request id.

## Testing
- JUnit 5; slice tests (`@WebMvcTest`, `@DataJpaTest`) for layers; Testcontainers for the database and brokers; MockK (Kotlin) or Mockito sparingly, preferring fakes.

## Review checklist
- [ ] Constructor injection; no entities in API responses; DTOs validated.
- [ ] Transactions on public service methods only; none around remote calls.
- [ ] No N+1 (fetch plans/projections); `open-in-view` off; migrations via Flyway/Liquibase.
- [ ] One exception handler; timeouts on clients; Kotlin without `!!`.

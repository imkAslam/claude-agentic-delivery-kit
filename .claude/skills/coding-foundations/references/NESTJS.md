# NestJS guide

With: NODE.md, TYPESCRIPT.md, OOP_AND_PATTERNS.md. Templates: `create-endpoint/references/BACKEND_TEMPLATES.md` (NestJS section).

## Modules and layering
- **One module per feature/bounded context** (`OrdersModule`), exporting only the providers other modules need. A `SharedModule`/`CoreModule` only for genuinely cross-cutting providers (config, logging, DB).
- **Controllers are thin:** map HTTP ↔ DTOs, call one use case/service, return the response DTO. No business rules, no repository calls in controllers.
- Services/use cases hold the application logic; domain classes hold the rules; repositories are providers behind an interface token (`@Inject(ORDER_REPOSITORY)`), so the ORM (Prisma, TypeORM, MikroORM, Drizzle) stays in infrastructure.
- **No circular module dependencies.** `forwardRef()` is a design smell that needs an ADR; split the module or introduce an event instead.

## Dependency injection
- Constructor injection only. Default (singleton) scope for stateless providers. **Avoid request-scoped providers**: the scope propagates up the injection chain and costs performance; use `AsyncLocalStorage` (e.g. `nestjs-cls`) for request context.
- Custom providers (`useFactory`, `useClass`) for configuration-dependent wiring; interface tokens as `Symbol`/string constants, not classes from other layers.

## Validation and DTOs
- Global `ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true })` (class-validator), or a zod pipe if the project chose zod. DTOs live at the edge; never expose ORM entities in responses. The server rules mirror the form rules exactly (FORMS_AND_VALIDATION.md).
- Response DTOs (or serializers) control output; `ClassSerializerInterceptor` with `@Exclude`/`@Expose` where class-transformer is used.
- Swagger decorators must match the frozen contract; if codegen from the contract exists, implement the generated interfaces instead of hand-writing them.

## Cross-cutting
- **Guards** for authentication and authorization (roles/policies, plus object-level checks in the service); **interceptors** for logging, timeouts and response mapping; **pipes** for validation/transformation; **one global exception filter** mapping domain errors to the contract error body.
- `ConfigModule.forRoot({ validationSchema | validate })`, typed config via a namespaced `registerAs`; fail at startup on invalid config.
- `app.enableShutdownHooks()`; close pools and queues in `onModuleDestroy`/`beforeApplicationShutdown`.
- Structured logging through a Nest logger adapter (pino via `nestjs-pino`).
- Transactions per use case (Prisma `$transaction`, TypeORM `DataSource.transaction`/query runner); no transaction spanning a network call.
- `@nestjs/cqrs`, microservices transport and event emitters only by ADR.

## Testing
- Unit: instantiate services with fakes, or `Test.createTestingModule` with overridden providers. E2E: boot the app module against containers, call with supertest, test guards with and without credentials.

## Review checklist
- [ ] Feature module boundaries respected; no `forwardRef` without an ADR.
- [ ] Controllers thin; ORM entities never returned; DTOs validated with whitelist + forbid.
- [ ] Guards on every protected route + object-level checks in services.
- [ ] One exception filter maps domain errors to the contract's error body.
- [ ] No new request-scoped providers; config validated; shutdown hooks enabled.

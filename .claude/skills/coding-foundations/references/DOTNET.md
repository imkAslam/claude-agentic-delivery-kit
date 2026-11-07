# C# / ASP.NET Core guide

With: OOP_AND_PATTERNS.md.

## Tooling (must)
- Pinned SDK (`global.json`); `<Nullable>enable</Nullable>`, `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>`, analyzers on (`AnalysisLevel` latest); `dotnet format` in CI; central package management.

## Structure
- Feature folders or Clean Architecture projects (Domain, Application, Infrastructure, Api) with project references enforcing the dependency rule.
- Records for DTOs and value objects; `sealed` classes by default; `required` and `init` properties for valid construction.

## DI and configuration (must)
- Register lifetimes correctly: stateless services singleton or scoped; `DbContext` scoped; **never inject a scoped service into a singleton**.
- Options pattern with validation (`AddOptions<T>().BindConfiguration(...).ValidateDataAnnotations().ValidateOnStart()`); secrets from environment or a secret store.
- `IHttpClientFactory` (typed clients) with timeouts and Polly/`Microsoft.Extensions.Http.Resilience` policies; never `new HttpClient()` per call.

## Async (must)
- Async all the way: no `.Result`, `.Wait()` or `async void` (except event handlers); pass `CancellationToken` through every I/O call; `ConfigureAwait(false)` in library code.

## API
- Minimal APIs or controllers, thin; validation with FluentValidation or data annotations; responses are DTOs; errors as `ProblemDetails` through one exception handler (`IExceptionHandler`/`UseExceptionHandler`).
- Authorization policies plus resource-based checks in handlers/services.

## Data (EF Core)
- `AsNoTracking()` for reads; projections (`Select`) to DTOs for lists; explicit `Include` per query, no lazy-loading proxies; pagination on every list; concurrency tokens where concurrent edits matter; migrations reviewed and applied by the pipeline.

## Logging
- `ILogger<T>` with message templates (`logger.LogInformation("Order {OrderId} placed", id)`), never string interpolation in log calls; source-generated `LoggerMessage` on hot paths; OpenTelemetry for traces and metrics.

## Testing
- xUnit (or NUnit); `WebApplicationFactory` for API tests; Testcontainers for the database; fakes over mocks where possible.

## Review checklist
- [ ] Nullable warnings clean; warnings as errors.
- [ ] No sync-over-async; cancellation tokens passed.
- [ ] Lifetimes correct; options validated on start; typed HttpClients with timeouts.
- [ ] EF Core reads untracked and projected; no lazy loading; no N+1.
- [ ] ProblemDetails via one handler; structured log templates.

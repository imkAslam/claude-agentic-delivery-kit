# AI and LLM integration guide

With: [INTEGRATION_PATTERNS.md](INTEGRATION_PATTERNS.md), [RESILIENCE.md](RESILIENCE.md), [PROVIDER_CATALOG.md](PROVIDER_CATALOG.md), `.claude/rules/integrations.md`, `.claude/rules/secure-coding.md`, and the threat model's prompt-injection controls.

## 1. Where the model sits
- A use case asks for a domain result ("summarize this order's notes") through a port. The adapter wraps the provider SDK or HTTP API. The architect chooses the SDK or framework (for example the Vercel AI SDK, the OpenAI or Anthropic SDK, LangChain or LlamaIndex) and records it in an ADR.
- Domain code never imports a provider SDK. Model names, endpoints and keys come from configuration, not from code. Do not hard-code a model ID, because models are retired and replaced.
- Each adapter maps provider errors into the domain's error types.

## 2. Calls
- Every call has a timeout. Long answers stream through a route handler (server-sent events or the framework's stream response), and the client cancels the stream when the user leaves.
- Retry only errors that are safe to retry (rate limit, transient server error), with backoff and jitter, and a cap on attempts.
- Limit requests per user and per tenant, and cap input and output size per call.
- Set a token budget per feature and record tokens and cost per call. The budget amount and any spending limit are business items for the client.

## 3. Security and safety
- Treat retrieved documents, user input and tool output as untrusted (prompt injection). Never let model output change permissions, run commands or send messages without a separate check in the application.
- Tools the model can call are an explicit allow-list. Each tool validates its arguments against a schema and checks the user's permission on the server.
- Validate model output against a schema before the application uses it. Never render model output as HTML without sanitizing it.
- Send only the data the feature needs. Personal or sensitive data goes to a provider only when the data-classification and the client's approval allow it.
- Logs record the call's metadata (model, tokens, latency, outcome). Prompts and answers are logged only if they contain no personal data, or are redacted.
- Content moderation is added when the product or the provider requires it.

## 4. Retrieval (RAG), when needed
- Store embeddings in the project's existing database (for PostgreSQL, the `pgvector` extension) inside the same local container, so no second service is added.
- The embedding dimension is part of the configuration and the migration; changing the embedding model means re-embedding, so record it as a migration step.
- Index the vectors for the similarity search and check the query plan (design-database, INDEXING_AND_PERFORMANCE.md).
- Chunk documents by meaning (headings, paragraphs), keep the source reference with each chunk, and show the source to the user where the answer depends on it.

## 5. Local development and tests
- Use a deterministic local adapter with recorded fixtures for tests and for offline development (PROVIDER_CATALOG.md). Tests never call a live model.
- Contract-test the mapping from the provider's response to the domain type.
- Provider keys are environment variables, named in `.env.example` and in `deploy.required_secrets`. Never put a key in code, a fixture or a log.

## 6. Checklist
- [ ] Domain code uses a port; the provider SDK lives in the adapter.
- [ ] No model ID or key in code; configuration only.
- [ ] Timeouts on every call; retries only for safe errors, with backoff and jitter.
- [ ] Per-user limits, input and output size caps, and a token budget per feature.
- [ ] Untrusted text cannot change permissions or trigger actions; tools allow-listed and checked on the server.
- [ ] Model output validated against a schema and sanitized before rendering.
- [ ] Only the data the feature needs leaves the system; logs hold no personal data.
- [ ] Tests use fixtures; no test calls a live model.

# Observability guide

With: `.claude/rules/coding-standards.md` (logging and observability), [NODE.md](NODE.md), [PYTHON.md](PYTHON.md), [FASTAPI.md](FASTAPI.md), [REACT.md](REACT.md), [NEXTJS.md](NEXTJS.md). The architecture's monitoring plan is in `ARCHITECTURE.md › Operations`.

## 1. What every service emits (must)
- **Structured logs** in JSON with level, message, request id and the relevant entity ids. Redact authorization headers, cookies, passwords and tokens by name.
- **Health endpoints:** a liveness check that does not call dependencies, and a readiness check that tests each dependency with a short timeout. Public responses show status only, never internal details.
- **Error tracking:** one tracker for the project (Sentry or the one `PROJECT.md` names), for unhandled errors on the server and in the browser. Turn on PII scrubbing, and tag each event with the environment and the release.
- **Metrics and traces:** the golden signals (latency, traffic, errors, saturation) and one span per external call.

## 2. Logging by stack
- **Node:** pino (or the framework's structured logger), with a redaction list and a request id from AsyncLocalStorage (NODE.md). Pretty printing only in development.

  ```ts
  const logger = pino({
    level: config.logLevel,
    redact: ['req.headers.authorization', 'req.headers.cookie', '*.password', '*.token'],
  });
  ```
- **Python:** structlog or the standard logging module with a JSON renderer in production. The request id lives in a context variable set by middleware (FASTAPI.md).
- **Browser:** no `console` output in production code. Send errors to the tracker through the error boundary. Keep personal data out of breadcrumbs and URLs.

## 3. Error tracking
- Initialize the SDK at startup from configuration. The DSN is an environment variable by name; a browser DSN uses the framework's public prefix and is not a secret.
- **Server:** capture unknown errors in the one error mapper. Expected domain errors (validation, not found, conflict) are not sent to the tracker.
- **Browser:** an error boundary around each route or section reports the error and shows the fallback. React error boundaries are class components, so use one shared boundary; Next.js also has `error.tsx` per NEXTJS.md.

  ```tsx
  class ErrorBoundary extends Component<{ fallback: ReactNode; children: ReactNode }, { failed: boolean }> {
    state = { failed: false };
    static getDerivedStateFromError() { return { failed: true }; }
    componentDidCatch(error: Error, info: ErrorInfo) { reportError(error, info.componentStack); }
    render() { return this.state.failed ? this.props.fallback : this.props.children; }
  }
  ```
- Upload source maps in CI so stack traces are readable, and keep them out of the public bundle.

## 4. Health checks and deploys
- The deploy's smoke test calls the readiness endpoint (see `ship` for each target's health path).
- A failed readiness check during a release is a rollback trigger in the release package (`release-docs`).

## 5. Alerts and dashboards
- Alerts and dashboards are defined from the golden signals and listed in `ARCHITECTURE.md › Operations`. The release package's runbook links to them.
- Alerts name an owner and a first action. An alert nobody acts on is removed, not muted.

## 6. Review checklist
- [ ] Logs are structured, carry a request id and redact secrets and personal data.
- [ ] Liveness does not depend on other services; readiness has timeouts.
- [ ] Unknown errors reach the tracker; expected errors do not.
- [ ] Each route or section has an error boundary that reports and shows a fallback.
- [ ] The DSN and other keys come from configuration by name.
- [ ] Source maps are uploaded in CI and not published.
- [ ] Events carry the environment and the release.

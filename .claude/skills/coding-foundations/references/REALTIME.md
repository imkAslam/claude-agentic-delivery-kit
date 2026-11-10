# Realtime guide (SSE, WebSockets, WebRTC)

Read only when ARCHITECTURE names a realtime channel. With: the stack guide, PERFORMANCE.md, `secure-coding.md`. The channel choice is the architect's (design-architecture → ARCHITECTURE_PATTERNS §5), recorded in an ADR.

## 1. Choosing the transport
| Need | Use | Notes |
|---|---|---|
| Server → client updates (notifications, feeds, progress, dashboards) | **Server-Sent Events** | Plain HTTP, automatic reconnect, simplest to operate. The default |
| Two-way, low latency (chat, presence, collaboration) | **WebSockets** (a library with rooms and fallbacks, or a managed realtime service) | Needs sticky sessions or a pub/sub backplane to scale out |
| Audio, video or peer-to-peer data | **WebRTC** with a signalling channel and TURN | A managed media service unless the ADR says otherwise |
| Updates every 30 s or slower | **Polling** with caching headers | Often enough; no new infrastructure |
Serverless hosts usually can't hold long connections: check the hosting fit before choosing.

## 2. Contract (must)
- Events are part of the contracts: name, direction, payload schema, who may receive it. Use the project's contract format for async APIs (e.g. AsyncAPI, or typed event definitions in `packages/contracts`), frozen at G2 like the rest.
- Event names: `domain:action` in lowercase (`message:new`, `order:status-changed`). Version a payload by adding fields, never by changing meaning.
- Every event carries an id and a timestamp so clients can de-duplicate and order.

## 3. Server (must)
- **Authenticate at the handshake** with the same session or token as the API; reject unauthenticated connections. Check the `Origin` for browser clients.
- **Authorize every subscription and every inbound message:** joining a room or channel checks the user's access to that resource, on the server, each time. Never trust a room name sent by the client.
- **Validate every inbound message** against its schema; drop and log invalid ones. Limit message size and rate per connection.
- Emit events from the application layer **after the transaction commits** (or through the outbox), never from inside it.
- Heartbeats (ping/pong or SSE comments) detect dead connections; idle and maximum lifetimes close them; tokens are re-checked on reconnect.
- Scale out with a pub/sub backplane (e.g. the cache's pub/sub or a broker) so an event reaches clients on every instance; keep per-connection state out of process memory where possible.
- Graceful shutdown: stop accepting, tell clients to reconnect, close within the deadline.
- No sensitive data in events beyond what the receiver may see through the API; send ids and let the client fetch when in doubt.

## 4. Client (must)
- **One connection per app,** owned by a provider or service (`lib/realtime` + a provider); components subscribe through a hook or composable and always unsubscribe on unmount.
- **Reconnect with exponential backoff and jitter,** capped; after reconnecting, **resync** (refetch or request missed events since the last id). Never assume no events were missed.
- **Merge events into the server-state cache** (update or invalidate the query), not into a second copy of the data.
- Show connection status when data may be stale; queue or disable sends while offline; make sends idempotent (client-generated ids).
- Batch bursts of events before rendering; throttle high-frequency signals (typing, cursor, presence).
- Tokens are never placed in the URL query string where logs can capture them, unless the transport leaves no alternative and the token is short-lived and single-use.

## 5. Testing
- Unit: event handlers and reducers with typed payloads. Integration: a real server instance, two clients, authorization on join, invalid message rejected, delivery across two instances when a backplane is used.
- E2E: one journey per realtime feature (send in one session, see it in another), plus reconnect-and-resync.

## Review checklist
- [ ] The transport matches the need and the hosting; the ADR exists.
- [ ] Events are in the contracts with schemas, ids and timestamps; names follow `domain:action`.
- [ ] Handshake authentication, per-subscription and per-message authorization, origin check.
- [ ] Inbound messages validated, size- and rate-limited.
- [ ] Events emitted after commit; a backplane is in place when there is more than one instance.
- [ ] Client: one shared connection, cleanup on unmount, backoff with jitter, resync after reconnect, cache merge.
- [ ] Heartbeats and graceful shutdown; no secrets or excess personal data in payloads.

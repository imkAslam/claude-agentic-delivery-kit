# Webhook templates

Skeletons that show the **shape**: verify, record, enqueue, answer. Replace names with the project's; keep the order of the steps. Use the provider's official SDK verifier where one exists (it handles the scheme's details); the manual version below is for providers without one.

## The four steps (every stack)
```text
1. raw = the exact bytes of the request body          (before any JSON parsing)
2. verify(raw, headers, secret)  → reject 400 on failure; reject when |now - timestamp| > 5 min
3. insert webhook_events(provider, event_id, type, payload, received_at)
     unique violation → return 200 (already received)
4. enqueue process_webhook(event row id) → return 200
```

## Node / Next.js Route Handler (TypeScript)
```ts
/** Receives <provider> events: verifies the signature over the raw body, stores the event once, queues the work. */
export async function POST(req: Request): Promise<Response> {
  const raw = await req.text();                                   // raw body: never req.json() first
  const result = verifySignature(raw, req.headers, env.PROVIDER_WEBHOOK_SECRET);
  if (!result.ok) { log.warn({ provider: 'provider', reason: result.reason }, 'webhook rejected'); return new Response(null, { status: 400 }); }
  const event = InboundEvent.parse(JSON.parse(raw));              // schema validation after verification
  const stored = await webhookEvents.insertOnce({ provider: 'provider', eventId: event.id, type: event.type, payload: raw });
  if (stored.inserted) await queue.enqueue('process-webhook', { id: stored.id });
  return new Response(null, { status: 200 });
}

/** HMAC-SHA256 over "<timestamp>.<raw body>", compared in constant time; rejects old timestamps. */
function verifySignature(raw: string, headers: Headers, secret: string): { ok: boolean; reason?: string } {
  const ts = Number(headers.get('x-timestamp')); const sig = headers.get('x-signature') ?? '';
  if (!ts || Math.abs(Date.now() / 1000 - ts) > 300) return { ok: false, reason: 'stale' };
  const expected = createHmac('sha256', secret).update(`${ts}.${raw}`).digest('hex');
  const a = Buffer.from(expected); const b = Buffer.from(sig);
  return a.length === b.length && timingSafeEqual(a, b) ? { ok: true } : { ok: false, reason: 'signature' };
}
```
Frameworks that parse the body for you (Express, NestJS, Fastify) need the raw body kept: register the raw-body option or a route-level raw parser for the webhook path only.

## Python / FastAPI
```python
@router.post("/webhooks/provider", status_code=200)
async def receive_provider_webhook(request: Request) -> Response:
    """Receives <provider> events: verifies the raw body's signature, stores the event once, queues the work."""
    raw = await request.body()
    if not verify_signature(raw, request.headers, settings.provider_webhook_secret):
        logger.warning("webhook rejected", extra={"provider": "provider"})
        return Response(status_code=400)
    event = InboundEvent.model_validate_json(raw)
    inserted_id = await webhook_events.insert_once("provider", event.id, event.type, raw)
    if inserted_id is not None:
        await queue.enqueue("process_webhook", inserted_id)
    return Response(status_code=200)
```
`verify_signature` uses `hmac.new(...).hexdigest()` and `hmac.compare_digest`.

## Go (net/http)
```go
// ReceiveProviderWebhook verifies the raw body's signature, stores the event once and queues the work.
func (h *Handler) ReceiveProviderWebhook(w http.ResponseWriter, r *http.Request) {
	raw, err := io.ReadAll(http.MaxBytesReader(w, r.Body, 1<<20))
	if err != nil || !verifySignature(raw, r.Header, h.secret) { w.WriteHeader(http.StatusBadRequest); return }
	var ev InboundEvent
	if json.Unmarshal(raw, &ev) != nil { w.WriteHeader(http.StatusBadRequest); return }
	if id, inserted := h.events.InsertOnce(r.Context(), "provider", ev.ID, ev.Type, raw); inserted { h.queue.Enqueue(r.Context(), "process_webhook", id) }
	w.WriteHeader(http.StatusOK)
}
```
`verifySignature` uses `hmac.New(sha256.New, secret)` and `hmac.Equal`.

## Other stacks
- **Java / Kotlin (Spring):** read `@RequestBody byte[] raw`; `Mac.getInstance("HmacSHA256")`; compare with `MessageDigest.isEqual`.
- **.NET:** enable request buffering and read `Request.Body` to bytes; `HMACSHA256`; compare with `CryptographicOperations.FixedTimeEquals`.
- **Ruby / PHP:** `request.raw_post` / `php://input`; `OpenSSL::HMAC` / `hash_hmac`; compare with `secure_compare` / `hash_equals`.

## The processing job (every stack)
```text
load webhook_events row → skip if already processed
map provider payload → application event (adapter)
if the state matters (amount, status): fetch the object from the provider API and use that
apply the change in one transaction, idempotently (compare versions / timestamps for out-of-order events)
mark the row processed (or failed with the error); retries are safe because every step is idempotent
```

## The delivery worker (outbound, every stack)
```text
take the next due delivery (event + subscription)
check the subscription is active and the URL still resolves to a public address
body = JSON(event envelope);  id, ts = event id, now
signature = base64(HMAC-SHA256(secret, id + "." + ts + "." + body))
POST with headers webhook-id, webhook-timestamp, webhook-signature: "v1,<signature>"; timeout 10 s; no redirects followed
2xx → delivered · anything else or a timeout → record the attempt, schedule the next try with backoff + jitter
after the last try → dead letter; count failures; disable the subscription at the limit and notify its owner
```

# Backend templates

Each one shows: validated input → service with authorization + transaction → the contract-shaped response and errors. Adapt the names to the ticket's `operationId`. **Prefer the project's existing layering.**

## Node: Fastify (TypeScript)
```ts
app.post('/orders', {
  schema: { body: CreateOrderBody, response: { 201: Order, 422: ErrorBody, 409: ErrorBody } }, // from contract codegen
  preHandler: [requireAuth],
}, async (req, reply) => {
  const order = await orders.create(req.user, req.body, { idempotencyKey: req.headers['idempotency-key'] as string | undefined });
  return reply.code(201).send(order);
});

// service
export async function create(actor: Actor, input: CreateOrderInput, opts: { idempotencyKey?: string }) {
  authorize(actor, 'order:create');                                   // throws AppError('forbidden')
  if (opts.idempotencyKey) { const prior = await idem.find(actor.id, opts.idempotencyKey); if (prior) return prior; }
  return db.transaction(async (tx) => {
    const stock = await tx.stock.decrementIfAvailable(input.itemId, input.qty);   // atomic update, no read-modify-write
    if (!stock) throw new AppError('conflict', 'Item is out of stock');
    const order = await tx.orders.insert({ ...input, customerId: actor.id, status: 'confirmed' });
    if (opts.idempotencyKey) await idem.save(actor.id, opts.idempotencyKey, order, tx);
    return order;
  });
}
```
Express, Hono and Koa follow the same shape: a validation middleware (schema from the contract) → handler → service; one central error middleware maps `AppError` to the standard error body.

## Node: NestJS
```ts
@Controller('orders')
@UseGuards(AuthGuard)
export class OrdersController {
  constructor(private readonly orders: OrdersService) {}
  @Post() @HttpCode(201)
  create(@CurrentUser() actor: Actor, @Body() body: CreateOrderDto, @Headers('idempotency-key') key?: string) {
    return this.orders.create(actor, body, { idempotencyKey: key });
  }
}
// global ValidationPipe({ whitelist: true, forbidNonWhitelisted: true }) + an exception filter → standard error body
```

## Python: FastAPI
```python
@router.post("/orders", status_code=201, response_model=Order, responses={409: {"model": ErrorBody}, 422: {"model": ErrorBody}})
async def create_order(body: CreateOrderBody, actor: Actor = Depends(current_actor),
                       idempotency_key: str | None = Header(default=None), db: AsyncSession = Depends(get_db)):
    authorize(actor, "order:create")
    async with db.begin():
        return await orders.create(db, actor, body, idempotency_key)
# exception handlers map AppError and RequestValidationError to the standard error body
```

## Python: Django + DRF
```python
class OrderViewSet(viewsets.GenericViewSet, mixins.CreateModelMixin, mixins.ListModelMixin):
    serializer_class = OrderSerializer
    permission_classes = [IsAuthenticated, CanCreateOrder]
    pagination_class = CursorPagination
    def get_queryset(self):  # object-level scoping: never return other users' rows
        return Order.objects.filter(customer=self.request.user).select_related("item")
    @transaction.atomic
    def perform_create(self, serializer):
        serializer.save(customer=self.request.user, status="confirmed")
# EXCEPTION_HANDLER setting maps errors to the standard error body
```

## Go (net/http or chi)
```go
func (h *Handler) CreateOrder(w http.ResponseWriter, r *http.Request) {
	actor := auth.From(r.Context())
	var in CreateOrderInput
	if err := decodeAndValidate(r, &in); err != nil { writeError(w, 422, "validation_failed", err); return }
	order, err := h.svc.Create(r.Context(), actor, in, r.Header.Get("Idempotency-Key"))
	if err != nil { writeAppError(w, err); return }
	writeJSON(w, http.StatusCreated, order)
}
// service: authz check, then db.WithTx(ctx, func(tx) error { ... }) with conditional UPDATE for stock
```

## Background job (any stack)
Idempotent handler (dedupe on a job key), retries with backoff, a dead-letter destination after N attempts, structured logs with the job id, and no long transactions.

## Test skeleton (integration)
```ts
it('AC-ORD-4: only one order succeeds when stock is 1', async () => {
  await factory.stock({ itemId, qty: 1 });
  const [a, b] = await Promise.all([api.as(userA).post('/orders', body), api.as(userB).post('/orders', body)]);
  expect([a.status, b.status].sort()).toEqual([201, 409]);
  expect((a.status === 409 ? a : b).body.error.code).toBe('conflict');
});
```

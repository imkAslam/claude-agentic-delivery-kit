# Writing acceptance criteria

## Format
```
AC-<area>-<n> (<type: happy|validation|error|permission|empty|concurrency|performance|a11y>)
Given <precondition: actor, state, data>
When <single action or event>
Then <observable outcome>
[And <additional observable outcome>]
```

## Rules
1. **One behavior per criterion.** Split anything with more than one `When`.
2. **Observable outcomes only:** what the user sees, the API returns, or the data shows. Never the implementation ("calls service X").
3. **Concrete values:** "Given a cart with 3 items totalling 120.00", not "Given some items".
4. **Stable ids.** Never renumber them. Retire an id by marking it `~~withdrawn~~` with the reason.
5. **Cover each story with at least:** a happy path, validation/error, and permission. Add empty-state, concurrency, limit, performance and accessibility criteria where the story touches them.
6. **Traceable:** reference the business rule (`BR-`) or decision (`D-`) it encodes.

## Examples
```
AC-ORD-1 (happy)        Given a signed-in customer with 2 items in the cart
                        When they confirm checkout with a valid payment method
                        Then an order with status "confirmed" is created
                        And they see the order number and a confirmation message      (BR-2)

AC-ORD-2 (validation)   Given the delivery address has no postcode
                        When the customer confirms checkout
                        Then checkout is not submitted
                        And the postcode field shows "Postcode is required"

AC-ORD-3 (permission)   Given a signed-in user with the role "viewer"
                        When they open another customer's order URL
                        Then they receive "not found" and no order data is shown      (AC-SEC-2)

AC-ORD-4 (concurrency)  Given 1 unit of an item is in stock
                        When two customers confirm checkout for it at the same moment
                        Then exactly one order is confirmed
                        And the other customer sees "This item just sold out"         (BR-7)

AC-ORD-5 (empty)        Given a customer with no orders
                        When they open "My orders"
                        Then they see an empty state with a link to start shopping
```

## Anti-patterns
- "The system should be fast": give a target (p95 < 300 ms for N concurrent users).
- "Handle errors gracefully": name the error and the exact user-visible handling.
- "Admin can manage users": split it into create, edit, deactivate, with the rules for each.

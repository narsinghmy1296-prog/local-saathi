# Local Saathi — Backend (Phase 6 + 6.5 Hardened)

Real, database-backed FastAPI backend implementing the core Local Saathi
workflow: auth+roles, dynamic categories, products (with the mandatory
"Other" workflow), smart search, cart, addresses, orders, delivery
tracking, and manual payment-status confirmation with a full audit trail.
Phase 6.5 added strict order/payment/delivery state machines, ownership
checks on every sensitive endpoint, server-side re-validation of
price/stock/delivery-zone at checkout, and an automated test suite —
see `docs/ARCHITECTURE.md` → Phase 6.5 for the full list, and the chat
report for details of every bug found and fixed.

**Nothing here is fake** — every button/endpoint hits the real database.
Voice search works by having your Android/web client do speech-to-text
locally and send the resulting text to `/api/v1/search?q=...` — same
endpoint as typed search.

## Setup (in your own VS Code, with internet)

```bash
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt

cp .env.example .env            # then edit .env — set a real SECRET_KEY at minimum
                                 # (generate one: python -c "import secrets; print(secrets.token_hex(32))")

python seed.py                  # creates starter categories, a test delivery
                                 # zone (pincode 000000), and an admin login
                                 # (phone 9999999999 / password admin123 — change
                                 # this password immediately in anything beyond local dev)

uvicorn app.main:app --reload
```

Open **http://127.0.0.1:8000/docs** — full interactive Swagger UI where you
can register a seller, log in, add products, place an order, and run the
whole workflow by hand before you build any UI.

## Running the automated tests

```bash
pytest tests/ -v
```

Uses an isolated in-memory SQLite database (see `tests/conftest.py`) —
never touches your real `local_saathi.db`. Covers authentication,
role/ownership authorization (seller-on-own-product, seller-on-own-order,
delivery-partner-on-own-assignment, customer-cart-isolation), the Other-
product workflow end-to-end, search ranking, the order state machine
(rejecting illegal jumps like `placed → delivered`), payment authorization
+ state machine, stock deduction/oversell prevention, delivery-zone
enforcement, and admin-only access. **This could not be executed inside
the sandbox that built it** (no internet access to install `fastapi`/
`pytest`) — run it in your own environment and treat the first real run
as part of Phase 6.5 sign-off, not an assumption.

## Quick manual test of the full order flow (via /docs)

1. `POST /auth/register` — role=seller, shop details, phone/password
2. Log in as admin (9999999999/admin123) → `POST /admin/sellers/{id}/approve`
3. Log in as the seller → `POST /products` (try a real category, then try
   one with `category_id: null` to see the "Other" workflow)
4. `POST /auth/register` — role=delivery, then admin-approve it too
5. `POST /auth/register` — role=customer → log in
6. `GET /search?q=...` or `GET /categories` + `GET /products` to browse
7. `POST /cart/items` → `POST /addresses` (pincode must be `000000` from
   seed, or add your own zone via admin) → `POST /orders` (checkout)
8. Seller: `POST /orders/{id}/status` → accepted → preparing → delivery_assigned
9. Delivery partner: `GET /delivery/assignments` → `POST /delivery/{id}/status`
   → picked_up → out_for_delivery → delivered
10. Seller/delivery: `POST /orders/{id}/payment/mark-received`
11. `GET /orders/{id}/invoice`
12. Admin: `GET /admin/products/other/list` → `POST /products/{id}/move-category`

This is exactly the acceptance-test scenario from the spec (section 62),
minus voice search (which is a client-side concern) and minus a
generated PDF invoice (the invoice endpoint returns structured JSON today
— wiring it into the existing `pdf` skill to produce an actual PDF is a
same-day follow-up, not a redesign).

## What's deliberately NOT in this MVP yet (per your own MVP principle, #66)

- Multi-seller cart splitting, coupons, ratings, wallet, subscriptions —
  all listed in your spec as "later" features. The schema has room for
  them (see docs/ARCHITECTURE.md) but they're not implemented, so the
  MVP stays simple and shippable.
- Push notifications — `notifications` table exists; wiring it to
  Firebase Cloud Messaging happens once you have an Android client.
- Distance/zone-based delivery pricing — currently a flat ₹20; the slab
  logic from your spec is a small change to `FLAT_DELIVERY_CHARGE` in
  `app/routers/orders.py` once zones have distance data.
- PDF invoice file generation, Android app itself, production Postgres
  config (works out of the box — just change `DATABASE_URL`).
- **Row-level stock locking only takes effect on Postgres** (`with_for_update()`
  in `app/routers/orders.py`) — SQLite (the dev default) has no real row
  locking, so two truly simultaneous checkouts against the same low-stock
  item could still both succeed in dev. Not a concern until you deploy to
  Postgres for the real pilot, at which point the lock is already active.
- Rate limiting / DDoS protection is not implemented in-app — the standard
  approach (and the one recommended here, to avoid adding unnecessary
  complexity to the app itself) is to put this behind a reverse proxy
  (nginx, Cloudflare, or your cloud provider's API gateway) in production.

## Next phases (as per your own Phase list)

- **Phase 7-10**: Client apps (Customer/Seller/Delivery/Admin) — can be a
  single role-aware Android app (React Native/Flutter) or a web app first,
  hitting these same APIs.
- **Phase 11**: Voice search — client-side Android `SpeechRecognizer`
  (Hindi locale) → text → same `/search` endpoint.
- **Phase 13**: Automated tests (pytest + FastAPI TestClient).
- **Phase 14**: Deployment — any VPS/cloud with Postgres; environment
  variables for secrets, never hard-coded.

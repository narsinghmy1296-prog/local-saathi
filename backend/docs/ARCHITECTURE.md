# LOCAL SAATHI — Architecture Document (Phases 1-5)

## PHASE 1: System Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌──────────────────┐
│  Customer App    │     │  Seller App      │     │ Delivery Partner │
│ (Android/Web)    │     │ (Android/Web)    │     │ App (Android)    │
└────────┬─────────┘     └────────┬─────────┘     └────────┬─────────┘
         │                        │                        │
         └────────────┬───────────┴────────────┬───────────┘
                       │      REST API (JSON)   │
              ┌────────▼────────────────────────▼────────┐
              │      FastAPI Backend (Python)             │
              │  ─ Auth (JWT + Role-based)                │
              │  ─ Product/Category Service               │
              │  ─ Search Service (text + keyword)         │
              │  ─ Order/Cart Service                      │
              │  ─ Delivery Service                        │
              │  ─ Payment-Status Service (no gateway)      │
              │  ─ Audit Log Service                       │
              │  ─ Notification Service (stub → push later) │
              └────────────────────┬───────────────────────┘
                                   │
                        ┌──────────▼──────────┐
                        │  Database            │
                        │  Dev: SQLite         │
                        │  Prod: PostgreSQL    │
                        └──────────────────────┘
```

- Voice-to-text happens **on-device** (Android `SpeechRecognizer` / browser Web Speech API,
  Hindi locale). The app sends the **recognized text** to the same `/search` endpoint as
  typed search — backend never needs to do speech recognition itself. This keeps cost at
  zero and works with Hindi/English/Hinglish depending on what the OS engine supports.
- Single backend + API serves all four apps. Role is decided at login; each client only
  shows the screens relevant to its role.
- MVP ships as **one Android app with role-based dashboards** (per your note in point 51),
  splitting into separate apps later needs no backend change.

## PHASE 2: Database Schema (core entities + relationships)

> Updated in Phase 6.5 to match the actual code exactly (this had drifted
> from the original Phase 2 draft — see the Phase 6.5 note at the bottom
> of this document).

| Table | Key Columns | Relationships |
|---|---|---|
| `users` | id, phone (unique), name, password_hash, role (customer/seller/delivery/admin), is_active, created_at | 1—1 with role-profile tables |
| `sellers` | id, user_id→users, shop_name, owner_name, area, upi_id, is_approved | 1—many `products`, 1—many `orders` |
| `delivery_partners` | id, user_id→users, vehicle_type, area, is_approved, is_available | 1—many `deliveries` |
| `categories` | id, name_hi, name_en, icon_url, sort_order, is_active | 1—many `products`. *(No `parent_id`/sub-category nesting in the MVP — flat list only, as the seed data is flat. Add it later if a two-level category tree is needed.)* |
| `products` | id, seller_id→sellers, category_id→categories (nullable = filed as "Other"), is_other (bool), name, description, price, unit, available_qty, min_order_qty, stock_status, image_url, is_active | 1—many `product_keywords` |
| `product_keywords` | id, product_id→products, keyword (indexed) | many—1 `products` |
| `carts` | id, customer_id→users (unique) | 1—many `cart_items` |
| `cart_items` | id, cart_id→carts, product_id→products, quantity | — |
| `addresses` | id, customer_id→users, name, mobile, village_town, house, landmark, pincode, lat, lng, is_default | — |
| `delivery_zones` | id, name, pincode, is_active | referenced by `addresses`/checkout for feasibility check |
| `orders` | id, customer_id, address_id, seller_id, delivery_partner_id (nullable), status, subtotal, delivery_charge, discount, grand_total, **payment_method, payment_status** (see note below), created_at | 1—many `order_items`, 1—many `order_status_history` |
| `order_items` | id, order_id→orders, product_id→products, quantity, unit_price, amount | — |
| `order_status_history` | id, order_id, status, changed_by_user_id, timestamp | audit trail of order lifecycle |
| `payment_audit_logs` | id, order_id→orders, user_id, payment_method, old_status, new_status, timestamp | append-only audit of every payment-status change |
| `deliveries` | id, order_id (unique), delivery_partner_id, status, assigned_at, picked_up_at, delivered_at | — |
| `delivery_status_history` | id, delivery_id, status, changed_by_user_id, timestamp | — |
| `invoices` | id, order_id (unique), invoice_number, generated_at | — |
| `notifications` | id, user_id, title, body, is_read, created_at | not yet wired to any push service — see README |
| `admin_actions` | id, admin_user_id (really "actor_user_id" — see model docstring), action, entity_type, entity_id, old_value, new_value, timestamp | generic audit for admin **and seller-on-own-product** changes |

**19 tables total.** Corrections from the original Phase 2 draft:
there is **no separate `payments` table** — `payment_method` and
`payment_status` live directly on `orders` (one order = one payment,
so a separate table added no value), and `payment_audit_logs` is the
audit trail. `categories` has no `parent_id` — it's a flat list in the
MVP. `products.is_other` was added as an explicit flag rather than
inferring "Other" purely from `category_id IS NULL`, so a product's
Other/official status survives even if it's ever temporarily
uncategorized for another reason.

All FKs indexed; `product_keywords.keyword` and `products.name` indexed for search speed.

## PHASE 3: API List (v1, prefix `/api/v1`)

**Auth**
`POST /auth/register` · `POST /auth/login` · `GET /auth/me`

**Categories** (admin write, public read)
`GET /categories` · `POST /categories` (admin) · `PUT /categories/{id}` (admin) · `DELETE /categories/{id}` (admin)

**Products**
`GET /products` (filters: category, seller) · `POST /products` (seller, approved only) ·
`PUT /products/{id}` (owner seller/admin) · `DELETE /products/{id}` (soft-delete, owner seller/admin) ·
`PATCH /products/{id}/stock` (owner seller) · `POST /products/{id}/move-category` (admin — "Other" → official) ·
`GET /products/other/list` (admin)

**Search**
`GET /search?q=चप्पल` → ranked results (exact name → name match → keyword → category → related)

**Cart**
`GET /cart` · `POST /cart/items` · `PUT /cart/items/{id}` · `DELETE /cart/items/{id}` — all scoped to the caller's own cart only

**Addresses**
`GET /addresses` · `POST /addresses` · `PUT /addresses/{id}` · `DELETE /addresses/{id}` — all scoped to the caller; zone-validated on create *and* update

**Orders**
`POST /orders` (checkout — re-validates zone/price/stock server-side, deducts stock) · `GET /orders` (mine, by role) ·
`GET /orders/{id}` (owner/assigned/admin only) · `POST /orders/{id}/status` (state-machine + role + ownership checked) ·
`POST /orders/{id}/cancel` (ownership checked, restores stock) ·
`POST /orders/{id}/payment/mark-received` (ownership + payment state machine checked) ·
`GET /orders/{id}/invoice` (owner/assigned/admin only)

**Delivery**
`GET /delivery/assignments` (own assignments only) · `POST /delivery/{id}/status` (ownership + delivery state machine checked)

**Invoice**
`GET /orders/{id}/invoice` (see Orders above — invoice lives under the order, not a separate top-level resource)

**Admin**
`GET /admin/dashboard` · `POST /admin/sellers/{id}/approve` · `POST /admin/delivery-partners/{id}/approve` ·
`POST /admin/delivery-zones` · `GET /admin/audit-logs`

## PHASE 4: Folder Structure

```
local_saathi/
├── app/
│   ├── main.py                # FastAPI app, mounts routers
│   ├── core/
│   │   ├── config.py          # env-based settings (no hardcoded secrets)
│   │   ├── database.py        # SQLAlchemy engine/session
│   │   └── security.py        # password hashing, JWT, role dependency
│   ├── models/                # SQLAlchemy ORM models (one file per entity group)
│   ├── schemas/                # Pydantic request/response schemas
│   └── routers/                # one router file per API group above
├── requirements.txt
└── docs/ARCHITECTURE.md
```

## PHASE 5: Authentication & Roles

- Password hashing: `bcrypt` via `passlib`.
- Login returns a JWT containing `user_id` + `role`.
- Every protected endpoint uses a `require_role(["seller"])`-style FastAPI dependency —
  centralized, not re-implemented per route, so role checks can't be forgotten.
- Payment-status and order-status transitions carry an extra check: only the role allowed
  for *that specific transition* (e.g. only delivery partner can mark "Delivered", only
  seller/delivery/admin can mark "Cash Received") can call it — enforced in the router,
  logged in `payment_audit_logs` / `order_status_history` either way.
- `POST /auth/register` refuses `role: "admin"` outright — admin accounts are created only
  via `seed.py` or directly in the database, never through public self-registration
  (this was a critical hole found and closed in Phase 6.5, see below).

## PHASE 6.5: Security & Functional Hardening

A full audit pass over the Phase 6 backend, before starting any Customer UI work. See the
chat response for the complete report (Fixed / Verified / Needs Runtime Test / Remaining
Limitations / Files Changed / Test Results / Phase 7 Readiness). Highlights:

- **Critical fix**: public registration allowed anyone to create an `admin` account —
  closed.
- **Real bug fix**: `Order.customer` / `Order.seller` / `Order.address` relationships were
  referenced by Phase 6 code (`delivery.py`, the invoice endpoint) but never declared on
  the `Order` model — would have crashed the first time those endpoints ran.
- **Real bug fix**: adding `quantity > 0` validation to the shared cart schema silently
  broke "set quantity to 0 to remove the item" — split into `CartItemAdd` (quantity must
  be > 0) vs `CartItemUpdate` (0 allowed, means remove).
- Strict state machines added for Order status, Payment status, and Delivery status
  (`app/core/state_machine.py`) — no more direct `placed → delivered`-style jumps.
- Ownership checks added everywhere a role check alone was previously being treated as
  sufficient (seller-on-own-order, delivery-partner-on-own-assignment, customer-on-own-
  order/cart/address).
- Checkout now re-verifies price/stock/zone from the database (never trusts the client or
  a stale cart-item object) and actually deducts stock — Phase 6 built the order but never
  decremented `available_qty`.
- Product edit/deactivate endpoints added — Phase 6 had no way to change a product's price
  or take it off sale at all beyond the stock-only PATCH.
- CORS, a global exception handler (no raw tracebacks to the client), `.env.example`, and
  an automated pytest suite (`tests/`) were added.

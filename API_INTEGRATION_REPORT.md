# API_INTEGRATION_REPORT.md — Local Saathi Customer App ↔ Backend

**Status: CONFIRMED against real backend source**, not inferred. This
supersedes the "ASSUMED" markers in the earlier `PROJECT_README.md`,
which was written before the actual `backend/app/` source was available.
Every row below was checked directly against `backend/app/routers/*.py`
and `backend/app/schemas/*.py`.

All paths are prefixed `/api/v1` (see `ApiConfig` in `lib/core/api_endpoints.dart`).

---

## AUTH

| | |
|---|---|
| **Register** | `POST /auth/register` — body `{phone, name, password, role: "customer"}` (Flutter always sends `role: "customer"`; backend hard-blocks `role: "admin"`). Response: `UserOut` `{id, phone, name, role, is_active}`. Auth: none. |
| **Login** | `POST /auth/login` — body `{phone, password}`. Response: `{access_token, token_type, role}` — **no user id/name in the login response**; Flutter's `AuthService.login()` correctly follows up with `GET /auth/me` to get those. |
| **Me** | `GET /auth/me` — Bearer required. Response: `UserOut`. |
| Validation | `phone` must match `^[6-9]\d{9}$`, `password` min length 6 — Flutter's form validators now match these exactly (fixed in this pass; previously checked length only). |

**Flutter service:** `services/auth_service.dart` — compatible.

---

## CATEGORY

| | |
|---|---|
| `GET /categories` | Public, no auth. Returns active categories sorted by `sort_order`. Shape: `[{id, name_hi, name_en, icon_url, sort_order, is_active}]`. |

**Flutter service:** `services/catalog_service.dart` -> `models/category.dart` — compatible, field names match exactly.

---

## PRODUCT

| | |
|---|---|
| `GET /products` | Public. Query params `category_id`, `seller_id` (both optional). Returns only `is_active=true` products. Shape: `[{id, seller_id, category_id, is_other, name, description, price, unit, available_qty, min_order_qty, stock_status, image_url, is_active}]`. |
| No `GET /products/{id}` | **Does not exist on the backend.** `CatalogService.getProduct(id)` correctly works around this by fetching the full list and filtering client-side — this is intentional, not a bug, given the backend's real surface. |

**Flutter service:** `services/catalog_service.dart` -> `models/product.dart` — compatible.

---

## SEARCH

| | |
|---|---|
| `GET /search?q=...` | Public. Ranked: exact name -> name match -> keyword match -> category match. Same endpoint for typed and voice search (voice just sends recognized text as `q`). Returns `[ProductOut]`, same shape as `/products`. |

**Flutter service:** `services/catalog_service.dart` (`search()`), fed by `services/voice_search_controller.dart` (real `speech_to_text` package, not a stub) — compatible.

---

## CART

| | |
|---|---|
| `GET /cart` | Bearer + role=customer. Returns `{items: [{id, product_id, name, price, quantity, amount}], subtotal}`. |
| `POST /cart/items` | body `{product_id, quantity}`. Validates stock/min-order-qty server-side. |
| `PUT /cart/items/{id}` | body `{product_id, quantity}` — **`product_id` is required in the body even though it's also in the URL** (backend's `CartItemUpdate` schema requires it). Flutter's `cart_service.dart` already sends both — confirmed correct. |
| `DELETE /cart/items/{id}` | No body. |

**Flutter service:** `services/cart_service.dart` -> `models/cart.dart`, `state/cart_provider.dart` — compatible.

---

## ADDRESS

| | |
|---|---|
| `GET/POST/PUT /addresses`, `/addresses/{id}` | Bearer + role=customer, scoped to the caller. `POST`/`PUT` validate the pincode against an active `DeliveryZone` server-side — a customer cannot save an address outside the service area. |

**BUG FOUND AND FIXED (this pass):** these three endpoints had **no `response_model`** and were returning raw SQLAlchemy ORM objects. FastAPI's JSON encoder cannot serialize a SQLAlchemy object's internal `_sa_instance_state`, so every call would have thrown a 500 error — the Customer app's entire Address feature (and therefore Checkout) would have been unusable. Fixed by adding `AddressOut` (`backend/app/schemas/order.py`) and wiring it into all three endpoints (`backend/app/routers/addresses.py`). Covered by a new regression test (`test_address_crud_returns_proper_json`).

**Flutter service:** `services/address_service.dart` -> `models/address.dart` — now compatible (was broken before this pass).

---

## CHECKOUT

| | |
|---|---|
| `POST /orders` | body `{address_id, payment_method: "upi"|"cod"}`. Backend re-verifies price/stock/zone from the DB (never trusts the client), deducts stock, empties the cart, returns `{order_id, status, grand_total}`. |

**Flutter service:** `services/order_service.dart` (`placeOrder`) — lowercases `paymentMethod` before sending, matching the backend's lowercase enum — compatible.

---

## ORDER

| | |
|---|---|
| `GET /orders` | List, scoped to caller. Shape: `[{id, status, payment_method, payment_status, grand_total, created_at, item_count}]`. **`item_count` added in this pass** — previously this endpoint had no item data at all, so the "My Orders" screen's "N products" line always showed 0. |
| `GET /orders/{id}` | Detail, ownership-checked. Shape: `{id, status, payment_method, payment_status, subtotal, delivery_charge, discount, grand_total, items: [...], status_history: [{status, timestamp}]}`. |
| `POST /orders/{id}/cancel` | Ownership + state-machine checked (can't cancel past `out_for_delivery`). |

**Not called by the Customer app** (belong to Seller/Delivery/Admin roles): `POST /orders/{id}/status`, `POST /orders/{id}/payment/mark-received`, all of `/delivery/*` and `/admin/*`. Confirmed the Customer app never calls these.

**Flutter service:** `services/order_service.dart` -> `models/order.dart` — compatible after this pass's `item_count` fix.

---

## ORDER STATUS (enum, confirmed from `backend/app/models/order.py`)

```
placed, accepted, preparing, delivery_assigned, picked_up,
out_for_delivery, delivered, cancelled, rejected
```

There is **no separate status-history endpoint** — `status_history` is a field inside `GET /orders/{id}`. `order_detail_screen.dart`'s `getStatusHistory()` re-fetches the same order-detail endpoint, which works but is a redundant network call — noted as a minor optimization opportunity, not a bug.

`rejected` was **missing from the Flutter `OrderStatus` enum** — added in this pass (`models/order.dart`, `widgets/order_status_stepper.dart`, `screens/orders/orders_screen.dart`'s active/past grouping and badge color).

---

## INVOICE

| | |
|---|---|
| `GET /orders/{id}/invoice` | Ownership-checked. Shape: `{invoice_number, generated_at, order_id, customer, seller, items: [{name, quantity, unit_price, amount}], subtotal, delivery_charge, discount, grand_total, payment_status}`. JSON only — no PDF exists on the backend today. |

**Rebuilt in this pass:** the previous `Invoice` model only parsed `id`/`invoice_number`/`order_id`/`generated_at` and dumped every other field (including the `items` list and `customer`/`seller` strings) through a generic key-value fallback loop — technically didn't crash, but rendered as raw stringified Dart objects instead of a real receipt. `models/invoice.dart` and `screens/orders/invoice_screen.dart` were rewritten to parse the real shape properly and render a clean itemized invoice.

---

## USER PROFILE

| | |
|---|---|
| `GET /auth/me` | Only profile-related endpoint that exists. **No profile-edit API on the backend** — the Profile screen is therefore read-only by design, not a missing feature. |

**Gap found and fixed:** the spec's module #19/#25 "Profile" screen didn't exist anywhere in the delivered app, and there was no 4th bottom-nav tab for it — meaning Addresses were only reachable from mid-checkout, with no standalone way to manage them. Added `screens/profile/profile_screen.dart` (name/phone display from `AuthProvider`, links to My Addresses and My Orders, Help dialog, Logout) and wired it as the 4th tab in `home_shell.dart`. Logout button was moved off the Home app bar onto this screen (was duplicated before).

---

## Summary of backend changes made during this integration pass

All changes are additive/backward-compatible — nothing existing was removed or renamed:

1. `backend/app/schemas/order.py` — added `AddressOut`.
2. `backend/app/routers/addresses.py` — added `response_model=AddressOut` / `list[AddressOut]` to `GET`/`POST`/`PUT`.
3. `backend/app/routers/orders.py` — added `item_count` field to the `GET /orders` list response.
4. `backend/tests/test_workflow.py` — added `test_address_crud_returns_proper_json` and `test_my_orders_list_includes_item_count`.

## Summary of Flutter changes made during this integration pass

1. `models/invoice.dart`, `screens/orders/invoice_screen.dart` — rebuilt to parse/render the real invoice shape.
2. `screens/profile/profile_screen.dart` (new), `screens/home/home_shell.dart`, `screens/home/home_screen.dart` — added the missing Profile screen/tab, moved Logout there.
3. `core/token_storage.dart`, `services/auth_service.dart`, `state/auth_provider.dart` — added `phone` to the stored session so Profile can display it.
4. `models/order.dart`, `widgets/order_status_stepper.dart`, `screens/orders/orders_screen.dart` — added the missing `rejected` order status.
5. `screens/auth/register_screen.dart` — password validator now matches backend's `min_length=6` (was checking `<4`).
6. `screens/auth/login_screen.dart`, `screens/auth/register_screen.dart`, `screens/address/address_form_screen.dart` — phone/pincode validators now match the backend's exact regex instead of just checking length.

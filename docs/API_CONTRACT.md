# API_CONTRACT.md — Local Saathi Backend (verified against source)

Base path for every endpoint below: `/api/v1`. All bodies are JSON.
Auth is `Authorization: Bearer <token>` from `POST /auth/login`.
Errors are always `{"detail": "..."}` (or, for 422, `{"detail": "...",
"errors": [...]}`), enforced by centralized exception handlers in
`app/main.py` — never a raw traceback.

Legend: 🔓 public · 🔑 any logged-in role · 👤 role-restricted (shown)

## Auth
| Method & Path | Access | Body / Notes |
|---|---|---|
| `POST /auth/register` | 🔓 | `{phone, name, password, role, ...role-specific fields}`. `role=admin` is rejected (403). `role=seller` requires `shop_name, owner_name, area`; `role=delivery` requires `area`. New seller/delivery accounts start `is_approved=False`. Returns `UserOut`. |
| `POST /auth/login` | 🔓 | `{phone, password}` → `{access_token, token_type, role}`. 403 if account deactivated. |
| `GET /auth/me` | 🔑 | → `UserOut {id, phone, name, role, is_active}` |

## Categories
| Method & Path | Access | Notes |
|---|---|---|
| `GET /categories` | 🔓 | Active only, sorted by `sort_order`. |
| `POST /categories`, `PUT /categories/{id}` | 👤 admin | `{name_hi, name_en, icon_url?, sort_order}` |
| `DELETE /categories/{id}` | 👤 admin | Soft-delete (`is_active=False`) only. |

## Products
| Method & Path | Access | Notes |
|---|---|---|
| `GET /products?category_id=&seller_id=` | 🔓 | Active only. **No `GET /products/{id}`** — resolve from this list, by design. |
| `POST /products` | 👤 seller (approved) | `category_id: null` → filed as "Other" (`is_other=True`), still searchable. |
| `PATCH /products/{id}/stock` | 👤 seller (own product) | `{available_qty, stock_status}` |
| `PUT /products/{id}` | 👤 seller (own) / admin | Partial update; price/category changes are audit-logged. |
| `DELETE /products/{id}` | 👤 seller (own) / admin | Soft-delete only — order history stays intact. |
| `POST /products/{id}/move-category?category_id=` | 👤 admin | Moves an "Other" product into a real category in place. |
| `GET /products/other/list` | 👤 admin | All `is_other=True` products, for the Admin review queue. |

## Search
| `GET /search?q=` | 🔓 | Ranked: exact name → name-contains → keyword → category name. Same endpoint for typed and voice search (client does speech-to-text, sends resulting text here). |

## Cart (customer only)
| Method & Path | Notes |
|---|---|
| `GET /cart` | → `{items: [{id, product_id, name, price, quantity, amount}], subtotal}` |
| `POST /cart/items` | `{product_id, quantity}` — validates stock + min-order-qty server-side |
| `PUT /cart/items/{id}` | `{product_id, quantity}` — **`product_id` required in body even though it's in the URL** (existing contract, kept as-is) |
| `DELETE /cart/items/{id}` | — |

## Addresses (customer only)
`GET/POST/PUT/DELETE /addresses`, `/addresses/{id}` — scoped to caller.
`POST`/`PUT` re-validate the pincode against an active `DeliveryZone`
server-side (a customer cannot bypass the service-area check).

## Orders
| Method & Path | Access | Notes |
|---|---|---|
| `POST /orders` | 👤 customer | `{address_id, payment_method: "upi"\|"cod"}` — checks out the whole cart against ONE seller only. Re-validates price/stock/zone from DB. Returns `{order_id, status, grand_total}`. |
| `GET /orders` | 🔑 | Scoped by role (customer: own; seller: own shop; delivery: own assignments; admin: all). Includes `item_count`. |
| `GET /orders/{id}` | 🔑 | Ownership-checked. Full detail incl. `items[]`, `status_history[]`, and (🆕 **added this pass**) `customer: {name, phone}` + `address: {village_town, house, landmark, pincode, mobile}` — previously missing entirely, which blocked the Seller App's whole fulfillment workflow (no way to see who/where to prepare an order for). Safe to always include: `_assert_order_visible` already restricts callers to the order's own customer/seller/delivery-partner/admin. |
| `POST /orders/{id}/status` | 👤 role depends on target status (seller/admin/delivery — see state machine) | `{status, delivery_partner_id?}`. Illegal jumps rejected (400). Auto-creates the `Delivery` row + assigns a partner when moving to `delivery_assigned`. |
| `POST /orders/{id}/cancel` | 👤 customer/seller/admin (not delivery) | Only allowed before `out_for_delivery`; restores stock. |
| `POST /orders/{id}/payment/mark-received` | 👤 seller/delivery/admin (own order) | `{new_status}`. Every attempt is written to `payment_audit_logs`, success or reject. |
| `GET /orders/{id}/invoice` | 🔑 (ownership-checked) | JSON invoice (no PDF yet). |

## Delivery (delivery-partner role only)
| `GET /delivery/assignments` | Own assignments, with customer/address/payment summary per order. |
| `POST /delivery/{delivery_id}/status` | `{status}` — `assigned→picked_up→out_for_delivery→delivered`, mirrored onto the parent `Order.status` too. |

## Admin
| Method & Path | Notes |
|---|---|
| `GET /admin/dashboard` | Orders/products/users/payments counts. |
| `GET /admin/sellers?status=all\|pending\|approved` | 🆕 **added this pass** — list/search sellers with owner phone, account status, product count. |
| `GET /admin/sellers/{id}` | 🆕 Detail view of one seller. |
| `POST /admin/sellers/{id}/approve` | Existing. |
| `POST /admin/sellers/{id}/reject` | 🆕 Sets `is_approved=False` + disables login. |
| `POST /admin/sellers/{id}/deactivate` / `/activate` | 🆕 Suspend/reinstate login without touching approval or products. |
| `GET /admin/delivery-partners?status=` | 🆕 Same shape as sellers, for delivery partners. |
| `POST /admin/delivery-partners/{id}/approve` \| `/reject` \| `/deactivate` \| `/activate` | Existing `approve`; **`reject`/`deactivate`/`activate` added this pass.** |
| `POST /admin/delivery-zones` | Add/reactivate a serviceable pincode. |
| `GET /admin/audit-logs` | Last 200 `AdminAction` rows. |

All 🆕 rows are additive (new routes only) — nothing existing was
renamed, removed, or had its response shape changed. Full request/response
schemas are in `backend/app/schemas/admin.py` (`SellerOut`,
`DeliveryPartnerOut`) and the existing `schemas/order.py` / `schemas/product.py`.

## Order/Payment/Delivery status enums (exact strings, from `app/models/*.py`)
```
OrderStatus:   placed, accepted, preparing, delivery_assigned, picked_up,
               out_for_delivery, delivered, cancelled, rejected
PaymentStatus: pending, initiated, paid, cash_received, failed, unverified
DeliveryStatus:assigned, picked_up, out_for_delivery, delivered
```

## Sellers (self-service)
| Method & Path | Access | Notes |
|---|---|---|
| `GET /sellers/me` | 👤 seller | 🆕 **added for Seller App** — own profile: `{id, shop_name, owner_name, area, upi_id, is_approved, phone, name}`. Did not exist before; a seller had no way to view their own shop details except through `/auth/me` (which has none of this). |
| `PUT /sellers/me` | 👤 seller | 🆕 Partial update of `shop_name/owner_name/area/upi_id` only — `is_approved` is not a field on this schema, so it can never be self-approved through this endpoint. Logged to `AdminAction`. |

## Uploads
| Method & Path | Access | Notes |
|---|---|---|
| `POST /uploads/product-image` | 👤 seller (approved) | 🆕 **added for Seller App** — multipart `file` field, JPEG/PNG/WebP only, 5MB max. Saves to `backend/static/products/` and returns `{"image_url": "/static/products/<name>.<ext>"}`, which the client then sends as `image_url` in `POST/PUT /products`. Backend previously had `image_url` as a plain string column with **no way to actually upload a file** — this was a real gap, not a design choice, since the Seller App's product form needs to let a seller take/pick a photo. Files are served back via `StaticFiles` mounted at `/static` in `app/main.py`. **Production note**: local disk storage is fine for a pilot; swap for S3/object storage before scaling, since local disk on most PaaS free tiers is ephemeral (wiped on redeploy). |


- **Seller App**: `auth/*`, `products/*` (own), `orders` filtered by
  seller role automatically, `orders/{id}/status`,
  `orders/{id}/payment/mark-received`, `categories` (read-only, to
  populate the picker).
- **Admin Panel**: `auth/login` (admin only — no self-registration
  path exists or should exist for admin), `admin/*` in full,
  `categories` CRUD, `products` (read/moderate), `orders` (read all).
- **Delivery App**: `auth/*`, `delivery/*` in full, `orders/{id}`
  (read own), `orders/{id}/payment/mark-received`.

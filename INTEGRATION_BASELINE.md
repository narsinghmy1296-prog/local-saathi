# Local Saathi — Integration Baseline

> **UPDATE (later audit pass):** This baseline's compatibility claims were
> re-verified against the actual backend source (they held up), and a full
> line-by-line audit of both projects found and fixed additional issues
> this baseline missed — most importantly, the Address endpoints were
> serializing raw SQLAlchemy objects and would have thrown 500 errors.
> See `API_INTEGRATION_REPORT.md` for the complete, current picture.

This package combines the tested FastAPI backend with the Phase 7 Flutter customer app as a starting integration baseline.

## Important verified compatibility fixes

- Backend authentication uses HTTP Bearer parsing compatible with the JSON `/api/v1/auth/login` endpoint.
- `bcrypt==4.0.1` is pinned because the backend uses `passlib==1.7.4`.
- Flutter login consumes the real `access_token` response and then calls `/api/v1/auth/me` for authoritative user metadata.
- Flutter cart parsing matches the real backend cart response.
- Cart quantity update uses the real backend `PUT /api/v1/cart/items/{item_id}` body: `product_id` + `quantity`.
- Checkout sends the real backend body: `address_id` + `payment_method`.
- The backend currently returns `status_history` inside `GET /api/v1/orders/{order_id}`; there is no separate `/status-history` endpoint.
- The backend currently has no `GET /api/v1/products/{id}` customer endpoint; the customer app resolves product details from the product list.
- The backend invoice endpoint returns JSON invoice data.

## Security baseline

The customer app never creates or approves admin accounts, never trusts client-side prices/stock, and never claims UPI payment success without backend confirmation.

## Local test credentials

Use the existing development seed credentials only in the local development environment. Do not ship development passwords or `.env` secrets in a production APK.

# Local Saathi Integration Baseline — Changes Included

> **UPDATE (later audit pass):** see `API_INTEGRATION_REPORT.md` at the
> project root for the complete, currently-accurate list of backend and
> Flutter fixes, including a critical Address-serialization bug this
> earlier pass did not catch.

This package was assembled from the latest uploaded Local Saathi backend and Phase-7 customer app.

## Backend changes included
- Replaced `backend/app/core/security.py` with the HTTP Bearer/JWT implementation used during the successful Swagger authentication work.
- Kept the existing RBAC, JWT, admin-registration protection and order/product ownership logic.
- Added `bcrypt==4.0.1` to `requirements.txt` to prevent the Passlib 1.7.4 / newer bcrypt compatibility problem encountered during setup.

## Flutter/backend compatibility changes included
- Login now consumes the real `{access_token, token_type, role}` response and calls `/auth/me` for authoritative user metadata.
- Cart model now matches the actual backend cart response.
- Cart quantity update now uses PUT and sends `product_id` + `quantity`.
- Product detail no longer calls a nonexistent `/products/{id}` endpoint; it resolves the product from the catalog list.
- Order status history now reads `status_history` from `/orders/{id}` because the backend has no separate `/status-history` endpoint.
- Order item parsing supports the backend's `name` field.
- Checkout sends the real `address_id` + `payment_method` contract and accepts the backend's `{order_id, status, grand_total}` response.

## Validation performed in this environment
- Python backend source/tests passed `python -m compileall` static compilation.
- Flutter/Dart SDK was not available in this build environment, so `flutter analyze`, `flutter test`, `flutter build apk` and device runtime testing are NOT claimed as passed.

Claude should perform the real Flutter/Android build and runtime tests on the user's Windows/VS Code environment.

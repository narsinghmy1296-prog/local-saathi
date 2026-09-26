# SELLER_APP_README.md — Local Saathi Seller App

Flutter/Android app for approved local sellers to manage their shop,
products, and orders against the shared Local Saathi FastAPI backend.
Built by reusing the Customer App's proven architecture (same
`ApiClient`, `TokenStorage`, `AppTheme`, Provider state pattern) — see
`docs/PROJECT_AUDIT.md` and `docs/IMPLEMENTATION_PLAN.md` at the repo
root for how this fits into the overall project.

## 1. What's inside

```
seller_app/
├── lib/
│   ├── core/        api_client, api_endpoints, token_storage, app_theme,
│   │                app_strings (Hindi/English), order_status_labels
│   ├── models/      category, product, order, seller_profile
│   ├── services/    auth, catalog, product, order, seller_profile, upload
│   ├── state/       auth/seller/products/orders/locale providers (Provider)
│   ├── screens/     auth/, dashboard/, products/, orders/, profile/, home/
│   └── main.dart
├── android/         package: com.example.local_saathi_seller
├── pubspec.yaml
└── analysis_options.yaml
```

## 2. Backend changes this app required

All additive — nothing existing renamed, removed, or had its response
shape changed. Full detail in `docs/API_CONTRACT.md` (search for 🆕).

1. `GET /sellers/me`, `PUT /sellers/me` — seller's own shop profile
   (view + edit `shop_name/owner_name/area/upi_id`). Did not exist
   before; there was no way for a seller to see or update their own
   shop details anywhere.
2. `POST /uploads/product-image` — multipart file upload (JPEG/PNG/WebP,
   5MB max), returns `{"image_url": "/static/products/<file>"}`. Backend
   previously only had `image_url` as a plain string column with **no
   way to actually upload a file** — a real gap, not a design choice.
   Files are served back via `StaticFiles` mounted at `/static`.
3. `GET /orders/{id}` now also returns `customer: {name, phone}` and
   `address: {village_town, house, landmark, pincode, mobile}` — this
   was **completely missing before**, which meant a seller had no way
   to see who or where to prepare an order for. Safe to always include:
   `_assert_order_visible` already restricts callers to the order's own
   customer/seller/delivery-partner/admin.

All three are covered by new tests in `backend/tests/test_workflow.py`
(`test_seller_can_view_and_update_own_profile`,
`test_seller_can_upload_product_image_and_use_it`,
`test_order_detail_includes_customer_and_address_for_seller`, and
related negative-path tests).

**No changes were made to the Customer App.** It was audited (imports,
API calls) and nothing in it depends on or is affected by any of the
above three additions.

## 3. Known limitations (documented, not silently worked around)

- **Keywords not shown on edit**: `ProductOut` (the backend's response
  shape for a product) does not include `keywords` — they're
  write-only, used only for search indexing. So the Add Product form
  lets a seller type keywords, but the Edit Product form starts with
  that field blank (whatever is typed on save is appended to the
  product's searchable keywords, not a replacement of what's there).
  Fixing this properly needs a small backend addition
  (`GET /products/{id}/keywords` or including it in `ProductOut`) —
  flagged here rather than guessed at or faked in the UI.
- **Photo picking is gallery-only** (`ImageSource.gallery`), not
  camera capture. Camera capture needs a `FileProvider` + extra
  manifest wiring that couldn't be verified with a real build in this
  sandbox (no Android SDK); gallery pick needed no such extra plumbing,
  so it was the safer choice to actually ship rather than leave
  half-wired. Camera support can be added as a follow-up once a real
  device/emulator build confirms the FileProvider setup works.
- **Local disk image storage**: `backend/static/products/` is local
  disk, fine for a pilot; most PaaS free tiers wipe local disk on
  redeploy, so move to S3/object storage before scaling (same note is
  in `docs/API_CONTRACT.md`).
- **Dashboard has no dedicated backend endpoint** — stats (product
  counts, order counts by status) are computed client-side from the
  existing `GET /products?seller_id=` and `GET /orders` calls, since
  there is no per-seller equivalent of `/admin/dashboard`. This is
  correct behavior, not a workaround — it uses only real data, just
  aggregates it on-device instead of a dedicated summary endpoint.

## 4. Configuration — API Base URL

No hardcoded IPs anywhere (this exact bug was found and fixed in the
Customer App during the Phase 1 audit — same fix applied here from the
start). Set via `--dart-define` at build/run time:

```bash
# Android emulator + local backend (uvicorn --reload) — this is the
# default with NO flag needed:
flutter run

# Physical phone on the same Wi-Fi as your dev machine:
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000

# Production release build:
flutter build apk --release --dart-define=API_BASE_URL=https://api.localsaathi.in
```

## 5. Exact commands to run yourself

This sandbox has **no internet access and no Flutter/Android SDK
installed** — `flutter pub get` fails immediately with no network to
resolve packages, so none of the commands below could be executed
here. This is an environment limitation, not a skipped step — see
`SELLER_APP_TEST_REPORT.md` for the honest per-check status. Run these
on your own machine, in order, from inside `seller_app/`:

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Static analysis (should be clean — flutter_lints + no warnings
#    were introduced; fix anything it flags before building)
flutter analyze

# 3. Widget/unit tests (none are included yet in this pass — see
#    SELLER_APP_TEST_REPORT.md "Not Run" section for why, and what to
#    add first)
flutter test

# 4. Debug APK build
flutter build apk --debug

# 5. Release APK build (once you have a real signing config —
#    currently debug-signed per the Flutter template default, see
#    android/app/build.gradle.kts "signingConfig = signingConfigs.getByName("debug")")
flutter build apk --release --dart-define=API_BASE_URL=https://your-real-backend
```

Backend must be running for the app to do anything useful:
```bash
cd backend
pip install -r requirements.txt   # first time only
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## 6. Manual test walkthrough (once you have a build + backend running)

1. Register a new seller (shop name, owner name, area, phone, password).
2. Log in immediately after — you should land on the **Pending
   Approval** screen (the new account isn't approved yet).
3. As admin (via `POST /api/v1/admin/sellers/{id}/approve`, or once the
   Admin Panel exists), approve the seller.
4. Tap "फिर से जाँचें / Refresh" on the Pending Approval screen — it
   should now open into the Dashboard.
5. Add a product: pick a category or check "Other/अन्य", add a photo,
   fill in price/unit/quantity, save. Confirm it shows in Products list.
6. Place an order for that product from the Customer App (or via
   `curl`/Postman against `/api/v1/orders`) as a separate customer
   account.
7. Back in Seller App → Orders → the new order should appear under
   "New Orders" with the customer's name/phone/address visible.
8. Accept → Mark Preparing → Mark Ready for Pickup, watching the
   status badge change each time.
9. For a COD order, tap "भुगतान मिल गया / Mark Payment Received" and
   confirm the payment status updates.

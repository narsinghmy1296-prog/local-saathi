# PROJECT_AUDIT.md — Local Saathi (audit performed on supplied ZIP)

This audit was done by reading the actual source in the supplied ZIP —
not by trusting old docs. Where old docs (`API_INTEGRATION_REPORT.md`,
`CHANGELOG_INTEGRATION.md`, `INTEGRATION_BASELINE.md`, `backend/docs/ARCHITECTURE.md`)
were accurate, this document says so and does not repeat every detail;
where this pass found something new, it's called out explicitly.

## 1. What actually exists in the ZIP

```
local-saathi-main/
├── backend/            FastAPI, real DB-backed, "Phase 6.5 hardened"
│   ├── app/            1,854 lines across models/routers/schemas/core
│   ├── tests/           391-line pytest suite (tests/test_workflow.py)
│   ├── seed.py, requirements.txt, .env.example, README.md
│   └── docs/ARCHITECTURE.md
├── customer_app/       Flutter app, fully wired to the real backend
│   └── lib/ (core, models, screens, services, state, widgets)
├── API_INTEGRATION_REPORT.md, CHANGELOG_INTEGRATION.md,
│   INTEGRATION_BASELINE.md   ← prior integration passes, verified below
└── render.yaml          Render.com deploy config (backend only)
```

There is **no** `seller_app/`, `admin_panel/`, or `delivery_app/` yet —
this ZIP is the Phase 1-7 output (backend + Customer App only), exactly
as the master prompt assumes. Phases 2-5 below build the rest.

## 2. Backend — verified state

- **Syntax**: every `.py` file under `backend/app/` and `backend/tests/`
  compiles cleanly (`python -m py_compile`). No import cycles found by
  inspection.
- **Cannot run `pytest` in this sandbox**: no internet access to `pip
  install` `fastapi`/`sqlalchemy`/etc. (confirmed — `pip install` fails
  with "No matching distribution found", not a version conflict). This
  matches the backend README's own disclosure that the test suite
  "could not be executed inside the sandbox that built it." **You must
  run it yourself** — see docs/DEPLOYMENT_GUIDE.md for the exact
  commands.
- **Auth/roles**: JWT via `python-jose`, bcrypt hashing, 4 roles
  (customer/seller/delivery/admin). Public self-registration as `admin`
  is explicitly blocked. `require_role()` + per-row ownership checks
  (seller-owns-product, seller-owns-order, delivery-owns-assignment,
  customer-owns-cart/address/order) are present on every sensitive
  endpoint I read, not just hidden in the UI.
- **State machines**: `app/core/state_machine.py` centralizes legal
  order/payment/delivery transitions (e.g. `placed→delivered` directly
  is rejected; only admin can force a payment-status override). This is
  real enforcement, not just documentation.
- **Checkout correctness**: `orders.py::checkout` re-reads price/stock
  from the DB inside one transaction (never trusts cart-cached price or
  anything the client sends), deducts stock, and rolls back atomically
  on any failure. Row-level locking (`with_for_update()`) is skipped on
  SQLite (documented, dev-only limitation) and active on Postgres.
- **Gap found and fixed in this pass**: the Admin Panel's required
  "Seller Management" / "Delivery Management" screens (list/search,
  approve/reject, activate/deactivate) had **no backend support beyond
  a single `approve` endpoint** — there was no way for any client to
  even list sellers or delivery partners awaiting approval. The
  existing test suite worked around this with a brute-force loop
  (`for sid in range(1, 10): approve(sid)`), which is a strong signal
  this was a real, unaddressed gap rather than an oversight in this
  audit. **Fixed**: added `GET /admin/sellers`, `GET
  /admin/sellers/{id}`, `POST /admin/sellers/{id}/reject`,
  `/deactivate`, `/activate`, and the equivalent four for
  `/admin/delivery-partners` — all additive, all audit-logged via the
  existing `AdminAction` table, all covered by new tests in
  `test_workflow.py`. See `docs/API_CONTRACT.md` for the full shape.
- **Not a gap, by design**: no `GET /products/{id}` (client resolves
  from the list — confirmed intentional and already handled correctly
  by the Customer App); no payment gateway (manual COD/UPI confirmation
  by design, per spec); no PDF invoice generation (JSON invoice only,
  documented as a same-day follow-up in the backend README).

## 3. Customer App — verified state

- Confirmed accurate against the real backend: `API_INTEGRATION_REPORT.md`
  at the repo root is a genuine, line-by-line integration audit from a
  prior pass (not aspirational) — I independently re-checked every
  endpoint it claims and it holds up. It already fixed a real bug
  (Address endpoints returning raw un-serializable SQLAlchemy objects)
  and several smaller ones (missing `rejected` status, invoice model
  mismatch, missing Profile screen).
- **New bug found in this pass**: `lib/core/api_endpoints.dart` had the
  backend base URL **hardcoded to a specific developer's LAN IP**
  (`http://192.168.43.40:8000`) — this only ever worked on that one
  Wi-Fi network; every other machine, tester, emulator, or real
  deployment would fail every single API call with no clear error.
  **Fixed**: now reads `API_BASE_URL` via `--dart-define` at build
  time, defaulting to the Android-emulator loopback (`10.0.2.2`) so a
  fresh checkout still works against a local `uvicorn --reload` with no
  extra flags. Production builds MUST pass the real API URL — see
  docs/DEPLOYMENT_GUIDE.md.
- **Cannot run `flutter analyze` / `flutter test` / `flutter build apk`
  in this sandbox**: no Flutter/Dart SDK is installed here, and there is
  no network access to install one. This is a hard environment
  limitation, not a decision — you must run these yourself (exact
  commands in docs/DEPLOYMENT_GUIDE.md) and treat that as the real
  Phase 1 sign-off, same caveat the backend README already gives for
  pytest.
- Architecture (Provider state management, a single `ApiClient` with
  centralized 401 handling, secure-storage-only token persistence,
  Hindi-first `AppTheme`/`app_strings.dart`) is solid and is exactly
  what the Seller/Delivery apps below reuse, to avoid re-inventing
  working patterns.

## 4. What Phase 1 stabilization actually did in this pass

1. Fixed the hardcoded-IP bug above (real bug, blocks everyone but the
   original developer).
2. Added the 8 missing admin management endpoints above (real gap,
   blocks all of Phase 3).
3. Re-ran `py_compile` after every change — stayed green throughout.
4. Did **not** touch anything already working: no renamed fields, no
   removed endpoints, no schema changes to existing tables.

## 5. Honest environment limitations (apply to every phase below)

This sandbox has **no internet access** (pip/npm/flutter pub all fail)
and **no Flutter/Node/Android SDK pre-installed**. Every phase after
this one produces real, complete source code, but the actual `pytest`,
`flutter analyze/test/build`, `npm run build`, and APK generation steps
must be run in your own machine — docs/DEPLOYMENT_GUIDE.md gives the
exact commands for each, and docs/TEST_REPORT.md marks every check
honestly as PASSED (ran here), NOT RUN (sandbox can't), or FAILED.

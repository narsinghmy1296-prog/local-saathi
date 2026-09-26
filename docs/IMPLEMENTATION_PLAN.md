# IMPLEMENTATION_PLAN.md — Local Saathi

## Where things stand after this pass

| Phase | Status |
|---|---|
| 0. Audit | ✅ Done — see `PROJECT_AUDIT.md`, `API_CONTRACT.md` |
| 1. Stabilize backend + Customer App | ✅ Done — 2 real bugs found & fixed (hardcoded IP, missing admin listing endpoints); syntax verified; `pytest`/`flutter` execution blocked by sandbox (no internet/SDKs) — commands given in `DEPLOYMENT_GUIDE.md` for you to run |
| 2. Seller App | ✅ Done — full Flutter app in `seller_app/`; 3 more real backend gaps found & fixed (seller self-profile, product image upload, order detail missing customer/address); see `seller_app/SELLER_APP_README.md` and `SELLER_APP_TEST_REPORT.md` |
| 3. Admin Web Panel | 🔜 Next |
| 4. Delivery Partner App | 🔜 After Admin Panel |
| 5. End-to-end integration pass | 🔜 Last, once 2-4 exist |

Each of Phases 2-4 is itself a multi-file application (auth, several
screens, state management, API service layer) — comparable in size to
the existing Customer App. Building all three plus a web Admin Panel
in a single pass, in one sandbox with no Flutter/Node SDKs to verify
against, risks producing code nobody has actually compiled. The plan
below builds them **one at a time, in working, buildable slices**, so
each phase can be hardened before the next starts.

## Phase 2 — Seller App (next)

Reuses the Customer App's proven architecture wholesale (same
`ApiClient`, `TokenStorage`, `AppTheme`, Provider state pattern) so it
is consistent and nothing is re-invented or re-debugged:

1. **Slice 1 — Auth + shell**: register (seller-specific fields:
   shop_name/owner_name/area/upi_id), login, pending/approved/rejected
   status screen (a seller who isn't approved yet sees a clear waiting
   screen instead of a broken dashboard), logout, session-expiry
   handling (reuse `ApiClient.sessionExpired` stream as-is).
2. **Slice 2 — Product management**: list own products (`GET
   /products?seller_id=`), add (with the mandatory "Other/अन्य" flow —
   category dropdown + free-text fallback + keywords chips), edit,
   stock update, deactivate.
3. **Slice 3 — Dashboard + Orders**: counts by status from `GET
   /orders` (seller-scoped automatically by the backend — no
   seller-side filtering needed), order detail, accept/reject/mark
   preparing (`POST /orders/{id}/status`), mark payment received.
4. **Slice 4 — Profile**: shop details (read from `/auth/me` + seller
   profile — note: **no seller-profile-edit endpoint exists yet**; if
   you want sellers to edit shop name/area/UPI after registration,
   that's a small additive backend endpoint to add first, flagged here
   rather than faked in the UI).

## Phase 3 — Admin Web Panel

Stack decision (per master prompt §3, "if the repo has an established
frontend framework, reuse it; otherwise choose a stable, simple
stack and document the choice"): **the repo has no existing frontend
framework** (Customer App is Flutter/mobile, not web). For a web Admin
Panel, a plain Vite + React + TypeScript SPA calling the same REST API
is the simplest maintainable choice that needs no server-side
rendering infrastructure and builds to static files deployable
anywhere (Render static site, Nginx, etc.) — documented here per the
instruction to record the choice, not asked about.

1. Login (admin only) + protected-route guard.
2. Dashboard (`GET /admin/dashboard`).
3. Seller Management using the endpoints added in Phase 1
   (`GET/POST /admin/sellers*`) — this was the actual blocker; it's
   already resolved.
4. Category management (existing CRUD endpoints).
5. Product moderation (`GET /products/other/list`, `POST
   /products/{id}/move-category`).
6. Order + Delivery-partner management, audit log viewer.

## Phase 4 — Delivery Partner App

Same reuse strategy as Phase 2. Auth → assignments list → task detail
→ status workflow (`picked_up → out_for_delivery → delivered`) →
COD/UPI confirmation. Smaller surface than the Seller App since
`/delivery/*` is already a small, complete router.

## Phase 5 — End-to-end integration

Once 2-4 exist: run the 19-step order cycle from the master prompt
against all four clients hitting one running backend instance, fix any
cross-client inconsistency found, and produce `TEST_REPORT.md` with
honest pass/fail/not-run status for every check.

## Standing rules carried through every phase (already applied in Phase 1)

- Never fake data client-side when a real endpoint is missing — add
  the backend endpoint (with auth, schema, and a test) instead, as was
  done for `/admin/sellers` and `/admin/delivery-partners` this pass.
- Every new endpoint gets logged in `API_CONTRACT.md` in the same pass
  it's written, not after.
- No renames of existing working fields/routes — only additive
  changes, exactly as the master prompt requires.
- Every phase ends with an honest status: what compiled/ran here vs.
  what needs your machine's SDKs, with exact commands either way.

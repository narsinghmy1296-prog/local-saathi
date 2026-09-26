# Local Saathi — Admin Control Panel

A React + TypeScript + Vite web app for platform admins: seller and
delivery-partner approval, product/category moderation, order and
delivery management, sales reports, and an audit log. It talks only to
the real Local Saathi FastAPI backend — see
`docs/ADMIN_PANEL_API_AUDIT.md` (in the repo root) for the exact
endpoint each screen uses.

## Requirements

- Node.js 18+ and npm
- A running Local Saathi backend (see `backend/README.md`) reachable
  over HTTP from wherever you run this panel

## Setup

```bash
cd admin_panel
cp .env.example .env
# edit .env and set VITE_API_BASE_URL to your backend's base URL,
# e.g. http://127.0.0.1:8000 for a local backend
npm install
npm run dev
```

The dev server prints a local URL (default `http://localhost:5173`).
Log in with an admin account — the seed script in `backend/seed.py`
creates one at phone `9999999999` / password `admin123` for local
testing; change this in production.

## Available scripts

| Command | What it does |
|---|---|
| `npm run dev` | Start the Vite dev server with hot reload |
| `npm run build` | Type-check (`tsc -b`) then produce a production build in `dist/` |
| `npm run preview` | Serve the production build locally, to sanity-check it before deploying |
| `npm run lint` | Type-check only (`tsc --noEmit`), no build output |

## Deployment

`npm run build` produces a fully static `dist/` folder — deploy it to
any static host (Render Static Site, Netlify, Vercel, Nginx, S3 +
CloudFront, etc.). Because this is a client-side-only SPA using
`react-router-dom`'s browser router, configure your host to rewrite
all unknown paths to `/index.html` (an SPA fallback), or deep links
like `/orders/42` will 404 on a hard refresh.

Set `VITE_API_BASE_URL` in your hosting provider's build-time
environment variables — Vite bakes `VITE_*` variables into the build
at build time, so it must be set **before** running `npm run build`,
not just at runtime.

## Security notes

- The JWT is stored in `localStorage`; on any `401` response the app
  clears it and redirects to `/login`.
- The login screen itself rejects any non-`admin` role, and every
  admin-only page additionally re-checks the role from `GET /auth/me`
  on load. **This is a UX convenience, not the actual security
  boundary** — every real admin endpoint enforces the `admin` role
  server-side (`require_role(["admin"])` in the FastAPI backend), so
  even a tampered local token cannot access another role's data.
- There is intentionally no admin self-registration screen anywhere in
  this app.
- No secrets (API keys, the backend's `SECRET_KEY`, database URLs)
  are read, stored, or displayed anywhere in this app.

## Project structure

```
admin_panel/
├── src/
│   ├── api/client.ts        — fetch wrapper: base URL from env, JWT
│   │                           header, 401 → logout, typed errors
│   ├── auth/AuthContext.tsx — login/logout/session state, role check
│   ├── components/          — shared UI: Layout, StatCard, StatusBadge,
│   │                           Pagination, ConfirmButton, Toast, etc.
│   ├── pages/                — one file per screen (see the table below)
│   ├── types.ts              — TS types matching the real API response
│   │                           shapes (cross-checked against the actual
│   │                           backend source, not guessed)
│   ├── App.tsx                — routes + the RequireAdmin guard
│   ├── main.tsx                — app entry point
│   └── styles.css              — hand-written, responsive, no CSS framework
```

| Page | Route | Backend endpoints used |
|---|---|---|
| Login | `/login` | `POST /auth/login`, `GET /auth/me` |
| Dashboard | `/` | `GET /admin/dashboard` |
| Sellers | `/sellers` | `GET /admin/sellers`, approve/reject/activate/deactivate |
| Products | `/products` | `GET /admin/products`, `PUT/DELETE /products/{id}`, `POST /products/{id}/activate`, `POST /products/{id}/move-category` |
| Categories | `/categories` | `GET /categories`, `POST/PUT/DELETE /categories/{id}` |
| Orders | `/orders`, `/orders/:id` | `GET /admin/orders`, `GET /orders/{id}`, `POST /orders/{id}/status`, `POST /orders/{id}/payment/mark-received` |
| Delivery | `/delivery` | `GET /admin/delivery-partners`, `GET /admin/deliveries`, `POST /admin/deliveries/{id}/reassign` |
| Reports | `/reports` | `GET /admin/orders` (aggregated client-side), `GET /admin/dashboard` |
| Audit Log | `/audit-log` | `GET /admin/audit-logs` |
| Settings | `/settings` | `GET /auth/me`, `POST /admin/delivery-zones` |

## Known limitations (see `docs/ADMIN_PANEL_API_AUDIT.md` for the full list)

- No PDF invoice generation — the Order Detail page links to the
  backend's JSON invoice endpoint instead.
- No payment gateway integration — payment status is always shown and
  edited exactly as the backend reports/accepts it; nothing is
  auto-verified.
- No "unassigned delivery queue" — the current backend design assigns
  a delivery partner atomically at the moment an order moves to
  `delivery_assigned`, so there is no intermediate unassigned state to
  show.
- Category duplicate-name checking is client-side only (see the audit
  doc for why, and what a proper fix would require).

## Was this actually built and run?

Source code: yes, by hand, file by file. `npm install` / `npm run
build` / `npm run dev` / `tsc --noEmit`: **could not be executed in
the sandbox this was built in** — it has no internet access, so `npm
install` cannot reach the npm registry (confirmed directly: it
returns `403 Forbidden`). See
`docs/ADMIN_PANEL_TEST_REPORT.md` for the complete, honest account of
what was and wasn't verified, and run the commands above yourself
once you have this on a machine with internet access.

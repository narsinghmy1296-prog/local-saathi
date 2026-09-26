# Local Saathi — Customer Android App (Phase 7)

Flutter/Dart customer app for the Local Saathi FastAPI backend. This file
supersedes `PROJECT_README.md` (which was written before the real backend
source code was available and marked everything "ASSUMED" — see
`../API_INTEGRATION_REPORT.md` for the now-CONFIRMED API contract map and
the full list of compatibility bugs found and fixed in this pass).

---

## Project structure

```
LOCAL_SAATHI_PROJECT/
├── backend/                  FastAPI backend (Phase 6.5, hardened)
├── API_INTEGRATION_REPORT.md ★ read this for the endpoint-by-endpoint contract
└── customer_app/             this Flutter app
    ├── pubspec.yaml
    ├── ANDROID_MANIFEST_ADDITIONS.md   ← apply after `flutter create .`
    ├── CUSTOMER_APP_README.md          ← this file
    └── lib/
        ├── main.dart
        ├── core/            api_client, api_endpoints, api_exceptions,
        │                    app_strings (Hindi/English), app_theme, token_storage
        ├── models/          user, category, product, cart, address, order, invoice
        ├── services/        one per resource — pure API calls, no UI
        ├── state/           AuthProvider, CartProvider, LocaleProvider
        ├── widgets/         product_card, category_chip, confirm_dialog,
        │                    order_status_stepper
        └── screens/
            ├── splash_screen.dart
            ├── auth/            login, register
            ├── home/            home_shell (bottom nav), home_screen
            ├── search/          voice_search_sheet, search_results_screen
            ├── product/         product_detail_screen
            ├── cart/            cart_screen
            ├── address/         address_list_screen, address_form_screen
            ├── checkout/        checkout_screen
            ├── orders/          orders_screen, order_detail_screen, invoice_screen
            ├── profile/         profile_screen  (added in this pass)
            └── common/          state_widgets (Loading/Error/Empty views)
```

No `android/`/`ios/` folders are included in this package — see setup step 3.

---

## Flutter version requirement

`environment: sdk: ">=3.0.0 <4.0.0"` in `pubspec.yaml` — any current Flutter
stable channel install (Flutter 3.16+) satisfies this. Check with:

```bash
flutter --version
flutter doctor
```

`flutter doctor` should show no unresolved issues for Android toolchain
before you try to build/run.

## Installing Flutter (if not already installed)

1. Download the Flutter SDK for your OS from the official Flutter site.
2. Add `flutter/bin` to your PATH.
3. Run `flutter doctor` and follow its instructions (Android Studio +
   Android SDK + an accepted license is the minimum for Android builds).

---

## Setup instructions

1. Make sure this `customer_app/` folder sits next to `backend/` (as shown
   in the structure above) — they're independent projects, nothing links
   them at the code level, only over HTTP at runtime.
2. Generate the native platform folders (not included in this package):
   ```bash
   cd customer_app
   flutter create .
   ```
   This fills in `android/`, `ios/`, etc. around the existing `lib/` and
   `pubspec.yaml` **without overwriting them**.
3. Apply the manifest changes in `ANDROID_MANIFEST_ADDITIONS.md`
   (INTERNET + RECORD_AUDIO permissions, speech-recognition `<queries>`).
4. Configure the backend URL — see "Configuring the API URL" below.
5. Install packages and run:
   ```bash
   flutter pub get
   flutter analyze
   flutter test
   flutter run
   ```

## Running the backend

```bash
cd backend
python -m venv venv && source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env      # edit SECRET_KEY at minimum
python seed.py
uvicorn app.main:app --host 0.0.0.0 --reload
```

`--host 0.0.0.0` (not just `127.0.0.1`) is required so an emulator or a
physical phone on the same network can actually reach it.

## Configuring the API URL

`lib/core/api_endpoints.dart` holds `ApiConfig.baseUrl`. There is no
separate DEV/PROD build-flavor wiring in this MVP (deliberately kept
simple) — change the one constant for whichever target you're running
against:

| Target | `baseUrl` |
|---|---|
| Android Emulator | `http://10.0.2.2:8000` |
| Physical Android phone | `http://<your-PC-LAN-IP>:8000` (same Wi-Fi as the phone) |
| Deployed pilot server | `https://your-real-domain` |

## Connecting an Android emulator

1. Start the backend (see above).
2. Set `baseUrl` to `http://10.0.2.2:8000`.
3. Android Studio → Device Manager → start an emulator (API 30+ recommended).
4. `flutter run`, pick the emulator.
5. Voice search may report "not available" on a bare AOSP emulator image
   without Google Play services — this is expected; test voice search on
   a real device.

## Connecting a physical Android phone

1. Enable Developer Options + USB debugging, connect via USB (or Wi-Fi debugging).
2. Find your PC's LAN IP (`ipconfig` on Windows / `ifconfig` or `ip addr` on
   Mac/Linux). Phone and PC must be on the **same Wi-Fi network**.
3. Set `baseUrl` to `http://<that-IP>:8000`.
4. `flutter run`, pick your phone, grant the microphone permission prompt
   on first mic tap.

## Building an APK

```bash
flutter build apk --debug     # for quick testing
flutter build apk --release   # for a real device install outside Android Studio
```

---

## How voice search works

`services/voice_search_controller.dart` wraps the `speech_to_text` package
(a real, maintained Flutter plugin — not a stub). Flow: mic tap → request
`RECORD_AUDIO` permission → start listening → show live partial text →
on final result, show "आपने कहा: ..." with Edit / Search Again / Retry
options → confirmed text is sent to `GET /search?q=...`, the same
endpoint typed search uses. The device's current input locale is used
rather than hard-coding `hi_IN`, so Hindi/English/Hinglish all work as far
as the phone's own speech engine supports.

---

## Known limitations

- **No offline mode / caching** — every screen re-fetches from the
  network; fine for a pilot, worth revisiting for low-bandwidth villages.
- **No image caching package** (`cached_network_image` deliberately left
  out to keep dependencies minimal) — product images re-download when a
  list rebuilds.
- **Invoice is JSON-rendered, not a PDF** — matches the backend, which
  doesn't generate PDFs yet.
- **Order status history makes a second network call** for the same data
  `GET /orders/{id}` already returns — works correctly, just not optimal;
  a good small follow-up if you want to trim one round-trip.
- **No profile-edit API** — the Profile screen is read-only by design
  because the backend has none (`GET /auth/me` only).
- **Not run in a real Flutter/Android environment yet** — see Testing
  section below.

---

## Testing instructions

### What could NOT be verified in the environment that built this

The sandbox that produced this code has **no Flutter/Dart SDK and no
internet access** to install one. `flutter pub get`, `flutter analyze`,
`flutter test`, and `flutter build apk` have **not been run**. What was
done instead: every `.dart` file was read in full and manually
cross-checked against the real backend source (see
`API_INTEGRATION_REPORT.md`), plus a scripted brace/paren/bracket balance
check across all 40+ files as a rough syntax sanity pass. Treat your first
real `flutter pub get && flutter analyze` as the actual first checkpoint,
not a formality — a real compiler catches things manual review cannot.

### Steps to run for real

```bash
cd customer_app
flutter create .
flutter pub get
flutter analyze          # fix any compile errors this surfaces
flutter test             # no widget tests are included yet — this mainly
                          # confirms the project itself compiles
flutter build apk --debug
flutter run               # with an emulator or device attached
```

### Manual walkthrough (matches the spec's acceptance checklist)

1. App launches → splash → login screen.
2. Register a new customer.
3. Log in with that customer.
4. Confirm JWT is stored (app stays logged in after a hot restart).
5. Home loads categories + products from the real backend.
6. Typed search works.
7. Voice search works (real device, mic permission granted).
8. Tap a product → product detail loads.
9. Add to cart → confirmation dialog → quantity increase/decrease in Cart tab.
10. Add an address (must be inside a delivery zone the backend admin has
    configured — `seed.py` creates pincode `000000` for exactly this).
11. Checkout → COD → place order.
12. Order appears in "My Orders" with a correct item count.
13. Order detail shows items + status history.
14. Invoice screen renders a clean itemized receipt.
15. Profile tab shows name/phone, links to Addresses/Orders, and Logout works.
16. Log out, then try opening a protected screen — should not be reachable
    without logging back in.
17. Turn off the backend mid-session and try an action — should show a
    friendly Hindi network-error message, not crash.

# StockRoom — Knowledge Extraction

Source: `/Users/MacBook/Desktop/stocktake_app` (Flutter, iVend Stock Take app, v4.3.2+38).
This document captures the patterns ShelfEye reuses and the ones it deliberately drops.

---

## 1. Product architecture

- **Single Flutter codebase**, iOS + Android, no platform UI — all pixels drawn by Flutter.
- **Layered, flat:** `screens/` → `services/` (state + I/O) → `models/` (pure data). No `repositories/` folder — `ApiService` doubles as client + repository. ShelfEye **adds a repository layer** (the one architectural upgrade over StockRoom).
- **State:** one app-wide `ChangeNotifier` (`AppState`) provided at the root via `provider`. Ephemeral UI state stays in `setState`.
- **Entry point** runs an async boot: `WidgetsFlutterBinding.ensureInitialized()` → install logging → global error handlers → load config → `runApp`.

## 2. API architecture

- Base URL is **hardcoded shape**: `http://{host}/iVendAPI/iVendAPI.svc/WebAPI` (HTTP only).
- One `ApiService` holding the `AppConfig`; every call builds a `Uri` via `_buildUri` (which **percent-encodes** query params via `Uri.replace`).
- Auth is **per-request headers**: `UserName` + `Password` (the *API* account, distinct from the operator login). The API is **stateless** — no tokens, no sessions, no cookies.
- Response handling normalizes iVend's chaos: `_parseBool` accepts bool / `"true"` / `"Success"` / XML fragments / maps; `_parseList` digs lists out of `Data`/`Items`/`Result`/… wrappers.
- **No automatic retries** anywhere (deliberate — `SaveInventoryCounting` is not idempotent).
- Adaptive timeouts: 8s when the server was recently reachable, 30s when cold (IIS app-pool warm-up).

## 3. Authentication methods

- **API credentials** (`apiUserId` / `apiPassword`) → sent as headers on every call. Stored in `flutter_secure_storage` (Keychain/Keystore) with **write-then-read-back verification**; non-sensitive config in `SharedPreferences`.
- **Operator login** → `GET /ValidateUser/?UserId=&Password=` returns `200` + `true`/`false`. Invalid credentials are `200 + false`, **not** an HTTP error.
- ShelfEye V1 is **lookup-only** → it needs the **API credentials** (for headers) but **no operator login** (no per-user actions). This is a key simplification.

## 4. Data models

- `Product` — defensive `fromJson` resolving id/name/code/barcode and **UOM id via a 9-field priority list** (`_barcodeUOMId` injected from the outer BarcodeProduct envelope, then `InventoryUOMId`, …). Carries iVend product-type flags and a `countabilityError` getter (stocktake-only; ShelfEye drops it).
- `Warehouse` — dual-purpose: represents stores (`/GetAllStores/`, `Key`=store id, `CashCustomerId`) and warehouses (`/GetWarehouse/`, `IsLocationEnabled`).
- `Location`, `StockTakeItem` — stocktake-only, not needed by ShelfEye.

## 5. Barcode handling

- `mobile_scanner` package; a modal bottom-sheet scanner (`_BarcodeScannerSheet`) with a once-latch (`_scanned`) so one capture = one result, torch toggle, and an align frame.
- Resolution order on scan: **`GetProductByBarCode` first, then `GetProduct` by id as fallback** — the exact pattern ShelfEye reuses.
- Manual entry: a text field submitting the same lookup path. ShelfEye supports both barcode and product-code entry through this path.

## 6. Product lookup logic (the core ShelfEye reuses)

```
code (scan/type)
 → GetProductByBarCode/?barCode=&vendorId=   (outer envelope carries UOMId → _barcodeUOMId)
 → if null: GetProduct/?id=
 → if uomGroupId present & != "0": GetUOMGroup/?id=  → base + alternate UOMs
```
- **Generation counters** guard rapid scans: each lookup increments a counter, captured before the first `await`; if it advanced by the time a response returns, the result is dropped ("latest wins"). ShelfEye keeps this.
- **Screen-lifetime caches** keyed by code avoid re-fetching the same product.

## 7. Inventory concepts

- StockRoom **submits** counts (`SaveInventoryCounting`) — out of ShelfEye scope.
- On-hand exists in `GetProduct` → `ProductInventoryList[]` per warehouse (`InStockQuantity`, `AvailableQuantity`, `Price`). ShelfEye V1 does **not** display stock (roadmap item) but the model leaves room.

## 8. UOM handling

- `GetUOMGroup` returns an `ArrayOfUOMGroup`; StockRoom collects the base UOM once + all alternates, skipping `ToDelete`. Guards `uomGroupId == "0"` (iVend's "no real group") to avoid a wasted round-trip.
- **Conversion fields** StockRoom didn't use but ShelfEye does: each entry has `BaseUOMId`, `AlternateUOMId`, `BaseQuantity`, `AlternateQuantity` → conversion = `BaseQuantity / AlternateQuantity` base units per alternate unit.

## 9. Pricing logic

- StockRoom does **not** price (it counts). Pricing in iVend is `GetItemSalesPrice/?productid&customerid&storeid&uomid&quantity` → `ItemPrice`, `Discount`, `DiscountType`. The Handheld's Item Lookup uses exactly this. ShelfEye adopts it **per UOM**.

## 10. Offline handling

- StockRoom persists a **session draft** to `SharedPreferences` and has a 48h offline **licensing** cache. ShelfEye V1 is online-only (lookup needs the live server); an offline **recent-lookups cache** is a documented roadmap item.

## 11. Error handling (StockRoom's strongest area — fully reused)

- `ApiException` carries `statusCode` + a **`friendlyMessage`** / `userMessage`.
- `friendlyHttpMessage(code, body)` maps: iVend JSON `Message` first → **SQL-down detection** (`CXSDataException`/`SqlException` → "server cannot reach its database") → **IIS custom error pages** (parsed from `<title>`, refined by substatus: 401/403/404/413/500.x) → **503** (HTTP.sys, app-pool) → bare status fallback.
- HTML bodies are rejected by `_extractApiMessage` so raw IIS HTML never reaches the UI.
- ShelfEye ports `friendlyHttpMessage` wholesale — it's API-version- and region-agnostic.

## 12. Synchronization patterns

- None beyond the draft + submission-counter persistence (stocktake-only). Reachability is polled (3-min timer) + `connectivity_plus` events. ShelfEye keeps a lightweight reachability ping for the lookup screen footer.

## 13. UI/UX conventions (reused)

- Design system in `app_theme.dart`: warm-paper palette, single graphite-green accent, **Inter** for UI + **JetBrains Mono** for codes/numerics, Material 3. ShelfEye reuses the token approach (trimmed).
- `Pressable` scale-on-press, canonical `ConfirmDialog`, bottom-sheet scanner.

## 14. Existing retail workflows

- Configure server + credentials (+ store) → login → pick warehouse → scan/count → submit. ShelfEye collapses this to: **configure server + credentials (+ store for pricing) → scan/type → view**.

## 15. What ShelfEye deliberately drops from StockRoom

Operator login, warehouse selection, counting/edit/submit, draft persistence, device-licensing gate (Supabase), submission counters, location handling, countability blocking. These are all stocktake concerns irrelevant to a price checker.

# ShelfEye — Architecture

A lightweight, lookup-only retail price checker. Online, stateless, fast.

---

## 1. Layering (cleaner than StockRoom — adds a repository)

```
UI (screens/widgets)
  └─ depends on → LookupService / ConfigService   (services/)
        └─ depends on → ProductRepository          (repository/)
              └─ depends on → ApiClient            (api/)  ← only place HTTP lives
                    └─ ApiException + friendlyHttpMessage  (api/)
models/  ← pure data (Product, UomOption, ProductLookupResult, AppConfig, StoreRef)
core/    ← theme, result types, constants
```

- **api/** — `ApiClient` (transport: build Uri, headers, timeout, logging, status→`ApiException`), `api_exception.dart` (+ the ported `friendlyHttpMessage` mapper). Nothing above this layer knows about `http`.
- **repository/** — `ProductRepository`: orchestrates the multi-call lookup (barcode→id fallback→UOM group→per-UOM price) and returns a single `ProductLookupResult`. This is the brain; it's pure Dart, unit-testable, no Flutter.
- **services/** — `ConfigService` (persist server settings + credentials + store), `LookupService`/`AppState` (`ChangeNotifier` exposing lookup state to the UI), reachability.
- **screens/** — `LookupScreen` (search + result), `ConfigScreen` (server setup), barcode scanner sheet.
- **models/** — immutable data + `fromJson`.
- **core/** — `AppTheme`, `Result<T>` (success/failure), constants.

## 2. Data models

- `AppConfig` — `host`, `apiUserId`, `apiPassword`, `storeId`, `cashCustomerId`, `storeName`.
- `StoreRef` — from GetAllStores: `key`(storeId), `id`, `name`, `cashCustomerId`.
- `Product` — `id`, `name`, `code`, `barcode`, `baseUomId`, `uomGroupId`.
- `UomOption` — `id`, `name`, `isBase`, `baseQuantity`, `alternateQuantity`, `price?`. Computed `conversionToBase = baseQuantity / alternateQuantity`.
- `ProductLookupResult` — `product`, `List<UomOption> uoms`, `basePrice?`, `priced` flag, `notFound` flag.

## 3. Lookup orchestration (`ProductRepository.lookup(code)`)

```
1. GetProductByBarCode(code)          → product (+ _barcodeUOMId)
2. if null → GetProduct(code)         → product   ; else notFound
3. if uomGroupId valid (≠ null/""/"0") → GetUOMGroup → base + alternates (skip ToDelete)
   else → single UOM from product.baseUomId (+ GetUOM for description)
4. if store configured → for each UOM: GetItemSalesPrice(prod, cashCustomer, store, uom, 0)
   → attach price ; else → uoms priced=false
5. return ProductLookupResult
```
- **Generation/latest-wins** guarding handled in `LookupService` (mirrors StockRoom) so a slow scan A can't overwrite scan B.
- **Cache**: in-memory `Map<code, ProductLookupResult>` for the session (instant repeat lookups).

## 4. Error handling layer

- All non-2xx → `ApiException(message, statusCode, friendlyMessage)`.
- `friendlyHttpMessage(code, body)` ported verbatim from StockRoom: iVend JSON `Message` → SQL-down detection → IIS page parse (401/403/404/413/500.x) → 503 → fallback.
- UI always shows `e.userMessage`. Network/timeout/socket → humanised messages.
- A `Result<T>` type (`Ok`/`Err`) is used by the repository so the UI gets either data or a message, never a raw throw.

## 5. State & UX

- `provider` + `ConfigService` + a `LookupController` (`ChangeNotifier`): states = idle / searching / found / notFound / error.
- `LookupScreen`: search row (barcode/code) + scan button → result card (name, code, barcode, base UOM + price) → multi-UOM list (name · price · "1 Pack = 6 EA"). Clear button. Reachability dot in footer.
- Speed: result renders the instant the repository returns; cached codes are instant.

## 6. Config & auth

- Mirrors StockRoom's split: non-sensitive (`host`, `storeId`, `cashCustomerId`, `storeName`) in `SharedPreferences`; credentials in `flutter_secure_storage` with read-back verification.
- Setup flow: enter host + API user/pass → Test (`CheckAPIConnection`) → pick store (`GetAllStores`, captures `Key` + `CashCustomerId`) → Save. Store is **optional** — without it, lookup still shows product + UOMs, just no price.

## 7. Dependencies (lean)

`http`, `provider`, `shared_preferences`, `flutter_secure_storage`, `mobile_scanner`, `google_fonts`. (No uuid/connectivity/share/device_info/crypto/path_provider — those were stocktake/licensing concerns.)

## 8. Non-goals for V1

No login, no counting, no stock display, no offline cache, no images, no promotions, no customer tiers — all in `future-enhancements.md`. Architecture leaves seams for each (see that doc).

# ShelfEye

A fast, lightweight **iVend retail product lookup** (price checker). Complements
StockRoom — lookup only, no stocktaking.

## What it does (V1)
- Scan a barcode, or type a barcode / product code → **Search**
- Shows **name, code, barcode, base UOM, base price**
- Multiple UOMs → each shown with **price** and **conversion** ("1 Pack = 6 EA")

## Run
```bash
flutter pub get
flutter run
```
On first launch, open **⚙ settings** → enter iVend host + API user/password →
**Test** → (optionally) pick a store for pricing → **Save**.

## Architecture (see `docs/shelfeye-architecture.md`)
```
screens → services (AppState, ConfigService) → repository (ProductRepository) → api (ApiClient)
models/ (pure data)   core/ (theme, Result)
```
- `api/` is the only place HTTP lives; `ApiException` + `friendlyHttpMessage` map every failure (IIS pages, SQL-down, 503) to readable text.
- `ProductRepository` orchestrates: GetProductByBarCode → GetProduct → GetUOMGroup → GetItemSalesPrice. Pure Dart, testable.

## Endpoints used (documented only — see `docs/ivend-api-analysis.md`)
`GetProductByBarCode`, `GetProduct`, `GetUOMGroup`, `GetUOM`, `GetItemSalesPrice`,
`GetAllStores`, `CheckAPIConnection`. No raw-SQL `GetQueryResult`. No write endpoints.

## Knowledge base (`docs/`)
- `stockroom-analysis.md` — patterns extracted/reused from StockRoom
- `ivend-handheld-analysis.md` — behavioural reference (Item Lookup)
- `ivend-api-analysis.md` — endpoint selection + contracts
- `shelfeye-architecture.md` — design
- `future-enhancements.md` — roadmap
- `gap-analysis.md` — StockRoom vs Handheld vs ShelfEye
- `reference/` — the iVend API reference + curated Handheld source

## Not in V1 (roadmap only)
Stock on hand, multi-store, promotions, customer tiers, product images,
description search, recent lookups, favorites, offline cache.

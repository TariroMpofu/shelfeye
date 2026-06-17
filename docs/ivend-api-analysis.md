# iVend API — Endpoint Analysis & Selection for ShelfEye

Primary knowledge base: `docs/reference/ivend_api_reference.md`.
**Rule: only documented endpoints are used.** All endpoints below were confirmed present in that reference.

Base URL shape: `http://{host}/iVendAPI/iVendAPI.svc/WebAPI/<Endpoint>/`
Auth: headers `UserName` + `Password` on every request. Stateless (no tokens/sessions).

---

## 1. Endpoint selection for ShelfEye V1

| ShelfEye need | Endpoint chosen | Why |
|---|---|---|
| **Barcode lookup** | `GET /GetProductByBarCode/?barCode=&vendorId=` | Direct barcode→product; outer envelope carries `UOMId` (the scanned pack's UOM). Primary path. |
| **Product code lookup** | `GET /GetProduct/?id=` | Looks up by product Id/code; also the fallback when a barcode doesn't resolve. |
| **UOM retrieval (multi-UOM)** | `GET /GetUOMGroup/?id={uomGroupId}` | Returns base + alternate UOMs **with conversion quantities**. |
| **Single UOM detail** | `GET /GetUOM/?id=` | Resolves a bare UOM id → description when no group. |
| **Pricing (per UOM)** | `GET /GetItemSalesPrice/?productid&customerid&storeid&uomid&quantity` | The authoritative sales price; called once per UOM. |
| **Store + cash customer** (setup) | `GET /GetAllStores/` | Supplies `storeId` (`Key`) and `CashCustomerId` needed by the price call. |
| **Reachability** | `GET /CheckAPIConnection/` | Footer health indicator + pre-flight. |

## 2. Request/response contracts used

### GetProductByBarCode
`?barCode={code}&vendorId=` → `{ "Product": { Id, Description, BarCode, InventoryUOMId, UOMGroupId/UOMGroupKey, ... }, "UOMId": "<scanned pack uom>" }`.
The outer `UOMId` is injected onto the product as `_barcodeUOMId` (highest-priority UOM source), mirroring StockRoom.

### GetProduct
`?id={code}` → product object incl. `Description`, `InventoryUOMId`, `UOMGroupId`, and `ProductInventoryList[]` (per-warehouse `InStockQuantity`, `AvailableQuantity`, `Price`). V1 reads identity + UOM group; inventory/price-from-inventory is roadmap.

### GetUOMGroup  →  `ArrayOfUOMGroup`
Each `UOMGroup`: `BaseUOMId`, `BaseUOMDescription`, `AlternateUOMId`, `AlternateUOMDescription`, **`BaseQuantity`**, **`AlternateQuantity`**, `ToDelete`.
- Distinct UOM set = base (once) + all alternates, skipping `ToDelete == true`.
- **Conversion**: `AlternateQuantity` alternate units = `BaseQuantity` base units →
  base-units-per-alternate = `BaseQuantity / AlternateQuantity`
  (e.g. `AlternateQuantity=1, BaseQuantity=6` → 1 Pack = 6 Each).
- Guard `uomGroupId == "0"` (iVend "no real group") → skip the call.

### GetItemSalesPrice  →  `ItemSalePrice`
`?productid&customerid&storeid&uomid&quantity` → `{ ItemPrice, Discount, DiscountType, UOMId, StoreId, CustomerId, Quantity }`.
- Called **once per UOM** to build the per-UOM price list.
- `customerid` = store's `CashCustomerId` (default retail price); `storeid` = store `Key`; `quantity` = 0 (Handheld convention) or 1.
- **Rule:** treat `ItemPrice == 0` as "no special price" (Handheld parity).

### GetAllStores  →  array; ShelfEye keeps `Key` (storeId), `Id`, `Description`, `CashCustomerId`.

### Error codes (per reference, all endpoints): 200 / 400 / 401 / 404 / 500.
Plus IIS-level pages (401/403/404/413/500.x) and HTTP.sys 503 (app-pool) — all mapped client-side.

## 3. Pricing strategy decision (documented assumption)

V1 has **no warehouse selection** (lookup is store-level, not bin-level). Therefore:
- **Displayed price = `GetItemSalesPrice` per UOM** for the configured store + its cash customer. This is the "shelf price" a normal customer pays — exactly right for a price checker.
- We do **not** use `ProductInventoryList[].Price` in V1 because that is per-warehouse and V1 doesn't pick a warehouse. (Roadmap: stock-on-hand + warehouse → can switch/augment.)
- If the store is not configured, ShelfEye still shows product + UOMs **without price** (graceful degradation) rather than failing.

## 4. Endpoints explicitly NOT used (and why)

- `ExecuteQueries` / `GetQueryResult` — documented, but take **raw SQL**; rejected to avoid DB-schema coupling (the Handheld's approach). Costs us the "browse all products" list → roadmap "search by description".
- `ValidateUser` / `ValidateUserWithDeviceId` — no operator login in a lookup-only app.
- `SaveInventoryCounting`, `PrintItemLabels`, all `Save*` — write operations, out of V1 scope.

## 5. Region/locale correctness

Quantities and prices are sent/received as **JSON numbers** (culture-invariant, always dot). Safe against any Windows regional setting on the iVend server. Any user-entered decimals are normalised comma→dot before parse.

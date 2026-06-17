# ShelfEye — Future Roadmap (NOT implemented in V1)

Each item lists the documented endpoint/field it would use and the architectural seam
already left in V1 so it can be added without a rewrite.

| Feature | Data source (documented) | Seam in V1 |
|---|---|---|
| **Product image display** | iVend product image fields / external URL (verify in reference before use) | `Product` model is the single render source; add `imageUrl` + a card slot. |
| **Stock on hand** | `GetProduct` → `ProductInventoryList[].InStockQuantity / AvailableQuantity` | Already returned by the call we make; add warehouse selection + parse list. |
| **Multi-store stock** | `ProductInventoryList[]` (all warehouses) + `GetAllStores`/`GetWarehouse` | Same payload already holds every warehouse row; add a per-store table. |
| **Promotions** | price/promotion fields on transaction/price responses | `UomOption.price` becomes a richer `PriceInfo {price, promo, discount, discountType}` — `GetItemSalesPrice` already returns `Discount`/`DiscountType`. |
| **Customer price tiers** | `GetItemSalesPrice` `customerid` param | Config already stores a customer id; add a customer picker, re-price. |
| **Alternative barcodes** | barcode resolution endpoints / product barcode list | Lookup path already normalises many → product; surface the list on `Product`. |
| **Product search by description** | a documented product-list endpoint **if one exists**; otherwise deferred (we refuse the Handheld's raw-SQL `GetQueryResult` route) | `LookupService` interface takes a query; add a `searchByDescription` repository method when a typed endpoint is available. |
| **Recent lookups** | local only | Repository already returns `ProductLookupResult`; persist the last N to `SharedPreferences`. |
| **Favorites** | local only | Same persistence seam as recent lookups. |
| **Offline cache** | local mirror of `ProductLookupResult` | The in-memory session cache becomes a persisted cache; add TTL + "stale" badge. |

## Principles to preserve as it grows
- **Only documented endpoints.** No raw SQL via `ExecuteQueries`/`GetQueryResult`.
- **HTTP stays in `api/`**; everything else depends on the repository.
- **Region-safe numbers** (invariant JSON), **mapped errors** (`friendlyHttpMessage`), **latest-wins** lookups.
- Keep it a price checker: any write feature belongs in StockRoom, not ShelfEye.

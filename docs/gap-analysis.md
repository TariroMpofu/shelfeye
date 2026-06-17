# Gap Analysis — StockRoom vs iVend Handheld vs ShelfEye V1

Scope of comparison: **product lookup** only (ShelfEye's domain).

| Capability | iVend Handheld | StockRoom | ShelfEye V1 |
|---|---|---|---|
| Barcode scan | ✅ camera + socket scanner | ✅ camera | ✅ camera (`ScannerSheet`) |
| Manual barcode / product-code entry | ✅ | ✅ | ✅ |
| Barcode→id fallback | ✅ GetBarCodeResolution→GetProduct | ✅ GetProductByBarCode→GetProduct | ✅ same |
| Product name / code / barcode | ✅ | ✅ | ✅ |
| UOM (base) | ✅ | ✅ | ✅ |
| **Multi-UOM with per-UOM price** | ✅ (inventory price + special) | ➖ (not a lookup app) | ✅ GetItemSalesPrice per UOM |
| **UOM conversion display** | ➖ not shown | ➖ collected ids only | ✅ "1 Pack = 6 EA" from BaseQty/AltQty |
| Customer/special price | ✅ GetItemSalesPrice + customer picker | ➖ | ⚙️ uses store cash customer (picker = roadmap) |
| Stock on hand | ✅ ProductInventoryList | ➖ | 🔜 roadmap (model leaves room) |
| Browse all products | ✅ (raw SQL via GetQueryResult) | ➖ | ❌ refused (schema coupling) → roadmap "search by description" |
| Print labels | ✅ PrintItemLabels | ➖ | ❌ out of scope (no printer) |
| Login required | ✅ device-bound | ✅ operator | ❌ none (lookup-only) |
| Error messaging | ➖ generic; **silent on non-200** | ✅✅ mapped (IIS/SQL/503) | ✅✅ ported `friendlyHttpMessage` |
| Region-safe numbers | ⚙️ locale-aware input | ✅ invariant JSON | ✅ invariant JSON + comma normalize |
| Latest-wins rapid lookups | ➖ | ✅ generation counters | ✅ generation counters |
| Repository/clean layering | ➖ activity+retrofit | ➖ ApiService = client+repo | ✅✅ dedicated repository layer |

Legend: ✅ has it · ✅✅ does it best · ⚙️ partial/assumption · 🔜 designed-for · ❌ deliberately excluded · ➖ n/a.

## Where ShelfEye leads
- **Cleanest architecture** of the three: HTTP isolated in `api/`, a pure-Dart `ProductRepository`, `Result<T>` instead of cross-layer throws.
- **Best error handling** (inherits StockRoom's mapper; the Handheld is silent on non-200).
- **UOM conversion** actually surfaced to the user ("1 Pack = 6 EA"), which neither other app shows.

## Where ShelfEye is intentionally lighter
- No login, no stock, no counting, no print, no product browse. All are roadmap or out-of-scope by design — ShelfEye is a price checker.

## Documented assumptions
1. **Price source = `GetItemSalesPrice` per UOM** against the store's cash customer (V1 has no warehouse, so per-warehouse `ProductInventoryList.Price` is deferred to the stock-on-hand roadmap item). `ItemPrice == 0` ⇒ "no price" (Handheld rule).
2. **Store is optional.** No store ⇒ product + UOMs shown without price (graceful degradation).
3. **No raw SQL.** The Handheld's customer/product lists use `GetQueryResult` with T-SQL; ShelfEye refuses this to stay schema-decoupled, trading away "browse all products" for safety.
4. **HTTP only**, per the documented base-URL shape, matching StockRoom and the Handheld.

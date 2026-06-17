# iVend Handheld — Behavioural Reference (Item Lookup)

Source: decompiled APK at `/Users/MacBook/Documents/ivend handheld`
(curated Java in `docs/reference/ivend-handheld-src/`). This is the reference
implementation for how a retail lookup *should* behave.

---

## 1. Item Lookup flow (`ItemLookupActivity.java`)

```
Enter screen
 ├─ getItemLookUpData()   → product list for the 🔍 picker (raw SQL via GetQueryResult)
 └─ customer defaults to the store's saved CustomerId (cash customer)

Resolve product (scan camera | type + blur | 🔍 pick) → all converge:
   validateBarcode(code) → GetBarCodeResolution → ProductDetailsBean(id)
        → getProductDetails(id) → GetProduct → ProductDetails
             • Description shown
             • loop ProductInventoryList, match WarehouseId == selectedWarehouse →
                 invEdT  = InStockQuantity
                 priceEdT = Price
        → getSpecialPriceList() → GetItemSalesPrice(product, customer, store, uom, 0)
             • onItemPriceReceived: if ItemPrice != 0 → priceEdT = ItemPrice (overrides)

Change customer (🔍) → GetQueryResult(SQL over CusCustomer) → re-run price
Print label → dialog → PrintItemLabels (POST array)
```

## 2. Endpoints the Handheld uses (`ApiInterface.java`)

| Purpose | Endpoint | Documented? |
|---|---|---|
| Login (device-bound) | `ValidateUserWithDeviceId/` | ✅ |
| Barcode → product | `GetBarCodeResolution/` | ✅ |
| Product + inventory | `GetProduct/` | ✅ |
| Sales price | `GetItemSalesPrice/` | ✅ |
| Health check | `CheckAPIConnection/` | ✅ |
| **Customer/product lists** | `ExecuteQueries/` + `GetQueryResult/?queryText=<SQL>` | ✅ endpoint, but **raw SQL payload** |
| Print labels | `PrintItemLabels/` | ✅ |

## 3. ⚠️ The key behavioural caveat: raw SQL

The Handheld builds its **customer list** and **product-browse list** by sending
**T-SQL strings** to `GetQueryResult` (e.g. `SELECT … FROM CusCustomer WITH (NOLOCK) …`,
`SELECT TOP 1000 … FROM InvProduct …`). This tightly couples the app to iVend's DB
schema. **ShelfEye does NOT replicate this** — it uses only typed REST endpoints, so it
forgoes the "browse all products" list in favour of scan + barcode/code entry (the
documented, schema-safe path). Documented as a roadmap item (search by description).

## 4. Success / error behaviour (worth bettering)

- Submit/print success keyed on `Message == "Success"` (strict; `StringUtils.isSuccess`).
- Response handler only acts on `code()==200`; **any non-200 (413/500/503) falls through to nothing — silent failure**. ShelfEye instead maps every status via `friendlyHttpMessage`.
- `onFailure` (timeout/network) shows a generic server-error alert.

## 5. Pricing rules to mirror exactly

- Base/inventory price = `ProductInventoryList[].Price` for the current warehouse.
- **Special price overrides only when `ItemPrice != 0`** — otherwise inventory price stands.
- ShelfEye V1 (no warehouse): uses `GetItemSalesPrice` per UOM against the store's cash customer as the displayed price; documents that inventory `Price` requires a warehouse (roadmap: stock on hand).

## 6. UX targets

- One field, instant resolve on scan/blur, clear button, read-only result fields.
- ShelfEye matches the "retail price checker" speed goal: scan → result with no extra taps.

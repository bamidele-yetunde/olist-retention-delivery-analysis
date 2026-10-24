# Power BI dashboard — `Olist Delivery Dashboard.pbix`

A 5-page report on 96,203 delivered orders. Open the `.pbix` in Power BI Desktop — the data is inside, nothing to configure.

| | |
|---|---|
| `Olist Delivery Dashboard.pbix` | the dashboard (5 pages, 63 visuals, data included, 25 MB) |
| `dax_measures.dax` | the 52 measures as readable text, grouped by topic |
| `theme.json` | the report theme (colours, fonts) |
| `../docs/dashboard_pages/` | PNG of each page + the 5-page PDF, exported from Power BI Desktop |

## How it is built

**Power Query (Get data → Text/CSV).** Eight tables are loaded from `data/processed/*.csv` (written by the Python notebook) through one `DataFolder` parameter, so the whole model re-points to another folder in one edit (Transform data → Edit parameters). Each query is: `Csv.Document` → `Table.PromoteHeaders` → `Table.TransformColumnTypes` (dates, integers, decimals typed explicitly). One column is added in Power Query rather than in the data: `fact_orders[route_group]` = `Table.AddColumn(... if List.Contains({the 12 worst routes}, [route]) then "Top 12 routes" else "All other routes")` — it powers the "top 12 routes vs everywhere else" line on page 3.

**Model (star schema).**

```
dim_date ─┐
dim_state ─┤
dim_customer ─┼── fact_orders ──< fact_order_items >── dim_product
dim_seller ─┘        (96,203)         (109,872)
cohort_retention (disconnected, feeds the retention matrix)
_Measures (52 measures, no columns)
```

One row per order in `fact_orders` (the grain of every KPI), one row per item in `fact_order_items` (revenue by category), and one dimension table per thing you slice by. Relationships are single-direction, one-to-many, from the dimensions into the facts; `dim_date` is marked as the date table; `fact_order_items → dim_seller` is an inactive relationship (the active seller link runs through the order's main seller). Sort-by columns make the delay and speed buckets sort logically instead of alphabetically.

**DAX (52 measures, `dax_measures.dax`).** Volume and revenue (`Orders`, `Revenue`, `Avg Order Value`), delivery (`Late Rate = DIVIDE([Late Orders], [Orders])`, `Avg Carrier Transit Days`, `Shipped After Deadline %`), reviews (`One-star Rate`, `Avg Score On-time` / `Avg Score Late` with `CALCULATE` filters, `Share of 1-stars from Late Orders`), retention (`Repeat Customer Rate`, `Retention %`), time intelligence (`Revenue PM` and `Late Rate PM` with `DATEADD`, month-over-month deltas), and share-of-total measures that use `REMOVEFILTERS` so a slicer changes the numerator but not the denominator (`Share of Orders`, `Share of Late Orders`, `Share of Items Revenue`).

**Report.** Top-N filters (worst 12 states, top 12 routes, top 12 categories, 12 biggest customer states in the matrix), measure filters (sellers with 100+ orders), conditional-formatting heat maps on the two matrices, slicers (Month, Region, State) synced across all five pages, display names on fields, a custom theme.

## The pages

| Page | Question it answers | Key visuals |
|---|---|---|
| **Overview** | How is the business doing and what is the one problem to care about? | 6 KPI cards · revenue and late-rate by month · avg review score and 1-star rate by delivery-vs-promise · "37% of 1-stars come from late orders" card |
| **Delivery & Satisfaction** | Do customers punish slow delivery or broken promises, and where is the time lost? | met-vs-missed cards · score by actual delivery time split by promise met/missed · seller handling vs carrier transit · 12 worst states · share of orders vs share of late orders by region |
| **Routes** | Which lanes should be fixed first? | top 12 routes by late orders · seller-state × customer-state late-rate heat map · late orders / avg days late / "seller shipped on time" cards · late rate by month, top 12 routes vs all other routes |
| **Sellers & Categories** | Who, specifically, do we call on Monday? | seller watchlist (100+ orders, worst late rate first) · revenue by category (top 12 of 74) · active sellers / sellers with 100+ orders |
| **Retention** | Does fixing delivery bring customers back? | customers / repeat rate cards · orders per customer · repeat rate by first-order score and by first-order delivery · 2017 cohort retention heat map · "what this means" box |

Definitions are identical to the SQL view `v_order_facts` and the Python notebook: *late* = delivered after the estimated date; *delay days* = delivered − promised in calendar days; *revenue* = sum of item prices; *review score* = latest review per order.

## Expected values (no filters) — use these to check a reload

Orders 96,203 · Late Rate 6.8% · Late Orders 6,531 · Avg Score Late 2.26 / On-time 4.28 · One-star Rate Late 54.2% / On-time 6.8% · Share of 1-stars from Late Orders 36.6% · Seller shipped on time among late orders 72.3% · Repeat Customer Rate 3.00% · Sellers 3,095 (210 with 100+ orders).

## Re-pointing the data

To reload from your own `data/processed/` folder: **Transform data → Edit parameters → DataFolder** (keep the trailing backslash), then **Refresh** (≈2 minutes for 250k rows).

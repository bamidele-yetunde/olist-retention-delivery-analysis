# LinkedIn write-up — the Power BI dashboard

Use **Version A** as the main post (≈2,700 characters, under LinkedIn's 3,000 limit). Attach the five page images in `docs/dashboard_pages/` (PNG, exported from Power BI itself) — LinkedIn shows the first image large, so lead with the Overview page. Put links in the **first comment**, not in the post (LinkedIn down-ranks posts with external links). Post Tuesday–Thursday, 8–10 am in the time zone of the recruiters you want (Europe/US), and reply to every comment in the first hour.

Everything in the post is something you can demonstrate live in the .pbix, the notebook, the SQL files or the workbook.

---

## Version A — main post

I built a 5-page Power BI dashboard on 96,203 real e-commerce orders. Here's what it found, and how it's built. 🧵

The question: Olist (Brazil's biggest marketplace) has a 97% one-and-done customer rate. Is it the product, the price, or the delivery — and what's the cheapest fix?

📊 Page 1 — Overview
Six KPIs, revenue and late-rate trends, and the chart that frames the whole story: average review score by delivery vs the promised date. On time → 4.2 stars. 1–3 days late → 3.3. 4–7 days late → 2.1. Only 6.8% of orders arrive late, but they produce 37% of ALL 1-star reviews.

📦 Page 2 — Delivery & Satisfaction
The finding I didn't expect. Same actual delivery time, split by whether the promised date was met: a 22–30 day delivery that met its promise scores 3.95; one that missed it scores 2.57. Customers grade the promise, not the clock.
Then "where the time goes": late orders spend 28 days with the carrier vs 8 for on-time ones. Seller handling barely moves (2.6 → 5.5 days). In 72% of late orders the seller shipped on time.

🗺️ Page 3 — Routes
12 seller→customer routes produce 69% of late orders; São Paulo → Rio alone is 18%. A seller-state × customer-state heat map and a "top 12 routes vs everywhere else" trend line show the Black Friday and Feb–Mar 2018 spikes hit exactly those lanes.

🏪 Page 4 — Sellers & Categories
The Monday-morning list: every seller with 100+ orders ranked by late rate (one seller in Maranhão is late on 19% of 389 orders), plus the 12 categories that carry the revenue.

🔁 Page 5 — Retention
Cohort retention heat map, orders per customer, repeat rate by first-order outcome. 97% never reorder. A late first order lowers the repeat rate from 3.03% to 2.52% — real, but small — and the first order's star rating doesn't predict a return at all. Delivery is a reputation problem, not a retention lever.

🛠️ How it's built
• MySQL: the raw Kaggle files loaded into a schema, one view that defines "late", "delay days" and "review score" once, and 11 analysis queries (CTEs and window functions)
• Python (pandas, NumPy): cleaning, one-row-per-order feature engineering, the cohort table, and the CSV exports the dashboard reads
• Power Query: 8 tables loaded through one folder parameter, typed columns, and a custom column that flags the 12 worst routes
• Data model: a star schema — fact_orders (96k rows) and fact_order_items, with date, customer, seller, product and state dimensions
• DAX: 52 measures — late rate, 1-star rate, repeat rate, share-of-total measures that ignore slicers for the denominator, month-over-month change
• Report: Top-N and measure filters, conditional-formatting heat maps, slicers synced across pages
• Excel: a what-if model where a manager changes the target late rate or the promise buffer and sees reviews avoided

💡 The recommendation
Make the delivery promise route-aware. A 7-day buffer on the 12 worst routes would have rescued 40% of late orders at zero logistics cost — about 730 fewer 1-star reviews a year. A/B test it. Second: a carrier SLA on Rio and the Northeast (22% of orders, 40% of late ones).

I'm a junior data analyst (Excel · Power BI · SQL · Python) open to remote Junior Data Analyst roles — the kind where the dashboard is the start of the conversation, not the end of it. Repo, memo and the .pbix are in the comments; happy to walk anyone through it.

#PowerBI #DataAnalytics #DAX #PowerQuery #SQL #MySQL #Python #Excel #JuniorDataAnalyst #DataAnalyst #OpenToWork

---

## Version B — short (if you want a punchier post, ~1,200 characters)

6.8% of orders. 37% of the 1-star reviews.

That's what a 5-page Power BI dashboard on 96,203 real e-commerce orders boiled down to.

What each page answers:
1️⃣ Overview — how's the business, and what's the one problem to care about?
2️⃣ Delivery & Satisfaction — slow or late: which one do customers punish? (Late. Same delivery time, up to 1.8 stars of difference depending on whether the promise was met.)
3️⃣ Routes — where does it happen? (12 routes = 69% of late orders; it's the carrier leg, not the seller.)
4️⃣ Sellers & Categories — who do we call on Monday? (every seller with 100+ orders, ranked by late rate)
5️⃣ Retention — does fixing delivery bring customers back? (No. 97% never reorder either way.)

Under the hood: MySQL → pandas → Power Query → a star schema with 52 DAX measures → Top-N filters, heat maps, synced slicers → an Excel what-if model for the recommendation.

The cheapest fix isn't a faster carrier — it's a smarter promise. A 7-day buffer on the 12 worst routes rescues 40% of late orders for free.

Full repo + memo in the comments. Open to remote Junior Data Analyst roles.

#PowerBI #DAX #SQL #Python #Excel #OpenToWork

---

## First comment (post this right after publishing)

🔗 Repo (SQL, notebook, Excel model, .pbix): [your GitHub link]
📄 One-page memo: [link to docs/insights_memo.pdf in the repo]
📊 Dashboard file: [link to powerbi/Olist Delivery Dashboard.pbix]
Data: Brazilian E-Commerce Public Dataset by Olist (Kaggle), 2016–2018.

---

## Image order for the post (all in `docs/dashboard_pages/`)

1. `page1_overview.png` — leads the post (KPI row + the "customers forgive slow, not late" chart)
2. `page2_delivery.png` — the promise-vs-speed chart is the hook for the comments
3. `page3_routes.png` — the route ranking, the heat map and the two-line trend
4. `page4_sellers_categories.png` — the watchlist shows operational depth
5. `page5_retention.png` — the cohort heat map

`Olist Delivery Dashboard.pdf` in the same folder is the 5-page export if you want to attach a document instead of images.

---

## If a recruiter asks "walk me through it" — the 60-second version

"The dashboard answers one question across five pages: why does this marketplace get 1-star reviews, and what's the cheapest fix. Page one shows the cliff — on-time orders average 4.2 stars, four days late is 2.1. Page two shows it's the broken promise, not the slow delivery, that customers punish, and that the time is lost with the carrier, not the seller. Page three names the twelve routes responsible and shows the seasonal spikes hit exactly those lanes. Page four is the call list — sellers with 100+ orders ranked by late rate. Page five shows retention is structural — 97% buy once — so I'd sell the fix on review scores, not repeat revenue. Under the hood it's a star schema with 52 DAX measures, loaded through Power Query from CSVs that my Python notebook writes, and every number reconciles to the MySQL view that defines the metrics."

---

## Questions recruiters ask about dashboards — and answers you can give

**"Why a star schema and not one big table?"** Because every page slices the same facts by month, region and state at once. With a date table, a state table and a customer table filtering `fact_orders`, one slicer filters every visual, share-of-total measures can use `REMOVEFILTERS` on a dimension for the denominator, and the model stays small — one wide table would repeat every dimension attribute 96,203 times.

**"Where do the numbers come from?"** The notebook (pandas) writes `data/processed/*.csv`; Power Query loads them through one `DataFolder` parameter and types every column. "Late" = delivered after the estimated date — the same definition lives in the MySQL view `v_order_facts`, so Orders 96,203 and Late Rate 6.8% match across SQL, Python and DAX.

**"Give me an example of a DAX measure."** `Share of Late Orders = DIVIDE([Late Orders], CALCULATE([Late Orders], REMOVEFILTERS(dim_state), REMOVEFILTERS(fact_orders)))` — the numerator respects the region slicer, the denominator ignores it, so the region bars on page 2 always add up to 100%.

**"What did you do in Power Query?"** Loaded 8 CSVs with `Csv.Document`, promoted headers, set data types explicitly (dates, integers, decimals), and added one custom column with `Table.AddColumn` + `List.Contains` that flags the 12 worst routes, so page 3 can compare them with everywhere else by month.

**"What would you do next?"** A/B test the route-aware promise; add carrier identity (the dataset doesn't have it) to split the carrier leg by partner; and move the model to a scheduled refresh in the Power BI service.

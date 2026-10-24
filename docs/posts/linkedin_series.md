# LinkedIn series — 5 posts over ~2 weeks

Rules I followed: first line is a number + a surprise (it's all people see before "…more"). One idea per post. One image per post. Ask a question at the end so people comment. Plain text, short paragraphs, no hashtags wall (3–5 max, at the bottom). Post Tue–Thu, 8–10am in your target market's time zone.

Replace `[repo link]` with your GitHub URL and `[dashboard link]` with the Power BI link once published.

---

## Post 1 — Day 1 · "Starting"  (image: `images/03_late_rate_by_month.png` or a screenshot of the 9 CSV files)

100,000 orders. 9 tables. One question.

I'm spending the next 10 days on a Brazilian e-commerce dataset (Olist, public on Kaggle) to answer something every marketplace cares about:

Is it the product, the price, or the delivery that makes customers leave a 1-star review — and what's the cheapest fix?

The plan:
→ MySQL: load the 9 CSVs into a proper schema with keys, write the analysis queries
→ Python: clean it, build the features, test the hypothesis properly
→ Power BI: a 3-page dashboard a manager could actually use
→ Excel: a one-sheet what-if model for the people who live in spreadsheets

My hypothesis going in: late deliveries are why 97% of these customers never come back.

I'll post what I find, including if the hypothesis is wrong.

What would you check first?

#DataAnalytics #SQL #PowerBI #Python #DataAnalyst

---

## Post 2 — Day 3 · "The messiest cleaning problem"  (image: screenshot of `sql/02_load_data.sql` around the reviews LOAD DATA block, or of the quality-check output)

The reviews file broke my MySQL load 3 times. Here's why.

Loading 9 CSVs with LOAD DATA INFILE should take a minute. Eight files did. The ninth — 100,000 customer reviews — kept failing.

Three separate problems inside one file:

1. Review texts contain line breaks. A plain line-by-line load splits one review into three rows. Fix: ENCLOSED BY '"' so MySQL respects quoted fields.

2. Backslashes inside the comments were being read as escape characters and eating the next character. Fix: ESCAPED BY ''.

3. The category translation file had Windows line endings (CRLF) while every other file used LF — so every English category name came in with an invisible \r at the end and none of my joins matched. Fix: TRIM(TRAILING '\r' …) on load.

Bonus: review_id isn't unique. 802 review IDs are attached to more than one order (827 extra rows). So the primary key is (review_id, order_id), not review_id.

None of this shows up in the final dashboard. All of it decides whether the numbers in the dashboard are right.

What's the worst data-loading bug you've hit?

#SQL #MySQL #DataCleaning #DataAnalytics

---

## Post 3 — Day 6 · "One finding, one chart"  (image: `images/01_review_score_vs_delay.png`)

Customers forgive slow. They don't forgive late.

6.8% of Olist orders arrive after the promised date.
Those orders produce 37% of all 1-star reviews.

The cliff is brutal:
• On time → 4.2 stars, 7% one-star
• 1–3 days late → 3.3 stars, 25% one-star
• 4–7 days late → 2.1 stars, 59% one-star
• 8+ days late → 1.7 stars, 70% one-star

But here's the part I didn't expect. I compared orders that took the SAME number of days:

• Took 22–30 days, met the promise → 3.95 stars
• Took 22–30 days, missed the promise → 2.57 stars

Same speed. 1.4 stars of difference. Customers are grading the promise, not the clock.

Which means the delivery estimate itself is a lever — and changing a number on a checkout page is a lot cheaper than changing a carrier.

Would you rather be told 10 days and get it in 12, or be told 15 and get it in 12?

#DataAnalytics #Ecommerce #CustomerExperience #SQL

---

## Post 4 — Day 9 · "The dashboard"  (video: 45–60 s screen recording of the Power BI pages, or 3 screenshots as a carousel)

Three pages. One story. Here's the Power BI dashboard.

Page 1 — Executive overview: orders, revenue, late rate, average score. The late-rate line has two spikes: Black Friday month (12%) and Feb–Mar 2018 (14–19%).

Page 2 — Delivery & satisfaction: the "customers grade the promise" chart, a map of late rates by state (the Northeast and Rio are 2–5× São Paulo), and where the time goes: late orders spend 28 days in carrier transit vs 8 for on-time ones. Seller handling barely changes. In 72% of late orders the seller shipped on time.

Page 3 — Routes: 12 routes produce 69% of late orders. SP → RJ alone is 18%. Page 4 — Sellers & categories: every seller with 100+ orders, ranked by late rate.

Behind it: a star schema (fact_orders + 5 dimensions), ~40 DAX measures, every definition identical to the SQL view it came from — so the numbers match the queries to the decimal.

[dashboard link]

What's the one visual you'd want on page 1?

#PowerBI #DAX #DataVisualization #DataAnalytics

---

## Post 5 — Day 12 · "Wrap-up"  (carousel: 7 slides — see below — or `images/01` + repo link)

My hypothesis was wrong. Here's what 96,203 orders actually said.

I started this project believing late deliveries were why 97% of Olist customers never come back.

Half of that survived.

✅ Late deliveries ARE the main driver of 1-star reviews (37% of them, from 6.8% of orders).
❌ They are NOT why customers don't return. A late first order lowers the repeat rate from 3.0% to 2.5%. The first order's star rating doesn't predict a return at all. Retention on this marketplace is structural — people buy once.

Three more things the data said:

1. Customers grade the promise, not the speed. Same 22–30 day delivery: 3.95 stars if on time, 2.57 if late.

2. Lateness is concentrated. 12 routes = 69% of late orders. Rio + the Northeast = 22% of orders but 40% of late ones. And in 72% of late orders the seller shipped on time — it's the carrier leg.

3. Multi-item orders get 1 star 2.5× as often, even though they're less often late. Probably split deliveries. Not in my hypothesis at all.

The recommendation, cheapest first:
→ Make the delivery promise route-aware. A 7-day buffer on the 12 worst routes would have rescued 40% of late orders at zero logistics cost — about 730 fewer 1-star reviews a year (56% and ~1,040 if applied everywhere). A/B test it.
→ Carrier SLA on Rio and the Northeast.
→ Stop measuring delivery as a retention lever.

Stack: MySQL (schema + 11 queries) → Python (pandas/numpy cleaning and feature engineering) → Power BI (Power Query, star schema, DAX) → Excel (what-if model a manager can play with).

Everything is in the repo, including the queries, the notebook, the Excel model and a one-page memo: [repo link]

If you're hiring a junior data analyst who starts from the business question and ends with a number someone can act on — my DMs are open.

#DataAnalyst #OpenToWork #SQL #Python #PowerBI #Excel

### Carousel slides for Post 5 (make in Canva/PowerPoint, 1080×1350)
1. Title: "My hypothesis was wrong. 96,203 orders. Here's what they said." (small: Olist e-commerce · SQL · Python · Power BI · Excel)
2. "6.8% of orders are late. They produce 37% of all 1-star reviews." + chart 01 (left panel)
3. "Customers grade the promise, not the speed." + chart 02
4. "12 routes = 69% of late orders. It's the carrier leg, not the seller." + chart 06 or 05
5. "97% never come back — and delivery barely moves that." + the 3.03% vs 2.52% comparison
6. "The cheapest fix: a route-aware delivery promise. ~730 fewer 1-star reviews a year on 12 routes, zero logistics cost."
7. "Full repo + memo + dashboard → link in comments." + your name / title

---

## Recruiter DM template (attach `docs/insights_memo.pdf`)

Hi [Name] — I saw you're hiring for [role] at [company]. I'm a junior data analyst (SQL, Python, Power BI, Excel) and I just finished an end-to-end project on 96k e-commerce orders: I found that the 6.8% of deliveries that arrived late were producing 37% of all 1-star reviews, and sized a zero-cost fix. The one-page memo is attached; the full repo with the SQL, notebook and dashboard is here: [repo link]. If it's useful, I'd love 15 minutes to talk about how I'd approach [company]'s data. Thanks either way.

# TikTok scripts — 5 videos, 30–60 s each

Format rules: hook in the first 2 seconds (say the number before anything else), captions on (most people watch muted), screen recording + your face in a corner or voiceover, one idea per video, end with a question or "part 2 tomorrow". Vertical 9:16. Record the screen with OBS or the Windows Game Bar (Win+G), then edit in CapCut.

---

## Video 1 — "Raw CSV chaos → dashboard" (timelapse, 30 s)

**Hook (0–2 s, text on screen):** "100,000 orders. 9 files. 10 days."

**Visuals:** fast timelapse — folder with 9 CSVs → MySQL Workbench with the schema → notebook scrolling → charts appearing → Power BI dashboard pages. Speed-ramp it so it lands in 25 s.

**Voiceover:**
"This is 100,000 real e-commerce orders from Brazil. Nine tables. I loaded them into MySQL, cleaned them in Python, and built a dashboard to answer one question: why do 97% of these customers never come back? The answer surprised me. Part 2 tomorrow."

**Caption:** "Day 1 to day 10 of a data analyst portfolio project. SQL → Python → Power BI → Excel. #dataanalyst #sql #powerbi #python"

---

## Video 2 — "The one chart" (45 s)

**Hook (0–2 s):** "Customers forgive slow. They don't forgive late."

**Visuals:** chart `01_review_score_vs_delay.png` full screen; zoom into each bar as you say its number. Finger/cursor pointing.

**Voiceover:**
"Only 7% of these orders arrived late. But look what happens to the review score. On time: 4.2 stars. One to three days late: 3.3. Four to seven days late: 2.1 — and more than half of those customers give one star. Seven percent of orders. Thirty-seven percent of all the one-star reviews. That's the whole problem in one chart. Tomorrow I'll show you the part nobody expects: slow isn't the problem."

**Caption:** "6.8% of orders → 37% of 1-star reviews. #dataanalytics #ecommerce #datavisualization"

---

## Video 3 — "The SQL query that found it" (60 s)

**Hook (0–2 s):** "This SQL query found a 1.4-star gap."

**Visuals:** screen recording of `sql/13_promise_vs_speed.sql` in MySQL Workbench. Highlight the CASE buckets, then the two conditional AVG lines, then run it and highlight the 22–30 day row.

**Voiceover:**
"I wanted to know if customers hate slow delivery or broken promises. So I bucketed every order by how many days it actually took — under 7, 8 to 14, and so on — and inside each bucket I split them into 'met the promised date' and 'missed it'. That's this CASE statement and these two conditional averages. Run it. Look at the 22-to-30-day row: same speed, 3.95 stars if the promise was met, 2.57 if it wasn't. Customers aren't grading the clock. They're grading the promise. And a promise is just a number on a checkout page — which makes it the cheapest thing to fix."

**Caption:** "CASE + conditional aggregation = one of the most useful SQL patterns for analysts. Full query in my repo. #sql #mysql #dataanalyst #learnsql"

---

## Video 4 — "Dashboard walkthrough" (45 s)

**Hook (0–2 s):** "Three pages. One story. Here's the dashboard."

**Visuals:** screen recording of Power BI. Page 1 (click a month on the late-rate line, show the KPIs filter), page 2 (hover the map on Alagoas: 21% late; then the stage bar: 28 days in transit), page 3 (sort the route matrix, show SP→RJ).

**Voiceover:**
"Page one: the business at a glance. Click Black Friday month and the late rate jumps to 12%. Page two: where it happens. The Northeast and Rio are late two to five times more often than São Paulo — and look where the time goes: late orders spend 28 days with the carrier versus 8. The seller isn't the problem. Page three: twelve routes make 69% of late orders. São Paulo to Rio alone is 18%. Everything on these pages comes from one SQL view, so the numbers match the queries exactly."

**Caption:** "Star schema, ~40 DAX measures, built in Power BI. #powerbi #dax #dashboard #dataanalytics"

---

## Video 5 — "How I'd explain this to my manager in 30 seconds" (talking to camera, 30–40 s)

**Hook (0–2 s):** "Boss, I know why we're getting one-star reviews."

**Visuals:** you, talking to camera. Three text cards appear as you say them: "7% late → 37% of 1-stars" · "They grade the promise, not the speed" · "Fix the promise first: ~730 fewer 1-stars a year, zero cost".

**Script:**
"Seven percent of our orders arrive after the date we promised, and they're producing thirty-seven percent of our one-star reviews. The interesting part: customers don't punish slow delivery — they punish a broken promise. Same delivery time, on time versus late, is a 1.4-star gap. Our estimate is padded by twelve days on average but it's the same padding everywhere, so it fails on exactly the routes where transit is slow. Recommendation: make the estimate route-aware. A seven-day buffer on the twelve worst routes would have rescued forty percent of our late orders — over seven hundred fewer one-star reviews a year — and it costs nothing in logistics. Let's A/B test it. The second fix is a carrier SLA on Rio and the Northeast. And one thing not to do: don't sell this as a retention fix. Ninety-seven percent of customers buy once no matter what."

**Caption:** "Communication is the skill that gets analysts hired. Memo + repo in bio. #dataanalyst #careertok #datastorytelling"

---

## Bonus clips (15 s each, for consistency between the main videos)
- "The CSV that broke my MySQL load 3 times" (the CRLF / embedded-newline story from LinkedIn post 2)
- "Why review_id can't be a primary key" (802 IDs on more than one order — show the GROUP BY … HAVING COUNT(*) > 1 query)
- "The finding I didn't expect": multi-item orders get 1 star 2.5× as often even though they're less often late

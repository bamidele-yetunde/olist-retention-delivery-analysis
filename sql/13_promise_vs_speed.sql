-- =====================================================================
--  13_promise_vs_speed.sql  |  MySQL 8.0
--  Business question: do customers punish SLOW delivery, or BROKEN
--  PROMISES?  Compare orders that took the same number of days but
--  either met or missed the promised date.
--
--  Techniques: two-dimensional bucketing (speed x on-time), pivot with
--  conditional aggregation.
--  Depends on: fact_orders
--
--  Reading the result: a 22-30 day delivery that still met the promise
--  averages ~3.9 stars; the same speed that missed the promise averages
--  ~2.6. The promise date matters more than the absolute speed, which
--  makes the delivery estimate itself a lever.
-- =====================================================================
USE olist;

SELECT
  CASE
    WHEN delivery_days <= 7  THEN '1. <= 7 days'
    WHEN delivery_days <= 14 THEN '2. 8-14 days'
    WHEN delivery_days <= 21 THEN '3. 15-21 days'
    WHEN delivery_days <= 30 THEN '4. 22-30 days'
    WHEN delivery_days <= 60 THEN '5. 31-60 days'
    ELSE                          '6. 60+ days'
  END                                                            AS delivery_speed,
  COUNT(*)                                                       AS orders,
  SUM(is_late = 0)                                               AS on_time_orders,
  SUM(is_late = 1)                                               AS late_orders,
  ROUND(AVG(CASE WHEN is_late = 0 THEN review_score END), 2)     AS avg_score_on_time,
  ROUND(AVG(CASE WHEN is_late = 1 THEN review_score END), 2)     AS avg_score_late,
  ROUND(AVG(CASE WHEN is_late = 0 THEN review_score END)
      - AVG(CASE WHEN is_late = 1 THEN review_score END), 2)     AS score_gap,
  ROUND(100 * AVG(CASE WHEN is_late = 0 THEN review_score = 1 END), 1) AS pct_one_star_on_time,
  ROUND(100 * AVG(CASE WHEN is_late = 1 THEN review_score = 1 END), 1) AS pct_one_star_late
FROM fact_orders
WHERE review_score IS NOT NULL
GROUP BY delivery_speed
ORDER BY delivery_speed;

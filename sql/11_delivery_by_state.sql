-- =====================================================================
--  11_delivery_by_state.sql  |  MySQL 8.0
--  Business question: which customer states get late deliveries, how do
--  they rate the experience, and how far is each state from the
--  national average?
--
--  Techniques: GROUP BY with conditional aggregation, RANK() and
--  AVG() OVER () window functions for ranking and benchmarking.
--  Depends on: fact_orders
-- =====================================================================
USE olist;

WITH by_state AS (
  SELECT
    customer_state,
    COUNT(*)                                   AS orders,
    ROUND(SUM(revenue), 2)                     AS revenue_brl,
    ROUND(AVG(delivery_days), 1)               AS avg_delivery_days,
    ROUND(AVG(promised_days), 1)               AS avg_promised_days,
    ROUND(100 * AVG(is_late), 2)               AS pct_late,
    SUM(is_late)                               AS late_orders,
    ROUND(AVG(review_score), 2)                AS avg_review_score,
    ROUND(100 * AVG(review_score = 1), 2)      AS pct_one_star,
    ROUND(AVG(freight / NULLIF(revenue, 0)) * 100, 1) AS freight_pct_of_price
  FROM fact_orders
  GROUP BY customer_state
)
SELECT
  customer_state,
  orders,
  revenue_brl,
  avg_delivery_days,
  avg_promised_days,
  pct_late,
  late_orders,
  ROUND(100 * late_orders / SUM(late_orders) OVER (), 1)   AS share_of_all_late_orders,
  ROUND(pct_late - (100 * SUM(late_orders) OVER () / SUM(orders) OVER ()), 2)
                                                           AS pct_late_vs_national,
  avg_review_score,
  pct_one_star,
  freight_pct_of_price,
  RANK() OVER (ORDER BY pct_late DESC)                     AS late_rank
FROM by_state
ORDER BY pct_late DESC;

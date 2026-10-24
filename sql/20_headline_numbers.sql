-- =====================================================================
--  20_headline_numbers.sql  |  MySQL 8.0
--  The single-row summary quoted in the README, the memo and the Excel
--  what-if. Every number in those documents traces back to this query
--  (or to one of the queries 10-19).
--  Depends on: fact_orders
-- =====================================================================
USE olist;

SELECT
  COUNT(*)                                                         AS delivered_orders,
  COUNT(DISTINCT customer_unique_id)                               AS customers,
  ROUND(SUM(revenue), 2)                                           AS revenue_brl,
  ROUND(AVG(revenue), 2)                                           AS avg_order_value_brl,
  ROUND(100 * AVG(is_late), 2)                                     AS pct_late,
  SUM(is_late)                                                     AS late_orders,
  ROUND(SUM(CASE WHEN is_late = 1 THEN revenue END), 2)            AS revenue_in_late_orders_brl,
  ROUND(AVG(delivery_days), 1)                                     AS avg_delivery_days,
  ROUND(AVG(promised_days), 1)                                     AS avg_promised_days,
  ROUND(AVG(delay_days), 1)                                        AS avg_delay_days_neg_is_early,
  ROUND(AVG(CASE WHEN is_late = 1 THEN delay_days END), 1)         AS avg_days_late_when_late,
  ROUND(AVG(review_score), 2)                                      AS avg_review_score,
  ROUND(AVG(CASE WHEN is_late = 0 THEN review_score END), 2)       AS avg_score_on_time,
  ROUND(AVG(CASE WHEN is_late = 1 THEN review_score END), 2)       AS avg_score_late,
  ROUND(100 * AVG(CASE WHEN is_late = 0 THEN review_score = 1 END), 1) AS pct_one_star_on_time,
  ROUND(100 * AVG(CASE WHEN is_late = 1 THEN review_score = 1 END), 1) AS pct_one_star_late,
  ROUND(100 * SUM(CASE WHEN review_score = 1 AND is_late = 1 THEN 1 ELSE 0 END)
            / SUM(review_score = 1), 1)                            AS pct_of_all_one_stars_from_late_orders,
  ROUND(100 * AVG(CASE WHEN is_late = 1 THEN shipped_after_limit END), 1) AS pct_late_orders_seller_shipped_late
FROM fact_orders;

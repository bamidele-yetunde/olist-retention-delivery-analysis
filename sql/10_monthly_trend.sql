-- =====================================================================
--  10_monthly_trend.sql  |  MySQL 8.0
--  Business question: how are orders, revenue and delivery performance
--  trending month by month, and when did lateness spike?
--
--  Techniques: DATE_FORMAT, conditional aggregation, LAG() window
--  function for month-over-month growth.
--  Depends on: fact_orders (04_create_views_and_fact_table.sql)
-- =====================================================================
USE olist;

WITH monthly AS (
  SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m')   AS order_month,
    COUNT(*)                                         AS orders,
    COUNT(DISTINCT customer_unique_id)               AS customers,
    ROUND(SUM(revenue), 2)                           AS revenue_brl,
    ROUND(SUM(freight), 2)                           AS freight_brl,
    ROUND(AVG(revenue), 2)                           AS avg_order_value,
    ROUND(100 * AVG(is_late), 2)                     AS pct_late,
    ROUND(AVG(delivery_days), 1)                     AS avg_delivery_days,
    ROUND(AVG(review_score), 2)                      AS avg_review_score,
    ROUND(100 * AVG(review_score = 1), 2)            AS pct_one_star
  FROM fact_orders
  GROUP BY order_month
)
SELECT
  order_month,
  orders,
  customers,
  revenue_brl,
  freight_brl,
  avg_order_value,
  ROUND(100 * (revenue_brl - LAG(revenue_brl) OVER (ORDER BY order_month))
            / LAG(revenue_brl) OVER (ORDER BY order_month), 1) AS revenue_mom_growth_pct,
  pct_late,
  avg_delivery_days,
  avg_review_score,
  pct_one_star
FROM monthly
ORDER BY order_month;

-- =====================================================================
--  14_delivery_stages.sql  |  MySQL 8.0
--  Business question: when an order is late, WHERE is the time lost -
--  with the seller (approval -> handed to carrier) or with the carrier
--  (handed to carrier -> delivered)?  Who should be held accountable?
--
--  Techniques: stage decomposition with TIMESTAMPDIFF (pre-computed in
--  the fact table), grouped comparison, percentage of late orders the
--  seller shipped after its deadline.
--  Depends on: fact_orders
--
--  Reading the result: late orders spend ~28 days in transit vs ~8 for
--  on-time orders, while seller handling only grows from ~2.6 to ~5.5
--  days. ~72 % of late orders were shipped by the seller on time -
--  the carrier leg is the main driver.
-- =====================================================================
USE olist;

-- A. Where the days go, late vs on time
SELECT
  CASE WHEN is_late = 1 THEN 'late' ELSE 'on time' END AS delivery_outcome,
  COUNT(*)                                            AS orders,
  ROUND(AVG(handling_days), 1)                        AS avg_seller_handling_days,
  ROUND(AVG(transit_days), 1)                         AS avg_carrier_transit_days,
  ROUND(AVG(delivery_days), 1)                        AS avg_total_delivery_days,
  ROUND(AVG(promised_days), 1)                        AS avg_promised_days,
  ROUND(100 * AVG(shipped_after_limit), 1)            AS pct_shipped_after_seller_deadline,
  ROUND(AVG(review_score), 2)                         AS avg_review_score
FROM fact_orders
WHERE handling_days IS NOT NULL AND transit_days IS NOT NULL
GROUP BY is_late
ORDER BY is_late;

-- B. Attribution of late orders: seller's fault vs carrier's fault
SELECT
  CASE WHEN shipped_after_limit = 1 THEN 'seller shipped late'
       ELSE 'seller shipped on time, carrier was slow' END AS late_order_cause,
  COUNT(*)                                            AS late_orders,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)    AS pct_of_late_orders,
  ROUND(AVG(delay_days), 1)                           AS avg_days_late,
  ROUND(AVG(review_score), 2)                         AS avg_review_score
FROM fact_orders
WHERE is_late = 1
GROUP BY shipped_after_limit
ORDER BY late_orders DESC;

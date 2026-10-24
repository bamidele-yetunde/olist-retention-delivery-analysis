-- =====================================================================
--  15_late_routes.sql  |  MySQL 8.0
--  Business question: which seller-state -> customer-state routes
--  generate most of the late orders?  If lateness is concentrated,
--  a targeted fix (carrier SLA or a longer promise on those routes)
--  is cheaper than a platform-wide one.
--
--  Techniques: CTE, cumulative share with SUM() OVER (ORDER BY ...),
--  ranking, filtering to routes with meaningful volume.
--  Depends on: fact_orders
--
--  Reading the result: SP -> SP and SP -> RJ alone produce ~40 % of all
--  late orders; SP -> RJ is late 14 % of the time on 8k orders.
-- =====================================================================
USE olist;

WITH routes AS (
  SELECT
    main_seller_state                         AS seller_state,
    customer_state,
    COUNT(*)                                  AS orders,
    SUM(is_late)                              AS late_orders,
    ROUND(100 * AVG(is_late), 2)              AS pct_late,
    ROUND(AVG(delivery_days), 1)              AS avg_delivery_days,
    ROUND(AVG(promised_days), 1)              AS avg_promised_days,
    ROUND(AVG(review_score), 2)               AS avg_review_score
  FROM fact_orders
  WHERE main_seller_state IS NOT NULL
  GROUP BY main_seller_state, customer_state
),
ranked AS (
  SELECT
    routes.*,
    RANK() OVER (ORDER BY late_orders DESC)                                    AS late_volume_rank,
    ROUND(100 * SUM(late_orders) OVER (ORDER BY late_orders DESC, seller_state, customer_state)
              / SUM(late_orders) OVER (), 1)                                   AS cumulative_pct_of_late_orders
  FROM routes
)
SELECT
  late_volume_rank,
  CONCAT(seller_state, ' -> ', customer_state) AS route,
  orders,
  late_orders,
  pct_late,
  cumulative_pct_of_late_orders,
  avg_delivery_days,
  avg_promised_days,
  ROUND(avg_promised_days - avg_delivery_days, 1) AS avg_buffer_days,
  avg_review_score
FROM ranked
WHERE orders >= 200
ORDER BY late_volume_rank
LIMIT 20;

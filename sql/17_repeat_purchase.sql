-- =====================================================================
--  17_repeat_purchase.sql  |  MySQL 8.0
--  Business question: how many customers ever come back, and does a
--  late (or badly reviewed) FIRST order change that?
--
--  Techniques: ROW_NUMBER() to isolate each customer's first order,
--  customer-level aggregation, grouped comparison.
--  Depends on: fact_orders
--
--  Reading the result: only ~3 % of customers place a second order,
--  whatever happened on the first one. A late first order lowers the
--  repeat rate from 3.0 % to 2.5 % (a 17 % relative drop) - real,
--  but the retention problem is structural, not a delivery problem.
-- =====================================================================
USE olist;

-- A. Distribution of orders per customer
WITH per_customer AS (
  SELECT customer_unique_id, COUNT(*) AS n_orders
  FROM fact_orders
  GROUP BY customer_unique_id
)
SELECT
  CASE WHEN n_orders >= 3 THEN '3+' ELSE CAST(n_orders AS CHAR) END AS orders_per_customer,
  COUNT(*)                                            AS customers,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)    AS pct_of_customers
FROM per_customer
GROUP BY orders_per_customer
ORDER BY orders_per_customer;

-- B. Repeat rate by what happened on the FIRST order
WITH ordered AS (
  SELECT
    customer_unique_id, is_late, review_score,
    ROW_NUMBER() OVER (PARTITION BY customer_unique_id ORDER BY order_purchase_timestamp, order_id) AS order_seq,
    COUNT(*)     OVER (PARTITION BY customer_unique_id)                                             AS n_orders
  FROM fact_orders
),
first_orders AS (
  SELECT customer_unique_id,
         is_late                       AS first_order_late,
         review_score                  AS first_order_score,
         CASE WHEN n_orders > 1 THEN 1 ELSE 0 END AS came_back
  FROM ordered
  WHERE order_seq = 1
)
SELECT 'first order late?' AS dimension,
       CASE WHEN first_order_late = 1 THEN 'late' ELSE 'on time' END AS segment,
       COUNT(*)                          AS customers,
       SUM(came_back)                    AS repeat_customers,
       ROUND(100 * AVG(came_back), 2)    AS repeat_rate_pct
FROM first_orders
GROUP BY first_order_late

UNION ALL

SELECT 'first order review score',
       CAST(first_order_score AS CHAR),
       COUNT(*),
       SUM(came_back),
       ROUND(100 * AVG(came_back), 2)
FROM first_orders
WHERE first_order_score IS NOT NULL
GROUP BY first_order_score
ORDER BY dimension, segment;

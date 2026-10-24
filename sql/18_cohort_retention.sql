-- =====================================================================
--  18_cohort_retention.sql  |  MySQL 8.0
--  Business question: for customers acquired in a given month, what
--  share place another order 1, 2, 3 ... months later?
--
--  Techniques: cohort assignment with MIN() OVER (PARTITION BY),
--  month arithmetic with TIMESTAMPDIFF(MONTH, ...), conditional
--  pivot for a classic retention triangle.
--  Depends on: fact_orders
--
--  Output: one row per acquisition cohort, columns m1..m6 = % of the
--  cohort that ordered again N months after their first order.
--  (Long format for Power BI is in the second query.)
-- =====================================================================
USE olist;

WITH orders_with_cohort AS (
  SELECT
    customer_unique_id,
    order_purchase_timestamp,
    DATE_FORMAT(MIN(order_purchase_timestamp) OVER (PARTITION BY customer_unique_id), '%Y-%m-01') AS cohort_month
  FROM fact_orders
),
activity AS (
  SELECT
    cohort_month,
    customer_unique_id,
    TIMESTAMPDIFF(MONTH, cohort_month, DATE_FORMAT(order_purchase_timestamp, '%Y-%m-01')) AS months_since_first
  FROM orders_with_cohort
),
cohort_size AS (
  SELECT cohort_month, COUNT(DISTINCT customer_unique_id) AS customers
  FROM activity
  GROUP BY cohort_month
)
-- A. Retention triangle (wide)
SELECT
  DATE_FORMAT(a.cohort_month, '%Y-%m')  AS cohort,
  cs.customers,
  ROUND(100 * COUNT(DISTINCT CASE WHEN months_since_first = 1 THEN a.customer_unique_id END) / cs.customers, 2) AS m1,
  ROUND(100 * COUNT(DISTINCT CASE WHEN months_since_first = 2 THEN a.customer_unique_id END) / cs.customers, 2) AS m2,
  ROUND(100 * COUNT(DISTINCT CASE WHEN months_since_first = 3 THEN a.customer_unique_id END) / cs.customers, 2) AS m3,
  ROUND(100 * COUNT(DISTINCT CASE WHEN months_since_first = 4 THEN a.customer_unique_id END) / cs.customers, 2) AS m4,
  ROUND(100 * COUNT(DISTINCT CASE WHEN months_since_first = 5 THEN a.customer_unique_id END) / cs.customers, 2) AS m5,
  ROUND(100 * COUNT(DISTINCT CASE WHEN months_since_first = 6 THEN a.customer_unique_id END) / cs.customers, 2) AS m6,
  ROUND(100 * COUNT(DISTINCT CASE WHEN months_since_first >= 1 THEN a.customer_unique_id END) / cs.customers, 2) AS ever_returned
FROM activity a
JOIN cohort_size cs USING (cohort_month)
GROUP BY a.cohort_month, cs.customers
ORDER BY a.cohort_month;

-- B. Same thing in long format (cohort, month_offset, retention_pct) - for Power BI
WITH orders_with_cohort AS (
  SELECT
    customer_unique_id,
    order_purchase_timestamp,
    DATE_FORMAT(MIN(order_purchase_timestamp) OVER (PARTITION BY customer_unique_id), '%Y-%m-01') AS cohort_month
  FROM fact_orders
),
activity AS (
  SELECT cohort_month, customer_unique_id,
         TIMESTAMPDIFF(MONTH, cohort_month, DATE_FORMAT(order_purchase_timestamp, '%Y-%m-01')) AS months_since_first
  FROM orders_with_cohort
),
cohort_size AS (
  SELECT cohort_month, COUNT(DISTINCT customer_unique_id) AS customers
  FROM activity GROUP BY cohort_month
)
SELECT DATE_FORMAT(a.cohort_month, '%Y-%m')          AS cohort,
       a.months_since_first                           AS month_offset,
       COUNT(DISTINCT a.customer_unique_id)           AS active_customers,
       cs.customers                                   AS cohort_customers,
       ROUND(100 * COUNT(DISTINCT a.customer_unique_id) / cs.customers, 2) AS retention_pct
FROM activity a
JOIN cohort_size cs USING (cohort_month)
WHERE a.months_since_first BETWEEN 1 AND 12
GROUP BY a.cohort_month, a.months_since_first, cs.customers
ORDER BY cohort, month_offset;

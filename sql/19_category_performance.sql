-- =====================================================================
--  19_category_performance.sql  |  MySQL 8.0
--  Business question: which product categories drive revenue, and do
--  any of them carry unusually high freight, lateness or bad reviews?
--
--  Techniques: multi-table joins (items -> products -> translation ->
--  fact), LEFT JOIN with COALESCE for missing translations,
--  share-of-total with SUM() OVER (), ranking.
--  Depends on: fact_orders, order_items, products, product_category_translation
-- =====================================================================
USE olist;

WITH category_items AS (
  SELECT
    COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
    i.order_id,
    i.price,
    i.freight_value,
    f.is_late,
    f.review_score
  FROM order_items i
  JOIN fact_orders f  ON f.order_id = i.order_id
  JOIN products p     ON p.product_id = i.product_id
  LEFT JOIN product_category_translation t ON t.product_category_name = p.product_category_name
),
by_category AS (
  SELECT
    category,
    COUNT(DISTINCT order_id)                        AS orders,
    COUNT(*)                                        AS items_sold,
    ROUND(SUM(price), 2)                            AS revenue_brl,
    ROUND(AVG(price), 2)                            AS avg_item_price,
    ROUND(100 * SUM(freight_value) / SUM(price), 1) AS freight_pct_of_price,
    ROUND(100 * AVG(is_late), 2)                    AS pct_late,
    ROUND(AVG(review_score), 2)                     AS avg_review_score,
    ROUND(100 * AVG(review_score = 1), 1)           AS pct_one_star
  FROM category_items
  GROUP BY category
)
SELECT
  RANK() OVER (ORDER BY revenue_brl DESC)                    AS revenue_rank,
  category,
  orders,
  items_sold,
  revenue_brl,
  ROUND(100 * revenue_brl / SUM(revenue_brl) OVER (), 2)     AS pct_of_revenue,
  avg_item_price,
  freight_pct_of_price,
  pct_late,
  avg_review_score,
  pct_one_star
FROM by_category
ORDER BY revenue_rank
LIMIT 20;

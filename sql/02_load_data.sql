-- =====================================================================
--  02_load_data.sql  |  MySQL 8.0
--  Bulk-load the 9 CSV files with LOAD DATA LOCAL INFILE.
--
--  HOW TO RUN (from the project root folder, so the relative paths work):
--
--    Windows (PowerShell / CMD):
--      mysql --local-infile=1 -u root -p < sql\02_load_data.sql
--    macOS / Linux:
--      mysql --local-infile=1 -u root -p < sql/02_load_data.sql
--
--  If MySQL says "Loading local data is disabled", run this once as root:
--      SET GLOBAL local_infile = 1;
--  (MySQL Workbench: Edit Connection > Advanced > add OPT_LOCAL_INFILE=1
--   in "Others", or just use the command line above.)
--
--  Alternative: python scripts/load_to_mysql.py  (does exactly this, from Python)
--
--  Format notes
--  * Fields are comma separated, optionally wrapped in double quotes.
--  * ESCAPED BY '' because review texts contain backslashes that must be
--    read literally, and quotes inside quoted fields are doubled ("").
--  * Review comments contain line breaks INSIDE quoted fields; MySQL
--    handles that correctly as long as ENCLOSED BY '"' is set.
--  * Empty strings in the CSV become NULL via NULLIF(@var, '').
--  Load order respects the foreign keys (parents before children).
-- =====================================================================

USE olist;

SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
SET SESSION unique_checks = 1;
SET SESSION foreign_key_checks = 1;

-- 1) Category translation (71 rows)
--    This file has Windows line endings (CRLF) while the others use LF,
--    so the trailing '\r' is trimmed off the last column.
LOAD DATA LOCAL INFILE 'data/raw/product_category_name_translation.csv'
INTO TABLE product_category_translation
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(product_category_name, @english)
SET product_category_name_english = TRIM(TRAILING '\r' FROM @english);

-- 2) Customers (99,441 rows)
LOAD DATA LOCAL INFILE 'data/raw/olist_customers_dataset.csv'
INTO TABLE customers
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state);

-- 3) Geolocation (1,000,163 rows - the biggest file, ~10 s)
LOAD DATA LOCAL INFILE 'data/raw/olist_geolocation_dataset.csv'
INTO TABLE geolocation
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state);

-- 4) Sellers (3,095 rows)
LOAD DATA LOCAL INFILE 'data/raw/olist_sellers_dataset.csv'
INTO TABLE sellers
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(seller_id, seller_zip_code_prefix, seller_city, seller_state);

-- 5) Products (32,951 rows) - fixes the two misspelled source columns
LOAD DATA LOCAL INFILE 'data/raw/olist_products_dataset.csv'
INTO TABLE products
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(product_id, @category, @name_len, @desc_len, @photos, @weight, @length, @height, @width)
SET product_category_name      = NULLIF(@category, ''),
    product_name_length        = NULLIF(@name_len, ''),
    product_description_length = NULLIF(@desc_len, ''),
    product_photos_qty         = NULLIF(@photos, ''),
    product_weight_g           = NULLIF(@weight, ''),
    product_length_cm          = NULLIF(@length, ''),
    product_height_cm          = NULLIF(@height, ''),
    product_width_cm           = NULLIF(@width, '');

-- 6) Orders (99,441 rows) - three nullable timestamps
LOAD DATA LOCAL INFILE 'data/raw/olist_orders_dataset.csv'
INTO TABLE orders
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(order_id, customer_id, order_status, order_purchase_timestamp,
 @approved, @carrier, @delivered, order_estimated_delivery_date)
SET order_approved_at             = NULLIF(@approved, ''),
    order_delivered_carrier_date  = NULLIF(@carrier, ''),
    order_delivered_customer_date = NULLIF(@delivered, '');

-- 7) Order items (112,650 rows)
LOAD DATA LOCAL INFILE 'data/raw/olist_order_items_dataset.csv'
INTO TABLE order_items
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value);

-- 8) Order payments (103,886 rows)
LOAD DATA LOCAL INFILE 'data/raw/olist_order_payments_dataset.csv'
INTO TABLE order_payments
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(order_id, payment_sequential, payment_type, payment_installments, payment_value);

-- 9) Order reviews (99,224 rows; free-text fields with embedded newlines)
LOAD DATA LOCAL INFILE 'data/raw/olist_order_reviews_dataset.csv'
INTO TABLE order_reviews
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(review_id, order_id, review_score, @title, @message, review_creation_date, review_answer_timestamp)
SET review_comment_title   = NULLIF(REPLACE(@title, '\r', ''), ''),
    review_comment_message = NULLIF(REPLACE(@message, '\r', ''), '');   -- normalise CRLF inside comments

-- Quick confirmation
SELECT 'customers'                    AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL SELECT 'geolocation',                 COUNT(*) FROM geolocation
UNION ALL SELECT 'sellers',                     COUNT(*) FROM sellers
UNION ALL SELECT 'product_category_translation',COUNT(*) FROM product_category_translation
UNION ALL SELECT 'products',                    COUNT(*) FROM products
UNION ALL SELECT 'orders',                      COUNT(*) FROM orders
UNION ALL SELECT 'order_items',                 COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments',              COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews',               COUNT(*) FROM order_reviews;

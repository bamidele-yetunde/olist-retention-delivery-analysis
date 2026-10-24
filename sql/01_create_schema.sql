-- =====================================================================
--  01_create_schema.sql  |  MySQL 8.0
--  Olist e-commerce: relational schema for the 9 Kaggle CSV files
--
--  Design notes
--  * One table per CSV, same grain as the source file.
--  * Primary keys + foreign keys enforce the relationships below.
--  * review_id is NOT unique in the source (802 review ids appear on
--    more than one order - 827 extra rows), so order_reviews uses a
--    composite key (review_id, order_id).
--  * Two product-category names have no English translation in the
--    source, so products -> category translation is a LEFT JOIN, not an FK.
--  * The source has typos in two column names (product_name_lenght,
--    product_description_lenght); they are renamed on load.
--
--  Entity relationships
--    customers 1 --- n orders 1 --- n order_items n --- 1 products
--                                  |                   n --- 1 sellers
--                                  |--- n order_payments
--                                  |--- n order_reviews
--    geolocation (zip prefix -> lat/lng), used for mapping only
-- =====================================================================

CREATE DATABASE IF NOT EXISTS olist
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE olist;

-- Rebuild from scratch (children first because of foreign keys)
DROP TABLE IF EXISTS order_reviews;
DROP TABLE IF EXISTS order_payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS product_category_translation;
DROP TABLE IF EXISTS sellers;
DROP TABLE IF EXISTS geolocation;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
  customer_id               CHAR(32)     NOT NULL COMMENT 'One id per order (not per person)',
  customer_unique_id        CHAR(32)     NOT NULL COMMENT 'The real person - use this for retention',
  customer_zip_code_prefix  CHAR(5)      NOT NULL,
  customer_city             VARCHAR(64)  NOT NULL,
  customer_state            CHAR(2)      NOT NULL,
  PRIMARY KEY (customer_id),
  KEY ix_customers_unique_id (customer_unique_id),
  KEY ix_customers_state     (customer_state),
  KEY ix_customers_zip       (customer_zip_code_prefix)
) ENGINE = InnoDB;

CREATE TABLE geolocation (
  geolocation_zip_code_prefix CHAR(5)     NOT NULL,
  geolocation_lat             DOUBLE      NOT NULL,
  geolocation_lng             DOUBLE      NOT NULL,
  geolocation_city            VARCHAR(64) NOT NULL,
  geolocation_state           CHAR(2)     NOT NULL,
  KEY ix_geolocation_zip (geolocation_zip_code_prefix)
) ENGINE = InnoDB COMMENT = '1M rows, many per zip prefix - aggregate before joining';

CREATE TABLE sellers (
  seller_id               CHAR(32)    NOT NULL,
  seller_zip_code_prefix  CHAR(5)     NOT NULL,
  seller_city             VARCHAR(64) NOT NULL,
  seller_state            CHAR(2)     NOT NULL,
  PRIMARY KEY (seller_id),
  KEY ix_sellers_state (seller_state)
) ENGINE = InnoDB;

CREATE TABLE product_category_translation (
  product_category_name          VARCHAR(64) NOT NULL,
  product_category_name_english  VARCHAR(64) NOT NULL,
  PRIMARY KEY (product_category_name)
) ENGINE = InnoDB;

CREATE TABLE products (
  product_id                  CHAR(32)          NOT NULL,
  product_category_name       VARCHAR(64)       NULL,
  product_name_length         SMALLINT UNSIGNED NULL,
  product_description_length  SMALLINT UNSIGNED NULL,
  product_photos_qty          TINYINT  UNSIGNED NULL,
  product_weight_g            INT      UNSIGNED NULL,
  product_length_cm           SMALLINT UNSIGNED NULL,
  product_height_cm           SMALLINT UNSIGNED NULL,
  product_width_cm            SMALLINT UNSIGNED NULL,
  PRIMARY KEY (product_id),
  KEY ix_products_category (product_category_name)
) ENGINE = InnoDB;

CREATE TABLE orders (
  order_id                       CHAR(32)    NOT NULL,
  customer_id                    CHAR(32)    NOT NULL,
  order_status                   VARCHAR(16) NOT NULL,
  order_purchase_timestamp       DATETIME    NOT NULL,
  order_approved_at              DATETIME    NULL,
  order_delivered_carrier_date   DATETIME    NULL COMMENT 'Seller handed the parcel to the carrier',
  order_delivered_customer_date  DATETIME    NULL COMMENT 'Customer received it',
  order_estimated_delivery_date  DATETIME    NOT NULL COMMENT 'The promise shown at checkout',
  PRIMARY KEY (order_id),
  KEY ix_orders_customer  (customer_id),
  KEY ix_orders_purchase  (order_purchase_timestamp),
  KEY ix_orders_status    (order_status),
  CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers (customer_id)
) ENGINE = InnoDB;

CREATE TABLE order_items (
  order_id             CHAR(32)         NOT NULL,
  order_item_id        TINYINT UNSIGNED NOT NULL COMMENT 'Line number inside the order',
  product_id           CHAR(32)         NOT NULL,
  seller_id            CHAR(32)         NOT NULL,
  shipping_limit_date  DATETIME         NOT NULL COMMENT 'Deadline for the seller to ship',
  price                DECIMAL(10,2)    NOT NULL,
  freight_value        DECIMAL(10,2)    NOT NULL,
  PRIMARY KEY (order_id, order_item_id),
  KEY ix_items_product (product_id),
  KEY ix_items_seller  (seller_id),
  CONSTRAINT fk_items_order   FOREIGN KEY (order_id)   REFERENCES orders   (order_id),
  CONSTRAINT fk_items_product FOREIGN KEY (product_id) REFERENCES products (product_id),
  CONSTRAINT fk_items_seller  FOREIGN KEY (seller_id)  REFERENCES sellers  (seller_id)
) ENGINE = InnoDB;

CREATE TABLE order_payments (
  order_id              CHAR(32)         NOT NULL,
  payment_sequential    TINYINT UNSIGNED NOT NULL,
  payment_type          VARCHAR(16)      NOT NULL,
  payment_installments  TINYINT UNSIGNED NOT NULL,
  payment_value         DECIMAL(10,2)    NOT NULL,
  PRIMARY KEY (order_id, payment_sequential),
  CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES orders (order_id)
) ENGINE = InnoDB;

CREATE TABLE order_reviews (
  review_id               CHAR(32)         NOT NULL,
  order_id                CHAR(32)         NOT NULL,
  review_score            TINYINT UNSIGNED NOT NULL,
  review_comment_title    VARCHAR(64)      NULL,
  review_comment_message  TEXT             NULL,
  review_creation_date    DATETIME         NOT NULL,
  review_answer_timestamp DATETIME         NOT NULL,
  PRIMARY KEY (review_id, order_id),
  KEY ix_reviews_order (order_id),
  KEY ix_reviews_score (review_score),
  CONSTRAINT fk_reviews_order FOREIGN KEY (order_id) REFERENCES orders (order_id),
  CONSTRAINT ck_review_score CHECK (review_score BETWEEN 1 AND 5)
) ENGINE = InnoDB;

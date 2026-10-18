USE ROLE ACCOUNTADMIN;
USE DATABASE OLIST_DWH;
USE SCHEMA RAW;

CREATE TABLE IF NOT EXISTS RAW_CUSTOMERS (
    customer_id              VARCHAR(50),
    customer_unique_id       VARCHAR(50),
    customer_zip_code_prefix INTEGER,
    customer_city            VARCHAR(100),
    customer_state           VARCHAR(10)
);
CREATE TABLE IF NOT EXISTS RAW_ORDERS (
    order_id                       VARCHAR(50),
    customer_id                    VARCHAR(50),
    order_status                   VARCHAR(30),
    order_purchase_timestamp       TIMESTAMP_NTZ,
    order_approved_at               TIMESTAMP_NTZ,
    order_delivered_carrier_date    TIMESTAMP_NTZ,
    order_delivered_customer_date   TIMESTAMP_NTZ,
    order_estimated_delivery_date   TIMESTAMP_NTZ
);
CREATE TABLE IF NOT EXISTS RAW_ORDER_ITEMS (
    order_id              VARCHAR(50),
    order_item_id         INTEGER,
    product_id            VARCHAR(50),
    seller_id             VARCHAR(50),
    shipping_limit_date   TIMESTAMP_NTZ,
    price                 NUMBER(12,2),
    freight_value         NUMBER(12,2)
);
CREATE TABLE IF NOT EXISTS RAW_ORDER_PAYMENTS (
    order_id                VARCHAR(50),
    payment_sequential      INTEGER,
    payment_type            VARCHAR(50),
    payment_installments    INTEGER,
    payment_value           NUMBER(12,2)
);
CREATE TABLE IF NOT EXISTS RAW_ORDER_REVIEWS (
    review_id                VARCHAR(50),
    order_id                 VARCHAR(50),
    review_score             INTEGER,
    review_comment_title     VARCHAR,
    review_comment_message   VARCHAR,
    review_creation_date     TIMESTAMP_NTZ,
    review_answer_timestamp  TIMESTAMP_NTZ
);
CREATE TABLE IF NOT EXISTS RAW_PRODUCTS (
    product_id                    VARCHAR(50),
    product_category_name        VARCHAR(100),
    product_name_lenght          INTEGER,
    product_description_lenght   INTEGER,
    product_photos_qty           INTEGER,
    product_weight_g             NUMBER(12,2),
    product_length_cm            NUMBER(12,2),
    product_height_cm            NUMBER(12,2),
    product_width_cm             NUMBER(12,2)
);
CREATE TABLE IF NOT EXISTS RAW_SELLERS (
    seller_id                VARCHAR(50),
    seller_zip_code_prefix   INTEGER,
    seller_city              VARCHAR(100),
    seller_state             VARCHAR(10)
);
CREATE TABLE IF NOT EXISTS RAW_GEOLOCATION (
    geolocation_zip_code_prefix  INTEGER,
    geolocation_lat              NUMBER(12,8),
    geolocation_lng              NUMBER(12,8),
    geolocation_city             VARCHAR(100),
    geolocation_state            VARCHAR(10)
);
CREATE TABLE IF NOT EXISTS RAW_PRODUCT_CATEGORY_TRANSLATION (
    product_category_name        VARCHAR(100),
    product_category_name_english VARCHAR(100)
);
SHOW TABLES IN SCHEMA OLIST_DWH.RAW;
SELECT *
FROM OLIST_DWH.MARTS.DIM_CUSTOMER
LIMIT 10;

SELECT *
FROM OLIST_DWH.MARTS.DIM_PRODUCT
LIMIT 10;

SELECT *
FROM OLIST_DWH.MARTS.DIM_SELLER
LIMIT 10;

SELECT *
FROM OLIST_DWH.MARTS.DIM_LOCATION
LIMIT 10;

SELECT *
FROM OLIST_DWH.MARTS.DIM_DATE
LIMIT 10;

SELECT COUNT(*)
FROM OLIST_DWH.MARTS.DIM_LOCATION;

SELECT
    MIN(FULL_DATE) AS min_date,
    MAX(FULL_DATE) AS max_date,
    COUNT(*) AS total_dates
FROM OLIST_DWH.MARTS.DIM_DATE;


SELECT COUNT(*) AS total_rows
FROM OLIST_DWH.MARTS.FACT_SALES;

SELECT *
FROM OLIST_DWH.MARTS.FACT_SALES
LIMIT 20;

SELECT
    order_id,
    order_item_id,
    COUNT(*) AS number_of_rows
FROM OLIST_DWH.MARTS.FACT_SALES
GROUP BY
    order_id,
    order_item_id
HAVING COUNT(*) > 1;

SELECT
    SUM(price) AS total_price,
    SUM(freight_value) AS total_freight,
    SUM(total_item_amount) AS total_amount
FROM OLIST_DWH.MARTS.FACT_SALES;

SELECT
    order_status,
    COUNT(*) AS number_of_items,
    SUM(total_item_amount) AS total_amount
FROM OLIST_DWH.MARTS.FACT_SALES
GROUP BY order_status
ORDER BY number_of_items DESC;


SELECT COUNT(*) AS total_rows
FROM OLIST_DWH.MARTS.FACT_PAYMENT;

SELECT
    order_id,
    payment_sequential,
    COUNT(*) AS number_of_rows
FROM OLIST_DWH.MARTS.FACT_PAYMENT
GROUP BY
    order_id,
    payment_sequential
HAVING COUNT(*) > 1;

SELECT
    payment_type,
    COUNT(*) AS number_of_payments,
    SUM(payment_value) AS total_payment_value
FROM OLIST_DWH.MARTS.FACT_PAYMENT
GROUP BY payment_type
ORDER BY total_payment_value DESC;

SELECT COUNT(*) AS total_rows
FROM OLIST_DWH.MARTS.FACT_REVIEW;

SELECT
    review_score,
    COUNT(*) AS number_of_reviews
FROM OLIST_DWH.MARTS.FACT_REVIEW
GROUP BY review_score
ORDER BY review_score;

SELECT
    review_sentiment_category,
    COUNT(*) AS number_of_reviews
FROM OLIST_DWH.MARTS.FACT_REVIEW
GROUP BY review_sentiment_category;

SELECT
    review_id,
    COUNT(*) AS number_of_rows
FROM OLIST_DWH.MARTS.FACT_REVIEW
GROUP BY review_id
HAVING COUNT(*) > 1;

SELECT *
FROM OLIST_DWH.MARTS.FACT_REVIEW
WHERE review_id = '260893353c2400249d80dcd57f34b1cb';


SELECT
    review_id,
    order_id,
    COUNT(*) AS number_of_rows
FROM OLIST_DWH.MARTS.FACT_REVIEW
GROUP BY
    review_id,
    order_id
HAVING COUNT(*) > 1;



SELECT COUNT(*) AS WITH_COMMENT FROM OLIST_DWH.MARTS.FACT_REVIEW ;

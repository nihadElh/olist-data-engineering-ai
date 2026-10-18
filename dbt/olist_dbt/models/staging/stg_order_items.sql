WITH source_order_items AS (

    SELECT *
    FROM {{ source('raw_olist', 'RAW_ORDER_ITEMS') }}

),

cleaned_order_items AS (

    SELECT
        TRIM(order_id) AS order_id,

        order_item_id  AS order_item_id,

        TRIM(product_id) AS product_id,

        TRIM(seller_id) AS seller_id,

            shipping_limit_date AS shipping_limit_timestamp,
            price  AS price,
            freight_value   AS freight_value

    FROM source_order_items

)

SELECT *
FROM cleaned_order_items
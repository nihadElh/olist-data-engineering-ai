WITH source_orders AS (

    SELECT *
    FROM {{ source('raw_olist', 'RAW_ORDERS') }}

),

cleaned_orders AS (

    SELECT
        TRIM(order_id) AS order_id,

        TRIM(customer_id) AS customer_id,

        LOWER(TRIM(order_status))
            AS order_status,

            order_purchase_timestamp AS purchase_timestamp,

            order_approved_at AS approved_timestamp,

            order_delivered_carrier_date AS delivered_carrier_timestamp,

            order_delivered_customer_date AS delivered_customer_timestamp,

            order_estimated_delivery_date AS estimated_delivery_timestamp

    FROM source_orders

)

SELECT *
FROM cleaned_orders
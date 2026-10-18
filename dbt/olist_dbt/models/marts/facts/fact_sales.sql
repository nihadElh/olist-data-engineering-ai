WITH order_items AS (

    SELECT *
    FROM {{ ref('stg_order_items') }}

),

orders AS (

    SELECT *
    FROM {{ ref('stg_orders') }}

),

fact_sales AS (

    SELECT

        -- Clés principales de la ligne de fait
        oi.order_id,
        oi.order_item_id,

        -- Clés métier
        o.customer_id,
        oi.product_id,
        oi.seller_id,

        -- Informations de commande
        o.order_status,

        -- Dates
        o.purchase_timestamp,
        o.approved_timestamp,
        o.delivered_carrier_timestamp,
        o.delivered_customer_timestamp,
        o.estimated_delivery_timestamp,

        -- Clé de date pour la dimension DIM_DATE
        TO_NUMBER(
            TO_CHAR(o.purchase_timestamp::DATE, 'YYYYMMDD')
        ) AS date_key,

        -- Mesures commerciales
        oi.price,
        oi.freight_value,

        oi.price + oi.freight_value AS total_item_amount,

        -- Indicateurs de livraison
        CASE
            WHEN o.delivered_customer_timestamp IS NOT NULL
             AND o.estimated_delivery_timestamp IS NOT NULL
            THEN DATEDIFF(
                'day',
                o.estimated_delivery_timestamp,
                o.delivered_customer_timestamp
            )
            ELSE NULL
        END AS delivery_delay_days,

        CASE
            WHEN o.delivered_customer_timestamp IS NOT NULL
             AND o.estimated_delivery_timestamp IS NOT NULL
             AND o.delivered_customer_timestamp
                 <= o.estimated_delivery_timestamp
            THEN TRUE

            WHEN o.delivered_customer_timestamp IS NOT NULL
             AND o.estimated_delivery_timestamp IS NOT NULL
            THEN FALSE

            ELSE NULL
        END AS delivered_on_time

    FROM order_items oi

    LEFT JOIN orders o
        ON oi.order_id = o.order_id

)

SELECT *
FROM fact_sales
WITH payments AS (

    SELECT *
    FROM {{ ref('stg_order_payments') }}

),

orders AS (

    SELECT *
    FROM {{ ref('stg_orders') }}

),

fact_payments AS (

    SELECT

        -- Clé du paiement
        p.order_id,
        p.payment_sequential,

        -- Informations de paiement
        p.payment_type,
        p.payment_installments,
        p.payment_value,

        -- Informations de la commande
        o.customer_id,
        o.order_status,
        o.purchase_timestamp,

        -- Clé de date
        TO_NUMBER(
            TO_CHAR(o.purchase_timestamp::DATE, 'YYYYMMDD')
        ) AS date_key

    FROM payments p

    LEFT JOIN orders o
        ON p.order_id = o.order_id

)

SELECT *
FROM fact_payments
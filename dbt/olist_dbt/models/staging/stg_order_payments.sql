WITH source_payments AS (

    SELECT *
    FROM {{ source('raw_olist', 'RAW_ORDER_PAYMENTS') }}

),

cleaned_payments AS (

    SELECT
        TRIM(order_id) AS order_id,

        payment_sequential AS payment_sequential,

        LOWER(TRIM(payment_type))
            AS payment_type,

        payment_installments AS payment_installments,

        payment_value AS payment_value

    FROM source_payments

)

SELECT *
FROM cleaned_payments
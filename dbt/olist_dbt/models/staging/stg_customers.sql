WITH source_customers AS (

    SELECT *
    FROM {{ source('raw_olist', 'RAW_CUSTOMERS') }}

),

cleaned_customers AS (

    SELECT
        TRIM(customer_id) AS customer_id,

        TRIM(customer_unique_id) AS customer_unique_id,

        TRY_TO_NUMBER(customer_zip_code_prefix)
            AS customer_zip_code_prefix,

        INITCAP(TRIM(customer_city))
            AS customer_city,

        UPPER(TRIM(customer_state))
            AS customer_state

    FROM source_customers

)

SELECT *
FROM cleaned_customers
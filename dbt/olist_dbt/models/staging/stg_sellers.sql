WITH source_sellers AS (

    SELECT *
    FROM {{ source('raw_olist', 'RAW_SELLERS') }}

),

cleaned_sellers AS (

    SELECT
        TRIM(seller_id)
            AS seller_id,

        TRY_TO_NUMBER(
            seller_zip_code_prefix
        ) AS seller_zip_code_prefix,

        INITCAP(
            TRIM(seller_city)
        ) AS seller_city,

        UPPER(
            TRIM(seller_state)
        ) AS seller_state

    FROM source_sellers

)

SELECT *
FROM cleaned_sellers
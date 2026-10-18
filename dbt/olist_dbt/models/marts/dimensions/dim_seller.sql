WITH sellers AS (

    SELECT *
    FROM {{ ref('stg_sellers') }}

),

dim_seller AS (

    SELECT
        seller_id,

        seller_zip_code_prefix,

        seller_city,

        seller_state

    FROM sellers

)

SELECT *
FROM dim_seller
WITH source_category_translation AS (

    SELECT *
    FROM {{ source(
        'raw_olist',
        'RAW_PRODUCT_CATEGORY_TRANSLATION'
    ) }}

),

cleaned_category_translation AS (

    SELECT
        LOWER(
            TRIM(product_category_name)
        ) AS product_category_name,

        LOWER(
            TRIM(product_category_name_english)
        ) AS product_category_name_english

    FROM source_category_translation

)

SELECT *
FROM cleaned_category_translation
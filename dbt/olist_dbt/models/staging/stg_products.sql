WITH source_products AS (

    SELECT *
    FROM {{ source('raw_olist', 'RAW_PRODUCTS') }}

),

cleaned_products AS (

    SELECT
        TRIM(product_id)
            AS product_id,

        NULLIF(
            TRIM(product_category_name),
            ''
        ) AS product_category_name,

            product_name_lenght AS product_name_length,

            product_description_lenght AS product_description_length,

            product_photos_qty AS product_photos_quantity,

            product_weight_g AS product_weight_g,

        
            product_length_cm AS product_length_cm,

            product_height_cm AS product_height_cm,

            product_width_cm AS product_width_cm

    FROM source_products

)

SELECT *
FROM cleaned_products
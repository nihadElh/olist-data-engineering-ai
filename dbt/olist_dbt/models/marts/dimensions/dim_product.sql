WITH products AS (

    SELECT *
    FROM {{ ref('stg_products') }}

),

category_translation AS (

    SELECT *
    FROM {{ ref('stg_category_translation') }}

),

dim_product AS (

    SELECT
        p.product_id,

        p.product_category_name,

        t.product_category_name_english,

        p.product_name_length,

        p.product_description_length,

        p.product_photos_quantity,

        p.product_weight_g,

        p.product_length_cm,

        p.product_height_cm,

        p.product_width_cm

    FROM products p

    LEFT JOIN category_translation t
        ON p.product_category_name =
           t.product_category_name

)

SELECT *
FROM dim_product
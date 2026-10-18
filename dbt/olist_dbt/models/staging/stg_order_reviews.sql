WITH source_reviews AS (

    SELECT *
    FROM {{ source('raw_olist', 'RAW_ORDER_REVIEWS') }}

),

cleaned_reviews AS (

    SELECT
        TRIM(review_id) AS review_id,

        TRIM(order_id) AS order_id,

        TRY_TO_NUMBER(review_score)
            AS review_score,

        NULLIF(
            TRIM(review_comment_title),
            ''
        ) AS review_comment_title,

        NULLIF(
            TRIM(review_comment_message),
            ''
        ) AS review_comment_message,

       
        review_creation_date AS review_creation_timestamp,

        review_answer_timestamp AS review_answer_timestamp

    FROM source_reviews

)

SELECT *
FROM cleaned_reviews
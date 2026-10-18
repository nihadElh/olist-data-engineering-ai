WITH reviews AS (

    SELECT *
    FROM {{ ref('stg_order_reviews') }}

),

orders AS (

    SELECT *
    FROM {{ ref('stg_orders') }}

),

fact_reviews AS (

    SELECT

        -- Identifiants
        r.review_id,
        r.order_id,
        o.customer_id,

        -- Évaluation
        r.review_score,
        r.review_comment_title,
        r.review_comment_message,

        -- Dates de l'avis
        r.review_creation_timestamp,
        r.review_answer_timestamp,

        -- Date d'achat de la commande
        o.purchase_timestamp,

        -- Clés de date
        TO_NUMBER(
            TO_CHAR(
                r.review_creation_timestamp::DATE,
                'YYYYMMDD'
            )
        ) AS review_date_key,

        TO_NUMBER(
            TO_CHAR(
                o.purchase_timestamp::DATE,
                'YYYYMMDD'
            )
        ) AS purchase_date_key,

        -- Délai de réponse à l'avis
        CASE
            WHEN r.review_creation_timestamp IS NOT NULL
             AND r.review_answer_timestamp IS NOT NULL
            THEN DATEDIFF(
                'day',
                r.review_creation_timestamp,
                r.review_answer_timestamp
            )
            ELSE NULL
        END AS review_answer_delay_days,

        -- Classification du score
        CASE
            WHEN r.review_score IN (1, 2)
                THEN 'Negative'

            WHEN r.review_score = 3
                THEN 'Neutral'

            WHEN r.review_score IN (4, 5)
                THEN 'Positive'

            ELSE 'Unknown'
        END AS review_sentiment_category,

        -- Présence d'un commentaire
        CASE
            WHEN r.review_comment_message IS NOT NULL
                THEN TRUE
            ELSE FALSE
        END AS has_comment

    FROM reviews r

    LEFT JOIN orders o
        ON r.order_id = o.order_id

)

SELECT *
FROM fact_reviews
{% snapshot snap_reviews %}

{{
    config(
        target_schema='SNAPSHOTS',
        unique_key='review_id',
        strategy='check',
        check_cols=[
            'order_id',
            'review_score',
            'review_comment_title',
            'review_comment_message',
            'review_answer_timestamp'
        ]
    )
}}

SELECT
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_timestamp,
    review_answer_timestamp

FROM {{ ref('stg_order_reviews') }}

{% endsnapshot %}
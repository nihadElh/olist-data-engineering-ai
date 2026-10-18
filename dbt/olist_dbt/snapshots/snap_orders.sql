{% snapshot snap_orders %}

{{
    config(
        target_schema='SNAPSHOTS',
        unique_key='order_id',
        strategy='check',
        check_cols=[
            'order_status',
            'order_approved_at',
            'order_delivered_carrier_date',
            'order_delivered_customer_date',
            'order_estimated_delivery_date'
        ]
    )
}}

SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date

FROM {{ ref('stg_orders') }}

{% endsnapshot %}
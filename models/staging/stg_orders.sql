{{ config(materialized='view') }}

with raw_orders as (
    select * from {{ source('raw_data', 'Orders') }}
),
clean_orders as (
    -- Removed duplicate order_id records 
    select distinct
        order_id,
        subscription_id,
        -- Cast order_date from timestamp to date type
        cast(order_date as date) as order_date,
        gross_amount,
        -- Parse JSON values
        json_value(checkout_metadata, '$.currency') as currency,
        cast(json_value(checkout_metadata, '$.exchange_rate') as float64) as exchange_rate,
        -- Convert NULL tax percentage values to 0
        coalesce(cast(json_value(checkout_metadata, '$.tax_percentage') as float64), 0.0) as tax_percentage
    from raw_orders
)

select * from clean_orders
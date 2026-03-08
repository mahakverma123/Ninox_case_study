{{ config(materialized='view') }}

with raw_subscriptions as (
    select * from {{ source('raw_data', 'Subscriptions') }}
),
cleaned_subscriptions as (
    select
        subscription_id,
        customer_id,
        -- Lower casing the plan_name to normalize
        lower(plan_name) as plan_name,
        -- Casting licenses to integer
        cast(number_of_licenses as int) as number_of_licenses,
        -- Casting start and end dates 
        cast(start_date as date) as start_date,
        cast(end_date as date) as end_date
    from raw_subscriptions
)

select * from cleaned_subscriptions
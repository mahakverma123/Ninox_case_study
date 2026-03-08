{{ config(materialized='table') }}

with base_orders as (
    -- Referencing the base table
    select * from {{ ref('int_base') }}
),

-- Generate a month index from 0 to 11 to represent the 12 months
month_spine as (
    select month_offset
    from unnest(generate_array(0, 11)) as month_offset
),

-- Filter records missing start dates to ensure accurate reporting
filtered_base as (
    select *
    from base_orders
    where subscription_start_month is not null
),

-- Expand each subscription across the next 12 months and calculate monthly MRR
scaffolded_mrr as (
    select
        b.customer_id,
        b.subscription_id,
        b.order_id,
        b.country,
        b.plan_name,
        b.number_of_licenses,
        -- Calculate the reporting month by adding each month offset to the subscription start
        date_add(b.subscription_start_month, interval s.month_offset month) as reporting_month,
        b.subscription_start_month,
        -- Round MRR to 2 decimal places
        round(b.monthly_mrr, 2) as monthly_mrr
    from filtered_base b
    cross join month_spine s
)

select
    *,
    -- Calculate which month this is in the 1 year subscription (0 to 11)
    date_diff(reporting_month, subscription_start_month, month) as subscription_month_number
from scaffolded_mrr
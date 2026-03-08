{{ config(materialized='view') }}

with orders as (
    select * from {{ ref('stg_orders') }}
),
subscriptions as (
    select * from {{ ref('stg_subscriptions') }}
),
users as (
    select * from {{ ref('stg_users') }}
),
joined_base as (
    select
        o.order_id,
        o.subscription_id,
        s.customer_id,
        u.country,
        --converting dates to first date of the month
        {{ to_start_of_month('o.order_date') }} as order_month,
        {{ to_start_of_month('s.start_date') }} as subscription_start_month,
        {{ to_start_of_month('s.end_date') }} as subscription_end_month,
        --calculate net revenue
        {{ calculate_net_revenue('o.gross_amount', 'o.tax_percentage', 'o.exchange_rate') }} as net_revenue_eur,
        s.plan_name,
        s.number_of_licenses
    from orders o
    left join subscriptions s on o.subscription_id = s.subscription_id
    left join users u on s.customer_id = u.user_id
),
final_metrics as (
    select
        *,
        --Calculate MRR as Net revenue/12 from the Net Revenue
        {{ calculate_mrr('net_revenue_eur') }} as monthly_mrr
    from joined_base
)

select * from final_metrics

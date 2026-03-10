{{ config(materialized='table') }}

-- This query provides the final cohort retention result
-- One row per cohort Month and age index (0-35)
with monthly_aggregates as (
    -- Sum up the EUR amounts from your intermediate table
    select
        cohort_month,
        month_number,
        sum(retained_mrr) as total_retained_mrr_eur
    from {{ ref('int_mrr_cohorts') }}
    group by 1, 2
),

retention_with_total_baseline as (
    -- Identify the Month 0 baseline for the WHOLE cohort
    select
        *,
        first_value(total_retained_mrr_eur) over (
            partition by cohort_month 
            order by month_number
        ) as cohort_total_mrr_month_0
    from monthly_aggregates
)

-- Final Output
select
    cohort_month,
    month_number,
    total_retained_mrr_eur as retained_mrr,
    round(safe_divide(total_retained_mrr_eur, cohort_total_mrr_month_0) * 100, 2) as retention_percentage
from retention_with_total_baseline
order by 1, 2
{{ config(materialized='table') }}

-- This query creates a detailed, customer-level reporting table for interactive dashboards.
select
    reporting_month,
    -- Split reporting_month into separate columns: year and month.
    format_date('%m', reporting_month) as month,
    format_date('%Y', reporting_month) as year,
    country,
    last_plan_name as plan_name,
    -- Aggregate movement categories
    round(sum(start_of_period), 2) as start_of_period_mrr,
    round(sum(new_mrr), 2) as new_mrr,
    round(sum(expansion_mrr), 2) as expansion_mrr,
    round(sum(contraction_mrr), 2) as contraction_mrr,
    round(sum(lost_mrr), 2) as lost_mrr,
    round(sum(end_of_period), 2) as end_of_period_mrr
from {{ ref('int_mrr_movements') }}
group by 1, 2, 3, 4, 5
order by 1, 4, 5
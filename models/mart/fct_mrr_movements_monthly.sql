{{ config(materialized='table') }}

-- This query creates the month and movements result.
select
    reporting_month,
    -- Aggregate customer level MRR to the monthly level for reporting.
    round(sum(start_of_period), 2) as start_of_period_mrr,
    round(sum(new_mrr), 2) as new_mrr,
    round(sum(expansion_mrr), 2) as expansion_mrr,
    round(sum(contraction_mrr), 2) as contraction_mrr,
    round(sum(lost_mrr), 2) as lost_mrr,
    round(sum(end_of_period), 2) as end_of_period_mrr
from {{ ref('int_mrr_movements') }}
group by 1
order by 1
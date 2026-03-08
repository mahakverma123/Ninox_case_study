{{ config(materialized='table') }}

-- This query provides the final cohort retention result
-- One row per cohort Month and age index (0-35)
select
    cohort_month,
    -- Create a cohort label for reporting
    format_date('%Y-%m', cohort_month) as cohort_label,
    month_number,
    -- round reatined_mrr to decimal points.
    round(retained_mrr, 2) as retained_mrr_eur,
    round(retention_percentage, 2) as retention_percentage
from {{ ref('int_mrr_cohorts') }}
order by 1, 3
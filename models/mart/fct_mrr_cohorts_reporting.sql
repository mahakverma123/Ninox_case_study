{{ config(materialized='table') }}

-- This query provides the final cohort retention result for the visualization
-- according to month, country and plan
select
    cohort_month,
    -- Create a cohort label for reporting
    format_date('%Y-%m', cohort_month) as cohort_label,
    month_number,
    --added year, country and plan name to segment retention analysis using slicers
    extract(year from cohort_month) as cohort_year,
    coalesce(country, 'Unknown') as country,
    plan_name,
    -- round reatined_mrr to decimal points.
    round(retained_mrr, 2) as retained_mrr_eur,
    round(retention_percentage, 2) as retention_percentage
from {{ ref('int_mrr_cohorts') }}
order by 1, 3, 4, 5, 6
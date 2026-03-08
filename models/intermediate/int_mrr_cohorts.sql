{{ config(materialized='table') }}

with mrr_details as (
    -- Referencing the mrr_detailed table
    select * from {{ ref('int_mrr_detailed') }}
    where reporting_month is not null 
),

-- 1. Identify first month a customer started, also called Cohort Month.
customer_cohort_map as (
    select
        customer_id,
        min(reporting_month) as cohort_month
    from mrr_details
    group by 1
),

-- 2. Create a customer level cohort timeline 
customer_cohort_details as (
    select
        d.customer_id,
        c.cohort_month,
        d.reporting_month,
        -- Calculate the age of the customer relative to their first purchase.
        date_diff(d.reporting_month, c.cohort_month, month) as month_number,
        d.monthly_mrr
    from mrr_details d
    join customer_cohort_map c on d.customer_id = c.customer_id
),

-- 3. Aggregate to the Cohort age level to get the month 0 baseline
cohort_aggregates as (
    select
        cohort_month,
        month_number,
        -- Round monthly mrr to decimal point.
        round(sum(monthly_mrr), 2) as retained_mrr_eur
    from customer_cohort_details
    group by 1, 2
),

-- 4. Extract the month 0 baseline for each cohort to calculate percentages
retention_with_baseline as (
    select
        *,
        -- Take the first valid month_number (0) as the denominator.
        first_value(retained_mrr_eur) over (
            partition by cohort_month 
            order by month_number
        ) as cohort_mrr_month_0
    from cohort_aggregates
)

-- 5. Final Result : Absolute EUR and Retention Percentage
select
    cohort_month,
    month_number,
    retained_mrr_eur as retained_mrr,
    -- Retention % = (Current Month MRR / Month 0 MRR)
    round(safe_divide(retained_mrr_eur, cohort_mrr_month_0) * 100, 2) as retention_percentage
from retention_with_baseline
where month_number is not null
order by 1, 2
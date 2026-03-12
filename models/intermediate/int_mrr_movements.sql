{{ config(materialized='table') }}

with mrr_details as (
    -- Referencing the mrr_detailed table
    select * from {{ ref('int_mrr_detailed') }}
),

-- Identify all unique months and add the next months to identify Lost movements
all_months as (
    select distinct reporting_month from mrr_details
    union distinct
    select date_add(max(reporting_month), interval 1 month) from mrr_details
),

-- Create a spine of every customer for every reporting month
customer_spine as (
    select
        c.customer_id,
        m.reporting_month
    from (select distinct customer_id from mrr_details) c
    cross join all_months m
),

-- Join details like actual MRR with the customer spine 
mrr_joined as (
    select
        s.customer_id,
        s.reporting_month,
        coalesce(d.monthly_mrr, 0) as monthly_mrr,
        -- Keep country and plan info to track Lost movements
        max(d.country) over (partition by s.customer_id) as country,
        max(d.plan_name) over (partition by s.customer_id) as last_plan_name
    from customer_spine s
    left join mrr_details d
        on s.customer_id = d.customer_id
        and s.reporting_month = d.reporting_month
),

-- Calculate the previous month's MRR for comparison
mrr_with_lag as (
    select
        *,
        lag(monthly_mrr) over (partition by customer_id order by reporting_month) as previous_mrr
    from mrr_joined
),

-- Apply categorization according to the given business rules
categorized_movements as (
    select
        customer_id,
        reporting_month,
        -- Handle missing geographical data
        coalesce(country, 'Unknown') as country,
        coalesce(last_plan_name, 'Unknown') as last_plan_name,
        round(coalesce(previous_mrr, 0), 2) as start_of_period,
        
        -- New: MRR generating for customers who had zero MRR last month
        round(case 
            when coalesce(previous_mrr, 0) = 0 and monthly_mrr > 0 then monthly_mrr 
            else 0 
        end, 2) as new_mrr,
        
        -- Expansion: Increase in MRR for an existing customer.
        round(case 
            when monthly_mrr > previous_mrr and coalesce(previous_mrr, 0) > 0 then monthly_mrr - previous_mrr 
            else 0 
        end, 2) as expansion_mrr,
        
        -- Contraction: Decrease in MRR compared to last month.
        round(case 
            when monthly_mrr < previous_mrr and monthly_mrr > 0 then monthly_mrr - previous_mrr 
            else 0 
        end, 2) as contraction_mrr,
        
        -- Lost: Customer’s MRR drops to zero this month.
        round(case 
            when coalesce(previous_mrr, 0) > 0 and monthly_mrr = 0 then -previous_mrr 
            else 0 
        end, 2) as lost_mrr,
        round(monthly_mrr, 2) as end_of_period
    from mrr_with_lag
)

-- Exclude rows with no activity to keep the dataset manageable
select * from categorized_movements
where start_of_period > 0 or end_of_period > 0
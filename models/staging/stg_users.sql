{{ config(materialized='view') }}

with raw_users as (
    select * from {{ source('raw_data', 'Users') }}
),
cleaned_users as (
    select
        user_id,
        first_name,
        last_name,
        email,
        -- Standardizing country names
        case 
            when country in ('DE', 'Germany') then 'Germany'
            when country in ('US', 'USA') then 'USA'
            else country
        end as country,
        -- Casting signup_date to date
        cast(signup_date as date) as signup_date
    from raw_users
)

select * from cleaned_users
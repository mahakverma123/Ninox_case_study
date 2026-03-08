{% macro to_start_of_month(date_column) %}
    -- Convert date to first date of the month 
    date_trunc({{ date_column }}, month)
{% endmacro %}

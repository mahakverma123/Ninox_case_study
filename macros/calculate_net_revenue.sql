{% macro calculate_net_revenue(gross_amount, tax_percentage, exchange_rate) %}
    -- Net Revenue = (Gross Amount / (1 + Tax Percentage)) * Exchange Rate
    ({{ gross_amount }} / (1 + {{ tax_percentage }})) * {{ exchange_rate }}
{% endmacro %}

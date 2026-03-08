{% macro calculate_mrr(net_revenue_eur) %}
    -- MRR is Net Revenue in EUR divided by 12
    {{ net_revenue_eur }} / 12
{% endmacro %}

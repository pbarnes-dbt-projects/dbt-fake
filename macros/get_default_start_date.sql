{% macro get_default_start_date() %}
{% if not execute %}{{return('')}}{% endif %}

{% set start_date = var('start_date', 'current_date() - 3') %}
{% if 'current_date()' in start_date %}
    {{ return(start_date) }}
{% else %}
    {{ return("date('" + start_date + "')") }}
{% endif %}

{% endmacro %}
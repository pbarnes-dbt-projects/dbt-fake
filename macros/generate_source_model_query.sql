{% macro generate_source_model_query(seed_name, max_per_day, start_date, end_date, columns) %}

{% if not execute %} 
    {{ return('') }}
{% endif %} 

{# Get one row per date and record expected #}
{% set date_sql %}
    select 
        date,
        cast(
            floor( 
                rand() * ({{ max_per_day}} + 1) 
            ) as int
        ) as num_records
    from unnest(
        generate_date_array(date({{ start_date }}), date({{ end_date }}), interval 1 day)
    ) as date
{% endset %}

{% set date_records = run_query(date_sql) %}
{% for date_record in date_records%}
  {{log(date_record.values(), info=true)}}

{% endfor %}
{% set date_column = 0 %}
{% set num_records_column = 1 %}
{# Manually setting row_number for dates using a namespace value #}
{% set row_number = namespace(value = 1) %}

with dates as (
    {# Generate one row per date and number of records for each date #}
    {%- for date_record in date_records %}
        {% set num_records = date_record[num_records_column] | int %}
        {% set date = date_record[date_column] %}
        {% for row in range(num_records) %}
            select date('{{ date }}') as date, {{ row_number.value }} as row_number union all 
            {% set row_number.value = row_number.value + 1 %}
        {% endfor %} 
    {% endfor %}
     {# Loop.last is difficult with the nested loop  #}
     select date('2023-01-01'), 1 as row_number limit {{ row_number.value }} 
),
models as (
    select
    {% for column in columns %}
        {{ column }}, 
    {% endfor %}
    row_number() over (order by null) as row_number
    from {{ ref(seed_name) }} as seed  

    {% if is_incremental() %}
        where not exists (
            select 
                1
            from {{ this }} as current_seed
            where seed.id = current_seed.id
        )
    {% endif %}
)

select 
    {% for column in columns %}
        models.{{ column }},
    {% endfor %}
    dates.date as date_added
from dates 
inner join models 
    on models.row_number = dates.row_number
{% endmacro %}
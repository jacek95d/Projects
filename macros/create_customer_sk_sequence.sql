{% macro create_customer_sk_sequence() %}
  {% set sql %}
    CREATE SEQUENCE IF NOT EXISTS {{ target.database }}.{{ target.schema }}.customer_sk_seq START WITH 1 INCREMENT BY 1;
  {% endset %}

  {% do run_query(sql) %}
{% endmacro %}

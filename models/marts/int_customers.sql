-- models/int_customers.sql
{{ config(
    materialized          = 'incremental',
    unique_key            = 'customer_id',
    incremental_strategy  = 'merge'
) }}

with raw_increments as (

  select *
  from {{ ref('stg_deliveries') }}
  {% if is_incremental() %}
    where load_time > (select max(load_time) from {{ this }})
  {% endif %}

), ranked as (

  select
    customer_id,
    customer_name,
    customer_city,
    customer_signup_date,
    load_time,
    row_number() over (
      partition by customer_id
      order by load_time desc
    ) as rn
  from raw_increments

)

select
  customer_id,
  customer_name,
  customer_city,
  customer_signup_date,
  load_time
from ranked
where rn = 1

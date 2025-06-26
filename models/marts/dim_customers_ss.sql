with history as (

  select
    customer_id,
    name,
    city,
    signup_date,
    dbt_valid_from     as record_start_ts,
    dbt_valid_to       as record_end_ts,
    (dbt_valid_to is null)::boolean  as is_current,
    load_time          as ingestion_ts

  from {{ ref('snap_customers') }}

)

select
  -- use dbt_utils.surrogate_key if you need a numeric SK here,
  -- or rely on customer_id as your natural key + versioning
  customer_id,
  name,
  city,
  signup_date,
  record_start_ts,
  record_end_ts,
  is_current,
  ingestion_ts
from history
where is_current


-- snapshots/snap_customers.sql
{% snapshot snap_customers %}

{{
  config(
    target_schema = "snapshots",
    unique_key    = "customer_id",
    strategy      = "timestamp",
    updated_at    = "load_time"
  )
}}

-- Pull from your staging model that already dedupes & flattens:
select
  customer_id,
  customer_name  as name,
  customer_city  as city,
  customer_signup_date::date  as signup_date,
  load_time
from {{ ref('int_customers') }}

{% endsnapshot %}

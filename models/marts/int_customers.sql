{{ config(
    materialized='incremental',
    unique_key='customer_id'
) }}

WITH ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id
               ORDER BY load_time DESC
           ) AS row_num
    FROM {{ ref('stg_deliveries') }}
    {% if is_incremental() %}
      WHERE load_time >= (SELECT MAX(load_time) FROM {{ this }})
    {% endif %}
)

SELECT
    customer_id,
    customer_name,
    customer_city,
    customer_signup_date,
    load_time
FROM ranked
WHERE row_num = 1
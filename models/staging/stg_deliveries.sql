WITH flattened AS (
  SELECT
    VALUE AS raw_data,
    filename,
    load_time
  FROM {{ source('raw', 'raw_deliveries') }},
       LATERAL FLATTEN(input => raw_data)
)

SELECT
    raw_data:"delivery_id"::STRING AS delivery_id,
    raw_data:"delivery_time"::TIMESTAMP AS delivery_time,
    raw_data:"status"::STRING AS delivery_status,
    raw_data:"total_amount"::FLOAT AS total_amount,
    raw_data:"customer":"customer_id"::STRING AS customer_id,
    raw_data:"customer":"name"::STRING AS customer_name,
    raw_data:"customer":"city"::STRING AS customer_city,
    raw_data:"customer":"signup_date"::DATE AS customer_signup_date,
    raw_data:"courier":"courier_id"::STRING AS courier_id,
    raw_data:"courier":"name"::STRING AS courier_name,
    raw_data:"courier":"vehicle_type"::STRING AS courier_vehicle_type,
    raw_data:"restaurant":"restaurant_id"::STRING AS restaurant_id,
    raw_data:"restaurant":"name"::STRING AS restaurant_name,
    raw_data:"restaurant":"category"::STRING AS restaurant_category,
    load_time,
    filename
FROM flattened

{% if is_incremental() %}
  WHERE load_time >= (SELECT MAX(load_time) FROM {{ this }})
  AND filename NOT IN (SELECT filename FROM {{ this }})
{% endif %}





{{ config(
    materialized='incremental',
    unique_key='id',
    incremental_strategy='merge',
    merge_update_columns = ['is_current', 'valid_to']
) }}

WITH source_data AS (
    SELECT
        customer_id AS id,
        customer_name AS name,
        customer_city AS city,
        customer_signup_date AS signup_date,
        {{ "customer_sk_seq.nextval" }} AS customer_sk,
        load_time,
        DATE(load_time) AS valid_from,
        DATE('9999-01-01') AS valid_to,
        TRUE AS is_current,
        {{ dbt_utils.generate_surrogate_key(['customer_id', 'customer_name', 'customer_city']) }} AS row_hash
    FROM {{ ref('int_customers') }}
),

existing AS (
    {% if is_incremental() %}
    SELECT * FROM {{ this }} WHERE is_current = TRUE
    {% else %}
    SELECT NULL AS id, NULL AS name, NULL AS city, NULL AS signup_date, NULL AS customer_sk,
           NULL AS valid_from, NULL AS valid_to, NULL AS is_current, NULL AS row_hash
    WHERE FALSE
    {% endif %}
),

to_update AS (
    SELECT d.*
    FROM source_data  d
    LEFT JOIN existing e ON d.id = e.id
    WHERE e.row_hash IS NULL OR d.row_hash != e.row_hash
),

-- mark current records as expired
updated AS (
    SELECT
        id,
        FALSE AS is_current,
        DATE(CURRENT_TIMESTAMP) AS valid_to
    FROM to_update
)

-- Final output to insert
SELECT
    id,
    name,
    city,
    customer_sk,
    signup_date,
    valid_from,
    valid_to,
    is_current
FROM to_update


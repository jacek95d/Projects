{{ config(
    materialized='incremental',
    unique_key='id',
    incremental_strategy='insert_overwrite'
) }}

WITH source_data AS (
    SELECT
        customer_id AS id,
        customer_name AS name,
        customer_city AS city,
        customer_signup_date AS signup_date,
        load_time,
        DATE(load_time) AS valid_from,
        DATE('9999-01-01') AS valid_to,
        TRUE AS is_current,
        {{ dbt_utils.generate_surrogate_key(['customer_id', 'customer_name', 'customer_city','customer_signup_date']) }} AS customer_sk
    FROM {{ ref('int_customers') }}
),

existing AS (
    {% if is_incremental() %}
    SELECT *,
    {{ dbt_utils.generate_surrogate_key(['id', 'name', 'city','signup_date']) }} AS existing_customer_sk
    FROM {{ this }} WHERE is_current = TRUE
    {% else %}
    SELECT NULL AS id, NULL AS name, NULL AS city, NULL AS signup_date,
           NULL AS valid_from, NULL AS valid_to, NULL AS is_current, NULL AS existing_customer_sk
    WHERE FALSE
    {% endif %}
),

to_update AS (
    SELECT d.*
    FROM source_data  d
    LEFT JOIN existing e ON d.id = e.id
    WHERE e.existing_customer_sk IS NULL OR d.customer_sk != e.existing_customer_sk
),

-- mark current records as expired
updated AS (
    SELECT
        e.id,
        e.name,
        e.city,
        e.existing_customer_sk,
        e.signup_date,
        e.valid_from,
        FALSE AS is_current,
        DATE(CURRENT_TIMESTAMP) AS valid_to
    FROM existing e
    JOIN to_update d ON e.id = d.id
)

{% if is_incremental() %}

-- 1. All existing rows that are NOT being updated (stay as-is)
SELECT t.id, t.name, t.city, t.customer_sk, t.signup_date, t.valid_from, t.valid_to, t.is_current
FROM {{ this }} t WHERE is_current = FALSE

UNION ALL

SELECT t.id, t.name, t.city, t.customer_sk, t.signup_date, t.valid_from, t.valid_to, t.is_current FROM {{ this }} t
LEFT JOIN to_update u ON u.id = t.id
WHERE t.is_current = TRUE AND u.id IS NULL


UNION ALL

-- 2. Expire current rows that are changing
SELECT
    e.id,
    e.name,
    e.city,
    e.existing_customer_sk,
    e.signup_date,
    e.valid_from,
    DATE(CURRENT_TIMESTAMP) AS valid_to,
    FALSE AS is_current
FROM existing e
JOIN to_update d ON e.id = d.id

UNION ALL

-- 3. Insert new version
SELECT
    u.id,
    u.name,
    u.city,
    u.customer_sk,
    u.signup_date,
    u.valid_from,
    DATE('9999-01-01') AS valid_to,
    TRUE AS is_current
FROM to_update u

{% else %}

-- Initial full-refresh logic (just load all source_data)
SELECT
    s.id,
    s.name,
    s.city,
    s.customer_sk,
    s.signup_date,
    s.valid_from,
    DATE('9999-01-01') AS valid_to,
    TRUE AS is_current
FROM source_data s

{% endif %}

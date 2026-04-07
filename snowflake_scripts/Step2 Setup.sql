USE ROLE tb_data_engineer;
USE DATABASE SNOWFLAKE_INTELLIGENCE;
USE WAREHOUSE tb_de_wh;
USE SCHEMA franchise_intelligent_agent_franchise_agent_marts;

-- Build a simple performance summary for the prompt
CREATE OR REPLACE VIEW franchise_perf_summary AS
SELECT
    franchise_id,
    franchise_owner_name,
    franchise_city,
    franchise_country,
    truck_brand_name,
    SUM(total_revenue)    AS total_revenue_all_time,
    SUM(total_orders)     AS total_orders_all_time,
    AVG(avg_order_value)  AS avg_order_value,
    MAX(order_month)      AS last_active_month,
    -- classify performance tier to steer the LLM tone
    CASE
        WHEN SUM(total_revenue) > 500000  THEN 'high performer'
        WHEN SUM(total_revenue) > 150000  THEN 'mid performer'
        ELSE                                   'low performer'
    END AS performance_tier
FROM fct_franchise_revenue
GROUP BY 1, 2, 3, 4, 5;


-- Create the target table first
CREATE OR REPLACE TABLE franchise_feedback (
    feedback_id         NUMBER AUTOINCREMENT PRIMARY KEY,
    franchise_id        NUMBER,
    franchise_owner_name VARCHAR,
    franchise_city      VARCHAR,
    franchise_country   VARCHAR,
    truck_brand_name    VARCHAR,
    feedback_type       VARCHAR,   -- 'customer_complaint', 'customer_praise', 'ops_report'
    feedback_date       DATE,
    feedback_text       VARCHAR,
    performance_tier    VARCHAR
);

-- Generate 3 feedback records per franchise (one of each type)
-- This uses AI_COMPLETE with a structured prompt
INSERT INTO franchise_feedback (
    franchise_id,
    franchise_owner_name,
    franchise_city,
    franchise_country,
    truck_brand_name,
    feedback_type,
    feedback_date,
    feedback_text,
    performance_tier
)
SELECT
    franchise_id,
    franchise_owner_name,
    franchise_city,
    franchise_country,
    truck_brand_name,
    feedback_type,
    DATEADD('day', -UNIFORM(1, 180, RANDOM()), CURRENT_DATE()) AS feedback_date,
    TRIM(AI_COMPLETE(
        'mistral-large2',
        'You are generating realistic customer or operations feedback for a food truck franchise. '
        || 'Write a single paragraph of 3-4 sentences of ' || feedback_type || ' feedback '
        || 'for a ' || truck_brand_name || ' food truck franchise in ' || franchise_city || ', ' || franchise_country || '. '
        || 'The franchise is a ' || performance_tier || '. '
        || 'For customer_complaint: include specific issues like wait time, food quality, or staff attitude. '
        || 'For customer_praise: include specific compliments about food, speed, or friendliness. '
        || 'For ops_report: write as an area manager noting operational issues like equipment problems, supply delays, or hygiene concerns. '
        || 'Write only the feedback text. No labels, no preamble, no quotation marks.'
    )) AS feedback_text,
    performance_tier
FROM franchise_perf_summary
CROSS JOIN (
    SELECT 'customer_complaint' AS feedback_type UNION ALL
    SELECT 'customer_praise'                      UNION ALL
    SELECT 'ops_report'
) feedback_types;

SELECT franchise_id, franchise_owner_name, feedback_type, feedback_text
FROM franchise_feedback
ORDER BY franchise_id, feedback_type
LIMIT 15;
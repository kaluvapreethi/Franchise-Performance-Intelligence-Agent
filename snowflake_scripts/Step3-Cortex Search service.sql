USE ROLE tb_data_engineer;
USE DATABASE SNOWFLAKE_INTELLIGENCE;
USE WAREHOUSE tb_de_wh;
USE SCHEMA franchise_intelligent_agent_franchise_agent_marts;

CREATE OR REPLACE CORTEX SEARCH SERVICE franchise_feedback_search
    ON feedback_text
    ATTRIBUTES franchise_id, franchise_owner_name, franchise_city,
               franchise_country, truck_brand_name, feedback_type, feedback_date,
               sentiment_score
    WAREHOUSE = tb_de_wh
    TARGET_LAG = '1 day'
    AS (
        SELECT
            feedback_id,
            franchise_id,
            franchise_owner_name,
            franchise_city,
            franchise_country,
            truck_brand_name,
            feedback_type,
            feedback_date,
            feedback_text,
            performance_tier,
            sentiment_score
        FROM franchise_feedback
    );

    SELECT PARSE_JSON(
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'franchise_feedback_search',
        '{"query": "wait time complaints Paris", "columns": ["franchise_owner_name","feedback_text","franchise_city"], "limit": 3}'
    )
) AS search_results;

ALTER TABLE franchise_feedback ADD COLUMN sentiment_score FLOAT;

UPDATE franchise_feedback
SET sentiment_score = SNOWFLAKE.CORTEX.SENTIMENT(feedback_text);

select * from franchise_feedback limit 1000;
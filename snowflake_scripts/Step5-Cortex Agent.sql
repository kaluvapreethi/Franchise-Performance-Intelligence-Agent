USE ROLE accountadmin;
USE DATABASE SNOWFLAKE_INTELLIGENCE;
USE SCHEMA SNOWFLAKE_INTELLIGENCE.FRANCHISE_INTELLIGENT_AGENT_FRANCHISE_AGENT_MARTS;

CREATE OR REPLACE AGENT franchise_intelligence_agent
  COMMENT = 'Franchise Performance Intelligence Agent for Tasty Bytes'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  instructions:
    system: "I am an intelligence agent for Tasty Bytes franchise performance. I can answer questions about franchise revenue, order volumes, and customer/operational feedback. I combine structured sales data with unstructured franchise feedback to give you a complete picture."
    response: "You are a senior business analyst for Tasty Bytes. Answer questions about franchise performance using revenue data and feedback. Always cite whether your answer comes from structured revenue data or from feedback records. Format numbers as currency where relevant."
    orchestration: "When a user asks about performance metrics (revenue, orders, rankings), use the franchise_revenue_analyst tool. When they ask about complaints, feedback, praise, or operational issues, use the franchise_feedback_search tool. If a question spans both (e.g. 'Which low-revenue franchise has the most complaints?'), use both tools and combine the answer clearly."

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "franchise_revenue_analyst"
        description: "Answers questions about franchise revenue, order counts, average order values, and franchise rankings. Use for any numerical or time-based performance question."
    - tool_spec:
        type: "cortex_search"
        name: "franchise_feedback_search"
        description: "Searches franchise feedback, customer complaints, customer praise, and operational reports. Use for qualitative questions about what customers or area managers think of specific franchises."

  tool_resources:
    franchise_revenue_analyst:
      semantic_model_file: "@SNOWFLAKE_INTELLIGENCE.FRANCHISE_INTELLIGENT_AGENT_FRANCHISE_AGENT_MARTS.semantic_models/franchise_revenue_semantic_model.yaml"
    franchise_feedback_search:
      name: "SNOWFLAKE_INTELLIGENCE.FRANCHISE_INTELLIGENT_AGENT_FRANCHISE_AGENT_MARTS.franchise_feedback_search"
      max_results: "5"
  $$;

-- Grant access
GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.FRANCHISE_INTELLIGENT_AGENT_FRANCHISE_AGENT_MARTS.franchise_intelligence_agent
    TO ROLE tb_data_engineer;
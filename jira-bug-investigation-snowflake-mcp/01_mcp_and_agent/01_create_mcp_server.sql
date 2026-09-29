
USE DATABASE FINANCE_DEMO_DB;
USE SCHEMA FINANCE_DEMO_DB.GOLD;
USE WAREHOUSE FINANCE_DEMO_WH;

-- ============================================================================
-- 8. INTERNAL MCP SERVER
-- ============================================================================

CREATE OR REPLACE MCP SERVER
    FINANCE_DEMO_DB.GOLD.FINANCE_ANALYTICS_MCP_SERVER

FROM SPECIFICATION
$$
tools:
  - name: "finance-sales-analyst"
    type: "CORTEX_ANALYST_MESSAGE"
    identifier: "FINANCE_DEMO_DB.GOLD.FINANCE_SALES_SEMANTIC_VIEW"
    title: "Finance Sales Analyst"
    description: >
      Analyze sales KPIs including revenue, orders, customers, margin,
      sales channel, product category, region and split-payment patterns.

  - name: "execute-finance-sql"
    type: "SYSTEM_EXECUTE_SQL"
    title: "Execute Finance SQL"
    description: >
      Execute read-only Snowflake SQL for detailed Jira bug investigation,
      duplicate detection, source-to-target reconciliation and join analysis.
$$;
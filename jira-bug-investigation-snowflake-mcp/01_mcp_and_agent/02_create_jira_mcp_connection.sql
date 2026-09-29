-- Create Jira external MCP connector with OAuth dynamic client registration

USE DATABASE FINANCE_DEMO_DB;
USE SCHEMA FINANCE_DEMO_DB.GOLD;
USE WAREHOUSE FINANCE_DEMO_WH;

-- ============================================================================
-- 9. JIRA EXTERNAL MCP CONNECTOR
-- ============================================================================

-- Step 1: Create the API integration using dynamic client registration (DCR)
-- Note: OR REPLACE is not supported for external_mcp integrations; drop first if recreating.
DROP API INTEGRATION IF EXISTS JIRA_MCP_API_INTEGRATION;

CREATE API INTEGRATION JIRA_MCP_API_INTEGRATION
    API_PROVIDER = EXTERNAL_MCP
    API_ALLOWED_PREFIXES = ('https://mcp.atlassian.com')
    API_USER_AUTHENTICATION = (
        TYPE = OAUTH_DYNAMIC_CLIENT,
        OAUTH_RESOURCE_URL = 'https://mcp.atlassian.com/v1/mcp'
    )
    ENABLED = TRUE;

-- Step 2: Create the external MCP server
CREATE OR REPLACE EXTERNAL MCP SERVER FINANCE_DEMO_DB.GOLD.ATLASSIAN_JIRA_MCP_SERVER
    WITH DISPLAY_NAME = 'Atlassian (Jira & Confluence)'
    URL = 'https://mcp.atlassian.com/v1/mcp'
    API_INTEGRATION = JIRA_MCP_API_INTEGRATION;

--Got To https://admin.atlassian.com/ 
-- under ROVO -> ROVO MCP SERVER 
-- under DOMAIN ADD 'https://identity.snowflake.com/oauth2/callback'

-- Step 3: Authenticate with Atlassian (run these manually in the same session)
--
-- SELECT SYSTEM$START_USER_OAUTH_FLOW('JIRA_MCP_API_INTEGRATION');
--
-- After completing consent in the browser, run:
-- SELECT SYSTEM$FINISH_OAUTH_FLOW('https://apps-api.c1.us-east-2.aws.app.snowflake.com/oauth/complete-secret');
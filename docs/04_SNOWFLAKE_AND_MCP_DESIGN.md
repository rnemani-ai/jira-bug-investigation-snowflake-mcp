# Snowflake and MCP Technical Design

## Snowflake environment

-   Database: `FINANCE_DEMO_DB`
-   Warehouse: `FINANCE_DEMO_WH`
-   Schemas: `BRONZE`, `SILVER`, `GOLD`

## Bronze

-   `SALES` --- `ORDER_ITEM_ID` grain.
-   `PAYMENTS` --- `PAYMENT_ID` grain.
-   `CUSTOMERS`
-   `PRODUCTS`

## Silver

`FACT_SALES` remains at `ORDER_ITEM_ID` grain.

The transformation aggregates successful payments by `ORDER_ID` before
joining payment information to item-grain sales. This avoids directly
joining item-grain sales to payment-grain rows.

Dimensions: - `DIM_CUSTOMER` - `DIM_PRODUCT` - `DIM_DATE`

## Gold

`VW_SALES_KPI` provides business-ready measures and dimensions,
including revenue, orders, channels, product categories and
split-payment indicators.

## Semantic View

`FINANCE_DEMO_DB.GOLD.FINANCE_SALES_SEMANTIC_VIEW`

It provides business-friendly metadata for finance analytics and is used
by the `finance-sales-analyst` MCP tool.

## Internal Snowflake MCP

`FINANCE_DEMO_DB.GOLD.FINANCE_ANALYTICS_MCP_SERVER`

Implemented tools: - `finance-sales-analyst` - `execute-finance-sql`

## Jira MCP

External Atlassian MCP using OAuth dynamic-client authentication. It
supplies issue context and discussion for investigation.

## GitHub MCP

Connects to the private
`rnemani-ai/jira-bug-investigation-snowflake-mcp` repository using
GitHub App/OAuth-based access. It provides read-oriented code,
test-data, commit and repository evidence.

## Important runtime boundary

At the current POC checkpoint: - `BRONZE.SALES` = 0 rows -
`SILVER.FACT_SALES` = 0 rows - `GOLD.VW_SALES_KPI` = 0 rows

Therefore FSP-8 runtime reproduction is blocked in the current
environment.

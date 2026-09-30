# Architecture & End-to-End Flow

## High-level architecture

``` text
User / Persona
     |
     v
Cortex Agent: FINANCE_JIRA_AGENT
     |
     +----------------+------------------+
     |                |                  |
     v                v                  v
 Jira MCP       Snowflake MCP       GitHub MCP
     |                |                  |
     v                v                  v
Jira context     Runtime data       Code/test evidence
     |                |                  |
     +----------------+------------------+
                      |
                      v
              Evidence synthesis
                      |
                      v
                  RCA + Impact
                      |
                      v
             Proposed Jira comment
                      |
                      v
                 Human approval
```

## Snowflake data flow

``` text
BRONZE
SALES (ORDER_ITEM_ID)
PAYMENTS (PAYMENT_ID)
CUSTOMERS / PRODUCTS
        |
        v
SILVER
FACT_SALES (ORDER_ITEM_ID)
payment aggregation by ORDER_ID
dimensions
        |
        v
GOLD
VW_SALES_KPI
        |
        v
FINANCE_SALES_SEMANTIC_VIEW
```

## Complete 14-step investigation flow

1.  User asks a natural-language question such as `Investigate FSP-8`.
2.  Agent understands intent and determines the investigation plan.
3.  Agent retrieves the Jira issue through Jira MCP.
4.  Agent retrieves description, priority, labels, comments and
    acceptance criteria.
5.  Agent parses and classifies Jira evidence.
6.  Agent queries Snowflake for runtime validation.
7.  Agent analyzes Snowflake results, grain and data availability.
8.  Agent retrieves transformation code and test data from GitHub.
9.  Agent analyzes transformation logic and payment aggregation.
10. Agent validates evidence across data layers where runtime data
    permits.
11. Agent cross-references Jira, Snowflake and GitHub and determines RCA
    status.
12. Agent prepares structured RCA, impact and recommendations.
13. Agent generates a proposed Jira comment; it is not posted
    automatically.
14. Human reviews/approves the proposed update; the final response
    includes evidence, RCA, limitations and next steps.

## Three evidence planes

  Source      Primary role
  ----------- -------------------------------------------
  Jira        Business report, expected/actual behavior
  GitHub      Implementation and test evidence
  Snowflake   Runtime evidence

The Agent's main value is reconciling all three.

# Technical Architecture and Implementation

## 1. Document Purpose


> **Document boundary:** This is the implementation reference. It focuses on concrete Snowflake objects, data-layer design, MCP configuration, Agent wiring, GitHub/Snowflake Git integration, RBAC, security controls, and technical execution flow. Detailed skill methodology, the full FSP-8 case study, and evaluation results belong in their dedicated documents.

This document describes the **implemented technical architecture** of the Jira Bug Investigation with Snowflake MCP proof of concept.

It focuses on the concrete implementation:

- Snowflake database and schemas
- Bronze / Silver / Gold data flow
- Semantic View
- Snowflake MCP
- Atlassian Jira MCP
- GitHub MCP
- GitHub App
- Snowflake Git integration
- Cortex Agent
- Investigation skill
- Agent personas
- RBAC
- Evidence flow
- FSP-8 investigation path
- Read-only and human-approval controls
- Evaluation architecture

This document is intentionally more implementation-oriented than the project overview.

---

# 1. High-Level Architecture

The implemented architecture is:

```text
                         ┌──────────────────────────────┐
                         │       Investigation User     │
                         │                              │
                         │ Finance Analyst              │
                         │ Data Engineer                │
                         │ Engineering Manager          │
                         └──────────────┬───────────────┘
                                        │
                                        ▼
                         ┌──────────────────────────────┐
                         │       Cortex Agent           │
                         │ FINANCE_JIRA_AGENT           │
                         └──────────────┬───────────────┘
                                        │
              ┌─────────────────────────┼─────────────────────────┐
              │                         │                         │
              ▼                         ▼                         ▼
   ┌─────────────────────┐   ┌─────────────────────┐   ┌─────────────────────┐
   │   Atlassian Jira    │   │   Finance Analytics │   │      GitHub MCP      │
   │        MCP          │   │        MCP          │   │ GITHUB_BUG_          │
   │                     │   │                     │   │ INVESTIGATION        │
   └──────────┬──────────┘   └──────────┬──────────┘   └──────────┬──────────┘
              │                         │                         │
              ▼                         ▼                         ▼
       Jira Cloud                Snowflake SQL /             Private GitHub
       issue evidence            Semantic View              repository
              │                         │                         │
              └─────────────────────────┼─────────────────────────┘
                                        ▼
                              Evidence Reconciliation
                                        │
                         ┌──────────────┼──────────────┐
                         ▼              ▼              ▼
                       RCA         Business Impact   Regression
                    Classification  Classification     Guidance
                         │              │              │
                         └──────────────┼──────────────┘
                                        ▼
                              Proposed Jira Update
                                        │
                                        ▼
                               Human Approval Gate
```

---

# 2. Snowflake Platform Architecture

## 3.1 Database

The project uses:

```text
FINANCE_DEMO_DB
```

The database contains three primary analytical layers:

```text
FINANCE_DEMO_DB
├── BRONZE
├── SILVER
└── GOLD
```

The warehouse is:

```text
FINANCE_DEMO_WH
```

---

# 3. Bronze Layer

The Bronze layer represents source-oriented finance data.

Implemented objects include:

```text
FINANCE_DEMO_DB.BRONZE.SALES
FINANCE_DEMO_DB.BRONZE.PAYMENTS
FINANCE_DEMO_DB.BRONZE.CUSTOMERS
FINANCE_DEMO_DB.BRONZE.PRODUCTS
```

## 4.1 SALES

The sales source contains order-item-level records.

Important grain:

```text
ORDER_ITEM_ID
```

This grain is important because revenue is ultimately expected to remain attributable to individual order items.

---

## 4.2 PAYMENTS

The payment source contains payment-level records.

Important grain:

```text
PAYMENT_ID
```

Multiple payment records can belong to the same:

```text
ORDER_ID
```

This creates the exact cardinality issue investigated by FSP-8.

For example:

```text
ORDER_ID = 1001

Sales:
2 order items

Payments:
2 successful payments
```

A direct join on `ORDER_ID` can produce:

```text
2 × 2 = 4 rows
```

instead of the expected two item-level rows.

---

# 4. Silver Layer

The Silver layer contains normalized analytical structures.

Implemented objects include:

```text
FINANCE_DEMO_DB.SILVER.FACT_SALES
FINANCE_DEMO_DB.SILVER.DIM_CUSTOMER
FINANCE_DEMO_DB.SILVER.DIM_PRODUCT
FINANCE_DEMO_DB.SILVER.DIM_DATE
```

## 5.1 FACT_SALES

The principal fact table is:

```text
FINANCE_DEMO_DB.SILVER.FACT_SALES
```

Its intended grain is:

```text
ORDER_ITEM_ID
```

The table contains sales measures and payment-derived attributes.

Important payment-related fields include:

```text
SUCCESSFUL_PAYMENT_COUNT
SUCCESSFUL_PAYMENT_AMOUNT
PAYMENT_METHODS
PAYMENT_PATTERN
```

The implementation uses payment aggregation before joining payment information into the item-grain fact.

---

# 5. Payment Aggregation Pattern

The key transformation pattern is:

```text
BRONZE.PAYMENTS
       │
       │ filter successful payments
       ▼
Payment Summary
GROUP BY ORDER_ID
       │
       │ one row per order
       ▼
FACT_SALES
ORDER_ITEM_ID grain
```

The payment summary is a **transformation/CTE pattern**, not a separate persistent Silver table.

Conceptually:

```sql
PAYMENT_SUMMARY
GROUP BY ORDER_ID
```

produces one payment summary record per order.

The final fact transformation then joins that summary to sales.

This changes the relationship from:

```text
ORDER_ITEM_ID
      ↕
PAYMENT_ID
```

with potentially many-to-many multiplication,

to:

```text
ORDER_ITEM_ID
      ↓
ORDER_ID
      ↓
one payment summary row
```

The intended result is:

```text
FACT_SALES remains one row per ORDER_ITEM_ID
```

---

# 6. Gold Layer

The Gold layer provides business-facing analytics.

Primary object:

```text
FINANCE_DEMO_DB.GOLD.VW_SALES_KPI
```

The Gold view contains finance-oriented measures and dimensions including concepts such as:

- gross revenue
- net revenue
- average order value
- order count
- customer segment
- sales channel
- product category
- month
- quarter
- payment pattern

The Gold layer is intended to provide a business-facing representation of the underlying Silver data.

---

# 7. Semantic View

The implemented Semantic View is:

```text
FINANCE_DEMO_DB.GOLD.FINANCE_SALES_SEMANTIC_VIEW
```

It is built over:

```text
FINANCE_DEMO_DB.GOLD.VW_SALES_KPI
```

The Semantic View provides a business-oriented semantic representation for finance analysis.

It is used by the internal Snowflake MCP tool:

```text
finance-sales-analyst
```

This allows business questions to be handled through a semantic interface while detailed technical questions can use direct read-only SQL.

---

# 8. Snowflake MCP Architecture

The internal MCP server is:

```text
FINANCE_DEMO_DB.GOLD.FINANCE_ANALYTICS_MCP_SERVER
```

It contains two implemented tools.

## 9.1 finance-sales-analyst

Configuration concept:

```text
type:
CORTEX_ANALYST_MESSAGE

identifier:
FINANCE_DEMO_DB.GOLD.FINANCE_SALES_SEMANTIC_VIEW
```

Purpose:

- finance KPI analysis
- business-level questions
- revenue analysis
- order analysis
- customer analysis
- channel/category analysis
- split-payment analysis

---

## 9.2 execute-finance-sql

Configuration concept:

```text
type:
SYSTEM_EXECUTE_SQL
```

Purpose:

- inspect data availability
- inspect schemas
- investigate joins
- investigate duplicates
- compare source and target data
- reconcile values
- perform detailed read-only investigation

The Agent instructions restrict investigation activity to non-destructive SQL.

---

# 9. Atlassian Jira MCP

The external Jira integration is represented in Snowflake as:

```text
FINANCE_DEMO_DB.GOLD.ATLASSIAN_JIRA_MCP_SERVER
```

The external MCP endpoint is Atlassian's MCP service.

Authentication uses:

```text
OAUTH_DYNAMIC_CLIENT
```

The Snowflake API integration is:

```text
JIRA_MCP_API_INTEGRATION
```

The OAuth flow is initiated and completed through Snowflake's user OAuth workflow.

The Agent uses the Jira MCP connection to retrieve issue information.

---

# 10. Jira Evidence Model

The Agent is instructed to inspect available Jira fields such as:

```text
Summary
Description
Reproduction Steps
Expected Result
Actual Result
Comments
Labels
Priority
Linked Issues
Acceptance Criteria
```

Jira information is classified as:

```text
Documented evidence
```

unless the claim is independently validated.

For example:

```text
Jira says revenue is duplicated
```

is a documented claim.

It does not automatically mean:

```text
Snowflake currently reproduces revenue duplication
```

That distinction is fundamental to the implementation.

---

# 11. GitHub Integration Architecture

The project uses a private GitHub repository:

```text
https://github.com/rnemani-ai/jira-bug-investigation-snowflake-mcp
```

The repository contains the project implementation and configuration.

The GitHub integration consists of two complementary mechanisms:

```text
GitHub MCP
     +
Snowflake Git
```

They serve related but different purposes.

---

# 12. GitHub App

A dedicated GitHub App was created:

```text
Snowflake Jira Bug Investigation
```

The App was installed only on the POC repository.

Repository-level permissions are read-oriented and include:

```text
Contents      Read-only
Metadata      Read-only
Pull requests Read-only
Issues        Read-only
```

This allows the Agent to inspect private repository evidence without giving it broad repository-management privileges.

---

# 13. GitHub MCP Connector

The Snowflake connector is:

```text
GITHUB_BUG_INVESTIGATION
```

Its purpose is to investigate:

- SQL
- transformation logic
- repository structure
- test data
- commits
- pull requests
- implementation context

The connector is attached to:

```text
FINANCE_DEMO_DB.GOLD.FINANCE_JIRA_AGENT
```

The completed POC uses the GitHub connector primarily for **read-oriented implementation investigation**.

It is not treated as an automatic code modification mechanism.

---

# 14. Snowflake Git Integration

The project also configures Snowflake Git integration.

## Secret

```text
FINANCE_DEMO_DB.GOLD.GITHUB_JIRA_POC_SECRET
```

## API Integration

```text
GITHUB_JIRA_POC_API
```

## Git Repository

```text
FINANCE_DEMO_DB.GOLD.JIRA_BUG_INVESTIGATION_REPO
```

The repository is connected to:

```text
https://github.com/rnemani-ai/jira-bug-investigation-snowflake-mcp.git
```

The repository was fetched successfully.

A Snowflake Git workspace was also created for the project.

---

# 15. Cortex Agent

The principal Agent is:

```text
FINANCE_DEMO_DB.GOLD.FINANCE_JIRA_AGENT
```

The current published version used by the completed POC is:

```text
Version 4
```

The Agent connects to:

```text
FINANCE_DEMO_DB.GOLD.FINANCE_ANALYTICS_MCP_SERVER

FINANCE_DEMO_DB.GOLD.ATLASSIAN_JIRA_MCP_SERVER

GITHUB_BUG_INVESTIGATION
```

This gives the Agent access to three evidence domains:

```text
Jira
Snowflake
GitHub
```

---

# 16. Agent Orchestration

The Agent follows a staged investigation process.

## Step 1 — Retrieve Jira

Given an issue key such as:

```text
FSP-8
```

retrieve the issue and inspect its documented details.

---

## Step 2 — Establish the Reported Problem

Extract:

- issue summary
- description
- reproduction steps
- expected result
- actual result
- acceptance criteria
- comments
- priority
- labels

These are treated as reported/documented evidence.

---

## Step 3 — Check Snowflake Runtime

Inspect the relevant objects:

```text
BRONZE.SALES
BRONZE.PAYMENTS
SILVER.FACT_SALES
GOLD.VW_SALES_KPI
```

Determine whether the required data exists.

---

## Step 4 — Determine Grain

The Agent compares:

```text
SALES
ORDER_ITEM_ID grain

PAYMENTS
PAYMENT_ID grain

FACT_SALES
ORDER_ITEM_ID grain

GOLD
business-facing aggregation
```

Grain analysis is mandatory for FSP-8-style investigations.

---

## Step 5 — Inspect GitHub

Inspect relevant repository implementation.

For FSP-8, the critical transformation was:

```text
00_setup/01_create_silver_layer.sql
```

The Agent found that the implementation aggregates successful payments by:

```text
ORDER_ID
```

before joining payment information to item-grain sales.

---

## Step 6 — Reconcile Sources

The Agent compares:

```text
Jira claim
Snowflake runtime
GitHub implementation
GitHub test data
```

Conflicts must be surfaced.

---

## Step 7 — Determine RCA Classification

The Agent uses one of:

```text
Confirmed Root Cause
Documented Root Cause — Not Reproducible
Likely Root Cause
Root Cause Not Yet Determined
```

The classification depends on the available evidence.

---

## Step 8 — Determine Business Impact

The Agent classifies impact as:

```text
Measured
Estimated
Documented
Not Quantifiable with Current Data
```

The Agent must not invent financial impact.

---

## Step 9 — Propose Resolution

For the FSP-8 pattern, the safe technical resolution is:

```text
Aggregate successful payments to one row per ORDER_ID
before joining to item-grain sales.
```

The fact table remains:

```text
ORDER_ITEM_ID
```

grain.

---

## Step 10 — Regression Guidance

The Agent proposes tests such as:

- grain validation
- source-to-target reconciliation
- Gold-to-Silver reconciliation
- split-payment behavior
- duplicate detection

---

## Step 11 — Jira Action Boundary

If a Jira update is requested, the Agent must first show the exact proposed change.

It must not automatically post the change.

The required interaction is:

```text
This comment has NOT been posted to Jira.

Would you like me to post this comment to Jira?
```

The human must explicitly approve the action.

---

# 17. Investigation Skill Architecture

The reusable skill is:

```text
jira-bug-investigation
```

The skill provides behavioral rules to the Agent.

Major skill areas include:

```text
Evidence integrity
Jira retrieval
Snowflake investigation
Data availability
Grain validation
Join validation
Transformation analysis
Schema vs runtime
RCA classification
Business impact
Regression testing
Conflict handling
Evidence/citations
Jira approval
Final response structure
```

The skill is not a separate data source.

It defines **how the Agent should reason about and present the evidence it retrieves from the connected systems**.

---

# 18. Schema Evidence vs Runtime Evidence

A critical implementation rule is:

```text
Schema evidence
        ≠
Runtime evidence
```

For example, if:

```text
SUCCESSFUL_PAYMENT_COUNT
SUCCESSFUL_PAYMENT_AMOUNT
PAYMENT_PATTERN
```

exist in `FACT_SALES`, that proves the schema supports the required concept.

It does not prove:

```text
the transformation is currently producing correct values
```

To confirm runtime behavior, populated data and runtime validation are required.

---

# 19. RBAC Architecture

The investigation role is:

```text
FINANCE_AGENT_ROLE
```

The role provides access required by the Agent.

Conceptually:

```text
FINANCE_AGENT_ROLE
        │
        ├── Warehouse USAGE
        │
        ├── Database USAGE
        │
        ├── BRONZE/SILVER schema access
        │
        ├── Required table SELECT
        │
        ├── GOLD schema access
        │
        ├── Gold view SELECT
        │
        ├── Semantic View access
        │
        ├── Snowflake MCP access
        │
        ├── External MCP access
        │
        ├── Jira integration access
        │
        └── Cortex Agent access
```

The investigation workload is designed to be read-only.

---

# 20. Read-Only Investigation Controls

The Agent instructions explicitly prohibit data-changing SQL during investigation.

Disallowed operations include:

```text
INSERT
UPDATE
DELETE
MERGE
CREATE
ALTER
DROP
TRUNCATE
```

The investigation is restricted to operations such as:

```text
SELECT
SHOW
DESCRIBE
```

The objective is to prevent the investigation Agent from changing the data platform while analyzing a defect.

---

# 21. Jira Write Governance

The Agent also cannot silently modify Jira.

The intended workflow is:

```text
Investigate
   ↓
Prepare proposed comment
   ↓
Show exact text
   ↓
Human approval
   ↓
Post only after approval
```

This is an important distinction between:

```text
AI-assisted investigation
```

and:

```text
autonomous enterprise action
```

---

# 22. Persona Architecture

Three personas are implemented.

```text
                   FINANCE_JIRA_AGENT
                           │
          ┌────────────────┼────────────────┐
          │                │                │
          ▼                ▼                ▼
   Data Engineer     Finance Analyst   Engineering Manager
          │                │                │
          ▼                ▼                ▼
Technical evidence    KPI/business       RCA/risk/
grain/joins/tests     interpretation     next steps
```

The underlying investigation remains the same.

Only the response emphasis changes.

---

# 23. Configuration-as-Code Direction

The project keeps major implementation artifacts in the repository.

Examples include:

```text
00_setup/
01_mcp_and_agent/
JIRA_work_items/
skills/
cleanup/
README.md
```

This provides a reproducible project structure rather than keeping the entire implementation only inside the UI.

The repository therefore acts as the engineering record for:

- setup
- configuration
- Agent-related artifacts
- skills
- Jira work items
- cleanup

---

# 24. Cost-Aware Technical Design

The POC was intentionally designed for a Snowflake trial environment.

The implementation therefore favors:

- small datasets
- lightweight validation
- targeted queries
- read-only investigation
- warehouse auto-suspend
- avoiding unnecessary full-corpus processing
- representative evaluation instead of excessive Agent executions

The project did not require:

```text
RAG
Vector Database
Embeddings
Large-scale corpus processing
Multi-agent orchestration
```

This keeps the architecture focused and reduces unnecessary compute.

---

# 25. Important Architecture Boundaries

The following statements describe the current implementation accurately.

### Implemented

```text
Jira MCP
Snowflake MCP
GitHub MCP
Cortex Agent
Semantic View
Snowflake Git
GitHub App
Reusable skill
Personas
RBAC
Evaluation
```

### Not established by the current runtime

```text
End-to-end FSP-8 reproduction in populated Snowflake sales data
Runtime validation of the proposed transformation fix
```

### Not implemented

```text
Automatic Jira posting
dbt integration
ServiceNow integration
Slack/Teams integration
Confluence evidence workflow
RAG/vector database
Multi-agent orchestration
```

---

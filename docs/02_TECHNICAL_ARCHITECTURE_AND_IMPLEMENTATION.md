# Technical Architecture and Implementation

## 1. Document Purpose

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

# 2. High-Level Architecture

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

# 3. Snowflake Platform Architecture

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

# 4. Bronze Layer

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

# 5. Silver Layer

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

# 6. Payment Aggregation Pattern

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

# 7. Gold Layer

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

# 8. Semantic View

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

# 9. Snowflake MCP Architecture

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

# 10. Atlassian Jira MCP

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

# 11. Jira Evidence Model

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

# 12. GitHub Integration Architecture

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

# 13. GitHub App

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

# 14. GitHub MCP Connector

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

# 15. Snowflake Git Integration

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

# 16. Repository Structure

The repository is organized approximately as:

```text
jira-bug-investigation-snowflake-mcp/
│
├── README.md
│
├── cleanup/
│
├── JIRA_work_items/
│
├── 00_setup/
│
├── 01_mcp_and_agent/
│
└── skills/
    └── jira-bug-investigation/
        └── SKILL.md
```

Snowflake-managed skill content appears under:

```text
.snowflake/
└── si/
    └── skills/
```

The `.snowflake` directory is managed by the Snowflake environment and should not be treated as an ordinary project directory for manual cleanup.

---

# 17. Cortex Agent

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

# 18. Agent Orchestration

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

# 19. Investigation Skill Architecture

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

# 20. Evidence Classification

The investigation skill defines several evidence states.

## Confirmed

Supported by actual evidence available to the Agent.

Example:

```text
Snowflake query returned the observed row count.
```

---

## Documented

Reported by an external system such as Jira but not independently validated.

Example:

```text
Jira reports that revenue is duplicated.
```

---

## Likely

A technically supported interpretation that still lacks sufficient evidence for confirmation.

---

## Unverified

A claim for which sufficient supporting evidence has not been established.

---

## Illustrative

An example used for explanation rather than evidence.

The Agent must never present illustrative values as observed runtime data.

---

## Blocked

The required evidence is unavailable.

Example:

```text
SALES is empty.
FACT_SALES is empty.
Therefore runtime reproduction is blocked.
```

---

# 21. Schema Evidence vs Runtime Evidence

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

# 22. FSP-8 Technical Investigation

The representative Jira issue is:

```text
FSP-8
Revenue is duplicated for split-payment orders
```

Priority:

```text
Highest
```

Label:

```text
duplicate-revenue
```

Affected objects:

```text
FINANCE_DEMO_DB.BRONZE.SALES
FINANCE_DEMO_DB.BRONZE.PAYMENTS
FINANCE_DEMO_DB.SILVER.FACT_SALES
FINANCE_DEMO_DB.GOLD.VW_SALES_KPI
```

---

# 23. FSP-8 Grain Problem

The reported problematic join is conceptually:

```sql
FACT_SALES
JOIN PAYMENTS
  ON ORDER_ID
```

If an order contains:

```text
2 sales items
2 successful payments
```

the join can produce:

```text
2 × 2 = 4 rows
```

instead of:

```text
2 rows
```

For Order 1001, the issue description reports:

```text
2 sales rows
2 successful payments
4 joined rows
```

For Order 1004, it reports:

```text
2 sales rows
3 successful payments
6 joined rows
```

This is the many-to-many multiplication pattern.

---

# 24. GitHub Implementation Finding

The repository implementation provides a safer pattern.

Conceptually:

```text
PAYMENTS
   │
   ├── filter PAYMENT_STATUS = SUCCESS
   │
   ▼
PAYMENT_SUMMARY
GROUP BY ORDER_ID
   │
   ▼
one payment summary row/order
   │
   ▼
SALES
ORDER_ITEM_ID grain
```

The final join therefore becomes:

```text
ORDER_ITEM_ID rows
       +
one payment summary row per ORDER_ID
```

rather than a direct payment-level many-to-many join.

This supports:

```text
FACT_SALES remains at ORDER_ITEM_ID grain.
```

---

# 25. GitHub Test Data

The repository test data supports:

```text
Order 1001:
2 items
2 payments

Order 1004:
2 items
3 payments
```

This corroborates the multiplication pattern described in the Jira issue.

However, this repository data is **supporting implementation/test evidence**, not current Snowflake runtime evidence.

---

# 26. Current Snowflake Runtime Boundary

At the investigated runtime state:

```text
BRONZE.SALES          = 0 rows
BRONZE.PAYMENTS       = 8 rows
SILVER.FACT_SALES     = 0 rows
GOLD.VW_SALES_KPI     = 0 rows
```

Therefore:

```text
PAYMENTS
```

contains actual current Snowflake records, including split-payment patterns.

However:

```text
SALES
FACT_SALES
GOLD.VW_SALES_KPI
```

are empty.

Consequently, the full reported revenue duplication cannot be reproduced end-to-end using the current populated Snowflake runtime.

The Agent must report:

```text
Runtime validation blocked.
```

It must not simulate sales rows to manufacture a runtime result.

---

# 27. Order 1004 Conflict

The investigation found different descriptions of Order 1004.

The Jira issue description states:

```text
2 sales rows
3 successful payments
```

A Jira comment contains a different item count.

The GitHub test data supports:

```text
2 items
3 payments
```

The current Snowflake sales table cannot resolve the conflict because:

```text
BRONZE.SALES = 0 rows
```

The correct Agent behavior is to explicitly identify the conflict and preserve the evidence boundary.

---

# 28. RCA Interpretation

The implementation evidence supports the technical mechanism:

```text
Direct item-grain sales to payment-grain joining
can create many-to-many row multiplication.
```

The GitHub implementation also contains a payment aggregation approach intended to prevent this multiplication.

However, because the current Snowflake sales/fact/gold runtime data is empty, the completed investigation does not claim that the current deployed runtime has independently passed the FSP-8 reproduction and fix validation.

This is an intentional evidence boundary.

---

# 29. Fix Status Model

The Agent uses explicit fix-status language.

## Schema Support Confirmed

Use when supporting columns/objects exist.

```text
The schema supports the required payment aggregation.
```

This does not prove runtime correctness.

---

## Fix Logic Confirmed in Transformation

Use when the relevant transformation SQL has been inspected and contains the expected fix pattern.

For FSP-8:

```text
Payment data is aggregated by ORDER_ID before joining to sales.
```

---

## Runtime Behavior Validated

Use only when populated target data passes the relevant runtime checks.

This was **not established for the current empty sales/fact/gold runtime**.

---

## Deployment Documented

Use when a trusted source explicitly documents deployment.

It should not be confused with independent runtime validation.

---

# 30. RBAC Architecture

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

# 31. Read-Only Investigation Controls

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

# 32. Jira Write Governance

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

# 33. Persona Architecture

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

# 34. End-to-End Data and Evidence Flow

The complete flow is:

```text
                    User Question
                         │
                         ▼
                   Cortex Agent
                         │
              ┌──────────┼──────────┐
              ▼          ▼          ▼
            Jira      Snowflake   GitHub
             MCP         MCP       MCP
              │           │          │
              ▼           ▼          ▼
          Documented    Runtime   Implementation
           evidence     evidence    evidence
              │           │          │
              └───────────┼──────────┘
                          ▼
                 Evidence Reconciliation
                          │
             ┌────────────┼────────────┐
             ▼            ▼            ▼
            Grain       Conflict       Data
           Analysis     Analysis     Availability
             │            │            │
             └────────────┼────────────┘
                          ▼
                     RCA Class
                          │
                          ▼
                  Business Impact
                          │
                          ▼
                 Resolution Guidance
                          │
                          ▼
                 Regression Guidance
                          │
                          ▼
               Proposed Jira Comment
                          │
                          ▼
                   Human Approval
```

---

# 35. Configuration-as-Code Direction

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

# 36. Cost-Aware Technical Design

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

# 37. Evaluation Architecture

The evaluation layer tests whether the Agent follows the investigation rules.

The scenarios cover areas such as:

```text
Jira retrieval
GitHub implementation inspection
Multi-source investigation
Conflict detection
Empty-data handling
Persona behavior
```

The completed representative evaluation run produced:

```text
6 executed
6 passed
```

The evaluation was intentionally stopped after the core POC behavior was sufficiently demonstrated.

---

# 38. Important Architecture Boundaries

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

# 39. Technical Design Principles

## Principle 1 — Evidence Before Conclusions

The Agent must gather evidence before assigning RCA.

---

## Principle 2 — Source-Specific Trust

Different systems provide different types of evidence.

```text
Jira      → documented business context
Snowflake → runtime/data evidence
GitHub    → implementation evidence
```

---

## Principle 3 — Grain First

For data-quality investigations, determine table grain before reasoning about aggregation correctness.

---

## Principle 4 — No Fabricated Runtime Evidence

Empty data must remain empty in the analysis.

---

## Principle 5 — Schema Is Not Behavior

Columns and objects show capability, not runtime correctness.

---

## Principle 6 — Conflicts Are Evidence

Conflicting source statements should be surfaced rather than silently resolved.

---

## Principle 7 — Read-Only by Default

Investigation should not modify the data platform.

---

## Principle 8 — Human Approval for External Actions

The Agent can prepare a Jira update but requires explicit human approval before posting it.

---

## Principle 9 — Persona Does Not Change Facts

Presentation may change, but evidence classification and RCA should remain consistent.

---

# 40. Technical Outcome

The completed architecture establishes a practical Snowflake-native pattern:

```text
Enterprise Issue
      ↓
Jira MCP
      ↓
Cortex Agent
      ↓
Snowflake MCP ──────────────┐
      │                     │
      ▼                     │
Runtime Investigation       │
                            │
GitHub MCP ────────────────┤
      │                     │
      ▼                     │
Implementation Evidence     │
                            ▼
                    Evidence Reconciliation
                            │
                            ▼
                       RCA / Impact
                            │
                            ▼
                    Regression Guidance
                            │
                            ▼
                     Human Approval
```

The architecture demonstrates that MCP is being used as an **enterprise tool-access layer**, while Snowflake remains the data and analytical foundation.

The Cortex Agent provides orchestration, and the investigation skill provides behavioral governance.

The resulting system is therefore more accurately described as:

> **A governed, evidence-driven data-quality investigation workflow implemented on Snowflake Cortex Agent and MCP.**

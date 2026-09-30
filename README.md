# Jira Bug Investigation with Snowflake MCP

## Enterprise Data Quality Investigation Framework

An evidence-based data-quality investigation POC built with **Snowflake Cortex / CoCo**, **Cortex Agent**, **MCP integrations**, **Jira**, **GitHub**, Snowflake data layers, reusable investigation skills, RBAC, and a lightweight evaluation framework.

The project investigates a finance data-quality scenario in which revenue can be duplicated for split-payment orders. The objective is not simply to generate an answer, but to connect **business context, runtime data, implementation evidence, and explicit investigation rules** and then clearly distinguish what is confirmed, documented, likely, unverified, or blocked.

> **Reference / inspiration:** This project was inspired by the `deept-agl/Jira_Bug_Analysis_MCP_to_Snowflake` approach. The implementation in this repository was built around the project's own Snowflake environment, Jira MCP connection, GitHub MCP integration, Cortex Agent, reusable skill, governance controls, and evaluation scenarios.

---

# 1. Project at a Glance

## Problem

Finance users reported:

> **Revenue is duplicated for split-payment orders.**

The reported issue involves an item-grain sales dataset joined to payment-grain data on `ORDER_ID`. When an order has multiple successful payments, a direct join can create a many-to-many relationship and multiply revenue.

## What was built

```text
Jira Issue
    ↓
Cortex Agent / CoCo
    ↓
Jira MCP ────────────────┐
Snowflake MCP ───────────┼──→ Evidence-based investigation
GitHub MCP ──────────────┘
    ↓
Evidence classification
    ↓
Root-cause classification
    ↓
Business-impact classification
    ↓
Read-only resolution pattern
    ↓
Regression tests / limitations
```

## Completed POC result

**6 / 6 executed evaluations passed.**

The completed evaluations covered materially different behaviors:

- Jira issue retrieval
- GitHub transformation/code analysis
- Full multi-source investigation
- Conflicting-evidence reconciliation
- Empty-runtime handling
- Data Engineer persona behavior

---

# 2. What This Project Demonstrates

The POC brings together three primary evidence domains:

| Evidence source | Investigation role |
|---|---|
| **Jira MCP** | Business context and documented issue evidence |
| **Snowflake MCP** | Runtime data, schema, grain, joins, reconciliation and SQL investigation |
| **GitHub MCP** | Transformation SQL, repository context, test-data definitions and implementation evidence |

The **Snowflake Cortex Agent** orchestrates the investigation and applies reusable investigation guidance.

The resulting workflow can answer:

- What was reported?
- What does the current Snowflake runtime actually contain?
- What does the implementation code do?
- Are the sources consistent?
- Can the issue currently be reproduced?
- What root-cause classification is supported?
- What business impact can actually be supported?
- What resolution pattern is appropriate?
- What regression tests should be used?
- What remains unverified?

The key design principle is:

> **Do not force the Agent to produce a confident answer when the available evidence does not support one.**

---

# 3. Business Scenario

## Jira Project

**Financial Sales Project**

## Jira Issue

**FSP-8 — Revenue is duplicated for split-payment orders**

Priority: **Highest**

Status: **To Do**

Label: `duplicate-revenue`

### Documented scenario

Finance users reported that revenue is overstated for orders completed using multiple successful payment methods, while single-payment orders appear correct.

Affected objects:

```text
FINANCE_DEMO_DB.BRONZE.SALES
FINANCE_DEMO_DB.BRONZE.PAYMENTS
FINANCE_DEMO_DB.SILVER.FACT_SALES
FINANCE_DEMO_DB.GOLD.VW_SALES_KPI
```

The Jira acceptance criteria included:

1. Aggregate payments to one row per `ORDER_ID` before joining.
2. Preserve `FACT_SALES` at `ORDER_ITEM_ID` grain.
3. Ensure Gold revenue matches Silver revenue.
4. Ensure split-payment orders do not duplicate revenue.

---

# 4. High-Level Architecture

```text
                         ┌─────────────────────────┐
                         │       User / CoCo       │
                         │ Natural-language query  │
                         └────────────┬────────────┘
                                      │
                                      ▼
                         ┌─────────────────────────┐
                         │ Snowflake Cortex Agent   │
                         │     FINANCE_JIRA_AGENT  │
                         │                         │
                         │ • orchestration         │
                         │ • investigation skill   │
                         │ • evidence rules        │
                         │ • RCA / impact          │
                         │ • response generation   │
                         └──────┬──────┬──────┬────┘
                                │      │      │
                  ┌─────────────┘      │      └─────────────┐
                  ▼                    ▼                    ▼
          ┌───────────────┐    ┌───────────────┐   ┌───────────────┐
          │    Jira MCP   │    │ Snowflake MCP │   │  GitHub MCP   │
          │               │    │               │   │               │
          │ Issue context │    │ Runtime data  │   │ SQL / code    │
          │ Expected      │    │ Grain / joins │   │ Test data     │
          │ Actual        │    │ SQL analysis   │   │ Commits       │
          │ Acceptance    │    │ Semantic View │   │ Repo context  │
          └───────────────┘    └───────┬───────┘   └───────────────┘
                                        │
                                        ▼
                              ┌────────────────────┐
                              │ Snowflake Platform │
                              │                    │
                              │ Bronze → Silver    │
                              │        → Gold      │
                              └────────────────────┘
```

---

# 5. Snowflake Foundation

## Database

```text
FINANCE_DEMO_DB
```

## Schemas

```text
BRONZE
SILVER
GOLD
```

## Warehouse

```text
FINANCE_DEMO_WH
```

The POC was intentionally designed with a small dataset and controlled compute usage because it was built in a Snowflake trial environment.

The investigation favored:

- Small data volumes
- Lightweight validation
- Read-only queries
- Warehouse auto-suspend / controlled compute
- Avoiding unnecessary full-corpus processing

---

# 6. Bronze → Silver → Gold

## Bronze

Objects include:

```text
BRONZE.SALES
BRONZE.PAYMENTS
BRONZE.PRODUCTS
BRONZE.CUSTOMERS
```

Relevant grains:

```text
SALES    → ORDER_ITEM_ID / item grain
PAYMENTS → PAYMENT_ID / payment grain
```

## Silver

Objects include:

```text
SILVER.FACT_SALES
SILVER.DIM_PRODUCT
SILVER.DIM_CUSTOMER
SILVER.DIM_DATE
```

`FACT_SALES` is intended to remain at:

```text
ORDER_ITEM_ID grain
```

Payment-related fields in the fact design include:

```text
SUCCESSFUL_PAYMENT_COUNT
SUCCESSFUL_PAYMENT_AMOUNT
PAYMENT_METHODS
PAYMENT_PATTERN
```

## Gold

Primary analytical view:

```text
FINANCE_DEMO_DB.GOLD.VW_SALES_KPI
```

The Gold layer provides business KPI information including revenue, orders, customers, sales channel, product category, and payment-pattern information.

---

# 7. Semantic View and Cortex Analyst

The project created:

```text
FINANCE_DEMO_DB.GOLD.FINANCE_SALES_SEMANTIC_VIEW
```

The Semantic View provides business-level context for Cortex Analyst queries.

The POC explicitly tested the Semantic View path through the Agent.

Because the current sales/fact runtime tables were empty during the test, the Semantic View query correctly returned no business rows rather than inventing results.

---

# 8. Snowflake MCP

The internal Snowflake MCP server is:

```text
FINANCE_DEMO_DB.GOLD.FINANCE_ANALYTICS_MCP_SERVER
```

It exposes:

### Finance Sales Analyst

A Cortex Analyst tool connected to:

```text
FINANCE_DEMO_DB.GOLD.FINANCE_SALES_SEMANTIC_VIEW
```

Used for business-level KPI questions.

### Execute Finance SQL

A read-only SQL investigation capability used for:

- Data availability
- Schema inspection
- Grain analysis
- Duplicate detection
- Source-to-target reconciliation
- Join analysis
- Detailed investigation

The Agent was explicitly instructed not to perform destructive or data-changing SQL during investigation.

---

# 9. Jira / Atlassian MCP

The external Atlassian MCP connection is represented in Snowflake as:

```text
FINANCE_DEMO_DB.GOLD.ATLASSIAN_JIRA_MCP_SERVER
```

The authenticated connection was used to retrieve Jira issue evidence.

The Agent can use:

- Issue summary
- Description
- Reproduction steps
- Expected result
- Actual result
- Comments
- Labels
- Priority
- Acceptance criteria
- Linked issues

### Important scope clarification

The project used the **Atlassian MCP connection for Jira investigation**.

**Confluence was not used as an evidence source in the completed FSP-8 investigation.**

The documentation therefore distinguishes actual demonstrated Jira usage from capabilities that were not used in the completed investigation.

---

# 10. GitHub Integration

The project repository is:

```text
rnemani-ai/jira-bug-investigation-snowflake-mcp
```

The repository was kept **private**.

## GitHub App

A dedicated GitHub App was created:

```text
Snowflake Jira Bug Investigation
```

The App was installed only on the POC repository.

Repository access was intentionally scoped to the required read-oriented capabilities, including:

- Contents
- Metadata
- Pull requests
- Issues

The purpose was to allow the GitHub MCP connector to inspect implementation evidence without opening unrestricted repository access.

---

# 11. Snowflake Git Integration

Snowflake source-control integration was also configured.

Objects include:

```text
FINANCE_DEMO_DB.GOLD.GITHUB_JIRA_POC_SECRET

FINANCE_DEMO_DB.GOLD.GITHUB_JIRA_POC_API

FINANCE_DEMO_DB.GOLD.JIRA_BUG_INVESTIGATION_REPO
```

The repository was fetched into the Snowflake Git integration and a Snowflake Git workspace was created for the project.

This gave the project two complementary repository workflows:

```text
Snowflake Git / Workspace
        +
GitHub MCP
        ↓
Implementation evidence
```

---

# 12. GitHub MCP

The GitHub MCP connector was configured in Snowflake and attached to the Cortex Agent.

The Agent can inspect the private repository for:

- Transformation SQL
- Repository structure
- Test-data definitions
- Agent configuration
- Commit history
- Implementation context

This became especially important when Snowflake runtime data was unavailable.

---

# 13. Cortex CoCo Environment

The project used **Snowflake Cortex / CoCo through the browser/web interface** to configure and test the Agent and MCP connections.

The implementation workflow included:

```text
CoCo
 ↓
Agent configuration
 ↓
MCP connector configuration
 ↓
Skill configuration
 ↓
Agent testing
 ↓
Versioned Agent behavior
 ↓
Evaluation
```

The completed project therefore was not only SQL configuration; it included the interactive CoCo workflow used to connect and test the Agent capabilities.

---

# 14. CoWork Skill Development

A reusable CoWork skill was created and uploaded through the CoWork capability workflow.

The skill was created under:

```text
jira-bug-investigation/
└── SKILL.md
```

The CoWork workflow used:

```text
CoWork
 → Capabilities
 → Skills
 → Create / Upload
 → jira-bug-investigation
```

The skill encoded the investigation behavior rather than relying only on a prompt.

The Agent-specific version was then packaged for use by the Cortex Agent.

---

# 15. Investigation Skill

The reusable skill covers:

## Evidence integrity

```text
Confirmed
Documented
Likely
Unverified
Illustrative
```

## Root-cause classification

```text
Confirmed Root Cause
Documented Root Cause — Not Reproducible
Likely Root Cause
Root Cause Not Yet Determined
```

## Business-impact classification

```text
Measured
Estimated
Documented
Not Quantifiable with Current Data
```

## Technical investigation rules

- Determine data grain
- Validate join cardinality
- Inspect transformations
- Reconcile source and target layers
- Distinguish schema evidence from runtime evidence
- Never simulate missing data
- Never invent business logic
- Surface conflicting evidence
- Generate regression tests
- Preserve limitations

---

# 16. Cortex Agent Evolution

The Agent was iteratively improved rather than configured once.

### Version 2

The investigation skill was attached and tested.

### Version 3

Persona behavior was added.

### Version 4

Evidence and citation behavior was strengthened, including:

- Source identification
- Confirmed vs documented distinction
- Runtime vs schema distinction
- Conflict handling
- Fix-status language
- Persona behavior
- Structured investigation response
- Jira write approval

The completed evaluation runs used **Version 4**.

---

# 17. Agent Configuration

Agent:

```text
FINANCE_DEMO_DB.GOLD.FINANCE_JIRA_AGENT
```

MCP servers attached:

```text
FINANCE_DEMO_DB.GOLD.FINANCE_ANALYTICS_MCP_SERVER

FINANCE_DEMO_DB.GOLD.ATLASSIAN_JIRA_MCP_SERVER

GITHUB_BUG_INVESTIGATION
```

The Agent was instructed to:

1. Retrieve the Jira issue.
2. Understand the documented scenario.
3. Inspect Snowflake runtime data.
4. Determine data grain.
5. Inspect GitHub implementation evidence.
6. Reconcile conflicting sources.
7. Determine reproducibility.
8. Classify root cause.
9. Classify business impact.
10. Provide a read-only resolution pattern.
11. Provide regression tests.
12. Preserve limitations.
13. Never modify Jira without explicit approval.

---

# 18. Personas

The Agent supports different presentation perspectives without changing the underlying evidence.

## Default / Investigator

Focus:

- End-to-end investigation
- Evidence synthesis
- Root cause
- Business impact
- Limitations

## Data Engineer

Focus:

- Data models
- Grain
- SQL
- Joins
- Transformations
- Source-to-target flow
- Regression tests

## Finance Analyst

Focus:

- Revenue
- Orders
- KPIs
- Reconciliation
- Business impact

## Engineering Manager

Focus:

- Severity
- Business risk
- Root-cause status
- Remediation
- Validation status
- Dependencies
- Next actions

**Persona changes presentation and emphasis, not the underlying evidence or classification.**

---

# 19. End-to-End FSP-8 Investigation

The demonstrated investigation followed this pattern:

```text
User
 │
 │ "Investigate FSP-8"
 ▼
CoCo / Cortex Agent
 │
 ├── Jira MCP
 │      └── Issue details / expected / actual / acceptance
 │
 ├── GitHub MCP
 │      └── Transformation SQL / test data / repository evidence
 │
 └── Snowflake MCP
        ├── Bronze
        ├── Silver
        ├── Gold
        ├── Semantic View
        └── Runtime validation
              │
              ▼
        Evidence synthesis
              │
              ▼
        RCA + business impact
              │
              ▼
        Regression tests
              │
              ▼
        Structured response
```

---

# 20. The Technical Root Cause Pattern

The documented problem is a classic grain mismatch.

## Problem

```text
SALES
ORDER_ITEM_ID grain
        │
        │ JOIN ORDER_ID
        ▼
PAYMENTS
PAYMENT_ID grain
```

For example:

```text
2 sales items × 3 successful payments
= 6 joined rows
```

The same order can therefore cause revenue to be counted multiple times.

## Grain-safe pattern

The repository transformation inspected through GitHub uses a payment summary:

```text
PAYMENTS
   ↓
PAYMENT_SUMMARY
GROUP BY ORDER_ID
   ↓
JOIN TO SALES
   ↓
FACT_SALES
ORDER_ITEM_ID grain
```

The important implementation principle is:

> **Aggregate payment data to `ORDER_ID` before joining it to item-grain sales data.**

This preserves the intended `FACT_SALES` grain.

---

# 21. Important Evidence Boundary

The project deliberately distinguishes three different kinds of implementation status.

### Schema evidence

Columns or structures exist.

```text
Schema support confirmed
```

### Transformation evidence

The repository SQL contains the expected logic.

```text
Fix logic confirmed in the inspected transformation
```

### Runtime evidence

Populated Snowflake data passes validation.

```text
Runtime behavior validated
```

These are **not interchangeable**.

The POC explicitly avoids saying:

> “The fix is deployed and working”

merely because columns or transformation code exist.

---

# 22. Runtime Data Limitation

At the time of the completed investigation:

```text
BRONZE.SALES          = 0 rows
SILVER.FACT_SALES     = 0 rows
GOLD.VW_SALES_KPI     = 0 rows
```

`BRONZE.PAYMENTS` contained payment records.

Examples included split-payment patterns such as:

```text
Order 1001 → 2 successful payments
Order 1004 → 3 successful payments
```

Because the sales/fact runtime data was empty, the full revenue-duplication scenario could not be reproduced from the current Snowflake runtime.

The Agent correctly treated this as:

```text
Runtime validation blocked
```

It did not:

- Invent missing sales rows
- Treat GitHub INSERT statements as current Snowflake data
- Simulate a runtime result
- Claim production validation
- Invent financial impact

---

# 23. Conflicting Evidence: Order 1004

The investigation uncovered a concrete discrepancy.

| Source | Order 1004 item count | Evidence type |
|---|---:|---|
| Jira description | 2 | Documented |
| Jira comment | 3 | Documented |
| GitHub Bronze/test data | 2 | Repository evidence |
| GitHub CSV | 2 | Repository evidence |
| Current Snowflake runtime | 0 | Runtime observation |

The Agent did not silently select one number.

It explicitly reported the conflict and explained that:

- Snowflake runtime could not resolve it because the relevant sales data was empty.
- GitHub repository evidence supported the 2-item scenario.
- The Jira comment was inconsistent with the other available evidence.

This is one of the key examples of why multi-source evidence handling matters.

---

# 24. Root-Cause Classification

Based on the evidence available during the completed investigation, the Agent used:

```text
Documented Root Cause — Not Reproducible with Current Data
```

The distinction is important:

- The **many-to-many join pattern** is documented in Jira.
- The **grain-safe implementation pattern** is present in the inspected GitHub transformation.
- The **current Snowflake runtime** could not reproduce the issue because the relevant sales/fact data was empty.

Therefore, the POC did not convert implementation evidence into an unsupported runtime claim.

---

# 25. Business Impact Classification

The Agent was instructed to classify impact as:

```text
Measured
Estimated
Documented
Not Quantifiable with Current Data
```

For the completed runtime state, actual current business impact could not be independently measured because the relevant sales/fact runtime data was empty.

The Agent therefore preserved the limitation rather than inventing a financial amount.

---

# 26. Regression Testing

The Agent was instructed to generate regression checks covering applicable areas:

- FACT_SALES grain
- Source-to-target reconciliation
- Gold-to-Silver reconciliation
- Split-payment behavior
- Duplicate detection

The POC also identified an important testing-design lesson:

> A regression query must itself be valid for the target SQL engine and appropriate for the available data.

For example, a test that filters on a `SELECT` alias at the same query level may require a subquery or CTE in Snowflake.

This demonstrates that generated regression tests still require engineering review.

---

# 27. Evaluation Strategy

The evaluation was intentionally lightweight because the project was running in a Snowflake trial environment.

Rather than immediately running a large automated evaluation workload, representative tests were executed first.

The evaluation suite was captured separately as:

```text
evaluations/
├── README.md
├── test_cases.yaml
└── expected_results.md
```

The test cases were designed to evaluate different investigation behaviors rather than simply repeat the same prompt.

---

# 28. Completed Evaluation Results

| Test ID | Scenario | Focus | Result |
|---|---|---|---|
| **EVAL-001** | Jira issue retrieval | Single-source validation | **PASS** |
| **EVAL-003** | GitHub transformation | Implementation analysis | **PASS** |
| **EVAL-004** | End-to-end investigation | Multi-source integration | **PASS** |
| **EVAL-005** | Conflicting evidence | Evidence reconciliation | **PASS** |
| **EVAL-006** | Empty-data handling | Constraint validation | **PASS** |
| **EVAL-007** | Data Engineer persona | Persona-based analysis | **PASS** |

## Result

# **6 / 6 PASS**

The six tests covered:

```text
Jira retrieval
      +
GitHub code analysis
      +
End-to-end orchestration
      +
Conflict resolution
      +
Empty-runtime handling
      +
Persona behavior
```

Additional persona and Jira-write-safety scenarios were defined in the evaluation plan but were not required for the core POC demonstration.

---

# 29. What the Tests Proved

The completed tests demonstrated that the Agent can:

- Retrieve and understand Jira issues.
- Locate and analyze transformation code in GitHub.
- Use multiple MCP sources in one investigation.
- Detect conflicting evidence.
- Correctly recognize unavailable runtime data.
- Avoid fabricating missing records.
- Distinguish documented claims from runtime observations.
- Identify the many-to-many join pattern.
- Explain the grain-safe aggregation approach.
- Preserve the intended data grain.
- Produce structured technical responses.
- Adapt presentation for a Data Engineer persona.
- Maintain read-only investigation behavior.

---

# 30. What We Learned From Evaluation

The evaluation was also used to improve the Agent.

### Observation 1 — Repository evidence wording

GitHub test data should be described as:

```text
supporting / corroborating repository evidence
```

rather than automatically calling it authoritative over runtime data.

### Observation 2 — Empty-data regression behavior

Empty source tables do not automatically mean every regression test fails.

Some checks can:

- Return zero rows
- Produce a valid PASS condition
- Be blocked depending on the test design

### Observation 3 — Schema ≠ runtime validation

The existence of payment-related columns does not prove that a runtime transformation is deployed or functioning correctly.

### Observation 4 — Evidence boundaries matter

A strong investigation response should explicitly state where the evidence stops.

---

# 31. Native Capability Validation

Before the final evaluation suite, the individual capabilities were tested incrementally.

The validation journey included:

```text
Snowflake environment
        ↓
Semantic View
        ↓
Cortex Analyst
        ↓
Snowflake MCP
        ↓
Jira MCP
        ↓
Cortex Agent
        ↓
Agent + Snowflake MCP
        ↓
Agent + Jira MCP
        ↓
Agent + Jira + Snowflake
        ↓
Agent + Cortex Analyst
        ↓
GitHub MCP
        ↓
Private GitHub repository access
        ↓
Full Jira + Snowflake + GitHub investigation
        ↓
Evaluation
```

This incremental approach helped isolate integration issues before the final end-to-end test.

---

# 32. Security and Governance

## Snowflake RBAC

Role:

```text
FINANCE_AGENT_ROLE
```

Permissions were configured for the investigation environment, including appropriate:

- Warehouse USAGE
- Database USAGE
- Schema USAGE
- SELECT access
- Semantic View access
- MCP access
- Agent access

## Read-only investigation

The Agent instructions prohibit investigation-time data-changing statements such as:

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

The intended investigation path uses:

```text
SELECT
SHOW
DESCRIBE
```

## GitHub access

The private repository was accessed through a dedicated GitHub App with repository-scoped installation.

## Jira write safety

The Agent does not automatically modify Jira.

Before any Jira write:

1. Show the exact proposed comment.
2. Explicitly state that it has not been posted.
3. Ask for explicit approval.
4. Perform the write only after approval.

Required wording:

```text
This comment has NOT been posted to Jira.

Would you like me to post this comment to Jira?
```

---

# 33. CoWork vs Cortex Agent Skill

The project involved both the **CoWork skill workflow** and the **Cortex Agent skill configuration**.

The distinction is:

```text
CoWork
  ↓
Create / upload reusable skill
  ↓
jira-bug-investigation
  ↓
Agent-specific skill package
  ↓
Cortex Agent
  ↓
Agent Version 4
```

The skill is not merely documentation; it encodes operational investigation behavior, evidence boundaries, safety constraints, classifications, and response structure.

---

# 34. Repository Structure

```text
jira-bug-investigation-snowflake-mcp/
│
├── README.md
│
├── 00_setup/
│   ├── Snowflake environment
│   ├── Bronze / Silver / Gold
│   ├── Semantic View
│   └── supporting setup SQL
│
├── 01_mcp_and_agent/
│   ├── 00_create_semantic_view.sql
│   ├── 01_create_mcp_server.sql
│   ├── 02_create_jira_mcp_connection.sql
│   ├── 03_create_cortex_agent.sql
│   ├── 04_RBAC.sql
│   ├── 05_create_github_api_integration.sql
│   └── 06_create_github_repository.sql
│
├── JIRA_work_items/
│
├── evaluations/
│   ├── README.md
│   ├── test_cases.yaml
│   └── expected_results.md
│
├── skills/
│   └── jira-bug-investigation/
│       └── SKILL.md
│
└── cleanup/
```

### Snowflake-managed CoCo area

The Snowflake-managed `.snowflake/` area contains CoCo/skill-related content and is separate from the Git-tracked project structure.

Example:

```text
.snowflake/
└── si/
    └── skills/
        ├── jira-bug-investigation
        ├── jira-bug-investigation-v2
        └── jira-bug-investigation-v3
```

This area should not be treated as ordinary application source code or moved into the Git project simply to make the repository look cleaner.

---

# 35. Key Snowflake Objects

| Object | Purpose |
|---|---|
| `FINANCE_DEMO_DB.GOLD.FINANCE_SALES_SEMANTIC_VIEW` | Business semantic context |
| `FINANCE_DEMO_DB.GOLD.FINANCE_ANALYTICS_MCP_SERVER` | Snowflake MCP |
| `FINANCE_DEMO_DB.GOLD.ATLASSIAN_JIRA_MCP_SERVER` | Jira / Atlassian MCP |
| `FINANCE_DEMO_DB.GOLD.FINANCE_JIRA_AGENT` | Cortex investigation Agent |
| `FINANCE_DEMO_DB.GOLD.GITHUB_JIRA_POC_SECRET` | Git credentials / integration |
| `FINANCE_DEMO_DB.GOLD.GITHUB_JIRA_POC_API` | GitHub API integration |
| `FINANCE_DEMO_DB.GOLD.JIRA_BUG_INVESTIGATION_REPO` | Snowflake Git repository |
| `FINANCE_DEMO_DB.GOLD.VW_SALES_KPI` | Gold business KPI view |
| `SILVER.FACT_SALES` | Item-grain fact layer |

---

# 36. Project Files and Configuration as Code

Important implementation files include:

```text
00_create_semantic_view.sql
01_create_mcp_server.sql
02_create_jira_mcp_connection.sql
03_create_cortex_agent.sql
04_RBAC.sql
05_create_github_api_integration.sql
06_create_github_repository.sql
```

The repository also captures:

- Jira work items
- Evaluation cases
- Expected results
- Investigation skill
- Cleanup scripts
- README / project documentation

This allows the project to be reconstructed and discussed without relying exclusively on a live CoCo session.

---

# 37. Cost-Aware POC Design

Because the project was developed in a Snowflake trial environment, cost awareness was part of the engineering approach.

The project favored:

- Small test datasets
- Targeted queries
- Read-only investigation
- Lightweight evaluation
- Controlled warehouse usage
- Avoiding unnecessary full-corpus processing
- Avoiding RAG/vector infrastructure where it was not required

The POC deliberately did **not** introduce:

- Vector databases
- Embeddings
- LangChain
- Multi-agent orchestration
- Complex long-term memory
- Large-scale RAG pipelines

The investigation problem could be addressed using the systems and data already available.

---

# 38. What Was Not Implemented

To keep the architecture accurate, the following should **not** be represented as completed capabilities:

- No measured 70% MTTR reduction
- No production deployment claim
- No production runtime validation of the fix
- No demonstrated Confluence evidence workflow
- No vector database / embeddings
- No RAG pipeline
- No LangChain orchestration
- No multi-agent architecture
- No autonomous Jira modification
- No compliance certification
- No fabricated financial-impact measurement
- No claim that repository test data is equivalent to production runtime data

These may be future extensions where appropriate, but they are not presented as completed functionality.

---

# 39. Current POC Boundaries

The most important limitation is:

```text
Current Snowflake sales/fact runtime data is empty.
```

Therefore:

```text
Implementation evidence
        ≠
Runtime validation
        ≠
Production validation
```

The POC demonstrates the **investigation framework and reasoning behavior**, including how the Agent handles missing runtime evidence.

It does not claim that the current Snowflake environment represents a production deployment.

---

# 40. Why the Architecture Is Useful

The framework addresses a common investigation problem:

```text
Business ticket
      +
Data warehouse
      +
Transformation code
      +
Conflicting evidence
      +
Access controls
      +
Human approval
```

Instead of forcing an investigator to manually move among these systems, the Cortex Agent provides a controlled orchestration layer.

The Agent is responsible for:

```text
Retrieve
   ↓
Inspect
   ↓
Compare
   ↓
Validate
   ↓
Classify
   ↓
Explain
```

The underlying systems remain the sources of evidence.

---

# 41. Product / Hiring Manager Takeaway

The important capability demonstrated by this project is not simply an AI chatbot.

It is a **governed investigation workflow** that:

- Starts with a real business issue.
- Retrieves documented context from Jira.
- Checks actual Snowflake runtime data.
- Inspects implementation evidence in GitHub.
- Understands data grain and join behavior.
- Detects contradictory evidence.
- Refuses to fabricate missing runtime data.
- Classifies root cause and business impact.
- Produces regression-test guidance.
- Preserves limitations.
- Keeps investigation actions read-only.
- Requires explicit approval before Jira writes.
- Can present the same evidence for different personas.

The core design principle is:

> **Connect the business issue, runtime data, and implementation evidence—and make the Agent explain what the evidence actually supports.**

---

# 42. Technology Stack

```text
Snowflake
Snowflake Cortex / CoCo
Cortex Agent
Cortex Analyst
MCP
Jira / Atlassian MCP
GitHub MCP
GitHub App
Snowflake Git Integration
Semantic Views
SQL
RBAC
CoWork Skills
Agent Skills
Git / GitHub
```

---

# 43. Reference Architecture Summary

```text
                         USERS
                           │
                           ▼
                    ┌─────────────┐
                    │    CoCo     │
                    │ Snowflake UI│
                    └──────┬──────┘
                           │
                           ▼
              ┌─────────────────────────┐
              │   Cortex Agent          │
              │ FINANCE_JIRA_AGENT      │
              │                         │
              │ Investigation Skill     │
              │ Evidence Rules          │
              │ Personas                │
              │ RCA / Impact            │
              │ Safety Controls         │
              └───────┬───────┬─────────┘
                      │       │
             ┌────────┘       └─────────┐
             ▼                          ▼
       ┌────────────┐             ┌────────────┐
       │ MCP Layer  │             │ Snowflake  │
       │            │             │ MCP        │
       │ Jira       │             │ Analyst    │
       │ GitHub     │             │ SQL        │
       └─────┬──────┘             └──────┬─────┘
             │                           │
       ┌─────┴─────┐              ┌──────┴──────┐
       ▼           ▼              ▼             ▼
     Jira       GitHub         Bronze        Silver
    FSP-8       Private        / Raw         / Fact
                Repo              │             │
                                  └──────┬──────┘
                                         ▼
                                       Gold
                                  / Semantic View
                                         │
                                         ▼
                              Evidence-based response
```

---

# 44. Final Summary

This project demonstrates a practical **multi-source data-quality investigation framework** using Snowflake Cortex Agent and MCP.

The implementation combines:

```text
CoCo
 +
Reusable Skills
 +
Cortex Agent
 +
Jira MCP
 +
Snowflake MCP
 +
GitHub MCP
 +
GitHub App
 +
Snowflake Data Layers
 +
Semantic View / Cortex Analyst
 +
RBAC
 +
Evaluation
```

The central lesson is:

> **Don't ask AI to guess the root cause. Give it access to the business issue, runtime data, implementation evidence, and explicit evidence rules—and make it explain what the evidence actually supports.**

**Portfolio Project — 2026 | Data Engineering / AI Engineering**

Repository:

`https://github.com/rnemani-ai/jira-bug-investigation-snowflake-mcp`

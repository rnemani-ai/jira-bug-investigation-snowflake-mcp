# Project Overview and Engineering Journey

## 1. Project Overview

### Project Name

**Jira Bug Investigation with Snowflake MCP**

### Project Purpose

This project is a Snowflake-native proof of concept for investigating enterprise data-quality and analytics issues using an AI Agent connected to multiple evidence sources.

The solution brings together:

- **Snowflake** for data, analytics, runtime validation, and semantic modeling
- **Snowflake Cortex Agent** for investigation orchestration
- **MCP** for standardized access to enterprise tools and systems
- **Jira / Atlassian MCP** for business issue context
- **GitHub MCP** for implementation and repository evidence
- **Snowflake Git integration** for source-control and workspace workflows
- **CoCo** for Cortex Agent configuration and testing
- **CoWork** for reusable investigation-skill development
- **Investigation Skills** for evidence integrity, RCA, impact analysis, and governance
- **Personas** for audience-specific investigation responses
- **RBAC** for controlled access
- **Evaluation artifacts** for testing Agent behavior

The representative investigation is:

> **FSP-8 — Revenue is duplicated for split-payment orders**

The POC demonstrates how an AI Agent can investigate a data-quality issue across multiple enterprise systems while clearly separating:

- what was reported
- what was observed
- what was found in implementation
- what is supported by evidence
- what remains unverified
- what conflicts
- what cannot currently be validated

---

# 2. Why We Built This

## 2.1 The Investigation Problem

Enterprise data-quality issues are often distributed across multiple systems.

For example, a finance user may report an issue in Jira:

```text
Revenue is duplicated for split-payment orders.
```

The Jira issue may contain:

- business context
- expected behavior
- actual behavior
- reproduction steps
- acceptance criteria
- comments
- labels
- priority
- suspected root cause

However, Jira alone cannot prove whether the issue currently exists in the data platform.

The relevant runtime data may exist in Snowflake.

The transformation responsible for producing the data may exist in GitHub.

Therefore, a complete investigation may require:

```text
Jira
  ↓
Snowflake
  ↓
GitHub
  ↓
Jira
```

The engineer must manually move between systems and reconcile the information.

More importantly, manual investigation creates a risk of overstating what has actually been proven.

For example:

> Finding a SQL transformation that appears to address a bug does not prove that the deployed runtime is using that transformation.

Similarly:

> A Jira ticket reporting a defect does not independently prove that the current Snowflake environment reproduces the problem.

The POC was designed around this evidence boundary.

---

# 3. Core Project Objective

The primary objective was to demonstrate an AI-powered investigation workflow that can answer:

> **What happened, what evidence supports it, what can actually be reproduced, what does the implementation do, and what remains unverified?**

The project therefore focuses on **evidence reconciliation**, rather than simply generating a natural-language summary.

The Agent connects three primary evidence domains:

```text
                 BUSINESS CONTEXT
                       │
                       ▼
                     Jira
                       │
                       ▼
              ┌─────────────────┐
              │  Cortex Agent   │
              │  Investigation  │
              │  Orchestration  │
              └─────────────────┘
                 │      │      │
                 ▼      ▼      ▼
              Jira   Snowflake GitHub
               MCP      MCP      MCP
                 │        │       │
                 ▼        ▼       ▼
             Reported  Runtime  Implementation
              Issue     Data      Evidence
                 │        │       │
                 └────────┼───────┘
                          ▼
                 Evidence Synthesis
                          │
                          ▼
                    RCA + Impact
                          │
                          ▼
                  Bounded Conclusion
```

---

# 4. What We Wanted to Demonstrate

## 4.1 Snowflake-Native Data Investigation

Use Snowflake as the analytical and runtime evidence platform.

The project uses:

- Bronze
- Silver
- Gold
- Semantic View
- Snowflake MCP
- Cortex Agent

---

## 4.2 Multi-Source MCP Investigation

Use MCP to expose different enterprise systems to the Agent while maintaining clear evidence boundaries.

The completed POC uses:

- **Atlassian Jira MCP**
- **Snowflake Finance Analytics MCP**
- **GitHub MCP**

Each source has a distinct purpose.

| Source | Primary evidence |
|---|---|
| Jira | Reported business issue |
| Snowflake | Runtime/data evidence |
| GitHub | Implementation evidence |

The Agent does not treat these sources as interchangeable.

---

## 4.3 Evidence-Aware Reasoning

The Agent distinguishes between:

- **Confirmed**
- **Documented**
- **Likely**
- **Unverified**
- **Illustrative**
- **Blocked**
- **Conflict**

This prevents a reported hypothesis from automatically becoming a confirmed root cause.

---

## 4.4 Runtime-Aware Investigation

The Agent checks whether the required Snowflake data actually exists.

If the required tables are empty, it must explicitly state that runtime validation is blocked.

It must not create simulated rows and present them as Snowflake runtime evidence.

---

## 4.5 Code-to-Data Investigation

The POC connects:

```text
Jira business problem
        ↓
GitHub transformation
        ↓
Snowflake runtime
```

This allows the Agent to distinguish:

- reported behavior
- implementation logic
- runtime behavior

---

## 4.6 Governed Investigation

The investigation is intentionally read-only.

The Agent should not:

- change Snowflake data
- execute destructive SQL
- silently modify Jira
- claim that a fix is deployed without supporting evidence

Jira updates require explicit human approval.

---

# 5. Starting Point and Reference Project

The project was inspired by the reference implementation:

**Jira_Bug_Analysis_MCP_to_Snowflake**

Reference repository:

```text
deept-agl/Jira_Bug_Analysis_MCP_to_Snowflake
```

The reference project provided the starting architectural idea for connecting Jira-related investigation with Snowflake and MCP.

The objective of this POC was not simply to reproduce the reference project.

The project was extended into a more evidence-driven investigation workflow with:

- stronger evidence classification
- explicit runtime validation
- GitHub implementation evidence
- reusable investigation skills
- persona-based responses
- conflict detection
- Jira write governance
- regression-test guidance
- lightweight evaluation

---

# 6. Engineering Journey

The project evolved incrementally.

The major progression was:

```text
01. Snowflake Foundation
          ↓
02. Bronze → Silver → Gold
          ↓
03. Semantic View
          ↓
04. Snowflake MCP
          ↓
05. Jira MCP
          ↓
06. Cortex Agent
          ↓
07. RBAC
          ↓
08. CoCo Configuration & Testing
          ↓
09. CoWork Investigation Skill
          ↓
10. Agent Skill Refinement
          ↓
11. GitHub Integration
          ↓
12. GitHub MCP
          ↓
13. Personas
          ↓
14. Evidence & Governance Rules
          ↓
15. FSP-8 End-to-End Investigation
          ↓
16. Evaluation
```

Each stage addressed a specific capability rather than adding technology for its own sake.

---

# 7. Stage 1 — Snowflake Foundation

The first foundation was a small finance data environment.

## Database

```text
FINANCE_DEMO_DB
```

## Warehouse

```text
FINANCE_DEMO_WH
```

## Schemas

```text
BRONZE
SILVER
GOLD
```

The purpose was to create a controlled environment where the investigation Agent could inspect a realistic analytical data flow.

---

# 8. Stage 2 — Bronze, Silver and Gold

The project uses an analytical layering pattern.

## Bronze

Source-oriented tables:

```text
BRONZE.SALES
BRONZE.PAYMENTS
BRONZE.CUSTOMERS
BRONZE.PRODUCTS
```

Important grains include:

```text
SALES
→ ORDER_ITEM_ID

PAYMENTS
→ PAYMENT_ID
```

This grain distinction became central to the FSP-8 investigation.

---

## Silver

The Silver layer contains:

```text
SILVER.FACT_SALES
SILVER.DIM_CUSTOMER
SILVER.DIM_PRODUCT
SILVER.DIM_DATE
```

`FACT_SALES` is intended to remain at:

```text
ORDER_ITEM_ID
```

grain.

The payment transformation uses a payment aggregation pattern where successful payments are summarized by:

```text
ORDER_ID
```

before being joined to item-grain sales.

This prevents a direct many-to-many relationship between sales items and payment records.

---

## Gold

The Gold layer contains:

```text
GOLD.VW_SALES_KPI
```

The Gold view exposes business-level metrics and dimensions used for analytical investigation.

---

# 9. Stage 3 — Semantic View

A Semantic View was added above the Gold layer:

```text
FINANCE_DEMO_DB.GOLD.FINANCE_SALES_SEMANTIC_VIEW
```

The purpose was to provide a business-oriented semantic layer for finance analytics.

The Semantic View became the foundation for the:

```text
finance-sales-analyst
```

tool in the internal Snowflake MCP server.

This created two complementary investigation paths.

### Business-level investigation

```text
Business question
      ↓
Semantic View
      ↓
finance-sales-analyst
```

### Detailed technical investigation

```text
Technical question
      ↓
execute-finance-sql
```

---

# 10. Stage 4 — Snowflake MCP

An internal Snowflake MCP server was created:

```text
FINANCE_DEMO_DB.GOLD.FINANCE_ANALYTICS_MCP_SERVER
```

It exposes two investigation capabilities.

## `finance-sales-analyst`

Used for business-level finance and KPI analysis through the Semantic View.

## `execute-finance-sql`

Used for detailed technical investigation such as:

- data availability
- schema inspection
- grain analysis
- duplicate detection
- reconciliation
- join analysis
- detailed SQL investigation

The Agent was explicitly instructed to keep investigation SQL read-only.

---

# 11. Stage 5 — Jira / Atlassian MCP

The next step was connecting the Agent to Jira.

The project uses an external Atlassian MCP connection represented in Snowflake as:

```text
FINANCE_DEMO_DB.GOLD.ATLASSIAN_JIRA_MCP_SERVER
```

Authentication uses an OAuth dynamic-client flow.

The Agent can retrieve Jira investigation context including:

- Summary
- Description
- Reproduction steps
- Expected result
- Actual result
- Comments
- Labels
- Priority
- Linked issues
- Acceptance criteria

Jira became the source of **documented business evidence**.

## Scope clarification

The completed FSP-8 investigation used the Atlassian MCP connection for Jira investigation.

**Confluence was not used as an evidence source in the completed FSP-8 investigation.**

---

# 12. Stage 6 — Cortex Agent

The Cortex Agent was created as:

```text
FINANCE_DEMO_DB.GOLD.FINANCE_JIRA_AGENT
```

The Agent became the orchestration layer across:

```text
Jira MCP
Snowflake MCP
GitHub MCP
```

Its responsibility was not simply to answer a question.

It had to determine:

1. Which evidence source is needed?
2. What does that source actually say?
3. Is the evidence independently validated?
4. Do different sources agree?
5. Can the reported behavior be reproduced?
6. What RCA classification is appropriate?
7. What business-impact classification is appropriate?
8. What remains unverified?
9. What safe next steps can be proposed?

This changed the project from a simple MCP demonstration into an investigation workflow.

---

# 13. Stage 7 — RBAC and Access Control

The project introduced a dedicated role:

```text
FINANCE_AGENT_ROLE
```

The role provides the access needed for the investigation workflow, including:

- warehouse usage
- database/schema usage
- required table access
- Gold view access
- Semantic View access
- MCP access
- Agent access

The design follows a least-privilege principle for the investigation workload.

Administrative setup may require elevated Snowflake privileges, but the investigation itself is designed around read-only access.

---

# 14. Stage 8 — Cortex CoCo

Snowflake Cortex / CoCo was used through the **browser/web interface** to configure and test the Agent and its integrations.

The workflow included:

```text
CoCo
  ↓
Agent configuration
  ↓
MCP configuration
  ↓
Skill configuration
  ↓
Agent testing
  ↓
Versioned Agent behavior
  ↓
Evaluation
```

The CoCo environment was used to:

- configure the Agent
- connect MCP sources
- attach skills
- test tool calling
- inspect Agent behavior
- refine instructions
- validate the investigation workflow

The project therefore involved both SQL/configuration work and interactive Cortex Agent development.

---

# 15. Stage 9 — CoWork Investigation Skill

A reusable investigation skill was developed through the CoWork skill workflow.

The skill was created as:

```text
jira-bug-investigation/
└── SKILL.md
```

The CoWork workflow was:

```text
CoWork
  ↓
Capabilities
  ↓
Skills
  ↓
Create / Upload
  ↓
jira-bug-investigation
```

The skill was designed to encode the investigation methodology rather than relying only on a large Agent prompt.

The skill establishes rules for:

- evidence integrity
- source classification
- Jira investigation
- Snowflake investigation
- data availability
- grain analysis
- join validation
- transformation analysis
- schema-versus-runtime distinction
- RCA classification
- business-impact classification
- regression testing
- conflicting evidence
- read-only investigation
- Jira approval

---

# 16. Why the Investigation Skill Was Important

Without a reusable skill, an Agent could produce a plausible narrative while silently making assumptions.

The skill establishes boundaries such as:

> Never invent missing evidence.

> Actual Snowflake observations take precedence when the corresponding runtime data exists.

> Jira claims are not automatically confirmed.

> Empty source data blocks runtime validation.

> Schema support does not prove runtime fix validation.

> GitHub implementation evidence does not automatically prove deployment or production runtime behavior.

This makes the investigation methodology reusable across multiple Jira data-quality issues.

---

# 17. Stage 10 — Agent Skill Evolution

The Agent was iteratively refined.

The major versions documented in the project were:

## Version 2

The investigation skill was attached and tested.

The goal was to move the Agent toward a consistent evidence-based investigation pattern.

---

## Version 3

Persona behavior was added.

The same underlying investigation could now be presented differently depending on the requested audience.

---

## Version 4

Evidence and response behavior was strengthened.

The refinement included:

- source identification
- confirmed versus documented evidence
- runtime versus schema distinction
- conflict handling
- fix-status language
- persona behavior
- structured investigation responses
- Jira write approval

The completed evaluation runs used **Version 4**.

---

# 18. Stage 11 — GitHub Integration

A major enhancement was adding implementation evidence from the private GitHub repository.

Repository:

```text
rnemani-ai/jira-bug-investigation-snowflake-mcp
```

The repository was intentionally kept private.

The Agent needed to answer a question that Snowflake runtime data alone could not answer:

> **How is the transformation actually implemented?**

This became particularly important because the current Snowflake sales/fact/gold runtime tables were empty.

---

# 19. GitHub App

A dedicated GitHub App was created:

```text
Snowflake Jira Bug Investigation
```

The App was installed only on the POC repository.

Repository-level access was used rather than broad organization-level access.

The relevant read-oriented repository capabilities included:

- Contents
- Metadata
- Pull requests
- Issues

The purpose was to allow the GitHub MCP connector to inspect implementation evidence while keeping private repository access scoped to the POC.

A real integration issue was encountered during the POC: the private repository was initially not visible to the GitHub integration until the GitHub App was correctly installed for the repository.

After the repository-level installation was completed, the Agent could inspect the private repository.

---

# 20. Stage 12 — Snowflake Git Integration

In addition to GitHub MCP, Snowflake Git integration was configured.

Key objects include:

```text
FINANCE_DEMO_DB.GOLD.GITHUB_JIRA_POC_SECRET

FINANCE_DEMO_DB.GOLD.GITHUB_JIRA_POC_API

FINANCE_DEMO_DB.GOLD.JIRA_BUG_INVESTIGATION_REPO
```

The repository was fetched successfully and a Snowflake Git workspace was created.

This produced two complementary repository workflows:

```text
Snowflake Git / Workspace
          +
GitHub MCP
          ↓
Implementation evidence
```

Snowflake Git/workspace provided the source-control and development workflow inside the Snowflake environment, while GitHub MCP allowed the Cortex Agent to inspect repository evidence.

---

# 21. Stage 13 — GitHub MCP

A GitHub MCP connector was configured and attached to the Cortex Agent.

The connector is:

```text
GITHUB_BUG_INVESTIGATION
```

It is used to inspect implementation evidence such as:

- repository structure
- transformation SQL
- test-data definitions
- Agent configuration
- commits/history
- relevant implementation context

The GitHub MCP became especially valuable when Snowflake runtime data was unavailable.

It allowed the investigation to distinguish:

```text
What the code is designed to do
```

from:

```text
What the current Snowflake runtime can prove
```

---

# 22. Stage 14 — Personas

The Agent was enhanced with three implemented personas.

## Data Engineer

Focuses on:

- table grain
- joins
- transformations
- source-to-target reconciliation
- regression testing
- runtime validation
- technical implementation

## Finance Analyst

Focuses on:

- revenue
- orders
- customers
- finance KPIs
- business interpretation
- business impact

## Engineering Manager

Focuses on:

- RCA status
- affected components
- evidence confidence
- risk
- resolution status
- limitations
- next steps

## Persona Design Principle

Personas change:

> **presentation and emphasis**

They do not change:

- underlying evidence
- evidence classification
- RCA classification
- runtime limitations
- governance rules

---

# 23. Stage 15 — Evidence-Driven Investigation

At this point the project had three distinct evidence planes.

```text
                    INVESTIGATION
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
      Jira           Snowflake         GitHub
        │                │                │
        ▼                ▼                ▼
  Business report    Runtime data    Implementation
  & documentation                     evidence
```

Each source answers a different question.

### Jira

> What was reported?

### Snowflake

> What does the current data actually show?

### GitHub

> How is the transformation implemented?

The Agent then reconciles the evidence.

---

# 24. Stage 16 — FSP-8 as the Representative Investigation

The project needed a realistic issue to exercise the architecture.

The selected issue was:

```text
FSP-8
Revenue is duplicated for split-payment orders
```

The issue describes a potential many-to-many relationship between:

```text
SALES
ORDER_ITEM_ID grain
```

and:

```text
PAYMENTS
PAYMENT_ID grain
```

when joined directly on:

```text
ORDER_ID
```

The investigation became the end-to-end demonstration of the architecture.

---

# 25. Why FSP-8 Was a Useful Test Case

FSP-8 exercises several important investigation behaviors simultaneously.

It requires the Agent to:

- understand Jira documentation
- inspect Snowflake objects
- determine data availability
- understand table grain
- investigate join cardinality
- inspect transformation SQL
- inspect test data
- reconcile conflicting information
- distinguish implementation evidence from runtime evidence
- classify RCA
- classify business impact
- propose regression tests
- respect the Jira approval boundary

Therefore, the issue tests much more than simple Jira retrieval.

---

# 26. Critical Evidence Boundary

One of the most important lessons from the project is:

> **Code evidence is not runtime evidence.**

The GitHub repository contains a transformation pattern that aggregates successful payments by `ORDER_ID` before joining payment information to item-grain sales.

That provides implementation evidence.

However, the current Snowflake runtime state includes:

```text
BRONZE.SALES = 0 rows

BRONZE.PAYMENTS = 8 rows

SILVER.FACT_SALES = 0 rows

GOLD.VW_SALES_KPI = 0 rows
```

Therefore, the current environment does not provide populated sales/fact/gold data needed to independently reproduce the revenue duplication behavior.

The Agent must therefore report:

> **Runtime reproduction is blocked by the current data state.**

It must not convert GitHub test data into Snowflake runtime evidence.

---

# 27. Evidence Conflict Handling

The investigation also exposed a conflict involving Order 1004.

The Jira description describes:

```text
2 sales rows
3 successful payments
6 joined rows
```

A Jira comment contains a different item count.

The repository test data supports:

```text
2 items
3 payments
```

The current Snowflake sales table is empty.

The important behavior is not simply choosing one number.

The Agent must surface the conflict and identify the evidence source for each statement.

This demonstrates that the investigation workflow is designed to **reconcile evidence rather than silently overwrite conflicting information**.

---

# 28. Investigation Workflow

The resulting investigation model is:

```text
1. Start with Jira
       ↓
2. Understand the reported problem
       ↓
3. Validate Snowflake runtime availability
       ↓
4. Determine data grain
       ↓
5. Inspect implementation in GitHub
       ↓
6. Compare Jira claims with implementation
       ↓
7. Compare against Snowflake runtime where possible
       ↓
8. Identify conflicts
       ↓
9. Classify evidence
       ↓
10. Classify RCA
       ↓
11. Classify business impact
       ↓
12. Propose resolution
       ↓
13. Define regression tests
       ↓
14. Prepare bounded final response
       ↓
15. Require human approval before Jira write
```

The detailed architecture and exact technical implementation are documented separately in:

```text
docs/02_TECHNICAL_ARCHITECTURE_AND_IMPLEMENTATION.md
```

---

# 29. Evaluation Stage

After the architecture and investigation workflow were established, the Agent behavior was evaluated.

A lightweight evaluation strategy was intentionally used first.

The purpose was to validate the core investigation behavior without unnecessarily increasing Snowflake or Agent compute consumption.

The evaluation framework contains:

```text
EVAL-001
EVAL-002
EVAL-003
EVAL-004
EVAL-005
EVAL-006
EVAL-007
EVAL-008
EVAL-009
EVAL-010
```

The completed lightweight evaluation executed six representative scenarios:

```text
EVAL-001
EVAL-003
EVAL-004
EVAL-005
EVAL-006
EVAL-007
```

Result:

> **6 / 6 executed evaluations passed.**

The completed tests covered:

- Jira retrieval
- GitHub transformation investigation
- full multi-source investigation
- conflict detection
- empty-data handling
- Data Engineer persona behavior

The remaining scenarios were optional and were not required for the completed POC demonstration.

Detailed evaluation results are documented separately in:

```text
docs/05_EVALUATION_GOVERNANCE_AND_ENGINEERING_ARTIFACTS.md
```

---

# 30. What the Completed POC Demonstrates

The completed POC demonstrates a governed investigation pattern that combines:

```text
Snowflake
+
Cortex Agent
+
MCP
+
Jira
+
GitHub
+
Snowflake Git
+
CoCo
+
CoWork
+
Reusable Skill
+
Personas
+
Evidence Classification
+
RBAC
+
Human Approval
+
Evaluation
```

The key capability is not any single technology.

The value comes from connecting the technologies around a clearly defined investigation workflow.

---

# 31. Key Engineering Lessons

## 31.1 Multi-source access is valuable only when evidence boundaries are explicit

Giving an Agent access to multiple systems is not enough.

The Agent must understand what each system can and cannot prove.

---

## 31.2 Runtime evidence must remain separate from implementation evidence

A correct transformation in GitHub does not automatically prove that the current Snowflake runtime is executing it.

---

## 31.3 Empty data is meaningful evidence

An empty source table is not a reason to fabricate a result.

It is a runtime-validation boundary.

---

## 31.4 Schema support is not fix validation

The existence of payment aggregation columns or other supporting schema does not prove that the deployed transformation is behaving correctly.

---

## 31.5 Conflicting evidence should be surfaced

The investigation should not silently choose one source when multiple sources disagree.

---

## 31.6 Personas should not change factual conclusions

Different audiences may need different explanations, but the evidence and RCA classification must remain consistent.

---

## 31.7 Human approval separates investigation from action

The Agent can investigate and prepare a Jira update without automatically changing Jira.

This creates a useful boundary:

```text
Capability
    ≠
Authority
```

---

## 31.8 Lightweight evaluation can be useful for a POC

The six executed tests were intentionally representative.

The goal was to validate core behavior and its boundaries before spending additional compute on a larger evaluation run.

---

# 32. Final Project State

At the completed POC stage, the architecture contains:

```text
User / Persona
      ↓
Snowflake CoCo / Cortex Agent
      ↓
FINANCE_JIRA_AGENT
      ↓
┌──────────────┬────────────────┬───────────────┐
│              │                │
▼              ▼                ▼
Jira MCP    Snowflake MCP     GitHub MCP
│              │                │
▼              ▼                ▼
Jira         Snowflake       Private GitHub
Evidence     Runtime         Implementation
             Evidence        Evidence
│              │                │
└──────────────┴────────────────┘
               ↓
        Evidence Synthesis
               ↓
          RCA + Impact
               ↓
     Regression-Test Guidance
               ↓
      Proposed Jira Comment
               ↓
        Human Approval
```

The underlying Snowflake platform is:

```text
FINANCE_DEMO_DB
      │
      ├── BRONZE
      │     ├── SALES
      │     ├── PAYMENTS
      │     ├── CUSTOMERS
      │     └── PRODUCTS
      │
      ├── SILVER
      │     ├── FACT_SALES
      │     ├── DIM_CUSTOMER
      │     ├── DIM_PRODUCT
      │     └── DIM_DATE
      │
      └── GOLD
            ├── VW_SALES_KPI
            ├── FINANCE_SALES_SEMANTIC_VIEW
            ├── FINANCE_ANALYTICS_MCP_SERVER
            ├── ATLASSIAN_JIRA_MCP_SERVER
            └── FINANCE_JIRA_AGENT
```

The engineering workflow is supported by:

```text
CoCo
CoWork
GitHub App
GitHub MCP
Snowflake Git
Snowflake Workspace
RBAC
Investigation Skill
Evaluation Artifacts
```

---

# 33. Implemented vs. Future

The project deliberately distinguishes implemented capabilities from future ideas.

## Implemented

- Snowflake Bronze/Silver/Gold
- Snowflake Semantic View
- Snowflake MCP
- Atlassian Jira MCP
- GitHub MCP
- Private GitHub repository integration
- GitHub App
- Snowflake Git integration
- Snowflake Git workspace
- Cortex Agent
- CoCo-based configuration and testing
- Reusable investigation skill
- Agent skill refinement
- Data Engineer persona
- Finance Analyst persona
- Engineering Manager persona
- Evidence classification
- RCA classification
- Business-impact classification
- RBAC
- Read-only investigation
- Human approval for Jira updates
- FSP-8 investigation
- Evaluation framework
- Six executed evaluations with all six passing

## Not Implemented in the Completed POC

The following are future extensions rather than implemented components:

- dbt integration
- ServiceNow integration
- Slack/Teams integration
- Confluence as an investigation evidence source
- RAG/vector database
- Embeddings
- LangChain
- Multi-agent orchestration
- Automatic Jira posting
- Dedicated production audit platform

These items should not be represented as implemented components in the current architecture.

---

# 34. Future Direction

The architecture creates a foundation for additional evidence sources.

One particularly natural future extension is **dbt**.

A future investigation could potentially connect:

```text
Jira
  ↓
GitHub
  ↓
dbt
  ↓
Snowflake Runtime
```

dbt could provide additional evidence such as:

- transformation models
- lineage
- data-quality tests
- job status
- execution history
- model metadata

Other enterprise integrations could be considered when they provide a distinct evidence or workflow capability.

The principle is:

> **Add integrations because they improve the investigation, not simply to increase the technology count.**

---

# 35. Project Positioning

This project should be presented as an:

> **Evidence-driven enterprise data-quality investigation POC built with Snowflake Cortex Agent and MCP.**

It is not simply:

- a chatbot
- a Jira summarizer
- a Snowflake SQL assistant
- a GitHub code-search tool

The central product concept is:

```text
Business Context
      ↓
Tool-Grounded Investigation
      ↓
Cross-Source Evidence Reconciliation
      ↓
Evidence-Bounded RCA
      ↓
Governed Action
```

The Agent is valuable because it connects the investigation across business context, runtime data, implementation evidence, and governance boundaries.

---

# 36. Summary

The project started with a simple question:

> **Can an AI Agent help investigate a finance data-quality issue?**

The final POC demonstrates a more precise answer:

> **An AI Agent can orchestrate a governed investigation across Jira, Snowflake and GitHub when each source has a clearly defined evidence boundary and the Agent is explicitly instructed to distinguish documented claims, implementation evidence and runtime observations.**

The project combines:

- **Snowflake** for the data platform
- **Semantic Views** for business-level analytics
- **MCP** for tool integration
- **Jira** for business issue context
- **GitHub** for implementation evidence
- **Snowflake Git** for repository/workspace integration
- **Cortex Agent** for orchestration
- **CoCo** for Agent configuration and testing
- **CoWork** for reusable skill development
- **Investigation Skills** for consistent behavior
- **Personas** for audience-specific presentation
- **RBAC** for access control
- **Human approval** for Jira actions
- **Evaluation artifacts** for behavioral validation

The most important design principle is:

> **The Agent should never claim more than the available evidence can support.**

# Project Overview and Engineering Journey

## 1. Project Overview

### Project Name

**Jira Bug Investigation with Snowflake MCP**

### Purpose

This project is a **Snowflake-native proof of concept for investigating enterprise data-quality and analytics issues with an AI Agent connected to multiple evidence sources**.

The representative investigation is:

> **FSP-8 — Revenue is duplicated for split-payment orders**

The project combines Snowflake, Cortex Agent, MCP integrations, Jira, GitHub, reusable investigation skills, governance controls, personas, and evaluation.

The important capability is not simply retrieving information from multiple systems. It is **reconciling what each source can actually prove** and producing an evidence-bounded investigation.

![Project Overview](images/project-overview.png)

---

## 2. Why We Built This

### 2.1 The Investigation Problem

Enterprise data-quality issues are rarely contained in one system.

A finance user may report an issue in Jira with:

- business context
- expected behavior
- actual behavior
- reproduction steps
- acceptance criteria
- comments
- suspected root cause

But Jira alone does not prove that the current data platform reproduces the issue.

The relevant runtime data may be in Snowflake, while the transformation responsible for producing that data may be stored in GitHub.

A complete investigation can therefore require:

```text
Jira
  ↓
Snowflake
  ↓
GitHub
  ↓
Evidence reconciliation
```

The engineer must otherwise move manually between systems and determine whether the information is consistent.

### 2.2 The Evidence Problem

The project was designed around a simple boundary:

> **Finding evidence that a fix exists in source code does not prove that the deployed runtime is using that fix.**

Similarly:

> **A Jira ticket reporting a defect does not independently prove that the current Snowflake runtime reproduces the defect.**

This distinction became the central design principle for the Agent.

---

## 3. Core Objective

The primary objective was to demonstrate an investigation workflow that can answer:

> **What happened, what evidence supports it, what can actually be reproduced, what does the implementation do, and what remains unverified?**

The project therefore emphasizes **evidence reconciliation rather than natural-language summarization**.

The three primary evidence domains are:

| Source | Primary role |
|---|---|
| **Jira** | Reported business issue and documented context |
| **Snowflake** | Runtime/data evidence |
| **GitHub** | Implementation and repository evidence |

The Agent uses these sources together but does **not** treat them as interchangeable.

---

## 4. Design Principles

The engineering journey was driven by a small set of principles.

### 4.1 Evidence must have a clear source

The Agent should identify where an important claim came from.

### 4.2 Runtime evidence is distinct from implementation evidence

GitHub can show what the transformation is designed to do.

Snowflake can show what the current runtime contains.

Neither should silently be substituted for the other.

### 4.3 Missing data is a valid investigation result

If required runtime tables are empty, the Agent should report that validation is blocked rather than manufacture a result.

### 4.4 Conflicts should be surfaced

If Jira, GitHub, and Snowflake disagree, the Agent should identify the disagreement and preserve the source of each claim.

### 4.5 Investigation should be read-only

The Agent should investigate, classify, and propose safe next steps without changing the underlying data.

### 4.6 Capability and authority are different

The Agent may be capable of preparing a Jira update without being authorized to post it automatically.

### 4.7 Personas change presentation, not evidence

Different audiences may need different levels of technical or business detail, but the evidence and RCA classification should remain consistent.

---

## 5. Starting Point and Reference Project

The project was inspired by:

```text
deept-agl/Jira_Bug_Analysis_MCP_to_Snowflake
```

The reference implementation provided the starting architectural idea for connecting Jira-related investigation with Snowflake and MCP.

This POC was then extended around its own investigation requirements, including:

- explicit evidence classification
- runtime validation
- GitHub implementation evidence
- reusable investigation skills
- persona-based responses
- conflict handling
- Jira write governance
- regression-test guidance
- lightweight evaluation

The reference project is therefore treated as **inspiration/baseline**, not as a statement that the two implementations are identical.

---

## 6. Engineering Journey

![Phase 1 and Phase 2](images/phase-1-phase-2.png)

The project evolved incrementally:

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

Each stage was added to solve a specific investigation problem rather than to increase the technology count.

---

## 7. Stage 1 — Snowflake Foundation

The first step was to create a small, controlled finance-data environment.

The core Snowflake foundation was:

```text
FINANCE_DEMO_DB
    │
    ├── BRONZE
    ├── SILVER
    └── GOLD

FINANCE_DEMO_WH
```

The purpose was to create a realistic analytical environment in which the Agent could inspect:

- source-oriented data
- transformed data
- business-level views
- runtime availability
- data grain
- joins and reconciliation

The environment was intentionally small because the project was developed in a Snowflake trial environment.

---

## 8. Stage 2 — Bronze, Silver and Gold

The layered data model established the technical context required for investigation.

### Bronze

The source-oriented layer contains:

```text
BRONZE.SALES
BRONZE.PAYMENTS
BRONZE.CUSTOMERS
BRONZE.PRODUCTS
```

Two grains became especially important:

```text
SALES    → ORDER_ITEM_ID / item grain
PAYMENTS → PAYMENT_ID / payment grain
```

### Silver

The transformed layer contains:

```text
SILVER.FACT_SALES
SILVER.DIM_CUSTOMER
SILVER.DIM_PRODUCT
SILVER.DIM_DATE
```

`FACT_SALES` is intended to remain at `ORDER_ITEM_ID` grain.

The payment transformation follows the important pattern of summarizing successful payment information by `ORDER_ID` before joining it to item-grain sales.

### Gold

The analytical layer contains:

```text
GOLD.VW_SALES_KPI
```

This provides business-level metrics and dimensions for analytical investigation.

The detailed object definitions and transformation SQL are documented in:

`docs/02_TECHNICAL_ARCHITECTURE_AND_IMPLEMENTATION.md`

---

## 9. Stage 3 — Semantic View

A Semantic View was added above the Gold layer:

```text
FINANCE_DEMO_DB.GOLD.FINANCE_SALES_SEMANTIC_VIEW
```

The purpose was to provide business-oriented context for finance analytics.

This enabled a business-level investigation path:

```text
Business question
      ↓
Semantic View
      ↓
Cortex Analyst
```

while preserving a separate technical investigation path through SQL.

The important architectural decision was to use **business semantics for business questions** while retaining direct SQL investigation for technical validation.

---

## 10. Stage 4 — Snowflake MCP

The internal Snowflake MCP server became the Agent's primary interface to the Snowflake environment.

It provided two complementary capabilities:

```text
Finance Sales Analyst
        +
Execute Finance SQL
```

The first supports business-level analytical questions.

The second supports technical investigation such as:

- data availability
- schema inspection
- grain analysis
- duplicate detection
- source-to-target reconciliation
- join analysis
- detailed SQL investigation

This separation helped avoid forcing every investigation through a single query style.

The exact MCP configuration is documented in:

`docs/02_TECHNICAL_ARCHITECTURE_AND_IMPLEMENTATION.md`

---

## 11. Stage 5 — Jira / Atlassian MCP

Jira was added as the business-context source.

The Agent can retrieve investigation context such as:

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

### Scope clarification

The completed FSP-8 investigation used the Atlassian MCP connection for Jira investigation.

**Confluence was not used as an evidence source in the completed FSP-8 investigation.**

This distinction is intentionally preserved so the architecture does not imply capabilities that were not demonstrated.

---

## 12. Stage 6 — Cortex Agent

The Cortex Agent became the orchestration layer across:

```text
Jira MCP
Snowflake MCP
GitHub MCP
```

The Agent's responsibility was expanded beyond simply answering a user question.

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

This was the point where the project moved from a basic MCP demonstration toward an **investigation workflow**.

---

## 13. Stage 7 — RBAC and Access Control

A dedicated investigation role was introduced:

```text
FINANCE_AGENT_ROLE
```

The role provides the access required for the investigation workflow across the Snowflake environment.

The design follows a least-privilege approach for the investigation workload.

The investigation path itself is read-only even though administrative setup may require higher Snowflake privileges.

Detailed permissions are documented in:

`docs/02_TECHNICAL_ARCHITECTURE_AND_IMPLEMENTATION.md`

---

## 14. Stage 8 — Cortex CoCo

Snowflake Cortex / CoCo was used through the **browser/web interface** to configure and test the Agent and its integrations.

The workflow was:

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

CoCo was used to:

- configure the Agent
- connect MCP sources
- attach skills
- test tool calling
- inspect Agent behavior
- refine instructions
- validate the investigation workflow

This made the project both a SQL/configuration exercise and an interactive Cortex Agent engineering exercise.

---

## 15. Stage 9 — CoWork Investigation Skill

A reusable investigation skill was developed through the CoWork skill workflow:

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

The methodology covers:

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

The detailed skill design is documented in:

`docs/03_AGENT_COCOWORK_AND_INVESTIGATION_SKILL.md`

---

## 16. Why the Investigation Skill Was Important

Without reusable investigation rules, an Agent could produce a plausible narrative while silently making assumptions.

The skill established boundaries such as:

> **Never invent missing evidence.**

> **Actual Snowflake observations take precedence when the corresponding runtime data exists.**

> **Jira claims are not automatically confirmed.**

> **Empty source data blocks runtime validation.**

> **Schema support does not prove runtime fix validation.**

> **GitHub implementation evidence does not automatically prove deployment or production runtime behavior.**

These rules make the investigation methodology reusable across multiple data-quality issues.

---

## 17. Stage 10 — Agent Skill Evolution

The Agent was refined iteratively.

### Version 2

The investigation skill was attached and tested.

The goal was to establish a consistent evidence-based investigation pattern.

### Version 3

Persona behavior was introduced.

The same underlying investigation could now be presented differently for different audiences.

### Version 4

Evidence and response behavior was strengthened, including:

- source identification
- confirmed versus documented evidence
- runtime versus schema distinction
- conflict handling
- fix-status language
- persona behavior
- structured investigation responses
- Jira write approval

The completed evaluation runs used **Version 4**.

The detailed Agent evolution and skill behavior are documented in:

`docs/03_AGENT_COCOWORK_AND_INVESTIGATION_SKILL.md`

---

## 18. Stage 11 — GitHub Integration

A major enhancement was adding implementation evidence from the private GitHub repository:

```text
rnemani-ai/jira-bug-investigation-snowflake-mcp
```

The reason for adding GitHub was straightforward:

> **Snowflake runtime evidence can show what the current environment contains, but implementation evidence can show how the transformation is designed.**

This became especially important because the current Snowflake sales/fact/Gold runtime tables were empty during the completed investigation.

GitHub therefore provided a second evidence plane without being substituted for runtime validation.

---

## 19. GitHub App and Repository Access

A dedicated GitHub App was created:

```text
Snowflake Jira Bug Investigation
```

It was installed only on the POC repository with scoped repository access.

The relevant read-oriented capabilities included:

- Contents
- Metadata
- Pull requests
- Issues

A real integration issue was encountered during development: the private repository was initially not visible to the GitHub integration until the GitHub App was correctly installed for the repository.

After repository-level installation was completed, the Agent could inspect the private repository.

This was an important engineering lesson:

> **Private-repository MCP access depends on both connector configuration and correct repository-level authorization.**

---

## 20. Stage 12 — Snowflake Git Integration

Snowflake Git integration was configured alongside GitHub MCP.

The repository was fetched successfully and a Snowflake Git workspace was created.

The two workflows serve complementary purposes:

```text
Snowflake Git / Workspace
          +
GitHub MCP
          ↓
Implementation evidence
```

Snowflake Git/workspace supports source-control and development workflows inside the Snowflake environment.

GitHub MCP allows the Cortex Agent to inspect repository evidence during an investigation.

Detailed configuration is documented in:

`docs/02_TECHNICAL_ARCHITECTURE_AND_IMPLEMENTATION.md`

---

## 21. Stage 13 — GitHub MCP

The GitHub MCP connector was attached to the Cortex Agent:

```text
GITHUB_BUG_INVESTIGATION
```

It is used to inspect:

- repository structure
- transformation SQL
- test-data definitions
- Agent configuration
- commits/history
- relevant implementation context

The connector became particularly valuable when Snowflake runtime data was unavailable.

It allowed the investigation to distinguish:

```text
What the code is designed to do
```

from:

```text
What the current Snowflake runtime can prove
```

---

## 22. Stage 14 — Personas

Three personas were implemented:

### Data Engineer

Focus:

- table grain
- joins
- transformations
- source-to-target reconciliation
- regression testing
- runtime validation
- technical implementation

### Finance Analyst

Focus:

- revenue
- orders
- customers
- finance KPIs
- business interpretation
- business impact

### Engineering Manager

Focus:

- RCA status
- affected components
- evidence confidence
- risk
- resolution status
- limitations
- next steps

### Persona design principle

Personas change:

> **presentation and emphasis**

They do not change:

- underlying evidence
- evidence classification
- RCA classification
- runtime limitations
- governance rules

---

## 23. Stage 15 — Evidence-Driven Investigation

At this point the project had three distinct evidence planes:

```text
                    INVESTIGATION
                         │
          ┌──────────────┼──────────────┐
          │              │              │
          ▼              ▼              ▼
        Jira         Snowflake       GitHub
          │              │              │
          ▼              ▼              ▼
      Business        Runtime       Implementation
      report          data           evidence
```

Each source answers a different question.

### Jira

> **What was reported?**

### Snowflake

> **What does the current data actually show?**

### GitHub

> **How is the transformation implemented?**

The Agent then reconciles these sources rather than collapsing them into a single undifferentiated answer.

---

## 24. Stage 16 — FSP-8 as the Representative Investigation

The project selected a realistic issue to exercise the complete architecture:

```text
FSP-8
Revenue is duplicated for split-payment orders
```

The issue involves a potential grain mismatch between:

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

The representative investigation is documented separately in:

`docs/04_FSP8_END_TO_END_INVESTIGATION.md`

![FSP-8 Test Case](images/fsp8-test-case.png)

---

## 25. Why FSP-8 Was a Useful Test Case

FSP-8 exercises several investigation behaviors simultaneously:

- understanding Jira documentation
- checking Snowflake data availability
- determining table grain
- analyzing join cardinality
- inspecting transformation SQL
- inspecting test data
- reconciling conflicting information
- separating implementation evidence from runtime evidence
- classifying RCA
- classifying business impact
- proposing regression tests
- respecting the Jira approval boundary

It therefore tests substantially more than simple Jira retrieval.

---

## 26. Critical Evidence Boundary

One of the most important lessons from the project is:

> **Code evidence is not runtime evidence.**

The GitHub repository contains a transformation pattern that aggregates successful payments by `ORDER_ID` before joining payment information to item-grain sales.

That provides implementation evidence.

However, the completed investigation found:

```text
BRONZE.SALES       = 0 rows
BRONZE.PAYMENTS    = 8 rows
SILVER.FACT_SALES  = 0 rows
GOLD.VW_SALES_KPI  = 0 rows
```

Therefore, the current environment did not provide populated sales/fact/Gold data needed to independently reproduce the revenue-duplication behavior.

The Agent must report:

> **Runtime reproduction is blocked by the current data state.**

It must not convert GitHub test data into Snowflake runtime evidence.

---

## 27. Evidence Conflict Handling

The investigation exposed a concrete discrepancy involving Order 1004.

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

The Agent must:

1. identify the conflicting sources
2. identify the evidence type for each statement
3. explain why the current runtime cannot resolve the discrepancy
4. avoid presenting one source as runtime truth without supporting data

This demonstrates the project's emphasis on **evidence reconciliation rather than silent source selection**.

---

## 28. Investigation Workflow

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
14. Produce bounded final response
       ↓
15. Require human approval before Jira write
```

This sequence became the conceptual backbone of the investigation skill and Agent behavior.

---

## 29. Evaluation Stage

After the architecture and investigation workflow were established, Agent behavior was evaluated.

A lightweight evaluation strategy was intentionally used first because the project was running in a Snowflake trial environment.

The evaluation framework contains ten scenarios, while six representative scenarios were executed for the completed POC:

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

The detailed evaluation results are documented in:

`docs/05_EVALUATION_GOVERNANCE_AND_ENGINEERING_ARTIFACTS.md`

---

## 30. What the Completed POC Demonstrates

The completed POC demonstrates a governed investigation pattern combining:

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
Investigation Skill
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

The value is not any individual technology.

The value comes from connecting these technologies around a clearly defined investigation workflow.

---

## 31. Key Engineering Lessons

### 31.1 Multi-source access is valuable only when evidence boundaries are explicit

Giving an Agent access to multiple systems is not enough.

The Agent must understand what each system can and cannot prove.

### 31.2 Runtime evidence must remain separate from implementation evidence

A correct transformation in GitHub does not automatically prove that the current Snowflake runtime is executing it.

### 31.3 Empty data is meaningful evidence

An empty source table is not a reason to fabricate a result.

It is a runtime-validation boundary.

### 31.4 Schema support is not fix validation

The existence of payment aggregation columns or other supporting schema does not prove that the deployed transformation is behaving correctly.

### 31.5 Conflicting evidence should be surfaced

The investigation should not silently choose one source when multiple sources disagree.

### 31.6 Personas should not change factual conclusions

Different audiences may need different explanations, but the evidence and RCA classification must remain consistent.

### 31.7 Human approval separates investigation from action

The Agent can investigate and prepare a Jira update without automatically changing Jira.

This creates an important boundary:

```text
Capability
    ≠
Authority
```

### 31.8 Lightweight evaluation can be useful for a POC

The six executed tests were intentionally representative.

The goal was to validate core behavior and evidence boundaries before spending additional compute on a larger evaluation run.

---

## 32. Final Project State

At the completed POC stage, the architecture can be summarized as:

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
      Regression Guidance
               ↓
       Proposed Jira Comment
               ↓
         Human Approval
```

The supporting engineering workflow includes:

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

## 33. Implemented vs. Future

The project deliberately distinguishes implemented capabilities from future ideas.

### Implemented

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

### Not Implemented in the Completed POC

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

## 34. Future Direction

The architecture creates a foundation for additional evidence sources.

One natural future extension is **dbt**.

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

The guiding principle is:

> **Add integrations because they improve the investigation, not simply to increase the technology count.**

---

## 35. Summary

The project started with a simple question:

> **Can an AI Agent help investigate a finance data-quality issue?**

The completed POC demonstrates a more precise answer:

> **An AI Agent can orchestrate a governed investigation across Jira, Snowflake, and GitHub when each source has a clearly defined evidence boundary and the Agent is explicitly instructed to distinguish documented claims, implementation evidence, and runtime observations.**

The most important design principle is:

> **The Agent should never claim more than the available evidence can support.**

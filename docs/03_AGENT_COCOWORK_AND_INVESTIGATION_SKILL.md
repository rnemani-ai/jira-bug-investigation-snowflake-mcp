# Agent, CoWork and Investigation Skill

## Document Purpose

This document explains how the project evolved from a basic Cortex Agent into an **evidence-driven Jira investigation Agent** with a reusable investigation skill.

It focuses on:

- CoWork-based skill development
- Investigation-skill architecture
- Evidence handling and source boundaries
- Data and grain validation
- RCA and business-impact classification
- Agent version evolution
- Persona behavior
- Human approval for Jira actions
- CoCo and CoWork roles
- Evaluation lessons
- Current implementation boundaries

> **Document boundary:** Document 02 covers the concrete Snowflake/MCP/Agent implementation. Document 04 contains the detailed FSP-8 investigation case study. This document focuses on the **behavioral methodology, skill design, governance, and Agent evolution** that make those technical components work together.


# 2. Why an Investigation Skill Was Needed

A basic AI Agent can retrieve information and generate a plausible explanation.

That is not sufficient for an enterprise data-quality investigation.

A finance data issue can involve several different kinds of evidence:

```text
Jira
  → What was reported?

Snowflake
  → What does the current data show?

GitHub
  → What does the implementation do?
```

Without explicit rules, an Agent could easily blur these boundaries.

For example:

```text
Jira says the bug exists
        ↓
Agent assumes the bug exists in Snowflake
        ↓
GitHub contains a fix
        ↓
Agent assumes the fix is deployed
        ↓
Agent reports the issue as resolved
```

The project was specifically designed to avoid this chain of unsupported assumptions.

The investigation skill provides the behavioral framework that prevents those conclusions from being made without evidence.

---

# 3. Skill Development Approach

The skill was developed through the CoWork skill workflow and then refined for the Cortex Agent.

The development path was:

```text
Investigation requirements
        ↓
CoWork skill design
        ↓
jira-bug-investigation/SKILL.md
        ↓
Upload/use in Snowflake environment
        ↓
Agent testing
        ↓
Behavior refinement
        ↓
Agent Version 2
        ↓
Agent Version 3
        ↓
Agent Version 4
        ↓
Evaluation
```

The resulting skill is not simply a collection of prompts.

It encodes a repeatable investigation methodology.

---

# 4. CoWork Skill

The reusable skill is named:

```text
jira-bug-investigation
```

Its purpose is to guide an AI Agent through data-quality and analytics investigations involving:

- Jira
- Snowflake
- source/target data
- SQL transformations
- GitHub implementation evidence
- business impact
- RCA
- regression testing
- Jira follow-up

The skill establishes both:

```text
Investigation behavior
```

and:

```text
Governance boundaries
```

---

# 5. Core Skill Responsibilities

The investigation skill covers the following areas:

```text
1. Evidence integrity
2. Source classification
3. Jira retrieval
4. Snowflake investigation
5. Data availability
6. Grain validation
7. Join validation
8. Transformation analysis
9. Schema vs runtime distinction
10. RCA classification
11. Business-impact classification
12. Regression testing
13. Conflicting evidence
14. Evidence/citation handling
15. Jira approval
16. Final response structure
```

This makes the skill reusable beyond FSP-8.

---

# 6. Evidence-First Design

The most important skill principle is:

> **The Agent must not claim more than the available evidence supports.**

The skill therefore distinguishes several evidence states.

## Confirmed

A claim supported by actual evidence available to the Agent.

Example:

```text
Snowflake query returned 8 payment rows.
```

---

## Documented

A claim explicitly reported by an external source.

Example:

```text
Jira reports that revenue is duplicated for split-payment orders.
```

The report is real evidence of what was documented.

It is not automatically proof of current runtime behavior.

---

## Likely

A technically supported interpretation that has not reached the evidence threshold for confirmation.

Example:

```text
The observed join design is likely to create many-to-many multiplication.
```

---

## Unverified

A claim for which the investigation does not have enough supporting evidence.

---

## Illustrative

An example used to explain a technical mechanism.

Illustrative values must not be presented as actual runtime observations.

---

## Blocked

The evidence required to perform a validation step is unavailable.

Example:

```text
SALES is empty.
FACT_SALES is empty.
Therefore runtime reproduction is blocked.
```

---

# 7. Source-Specific Evidence

The skill explicitly distinguishes the role of each evidence source.

## Jira

Jira provides:

```text
Documented business context
```

It can provide:

- issue description
- expected behavior
- actual behavior as reported
- reproduction steps
- acceptance criteria
- comments
- labels
- priority
- linked issues

---

## Snowflake

Snowflake provides:

```text
Runtime/data evidence
```

It can provide:

- current row counts
- actual values
- table contents
- schema
- grain
- joins
- reconciliations
- runtime query results

---

## GitHub

GitHub provides:

```text
Implementation evidence
```

It can provide:

- transformation SQL
- repository structure
- test data
- configuration
- commits
- pull requests
- implementation context

The skill prevents these sources from being treated as interchangeable.

---

# 8. Runtime Evidence Boundary

One of the strongest rules in the skill is:

> **Do not confuse implementation evidence with runtime evidence.**

Suppose GitHub contains:

```text
Payment aggregation by ORDER_ID
```

That can establish:

```text
The repository contains a transformation designed to prevent payment multiplication.
```

It cannot automatically establish:

```text
The current Snowflake runtime is executing this logic successfully.
```

Runtime validation requires populated runtime data and appropriate validation queries.

---

# 9. Empty Data Handling

The skill explicitly treats empty data as a meaningful investigation result.

For example:

```text
BRONZE.SALES = 0 rows
SILVER.FACT_SALES = 0 rows
GOLD.VW_SALES_KPI = 0 rows
```

If the investigation requires those tables to reproduce a revenue issue, the Agent must state:

```text
Runtime validation blocked.
```

The Agent must not:

- invent rows
- simulate a query result
- convert GitHub test data into Snowflake evidence
- claim the bug is reproduced

This is one of the most important safeguards in the skill.

---

# 10. Grain-First Investigation

The skill requires the Agent to determine the grain of relevant objects before analyzing a data-quality issue.

For FSP-8:

```text
SALES
ORDER_ITEM_ID grain

PAYMENTS
PAYMENT_ID grain
```

This matters because joining two different granularities on:

```text
ORDER_ID
```

can produce row multiplication.

The Agent therefore asks:

```text
What is one row in each table?
```

before asking:

```text
Is the join correct?
```

---

# 11. Join Validation

For a suspected many-to-many issue, the Agent should compare:

```text
Source order-item count
+
Successful payment count
+
Joined row count
```

For example:

```text
2 sales items
2 successful payments
        ↓
2 × 2 = 4 joined rows
```

The expected item-level result remains:

```text
2 rows
```

This is the core mechanism behind the FSP-8 investigation.

---

# 12. Grain-Safe Resolution Pattern

The skill establishes the safe pattern for payment-related many-to-many problems:

```text
PAYMENTS
   ↓
filter successful payments
   ↓
GROUP BY ORDER_ID
   ↓
one payment summary row/order
   ↓
join to SALES
   ↓
FACT_SALES remains ORDER_ITEM_ID grain
```

The payment summary is a transformation/CTE pattern in the current implementation.

It is not represented as a separate persistent Silver table.

---

# 13. Schema vs Fix Validation

The skill explicitly separates:

```text
Schema support
```

from:

```text
Fix validation
```

For example, the existence of:

```text
SUCCESSFUL_PAYMENT_COUNT
SUCCESSFUL_PAYMENT_AMOUNT
PAYMENT_METHODS
PAYMENT_PATTERN
```

shows that the model supports payment-related information.

It does not prove that:

```text
the current transformation is correct
```

or:

```text
the runtime output is correct
```

The Agent therefore uses more precise language.

---

# 14. Fix-Status Language

The skill supports several levels of implementation evidence.

## Schema Support Confirmed

Use when the relevant columns or objects exist.

---

## Fix Logic Confirmed in Transformation

Use when the transformation SQL has been inspected and contains the expected logic.

For FSP-8:

```text
successful payments are aggregated by ORDER_ID before joining to sales.
```

---

## Runtime Behavior Validated

Use only when populated runtime data has passed the relevant checks.

This was not established for the current empty:

```text
SALES
FACT_SALES
GOLD.VW_SALES_KPI
```

runtime state.

---

## Deployment Documented

Use only when deployment is explicitly supported by evidence.

Deployment documentation should not be presented as independent runtime validation.

---

# 15. RCA Classification

The skill defines four RCA outcomes:

```text
Confirmed Root Cause
Documented Root Cause — Not Reproducible
Likely Root Cause
Root Cause Not Yet Determined
```

The Agent must select the classification based on available evidence.

---

## Confirmed Root Cause

Use when the evidence establishes the cause.

Typical support could include:

```text
populated runtime data
+
reproducible behavior
+
verified transformation/join mechanism
```

---

## Documented Root Cause — Not Reproducible

Use when the issue and/or cause are documented in a trusted source, but current runtime data cannot reproduce the behavior.

This classification is especially relevant when:

```text
Jira describes the issue
+
GitHub supports the technical mechanism
+
current Snowflake runtime is empty
```

---

## Likely Root Cause

Use when the technical mechanism is strongly supported but the evidence threshold for confirmation is not met.

---

## Root Cause Not Yet Determined

Use when the available evidence is insufficient to identify a credible mechanism.

---

# 16. Business-Impact Classification

The skill separately classifies business impact.

Possible classifications:

```text
Measured
Estimated
Documented
Not Quantifiable with Current Data
```

This prevents the Agent from inventing financial impact.

For example, if Jira reports that revenue is overstated, that can be documented.

But if current Snowflake data cannot support a calculation, the Agent must not invent:

```text
$X revenue impact
```

or:

```text
Y% overstatement
```

unless the evidence supports that value.

---

# 17. Evidence Conflict Handling

The skill explicitly requires the Agent to surface conflicts.

For example, FSP-8 contains an inconsistency around Order 1004.

The issue description reports:

```text
2 sales rows
3 successful payments
6 joined rows
```

A Jira comment contains a different item count.

GitHub test data supports:

```text
2 items
3 payments
```

Current Snowflake `SALES` is empty.

The Agent must not silently choose one source and discard the others.

Instead it should explain:

```text
Source A says X.
Source B says Y.
Repository evidence supports Z.
Current runtime cannot independently resolve the discrepancy.
```

---

# 18. Agent Version Evolution

The Agent evolved as the investigation requirements became clearer.

---

## Version 2 — Skill-Based Investigation

The first major refinement was attaching the investigation methodology to the Agent.

The objective was to make responses more consistent around:

- evidence
- runtime validation
- grain
- RCA
- impact
- regression tests

The Agent moved away from generic answer generation toward a defined investigation process.

---

# 19. Version 3 — Persona Behavior

The next refinement added persona-oriented responses.

Implemented personas:

```text
Data Engineer
Finance Analyst
Engineering Manager
```

The goal was to allow the same underlying evidence to be communicated according to the audience.

### Data Engineer

Emphasis:

```text
grain
joins
SQL
transformations
runtime checks
regression tests
```

### Finance Analyst

Emphasis:

```text
revenue
orders
finance KPIs
business meaning
business impact
```

### Engineering Manager

Emphasis:

```text
RCA status
risk
evidence confidence
affected components
next steps
```

The skill explicitly prevents personas from changing the factual investigation result.

---

# 20. Version 4 — Stronger Evidence Governance

Version 4 became the published Agent version used for the completed POC.

It strengthened:

- source-aware evidence handling
- conflict detection
- runtime validation boundaries
- schema-vs-runtime distinction
- fix-status language
- RCA classification
- business-impact classification
- regression guidance
- persona behavior
- read-only investigation
- Jira approval

The goal was to make the Agent's output more defensible for an enterprise engineering workflow.

---

# 21. Current Agent Instruction Pattern

The current Agent orchestration follows this high-level sequence:

```text
1. Retrieve Jira
2. Extract documented issue context
3. Inspect Snowflake runtime
4. Determine data availability
5. Determine grain
6. Analyze relevant joins
7. Inspect GitHub implementation
8. Compare sources
9. Identify conflicts
10. Classify evidence
11. Classify RCA
12. Classify business impact
13. Provide safe resolution guidance
14. Provide regression guidance
15. Respect read-only restrictions
16. Prepare Jira update only when requested
17. Require explicit approval before Jira write
```

---

# FSP-8 as a Skill Validation Example

FSP-8 provides a concrete example of the investigation methodology without serving as the full case study.

The skill applies the following sequence:

```text
Jira report
   ↓
Snowflake availability
   ↓
Grain and join analysis
   ↓
GitHub implementation inspection
   ↓
Source reconciliation
   ↓
RCA / impact classification
   ↓
Regression guidance
```

For the current POC, the skill correctly distinguishes:

- **Jira:** documents the reported revenue-duplication issue and acceptance criteria.
- **Snowflake:** contains payment data but the current `SALES`, `FACT_SALES`, and Gold runtime paths needed for full reproduction are empty.
- **GitHub:** contains transformation logic that aggregates successful payments by `ORDER_ID` before joining to sales.
- **Runtime status:** full end-to-end reproduction is therefore **blocked**.
- **Implementation status:** the payment-aggregation pattern is confirmed in the inspected transformation, but that does not establish runtime validation.
- **Conflicting evidence:** the Order 1004 item-count discrepancy is surfaced rather than silently resolved.

The complete FSP-8 investigation, including source evidence, transformation details, conflicts, impact analysis, and regression checks, belongs in **Document 04**.


# 23. Regression-Test Guidance

The skill treats regression testing as part of investigation rather than an optional afterthought.

Recommended categories include:

## Grain Test

Verify:

```text
one FACT_SALES row per ORDER_ITEM_ID
```

---

## Source-to-Target Reconciliation

Compare source sales measures with fact-level measures.

---

## Gold-to-Silver Reconciliation

Verify:

```text
Gold revenue = Silver revenue
```

for the relevant aggregation.

---

## Split-Payment Test

Specifically test orders containing:

```text
multiple successful payments
```

---

## Duplicate Detection

Check for unexpected multiplication after joins.

---

# 24. Jira Action Governance

The skill establishes a hard boundary between:

```text
Investigation
```

and:

```text
External action
```

The Agent can prepare a Jira comment.

It must not silently post it.

The required pattern is:

```text
Investigation complete
        ↓
Draft proposed comment
        ↓
"This comment has NOT been posted to Jira."
        ↓
"Would you like me to post this comment to Jira?"
        ↓
Explicit user approval
        ↓
Only then post
```

This prevents an investigation Agent from becoming an uncontrolled ticket-modification Agent.

---

# 25. Proposed Jira Comment Structure

When a Jira update is requested, the skill requires the proposed comment to distinguish:

```text
1. Confirmed evidence
2. Documented claims
3. Technical findings
4. Limitations
5. RCA classification
6. Business-impact classification
7. Resolution guidance
8. Regression-test guidance
```

The proposed comment must not contain unsupported claims.

---

# 26. Why Human Approval Matters

The project deliberately keeps a human in the loop for Jira updates.

The Agent may have enough technical information to prepare a useful comment.

However:

```text
Technical confidence
≠
Authorization to modify an enterprise system
```

The approval gate therefore acts as a governance control.

---

# 27. Persona + Skill Relationship

The architecture separates:

```text
Skill
```

from:

```text
Persona
```

The skill defines:

```text
How the investigation must be performed.
```

The persona defines:

```text
How the result should be communicated.
```

Conceptually:

```text
                Investigation Skill
                       │
                       ▼
                Common Evidence
                       │
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
 Data Engineer    Finance Analyst   Engineering Manager
        │              │              │
 technical view   business view    management view
```

This prevents persona selection from becoming a mechanism for changing the underlying facts.

---

# 28. CoCo and CoWork Roles

The project uses CoCo and CoWork for different purposes.

## CoCo

Used for:

- Cortex Agent configuration
- MCP connection
- Agent testing
- Agent versioning
- interactive investigation

## CoWork

Used for:

- reusable skill development
- skill authoring
- skill upload
- structured investigation methodology

The resulting relationship is:

```text
CoWork
   ↓
Investigation Skill
   ↓
Cortex Agent / CoCo
   ↓
MCP Tools
   ↓
Investigation
```

---

# 29. Skill Design vs Prompt-Only Design

The project intentionally moves important behavior into a reusable skill.

A prompt-only design can become difficult to maintain as rules grow.

The skill creates a more explicit structure for:

```text
Evidence
Data validation
RCA
Impact
Regression
Governance
```

This makes the methodology easier to reuse across future Jira investigations.

---

# 30. What the Skill Does Not Do

The investigation skill does not:

- create runtime data
- manufacture missing evidence
- independently prove deployment
- replace Snowflake data validation
- replace source-control evidence
- automatically approve Jira changes
- turn Jira claims into facts
- make business decisions for users

It is a behavioral and governance layer around the investigation process.

---

# 31. Evaluation of Skill Behavior

The completed lightweight evaluation tested the Agent's most important skill behaviors.

Executed scenarios:

```text
EVAL-001
EVAL-003
EVAL-004
EVAL-005
EVAL-006
EVAL-007
```

Results:

```text
6 executed
6 passed
```

The scenarios covered:

```text
Jira-only retrieval
GitHub implementation lookup
Full multi-source investigation
Conflict detection
Empty-data handling
Data Engineer persona
```

The results provided evidence that the skill rules were being followed in representative investigations.

---

# 32. Evaluation Lessons

The evaluation surfaced useful refinements.

For example:

- GitHub test data should be described as **supporting/corroborating evidence**, not automatically as authoritative runtime evidence.
- Empty tables can block some regression checks but do not mean every possible regression test would necessarily fail.
- Jira comments and descriptions can conflict and must be represented as separate source statements.
- A transformation containing the correct logic does not establish runtime validation.

These lessons were incorporated into the investigation behavior.

---

# 33. Current Skill Architecture

The resulting skill architecture can be represented as:

```text
                    User Investigation
                           │
                           ▼
                     Cortex Agent
                           │
                           ▼
                 jira-bug-investigation
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
   Evidence Rules      Data Rules       Governance Rules
        │                  │                  │
        ▼                  ▼                  ▼
  Source classes      Grain / joins      Read-only
  Conflicts          Availability       Jira approval
  Citations          Reconciliation     No fabrication
        │                  │                  │
        └──────────────────┼──────────────────┘
                           ▼
                   Investigation Output
                           │
            ┌──────────────┼──────────────┐
            ▼              ▼              ▼
           RCA          Impact       Regression
```

---

# 34. Enterprise Engineering Value

The skill architecture provides several engineering benefits.

## Consistency

Similar Jira issues can be investigated using the same methodology.

## Evidence Discipline

The Agent is less likely to confuse documented claims with runtime facts.

## Reusability

The investigation logic can be applied beyond FSP-8.

## Governance

External actions require explicit approval.

## Explainability

The response can show why an RCA classification was selected.

## Audience Adaptation

The same investigation can be presented to different personas.

---

# 35. Important Current Boundaries

The current implementation should be described accurately.

### Implemented

```text
Cortex Agent
Investigation skill
CoWork skill workflow
CoCo development/testing
Jira MCP
Snowflake MCP
GitHub MCP
Three personas
Evidence classification
RCA classification
Impact classification
Regression guidance
Human approval
Read-only investigation
```

### Current runtime limitation

```text
SALES is empty
FACT_SALES is empty
GOLD.VW_SALES_KPI is empty
```

Therefore:

```text
End-to-end FSP-8 runtime reproduction is blocked.
```

### Not implemented

```text
Automatic Jira writes
dbt
RAG
Vector DB
Embeddings
Multi-agent orchestration
ServiceNow
Slack/Teams
Confluence-based completed investigation workflow
```

---

# 36. Final Agent Behavior

The intended final behavior can be summarized as:

```text
Retrieve
   ↓
Inspect
   ↓
Validate
   ↓
Compare
   ↓
Classify
   ↓
Explain
   ↓
Test
   ↓
Ask approval before action
```

The Agent should be technically useful without pretending to know more than the evidence supports.

---

# 37. Final Design Principle

The central principle of the skill is:

> **Investigation quality depends not only on what tools the Agent can access, but on whether the Agent understands what each source can actually prove.**

The project therefore treats:

```text
Jira
Snowflake
GitHub
```

as different evidence planes.

The skill connects them through a controlled investigation methodology:

```text
Business report
      ↓
Runtime validation
      ↓
Implementation inspection
      ↓
Evidence reconciliation
      ↓
RCA
      ↓
Business impact
      ↓
Regression guidance
      ↓
Human-approved action
```

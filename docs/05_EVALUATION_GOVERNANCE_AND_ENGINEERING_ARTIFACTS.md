# Evaluation, Governance and Engineering Artifacts

## 1. Document Purpose

This document describes the evaluation, governance, engineering-artifact, and delivery aspects of the **Jira Bug Investigation with Snowflake MCP** proof of concept.

It covers:

- evaluation strategy
- evaluation scenarios
- executed results
- what passed
- evaluation limitations
- evidence governance
- SQL safety
- Jira write approval
- RBAC
- cost-aware POC design
- repository artifacts
- configuration-as-code
- implemented versus future capabilities
- engineering lessons
- final project readiness and boundaries

The purpose is to document how the project was validated and governed without overstating what the POC proves.

---

# 2. Evaluation Philosophy

The evaluation strategy was designed around a simple principle:

> **Evaluate the Agent's investigation behavior, not only whether it can generate a plausible answer.**

For this project, a useful evaluation must test whether the Agent can:

```text
Retrieve the right evidence
        ↓
Use the correct tool
        ↓
Respect source boundaries
        ↓
Validate runtime availability
        ↓
Understand grain
        ↓
Inspect implementation
        ↓
Detect conflicts
        ↓
Classify RCA correctly
        ↓
Classify business impact correctly
        ↓
Avoid unsupported claims
        ↓
Respect governance rules
```

This is different from evaluating a generic chatbot for answer quality.

---

# 3. Why a Lightweight Evaluation Was Used First

The project was developed in a Snowflake trial environment.

Agent executions, LLM-based evaluation, warehouse usage, and other Snowflake resources can consume trial resources.

Therefore the project intentionally started with a lightweight, representative evaluation set.

The objective was to establish:

```text
Does the core investigation workflow behave correctly?
```

before spending additional resources on a larger evaluation run.

The evaluation was stopped after the core POC behavior had been sufficiently demonstrated.

---

# 4. Evaluation Set

The project defines ten evaluation scenarios:

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

The evaluation set covers the main behaviors required by the investigation Agent.

The complete expected-results artifact is maintained separately in:

```text
evaluations/expected_results.md
```

The intended evaluation structure is:

```text
evaluations/
├── README.md
├── test_cases.yaml
└── expected_results.md
```

---

# 5. Executed Evaluation Scenarios

Six representative scenarios were executed:

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

The remaining scenarios:

```text
EVAL-002
EVAL-008
EVAL-009
EVAL-010
```

were not required for the completed POC demonstration.

They remain available as optional future evaluation coverage.

---

# 6. EVAL-001 — Jira-Only Retrieval

## Objective

Validate that the Agent can retrieve and accurately summarize the Jira issue without unnecessarily invoking other systems.

## Scenario

Retrieve:

```text
FSP-8
```

and report its documented:

- metadata
- expected behavior
- actual behavior
- acceptance criteria

## Expected Behavior

The Agent should:

- retrieve Jira information
- preserve the documented issue context
- avoid unnecessary Snowflake investigation
- avoid unnecessary GitHub investigation
- avoid modifying Jira

## Result

```text
PASS
```

The Agent correctly retrieved the Jira context and did not claim additional runtime or implementation evidence.

---

# 7. EVAL-003 — GitHub Transformation Lookup

## Objective

Validate that the Agent can inspect the repository and identify the implementation relevant to FSP-8.

## Scenario

Investigate the Silver-layer transformation.

The relevant implementation is:

```text
00_setup/01_create_silver_layer.sql
```

## Expected Behavior

The Agent should identify:

- sales grain
- payment grain
- payment aggregation
- `ORDER_ID` grouping
- final join behavior
- preservation of `FACT_SALES` item grain

## Result

```text
PASS
```

The Agent successfully found the transformation and explained the payment-summary approach.

---

# 8. EVAL-004 — Full Multi-Source Investigation

## Objective

Validate the complete investigation flow across:

```text
Jira
+
Snowflake
+
GitHub
```

## Scenario

Investigate FSP-8 end to end.

## Expected Behavior

The Agent should:

1. retrieve Jira
2. inspect Snowflake runtime
3. identify empty runtime tables
4. determine table grain
5. inspect GitHub implementation
6. identify the many-to-many mechanism
7. identify the payment aggregation pattern
8. identify the Jira Order 1004 conflict
9. avoid claiming runtime reproduction
10. avoid claiming runtime fix validation

## Result

```text
PASS
```

### Important observation

The Agent correctly maintained the runtime evidence boundary.

A minor evaluation refinement was identified:

> Empty tables can block some regression checks, but not every conceivable regression test would necessarily fail simply because the tables are empty.

This distinction was incorporated into the broader evaluation interpretation.

---

# 9. EVAL-005 — Conflicting Evidence

## Objective

Validate whether the Agent can identify conflicting information across evidence sources.

## Scenario

Compare Order 1004 information across:

```text
Jira description
Jira comment
GitHub test data
Snowflake runtime
```

## Expected Behavior

The Agent should identify:

```text
Jira description:
2 items + 3 payments

Jira comment:
different item-count statement

GitHub:
2 items + 3 payments

Snowflake SALES:
0 rows
```

The Agent should not silently select one source as universally authoritative.

## Result

```text
PASS
```

The Agent detected and described the conflict.

### Refinement

Repository test data should be described as:

```text
supporting/corroborating evidence
```

rather than automatically being described as authoritative runtime evidence.

---

# 10. EVAL-006 — Empty Data Handling

## Objective

Validate that the Agent does not fabricate runtime evidence when the relevant Snowflake tables are empty.

## Scenario

Investigate FSP-8 while:

```text
BRONZE.SALES = 0
SILVER.FACT_SALES = 0
GOLD.VW_SALES_KPI = 0
```

## Expected Behavior

The Agent should:

- report the empty state
- state that runtime reproduction is blocked
- avoid simulation
- avoid fabricated row counts
- avoid claiming runtime fix validation

## Result

```text
PASS
```

The Agent correctly preserved the runtime evidence boundary.

---

# 11. EVAL-007 — Data Engineer Persona

## Objective

Validate the Data Engineer persona.

## Scenario

Ask the Agent to explain FSP-8 from a technical engineering perspective.

## Expected Behavior

The response should emphasize:

- table grain
- joins
- transformation logic
- source/target reconciliation
- regression testing
- runtime limitations

It should not change the underlying evidence or RCA classification simply because the persona changed.

## Result

```text
PASS
```

The Agent provided a technical investigation while preserving the evidence boundaries.

---

# 12. Evaluation Summary

The executed evaluation result is:

| Evaluation | Purpose | Result |
|---|---|---|
| EVAL-001 | Jira retrieval | PASS |
| EVAL-003 | GitHub transformation lookup | PASS |
| EVAL-004 | Full multi-source investigation | PASS |
| EVAL-005 | Conflict detection | PASS |
| EVAL-006 | Empty-data handling | PASS |
| EVAL-007 | Data Engineer persona | PASS |

Overall:

```text
Executed: 6
Passed:   6
Failed:   0
```

This result demonstrates that the core POC behaviors were working for the tested scenarios.

It does not imply that every possible investigation scenario has been exhaustively tested.

---

# 13. Remaining Evaluation Coverage

The following scenarios were not required for the completed POC:

```text
EVAL-002
EVAL-008
EVAL-009
EVAL-010
```

These should be considered:

```text
Optional / future evaluation coverage
```

rather than failed tests.

A future evaluation cycle can execute them once additional coverage is needed.

---

# 14. Evaluation Boundaries

The evaluation results should be interpreted carefully.

A passing Agent evaluation means:

```text
The Agent behaved as expected for the tested scenario.
```

It does not mean:

```text
The production data pipeline is correct.
```

It does not mean:

```text
FSP-8 is currently fixed in production.
```

It does not mean:

```text
The current Snowflake runtime successfully reproduces or validates the bug.
```

The POC evaluation validates **Agent behavior**, not production deployment correctness.

---

# 15. Native Evaluation Considerations

Snowflake's native evaluation capabilities were considered during the project.

A native evaluation workflow can introduce additional resource consumption because it may involve:

- Agent executions
- LLM judging
- warehouse usage
- storage
- evaluation datasets

The project therefore chose a lightweight manual/representative baseline first.

The native evaluation path remains an extension rather than a requirement for the completed POC.

---

# 16. Governance Architecture

Governance is built into the Agent behavior.

The main controls are:

```text
Read-only Snowflake investigation
        +
Evidence classification
        +
No fabricated data
        +
Source conflict handling
        +
RCA classification
        +
Business-impact classification
        +
Human approval for Jira writes
        +
RBAC
```

The goal is to make the Agent useful without giving it uncontrolled authority.

---

# 17. Read-Only Snowflake Investigation

The Agent instructions prohibit destructive or data-changing SQL during investigation.

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

The investigation is intended to use operations such as:

```text
SELECT
SHOW
DESCRIBE
```

This keeps investigation separate from data modification.

---

# 18. Why Read-Only Matters

A data-quality investigation can involve uncertain evidence.

Allowing an Agent to modify data while it is still determining the root cause creates unnecessary risk.

The design therefore follows:

```text
Investigate first
        ↓
Validate evidence
        ↓
Propose action
        ↓
Human approval
        ↓
Separate execution workflow
```

The completed POC focuses on investigation, not autonomous remediation.

---

# 19. Jira Write Governance

The Agent is also prevented from silently modifying Jira.

The required pattern is:

```text
Investigation
     ↓
Draft Jira comment
     ↓
Show exact proposed comment
     ↓
Human approval
     ↓
Only then post
```

The Agent must explicitly state:

```text
This comment has NOT been posted to Jira.
```

and:

```text
Would you like me to post this comment to Jira?
```

before a Jira update is considered.

---

# 20. Why Human Approval Is Important

The Agent can have:

```text
technical capability
```

without automatically receiving:

```text
authorization to change enterprise records
```

This creates a clear governance boundary.

The project therefore demonstrates:

> **AI-assisted investigation with human-controlled external action.**

---

# 21. Evidence Governance

The Agent uses explicit evidence categories.

```text
Confirmed
Documented
Likely
Unverified
Illustrative
Blocked
```

These categories prevent a single confidence level from being applied to every statement.

For example:

```text
Jira says the issue exists
```

is:

```text
Documented
```

while:

```text
Snowflake query reproduced the issue
```

could be:

```text
Confirmed
```

if the runtime evidence actually supports it.

---

# 22. RCA Governance

RCA classification is separated from generic narrative generation.

Allowed classifications are:

```text
Confirmed Root Cause

Documented Root Cause — Not Reproducible

Likely Root Cause

Root Cause Not Yet Determined
```

The Agent must select the classification based on the evidence available.

For FSP-8, the current runtime limitation prevents an end-to-end runtime-confirmed conclusion.

---

# 23. Business-Impact Governance

Business impact is also classified independently.

Possible states:

```text
Measured
Estimated
Documented
Not Quantifiable with Current Data
```

For FSP-8:

```text
Jira reports revenue overstatement
```

is documented.

But:

```text
Current financial impact = $X
```

cannot be asserted without populated runtime data supporting the calculation.

---

# 24. Conflict Governance

When evidence sources disagree, the Agent must preserve the conflict.

The FSP-8 Order 1004 example demonstrates this.

The Agent should say:

```text
Source A reports one value.

Source B reports another.

Repository test data supports one interpretation.

Current Snowflake runtime cannot independently resolve the difference.
```

The Agent should not silently normalize conflicting evidence.

---

# 25. Schema vs Runtime Governance

Another key control is:

```text
Schema evidence
        ≠
Runtime evidence
```

For example, the presence of:

```text
PAYMENT_PATTERN
```

or payment aggregation fields proves that the schema supports payment information.

It does not prove:

```text
the current runtime output is correct.
```

The Agent must use precise fix-status language.

---

# 26. Fix Validation Governance

The project recognizes four useful states:

```text
Schema Support Confirmed

Fix Logic Confirmed in Transformation

Runtime Behavior Validated

Deployment Documented
```

These states must not be collapsed into one generic:

```text
Fixed
```

For FSP-8:

```text
Fix logic confirmed in transformation
```

is supported by GitHub inspection.

But:

```text
Runtime behavior validated
```

was blocked by empty runtime tables.

---

# 27. RBAC Governance

The investigation role is:

```text
FINANCE_AGENT_ROLE
```

The role provides the permissions needed for the investigation workflow.

Conceptually:

```text
FINANCE_AGENT_ROLE
       │
       ├── Warehouse usage
       ├── Database/schema usage
       ├── Required table SELECT
       ├── Gold view access
       ├── Semantic View access
       ├── MCP access
       └── Agent access
```

The design avoids giving the investigation workflow broad administrative authority.

---

# 28. External Integration Governance

The project uses scoped integrations.

## Jira

OAuth-based Atlassian MCP connection.

## GitHub

A dedicated GitHub App installed only on the POC repository.

## Snowflake Git

Repository integration through a dedicated Snowflake API integration and secret.

These controls are designed to avoid treating enterprise integrations as unrestricted credentials.

---

# 29. GitHub Repository Controls

The GitHub App was configured for the private POC repository with read-oriented permissions.

The relevant permissions include:

```text
Contents       Read-only
Metadata       Read-only
Pull requests  Read-only
Issues         Read-only
```

This is sufficient for the completed investigation use case.

The project does not depend on granting the Agent broad organization or enterprise permissions.

---

# 30. Cost-Aware POC Design

The project was built with Snowflake trial-resource usage in mind.

The design intentionally favors:

```text
Small datasets
Targeted SQL
Read-only queries
Representative tests
Warehouse auto-suspend
Avoiding unnecessary processing
```

The investigation does not require:

```text
large-scale data processing
vector databases
embedding generation
RAG pipelines
multi-agent orchestration
```

This keeps the POC technically focused and resource-conscious.

---

# 31. Warehouse Cost Control

The project uses:

```text
FINANCE_DEMO_WH
```

The warehouse was intended to use auto-suspend to avoid unnecessary idle compute.

A short auto-suspend interval is appropriate for a trial-style POC because investigations are intermittent rather than continuously processing data.

The exact account-level billing behavior can vary by Snowflake configuration and should be monitored separately.

---

# 32. Evaluation Cost Control

Evaluation can itself consume resources.

For example:

```text
Agent execution
+
LLM judgment
+
warehouse activity
```

can increase consumption.

The project therefore stopped after:

```text
6 executed
6 passed
```

once the core investigation behavior had been sufficiently demonstrated.

This is a deliberate POC tradeoff rather than an evaluation failure.

---

# 33. Engineering Artifacts

The project maintains engineering artifacts for reproducibility.

The repository includes:

```text
README.md
cleanup/
JIRA_work_items/
00_setup/
01_mcp_and_agent/
skills/
```

Additional documentation is organized as:

```text
docs/
├── 01_PROJECT_OVERVIEW_AND_ENGINEERING_JOURNEY.md
├── 02_TECHNICAL_ARCHITECTURE_AND_IMPLEMENTATION.md
├── 03_AGENT_COCOWORK_AND_INVESTIGATION_SKILL.md
├── 04_FSP8_END_TO_END_INVESTIGATION.md
└── 05_EVALUATION_GOVERNANCE_AND_ENGINEERING_ARTIFACTS.md
```

This separates:

```text
Project narrative
Technical architecture
Agent/skill behavior
FSP-8 case study
Evaluation/governance
```

instead of placing every detail into one README.

---

# 34. Evaluation Artifacts

The evaluation artifacts are organized as:

```text
evaluations/
├── README.md
├── test_cases.yaml
└── expected_results.md
```

### README.md

Describes the evaluation purpose and usage.

### test_cases.yaml

Defines the evaluation scenarios.

### expected_results.md

Documents expected behavior and detailed expected outcomes for:

```text
EVAL-001 through EVAL-010
```

The completed execution used six representative cases.

---

# 35. Skill Artifacts

The repository contains the investigation skill:

```text
skills/
└── jira-bug-investigation/
    └── SKILL.md
```

Snowflake also maintains managed skill content under:

```text
.snowflake/
└── si/
    └── skills/
```

The `.snowflake` content should be treated as Snowflake-managed environment content rather than manually duplicated or deleted as ordinary application files.

---

# 36. GitHub and Snowflake Git Artifacts

The repository integration includes:

```text
GITHUB_JIRA_POC_SECRET
GITHUB_JIRA_POC_API
JIRA_BUG_INVESTIGATION_REPO
```

The Git repository is connected to:

```text
rnemani-ai/jira-bug-investigation-snowflake-mcp
```

This provides a source-controlled home for the implementation.

---

# 37. Agent Artifacts

The main Agent is:

```text
FINANCE_DEMO_DB.GOLD.FINANCE_JIRA_AGENT
```

The current published POC version is:

```text
Version 4
```

Connected evidence/tool sources include:

```text
FINANCE_ANALYTICS_MCP_SERVER
ATLASSIAN_JIRA_MCP_SERVER
GITHUB_BUG_INVESTIGATION
```

---

# 38. Snowflake Object Inventory

The principal implementation objects are:

## Database

```text
FINANCE_DEMO_DB
```

## Warehouse

```text
FINANCE_DEMO_WH
```

## Bronze

```text
FINANCE_DEMO_DB.BRONZE.SALES
FINANCE_DEMO_DB.BRONZE.PAYMENTS
FINANCE_DEMO_DB.BRONZE.CUSTOMERS
FINANCE_DEMO_DB.BRONZE.PRODUCTS
```

## Silver

```text
FINANCE_DEMO_DB.SILVER.FACT_SALES
FINANCE_DEMO_DB.SILVER.DIM_CUSTOMER
FINANCE_DEMO_DB.SILVER.DIM_PRODUCT
FINANCE_DEMO_DB.SILVER.DIM_DATE
```

## Gold

```text
FINANCE_DEMO_DB.GOLD.VW_SALES_KPI
FINANCE_DEMO_DB.GOLD.FINANCE_SALES_SEMANTIC_VIEW
```

## MCP

```text
FINANCE_DEMO_DB.GOLD.FINANCE_ANALYTICS_MCP_SERVER
FINANCE_DEMO_DB.GOLD.ATLASSIAN_JIRA_MCP_SERVER
```

## Agent

```text
FINANCE_DEMO_DB.GOLD.FINANCE_JIRA_AGENT
```

---

# 39. Repository Engineering Workflow

The repository supports a basic engineering lifecycle:

```text
Develop
   ↓
Store implementation in GitHub
   ↓
Connect through Snowflake Git
   ↓
Inspect through GitHub MCP
   ↓
Configure Cortex Agent
   ↓
Test behavior
   ↓
Evaluate
   ↓
Document
```

This helps keep implementation and documentation connected.

---

# 40. Configuration-as-Code Principle

A core engineering goal is to avoid relying entirely on manual UI configuration.

The project stores important artifacts in source control where practical.

Examples include:

```text
SQL setup
MCP configuration
Agent-related configuration
Jira work items
Skills
Evaluation artifacts
Documentation
```

The UI is still used for certain interactive configuration and authentication workflows, but the repository provides a durable engineering record.

---

# 41. What the Evaluation Actually Demonstrates

The six passing tests provide evidence that the POC Agent can perform the tested investigation behaviors.

Specifically, the tests demonstrate:

```text
Jira retrieval
GitHub code inspection
Multi-source reasoning
Conflict detection
Empty-data handling
Persona-specific presentation
```

The tests also demonstrate that the Agent can preserve important boundaries such as:

```text
Jira claim ≠ runtime fact
GitHub code ≠ runtime validation
Empty data ≠ permission to fabricate evidence
Persona ≠ different factual conclusion
```

---

# 42. What the Evaluation Does Not Demonstrate

The evaluation does not establish:

```text
Production readiness
```

It does not establish:

```text
Production-scale performance
```

It does not establish:

```text
Current production financial accuracy
```

It does not establish:

```text
FSP-8 runtime reproduction in the current Snowflake environment
```

It does not establish:

```text
Runtime validation of the proposed fix
```

It does not establish:

```text
Autonomous safe Jira modification
```

These require additional evidence and testing.

---

# 43. Implemented Capabilities

The completed POC includes:

```text
✓ Snowflake Bronze/Silver/Gold
✓ Semantic View
✓ Snowflake MCP
✓ Atlassian Jira MCP
✓ GitHub MCP
✓ Private GitHub App integration
✓ Snowflake Git integration
✓ Snowflake Git workspace
✓ Cortex Agent
✓ CoCo configuration/testing
✓ CoWork investigation skill
✓ Evidence classification
✓ RCA classification
✓ Business-impact classification
✓ Data Engineer persona
✓ Finance Analyst persona
✓ Engineering Manager persona
✓ Read-only investigation
✓ Jira human-approval gate
✓ Evaluation artifacts
✓ 6/6 executed evaluation scenarios passing
```

---

# 44. Not Implemented

The following are intentionally outside the completed POC:

```text
✗ Automatic Jira posting without approval
✗ dbt integration
✗ ServiceNow integration
✗ Slack/Teams integration
✗ Completed Confluence evidence workflow
✗ RAG pipeline
✗ Vector database
✗ Embedding pipeline
✗ LangChain dependency
✗ Multi-agent orchestration
✗ Autonomous remediation
✗ Production audit platform
```

These should be presented as future possibilities, not current implementation.

---

# 45. Important Documentation Rule

The project documentation should always distinguish:

```text
Implemented
```

from:

```text
Future
```

For example:

### Correct

```text
Future extension:
Connect dbt metadata and test results.
```

### Incorrect

```text
The platform uses dbt for lineage.
```

unless dbt has actually been implemented.

The same rule applies to:

- Confluence
- ServiceNow
- Slack
- RAG
- vector databases
- automated remediation
- production monitoring

---

# 46. Important Evidence Rule

The project should also distinguish:

```text
Documented
```

from:

```text
Confirmed
```

For example:

### Correct

```text
Jira documents revenue duplication for split-payment orders.
```

### Stronger statement requiring runtime evidence

```text
Snowflake currently reproduces revenue duplication for split-payment orders.
```

The second statement requires populated runtime evidence.

---

# 47. Important Fix-Status Rule

The project should distinguish:

```text
Fix logic confirmed in transformation
```

from:

```text
Runtime behavior validated
```

For FSP-8:

```text
GitHub:
payment aggregation exists.
```

is implementation evidence.

But:

```text
Snowflake:
runtime revenue remains correct after the transformation.
```

requires populated runtime validation.

---

# 48. Engineering Lessons

## 48.1 Tool access alone is not enough

Connecting Jira, Snowflake and GitHub does not automatically create a reliable investigation.

The Agent needs explicit rules for how evidence is interpreted.

---

## 48.2 Skills provide behavioral structure

The reusable investigation skill provides a consistent methodology across investigations.

---

## 48.3 Grain analysis is fundamental

Many data-quality issues are really cardinality issues.

The Agent must understand:

```text
what one row represents
```

before interpreting aggregations.

---

## 48.4 Empty runtime data must remain an explicit limitation

An Agent should never compensate for missing evidence by inventing values.

---

## 48.5 Conflicting evidence should be visible

Conflicts can themselves be important investigation findings.

---

## 48.6 Code inspection and runtime validation are complementary

GitHub can explain how a transformation is implemented.

Snowflake can explain what the current runtime shows.

Neither should automatically substitute for the other.

---

## 48.7 Governance should be designed into the workflow

Read-only SQL and human approval are easier to enforce when they are part of the Agent's architecture rather than afterthoughts.

---

# 49. Future Evaluation Expansion

If the project is extended, evaluation can expand to cover:

```text
Additional personas
Additional Jira issue types
Additional data-quality patterns
Additional GitHub evidence
Populated runtime validation
Regression-test execution
Jira approval workflow
```

The current evaluation framework provides the foundation for that expansion.

---

# 50. Future Runtime Validation

A particularly useful next validation step would be to populate a controlled test dataset in the Snowflake environment and execute the FSP-8 regression tests.

The desired validation path would be:

```text
Populate controlled test data
        ↓
Run Silver transformation
        ↓
Validate FACT_SALES grain
        ↓
Validate split-payment orders
        ↓
Validate revenue reconciliation
        ↓
Validate Gold/Silver consistency
        ↓
Run Agent investigation again
```

Any such data-loading step should be treated as a separate controlled testing workflow rather than something the investigation Agent performs automatically.

---

# 51. Future Evaluation Maturity

A future mature evaluation approach could combine:

```text
Representative manual tests
        +
Structured evaluation dataset
        +
Automated assertions
        +
LLM-based qualitative judging
        +
Regression evaluation
```

The project intentionally did not require this full stack for the initial POC.

---

# 52. Future Governance Maturity

Potential future controls could include:

```text
More granular roles
Formal audit logging
Approval workflows
Environment separation
Automated regression gates
Deployment verification
Production observability
```

These are future extensions and should not be represented as already implemented.

---

# 53. Hiring-Manager / Engineering Story

The engineering story of the project can be summarized as:

```text
Started with a Snowflake + Jira MCP investigation concept
              ↓
Built a finance data foundation
              ↓
Added Semantic View and Snowflake MCP
              ↓
Connected Jira
              ↓
Built Cortex Agent
              ↓
Developed reusable investigation skill
              ↓
Refined Agent behavior through versions
              ↓
Connected private GitHub through a scoped App and MCP
              ↓
Added implementation-level evidence
              ↓
Added personas
              ↓
Added evidence/RCA/impact governance
              ↓
Investigated FSP-8 end to end
              ↓
Evaluated core behaviors
              ↓
Documented boundaries and future extensions
```

This demonstrates engineering judgment rather than simply tool configuration.

---

# 54. Product and Engineering Value

The completed POC demonstrates several practical capabilities.

## Cross-System Investigation

The Agent can connect business issue context with data and implementation evidence.

## Faster Root-Cause Analysis

The workflow reduces manual movement between:

```text
Jira
Snowflake
GitHub
```

## Evidence Discipline

The Agent explicitly distinguishes evidence types.

## Technical Explainability

The Agent can explain grain and join behavior rather than only reporting a conclusion.

## Governance

The Agent is constrained from destructive SQL and uncontrolled Jira writes.

## Reusability

The investigation methodology is encoded as a reusable skill.

---

# 55. Current POC Maturity

The completed system should be described as:

> **A working, evaluated proof of concept for governed, evidence-driven Jira data-quality investigation using Snowflake Cortex Agent and MCP.**

It should not be described as:

```text
production-ready automated remediation platform
```

or:

```text
fully autonomous enterprise incident-management system
```

The POC has demonstrated the core investigation architecture and representative Agent behavior.

---

# 56. Final Architecture and Governance Model

The completed design can be summarized as:

```text
                         User
                          │
                          ▼
                   Cortex Agent
                          │
              ┌───────────┼───────────┐
              │           │           │
              ▼           ▼           ▼
            Jira      Snowflake     GitHub
             MCP         MCP          MCP
              │           │           │
              ▼           ▼           ▼
          Documented    Runtime    Implementation
           evidence     evidence     evidence
              │           │           │
              └───────────┼───────────┘
                          ▼
                 Investigation Skill
                          │
              ┌───────────┼───────────┐
              ▼           ▼           ▼
             RCA        Impact     Regression
              │           │           │
              └───────────┼───────────┘
                          ▼
                  Proposed Jira Action
                          │
                          ▼
                   Human Approval
```

The governance boundaries are:

```text
Read-only Snowflake investigation
+
Evidence-aware reasoning
+
No fabricated runtime data
+
Explicit conflict handling
+
Scoped repository access
+
RBAC
+
Human approval for Jira writes
```

---

# 57. Final Conclusion

The evaluation and governance work completes the technical story of the POC.

The project does not attempt to prove that an AI Agent can simply answer a Jira question.

It demonstrates a more useful enterprise pattern:

```text
Retrieve evidence
      ↓
Validate evidence
      ↓
Understand data
      ↓
Inspect implementation
      ↓
Reconcile sources
      ↓
Classify confidence
      ↓
Determine RCA
      ↓
Assess impact
      ↓
Recommend validation
      ↓
Require human approval for action
```

The six executed evaluations all passed, providing representative evidence that the core Agent workflow behaves as designed.

At the same time, the project deliberately preserves its limitations:

```text
Current Snowflake sales/fact/gold data is empty.
Therefore FSP-8 runtime reproduction is blocked.

GitHub transformation logic is confirmed.
Runtime behavior is not independently validated.

Jira documents the issue.
Jira documentation is not automatically treated as runtime truth.

The Agent can prepare a Jira update.
It does not silently post one.
```

The strongest engineering outcome is therefore not a claim of complete automation.

It is a demonstrated architecture for:

> **Evidence-driven, governed enterprise data-quality investigation using Snowflake Cortex Agent, MCP, reusable skills, and controlled human action.**

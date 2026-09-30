# Executive Overview

## Project

**Jira Bug Investigation with Snowflake MCP**

## What we built

A Snowflake Cortex Agent that investigates Jira data-quality issues
using three evidence sources:

1.  **Jira MCP** --- business context and issue details.
2.  **Snowflake MCP** --- runtime data and analytical validation.
3.  **GitHub MCP** --- transformation SQL, test data, commits and
    repository evidence.

A reusable `jira-bug-investigation` skill controls evidence
classification, RCA analysis, business-impact classification, read-only
investigation and human approval before Jira updates.

## Why we built it

A data-quality issue is often distributed across systems. Jira contains
the reported symptom, GitHub contains implementation logic, and
Snowflake contains runtime data. The POC demonstrates how an Agent can
reconcile these sources rather than treating one source as automatically
authoritative.

## What it demonstrates

-   Snowflake Cortex Agent orchestration.
-   MCP integrations.
-   Bronze/Silver/Gold data architecture.
-   Semantic View and Cortex Analyst-backed finance analysis.
-   Private GitHub investigation.
-   Atlassian Jira integration.
-   Reusable investigation skill.
-   Evidence-aware RCA.
-   Read-only investigation.
-   Human approval before Jira updates.
-   Lightweight evaluation: **6 executed tests, all passed**.

## Central design principle

**Code evidence is not runtime evidence.** If the relevant Snowflake
tables are empty, the Agent must say that runtime validation is blocked
instead of inventing a result.

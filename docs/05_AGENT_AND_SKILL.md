# Cortex Agent and Investigation Skill

## Agent

`FINANCE_DEMO_DB.GOLD.FINANCE_JIRA_AGENT`

The Agent orchestrates the investigation and invokes source-specific MCP
tools.

## Skill

`jira-bug-investigation`

The reusable skill establishes the investigation discipline.

### Evidence categories

-   Confirmed
-   Documented
-   Likely
-   Unverified
-   Illustrative
-   Blocked
-   Conflict

### RCA classifications

-   Confirmed Root Cause
-   Documented Root Cause --- Not Reproducible
-   Likely Root Cause
-   Root Cause Not Yet Determined

### Business-impact classifications

-   Measured
-   Estimated
-   Documented
-   Not Quantifiable with Current Data

## Guardrails

-   Do not fabricate runtime results.
-   Do not treat Jira hypotheses as independently verified.
-   Do not infer a deployed fix from schema columns alone.
-   Preserve data grain.
-   Prefer actual Snowflake observations when available.
-   Use read-only SQL during investigation.
-   Never automatically modify Jira.
-   Show the exact proposed Jira comment and obtain approval first.

## Personas

### Data Engineer

Emphasizes grain, joins, transformations, tests and technical evidence.

### Finance Analyst

Emphasizes revenue, KPIs and business impact.

### Engineering Manager

Emphasizes RCA status, impact, risk and next steps.

Persona changes presentation, not evidence or RCA classification.

## Approval gate

The required pre-post wording is:

> This comment has NOT been posted to Jira.

> Would you like me to post this comment to Jira?

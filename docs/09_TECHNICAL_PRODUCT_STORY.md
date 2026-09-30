# Technical Product Story

## Problem

A finance data-quality bug can span multiple systems. Jira records the
business symptom, GitHub contains transformation logic, and Snowflake
contains runtime data.

## Solution

We built an evidence-driven Snowflake Cortex Agent that connects those
sources through MCP.

## Why this architecture

-   **Cortex Agent** provides orchestration.
-   **MCP** separates source access from Agent reasoning.
-   **Investigation Skill** enforces consistent evidence and governance
    rules.
-   **Snowflake** provides the analytical/runtime foundation.
-   **GitHub** provides implementation evidence.
-   **Jira** provides business context and issue lifecycle.

## Product value

The system reduces the manual work needed to move from a bug report to a
defensible investigation while making evidence gaps visible.

## What makes the POC technically interesting

It does not simply summarize Jira. It asks:

1.  What was reported?
2.  What does the implementation actually do?
3.  What can Snowflake runtime data prove?
4.  Do the sources agree?
5.  What is confirmed versus unverified?
6.  What should be communicated back to Jira?

## Hiring-manager summary

> We built an evidence-driven Snowflake Cortex Agent that investigates
> Jira data-quality issues by connecting Jira business context, GitHub
> implementation evidence and Snowflake runtime data, while enforcing
> evidence classification, read-only investigation and human approval
> for Jira updates.
